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
    public class CountryService : BaseCRUDService<Country, CountryResponse, CountrySearchObject, CountryUpsertRequest, CountryUpsertRequest>, ICountryService
    {
        public CountryService(ApplicationDbContext context, IMapper mapper) : base(context, mapper) { }

        protected override IQueryable<Country> AddInclude(IQueryable<Country> query) => query.Include(x => x.Continent);

        protected override IQueryable<Country> AddFilter(IQueryable<Country> query, CountrySearchObject? search)
        {
            if (!string.IsNullOrWhiteSpace(search?.SearchTerm))
                query = query.Where(x => x.Name.Contains(search.SearchTerm) || x.Code.Contains(search.SearchTerm));
            if (search?.ContinentID != null)
                query = query.Where(x => x.ContinentID == search.ContinentID);
            return query;
        }

        protected override IQueryable<Country> ApplyOrder(IQueryable<Country> query) => query.OrderBy(x => x.Name);

        protected override Task BeforeInsert(Country entity, CountryUpsertRequest request)
        {
            entity.Code = entity.Code.ToUpperInvariant();
            return Task.CompletedTask;
        }

        protected override Task BeforeUpdate(Country entity, CountryUpsertRequest request)
        {
            entity.Code = entity.Code.ToUpperInvariant();
            return Task.CompletedTask;
        }
    }
}
