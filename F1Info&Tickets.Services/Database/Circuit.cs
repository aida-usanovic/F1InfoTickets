using System.ComponentModel.DataAnnotations;

namespace F1Info_Tickets.Services.Database
{
    public class Circuit
    {
        [Key]
        public int CircuitID { get; set; }
        [Required, MaxLength(150)]
        public string Name { get; set; } = string.Empty;
        public int CityID { get; set; }
        public int TrackTypeID { get; set; }
        public int Laps { get; set; }
        public double LengthKm { get; set; }
        [MaxLength(300)]
        public string? ImageUrl { get; set; }
        public City City { get; set; } = null!;
        public TrackType TrackType { get; set; } = null!;
        public ICollection<Race> Races { get; set; } = new List<Race>();
    }
}
