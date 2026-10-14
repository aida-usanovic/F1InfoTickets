using F1Info_Tickets.Model.Responses;
using F1Info_Tickets.Model.SearchObjects;

namespace F1Info_Tickets.Services.Interfaces
{
    public interface INotificationService
    {
        Task<PagedResult<NotificationResponse>> GetForUserAsync(int userId, NotificationSearchObject search);
        Task<int> GetUnreadCountAsync(int userId);
        Task MarkAsReadAsync(int userId, int notificationId);
        Task MarkAllAsReadAsync(int userId);
    }
}
