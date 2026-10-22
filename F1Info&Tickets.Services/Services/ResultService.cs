using F1Info_Tickets.Model.Requests;
using F1Info_Tickets.Model.Responses;
using F1Info_Tickets.Model.SearchObjects;
using F1Info_Tickets.Services.BaseServices;
using F1Info_Tickets.Services.Database;
using F1Info_Tickets.Services.Exceptions;
using F1Info_Tickets.Services.Helpers;
using F1Info_Tickets.Services.Interfaces;
using MapsterMapper;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;

namespace F1Info_Tickets.Services.Services
{
    public class ResultService : BaseService<Result, ResultResponse, ResultSearchObject>, IResultService
    {
        private static readonly double[] PointsTable = { 25, 18, 15, 12, 10, 8, 6, 4, 2, 1 };
        private static readonly TimeSpan EditWindow = TimeSpan.FromHours(48);

        private readonly IMessageProducer _messageProducer;
        private readonly ILogger<ResultService> _logger;

        public ResultService(ApplicationDbContext context, IMapper mapper, IMessageProducer messageProducer, ILogger<ResultService> logger)
            : base(context, mapper)
        {
            _messageProducer = messageProducer;
            _logger = logger;
        }

        protected override IQueryable<Result> AddInclude(IQueryable<Result> query)
            => query.Include(r => r.Driver).Include(r => r.Team).Include(r => r.Race);

        protected override IQueryable<Result> AddFilter(IQueryable<Result> query, ResultSearchObject? search)
        {
            if (search?.RaceID != null)
                query = query.Where(r => r.RaceID == search.RaceID);
            if (search?.DriverID != null)
                query = query.Where(r => r.DriverID == search.DriverID);
            if (search?.Position != null)
                query = query.Where(r => r.Position == search.Position);
            return query;
        }

        protected override IQueryable<Result> ApplyOrder(IQueryable<Result> query) => query.OrderBy(r => r.Race.Date).ThenBy(r => r.Position);

        // Current F1 rules: points for the top 10, no bonus point for the fastest lap.
        public static double CalculatePoints(int position)
        {
            return position >= 1 && position <= PointsTable.Length ? PointsTable[position - 1] : 0;
        }

        public async Task<RaceResultsResponse> GetRaceResultsAsync(int raceId)
        {
            var race = await _context.Races.FindAsync(raceId) ?? throw new NotFoundException("Race not found.");
            var results = await AddInclude(_context.Results)
                .Where(r => r.RaceID == raceId)
                .OrderBy(r => r.Position)
                .ToListAsync();

            var (canEdit, info) = GetEditWindow(race);
            return new RaceResultsResponse
            {
                RaceID = race.RaceID,
                RaceName = race.RaceName,
                RaceDate = race.Date,
                CanEdit = canEdit,
                EditInfo = info,
                Results = _mapper.Map<List<ResultResponse>>(results)
            };
        }

        public async Task<RaceResultsResponse> SaveRaceResultsAsync(int raceId, RaceResultsSaveRequest request)
        {
            var race = await _context.Races.FindAsync(raceId) ?? throw new NotFoundException("Race not found.");
            var (canEdit, info) = GetEditWindow(race);
            if (!canEdit)
                throw new BusinessException(info!);

            var entries = request.Results.OrderBy(r => r.Position).ToList();
            if (entries.Select(e => e.DriverID).Distinct().Count() != entries.Count)
                throw new BusinessException("The same driver was entered more than once.");
            if (!entries.Select(e => e.Position).SequenceEqual(Enumerable.Range(1, entries.Count)))
                throw new BusinessException($"Positions must go from 1 to {entries.Count} without repeats or gaps.");
            if (entries.Count(e => e.IsFastestLap) > 1)
                throw new BusinessException("Only one driver can have the fastest lap.");

            // The team is the one the driver races for in this season.
            var driverIds = entries.Select(e => e.DriverID).ToList();
            var teams = await _context.TeamDrivers
                .Where(td => td.SeasonID == race.SeasonID && driverIds.Contains(td.DriverID))
                .ToDictionaryAsync(td => td.DriverID, td => td.TeamID);
            var missing = driverIds.Where(id => !teams.ContainsKey(id)).ToList();
            if (missing.Any())
            {
                var names = await _context.Drivers.Where(d => missing.Contains(d.DriverID))
                    .Select(d => d.FirstName + " " + d.LastName).ToListAsync();
                throw new BusinessException($"Drivers without a team in this season: {string.Join(", ", names)}.");
            }

            var firstPublish = !await _context.Results.AnyAsync(r => r.RaceID == raceId);

            // Replacing the classification is a single SaveChanges, so it is atomic.
            _context.Results.RemoveRange(await _context.Results.Where(r => r.RaceID == raceId).ToListAsync());
            _context.Results.AddRange(entries.Select(e => new Result
            {
                RaceID = raceId,
                DriverID = e.DriverID,
                TeamID = teams[e.DriverID],
                Position = e.Position,
                IsFastestLap = e.IsFastestLap,
                TimeTaken = e.TimeTaken,
                Points = CalculatePoints(e.Position)
            }));
            await _context.SaveChangesAsync();

            if (firstPublish)
                await NotifyResultsPublishedAsync(race, entries, teams);

            return await GetRaceResultsAsync(raceId);
        }

