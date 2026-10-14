using System.ComponentModel.DataAnnotations;

namespace F1Info_Tickets.Services.Database
{
    // A ticket offer for one race: ticket type, price and how many seats can be sold.
    public class RaceTicketCategory
    {
        [Key]
        public int RaceTicketCategoryID { get; set; }
        public int RaceID { get; set; }
        public int TicketTypeID { get; set; }
        public decimal Price { get; set; }
        public int Capacity { get; set; }
        public Race Race { get; set; } = null!;
        public TicketType TicketType { get; set; } = null!;
        public ICollection<Ticket> Tickets { get; set; } = new List<Ticket>();
    }
}
