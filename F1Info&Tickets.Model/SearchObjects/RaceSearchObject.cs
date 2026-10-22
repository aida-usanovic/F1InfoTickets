namespace F1Info_Tickets.Model.SearchObjects
{
    public class RaceSearchObject : BaseSearchObject
    {
        public int? SeasonID { get; set; }
        public int? ContinentID { get; set; }
        public int? TrackTypeID { get; set; }
        // true = only upcoming, false = only finished, null = all.
        public bool? Upcoming { get; set; }
        // Races that start at or after this moment (e.g. results entry: now minus 48 hours).
        public DateTime? DateFrom { get; set; }
    }
}
