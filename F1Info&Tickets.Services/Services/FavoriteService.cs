using F1Info_Tickets.Model.Responses;
using F1Info_Tickets.Model.SearchObjects;
using F1Info_Tickets.Services.Database;
using F1Info_Tickets.Services.Exceptions;
using F1Info_Tickets.Services.Helpers;
using F1Info_Tickets.Services.Interfaces;
using MapsterMapper;
using Microsoft.EntityFrameworkCore;

namespace F1Info_Tickets.Services.Services
{
    public class FavoriteService : IFavoriteService
    {
        private readonly ApplicationDbContext _context;
        private readonly IMapper _mapper;

        public FavoriteService(ApplicationDbContext context, IMapper mapper)
        {
            _context = context;
            _mapper = mapper;
        }

        public async Task<PagedResult<DriverResponse>> GetDriversAsync(int userId, PageRequest paging)
        {
            var drivers = await _context.Drivers
                .Include(d => d.Country)
                .Where(d => _context.FavoriteDrivers.Any(f => f.UserID == userId && f.DriverID == d.DriverID))
                .OrderBy(d => d.LastName).ThenBy(d => d.DriverID)
                .ToPagedResultAsync(paging);
            return drivers.MapItems(_mapper.Map<List<DriverResponse>>);
        }

        public Task<bool> IsFavoriteDriverAsync(int userId, int driverId) =>
            _context.FavoriteDrivers.AnyAsync(f => f.UserID == userId && f.DriverID == driverId);

        public async Task AddDriverAsync(int userId, int driverId)
        {
            if (!await _context.Drivers.AnyAsync(d => d.DriverID == driverId))
                throw new NotFoundException("Driver not found.");
            if (await _context.FavoriteDrivers.AnyAsync(f => f.UserID == userId && f.DriverID == driverId))
                return;

            _context.FavoriteDrivers.Add(new FavoriteDriver { UserID = userId, DriverID = driverId, CreatedAt = DateTime.UtcNow });
            await _context.SaveChangesAsync();
        }

        public async Task RemoveDriverAsync(int userId, int driverId)
        {
            var favorite = await _context.FavoriteDrivers.FirstOrDefaultAsync(f => f.UserID == userId && f.DriverID == driverId);
            if (favorite == null) return;
            _context.FavoriteDrivers.Remove(favorite);
            await _context.SaveChangesAsync();
        }

        public async Task<PagedResult<TeamResponse>> GetTeamsAsync(int userId, PageRequest paging)
        {
            var teams = await _context.Teams
                .Include(t => t.BaseCity).ThenInclude(c => c.Country)
                .Where(t => _context.FavoriteTeams.Any(f => f.UserID == userId && f.TeamID == t.TeamID))
                .OrderBy(t => t.TeamName).ThenBy(t => t.TeamID)
                .ToPagedResultAsync(paging);
            return teams.MapItems(_mapper.Map<List<TeamResponse>>);
        }

        public Task<bool> IsFavoriteTeamAsync(int userId, int teamId) =>
            _context.FavoriteTeams.AnyAsync(f => f.UserID == userId && f.TeamID == teamId);

        public async Task AddTeamAsync(int userId, int teamId)
        {
            if (!await _context.Teams.AnyAsync(t => t.TeamID == teamId))
                throw new NotFoundException("Team not found.");
            if (await _context.FavoriteTeams.AnyAsync(f => f.UserID == userId && f.TeamID == teamId))
                return;

            _context.FavoriteTeams.Add(new FavoriteTeam { UserID = userId, TeamID = teamId, CreatedAt = DateTime.UtcNow });
            await _context.SaveChangesAsync();
        }

        public async Task RemoveTeamAsync(int userId, int teamId)
        {
            var favorite = await _context.FavoriteTeams.FirstOrDefaultAsync(f => f.UserID == userId && f.TeamID == teamId);
            if (favorite == null) return;
            _context.FavoriteTeams.Remove(favorite);
            await _context.SaveChangesAsync();
        }
    }
}
