using System.ComponentModel.DataAnnotations;

namespace F1Info_Tickets.Model.Requests
{
    public class SeasonUpsertRequest
    {
        [Range(1950, 2100, ErrorMessage = "Season year must be between 1950 and 2100.")]
        public int Year { get; set; }

        [Required(ErrorMessage = "Season description is required.")]
        [MaxLength(100, ErrorMessage = "Description can have at most 100 characters.")]
        public string Description { get; set; } = string.Empty;
    }
}
