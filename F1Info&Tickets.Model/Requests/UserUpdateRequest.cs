using System.ComponentModel.DataAnnotations;

namespace F1Info_Tickets.Model.Requests
{
    // Admin edit: the password is optional and the old password is not required.
    public class UserUpdateRequest
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

        [Required(ErrorMessage = "Username is required.")]
        [RegularExpression(ValidationPatterns.Username, ErrorMessage = ValidationPatterns.UsernameMessage)]
        public string Username { get; set; } = string.Empty;

        [Required(ErrorMessage = "Phone number is required.")]
        [RegularExpression(ValidationPatterns.Phone, ErrorMessage = ValidationPatterns.PhoneMessage)]
        public string Phone { get; set; } = string.Empty;

        public DateTime BirthDate { get; set; }

        [Range(1, int.MaxValue, ErrorMessage = "Select a role.")]
        public int RoleID { get; set; }

        [MinLength(6, ErrorMessage = "Password must have at least 6 characters.")]
        public string? Password { get; set; }

        [Compare(nameof(Password), ErrorMessage = "Passwords do not match.")]
        public string? PasswordConfirmation { get; set; }
    }
}
