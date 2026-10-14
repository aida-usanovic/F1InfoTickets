using F1Info_Tickets.Model.Requests;
using F1Info_Tickets.Model.Responses;

namespace F1Info_Tickets.Services.Interfaces
{
    public interface IPaymentService
    {
        Task<PaymentResponse> CreatePayPalOrderAsync(PaymentCreateRequest request, int userId);
        Task<PaymentResponse> CapturePayPalOrderAsync(string providerOrderId, int userId);
        Task<PaymentResponse> RefundPayPalPaymentAsync(int paymentId, int userId);
    }
}
