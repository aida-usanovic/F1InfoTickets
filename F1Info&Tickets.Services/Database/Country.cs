using System.ComponentModel.DataAnnotations;

namespace F1Info_Tickets.Services.Database
{
    public class Country
    {
        [Key]
        public int CountryID { get; set; }
        [Required, MaxLength(100)]
        public string Name { get; set; } = string.Empty;
        [Required, MaxLength(3)]
        public string Code { get; set; } = string.Empty;
        public int ContinentID { get; set; }
        public Continent Continent { get; set; } = null!;
        public ICollection<City> Cities { get; set; } = new List<City>();
    }
}
