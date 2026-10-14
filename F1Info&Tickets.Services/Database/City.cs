using System.ComponentModel.DataAnnotations;

namespace F1Info_Tickets.Services.Database
{
    public class City
    {
        [Key]
        public int CityID { get; set; }
        [Required, MaxLength(100)]
        public string Name { get; set; } = string.Empty;
        public int CountryID { get; set; }
        public Country Country { get; set; } = null!;
    }
}
