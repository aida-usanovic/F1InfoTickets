using F1Info_Tickets.Model.Responses;
using F1Info_Tickets.Model.SearchObjects;
using F1Info_Tickets.Services.Exceptions;
using F1Info_Tickets.Services.Interfaces;
using MapsterMapper;
using Microsoft.EntityFrameworkCore;

namespace F1Info_Tickets.Services.Services
{
    public class NotificationService : INotificationService
    {
        private readonly ApplicationDbContext _context;
        private readonly IMapper _mapper;

        public NotificationService(ApplicationDbContext context, IMapper mapper)
        {
            _context = context;
            _mapper = mapper;
        }

        public async Task<PagedResult<NotificationResponse>> GetForUserAsync(int userId, NotificationSearchObject search)
        {
            var query = _context.Notifications.Where(n => n.UserID == userId);
            if (search.UnreadOnly == true)
                query = query.Where(n => !n.IsRead);
            if (!string.IsNullOrWhiteSpace(search.SearchTerm))
                query = query.Where(n => n.Title.Contains(search.SearchTerm) || n.Message.Contains(search.SearchTerm));

            var page = Math.Max(search.Page, 1);
            var pageSize = Math.Clamp(search.PageSize, 1, 100);
            var items = await query
                .OrderByDescending(n => n.CreatedAt)
                .Skip((page - 1) * pageSize)
                .Take(pageSize)
                .ToListAsync();

            return new PagedResult<NotificationResponse>
            {
                TotalCount = await query.CountAsync(),
                Page = page,
                PageSize = pageSize,
                Items = _mapper.Map<List<NotificationResponse>>(items)
            };
        }

        public Task<int> GetUnreadCountAsync(int userId)
        {
            return _context.Notifications.CountAsync(n => n.UserID == userId && !n.IsRead);
        }

        public async Task MarkAsReadAsync(int userId, int notificationId)
        {
            var notification = await _context.Notifications.FirstOrDefaultAsync(n => n.NotificationID == notificationId && n.UserID == userId)
                ?? throw new NotFoundException("Notification not found.");
            notification.IsRead = true;
            await _context.SaveChangesAsync();
        }

        public async Task MarkAllAsReadAsync(int userId)
        {
            await _context.Notifications
                .Where(n => n.UserID == userId && !n.IsRead)
                .ExecuteUpdateAsync(s => s.SetProperty(n => n.IsRead, true));
        }
    }
}
