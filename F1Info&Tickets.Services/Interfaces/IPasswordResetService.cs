using F1Info_Tickets.Model.Requests;

namespace F1Info_Tickets.Services.Interfaces
{
    public interface IPasswordResetService
    {
        Task RequestCodeAsync(ForgotPasswordRequest request);
        Task ResetPasswordAsync(ResetPasswordRequest request);
    }
}
