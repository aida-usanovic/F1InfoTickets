using F1Info_Tickets.Model.Requests;
using F1Info_Tickets.Model.Responses;
using F1Info_Tickets.Model.SearchObjects;
using F1Info_Tickets.Services.BaseServices;
using F1Info_Tickets.Services.Database;
using F1Info_Tickets.Services.Interfaces;
using MapsterMapper;

namespace F1Info_Tickets.Services.Services
{
    public class TrackTypeService : BaseCRUDService<TrackType, TrackTypeResponse, TrackTypeSearchObject, TrackTypeUpsertRequest, TrackTypeUpsertRequest>, ITrackTypeService
    {
        public TrackTypeService(ApplicationDbContext context, IMapper mapper) : base(context, mapper) { }

        protected override IQueryable<TrackType> AddFilter(IQueryable<TrackType> query, TrackTypeSearchObject? search)
        {
            if (!string.IsNullOrWhiteSpace(search?.SearchTerm))
                query = query.Where(x => x.Name.Contains(search.SearchTerm));
            return query;
        }

        protected override IQueryable<TrackType> ApplyOrder(IQueryable<TrackType> query) => query.OrderBy(x => x.Name);
    }
}
