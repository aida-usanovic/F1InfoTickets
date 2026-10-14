namespace F1Info_Tickets.Model.Responses
{
    public class CartResponse
    {
        public int CartID { get; set; }
        public List<CartItemResponse> Items { get; set; } = new();
        public int TotalQuantity => Items.Sum(i => i.Quantity);
        public decimal Total => Items.Sum(i => i.Subtotal);
    }

    public class CartItemResponse
    {
        public int CartItemID { get; set; }
        public int RaceTicketCategoryID { get; set; }
        public int RaceID { get; set; }
        public string? RaceName { get; set; }
        public DateTime RaceDate { get; set; }
        public string? CircuitName { get; set; }
        public string? TicketType { get; set; }
        public decimal UnitPrice { get; set; }
        public int Quantity { get; set; }
        public int Available { get; set; }
        public decimal Subtotal => UnitPrice * Quantity;
    }
}
