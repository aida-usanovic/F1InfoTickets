using F1Info_Tickets.Model.Requests;
using F1Info_Tickets.Model.Responses;
using F1Info_Tickets.Model.SearchObjects;
using F1Info_Tickets.Services.BaseInterfaces;

namespace F1Info_Tickets.Services.Interfaces
{
    public interface IResultService : IService<ResultResponse, ResultSearchObject>
    {
        Task<RaceResultsResponse> GetRaceResultsAsync(int raceId);
        Task<RaceResultsResponse> SaveRaceResultsAsync(int raceId, RaceResultsSaveRequest request);
        Task<PagedResult<DriverStandingResponse>> GetDriverStandingsBySeason(int seasonId, BaseSearchObject search);
        Task<PagedResult<TeamStandingResponse>> GetTeamStandingsAsync(int seasonId, BaseSearchObject search);
    }
}
