using F1Info_Tickets.Model.Requests;
using F1Info_Tickets.Model.Responses;
using F1Info_Tickets.Model.SearchObjects;
using F1Info_Tickets.Services.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace F1Info_Tickets.WebAPI.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class ResultController : BaseController<ResultResponse, ResultSearchObject>
    {
        private readonly IResultService _resultService;

        public ResultController(IResultService resultService) : base(resultService)
        {
            _resultService = resultService;
        }

        [HttpGet("race/{raceId}")]
        public async Task<ActionResult<RaceResultsResponse>> GetRaceResults(int raceId)
        {
            return Ok(await _resultService.GetRaceResultsAsync(raceId));
        }

        // Saves the whole classification of a race at once (allowed from the start until 48h after the race).
        [HttpPut("race/{raceId}")]
        [Authorize(Roles = "Admin")]
        public async Task<ActionResult<RaceResultsResponse>> SaveRaceResults(int raceId, [FromBody] RaceResultsSaveRequest request)
        {
            return Ok(await _resultService.SaveRaceResultsAsync(raceId, request));
        }

        [HttpGet("driver-standings/{seasonId}")]
        public async Task<ActionResult<List<DriverStandingResponse>>> GetDriverStandings(int seasonId)
        {
            return Ok(await _resultService.GetDriverStandingsBySeason(seasonId));
        }

        [HttpGet("team-standings/{seasonId}")]
        public async Task<ActionResult<List<TeamStandingResponse>>> GetTeamStandings(int seasonId)
        {
            return Ok(await _resultService.GetTeamStandingsAsync(seasonId));
        }
    }
}
