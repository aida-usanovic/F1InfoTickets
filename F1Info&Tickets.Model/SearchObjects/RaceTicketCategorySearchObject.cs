namespace F1Info_Tickets.Model.SearchObjects
{
    public class RaceTicketCategorySearchObject : BaseSearchObject
    {
        public int? RaceID { get; set; }
        public int? TicketTypeID { get; set; }
        public bool? UpcomingOnly { get; set; }
    }
}
