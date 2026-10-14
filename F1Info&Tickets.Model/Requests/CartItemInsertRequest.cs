using System.ComponentModel.DataAnnotations;

namespace F1Info_Tickets.Model.Requests
{
    public class CartItemInsertRequest
    {
        [Range(1, int.MaxValue, ErrorMessage = "Select a ticket type.")]
        public int RaceTicketCategoryID { get; set; }

        [Range(1, 10, ErrorMessage = "Quantity must be between 1 and 10.")]
        public int Quantity { get; set; } = 1;
    }
}
