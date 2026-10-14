using F1Info_Tickets.Model.Messaging;
using Microsoft.Extensions.Options;
using RabbitMQ.Client;
using RabbitMQ.Client.Events;
using System.Net;
using System.Net.Mail;
using System.Text;
using System.Text.Json;

namespace F1Info_Tickets.Worker
{
    // Consumes email messages published by the API and sends them over SMTP.
    // A message that cannot be sent is moved to the dead-letter queue instead of being retried forever.
    public class EmailWorker : BackgroundService
    {
        private readonly RabbitMqSettings _rabbit;
        private readonly SmtpSettings _smtp;
        private readonly ILogger<EmailWorker> _logger;

        public EmailWorker(IOptions<RabbitMqSettings> rabbit, IOptions<SmtpSettings> smtp, ILogger<EmailWorker> logger)
        {
            _rabbit = rabbit.Value;
            _smtp = smtp.Value;
            _logger = logger;
        }

        protected override async Task ExecuteAsync(CancellationToken stoppingToken)
        {
            var factory = new ConnectionFactory
            {
                HostName = _rabbit.Host,
                Port = _rabbit.Port,
                UserName = _rabbit.Username,
                Password = _rabbit.Password
            };

            IConnection? connection = null;
            while (connection == null && !stoppingToken.IsCancellationRequested)
            {
                try
                {
                    connection = await factory.CreateConnectionAsync("f1-email-worker", stoppingToken);
                    _logger.LogInformation("Email worker connected to RabbitMQ at {Host}:{Port}.", _rabbit.Host, _rabbit.Port);
                }
                catch (Exception ex)
                {
                    _logger.LogWarning(ex, "RabbitMQ is not ready. Retrying in 3 seconds.");
                    await Task.Delay(3000, stoppingToken);
                }
            }

            if (connection == null) return;

            var channel = await connection.CreateChannelAsync(cancellationToken: stoppingToken);
            await channel.QueueDeclareAsync(MessagingConstants.EmailDeadLetterQueue, durable: true, exclusive: false, autoDelete: false,
                cancellationToken: stoppingToken);
            await channel.QueueDeclareAsync(MessagingConstants.EmailQueue, durable: true, exclusive: false, autoDelete: false,
                arguments: MessagingConstants.EmailQueueArguments, cancellationToken: stoppingToken);
            await channel.BasicQosAsync(prefetchSize: 0, prefetchCount: 5, global: false, cancellationToken: stoppingToken);

            var consumer = new AsyncEventingBasicConsumer(channel);
            consumer.ReceivedAsync += async (_, ea) =>
            {
                try
                {
                    var message = JsonSerializer.Deserialize<EmailMessage>(Encoding.UTF8.GetString(ea.Body.Span));
                    if (message == null || string.IsNullOrWhiteSpace(message.ToEmail))
                    {
                        _logger.LogWarning("Discarding an email message without a recipient.");
                        await channel.BasicNackAsync(ea.DeliveryTag, multiple: false, requeue: false, cancellationToken: stoppingToken);
                        return;
                    }

                    await SendEmailAsync(message);
                    await channel.BasicAckAsync(ea.DeliveryTag, multiple: false, cancellationToken: stoppingToken);
                }
                catch (Exception ex)
                {
                    _logger.LogError(ex, "Email could not be sent; message moved to {Queue}.", MessagingConstants.EmailDeadLetterQueue);
                    await channel.BasicNackAsync(ea.DeliveryTag, multiple: false, requeue: false, cancellationToken: stoppingToken);
                }
            };

            await channel.BasicConsumeAsync(MessagingConstants.EmailQueue, autoAck: false, consumer: consumer, cancellationToken: stoppingToken);

            try
            {
                await Task.Delay(Timeout.Infinite, stoppingToken);
            }
            finally
            {
                await channel.DisposeAsync();
                await connection.DisposeAsync();
            }
        }

        private async Task SendEmailAsync(EmailMessage message)
        {
            using var client = new SmtpClient(_smtp.Host, _smtp.Port)
            {
                Credentials = new NetworkCredential(_smtp.Username, _smtp.Password),
                EnableSsl = _smtp.EnableSsl
            };

            using var mail = new MailMessage(new MailAddress(_smtp.Username, "F1 Info & Tickets"), new MailAddress(message.ToEmail, message.ToName))
            {
                Subject = message.Subject,
                Body = message.HtmlBody,
                IsBodyHtml = true,
                BodyEncoding = Encoding.UTF8,
                SubjectEncoding = Encoding.UTF8
            };

            await client.SendMailAsync(mail);
            _logger.LogInformation("Email \"{Subject}\" sent to {Email}.", message.Subject, message.ToEmail);
        }
    }
}
