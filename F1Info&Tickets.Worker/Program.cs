using F1Info_Tickets.Model.Messaging;
using F1Info_Tickets.Worker;

var builder = Host.CreateApplicationBuilder(args);

builder.Services.Configure<RabbitMqSettings>(builder.Configuration.GetSection("RabbitMQ"));
builder.Services.Configure<SmtpSettings>(builder.Configuration.GetSection("Smtp"));
builder.Services.AddHostedService<EmailWorker>();

var host = builder.Build();
host.Run();
