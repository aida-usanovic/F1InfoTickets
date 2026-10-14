namespace F1Info_Tickets.Model.Responses
{
    public class TicketResponse
    {
        public int TicketID { get; set; }
        public int UserID { get; set; }
        public string? Username { get; set; }
        public string? CustomerName { get; set; }
        public int RaceTicketCategoryID { get; set; }
        public int RaceID { get; set; }
        public string? RaceName { get; set; }
        public DateTime RaceDate { get; set; }
        public string? CircuitName { get; set; }
        public string? TicketType { get; set; }
        public decimal Price { get; set; }
        public DateTime PurchaseDate { get; set; }
        public string QRCode { get; set; } = string.Empty;
        public int PaymentID { get; set; }
        public string? PaymentMethod { get; set; }
        public string? PaymentStatus { get; set; }
        public string Status { get; set; } = string.Empty;
    }
}
