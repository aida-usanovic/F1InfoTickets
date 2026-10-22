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
    public class DriverService : BaseCRUDService<Driver, DriverResponse, DriverSearchObject, DriverInsertRequest, DriverUpdateRequest>, IDriverService
    {
        public DriverService(ApplicationDbContext context, IMapper mapper)
            : base(context, mapper) { }

        protected override IQueryable<Driver> AddInclude(IQueryable<Driver> query) => query.Include(d => d.Country);

        protected override IQueryable<Driver> AddFilter(IQueryable<Driver> query, DriverSearchObject? search)
        {
            if (search == null) return query;

            var term = !string.IsNullOrWhiteSpace(search.Name) ? search.Name : search.SearchTerm;
            if (!string.IsNullOrWhiteSpace(term))
                query = query.Where(x => x.FirstName.Contains(term) || x.LastName.Contains(term) || (x.FirstName + " " + x.LastName).Contains(term));

            if (search.SeasonId.HasValue)
                query = query.Where(d => d.TeamDrivers.Any(td => td.SeasonID == search.SeasonId.Value));

            return query;
        }

        protected override IQueryable<Driver> ApplyOrder(IQueryable<Driver> query) => query.OrderBy(d => d.LastName).ThenBy(d => d.FirstName);

        protected override async Task BeforeInsert(Driver entity, DriverInsertRequest request)
        {
            if (request.Image != null)
                entity.PhotoUrl = await FileHelper.SaveImageAsync(request.Image, "drivers");
        }

        protected override async Task BeforeUpdate(Driver entity, DriverUpdateRequest request)
        {
            // A reserve driver who becomes a race driver must fit the limit of 2 race drivers in every team line-up they belong to.
            var wasReserve = _context.Entry(entity).Property(x => x.IsReserveDriver).OriginalValue;
            if (wasReserve && !entity.IsReserveDriver)
            {
                var full = await _context.TeamDrivers
                    .Where(td => td.DriverID == entity.DriverID)
                    .Select(td => new
                    {
                        td.Team.TeamName,
                        td.Season.Year,
                        RaceDrivers = _context.TeamDrivers.Count(o => o.TeamID == td.TeamID && o.SeasonID == td.SeasonID
                            && o.DriverID != entity.DriverID && !o.Driver.IsReserveDriver)
                    })
                    .Where(x => x.RaceDrivers >= 2)
                    .OrderByDescending(x => x.Year)
                    .FirstOrDefaultAsync();
                if (full != null)
                    throw new BusinessException($"{full.TeamName} already has 2 race drivers in the {full.Year} season, so this driver cannot become a race driver. Make one of them a reserve driver or remove the driver from that line-up first.");
            }

            if (request.Image != null)
                entity.PhotoUrl = await FileHelper.SaveImageAsync(request.Image, "drivers");
        }

        public async Task<PagedResult<DriverResponse>> GetActiveDriversBySeason(int seasonId, PageRequest paging)
        {
            var drivers = await _context.Drivers
                .Include(d => d.Country)
                .Include(d => d.TeamDrivers.Where(td => td.SeasonID == seasonId)).ThenInclude(td => td.Team)
                .Where(d => d.TeamDrivers.Any(td => td.SeasonID == seasonId))
                .OrderBy(d => d.LastName).ThenBy(d => d.DriverID)
                .ToPagedResultAsync(paging);

            return drivers.MapItems(items => items.Select(d =>
            {
                var response = _mapper.Map<DriverResponse>(d);
                response.TeamName = d.TeamDrivers.FirstOrDefault()?.Team.TeamName;
                return response;
            }).ToList());
        }

        public async Task<DriverStatsResponse> GetStatsAsync(int driverId)
        {
            var driver = await FindWithIncludesAsync(driverId) ?? throw new NotFoundException("Driver not found.");
            var results = await _context.Results
                .Include(r => r.Race).ThenInclude(r => r.Season)
                .Include(r => r.Team)
                .Where(r => r.DriverID == driverId)
                .ToListAsync();
            var currentTeam = await _context.TeamDrivers
                .Where(td => td.DriverID == driverId)
                .OrderByDescending(td => td.Season.Year)
                .Select(td => td.Team.TeamName)
                .FirstOrDefaultAsync();

            var today = DateTime.UtcNow.Date;
            var age = today.Year - driver.BirthDate.Year;
            if (driver.BirthDate.Date > today.AddYears(-age)) age--;

            return new DriverStatsResponse
            {
                Driver = _mapper.Map<DriverResponse>(driver),
                CurrentTeam = currentTeam,
                Age = age,
                Races = results.Count,
                Wins = results.Count(r => r.Position == 1),
                Podiums = results.Count(r => r.Position <= 3),
                FastestLaps = results.Count(r => r.IsFastestLap),
                TotalPoints = results.Sum(r => r.Points),
                BestFinish = results.Count > 0 ? results.Min(r => r.Position) : null,
                Seasons = results
                    .GroupBy(r => r.Race.Season.Year)
                    .OrderByDescending(g => g.Key)
                    .Select(g => new DriverSeasonStats
                    {
                        Year = g.Key,
                        Team = g.OrderByDescending(r => r.Race.Date).First().Team.TeamName,
                        Races = g.Count(),
                        Wins = g.Count(r => r.Position == 1),
                        Podiums = g.Count(r => r.Position <= 3),
                        Points = g.Sum(r => r.Points)
                    })
                    .ToList()
            };
        }

        public async Task<int?> GetDriverTeamId(int driverId, int seasonId)
        {
            var teamDriver = await _context.TeamDrivers
                .FirstOrDefaultAsync(td => td.DriverID == driverId && td.SeasonID == seasonId);
            return teamDriver?.TeamID;
        }

        public async Task<PagedResult<DriverResponse>> GetDriversByTeamAndSeason(int teamId, int seasonId, PageRequest paging)
        {
            var drivers = await _context.Drivers
                .Include(d => d.Country)
                .Where(d => d.TeamDrivers.Any(td => td.TeamID == teamId && td.SeasonID == seasonId))
                .OrderBy(d => d.IsReserveDriver).ThenBy(d => d.LastName).ThenBy(d => d.DriverID)
                .ToPagedResultAsync(paging);

            return drivers.MapItems(_mapper.Map<List<DriverResponse>>);
        }
    }
}
