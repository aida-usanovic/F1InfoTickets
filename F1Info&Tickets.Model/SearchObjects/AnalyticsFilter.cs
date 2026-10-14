namespace F1Info_Tickets.Model.SearchObjects
{
    // Season filters by race season; dates filter by purchase date.
    public class AnalyticsFilter
    {
        public int? SeasonID { get; set; }
        public DateTime? DateFrom { get; set; }
        public DateTime? DateTo { get; set; }
    }
}
