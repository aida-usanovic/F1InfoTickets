namespace F1Info_Tickets.Model.SearchObjects
{
    public class TicketSearchObject : BaseSearchObject
    {
        public int? UserID { get; set; }
        public int? RaceID { get; set; }
        public int? TicketTypeID { get; set; }
        public DateTime? PurchaseDateFrom { get; set; }
        public DateTime? PurchaseDateTo { get; set; }
    }
}
