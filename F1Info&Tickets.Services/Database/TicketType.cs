using System.ComponentModel.DataAnnotations;

namespace F1Info_Tickets.Services.Database
{
    public class TicketType
    {
        [Key]
        public int TicketTypeID { get; set; }
        [Required, MaxLength(50)]
        public string Name { get; set; } = string.Empty;
        [MaxLength(300)]
        public string? Description { get; set; }
    }
}
