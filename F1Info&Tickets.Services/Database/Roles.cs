namespace F1Info_Tickets.Services.Database
{
    // Built-in roles the authorization rules depend on.
    public static class Roles
    {
        public const string Admin = "Admin";
        public const string User = "User";

        public static bool IsSystemRole(string name) => name == Admin || name == User;
    }
}
