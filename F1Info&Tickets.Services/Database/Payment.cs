using System.ComponentModel.DataAnnotations;

namespace F1Info_Tickets.Services.Database
{
    public class Payment
    {
        [Key]
        public int PaymentID { get; set; }
        public int UserID { get; set; }
        public decimal Amount { get; set; }
        [Required, MaxLength(3)]
        public string Currency { get; set; } = "EUR";
        [Required, MaxLength(30)]
        public string PaymentMethod { get; set; } = string.Empty;
        [Required, MaxLength(100)]
        public string PayPalTransactionID { get; set; } = string.Empty;
        [Required, MaxLength(20)]
        public string Status { get; set; } = string.Empty;
        public DateTime PaymentDate { get; set; }
        public DateTime? RefundedAt { get; set; }
        public User User { get; set; } = null!;
        public ICollection<Ticket> Tickets { get; set; } = new List<Ticket>();
    }
}
