using F1Info_Tickets.Model.Responses;
using F1Info_Tickets.Services.Database;
using F1Info_Tickets.Services.Exceptions;
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

        public async Task<List<DriverResponse>> GetDriversAsync(int userId)
        {
            var drivers = await _context.Drivers
                .Include(d => d.Country)
                .Where(d => _context.FavoriteDrivers.Any(f => f.UserID == userId && f.DriverID == d.DriverID))
                .OrderBy(d => d.LastName)
                .ToListAsync();
            return _mapper.Map<List<DriverResponse>>(drivers);
        }

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

        public async Task<List<TeamResponse>> GetTeamsAsync(int userId)
        {
            var teams = await _context.Teams
                .Include(t => t.BaseCity).ThenInclude(c => c.Country)
                .Where(t => _context.FavoriteTeams.Any(f => f.UserID == userId && f.TeamID == t.TeamID))
                .OrderBy(t => t.TeamName)
                .ToListAsync();
            return _mapper.Map<List<TeamResponse>>(teams);
        }

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
