using F1Info_Tickets.Model.Responses;
using F1Info_Tickets.Model.SearchObjects;
using F1Info_Tickets.Services.BaseServices;
using F1Info_Tickets.Services.Database;
using F1Info_Tickets.Services.Helpers;
using F1Info_Tickets.Services.Interfaces;
using MapsterMapper;

namespace F1Info_Tickets.Services.Services
{
    public class TicketService : BaseService<Ticket, TicketResponse, TicketSearchObject>, ITicketService
    {
        public TicketService(ApplicationDbContext context, IMapper mapper) : base(context, mapper) { }

        protected override IQueryable<Ticket> AddInclude(IQueryable<Ticket> query) => query.IncludeTicketDetails();

        protected override IQueryable<Ticket> AddFilter(IQueryable<Ticket> query, TicketSearchObject? search)
        {
            if (search == null) return query;

            if (!string.IsNullOrWhiteSpace(search.SearchTerm))
                query = query.Where(t => t.User.Username.Contains(search.SearchTerm)
                    || (t.User.FirstName + " " + t.User.LastName).Contains(search.SearchTerm)
                    || t.RaceTicketCategory.Race.RaceName.Contains(search.SearchTerm));
            if (search.UserID != null)
                query = query.Where(t => t.UserID == search.UserID);
            if (search.RaceID != null)
                query = query.Where(t => t.RaceTicketCategory.RaceID == search.RaceID);
            if (search.TicketTypeID != null)
                query = query.Where(t => t.RaceTicketCategory.TicketTypeID == search.TicketTypeID);
            if (search.PurchaseDateFrom != null)
                query = query.Where(t => t.PurchaseDate >= search.PurchaseDateFrom);
            if (search.PurchaseDateTo != null)
                query = query.Where(t => t.PurchaseDate < search.PurchaseDateTo.Value.Date.AddDays(1));

            return query;
        }

        protected override IQueryable<Ticket> ApplyOrder(IQueryable<Ticket> query) => query.OrderByDescending(t => t.PurchaseDate);
    }
}
