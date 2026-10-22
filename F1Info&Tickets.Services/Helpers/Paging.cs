using F1Info_Tickets.Model.Responses;
using F1Info_Tickets.Model.SearchObjects;
using Microsoft.EntityFrameworkCore;

namespace F1Info_Tickets.Services.Helpers
{
    public static class Paging
    {
        // Pages an ordered query in the database.
        public static async Task<PagedResult<T>> ToPagedResultAsync<T>(this IQueryable<T> query, PageRequest request)
        {
            var (page, pageSize) = Normalize(request);
            return new PagedResult<T>
            {
                TotalCount = await query.CountAsync(),
                Page = page,
                PageSize = pageSize,
                Items = await query.Skip((page - 1) * pageSize).Take(pageSize).ToListAsync()
            };
        }

        // Pages a list computed in memory (e.g. standings, where positions need the whole list).
        public static PagedResult<T> ToPagedResult<T>(this IReadOnlyCollection<T> items, PageRequest request)
        {
            var (page, pageSize) = Normalize(request);
            return new PagedResult<T>
            {
                TotalCount = items.Count,
                Page = page,
                PageSize = pageSize,
                Items = items.Skip((page - 1) * pageSize).Take(pageSize).ToList()
            };
        }

        public static PagedResult<TOut> MapItems<TIn, TOut>(this PagedResult<TIn> result, Func<List<TIn>, List<TOut>> map) => new()
        {
            TotalCount = result.TotalCount,
            Page = result.Page,
            PageSize = result.PageSize,
            Items = map(result.Items)
        };

        public static (int Page, int PageSize) Normalize(PageRequest request) =>
            (Math.Max(1, request.Page), request.PageSize <= 0 ? 10 : Math.Min(request.PageSize, PageRequest.MaxPageSize));
    }
}
