using F1Info_Tickets.Model.Requests;
using F1Info_Tickets.Model.Responses;
using F1Info_Tickets.Model.SearchObjects;
using F1Info_Tickets.Services.BaseServices;
using F1Info_Tickets.Services.Database;
using F1Info_Tickets.Services.Interfaces;
using MapsterMapper;

namespace F1Info_Tickets.Services.Services
{
    public class ContinentService : BaseCRUDService<Continent, ContinentResponse, ContinentSearchObject, ContinentUpsertRequest, ContinentUpsertRequest>, IContinentService
    {
        public ContinentService(ApplicationDbContext context, IMapper mapper) : base(context, mapper) { }

        protected override IQueryable<Continent> AddFilter(IQueryable<Continent> query, ContinentSearchObject? search)
        {
            if (!string.IsNullOrWhiteSpace(search?.SearchTerm))
                query = query.Where(x => x.Name.Contains(search.SearchTerm));
            return query;
        }

        protected override IQueryable<Continent> ApplyOrder(IQueryable<Continent> query) => query.OrderBy(x => x.Name);
    }
}
