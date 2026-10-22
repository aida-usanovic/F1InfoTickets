using F1Info_Tickets.Model.Requests;
using F1Info_Tickets.Model.Responses;
using F1Info_Tickets.Model.SearchObjects;
using F1Info_Tickets.Services.BaseInterfaces;

namespace F1Info_Tickets.Services.Interfaces
{
    public interface IRaceService : ICRUDService<RaceResponse, RaceSearchObject, RaceInsertRequest, RaceUpdateRequest>
    {
        Task<PagedResult<RaceResponse>> GetRacesBySeason(int seasonId, PageRequest paging);
        Task<PagedResult<RaceResponse>> GetUpcomingRaces(PageRequest paging);
        Task RecordViewAsync(int userId, int raceId);
    }
}
