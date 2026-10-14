namespace F1Info_Tickets.Services.Configuration
{
    public class PayPalSettings
    {
        public string ClientId { get; set; } = string.Empty;
        public string Secret { get; set; } = string.Empty;
        public string Mode { get; set; } = "sandbox"; // "sandbox" or "live"
        public string Currency { get; set; } = "EUR";
    }
}
