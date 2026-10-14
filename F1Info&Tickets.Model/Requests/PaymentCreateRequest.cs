namespace F1Info_Tickets.Model.Requests
{
    // The order is built from the current user's cart on the server.
    public class PaymentCreateRequest
    {
        public string ReturnUrl { get; set; } = string.Empty;
        public string CancelUrl { get; set; } = string.Empty;
    }
}
