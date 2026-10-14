namespace F1Info_Tickets.Model.Messaging
{
    // Shared by the API (producer) and the worker (consumer) so both declare the queues the same way.
    public static class MessagingConstants
    {
        public const string EmailQueue = "email_notifications";
        public const string EmailDeadLetterQueue = "email_notifications.dead";

        public static Dictionary<string, object?> EmailQueueArguments => new()
        {
            ["x-dead-letter-exchange"] = string.Empty,
            ["x-dead-letter-routing-key"] = EmailDeadLetterQueue
        };
    }
}
