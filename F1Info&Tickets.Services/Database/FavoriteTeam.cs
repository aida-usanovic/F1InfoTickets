using System.ComponentModel.DataAnnotations;

namespace F1Info_Tickets.Services.Database
{
    public class FavoriteTeam
    {
        [Key]
        public int FavoriteTeamID { get; set; }
        public int UserID { get; set; }
        public int TeamID { get; set; }
        public DateTime CreatedAt { get; set; }
        public User User { get; set; } = null!;
        public Team Team { get; set; } = null!;
    }
}
