using System.ComponentModel.DataAnnotations;

namespace F1Info_Tickets.Services.Database
{
    // Logged each time a user opens race details; used by the recommender.
    public class RaceView
    {
        [Key]
        public int RaceViewID { get; set; }
        public int UserID { get; set; }
        public int RaceID { get; set; }
        public DateTime ViewedAt { get; set; }
        public User User { get; set; } = null!;
        public Race Race { get; set; } = null!;
    }
}
