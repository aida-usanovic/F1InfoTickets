namespace F1Info_Tickets.Model.Responses
{
    public class TicketTypeResponse
    {
        public int TicketTypeID { get; set; }
        public string Name { get; set; } = string.Empty;
        public string? Description { get; set; }
    }
}
