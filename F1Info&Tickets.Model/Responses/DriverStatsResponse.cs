namespace F1Info_Tickets.Model.Responses
{
    public class DriverStatsResponse
    {
        public DriverResponse Driver { get; set; } = new();
        public string? CurrentTeam { get; set; }
        public int Age { get; set; }
        public int Races { get; set; }
        public int Wins { get; set; }
        public int Podiums { get; set; }
        public int FastestLaps { get; set; }
        public double TotalPoints { get; set; }
        public int? BestFinish { get; set; }
        public List<DriverSeasonStats> Seasons { get; set; } = new();
    }

    public class DriverSeasonStats
    {
        public int Year { get; set; }
        public string? Team { get; set; }
        public int Races { get; set; }
        public int Wins { get; set; }
        public int Podiums { get; set; }
        public double Points { get; set; }
    }
}
