namespace F1Info_Tickets.Model.Responses
{
    public class CircuitResponse
    {
        public int CircuitID { get; set; }
        public string Name { get; set; } = string.Empty;
        public int CityID { get; set; }
        public string? CityName { get; set; }
        public int CountryID { get; set; }
        public string? CountryName { get; set; }
        public string? ContinentName { get; set; }
        public int TrackTypeID { get; set; }
        public string? TrackTypeName { get; set; }
        public int Laps { get; set; }
        public double LengthKm { get; set; }
        public string? ImageUrl { get; set; }
    }
}
