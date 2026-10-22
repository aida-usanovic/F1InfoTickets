using F1Info_Tickets.Model.Responses;
using F1Info_Tickets.Model.SearchObjects;

namespace F1Info_Tickets.Services.Interfaces
{
    public interface IFavoriteService
    {
        Task<PagedResult<DriverResponse>> GetDriversAsync(int userId, PageRequest paging);
        Task<bool> IsFavoriteDriverAsync(int userId, int driverId);
        Task AddDriverAsync(int userId, int driverId);
        Task RemoveDriverAsync(int userId, int driverId);
        Task<PagedResult<TeamResponse>> GetTeamsAsync(int userId, PageRequest paging);
        Task<bool> IsFavoriteTeamAsync(int userId, int teamId);
        Task AddTeamAsync(int userId, int teamId);
        Task RemoveTeamAsync(int userId, int teamId);
    }
}
