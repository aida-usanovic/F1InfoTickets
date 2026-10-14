namespace F1Info_Tickets.Model.Dtos
{
    public class TicketTypeSalesDto
    {
        public string TicketType { get; set; } = string.Empty;
        public int TicketsSold { get; set; }
        public decimal TotalRevenue { get; set; }
    }
}
