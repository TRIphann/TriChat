using System.Reflection;
using backend.Attributes;
using backend.Hubs;
using backend.Interfaces;
using backend.Middleware;
using backend.Services;
using backend.settings;
using FluentValidation;
using FluentValidation.AspNetCore;
using Mapster;
using MapsterMapper;
using Microsoft.Extensions.Configuration;
using Microsoft.OpenApi.Models;
using Serilog;
using backend.swagger;

// Disable inotify-based file watching on Linux containers (Render has low inotify limits)
// Polling watcher will be used instead when file watching is needed
Environment.SetEnvironmentVariable("DOTNET_USE_POLLING_FILE_WATCHER", "1");
Environment.SetEnvironmentVariable("POLLING_INTERVAL", "10000");

if (Environment.GetEnvironmentVariable("ASPNETCORE_ENVIRONMENT") != "Development")
{
    AppContext.SetSwitch("Microsoft.AspNetCore.Server.Kestrel.AllowSynchronousIO", true);
}

var builder = WebApplication.CreateBuilder(args);

// In production, only use environment variables for configuration
// This avoids loading any JSON files that would create FileSystemWatchers
if (!builder.Environment.IsDevelopment())
{
    builder.Configuration.Sources.Clear();
    builder.Configuration.AddEnvironmentVariables();
}

builder.Services.AddHostedService<StoryExpirationService>();
builder.Services.AddHostedService<DisappearingMessageService>();

builder.Host.UseSerilog((ctx, config) => config
    .ReadFrom.Configuration(ctx.Configuration)
    .Enrich.FromLogContext()
    .WriteTo.Console(outputTemplate:
        "[{Timestamp:HH:mm:ss} {Level:u3}] {SourceContext} | {Message}{NewLine}{Exception}"));

builder.Services.Configure<UpstashRedisSettings>(
    builder.Configuration.GetSection("Redis"));

// Log Redis config at startup for debugging
var redisSection = builder.Configuration.GetSection("Redis");
Console.WriteLine($"[CONFIG] Redis.RestUrl: '{redisSection["RestUrl"]}'");
Console.WriteLine($"[CONFIG] Redis.RestToken: '{(string.IsNullOrEmpty(redisSection["RestToken"]) ? "NOT SET" : "***" + redisSection["RestToken"]?.TakeLast(4).ToString())}'");

builder.Services.AddHttpClient<IKeyValueStore, UpstashRedisService>();

builder.Services.Configure<MailgunSettings>(
    builder.Configuration.GetSection("Mailgun"));

// Log Mailgun config at startup for debugging
var mailgunSection = builder.Configuration.GetSection("Mailgun");
Console.WriteLine($"[CONFIG] Mailgun.Domain: '{mailgunSection["Domain"]}'");
Console.WriteLine($"[CONFIG] Mailgun.ApiKey: '{(string.IsNullOrEmpty(mailgunSection["ApiKey"]) ? "NOT SET" : "***SET")}'");

builder.Services.AddHttpClient("mailgun", client =>
{
    client.BaseAddress = new Uri("https://api.mailgun.net/v3/");
    client.Timeout = TimeSpan.FromSeconds(30);
});

builder.Services.Configure<CloudinarySettings>(
    builder.Configuration.GetSection("Cloudinary"));

var mapsterConfig = TypeAdapterConfig.GlobalSettings;
mapsterConfig.Scan(Assembly.GetExecutingAssembly());
builder.Services.AddSingleton(mapsterConfig);
builder.Services.AddScoped<IMapper, ServiceMapper>();

builder.Services.AddFluentValidationAutoValidation();
builder.Services.AddValidatorsFromAssemblyContaining<Program>();

builder.Services.Scan(scan => scan
    .FromAssemblyOf<Program>()
    .AddClasses(c => c.WithAttribute<ScopedServiceAttribute>())
    .AsSelf()
    .WithScopedLifetime());

builder.Services.AddTransient<GlobalExceptionHandler>();

builder.Services.AddSingleton<FirebaseService>();
builder.Services.AddSingleton(sp =>
    sp.GetRequiredService<FirebaseService>().FirestoreDb);

builder.Services.AddControllers()
    .AddJsonOptions(options =>
    {
        options.JsonSerializerOptions.PropertyNamingPolicy = System.Text.Json.JsonNamingPolicy.SnakeCaseLower;
    });
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen(options =>
{
    var xmlFile = $"{Assembly.GetExecutingAssembly().GetName().Name}.xml";
    var xmlPath = Path.Combine(AppContext.BaseDirectory, xmlFile);
    options.IncludeXmlComments(xmlPath);

    options.OperationFilter<AuthorizeCheckOperationFilter>();

    options.AddSecurityDefinition("Bearer", new OpenApiSecurityScheme
    {
        Name = "Authorization",
        Type = SecuritySchemeType.Http,
        Scheme = "Bearer",
        BearerFormat = "JWT",
        In = ParameterLocation.Header,
        Description = "Nhập token theo định dạng: Bearer {token}"
    });

    options.ResolveConflictingActions(apiDescriptions => apiDescriptions.First());
});

// CORS — allow Netlify SPA and SignalR WebSocket connections.
// Additional origins can be injected at runtime via the `BackendAllowedOrigins`
// CSV env var (writes "AllowedCorsOrigins" into appsettings.json).
var allowedOrigins = builder.Environment.IsDevelopment()
    ? new List<string> {
        "http://localhost:5000", "http://localhost:5244",
        "http://127.0.0.1:5000", "http://127.0.0.1:5244"
      }
    : new List<string> {
        "https://trichat.onrender.com",
        "http://trichat.onrender.com",
        "https://trichatt.netlify.app",
        "http://trichatt.netlify.app"
      };

var extraOrigins = builder.Configuration["AllowedCorsOrigins"];
if (!string.IsNullOrWhiteSpace(extraOrigins))
{
    foreach (var raw in extraOrigins.Split(',', StringSplitOptions.RemoveEmptyEntries | StringSplitOptions.TrimEntries))
    {
        if (!allowedOrigins.Contains(raw)) allowedOrigins.Add(raw);
    }
}

builder.Services.AddCors(opt =>
{
    opt.AddDefaultPolicy(policy =>
        policy
            .AllowAnyHeader()
            .AllowAnyMethod()
            .WithOrigins(allowedOrigins.ToArray())
            .AllowCredentials());
});

// SignalR — configured with larger message size for web
builder.Services.AddSignalR(opts =>
{
    opts.MaximumReceiveMessageSize = 102400; // 100 KB
})
    .AddJsonProtocol(opts =>
        opts.PayloadSerializerOptions.PropertyNamingPolicy =
            System.Text.Json.JsonNamingPolicy.SnakeCaseLower);

var app = builder.Build();

app.Services.GetRequiredService<FirebaseService>();

app.UseMiddleware<GlobalExceptionHandler>();

// Render terminates TLS at its edge proxy and forwards plain HTTP to the container.
// UseHttpsRedirection with the default empty HTTPS config on Production throws at
// startup on Render, so we only enable it for local dev.
if (app.Environment.IsDevelopment())
{
    app.UseHttpsRedirection();
}

if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

app.UseRouting();
app.UseCors();
app.UseMiddleware<FirebaseAuthMiddleware>();
app.UseAuthentication();
app.UseAuthorization();

app.MapControllers();
app.MapHub<ChatHub>("/hubs/chat");
app.MapHub<FriendHub>("/hubs/friend");

app.Run();
