using F1Info_Tickets.Model.Responses;
using F1Info_Tickets.Model.SearchObjects;
using F1Info_Tickets.Services.BaseInterfaces;

namespace F1Info_Tickets.Services.Interfaces
{
    // Tickets are created only by the payment flow, so the API exposes them read-only.
    public interface ITicketService : IService<TicketResponse, TicketSearchObject>
    {
    }
}
