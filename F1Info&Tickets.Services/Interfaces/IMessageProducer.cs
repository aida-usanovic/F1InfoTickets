using F1Info_Tickets.Model.Messaging;

namespace F1Info_Tickets.Services.Interfaces
{
    public interface IMessageProducer
    {
        Task PublishEmailAsync(EmailMessage message);
    }
}
