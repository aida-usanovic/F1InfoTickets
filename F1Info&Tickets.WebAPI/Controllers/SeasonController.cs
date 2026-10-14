using F1Info_Tickets.Model.Requests;
using F1Info_Tickets.Model.Responses;
using F1Info_Tickets.Model.SearchObjects;
using F1Info_Tickets.Services.Interfaces;
using Microsoft.AspNetCore.Mvc;

namespace F1Info_Tickets.WebAPI.Controllers
{
    public class SeasonController : BaseCRUDController<SeasonResponse, SeasonSearchObject, SeasonUpsertRequest, SeasonUpsertRequest>
    {
        private readonly ISeasonService _seasonService;

        public SeasonController(ISeasonService seasonService) : base(seasonService)
        {
            _seasonService = seasonService;
        }

        // The season shown by default in standings: the latest one with results.
        [HttpGet("current")]
        public async Task<ActionResult<SeasonResponse>> GetCurrent()
        {
            var season = await _seasonService.GetCurrentSeasonAsync();
            return season == null ? NotFound(new { message = "No seasons have been entered." }) : Ok(season);
        }
    }
}
