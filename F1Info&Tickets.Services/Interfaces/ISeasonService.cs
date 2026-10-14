using F1Info_Tickets.Model.Requests;
using F1Info_Tickets.Model.Responses;
using F1Info_Tickets.Model.SearchObjects;
using F1Info_Tickets.Services.BaseInterfaces;
using F1Info_Tickets.Services.Database;

namespace F1Info_Tickets.Services.Interfaces
{
    public interface ISeasonService : ICRUDService<SeasonResponse, SeasonSearchObject, SeasonUpsertRequest, SeasonUpsertRequest>
    {
        Task<Season> GetOrCreateSeasonAsync(int year);
        Task<SeasonResponse?> GetCurrentSeasonAsync();
    }
}
