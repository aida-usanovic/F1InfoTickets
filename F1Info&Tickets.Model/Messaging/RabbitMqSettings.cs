namespace F1Info_Tickets.Model.Messaging
{
    // Bound from the "RabbitMQ" configuration section (RabbitMQ__Host, RabbitMQ__Port, ... in docker-compose).
    public class RabbitMqSettings
    {
        public string Host { get; set; } = string.Empty;
        public int Port { get; set; }
        public string Username { get; set; } = string.Empty;
        public string Password { get; set; } = string.Empty;
    }
}
