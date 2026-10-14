using System.ComponentModel.DataAnnotations;

namespace F1Info_Tickets.Services.Database
{
    public class FavoriteDriver
    {
        [Key]
        public int FavoriteDriverID { get; set; }
        public int UserID { get; set; }
        public int DriverID { get; set; }
        public DateTime CreatedAt { get; set; }
        public User User { get; set; } = null!;
        public Driver Driver { get; set; } = null!;
    }
}
