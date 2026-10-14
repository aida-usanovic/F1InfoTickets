using F1Info_Tickets.Model.Dtos;
using F1Info_Tickets.Model.SearchObjects;
using F1Info_Tickets.Services.Database;
using F1Info_Tickets.Services.Interfaces;
using Microsoft.EntityFrameworkCore;

namespace F1Info_Tickets.Services.Services
{
    public class AnalyticsService : IAnalyticsService
    {
        private readonly ApplicationDbContext _context;

        public AnalyticsService(ApplicationDbContext context)
        {
            _context = context;
        }

        public async Task<DashboardDto> GetDashboardAsync()
        {
            var now = DateTime.UtcNow;
            var sold = _context.Tickets.Where(t => t.Status != TicketStatus.Refunded);
            return new DashboardDto
            {
                TotalUsers = await _context.Users.CountAsync(u => u.UserRoles.Any(ur => ur.Role.Name == Roles.User)),
                TotalDrivers = await _context.Drivers.CountAsync(),
                TicketsSold = await sold.CountAsync(),
                TotalRevenue = await sold.SumAsync(t => (decimal?)t.Price) ?? 0,
                UpcomingRaces = await _context.Races.CountAsync(r => r.Date > now)
            };
        }

        public async Task<List<SalesAnalyticsDto>> GetTicketSalesReport(AnalyticsFilter filter)
        {
            return await SoldTickets(filter)
                .GroupBy(t => new { t.RaceTicketCategory.RaceID, t.RaceTicketCategory.Race.RaceName, t.RaceTicketCategory.Race.Date })
                .OrderBy(g => g.Key.Date)
                .Select(g => new SalesAnalyticsDto
                {
                    RaceId = g.Key.RaceID,
                    RaceName = g.Key.RaceName,
                    RaceDate = g.Key.Date,
                    TicketsSold = g.Count(),
                    TotalRevenue = g.Sum(x => x.Price)
                })
                .ToListAsync();
        }

        public async Task<List<TicketTypeSalesDto>> GetTicketTypeSalesReport(AnalyticsFilter filter)
        {
            return await SoldTickets(filter)
                .GroupBy(t => t.RaceTicketCategory.TicketType.Name)
                .Select(g => new TicketTypeSalesDto
                {
                    TicketType = g.Key,
                    TicketsSold = g.Count(),
                    TotalRevenue = g.Sum(x => x.Price)
                })
                .OrderByDescending(x => x.TotalRevenue)
                .ToListAsync();
        }

        public async Task<List<RaceAttendanceDto>> GetRaceAttendanceReport(AnalyticsFilter filter)
        {
            var races = _context.Races.AsQueryable();
            if (filter.SeasonID != null)
                races = races.Where(r => r.SeasonID == filter.SeasonID);
            if (filter.DateFrom != null)
                races = races.Where(r => r.Date >= filter.DateFrom);
            if (filter.DateTo != null)
                races = races.Where(r => r.Date < filter.DateTo.Value.Date.AddDays(1));

            var rows = await races
                .OrderBy(r => r.Date)
                .Select(r => new RaceAttendanceDto
                {
                    RaceId = r.RaceID,
                    RaceName = r.RaceName,
                    RaceDate = r.Date,
                    Capacity = r.TicketCategories.Sum(c => c.Capacity),
                    TicketsSold = r.TicketCategories.SelectMany(c => c.Tickets).Count(t => t.Status != TicketStatus.Refunded)
                })
                .ToListAsync();

            foreach (var row in rows)
                row.OccupancyPercent = row.Capacity > 0 ? Math.Round(100.0 * row.TicketsSold / row.Capacity, 1) : 0;
            return rows;
        }

        public async Task<UserActivityDto> GetUserActivityReport(AnalyticsFilter filter)
        {
            var tickets = SoldTickets(filter);
            var views = _context.RaceViews.AsQueryable();
            if (filter.DateFrom != null)
                views = views.Where(v => v.ViewedAt >= filter.DateFrom);
            if (filter.DateTo != null)
                views = views.Where(v => v.ViewedAt < filter.DateTo.Value.Date.AddDays(1));
            if (filter.SeasonID != null)
                views = views.Where(v => v.Race.SeasonID == filter.SeasonID);

            var viewsPerUser = await views.GroupBy(v => v.UserID).Select(g => new { g.Key, Count = g.Count() })
                .ToDictionaryAsync(x => x.Key, x => x.Count);

            var customers = await tickets
                .GroupBy(t => new { t.UserID, t.User.Username, t.User.FirstName, t.User.LastName })
                .Select(g => new CustomerActivityDto
                {
                    Username = g.Key.Username,
                    FullName = g.Key.FirstName + " " + g.Key.LastName,
                    TicketsPurchased = g.Count(),
                    TotalSpent = g.Sum(x => x.Price),
                    LastPurchase = g.Max(x => x.PurchaseDate)
                })
                .OrderByDescending(x => x.TotalSpent)
                .ToListAsync();

            var userIds = await _context.Users.Where(u => customers.Select(c => c.Username).Contains(u.Username))
                .ToDictionaryAsync(u => u.Username, u => u.UserID);
            foreach (var c in customers)
                c.RaceViews = viewsPerUser.GetValueOrDefault(userIds[c.Username]);

            return new UserActivityDto
            {
                TotalUsersRegistered = await _context.Users.CountAsync(u => u.UserRoles.Any(ur => ur.Role.Name == Roles.User)),
                ActiveBuyers = customers.Count,
                TotalTicketsPurchased = customers.Sum(c => c.TicketsPurchased),
                TotalRevenue = customers.Sum(c => c.TotalSpent),
                RaceViews = viewsPerUser.Values.Sum(),
                TopCustomers = customers.Take(10).ToList()
            };
        }

        private IQueryable<Ticket> SoldTickets(AnalyticsFilter filter)
        {
            var query = _context.Tickets.Where(t => t.Status != TicketStatus.Refunded);
            if (filter.SeasonID != null)
                query = query.Where(t => t.RaceTicketCategory.Race.SeasonID == filter.SeasonID);
            if (filter.DateFrom != null)
                query = query.Where(t => t.PurchaseDate >= filter.DateFrom);
            if (filter.DateTo != null)
                query = query.Where(t => t.PurchaseDate < filter.DateTo.Value.Date.AddDays(1));
            return query;
        }
    }
}
