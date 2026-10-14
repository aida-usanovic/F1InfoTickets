using F1Info_Tickets.Model.Responses;
using F1Info_Tickets.Model.SearchObjects;
using F1Info_Tickets.Services.BaseInterfaces;
using MapsterMapper;
using Microsoft.EntityFrameworkCore;

namespace F1Info_Tickets.Services.BaseServices
{
    public class BaseService<TDb, TResponse, TSearch> : IService<TResponse, TSearch>
    where TDb : class
    {
        protected readonly ApplicationDbContext _context;
        protected readonly IMapper _mapper;

        public BaseService(ApplicationDbContext context, IMapper mapper)
        {
            _context = context;
            _mapper = mapper;
        }

        // Navigation properties the response needs (names of the city, country, ...).
        protected virtual IQueryable<TDb> AddInclude(IQueryable<TDb> query)
        {
            return query;
        }

        protected virtual IQueryable<TDb> AddFilter(IQueryable<TDb> query, TSearch? search)
        {
            return query;
        }

        protected virtual IQueryable<TDb> ApplyOrder(IQueryable<TDb> query)
        {
            return query;
        }

        public virtual async Task<PagedResult<TResponse>> GetAsync(TSearch search)
        {
            var query = AddInclude(_context.Set<TDb>().AsQueryable());
            query = AddFilter(query, search);

            var totalCount = await query.CountAsync();

            int page = 1;
            int pageSize = 10;
            const int maxPageSize = 100;

            if (search is BaseSearchObject baseSearch)
            {
                page = baseSearch.Page > 0 ? baseSearch.Page : 1;
                pageSize = baseSearch.PageSize > 0 ? baseSearch.PageSize : 10;
                pageSize = Math.Min(pageSize, maxPageSize);
            }

            var items = await ApplyOrder(query)
                .Skip((page - 1) * pageSize)
                .Take(pageSize)
                .ToListAsync();

            return new PagedResult<TResponse>
            {
                TotalCount = totalCount,
                Page = page,
                PageSize = pageSize,
                Items = _mapper.Map<List<TResponse>>(items)
            };
        }

        public virtual async Task<TResponse?> GetByIdAsync(int id)
        {
            var entity = await FindWithIncludesAsync(id);
            return entity == null ? default : _mapper.Map<TResponse>(entity);
        }

        protected Task<TDb?> FindWithIncludesAsync(int id)
        {
            var keyName = _context.Model.FindEntityType(typeof(TDb))!.FindPrimaryKey()!.Properties[0].Name;
            return AddInclude(_context.Set<TDb>().AsQueryable())
                .FirstOrDefaultAsync(e => EF.Property<int>(e, keyName) == id);
        }

        protected int GetKey(TDb entity)
        {
            var keyName = _context.Model.FindEntityType(typeof(TDb))!.FindPrimaryKey()!.Properties[0].Name;
            return (int)_context.Entry(entity).Property(keyName).CurrentValue!;
        }
    }
}
