using System.ComponentModel.DataAnnotations;

namespace F1Info_Tickets.Model.Requests
{
    public class RaceUpdateRequest
    {
        [Required(ErrorMessage = "Race name is required.")]
        [MaxLength(150, ErrorMessage = "Race name can have at most 150 characters.")]
        public string RaceName { get; set; } = string.Empty;

        [Range(1, int.MaxValue, ErrorMessage = "Select a circuit.")]
        public int CircuitID { get; set; }

        public DateTime Date { get; set; }
    }
}
