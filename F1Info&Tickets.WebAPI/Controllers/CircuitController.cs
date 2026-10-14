using F1Info_Tickets.Model.Requests;
using F1Info_Tickets.Model.Responses;
using F1Info_Tickets.Model.SearchObjects;
using F1Info_Tickets.Services.Interfaces;

namespace F1Info_Tickets.WebAPI.Controllers
{
    public class CircuitController : BaseCRUDController<CircuitResponse, CircuitSearchObject, CircuitUpsertRequest, CircuitUpsertRequest>
    {
        public CircuitController(ICircuitService service) : base(service) { }
    }
}
