namespace F1Info_Tickets.Model.Requests
{
    public static class ValidationPatterns
    {
        public const string Phone = @"^\+?[0-9]{9,15}$";
        public const string PhoneMessage = "Enter a valid phone number: 9 to 15 digits, optionally starting with + (e.g. +38761123456).";
        public const string Username = @"^[a-zA-Z0-9._]{3,50}$";
        public const string UsernameMessage = "Username must have 3 to 50 characters: letters, digits, dot or underscore.";
        public const string RaceTime = @"^\d{1,2}:[0-5]\d:[0-5]\d(\.\d{1,3})?$";
        public const string RaceTimeMessage = "Time must be in the format h:mm:ss.fff (e.g. 1:32:15.123).";
    }
}
