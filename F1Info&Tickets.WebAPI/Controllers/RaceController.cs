using F1Info_Tickets.Model.Requests;
using F1Info_Tickets.Model.Responses;
using F1Info_Tickets.Model.SearchObjects;
using F1Info_Tickets.Services.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace F1Info_Tickets.WebAPI.Controllers
{
    [ApiController]
    public class RaceController : BaseCRUDController<RaceResponse,RaceSearchObject,RaceInsertRequest,RaceUpdateRequest>
    {
        private readonly IRaceService _raceService;
        public RaceController(IRaceService raceService) : base(raceService) 
        { 
            _raceService = raceService;
        }

        [HttpGet("season/{seasonId}")]
        public async Task<ActionResult<List<RaceResponse>>> GetRacesBySeason(int seasonId)
        {
            var result = await _raceService.GetRacesBySeason(seasonId);
            return Ok(result);
        }

        // Called by the mobile app when a customer opens race details; feeds the recommender.
        [HttpPost("{id}/view")]
        [Authorize(Roles = "User")]
        public async Task<IActionResult> RecordView(int id)
        {
            await _raceService.RecordViewAsync(GetCurrentUserId(), id);
            return NoContent();
        }

        [HttpGet("upcoming")]
        public async Task<ActionResult<List<RaceResponse>>> GetUpcomingRaces()
        {
            var result = await _raceService.GetUpcomingRaces();
            return Ok(result);
        }
    }
}

