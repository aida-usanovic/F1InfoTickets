using F1Info_Tickets.Model.Requests;
using F1Info_Tickets.Model.Responses;
using F1Info_Tickets.Model.SearchObjects;
using F1Info_Tickets.Services.BaseInterfaces;

namespace F1Info_Tickets.Services.Interfaces
{
    public interface IDriverService : ICRUDService<DriverResponse, DriverSearchObject, DriverInsertRequest, DriverUpdateRequest>
    {
        Task<List<DriverResponse>> GetActiveDriversBySeason(int seasonId);
        Task<int?> GetDriverTeamId(int driverId, int seasonId);
        Task<List<DriverResponse>> GetDriversByTeamAndSeason(int teamId, int seasonId);
        Task<DriverStatsResponse> GetStatsAsync(int driverId);
    }
}
