namespace F1Info_Tickets.Model.Responses
{
    public class RaceTicketCategoryResponse
    {
        public int RaceTicketCategoryID { get; set; }
        public int RaceID { get; set; }
        public string? RaceName { get; set; }
        public DateTime RaceDate { get; set; }
        public int TicketTypeID { get; set; }
        public string? TicketTypeName { get; set; }
        public string? TicketTypeDescription { get; set; }
        public decimal Price { get; set; }
        public int Capacity { get; set; }
        public int Sold { get; set; }
        public int Available => Math.Max(0, Capacity - Sold);
    }
}
