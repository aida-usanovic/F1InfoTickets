using F1Info_Tickets.Model.Requests;
using F1Info_Tickets.Model.Responses;
using F1Info_Tickets.Model.SearchObjects;
using F1Info_Tickets.Services.Interfaces;

namespace F1Info_Tickets.WebAPI.Controllers
{
    public class TicketTypeController : BaseCRUDController<TicketTypeResponse, TicketTypeSearchObject, TicketTypeUpsertRequest, TicketTypeUpsertRequest>
    {
        public TicketTypeController(ITicketTypeService service) : base(service) { }
    }
}
