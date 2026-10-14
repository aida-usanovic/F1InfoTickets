using System.ComponentModel.DataAnnotations;

namespace F1Info_Tickets.Services.Database
{
    public class Team
    {
        [Key]
        public int TeamID { get; set; }
        [Required, MaxLength(100)]
        public string TeamName { get; set; } = string.Empty;
        public int BaseCityID { get; set; }
        [Required, MaxLength(100)]
        public string TeamPrincipal { get; set; } = string.Empty;
        [MaxLength(300)]
        public string? LogoUrl { get; set; }
        public City BaseCity { get; set; } = null!;
        public ICollection<TeamDriver> TeamDrivers { get; set; } = new List<TeamDriver>();
    }
}
