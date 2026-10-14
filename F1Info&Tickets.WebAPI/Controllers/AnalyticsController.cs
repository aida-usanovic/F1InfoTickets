using F1Info_Tickets.Model.Dtos;
using F1Info_Tickets.Model.SearchObjects;
using F1Info_Tickets.Services.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace F1Info_Tickets.WebAPI.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    [Authorize(Roles = "Admin")]
    public class AnalyticsController : ControllerBase
    {
        private readonly IAnalyticsService _analyticsService;

        public AnalyticsController(IAnalyticsService analyticsService)
        {
            _analyticsService = analyticsService;
        }

        [HttpGet("dashboard")]
        public async Task<ActionResult<DashboardDto>> GetDashboard()
        {
            return Ok(await _analyticsService.GetDashboardAsync());
        }

        [HttpGet("ticket-sales")]
        public async Task<ActionResult<List<SalesAnalyticsDto>>> GetTicketSalesReport([FromQuery] AnalyticsFilter filter)
        {
            return Ok(await _analyticsService.GetTicketSalesReport(filter));
        }

        [HttpGet("ticket-type-sales")]
        public async Task<ActionResult<List<TicketTypeSalesDto>>> GetTicketTypeSalesReport([FromQuery] AnalyticsFilter filter)
        {
            return Ok(await _analyticsService.GetTicketTypeSalesReport(filter));
        }

        [HttpGet("attendance")]
        public async Task<ActionResult<List<RaceAttendanceDto>>> GetRaceAttendanceReport([FromQuery] AnalyticsFilter filter)
        {
            return Ok(await _analyticsService.GetRaceAttendanceReport(filter));
        }

        [HttpGet("user-activity")]
        public async Task<ActionResult<UserActivityDto>> GetUserActivityReport([FromQuery] AnalyticsFilter filter)
        {
            return Ok(await _analyticsService.GetUserActivityReport(filter));
        }
    }
}
