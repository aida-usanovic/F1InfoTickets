using F1Info_Tickets.Model.Requests;
using F1Info_Tickets.Model.Responses;
using F1Info_Tickets.Services.Database;
using F1Info_Tickets.Services.Exceptions;
using F1Info_Tickets.Services.Interfaces;
using Microsoft.EntityFrameworkCore;

namespace F1Info_Tickets.Services.Services
{
    public class CartService : ICartService
    {
        private const int MaxPerItem = 10;
        private readonly ApplicationDbContext _context;

        public CartService(ApplicationDbContext context)
        {
            _context = context;
        }

        public async Task<CartResponse> GetCartAsync(int userId)
        {
            var cart = await LoadCartAsync(userId);
            if (cart == null) return new CartResponse();

            var categoryIds = cart.CartItems.Select(i => i.RaceTicketCategoryID).ToList();
            var sold = await _context.Tickets
                .Where(t => categoryIds.Contains(t.RaceTicketCategoryID) && t.Status != TicketStatus.Refunded)
                .GroupBy(t => t.RaceTicketCategoryID)
                .Select(g => new { g.Key, Count = g.Count() })
                .ToDictionaryAsync(x => x.Key, x => x.Count);

            return new CartResponse
            {
                CartID = cart.CartID,
                Items = cart.CartItems
                    .OrderBy(i => i.RaceTicketCategory.Race.Date)
                    .Select(i => new CartItemResponse
                    {
                        CartItemID = i.CartItemID,
                        RaceTicketCategoryID = i.RaceTicketCategoryID,
                        RaceID = i.RaceTicketCategory.RaceID,
                        RaceName = i.RaceTicketCategory.Race.RaceName,
                        RaceDate = i.RaceTicketCategory.Race.Date,
                        CircuitName = i.RaceTicketCategory.Race.Circuit.Name,
                        TicketType = i.RaceTicketCategory.TicketType.Name,
                        UnitPrice = i.RaceTicketCategory.Price,
                        Quantity = i.Quantity,
                        Available = i.RaceTicketCategory.Capacity - sold.GetValueOrDefault(i.RaceTicketCategoryID)
                    })
                    .ToList()
            };
        }

        public async Task<CartResponse> AddItemAsync(int userId, CartItemInsertRequest request)
        {
            var cart = await LoadCartAsync(userId);
            if (cart == null)
            {
                cart = new Cart { UserID = userId, CreatedAt = DateTime.UtcNow };
                _context.Carts.Add(cart);
            }

            var existing = cart.CartItems.FirstOrDefault(i => i.RaceTicketCategoryID == request.RaceTicketCategoryID);
            var newQuantity = (existing?.Quantity ?? 0) + request.Quantity;
            await EnsureAvailableAsync(request.RaceTicketCategoryID, newQuantity);

            if (existing != null)
            {
                existing.Quantity = newQuantity;
            }
            else
            {
                cart.CartItems.Add(new CartItem
                {
                    RaceTicketCategoryID = request.RaceTicketCategoryID,
                    Quantity = request.Quantity,
                    AddedAt = DateTime.UtcNow
                });
            }

            await _context.SaveChangesAsync();
            return await GetCartAsync(userId);
        }

        public async Task<CartResponse> UpdateItemAsync(int userId, int cartItemId, CartItemUpdateRequest request)
        {
            var item = await FindOwnItemAsync(userId, cartItemId);
            await EnsureAvailableAsync(item.RaceTicketCategoryID, request.Quantity);
            item.Quantity = request.Quantity;
            await _context.SaveChangesAsync();
            return await GetCartAsync(userId);
        }

        public async Task<CartResponse> RemoveItemAsync(int userId, int cartItemId)
        {
            var item = await FindOwnItemAsync(userId, cartItemId);
            _context.CartItems.Remove(item);
            await _context.SaveChangesAsync();
            return await GetCartAsync(userId);
        }

        public async Task ClearAsync(int userId)
        {
            var items = await _context.CartItems.Where(i => i.Cart.UserID == userId).ToListAsync();
            _context.CartItems.RemoveRange(items);
            await _context.SaveChangesAsync();
        }

        private Task<Cart?> LoadCartAsync(int userId)
        {
            return _context.Carts
                .Include(c => c.CartItems).ThenInclude(i => i.RaceTicketCategory).ThenInclude(rc => rc.TicketType)
                .Include(c => c.CartItems).ThenInclude(i => i.RaceTicketCategory).ThenInclude(rc => rc.Race).ThenInclude(r => r.Circuit)
                .FirstOrDefaultAsync(c => c.UserID == userId);
        }

        private async Task<CartItem> FindOwnItemAsync(int userId, int cartItemId)
        {
            return await _context.CartItems.FirstOrDefaultAsync(i => i.CartItemID == cartItemId && i.Cart.UserID == userId)
                ?? throw new NotFoundException("The item was not found in your cart.");
        }

        private async Task EnsureAvailableAsync(int categoryId, int quantity)
        {
            if (quantity > MaxPerItem)
                throw new BusinessException($"You can buy at most {MaxPerItem} tickets of the same type for one race.");

            var category = await _context.RaceTicketCategories
                .Include(c => c.Race)
                .FirstOrDefaultAsync(c => c.RaceTicketCategoryID == categoryId)
                ?? throw new BusinessException("The selected ticket type does not exist.");

            if (category.Race.Date <= DateTime.UtcNow)
                throw new BusinessException("Tickets for this race are no longer on sale.");

            var sold = await _context.Tickets.CountAsync(t => t.RaceTicketCategoryID == categoryId && t.Status != TicketStatus.Refunded);
            var available = category.Capacity - sold;
            if (quantity > available)
                throw new BusinessException(available > 0
                    ? $"Only {available} seats are left for this ticket type."
                    : "This ticket type is sold out.");
        }
    }
}
