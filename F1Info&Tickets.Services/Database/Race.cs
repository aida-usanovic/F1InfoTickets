using System.ComponentModel.DataAnnotations;

namespace F1Info_Tickets.Services.Database
{
    public class Race
    {
        [Key]
        public int RaceID { get; set; }
        [Required, MaxLength(150)]
        public string RaceName { get; set; } = string.Empty;
        public DateTime Date { get; set; }
        public int CircuitID { get; set; }
        public int SeasonID { get; set; }
        public Circuit Circuit { get; set; } = null!;
        public Season Season { get; set; } = null!;
        public ICollection<Result> Results { get; set; } = new List<Result>();
        public ICollection<RaceTicketCategory> TicketCategories { get; set; } = new List<RaceTicketCategory>();
        public ICollection<RaceView> Views { get; set; } = new List<RaceView>();
    }
}
