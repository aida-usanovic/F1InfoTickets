using F1Info_Tickets.Services.Database;
using Microsoft.EntityFrameworkCore;

namespace F1Info_Tickets.Services.Helpers
{
    // Includes shared by every place that maps races or tickets to responses.
    public static class QueryExtensions
    {
        public static IQueryable<Race> IncludeRaceDetails(this IQueryable<Race> query)
        {
            return query
                .Include(r => r.Season)
                .Include(r => r.Circuit).ThenInclude(c => c.City).ThenInclude(c => c.Country).ThenInclude(c => c.Continent)
                .Include(r => r.Circuit).ThenInclude(c => c.TrackType)
                .Include(r => r.TicketCategories);
        }

        public static IQueryable<Ticket> IncludeTicketDetails(this IQueryable<Ticket> query)
        {
            return query
                .Include(t => t.User)
                .Include(t => t.Payment)
                .Include(t => t.RaceTicketCategory).ThenInclude(c => c.TicketType)
                .Include(t => t.RaceTicketCategory).ThenInclude(c => c.Race).ThenInclude(r => r.Circuit);
        }

        public static IQueryable<Ticket> NotRefunded(this IQueryable<Ticket> query)
        {
            return query.Where(t => t.Status != TicketStatus.Refunded);
        }
    }
}
