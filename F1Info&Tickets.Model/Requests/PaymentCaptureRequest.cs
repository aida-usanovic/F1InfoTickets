using System.ComponentModel.DataAnnotations;

namespace F1Info_Tickets.Model.Requests
{
    public class PaymentCaptureRequest
    {
        [Required(ErrorMessage = "The PayPal order is unknown.")]
        public string OrderId { get; set; } = string.Empty;
    }
}
