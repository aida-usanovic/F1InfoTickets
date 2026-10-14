using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace F1Info_Tickets.Services.Database
{
    public class RevokedToken
    {
        [Key]
        public int RevokedTokenID { get; set; }
        [Required]
        public string Jti { get; set; }
        public DateTime ExpiresAtUtc { get; set; }
    }
}
