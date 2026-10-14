using F1Info_Tickets.Model.Requests;
using F1Info_Tickets.Model.Responses;
using F1Info_Tickets.Model.SearchObjects;
using F1Info_Tickets.Services.BaseInterfaces;

namespace F1Info_Tickets.Services.Interfaces
{
    public interface ICircuitService : ICRUDService<CircuitResponse, CircuitSearchObject, CircuitUpsertRequest, CircuitUpsertRequest>
    {
    }
}
