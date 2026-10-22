namespace F1Info_Tickets.Model.Responses
{
    public class RaceResponse
    {
        public int RaceID { get; set; }
        public string RaceName { get; set; } = string.Empty;
        public DateTime Date { get; set; }
        public int SeasonID { get; set; }
        public int SeasonYear { get; set; }
        public int CircuitID { get; set; }
        public string? CircuitName { get; set; }
        // "City, Country" for display.
        public string? Location { get; set; }
        public int CountryID { get; set; }
        public string? CountryName { get; set; }
        public int ContinentID { get; set; }
        public string? ContinentName { get; set; }
        public string? TrackType { get; set; }
        public int Laps { get; set; }
        public double CircuitLength { get; set; }
        public string? ImageUrl { get; set; }
        public decimal? MinTicketPrice { get; set; }
        public string? RecommendationReason { get; set; }
        // Set only on recommendations: the ticket type the user buys most often, if this race still offers it.
        public int? RecommendedTicketTypeID { get; set; }
        public string? RecommendedTicketType { get; set; }
        public decimal? RecommendedTicketPrice { get; set; }
    }
}
