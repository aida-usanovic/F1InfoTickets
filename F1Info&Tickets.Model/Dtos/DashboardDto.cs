namespace F1Info_Tickets.Model.Dtos
{
    public class DashboardDto
    {
        public int TotalUsers { get; set; }
        public int TotalDrivers { get; set; }
        public int TicketsSold { get; set; }
        public decimal TotalRevenue { get; set; }
        public int UpcomingRaces { get; set; }
    }
}
