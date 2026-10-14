using System.ComponentModel.DataAnnotations;

namespace F1Info_Tickets.Model.Requests
{
    public class RaceTicketCategoryUpsertRequest
    {
        [Range(1, int.MaxValue, ErrorMessage = "Select a race.")]
        public int RaceID { get; set; }

        [Range(1, int.MaxValue, ErrorMessage = "Select a ticket type.")]
        public int TicketTypeID { get; set; }

        [Range(typeof(decimal), "1", "100000", ErrorMessage = "Price must be between 1 and 100000 EUR.")]
        public decimal Price { get; set; }

        [Range(1, 500000, ErrorMessage = "Capacity must be between 1 and 500000 seats.")]
        public int Capacity { get; set; }
    }
}
