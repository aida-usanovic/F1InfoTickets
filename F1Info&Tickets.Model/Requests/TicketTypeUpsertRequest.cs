using System.ComponentModel.DataAnnotations;

namespace F1Info_Tickets.Model.Requests
{
    public class TicketTypeUpsertRequest
    {
        [Required(ErrorMessage = "Ticket type name is required.")]
        [MaxLength(50, ErrorMessage = "Ticket type name can have at most 50 characters.")]
        public string Name { get; set; } = string.Empty;

        [MaxLength(300, ErrorMessage = "Description can have at most 300 characters.")]
        public string? Description { get; set; }
    }
}
