using F1Info_Tickets.Model.Requests;
using F1Info_Tickets.Model.Responses;
using F1Info_Tickets.Model.SearchObjects;
using F1Info_Tickets.Services.BaseInterfaces;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace F1Info_Tickets.Services.Interfaces
{
    public interface ITeamService : ICRUDService<TeamResponse,TeamSearchObject,TeamUpsertRequest,TeamUpsertRequest>
    {
        Task<TeamDetailsResponse> GetTeamDetailsAsync(int teamId, int? seasonId);
        Task AddDriverToTeam(int teamId, int driverId, int seasonId);
        Task RemoveDriverFromTeam(int teamId, int driverId, int seasonId);
        Task<int?> GetCurrentTeamIdForDriverAsync(int driverId, int seasonId);
    }
}
