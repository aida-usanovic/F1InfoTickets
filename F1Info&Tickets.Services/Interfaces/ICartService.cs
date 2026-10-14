using F1Info_Tickets.Model.Requests;
using F1Info_Tickets.Model.Responses;

namespace F1Info_Tickets.Services.Interfaces
{
    public interface ICartService
    {
        Task<CartResponse> GetCartAsync(int userId);
        Task<CartResponse> AddItemAsync(int userId, CartItemInsertRequest request);
        Task<CartResponse> UpdateItemAsync(int userId, int cartItemId, CartItemUpdateRequest request);
        Task<CartResponse> RemoveItemAsync(int userId, int cartItemId);
        Task ClearAsync(int userId);
    }
}
