using System.ComponentModel.DataAnnotations;

namespace F1Info_Tickets.Model.Requests
{
    public class CountryUpsertRequest
    {
        [Required(ErrorMessage = "Country name is required.")]
        [MaxLength(100, ErrorMessage = "Country name can have at most 100 characters.")]
        public string Name { get; set; } = string.Empty;

        [Required(ErrorMessage = "Country code is required.")]
        [RegularExpression("^[A-Za-z]{2,3}$", ErrorMessage = "Country code must have 2 or 3 letters (e.g. BA, ITA).")]
        public string Code { get; set; } = string.Empty;

        [Range(1, int.MaxValue, ErrorMessage = "Select a continent.")]
        public int ContinentID { get; set; }
    }
}
