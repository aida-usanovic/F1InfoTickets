using F1Info_Tickets.Model.Responses;
using F1Info_Tickets.Model.SearchObjects;
using F1Info_Tickets.Services.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using System.Security.Claims;

namespace F1Info_Tickets.WebAPI.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    [Authorize(Roles = "User")]
    public class FavoriteController : ControllerBase
    {
        private readonly IFavoriteService _favoriteService;

        public FavoriteController(IFavoriteService favoriteService)
        {
            _favoriteService = favoriteService;
        }

        [HttpGet("drivers")]
        public async Task<ActionResult<PagedResult<DriverResponse>>> GetDrivers([FromQuery] PageRequest paging)
        {
            return Ok(await _favoriteService.GetDriversAsync(GetCurrentUserId(), paging));
        }

        // Whether one driver is a favourite (the driver page needs only this, not the whole list).
        [HttpGet("drivers/{driverId}")]
        public async Task<ActionResult<FavoriteStatusResponse>> IsFavoriteDriver(int driverId)
        {
            return Ok(new FavoriteStatusResponse { IsFavorite = await _favoriteService.IsFavoriteDriverAsync(GetCurrentUserId(), driverId) });
        }

        [HttpPost("drivers/{driverId}")]
        public async Task<IActionResult> AddDriver(int driverId)
        {
            await _favoriteService.AddDriverAsync(GetCurrentUserId(), driverId);
            return NoContent();
        }

        [HttpDelete("drivers/{driverId}")]
        public async Task<IActionResult> RemoveDriver(int driverId)
        {
            await _favoriteService.RemoveDriverAsync(GetCurrentUserId(), driverId);
            return NoContent();
        }

        [HttpGet("teams")]
        public async Task<ActionResult<PagedResult<TeamResponse>>> GetTeams([FromQuery] PageRequest paging)
        {
            return Ok(await _favoriteService.GetTeamsAsync(GetCurrentUserId(), paging));
        }

        [HttpGet("teams/{teamId}")]
        public async Task<ActionResult<FavoriteStatusResponse>> IsFavoriteTeam(int teamId)
        {
            return Ok(new FavoriteStatusResponse { IsFavorite = await _favoriteService.IsFavoriteTeamAsync(GetCurrentUserId(), teamId) });
        }

        [HttpPost("teams/{teamId}")]
        public async Task<IActionResult> AddTeam(int teamId)
        {
            await _favoriteService.AddTeamAsync(GetCurrentUserId(), teamId);
            return NoContent();
        }

        [HttpDelete("teams/{teamId}")]
        public async Task<IActionResult> RemoveTeam(int teamId)
        {
            await _favoriteService.RemoveTeamAsync(GetCurrentUserId(), teamId);
            return NoContent();
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
