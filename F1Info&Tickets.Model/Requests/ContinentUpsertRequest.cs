using System.ComponentModel.DataAnnotations;

namespace F1Info_Tickets.Model.Requests
{
    public class ContinentUpsertRequest
    {
        [Required(ErrorMessage = "Continent name is required.")]
        [MaxLength(50, ErrorMessage = "Continent name can have at most 50 characters.")]
        public string Name { get; set; } = string.Empty;
    }
}
