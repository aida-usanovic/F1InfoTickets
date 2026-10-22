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
    public class RaceTicketCategoryService : BaseCRUDService<RaceTicketCategory, RaceTicketCategoryResponse, RaceTicketCategorySearchObject, RaceTicketCategoryUpsertRequest, RaceTicketCategoryUpsertRequest>, IRaceTicketCategoryService
    {
        public RaceTicketCategoryService(ApplicationDbContext context, IMapper mapper) : base(context, mapper) { }

        protected override IQueryable<RaceTicketCategory> AddInclude(IQueryable<RaceTicketCategory> query)
        {
            return query
                .Include(x => x.Race)
                .Include(x => x.TicketType)
                .Include(x => x.Tickets.Where(t => t.Status != TicketStatus.Refunded));
        }

        protected override IQueryable<RaceTicketCategory> AddFilter(IQueryable<RaceTicketCategory> query, RaceTicketCategorySearchObject? search)
        {
            if (!string.IsNullOrWhiteSpace(search?.SearchTerm))
                query = query.Where(x => x.Race.RaceName.Contains(search.SearchTerm) || x.TicketType.Name.Contains(search.SearchTerm));
            if (search?.RaceID != null)
                query = query.Where(x => x.RaceID == search.RaceID);
            if (search?.TicketTypeID != null)
                query = query.Where(x => x.TicketTypeID == search.TicketTypeID);
            if (search?.UpcomingOnly == true)
                query = query.Where(x => x.Race.Date > DateTime.UtcNow);
            return query;
        }

        protected override IQueryable<RaceTicketCategory> ApplyOrder(IQueryable<RaceTicketCategory> query)
            => query.OrderBy(x => x.Race.Date).ThenBy(x => x.Price);

        protected override async Task BeforeInsert(RaceTicketCategory entity, RaceTicketCategoryUpsertRequest request)
        {
            var race = await _context.Races.FindAsync(request.RaceID)
                ?? throw new BusinessException("The selected race does not exist.");
            if (race.Date <= DateTime.UtcNow)
                throw new BusinessException("Tickets can only be offered for upcoming races.");
            if (await _context.RaceTicketCategories.AnyAsync(x => x.RaceID == request.RaceID && x.TicketTypeID == request.TicketTypeID))
                throw new BusinessException("This ticket type already exists for the selected race. Edit the existing offer.");
        }

        protected override async Task BeforeUpdate(RaceTicketCategory entity, RaceTicketCategoryUpsertRequest request)
        {
            if (await _context.RaceTicketCategories.AnyAsync(x => x.RaceTicketCategoryID != entity.RaceTicketCategoryID && x.RaceID == request.RaceID && x.TicketTypeID == request.TicketTypeID))
                throw new BusinessException("This ticket type already exists for the selected race.");

            var sold = await _context.Tickets.CountAsync(t => t.RaceTicketCategoryID == entity.RaceTicketCategoryID && t.Status != TicketStatus.Refunded);
            if (request.Capacity < sold)
                throw new BusinessException($"Capacity cannot be lower than the number of tickets already sold ({sold}).");

            // The entity already holds the new values; the original ones decide whether the offer is moved.
            var entry = _context.Entry(entity);
            var raceChanged = entry.Property(x => x.RaceID).OriginalValue != request.RaceID;
            var typeChanged = entry.Property(x => x.TicketTypeID).OriginalValue != request.TicketTypeID;
            if ((raceChanged || typeChanged) && sold > 0)
                throw new BusinessException($"{sold} ticket(s) of this offer are already sold, so its race and ticket type cannot be changed. You can still change the price and capacity.");
            if (raceChanged && !await _context.Races.AnyAsync(r => r.RaceID == request.RaceID && r.Date > DateTime.UtcNow))
                throw new BusinessException("Tickets can only be offered for upcoming races.");
        }
    }
}
