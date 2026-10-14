using Microsoft.AspNetCore.Http;
using System.ComponentModel.DataAnnotations;

namespace F1Info_Tickets.Model.Requests
{
    public class TeamUpsertRequest
    {
        [Required(ErrorMessage = "Team name is required.")]
        [MaxLength(100, ErrorMessage = "Team name can have at most 100 characters.")]
        public string TeamName { get; set; } = string.Empty;

        [Range(1, int.MaxValue, ErrorMessage = "Select the city of the team's headquarters.")]
        public int BaseCityID { get; set; }

        [Required(ErrorMessage = "Team principal is required.")]
        [MaxLength(100, ErrorMessage = "Team principal's name can have at most 100 characters.")]
        public string TeamPrincipal { get; set; } = string.Empty;

        public IFormFile? Image { get; set; }
    }
}
