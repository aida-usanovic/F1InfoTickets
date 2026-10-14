using F1Info_Tickets.Model.Requests;
using F1Info_Tickets.Model.Responses;
using F1Info_Tickets.Model.SearchObjects;
using F1Info_Tickets.Services.Interfaces;

namespace F1Info_Tickets.WebAPI.Controllers
{
    // Ticket offers per race: admins manage them, customers browse them.
    public class RaceTicketCategoryController : BaseCRUDController<RaceTicketCategoryResponse, RaceTicketCategorySearchObject, RaceTicketCategoryUpsertRequest, RaceTicketCategoryUpsertRequest>
    {
        public RaceTicketCategoryController(IRaceTicketCategoryService service) : base(service) { }
    }
}
