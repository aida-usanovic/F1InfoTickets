using F1Info_Tickets.Model.Requests;
using F1Info_Tickets.Model.Responses;
using F1Info_Tickets.Model.SearchObjects;
using F1Info_Tickets.Services.BaseServices;
using F1Info_Tickets.Services.Database;
using F1Info_Tickets.Services.Interfaces;
using MapsterMapper;

namespace F1Info_Tickets.Services.Services
{
    public class TicketTypeService : BaseCRUDService<TicketType, TicketTypeResponse, TicketTypeSearchObject, TicketTypeUpsertRequest, TicketTypeUpsertRequest>, ITicketTypeService
    {
        public TicketTypeService(ApplicationDbContext context, IMapper mapper) : base(context, mapper) { }

        protected override IQueryable<TicketType> AddFilter(IQueryable<TicketType> query, TicketTypeSearchObject? search)
        {
            if (!string.IsNullOrWhiteSpace(search?.SearchTerm))
                query = query.Where(x => x.Name.Contains(search.SearchTerm));
            return query;
        }

        protected override IQueryable<TicketType> ApplyOrder(IQueryable<TicketType> query) => query.OrderBy(x => x.Name);
    }
}
