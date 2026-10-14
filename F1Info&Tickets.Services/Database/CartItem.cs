using System.ComponentModel.DataAnnotations;

namespace F1Info_Tickets.Services.Database
{
    public class CartItem
    {
        [Key]
        public int CartItemID { get; set; }
        public int CartID { get; set; }
        public int RaceTicketCategoryID { get; set; }
        public int Quantity { get; set; }
        public DateTime AddedAt { get; set; }
        public Cart Cart { get; set; } = null!;
        public RaceTicketCategory RaceTicketCategory { get; set; } = null!;
    }
}
