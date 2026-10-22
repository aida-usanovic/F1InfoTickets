using F1Info_Tickets.Model.Requests;
using F1Info_Tickets.Model.Responses;
using F1Info_Tickets.Services.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using System.Security.Claims;

namespace F1Info_Tickets.WebAPI.Controllers
{
    // The signed-in user's own account.
    [ApiController]
    [Route("api/[controller]")]
    [Authorize]
    public class ProfileController : ControllerBase
    {
        private readonly IUserService _userService;

        public ProfileController(IUserService userService)
        {
            _userService = userService;
        }

        [HttpGet]
        public async Task<ActionResult<UserResponse>> Get()
        {
            return Ok(await _userService.GetProfileAsync(GetCurrentUserId()));
        }

        [HttpPut]
        // Multipart form, because the request can contain a new profile photo.
        public async Task<ActionResult<UserResponse>> Update([FromForm] ProfileUpdateRequest request)
        {
            return Ok(await _userService.UpdateProfileAsync(GetCurrentUserId(), request));
        }

        [HttpPut("password")]
        public async Task<IActionResult> ChangePassword([FromBody] ChangePasswordRequest request)
        {
            await _userService.ChangePasswordAsync(GetCurrentUserId(), request);
            return Ok(new { message = "Your password was changed." });
        }

        private int GetCurrentUserId()
        {
            var value = User.FindFirstValue(ClaimTypes.NameIdentifier);
            if (!int.TryParse(value, out var userId))
                throw new UnauthorizedAccessException("Invalid user token.");
            return userId;
        }
    }
}
