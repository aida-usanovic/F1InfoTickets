using System.ComponentModel.DataAnnotations;

namespace F1Info_Tickets.Model.Requests
{
    public class ResetPasswordRequest
    {
        [Required(ErrorMessage = "Email is required.")]
        [EmailAddress(ErrorMessage = "Enter a valid email address (e.g. name@domain.com).")]
        public string Email { get; set; } = string.Empty;

        [Required(ErrorMessage = "Enter the code from the email.")]
        [RegularExpression(@"^\d{6}$", ErrorMessage = "The code has 6 digits.")]
        public string Code { get; set; } = string.Empty;

        [Required(ErrorMessage = "Enter a new password.")]
        [MinLength(6, ErrorMessage = "Password must have at least 6 characters.")]
        public string NewPassword { get; set; } = string.Empty;

        [Required(ErrorMessage = "Confirm the new password.")]
        [Compare(nameof(NewPassword), ErrorMessage = "Passwords do not match.")]
        public string NewPasswordConfirmation { get; set; } = string.Empty;
    }
}
