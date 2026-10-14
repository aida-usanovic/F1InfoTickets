using F1Info_Tickets.Model.Requests;
using F1Info_Tickets.Model.Responses;
using F1Info_Tickets.Model.SearchObjects;
using F1Info_Tickets.Services.BaseInterfaces;

namespace F1Info_Tickets.Services.Interfaces
{
    public interface IUserService : ICRUDService<UserResponse, UserSearchObject, UserInsertRequest, UserUpdateRequest>
    {
        Task<AuthResponse> LoginAsync(UserLoginRequest request);
        Task<UserResponse> RegisterAsync(UserInsertRequest request);
        Task RevokeTokenAsync(string jti, DateTime expiresAtUtc);
        Task<UserResponse> GetProfileAsync(int userId);
        Task<UserResponse> UpdateProfileAsync(int userId, ProfileUpdateRequest request);
        Task ChangePasswordAsync(int userId, ChangePasswordRequest request);
    }
}
