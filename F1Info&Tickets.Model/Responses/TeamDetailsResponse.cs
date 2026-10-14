namespace F1Info_Tickets.Model.Responses
{
    public class TeamDetailsResponse
    {
        public TeamResponse Team { get; set; } = new();
        public int SeasonYear { get; set; }
        public double SeasonPoints { get; set; }
        public int SeasonWins { get; set; }
        public int SeasonPodiums { get; set; }
        public List<DriverResponse> Drivers { get; set; } = new();
    }
}
