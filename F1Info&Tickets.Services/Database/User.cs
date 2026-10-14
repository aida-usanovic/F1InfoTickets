using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using System.Linq;
using System.Net.Sockets;
using System.Text;
using System.Threading.Tasks;

namespace F1Info_Tickets.Services.Database
{
    public class User
    {
        [Key]
        [DatabaseGenerated(DatabaseGeneratedOption.Identity)]
        public int UserID { get; set; }

        [Required]
        [MaxLength(50)]
        public string FirstName { get; set; }

        [Required]
        [MaxLength(50)]
        public string LastName { get; set; }

        [Required]
        [EmailAddress, MaxLength(100)]
        public string Email { get; set; }
        
        [Required, MaxLength(50)]
        public string Username { get; set; }

        [Required, MaxLength(20)]
        public string Phone { get; set; }

        public DateTime BirthDate { get; set; }

        [Required]
        public string PasswordHash { get; set; }

        public ICollection<UserRole> UserRoles { get; set; }
        public ICollection<Payment> Payments { get; set; }
        public ICollection<Ticket> Tickets { get; set; }
        public Cart? Cart { get; set; }
    }
}
