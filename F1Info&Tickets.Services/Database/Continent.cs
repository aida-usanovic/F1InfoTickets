using System.ComponentModel.DataAnnotations;

namespace F1Info_Tickets.Services.Database
{
    public class Continent
    {
        [Key]
        public int ContinentID { get; set; }
        [Required, MaxLength(50)]
        public string Name { get; set; } = string.Empty;
        public ICollection<Country> Countries { get; set; } = new List<Country>();
    }
}
