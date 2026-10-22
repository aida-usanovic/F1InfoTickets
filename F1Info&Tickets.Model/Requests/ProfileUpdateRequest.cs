using Microsoft.AspNetCore.Http;
using System.ComponentModel.DataAnnotations;

namespace F1Info_Tickets.Model.Requests
{
    public class ProfileUpdateRequest
    {
        [Required(ErrorMessage = "First name is required.")]
        [MaxLength(50, ErrorMessage = "First name can have at most 50 characters.")]
        public string FirstName { get; set; } = string.Empty;

        [Required(ErrorMessage = "Last name is required.")]
        [MaxLength(50, ErrorMessage = "Last name can have at most 50 characters.")]
        public string LastName { get; set; } = string.Empty;

        [Required(ErrorMessage = "Email is required.")]
        [EmailAddress(ErrorMessage = "Enter a valid email address (e.g. name@domain.com).")]
        [MaxLength(100, ErrorMessage = "Email can have at most 100 characters.")]
        public string Email { get; set; } = string.Empty;

        [Required(ErrorMessage = "Phone number is required.")]
        [RegularExpression(ValidationPatterns.Phone, ErrorMessage = ValidationPatterns.PhoneMessage)]
        public string Phone { get; set; } = string.Empty;

        public DateTime BirthDate { get; set; }

        // Optional new profile photo (sent as multipart form data); checked like driver and team images.
        public IFormFile? Image { get; set; }
    }
}
