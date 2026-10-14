namespace F1Info_Tickets.Model.Messaging
{
    // Published by the API on RabbitMQ and sent by the worker over SMTP.
    public class EmailMessage
    {
        public string ToEmail { get; set; } = string.Empty;
        public string ToName { get; set; } = string.Empty;
        public string Subject { get; set; } = string.Empty;
        public string HtmlBody { get; set; } = string.Empty;
    }
}
