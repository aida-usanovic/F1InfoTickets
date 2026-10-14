using System.ComponentModel.DataAnnotations;

namespace F1Info_Tickets.Services.Database
{
    public enum TicketStatus
    {
        Active = 0,
        Used = 1,
        Refunded = 2
    }

    // A ticket exists only once it has been paid for.
    public class Ticket
    {
        [Key]
        public int TicketID { get; set; }
        public int UserID { get; set; }
        public int RaceTicketCategoryID { get; set; }
        public int PaymentID { get; set; }
        public decimal Price { get; set; }
        public DateTime PurchaseDate { get; set; }
        [Required, MaxLength(64)]
        public string QRCode { get; set; } = string.Empty;
        public TicketStatus Status { get; set; } = TicketStatus.Active;
        public User User { get; set; } = null!;
        public RaceTicketCategory RaceTicketCategory { get; set; } = null!;
        public Payment Payment { get; set; } = null!;
    }
}
