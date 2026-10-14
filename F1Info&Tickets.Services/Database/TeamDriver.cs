using System.ComponentModel.DataAnnotations;

namespace F1Info_Tickets.Services.Database
{
    public class TeamDriver
    {
        [Key]
        public int TeamDriverID { get; set; }
        public int TeamID { get; set; }
        public int DriverID { get; set; }
        public int SeasonID { get; set; }
        public Team Team { get; set; } = null!;
        public Driver Driver { get; set; } = null!;
        public Season Season { get; set; } = null!;
    }
}
