using F1Info_Tickets.Model.Requests;
using F1Info_Tickets.Model.Responses;
using F1Info_Tickets.Model.SearchObjects;
using F1Info_Tickets.Services.Interfaces;

namespace F1Info_Tickets.WebAPI.Controllers
{
    public class TrackTypeController : BaseCRUDController<TrackTypeResponse, TrackTypeSearchObject, TrackTypeUpsertRequest, TrackTypeUpsertRequest>
    {
        public TrackTypeController(ITrackTypeService service) : base(service) { }
    }
}
