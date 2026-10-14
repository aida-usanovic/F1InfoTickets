using Microsoft.AspNetCore.Http;
using System.ComponentModel.DataAnnotations;

namespace F1Info_Tickets.Model.Requests
{
    public class DriverUpdateRequest
    {
        [Required(ErrorMessage = "First name is required.")]
        [MaxLength(50, ErrorMessage = "First name can have at most 50 characters.")]
        public string FirstName { get; set; } = string.Empty;

        [Required(ErrorMessage = "Last name is required.")]
        [MaxLength(50, ErrorMessage = "Last name can have at most 50 characters.")]
        public string LastName { get; set; } = string.Empty;

        [Range(1, 99, ErrorMessage = "Racing number must be between 1 and 99.")]
        public int Number { get; set; }

        [Range(1, int.MaxValue, ErrorMessage = "Select a nationality.")]
        public int CountryID { get; set; }

        public DateTime BirthDate { get; set; }
        public bool IsReserveDriver { get; set; }
        public IFormFile? Image { get; set; }
    }
}
