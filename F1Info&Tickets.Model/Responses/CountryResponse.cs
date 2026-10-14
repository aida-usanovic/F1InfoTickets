namespace F1Info_Tickets.Model.Responses
{
    public class CountryResponse
    {
        public int CountryID { get; set; }
        public string Name { get; set; } = string.Empty;
        public string Code { get; set; } = string.Empty;
        public int ContinentID { get; set; }
        public string? ContinentName { get; set; }
    }
}
