using System.ComponentModel.DataAnnotations;

namespace F1Info_Tickets.Model.Requests
{
    public class RoleUpsertRequest
    {
        [Required(ErrorMessage = "Role name is required.")]
        [MaxLength(50, ErrorMessage = "Role name can have at most 50 characters.")]
        public string Name { get; set; } = string.Empty;
    }
}
