using F1Info_Tickets.Model.Requests;
using F1Info_Tickets.Services.Database;
using F1Info_Tickets.Services.Exceptions;
using F1Info_Tickets.Services.Helpers;
using F1Info_Tickets.Services.Interfaces;
using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using System.Security.Cryptography;
using System.Text;

namespace F1Info_Tickets.Services.Services
{
    // Forgotten password: a short-lived one-time code is emailed (through RabbitMQ and the worker);
    // the code and a new password then reset the password.
    public class PasswordResetService : IPasswordResetService
    {
        private static readonly TimeSpan CodeLifetime = TimeSpan.FromMinutes(15);
        private static readonly TimeSpan ResendDelay = TimeSpan.FromMinutes(1);
        private const int MaxFailedAttempts = 5;
        private const string InvalidCodeMessage = "The code is invalid or has expired. Request a new code.";

        private readonly ApplicationDbContext _context;
        private readonly IMessageProducer _messageProducer;
        private readonly ILogger<PasswordResetService> _logger;
        private readonly PasswordHasher<User> _passwordHasher = new();

        public PasswordResetService(ApplicationDbContext context, IMessageProducer messageProducer, ILogger<PasswordResetService> logger)
        {
            _context = context;
            _messageProducer = messageProducer;
            _logger = logger;
        }

        public async Task RequestCodeAsync(ForgotPasswordRequest request)
        {
            var user = await FindUserAsync(request.Email);
            // The response is the same for unknown addresses, so the endpoint does not reveal who is registered.
            if (user == null)
                return;

            var now = DateTime.UtcNow;
            var openCodes = await _context.PasswordResetCodes
                .Where(c => c.UserID == user.UserID && c.UsedAt == null && c.ExpiresAt > now)
                .ToListAsync();
            if (openCodes.Any(c => now - c.CreatedAt < ResendDelay))
                throw new BusinessException("A code was sent less than a minute ago. Check your email or try again shortly.");

            // Only the newest code is valid.
            foreach (var open in openCodes)
                open.ExpiresAt = now;

            var code = RandomNumberGenerator.GetInt32(0, 1_000_000).ToString("D6");
            _context.PasswordResetCodes.Add(new PasswordResetCode
            {
                UserID = user.UserID,
                CodeHash = Hash(user.UserID, code),
                CreatedAt = now,
                ExpiresAt = now.Add(CodeLifetime)
            });
            await _context.SaveChangesAsync();

            try
            {
                await _messageProducer.PublishEmailAsync(EmailTemplates.PasswordReset(user, code, CodeLifetime));
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Password reset email for user {UserId} could not be queued.", user.UserID);
                throw new BusinessException("The code could not be sent right now. Please try again.");
            }
        }

        public async Task ResetPasswordAsync(ResetPasswordRequest request)
        {
            var user = await FindUserAsync(request.Email) ?? throw new BusinessException(InvalidCodeMessage);
            var now = DateTime.UtcNow;
            var reset = await _context.PasswordResetCodes
                .Where(c => c.UserID == user.UserID && c.UsedAt == null && c.ExpiresAt > now)
                .OrderByDescending(c => c.CreatedAt)
                .FirstOrDefaultAsync() ?? throw new BusinessException(InvalidCodeMessage);

            var expected = Encoding.ASCII.GetBytes(reset.CodeHash);
            var actual = Encoding.ASCII.GetBytes(Hash(user.UserID, request.Code.Trim()));
            if (!CryptographicOperations.FixedTimeEquals(expected, actual))
            {
                reset.FailedAttempts++;
                var blocked = reset.FailedAttempts >= MaxFailedAttempts;
                if (blocked)
                    reset.ExpiresAt = now;
                await _context.SaveChangesAsync();
                throw new BusinessException(blocked
                    ? "Too many wrong attempts. Request a new code."
                    : $"The code is not correct. Attempts left: {MaxFailedAttempts - reset.FailedAttempts}.");
            }

            // New password and used code are saved together, so the code cannot be used twice.
            user.PasswordHash = _passwordHasher.HashPassword(user, request.NewPassword);
            reset.UsedAt = now;
            await _context.SaveChangesAsync();
        }

        private Task<User?> FindUserAsync(string email)
        {
            var normalized = email.Trim();
            return _context.Users.FirstOrDefaultAsync(u => u.Email == normalized);
        }

        // The code is salted with the user ID; only this hash is stored.
        private static string Hash(int userId, string code)
            => Convert.ToHexString(SHA256.HashData(Encoding.UTF8.GetBytes($"{userId}:{code}")));
    }
}
