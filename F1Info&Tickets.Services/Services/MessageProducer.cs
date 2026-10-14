using F1Info_Tickets.Model.Messaging;
using F1Info_Tickets.Services.Interfaces;
using Microsoft.Extensions.Options;
using RabbitMQ.Client;
using System.Text;
using System.Text.Json;

namespace F1Info_Tickets.Services.Services
{
    // Singleton: one RabbitMQ connection for the whole API, a short-lived channel per message.
    public sealed class MessageProducer : IMessageProducer, IAsyncDisposable
    {
        private readonly RabbitMqSettings _settings;
        private readonly SemaphoreSlim _connectionLock = new(1, 1);
        private IConnection? _connection;

        public MessageProducer(IOptions<RabbitMqSettings> settings)
        {
            _settings = settings.Value;
        }

        public async Task PublishEmailAsync(EmailMessage message)
        {
            var connection = await GetConnectionAsync();
            await using var channel = await connection.CreateChannelAsync();

            await channel.QueueDeclareAsync(MessagingConstants.EmailDeadLetterQueue, durable: true, exclusive: false, autoDelete: false);
            await channel.QueueDeclareAsync(MessagingConstants.EmailQueue, durable: true, exclusive: false, autoDelete: false,
                arguments: MessagingConstants.EmailQueueArguments);

            var body = Encoding.UTF8.GetBytes(JsonSerializer.Serialize(message));
            var properties = new BasicProperties { Persistent = true, ContentType = "application/json" };
            await channel.BasicPublishAsync(string.Empty, MessagingConstants.EmailQueue, mandatory: false, basicProperties: properties, body: body);
        }

        private async Task<IConnection> GetConnectionAsync()
        {
            if (_connection is { IsOpen: true }) return _connection;

            await _connectionLock.WaitAsync();
            try
            {
                if (_connection is { IsOpen: true }) return _connection;
                if (string.IsNullOrWhiteSpace(_settings.Host))
                    throw new InvalidOperationException("RabbitMQ:Host is not configured.");

                var factory = new ConnectionFactory
                {
                    HostName = _settings.Host,
                    Port = _settings.Port,
                    UserName = _settings.Username,
                    Password = _settings.Password
                };
                _connection = await factory.CreateConnectionAsync("f1-api");
                return _connection;
            }
            finally
            {
                _connectionLock.Release();
            }
        }

        public async ValueTask DisposeAsync()
        {
            if (_connection != null) await _connection.DisposeAsync();
            _connectionLock.Dispose();
        }
    }
}
