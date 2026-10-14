using F1Info_Tickets.Model.Responses;

namespace F1Info_Tickets.Services.Interfaces
{
    public interface IFavoriteService
    {
        Task<List<DriverResponse>> GetDriversAsync(int userId);
        Task AddDriverAsync(int userId, int driverId);
        Task RemoveDriverAsync(int userId, int driverId);
        Task<List<TeamResponse>> GetTeamsAsync(int userId);
        Task AddTeamAsync(int userId, int teamId);
        Task RemoveTeamAsync(int userId, int teamId);
    }
}
