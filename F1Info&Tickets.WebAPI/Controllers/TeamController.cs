using F1Info_Tickets.Model.Requests;
using F1Info_Tickets.Model.Responses;
using F1Info_Tickets.Model.SearchObjects;
using F1Info_Tickets.Services.Database;
using F1Info_Tickets.Services.Interfaces;
using F1Info_Tickets.Services.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace F1Info_Tickets.WebAPI.Controllers
{
    public class TeamController : BaseCRUDController<TeamResponse, TeamSearchObject, TeamUpsertRequest, TeamUpsertRequest>
    {
        private readonly ITeamService _teamService;
        public TeamController(ITeamService teamService) : base(teamService)
        {
            _teamService = teamService;
        }

        [HttpPost]
        [Authorize(Roles = "Admin")]
        public override async Task<ActionResult<TeamResponse>> Insert([FromForm] TeamUpsertRequest request)
        {
            var result = await _teamService.InsertAsync(request);
            return Ok(result);
        }

        [HttpPut("{id}")]
        [Authorize(Roles = "Admin")]
        public override async Task<ActionResult<TeamResponse>> Update(int id, [FromForm] TeamUpsertRequest request)
        {
            var result = await _teamService.UpdateAsync(id, request);

            if (result == null)
                return NotFound();

            return Ok(result);
        }

        [HttpPost("{teamId}/add-driver/{driverId}/{seasonId}")]
        [Authorize(Roles = "Admin")]
        public async Task<ActionResult> AddDriverToTeam(int teamId, int driverId, int seasonId)
        {
            await _teamService.AddDriverToTeam(teamId, driverId, seasonId);
            return Ok();
        }

        [HttpDelete("{teamId}/remove-driver/{driverId}/{seasonId}")]
        [Authorize(Roles = "Admin")]
        public async Task<ActionResult> RemoveDriverFromTeam(int teamId, int driverId, int seasonId)
        {
            await _teamService.RemoveDriverFromTeam(teamId, driverId, seasonId);
            return Ok();
        }

        [HttpGet("{teamId}/details")]
        public async Task<ActionResult<TeamDetailsResponse>> GetTeamDetails(int teamId, [FromQuery] int? seasonId)
        {
            return Ok(await _teamService.GetTeamDetailsAsync(teamId, seasonId));
        }

        [HttpGet("driver/{driverId}/current-team/{seasonId}")]
        public async Task<ActionResult<int?>> GetCurrentTeamForDriver(int driverId, int seasonId)
        {
            var teamId = await _teamService.GetCurrentTeamIdForDriverAsync(driverId, seasonId);
            return Ok(teamId);
        }
    }
}


