namespace F1Info_Tickets.Worker
{
    // Bound from the "Smtp" configuration section (Smtp__Host, Smtp__Port, ... in docker-compose).
    public class SmtpSettings
    {
        public string Host { get; set; } = string.Empty;
        public int Port { get; set; }
        public string Username { get; set; } = string.Empty;
        public string Password { get; set; } = string.Empty;
        public bool EnableSsl { get; set; }
    }
}
