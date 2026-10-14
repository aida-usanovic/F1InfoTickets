using System.ComponentModel.DataAnnotations;

namespace F1Info_Tickets.Model.Requests
{
    // The full classification of one race; replaces whatever was saved before.
    public class RaceResultsSaveRequest
    {
        [Required(ErrorMessage = "Enter at least one result.")]
        [MinLength(1, ErrorMessage = "Enter at least one result.")]
        [MaxLength(30, ErrorMessage = "A race can have at most 30 classified drivers.")]
        public List<RaceResultEntry> Results { get; set; } = new();
    }

    public class RaceResultEntry
    {
        [Range(1, int.MaxValue, ErrorMessage = "Select a driver.")]
        public int DriverID { get; set; }

        [Range(1, 30, ErrorMessage = "Position must be between 1 and 30.")]
        public int Position { get; set; }

        public bool IsFastestLap { get; set; }

        [Required(ErrorMessage = "Time is required.")]
        [RegularExpression(ValidationPatterns.RaceTime, ErrorMessage = ValidationPatterns.RaceTimeMessage)]
        public string TimeTaken { get; set; } = string.Empty;
    }
}
