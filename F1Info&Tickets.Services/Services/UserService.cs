using F1Info_Tickets.Model.Requests;
using F1Info_Tickets.Model.Responses;
using F1Info_Tickets.Model.SearchObjects;
using F1Info_Tickets.Services.BaseServices;
using F1Info_Tickets.Services.Database;
using F1Info_Tickets.Services.Exceptions;
using F1Info_Tickets.Services.Interfaces;
using MapsterMapper;
using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.IdentityModel.Tokens;
using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;

namespace F1Info_Tickets.Services.Services
{
    public class UserService : BaseCRUDService<User, UserResponse, UserSearchObject, UserInsertRequest, UserUpdateRequest>, IUserService
    {
        private const int MinimumAge = 16;
        private static readonly TimeSpan TokenLifetime = TimeSpan.FromHours(8);

        private readonly PasswordHasher<User> _passwordHasher = new();
        private readonly IConfiguration _configuration;

        public UserService(ApplicationDbContext context, IMapper mapper, IConfiguration configuration)
            : base(context, mapper)
        {
            _configuration = configuration;
        }

        protected override IQueryable<User> AddInclude(IQueryable<User> query)
            => query.Include(u => u.UserRoles).ThenInclude(ur => ur.Role);

        protected override IQueryable<User> AddFilter(IQueryable<User> query, UserSearchObject? search)
        {
            if (!string.IsNullOrWhiteSpace(search?.SearchTerm))
                query = query.Where(u => u.Username.Contains(search.SearchTerm)
                    || u.Email.Contains(search.SearchTerm)
                    || (u.FirstName + " " + u.LastName).Contains(search.SearchTerm));
            if (search?.RoleID != null)
                query = query.Where(u => u.UserRoles.Any(ur => ur.RoleID == search.RoleID));
            return query;
        }

        protected override IQueryable<User> ApplyOrder(IQueryable<User> query) => query.OrderBy(u => u.LastName).ThenBy(u => u.FirstName);

        public override async Task<UserResponse> InsertAsync(UserInsertRequest request)
        {
            if (request.RoleID == null)
                throw new BusinessException("Select the user's role.");
            return await CreateUserAsync(request, request.RoleID.Value);
        }

        public async Task<UserResponse> RegisterAsync(UserInsertRequest request)
        {
            var userRoleId = await _context.Roles.Where(r => r.Name == Roles.User).Select(r => r.RoleID).FirstAsync();
            return await CreateUserAsync(request, userRoleId);
        }

        private async Task<UserResponse> CreateUserAsync(UserInsertRequest request, int roleId)
        {
            ValidateBirthDate(request.BirthDate);
            await EnsureUniqueAsync(request.Username, request.Email, null);
            await EnsureRoleExistsAsync(roleId);

            var user = _mapper.Map<User>(request);
            user.PasswordHash = _passwordHasher.HashPassword(user, request.Password);
            user.UserRoles = new List<UserRole> { new() { RoleID = roleId } };

            _context.Users.Add(user);
            await SaveChangesAsync();
            return (await GetByIdAsync(user.UserID))!;
        }

        // Admin edit: role and (optionally) a new password without knowing the old one.
        public override async Task<UserResponse?> UpdateAsync(int id, UserUpdateRequest request)
        {
            var user = await _context.Users.Include(u => u.UserRoles).FirstOrDefaultAsync(u => u.UserID == id);
            if (user == null) return null;

            ValidateBirthDate(request.BirthDate);
            await EnsureUniqueAsync(request.Username, request.Email, id);
            await EnsureRoleExistsAsync(request.RoleID);

            user.FirstName = request.FirstName;
            user.LastName = request.LastName;
            user.Email = request.Email;
            user.Username = request.Username;
            user.Phone = request.Phone;
            user.BirthDate = request.BirthDate;

            if (!string.IsNullOrEmpty(request.Password))
                user.PasswordHash = _passwordHasher.HashPassword(user, request.Password);

            if (user.UserRoles.All(ur => ur.RoleID != request.RoleID))
            {
                _context.UserRoles.RemoveRange(user.UserRoles);
                _context.UserRoles.Add(new UserRole { UserID = id, RoleID = request.RoleID });
            }

            await SaveChangesAsync();
            return await GetByIdAsync(id);
        }

        public async Task<UserResponse> GetProfileAsync(int userId)
        {
            return await GetByIdAsync(userId) ?? throw new NotFoundException("User not found.");
        }

