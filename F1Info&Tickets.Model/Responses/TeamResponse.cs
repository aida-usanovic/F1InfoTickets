namespace F1Info_Tickets.Model.Responses
{
    public class TeamResponse
    {
        public int TeamID { get; set; }
        public string TeamName { get; set; } = string.Empty;
        public int BaseCityID { get; set; }
        public string? BaseCityName { get; set; }
        public int CountryID { get; set; }
        // Country of the team base.
        public string? Country { get; set; }
        public string TeamPrincipal { get; set; } = string.Empty;
        public string? LogoUrl { get; set; }
    }
}
