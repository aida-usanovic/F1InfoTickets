namespace F1Info_Tickets.Model.Responses
{
    public class DriverResponse
    {
        public int DriverID { get; set; }
        public string FirstName { get; set; } = string.Empty;
        public string LastName { get; set; } = string.Empty;
        public int Number { get; set; }
        public int CountryID { get; set; }
        // Country name, kept under this name for the existing clients.
        public string? Nationality { get; set; }
        public DateTime BirthDate { get; set; }
        public bool IsReserveDriver { get; set; }
        public string? PhotoUrl { get; set; }
        // Filled only by the per-season list (team the driver races for in that season).
        public string? TeamName { get; set; }
    }
}