        public async Task<UserResponse> UpdateProfileAsync(int userId, ProfileUpdateRequest request)
        {
            var user = await _context.Users.FindAsync(userId) ?? throw new NotFoundException("User not found.");

            ValidateBirthDate(request.BirthDate);
            await EnsureUniqueAsync(user.Username, request.Email, userId);

            user.FirstName = request.FirstName;
            user.LastName = request.LastName;
            user.Email = request.Email;
            user.Phone = request.Phone;
            user.BirthDate = request.BirthDate;

            await SaveChangesAsync();
            return (await GetByIdAsync(userId))!;
        }

        public async Task ChangePasswordAsync(int userId, ChangePasswordRequest request)
        {
            var user = await _context.Users.FindAsync(userId) ?? throw new NotFoundException("User not found.");

            if (_passwordHasher.VerifyHashedPassword(user, user.PasswordHash, request.OldPassword) == PasswordVerificationResult.Failed)
                throw new BusinessException("The current password is incorrect.");
            if (request.OldPassword == request.NewPassword)
                throw new BusinessException("The new password must be different from the current one.");

            user.PasswordHash = _passwordHasher.HashPassword(user, request.NewPassword);
            await _context.SaveChangesAsync();
        }

        public async Task<AuthResponse> LoginAsync(UserLoginRequest request)
        {
            var user = await _context.Users
                .Include(u => u.UserRoles).ThenInclude(ur => ur.Role)
                .FirstOrDefaultAsync(u => u.Username == request.Username);

            if (user == null || _passwordHasher.VerifyHashedPassword(user, user.PasswordHash, request.Password) == PasswordVerificationResult.Failed)
                throw new InvalidCredentialsException();

            var role = user.UserRoles.FirstOrDefault()?.Role?.Name ?? Roles.User;
            var expires = DateTime.UtcNow.Add(TokenLifetime);

            return new AuthResponse
            {
                Token = GenerateJwtToken(user, role, expires),
                UserID = user.UserID,
                Username = user.Username,
                Role = role,
                ExpiresAt = expires
            };
        }

        public async Task RevokeTokenAsync(string jti, DateTime expiresAtUtc)
        {
            if (await _context.RevokedTokens.AnyAsync(r => r.Jti == jti))
                return;

            _context.RevokedTokens.Add(new RevokedToken { Jti = jti, ExpiresAtUtc = expiresAtUtc });
            await _context.SaveChangesAsync();
        }

        private string GenerateJwtToken(User user, string role, DateTime expires)
        {
            var jwtSection = _configuration.GetSection("Jwt");
            var securityKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(jwtSection["Key"]!));
            var credentials = new SigningCredentials(securityKey, SecurityAlgorithms.HmacSha256);

            var claims = new[]
            {
                new Claim(ClaimTypes.NameIdentifier, user.UserID.ToString()),
                new Claim(ClaimTypes.Name, user.Username),
                new Claim(ClaimTypes.Role, role),
                new Claim(JwtRegisteredClaimNames.Jti, Guid.NewGuid().ToString()),
            };

            var token = new JwtSecurityToken(
                issuer: jwtSection["Issuer"],
                audience: jwtSection["Audience"],
                claims: claims,
                expires: expires,
                signingCredentials: credentials);

            return new JwtSecurityTokenHandler().WriteToken(token);
        }

        private async Task EnsureUniqueAsync(string username, string email, int? exceptUserId)
        {
            if (await _context.Users.AnyAsync(u => u.Username == username && u.UserID != exceptUserId))
                throw new BusinessException("This username is already taken.");
            if (await _context.Users.AnyAsync(u => u.Email == email && u.UserID != exceptUserId))
                throw new BusinessException("This email address is already registered.");
        }

        private async Task EnsureRoleExistsAsync(int roleId)
        {
            if (!await _context.Roles.AnyAsync(r => r.RoleID == roleId))
                throw new BusinessException("Odabrana uloga ne postoji.");
        }

        private static void ValidateBirthDate(DateTime birthDate)
        {
            var today = DateTime.UtcNow.Date;
            if (birthDate.Date > today)
                throw new BusinessException("Date of birth cannot be in the future.");
            if (birthDate.Date > today.AddYears(-MinimumAge))
                throw new BusinessException($"The user must be at least {MinimumAge} years old.");
            if (birthDate.Year < 1900)
                throw new BusinessException("Enter a valid date of birth.");
        }
    }
}
