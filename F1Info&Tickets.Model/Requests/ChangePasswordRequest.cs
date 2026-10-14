using System.ComponentModel.DataAnnotations;

namespace F1Info_Tickets.Model.Requests
{
    // A user changing their own password must confirm the current one.
    public class ChangePasswordRequest
    {
        [Required(ErrorMessage = "Enter your current password.")]
        public string OldPassword { get; set; } = string.Empty;

        [Required(ErrorMessage = "Enter a new password.")]
        [MinLength(6, ErrorMessage = "Password must have at least 6 characters.")]
        public string NewPassword { get; set; } = string.Empty;

        [Required(ErrorMessage = "Confirm the new password.")]
        [Compare(nameof(NewPassword), ErrorMessage = "Passwords do not match.")]
        public string NewPasswordConfirmation { get; set; } = string.Empty;
    }
}
