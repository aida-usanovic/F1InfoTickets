using F1Info_Tickets.Model.Requests;
using F1Info_Tickets.Model.Responses;
using F1Info_Tickets.Model.SearchObjects;
using F1Info_Tickets.Services.BaseInterfaces;

namespace F1Info_Tickets.Services.Interfaces
{
    public interface IDriverService : ICRUDService<DriverResponse, DriverSearchObject, DriverInsertRequest, DriverUpdateRequest>
    {
        Task<PagedResult<DriverResponse>> GetActiveDriversBySeason(int seasonId, PageRequest paging);
        Task<int?> GetDriverTeamId(int driverId, int seasonId);
        Task<PagedResult<DriverResponse>> GetDriversByTeamAndSeason(int teamId, int seasonId, PageRequest paging);
        Task<DriverStatsResponse> GetStatsAsync(int driverId);
    }
}
