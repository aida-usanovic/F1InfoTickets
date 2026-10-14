using F1Info_Tickets.Model.Dtos;
using F1Info_Tickets.Model.SearchObjects;

namespace F1Info_Tickets.Services.Interfaces
{
    public interface IAnalyticsService
    {
        Task<DashboardDto> GetDashboardAsync();
        Task<List<SalesAnalyticsDto>> GetTicketSalesReport(AnalyticsFilter filter);
        Task<List<TicketTypeSalesDto>> GetTicketTypeSalesReport(AnalyticsFilter filter);
        Task<List<RaceAttendanceDto>> GetRaceAttendanceReport(AnalyticsFilter filter);
        Task<UserActivityDto> GetUserActivityReport(AnalyticsFilter filter);
    }
}
