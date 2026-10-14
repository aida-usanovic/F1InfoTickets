using F1Info_Tickets.Model.Requests;
using F1Info_Tickets.Model.Responses;
using F1Info_Tickets.Model.SearchObjects;
using F1Info_Tickets.Services.BaseServices;
using F1Info_Tickets.Services.Database;
using F1Info_Tickets.Services.Exceptions;
using F1Info_Tickets.Services.Interfaces;
using MapsterMapper;
using Microsoft.EntityFrameworkCore;

namespace F1Info_Tickets.Services.Services
{
    public class SeasonService : BaseCRUDService<Season, SeasonResponse, SeasonSearchObject, SeasonUpsertRequest, SeasonUpsertRequest>, ISeasonService
    {
        public SeasonService(ApplicationDbContext context, IMapper mapper) : base(context, mapper)
        {
        }

        protected override IQueryable<Season> AddFilter(IQueryable<Season> query, SeasonSearchObject? search)
        {
            if (search?.Year != null)
                query = query.Where(s => s.Year == search.Year);
            if (!string.IsNullOrWhiteSpace(search?.SearchTerm))
                query = query.Where(s => s.Description.Contains(search.SearchTerm) || s.Year.ToString().Contains(search.SearchTerm));
            return query;
        }

        protected override IQueryable<Season> ApplyOrder(IQueryable<Season> query) => query.OrderBy(s => s.Year);

        protected override async Task BeforeInsert(Season entity, SeasonUpsertRequest request)
        {
            if (await _context.Seasons.AnyAsync(s => s.Year == request.Year))
                throw new BusinessException($"Season {request.Year} already exists.");
        }

        protected override async Task BeforeUpdate(Season entity, SeasonUpsertRequest request)
        {
            if (await _context.Seasons.AnyAsync(s => s.Year == request.Year && s.SeasonID != entity.SeasonID))
                throw new BusinessException($"Season {request.Year} already exists.");
            if (await _context.Races.AnyAsync(r => r.SeasonID == entity.SeasonID && r.Date.Year != request.Year))
                throw new BusinessException("The season year must match the dates of the season's races.");
        }

        public async Task<Season> GetOrCreateSeasonAsync(int year)
        {
            var season = await _context.Seasons.FirstOrDefaultAsync(s => s.Year == year);
            if (season == null)
            {
                season = new Season
                {
                    Year = year,
                    Description = $"FIA Formula 1 svjetsko prvenstvo {year}."
                };

                _context.Seasons.Add(season);
                await _context.SaveChangesAsync();
            }

            return season;
        }

        // The season whose standings are "live": the latest one that already has results.
        public async Task<SeasonResponse?> GetCurrentSeasonAsync()
        {
            var season = await _context.Results
                .OrderByDescending(r => r.Race.Date)
                .Select(r => r.Race.Season)
                .FirstOrDefaultAsync()
                ?? await _context.Seasons.Where(s => s.Year <= DateTime.UtcNow.Year).OrderByDescending(s => s.Year).FirstOrDefaultAsync()
                ?? await _context.Seasons.OrderBy(s => s.Year).FirstOrDefaultAsync();

            return season == null ? null : _mapper.Map<SeasonResponse>(season);
        }
    }
}
