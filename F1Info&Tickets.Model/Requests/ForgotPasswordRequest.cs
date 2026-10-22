using System.ComponentModel.DataAnnotations;

namespace F1Info_Tickets.Model.Requests
{
    public class ForgotPasswordRequest
    {
        [Required(ErrorMessage = "Email is required.")]
        [EmailAddress(ErrorMessage = "Enter a valid email address (e.g. name@domain.com).")]
        public string Email { get; set; } = string.Empty;
    }
}
