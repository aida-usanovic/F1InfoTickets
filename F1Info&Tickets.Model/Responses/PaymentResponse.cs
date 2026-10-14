namespace F1Info_Tickets.Model.Responses
{
    public class PaymentResponse
    {
        public int? PaymentID { get; set; }
        public string ProviderOrderId { get; set; } = string.Empty;
        public string ApprovalUrl { get; set; } = string.Empty;
        public string Status { get; set; } = string.Empty;
    }
}