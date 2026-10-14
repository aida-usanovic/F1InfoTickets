using System.ComponentModel.DataAnnotations;

namespace F1Info_Tickets.Services.Database
{
    public class Result
    {
        [Key]
        public int ResultID { get; set; }
        public int RaceID { get; set; }
        public int DriverID { get; set; }
        public int TeamID { get; set; }
        public int Position { get; set; }
        public double Points { get; set; }
        public bool IsFastestLap { get; set; }
        [Required, MaxLength(20)]
        public string TimeTaken { get; set; } = string.Empty;
        public Race Race { get; set; } = null!;
        public Driver Driver { get; set; } = null!;
        public Team Team { get; set; } = null!;
    }
}
