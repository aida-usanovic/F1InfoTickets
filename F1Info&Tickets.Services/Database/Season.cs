using System.ComponentModel.DataAnnotations;

namespace F1Info_Tickets.Services.Database
{
    public class Season
    {
        [Key]
        public int SeasonID { get; set; }
        public int Year { get; set; }
        [Required, MaxLength(100)]
        public string Description { get; set; } = string.Empty;
        public ICollection<Race> Races { get; set; } = new List<Race>();
        public ICollection<TeamDriver> TeamDrivers { get; set; } = new List<TeamDriver>();
    }
}
