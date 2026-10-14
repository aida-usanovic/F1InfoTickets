using System.ComponentModel.DataAnnotations;

namespace F1Info_Tickets.Model.Requests
{
    public class CityUpsertRequest
    {
        [Required(ErrorMessage = "City name is required.")]
        [MaxLength(100, ErrorMessage = "City name can have at most 100 characters.")]
        public string Name { get; set; } = string.Empty;

        [Range(1, int.MaxValue, ErrorMessage = "Select a country.")]
        public int CountryID { get; set; }
    }
}
