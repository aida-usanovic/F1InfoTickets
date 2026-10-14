using F1Info_Tickets.Model.Requests;
using F1Info_Tickets.Model.Responses;
using F1Info_Tickets.Model.SearchObjects;
using F1Info_Tickets.Services.BaseServices;
using F1Info_Tickets.Services.Database;
using F1Info_Tickets.Services.Interfaces;
using MapsterMapper;
using Microsoft.EntityFrameworkCore;

namespace F1Info_Tickets.Services.Services
{
    public class CircuitService : BaseCRUDService<Circuit, CircuitResponse, CircuitSearchObject, CircuitUpsertRequest, CircuitUpsertRequest>, ICircuitService
    {
        public CircuitService(ApplicationDbContext context, IMapper mapper) : base(context, mapper) { }

        protected override IQueryable<Circuit> AddInclude(IQueryable<Circuit> query)
        {
            return query
                .Include(x => x.City).ThenInclude(c => c.Country).ThenInclude(c => c.Continent)
                .Include(x => x.TrackType);
        }

        protected override IQueryable<Circuit> AddFilter(IQueryable<Circuit> query, CircuitSearchObject? search)
        {
            if (!string.IsNullOrWhiteSpace(search?.SearchTerm))
                query = query.Where(x => x.Name.Contains(search.SearchTerm) || x.City.Name.Contains(search.SearchTerm) || x.City.Country.Name.Contains(search.SearchTerm));
            if (search?.CountryID != null)
                query = query.Where(x => x.City.CountryID == search.CountryID);
            if (search?.TrackTypeID != null)
                query = query.Where(x => x.TrackTypeID == search.TrackTypeID);
            return query;
        }

        protected override IQueryable<Circuit> ApplyOrder(IQueryable<Circuit> query) => query.OrderBy(x => x.Name);
    }
}
