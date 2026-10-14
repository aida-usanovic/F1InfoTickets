namespace F1Info_Tickets.Model.Responses
{
    public class RoleResponse
    {
        public int RoleID { get; set; }
        public string Name { get; set; } = string.Empty;
        public bool IsSystemRole { get; set; }
    }
}
