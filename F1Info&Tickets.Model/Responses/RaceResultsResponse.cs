namespace F1Info_Tickets.Model.Responses
{
    public class RaceResultsResponse
    {
        public int RaceID { get; set; }
        public string RaceName { get; set; } = string.Empty;
        public DateTime RaceDate { get; set; }
        // Results can be entered from the race start until 48h after it.
        public bool CanEdit { get; set; }
        public string? EditInfo { get; set; }
        public List<ResultResponse> Results { get; set; } = new();
    }
}
