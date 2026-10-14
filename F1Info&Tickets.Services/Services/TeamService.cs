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

namespace F1Info_Tickets.Services.Services
{
    public class TeamService : BaseCRUDService<Team, TeamResponse, TeamSearchObject, TeamUpsertRequest, TeamUpsertRequest>, ITeamService
    {
        public TeamService(ApplicationDbContext context, IMapper mapper)
            : base(context, mapper) { }

        protected override IQueryable<Team> AddInclude(IQueryable<Team> query)
            => query.Include(t => t.BaseCity).ThenInclude(c => c.Country);

        protected override IQueryable<Team> AddFilter(IQueryable<Team> query, TeamSearchObject? search)
        {
            if (!string.IsNullOrWhiteSpace(search?.SearchTerm))
                query = query.Where(t => t.TeamName.Contains(search.SearchTerm) || t.TeamPrincipal.Contains(search.SearchTerm));
            if (search?.CountryID != null)
                query = query.Where(t => t.BaseCity.CountryID == search.CountryID);
            return query;
        }

        protected override IQueryable<Team> ApplyOrder(IQueryable<Team> query) => query.OrderBy(t => t.TeamName);

        protected override async Task BeforeInsert(Team entity, TeamUpsertRequest request)
        {
            if (request.Image != null)
                entity.LogoUrl = await FileHelper.SaveImageAsync(request.Image, "teams");
        }

        protected override async Task BeforeUpdate(Team entity, TeamUpsertRequest request)
        {
            if (request.Image != null)
                entity.LogoUrl = await FileHelper.SaveImageAsync(request.Image, "teams");
        }

        // Team info with the season line-up and season results (latest season the team raced in by default).
        public async Task<TeamDetailsResponse> GetTeamDetailsAsync(int teamId, int? seasonId)
        {
            var team = await FindWithIncludesAsync(teamId)
                ?? throw new NotFoundException("Team not found.");

            var season = seasonId != null
                ? await _context.Seasons.FindAsync(seasonId.Value)
                : await _context.Results.Where(r => r.TeamID == teamId).OrderByDescending(r => r.Race.Date).Select(r => r.Race.Season).FirstOrDefaultAsync()
                  ?? await _context.TeamDrivers.Where(td => td.TeamID == teamId).OrderByDescending(td => td.Season.Year).Select(td => td.Season).FirstOrDefaultAsync();

            var response = new TeamDetailsResponse { Team = _mapper.Map<TeamResponse>(team) };
            if (season == null) return response;

            var drivers = await _context.Drivers
                .Include(d => d.Country)
                .Where(d => d.TeamDrivers.Any(td => td.TeamID == teamId && td.SeasonID == season.SeasonID))
                .OrderBy(d => d.IsReserveDriver).ThenBy(d => d.LastName)
                .ToListAsync();
            var results = await _context.Results
                .Where(r => r.TeamID == teamId && r.Race.SeasonID == season.SeasonID)
                .Select(r => new { r.Position, r.Points })
                .ToListAsync();

            response.SeasonYear = season.Year;
            response.SeasonPoints = results.Sum(r => r.Points);
            response.SeasonWins = results.Count(r => r.Position == 1);
            response.SeasonPodiums = results.Count(r => r.Position <= 3);
            response.Drivers = _mapper.Map<List<DriverResponse>>(drivers);
            return response;
        }

        public async Task AddDriverToTeam(int teamId, int driverId, int seasonId)
        {
            var current = await _context.TeamDrivers
                .Include(td => td.Team)
                .FirstOrDefaultAsync(td => td.DriverID == driverId && td.SeasonID == seasonId);

            if (current != null)
            {
                if (current.TeamID == teamId) return;
                throw new BusinessException($"The driver already races for {current.Team.TeamName} in this season.");
            }

            var driverToAdd = await _context.Drivers.FindAsync(driverId)
                ?? throw new BusinessException("The driver does not exist.");

            if (!driverToAdd.IsReserveDriver)
            {
                var mainDriversCount = await _context.TeamDrivers
                    .Where(td => td.TeamID == teamId && td.SeasonID == seasonId)
                    .CountAsync(td => !td.Driver.IsReserveDriver);

                if (mainDriversCount >= 2)
                    throw new BusinessException("The team already has the maximum number of race drivers (2) for this season.");
            }

            _context.TeamDrivers.Add(new TeamDriver
            {
                TeamID = teamId,
                DriverID = driverId,
                SeasonID = seasonId
            });
            await _context.SaveChangesAsync();
        }

        public async Task RemoveDriverFromTeam(int teamId, int driverId, int seasonId)
        {
            var relation = await _context.TeamDrivers.FirstOrDefaultAsync(x =>
                x.TeamID == teamId && x.DriverID == driverId && x.SeasonID == seasonId);

            if (relation != null)
            {
                _context.TeamDrivers.Remove(relation);
                await _context.SaveChangesAsync();
            }
        }

        public async Task<int?> GetCurrentTeamIdForDriverAsync(int driverId, int seasonId)
        {
            return await _context.TeamDrivers
                .Where(td => td.DriverID == driverId && td.SeasonID == seasonId)
                .Select(td => (int?)td.TeamID)
                .FirstOrDefaultAsync();
        }
    }
}
