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
    public class CityService : BaseCRUDService<City, CityResponse, CitySearchObject, CityUpsertRequest, CityUpsertRequest>, ICityService
    {
        public CityService(ApplicationDbContext context, IMapper mapper) : base(context, mapper) { }

        protected override IQueryable<City> AddInclude(IQueryable<City> query) => query.Include(x => x.Country);

        protected override IQueryable<City> AddFilter(IQueryable<City> query, CitySearchObject? search)
        {
            if (!string.IsNullOrWhiteSpace(search?.SearchTerm))
                query = query.Where(x => x.Name.Contains(search.SearchTerm) || x.Country.Name.Contains(search.SearchTerm));
            if (search?.CountryID != null)
                query = query.Where(x => x.CountryID == search.CountryID);
            return query;
        }

        protected override IQueryable<City> ApplyOrder(IQueryable<City> query) => query.OrderBy(x => x.Name);
    }
}