        // Ticket holders and fans of the podium drivers/teams get a notification and an email.
        private async Task NotifyResultsPublishedAsync(Race race, List<RaceResultEntry> entries, Dictionary<int, int> teams)
        {
            var podiumDriverIds = entries.Take(3).Select(e => e.DriverID).ToList();
            var podiumTeamIds = podiumDriverIds.Select(id => teams[id]).Distinct().ToList();
            var podiumNames = await _context.Drivers
                .Where(d => podiumDriverIds.Contains(d.DriverID))
                .ToDictionaryAsync(d => d.DriverID, d => d.FirstName + " " + d.LastName);
            var podium = podiumDriverIds.Select(id => podiumNames[id]).ToList();

            var recipients = await _context.Users
                .Where(u => u.UserRoles.Any(ur => ur.Role.Name == Roles.User))
                .Where(u => u.Tickets.Any(t => t.RaceTicketCategory.RaceID == race.RaceID && t.Status != TicketStatus.Refunded)
                    || _context.FavoriteDrivers.Any(f => f.UserID == u.UserID && podiumDriverIds.Contains(f.DriverID))
                    || _context.FavoriteTeams.Any(f => f.UserID == u.UserID && podiumTeamIds.Contains(f.TeamID)))
                .ToListAsync();

            foreach (var user in recipients)
            {
                _context.Notifications.Add(new Notification
                {
                    UserID = user.UserID,
                    Title = "Results published",
                    Message = $"{race.RaceName}: {podium[0]} won. The full classification is in the app.",
                    CreatedAt = DateTime.UtcNow
                });
            }
            await _context.SaveChangesAsync();

            foreach (var user in recipients)
            {
                try
                {
                    await _messageProducer.PublishEmailAsync(EmailTemplates.ResultsPublished(user, race.RaceName, podium));
                }
                catch (Exception ex)
                {
                    _logger.LogError(ex, "Results email for race {RaceId} could not be queued.", race.RaceID);
                    break;
                }
            }
        }

        private static (bool CanEdit, string? Info) GetEditWindow(Race race)
        {
            var now = DateTime.UtcNow;
            if (race.Date > now)
                return (false, FormattableString.Invariant($"Results can be entered from the race start ({race.Date:d MMM yyyy, HH:mm} UTC) until 48 hours after it."));
            if (now - race.Date > EditWindow)
                return (false, "The time for entering and changing results (48 hours after the race) has expired.");
            return (true, FormattableString.Invariant($"Results can be changed until {race.Date.Add(EditWindow):d MMM yyyy, HH:mm} (UTC)."));
        }

        public async Task<List<DriverStandingResponse>> GetDriverStandingsBySeason(int seasonId)
        {
            return await _context.Results
                .Where(r => r.Race.SeasonID == seasonId)
                .GroupBy(r => new
                {
                    r.DriverID,
                    r.Driver.FirstName,
                    r.Driver.LastName,
                    r.Driver.PhotoUrl
                })
                .Select(g => new DriverStandingResponse
                {
                    DriverID = g.Key.DriverID,
                    DriverName = g.Key.FirstName + " " + g.Key.LastName,
                    PhotoUrl = g.Key.PhotoUrl,
                    TeamName = g.OrderByDescending(x => x.Race.Date)
                                .Select(x => x.Team.TeamName)
                                .FirstOrDefault() ?? "N/A",
                    TotalPoints = g.Sum(x => x.Points),
                    RacesCompleted = g.Count(),
                    BestFinish = g.Min(x => x.Position)
                })
                .OrderByDescending(x => x.TotalPoints)
                .ThenBy(x => x.BestFinish)
                .ToListAsync();
        }

        public async Task<List<TeamStandingResponse>> GetTeamStandingsAsync(int seasonId)
        {
            return await _context.Results
                .Where(r => r.Race.SeasonID == seasonId)
                .GroupBy(r => new
                {
                    r.TeamID,
                    r.Team.TeamName,
                    r.Team.LogoUrl
                })
                .Select(g => new TeamStandingResponse
                {
                    TeamID = g.Key.TeamID,
                    TeamName = g.Key.TeamName,
                    LogoUrl = g.Key.LogoUrl,
                    TotalPoints = g.Sum(x => x.Points),
                    DriversCount = g.Select(x => x.DriverID).Distinct().Count()
                })
                .OrderByDescending(x => x.TotalPoints)
                .ToListAsync();
        }
    }
}
