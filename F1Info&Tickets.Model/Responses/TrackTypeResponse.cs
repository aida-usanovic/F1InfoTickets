namespace F1Info_Tickets.Model.Responses
{
    public class TrackTypeResponse
    {
        public int TrackTypeID { get; set; }
        public string Name { get; set; } = string.Empty;
        public string? Description { get; set; }
    }
}
