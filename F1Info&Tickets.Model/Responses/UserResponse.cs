namespace F1Info_Tickets.Model.Responses
{
    public class UserResponse
    {
        public int UserID { get; set; }
        public string FirstName { get; set; } = string.Empty;
        public string LastName { get; set; } = string.Empty;
        public string Email { get; set; } = string.Empty;
        public string Username { get; set; } = string.Empty;
        public string Phone { get; set; } = string.Empty;
        public DateTime BirthDate { get; set; }
        public int RoleID { get; set; }
        public string? RoleName { get; set; }
        public string? PhotoUrl { get; set; }
    }
}
