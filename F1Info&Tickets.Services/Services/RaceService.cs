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
    public class RaceService : BaseCRUDService<Race, RaceResponse, RaceSearchObject, RaceInsertRequest, RaceUpdateRequest>, IRaceService
    {
        private readonly ISeasonService _seasonService;

        public RaceService(ApplicationDbContext context, IMapper mapper, ISeasonService seasonService) : base(context, mapper)
        {
            _seasonService = seasonService;
        }

        protected override IQueryable<Race> AddInclude(IQueryable<Race> query) => query.IncludeRaceDetails();

        protected override IQueryable<Race> AddFilter(IQueryable<Race> query, RaceSearchObject? search)
        {
            if (search == null) return query;

            if (!string.IsNullOrWhiteSpace(search.SearchTerm))
                query = query.Where(r => r.RaceName.Contains(search.SearchTerm)
                    || r.Circuit.Name.Contains(search.SearchTerm)
                    || r.Circuit.City.Name.Contains(search.SearchTerm)
                    || r.Circuit.City.Country.Name.Contains(search.SearchTerm));
            if (search.SeasonID != null)
                query = query.Where(r => r.SeasonID == search.SeasonID);
            if (search.ContinentID != null)
                query = query.Where(r => r.Circuit.City.Country.ContinentID == search.ContinentID);
            if (search.TrackTypeID != null)
                query = query.Where(r => r.Circuit.TrackTypeID == search.TrackTypeID);
            if (search.Upcoming == true)
                query = query.Where(r => r.Date > DateTime.UtcNow);
            if (search.Upcoming == false)
                query = query.Where(r => r.Date <= DateTime.UtcNow);
            if (search.DateFrom.HasValue)
            {
                var from = search.DateFrom.Value.ToUniversalTime();
                query = query.Where(r => r.Date >= from);
            }

            return query;
        }

        protected override IQueryable<Race> ApplyOrder(IQueryable<Race> query) => query.OrderBy(r => r.Date);

        // Finished races: the latest first, so paging starts with the most recent race.
        protected override IQueryable<Race> ApplyOrder(IQueryable<Race> query, RaceSearchObject? search) =>
            search?.Upcoming == false ? query.OrderByDescending(r => r.Date) : ApplyOrder(query);

        protected override async Task BeforeInsert(Race entity, RaceInsertRequest request)
        {
            await EnsureCircuitExists(request.CircuitID);
            entity.SeasonID = (await _seasonService.GetOrCreateSeasonAsync(request.Date.Year)).SeasonID;
        }

        protected override async Task BeforeUpdate(Race entity, RaceUpdateRequest request)
        {
            await EnsureCircuitExists(request.CircuitID);

            // A race with results stays a finished race of its season, so the standings of that season stay correct.
            var originalDate = _context.Entry(entity).Property(x => x.Date).OriginalValue;
            if (originalDate != request.Date && await _context.Results.AnyAsync(r => r.RaceID == entity.RaceID))
            {
                if (request.Date.Year != originalDate.Year)
                    throw new BusinessException($"Results are already entered for this race, so it must stay in the {originalDate.Year} season.");
                if (request.Date > DateTime.UtcNow)
                    throw new BusinessException("Results are already entered for this race, so its date cannot be moved into the future.");
            }

            entity.SeasonID = (await _seasonService.GetOrCreateSeasonAsync(request.Date.Year)).SeasonID;
        }

        public override async Task<PagedResult<RaceResponse>> GetAsync(RaceSearchObject search)
        {
            var result = await base.GetAsync(search);
            await FillHasResultsAsync(result.Items);
            return result;
        }

        public override async Task<RaceResponse?> GetByIdAsync(int id)
        {
            var race = await base.GetByIdAsync(id);
            if (race != null) await FillHasResultsAsync([race]);
            return race;
        }

        private async Task FillHasResultsAsync(IReadOnlyCollection<RaceResponse> races)
        {
            var ids = races.Select(r => r.RaceID).ToList();
            var withResults = await _context.Results.Where(r => ids.Contains(r.RaceID)).Select(r => r.RaceID).Distinct().ToListAsync();
            foreach (var race in races) race.HasResults = withResults.Contains(race.RaceID);
        }

        public async Task<PagedResult<RaceResponse>> GetRacesBySeason(int seasonId, PageRequest paging)
        {
            var races = await _context.Races.IncludeRaceDetails()
                .Where(r => r.SeasonID == seasonId)
                .OrderBy(r => r.Date).ThenBy(r => r.RaceID)
                .ToPagedResultAsync(paging);
            return races.MapItems(_mapper.Map<List<RaceResponse>>);
        }

        public async Task<PagedResult<RaceResponse>> GetUpcomingRaces(PageRequest paging)
        {
            var races = await _context.Races.IncludeRaceDetails()
                .Where(r => r.Date > DateTime.UtcNow)
                .OrderBy(r => r.Date).ThenBy(r => r.RaceID)
                .ToPagedResultAsync(paging);
            return races.MapItems(_mapper.Map<List<RaceResponse>>);
        }

        public async Task RecordViewAsync(int userId, int raceId)
        {
            if (!await _context.Races.AnyAsync(r => r.RaceID == raceId))
                throw new NotFoundException("Race not found.");

            _context.RaceViews.Add(new RaceView { UserID = userId, RaceID = raceId, ViewedAt = DateTime.UtcNow });
            await _context.SaveChangesAsync();
        }

        private async Task EnsureCircuitExists(int circuitId)
        {
            if (!await _context.Circuits.AnyAsync(c => c.CircuitID == circuitId))
                throw new BusinessException("The selected circuit does not exist.");
        }
    }
}
