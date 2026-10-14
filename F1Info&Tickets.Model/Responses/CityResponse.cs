namespace F1Info_Tickets.Model.Responses
{
    public class CityResponse
    {
        public int CityID { get; set; }
        public string Name { get; set; } = string.Empty;
        public int CountryID { get; set; }
        public string? CountryName { get; set; }
    }
}
