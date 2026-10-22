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

            // A customer's own tickets (UserID set) are searched by race, circuit and country; the admin list also by customer.
            if (!string.IsNullOrWhiteSpace(search.SearchTerm))
                query = query.Where(t => t.RaceTicketCategory.Race.RaceName.Contains(search.SearchTerm)
                    || t.RaceTicketCategory.Race.Circuit.Name.Contains(search.SearchTerm)
                    || t.RaceTicketCategory.Race.Circuit.City.Country.Name.Contains(search.SearchTerm)
                    || (search.UserID == null && (t.User.Username.Contains(search.SearchTerm)
                        || (t.User.FirstName + " " + t.User.LastName).Contains(search.SearchTerm))));
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
            if (search.Upcoming == true)
                query = query.Where(t => t.RaceTicketCategory.Race.Date > DateTime.UtcNow);
            if (search.Upcoming == false)
                query = query.Where(t => t.RaceTicketCategory.Race.Date <= DateTime.UtcNow);

            return query;
        }

        // Upcoming tickets: the nearest race first; past tickets: the latest race first; otherwise the latest purchase first.
        protected override IQueryable<Ticket> ApplyOrder(IQueryable<Ticket> query, TicketSearchObject? search) => search?.Upcoming switch
        {
            true => query.OrderBy(t => t.RaceTicketCategory.Race.Date).ThenBy(t => t.TicketID),
            false => query.OrderByDescending(t => t.RaceTicketCategory.Race.Date).ThenBy(t => t.TicketID),
            _ => query.OrderByDescending(t => t.PurchaseDate).ThenByDescending(t => t.TicketID)
        };
    }
}
