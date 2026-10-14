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
            if (request.Image != null)
                entity.PhotoUrl = await FileHelper.SaveImageAsync(request.Image, "drivers");
        }

        public async Task<List<DriverResponse>> GetActiveDriversBySeason(int seasonId)
        {
            var drivers = await _context.Drivers
                .Include(d => d.Country)
                .Include(d => d.TeamDrivers.Where(td => td.SeasonID == seasonId)).ThenInclude(td => td.Team)
                .Where(d => d.TeamDrivers.Any(td => td.SeasonID == seasonId))
                .OrderBy(d => d.LastName)
                .ToListAsync();

            return drivers.Select(d =>
            {
                var response = _mapper.Map<DriverResponse>(d);
                response.TeamName = d.TeamDrivers.FirstOrDefault()?.Team.TeamName;
                return response;
            }).ToList();
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

        public async Task<List<DriverResponse>> GetDriversByTeamAndSeason(int teamId, int seasonId)
        {
            var drivers = await _context.Drivers
                .Include(d => d.Country)
                .Where(d => d.TeamDrivers.Any(td => td.TeamID == teamId && td.SeasonID == seasonId))
                .OrderBy(d => d.IsReserveDriver).ThenBy(d => d.LastName)
                .ToListAsync();

            return _mapper.Map<List<DriverResponse>>(drivers);
        }
    }
}
