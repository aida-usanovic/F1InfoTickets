using F1Info_Tickets.Model.Messaging;
using F1Info_Tickets.Services;
using F1Info_Tickets.Services.Configuration;
using F1Info_Tickets.Services.Interfaces;
using F1Info_Tickets.Services.Seed;
using F1Info_Tickets.Services.Services;
using F1Info_Tickets.WebAPI.Json;
using F1Info_Tickets.WebAPI.Middleware;
using Mapster;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.FileProviders;
using Microsoft.IdentityModel.Tokens;
using Microsoft.OpenApi.Models;
using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;

var builder = WebApplication.CreateBuilder(args);

// All settings come from configuration (docker-compose passes them from .env); nothing is hardcoded here.
string RequiredSetting(string key) => builder.Configuration[key] is { Length: > 0 } value
    ? value
    : throw new InvalidOperationException($"Configuration value '{key}' is missing. Set it in the .env file.");

var connectionString = RequiredSetting("ConnectionStrings:DefaultConnection");
var jwtKey = RequiredSetting("Jwt:Key");

builder.Services.AddDbContext<ApplicationDbContext>(options =>
    options.UseSqlServer(connectionString, sqlOptions => sqlOptions.EnableRetryOnFailure()));

builder.Services.Configure<PayPalSettings>(builder.Configuration.GetSection("PayPal"));
builder.Services.Configure<RabbitMqSettings>(builder.Configuration.GetSection("RabbitMQ"));

builder.Services.AddScoped<IUserService, UserService>();
builder.Services.AddScoped<IRoleService, RoleService>();
builder.Services.AddScoped<IContinentService, ContinentService>();
builder.Services.AddScoped<ICountryService, CountryService>();
builder.Services.AddScoped<ICityService, CityService>();
builder.Services.AddScoped<ITrackTypeService, TrackTypeService>();
builder.Services.AddScoped<ITicketTypeService, TicketTypeService>();
builder.Services.AddScoped<ISeasonService, SeasonService>();
builder.Services.AddScoped<IDriverService, DriverService>();
builder.Services.AddScoped<ITeamService, TeamService>();
builder.Services.AddScoped<ICircuitService, CircuitService>();
builder.Services.AddScoped<IRaceService, RaceService>();
builder.Services.AddScoped<IResultService, ResultService>();
builder.Services.AddScoped<IRaceTicketCategoryService, RaceTicketCategoryService>();
builder.Services.AddScoped<ICartService, CartService>();
builder.Services.AddScoped<ITicketService, TicketService>();
builder.Services.AddScoped<IFavoriteService, FavoriteService>();
builder.Services.AddScoped<INotificationService, NotificationService>();
builder.Services.AddScoped<IAnalyticsService, AnalyticsService>();
builder.Services.AddScoped<IRecommenderService, RecommenderService>();
builder.Services.AddSingleton<IMessageProducer, MessageProducer>();
builder.Services.AddHttpClient<IPaymentService, PaymentService>();

MapsterConfiguration.Configure();
builder.Services.AddMapster();

builder.Services.AddControllers()
    .AddJsonOptions(o => o.JsonSerializerOptions.Converters.Add(new UtcDateTimeConverter()));
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen(c =>
{
    c.SwaggerDoc("v1", new OpenApiInfo { Title = "F1 Info & Tickets API", Version = "v1" });
    var scheme = new OpenApiSecurityScheme
    {
        Name = "Authorization",
        Type = SecuritySchemeType.Http,
        Scheme = "bearer",
        BearerFormat = "JWT",
        In = ParameterLocation.Header,
        Reference = new OpenApiReference { Type = ReferenceType.SecurityScheme, Id = "Bearer" }
    };
    c.AddSecurityDefinition("Bearer", scheme);
    c.AddSecurityRequirement(new OpenApiSecurityRequirement { [scheme] = Array.Empty<string>() });
});

builder.Services.AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
    .AddJwtBearer(options =>
    {
        options.TokenValidationParameters = new TokenValidationParameters
        {
            ValidateIssuer = true,
            ValidateAudience = true,
            ValidateLifetime = true,
            ValidateIssuerSigningKey = true,
            ValidIssuer = builder.Configuration["Jwt:Issuer"],
            ValidAudience = builder.Configuration["Jwt:Audience"],
            IssuerSigningKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(jwtKey)),
        };

        options.Events = new JwtBearerEvents
        {
            OnTokenValidated = async context =>
            {
                var jti = context.Principal?.FindFirstValue(JwtRegisteredClaimNames.Jti);
                var db = context.HttpContext.RequestServices.GetRequiredService<ApplicationDbContext>();
                if (!string.IsNullOrEmpty(jti) && await db.RevokedTokens.AnyAsync(r => r.Jti == jti))
                {
                    context.Fail("The token has been revoked (logout).");
                }
            }
        };
    });

builder.Services.AddAuthorization();

var app = builder.Build();

app.UseMiddleware<ExceptionMiddleware>();

app.UseSwagger();
app.UseSwaggerUI();

// Seeded images live in wwwroot/Images, uploaded ones in wwwroot/uploads (served under /images).
var uploadsPath = Path.Combine(builder.Environment.ContentRootPath, "wwwroot", "uploads");
Directory.CreateDirectory(uploadsPath);
app.UseStaticFiles();
app.UseStaticFiles(new StaticFileOptions
{
    FileProvider = new PhysicalFileProvider(uploadsPath),
    RequestPath = "/images"
});

app.UseAuthentication();
app.UseAuthorization();

using (var scope = app.Services.CreateScope())
{
    var context = scope.ServiceProvider.GetRequiredService<ApplicationDbContext>();
    await SeedData.InitializeAsync(context);
}

app.MapControllers();

app.Run();
