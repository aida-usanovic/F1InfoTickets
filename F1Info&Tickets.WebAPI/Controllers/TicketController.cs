using F1Info_Tickets.Model.Responses;
using F1Info_Tickets.Model.SearchObjects;
using F1Info_Tickets.Services.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace F1Info_Tickets.WebAPI.Controllers
{
    // Tickets are created by the payment flow; this controller only reads them.
    [ApiController]
    [Route("api/[controller]")]
    public class TicketController : BaseController<TicketResponse, TicketSearchObject>
    {
        public TicketController(ITicketService ticketService) : base(ticketService) { }

        [HttpGet]
        [Authorize(Roles = "Admin")]
        public override Task<ActionResult<PagedResult<TicketResponse>>> Get([FromQuery] TicketSearchObject search)
        {
            return base.Get(search);
        }

        [HttpGet("{id}")]
        public override async Task<ActionResult<TicketResponse>> GetById(int id)
        {
            var ticket = await _service.GetByIdAsync(id);
            if (ticket == null)
                return NotFound();

            if (!User.IsInRole("Admin") && ticket.UserID != GetCurrentUserId())
                return Forbid();

            return Ok(ticket);
        }

        [HttpGet("my")]
        public async Task<ActionResult<PagedResult<TicketResponse>>> GetMyTickets([FromQuery] TicketSearchObject search)
        {
            search.UserID = GetCurrentUserId();
            return Ok(await _service.GetAsync(search));
        }
    }
}
