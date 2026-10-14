using System.ComponentModel.DataAnnotations;

namespace F1Info_Tickets.Services.Database
{
    public class Driver
    {
        [Key]
        public int DriverID { get; set; }
        [Required, MaxLength(50)]
        public string FirstName { get; set; } = string.Empty;
        [Required, MaxLength(50)]
        public string LastName { get; set; } = string.Empty;
        public int Number { get; set; }
        public int CountryID { get; set; }
        public DateTime BirthDate { get; set; }
        public bool IsReserveDriver { get; set; }
        [MaxLength(300)]
        public string? PhotoUrl { get; set; }
        public Country Country { get; set; } = null!;
        public ICollection<TeamDriver> TeamDrivers { get; set; } = new List<TeamDriver>();
        public ICollection<Result> Results { get; set; } = new List<Result>();
    }
}
