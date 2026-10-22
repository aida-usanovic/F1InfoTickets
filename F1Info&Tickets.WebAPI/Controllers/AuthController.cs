using F1Info_Tickets.Model.Requests;
using F1Info_Tickets.Model.Responses;
using F1Info_Tickets.Services.Exceptions;
using F1Info_Tickets.Services.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;

namespace F1Info_Tickets.WebAPI.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class AuthController : ControllerBase
    {
        private readonly IUserService _userService;
        private readonly IPasswordResetService _passwordResetService;

        public AuthController(IUserService userService, IPasswordResetService passwordResetService)
        {
            _userService = userService;
            _passwordResetService = passwordResetService;
        }

        [HttpPost("login")]
        [AllowAnonymous]
        public async Task<ActionResult<AuthResponse>> Login([FromBody] UserLoginRequest request)
        {
            try
            {
                return Ok(await _userService.LoginAsync(request));
            }
            catch (InvalidCredentialsException ex)
            {
                return Unauthorized(new { message = ex.Message });
            }
        }

        // Customer self-registration from the mobile app; the role is always "User".
        [HttpPost("register")]
        [AllowAnonymous]
        public async Task<ActionResult<UserResponse>> Register([FromBody] UserInsertRequest request)
        {
            return Ok(await _userService.RegisterAsync(request));
        }

        // Forgotten password, step 1: emails a one-time code. The answer is the same for unknown addresses.
        [HttpPost("forgot-password")]
        [AllowAnonymous]
        public async Task<IActionResult> ForgotPassword([FromBody] ForgotPasswordRequest request)
        {
            await _passwordResetService.RequestCodeAsync(request);
            return Ok(new { message = "If this email is registered, a reset code has been sent to it." });
        }

        // Forgotten password, step 2: the code from the email and a new password.
        [HttpPost("reset-password")]
        [AllowAnonymous]
        public async Task<IActionResult> ResetPassword([FromBody] ResetPasswordRequest request)
        {
            await _passwordResetService.ResetPasswordAsync(request);
            return Ok(new { message = "Your password was reset. You can sign in now." });
        }

        [HttpPost("logout")]
        [Authorize]
        public async Task<IActionResult> Logout()
        {
            var jti = User.FindFirstValue(JwtRegisteredClaimNames.Jti);
            var expClaim = User.FindFirstValue(JwtRegisteredClaimNames.Exp);

            if (string.IsNullOrEmpty(jti))
                return BadRequest(new { message = "The token has no jti." });

            var expiresAt = long.TryParse(expClaim, out var expUnix)
                ? DateTimeOffset.FromUnixTimeSeconds(expUnix).UtcDateTime
                : DateTime.UtcNow.AddHours(8);

            await _userService.RevokeTokenAsync(jti, expiresAt);
            return Ok(new { message = "You have signed out." });
        }
    }
}
