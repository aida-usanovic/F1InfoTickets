namespace F1Info_Tickets.Model.Dtos
{
    public class SalesAnalyticsDto
    {
        public int RaceId { get; set; }
        public string RaceName { get; set; } = string.Empty;
        public DateTime RaceDate { get; set; }
        public int TicketsSold { get; set; }
        public decimal TotalRevenue { get; set; }
    }
}
