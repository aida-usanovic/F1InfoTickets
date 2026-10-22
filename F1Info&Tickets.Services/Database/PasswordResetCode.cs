using System.ComponentModel.DataAnnotations;

namespace F1Info_Tickets.Services.Database
{
    // One-time code for resetting a forgotten password. Only a hash of the code is stored.
    public class PasswordResetCode
    {
        [Key]
        public int PasswordResetCodeID { get; set; }
        public int UserID { get; set; }
        [Required]
        [MaxLength(64)]
        public string CodeHash { get; set; } = string.Empty;
        public DateTime CreatedAt { get; set; }
        public DateTime ExpiresAt { get; set; }
        public DateTime? UsedAt { get; set; }
        public int FailedAttempts { get; set; }

        public User User { get; set; } = null!;
    }
}
