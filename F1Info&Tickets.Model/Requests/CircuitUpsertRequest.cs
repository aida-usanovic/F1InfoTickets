using System.ComponentModel.DataAnnotations;

namespace F1Info_Tickets.Model.Requests
{
    public class CircuitUpsertRequest
    {
        [Required(ErrorMessage = "Circuit name is required.")]
        [MaxLength(150, ErrorMessage = "Circuit name can have at most 150 characters.")]
        public string Name { get; set; } = string.Empty;

        [Range(1, int.MaxValue, ErrorMessage = "Select a city.")]
        public int CityID { get; set; }

        [Range(1, int.MaxValue, ErrorMessage = "Select a track type.")]
        public int TrackTypeID { get; set; }

        [Range(1, 200, ErrorMessage = "Number of laps must be between 1 and 200.")]
        public int Laps { get; set; }

        [Range(1.0, 20.0, ErrorMessage = "Lap length must be between 1 and 20 km.")]
        public double LengthKm { get; set; }
    }
}
