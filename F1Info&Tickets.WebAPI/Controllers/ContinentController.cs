using F1Info_Tickets.Model.Requests;
using F1Info_Tickets.Model.Responses;
using F1Info_Tickets.Model.SearchObjects;
using F1Info_Tickets.Services.Interfaces;

namespace F1Info_Tickets.WebAPI.Controllers
{
    public class ContinentController : BaseCRUDController<ContinentResponse, ContinentSearchObject, ContinentUpsertRequest, ContinentUpsertRequest>
    {
        public ContinentController(IContinentService service) : base(service) { }
    }
}
