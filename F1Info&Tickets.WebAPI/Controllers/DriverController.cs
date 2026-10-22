using F1Info_Tickets.Model.Requests;
using F1Info_Tickets.Model.Responses;
using F1Info_Tickets.Model.SearchObjects;
using F1Info_Tickets.Services.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace F1Info_Tickets.WebAPI.Controllers
{
    [ApiController]
    public class DriverController : BaseCRUDController<DriverResponse, DriverSearchObject, DriverInsertRequest, DriverUpdateRequest>
    {
        private readonly IDriverService _driverService;
        public DriverController(IDriverService driverService) : base(driverService) 
        {
            _driverService = driverService;
        }

        [HttpPost]
        [Authorize(Roles = "Admin")]
        public override async Task<ActionResult<DriverResponse>> Insert([FromForm] DriverInsertRequest request)
        {
            var result = await _driverService.InsertAsync(request);
            return Ok(result);
        }

        [HttpPut("{id}")]
        [Authorize(Roles = "Admin")]
        public override async Task<ActionResult<DriverResponse>> Update(int id, [FromForm] DriverUpdateRequest request)
        {
            var result = await _driverService.UpdateAsync(id, request);

            if (result == null)
                return NotFound();

            return Ok(result);
        }

        [HttpGet("{id}/stats")]
        public async Task<ActionResult<DriverStatsResponse>> GetStats(int id)
        {
            return Ok(await _driverService.GetStatsAsync(id));
        }

        [HttpGet("season/{seasonId}")]
        public async Task<ActionResult<PagedResult<DriverResponse>>> GetActiveDriversBySeason(int seasonId, [FromQuery] PageRequest paging)
        {
            var result = await _driverService.GetActiveDriversBySeason(seasonId, paging);
            return Ok(result);
        }

        [HttpGet("{driverId}/team-in-season/{seasonId}")]
        public async Task<ActionResult<int>> GetDriverTeamId(int driverId, int seasonId)
        {
            var teamId = await _driverService.GetDriverTeamId(driverId, seasonId);
            if (teamId == null) return NotFound("The driver has no team assigned for this season.");
            return Ok(teamId);
        }

        [HttpGet("team/{teamId}/season/{seasonId}")]
        public async Task<ActionResult<PagedResult<DriverResponse>>> GetDriversByTeamAndSeason(int teamId, int seasonId, [FromQuery] PageRequest paging)
        {
            var result = await _driverService.GetDriversByTeamAndSeason(teamId, seasonId, paging);
            return Ok(result);
        }
    }
}


