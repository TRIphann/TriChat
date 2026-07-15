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

// Disable file watching on containerised Linux (avoids inotify limit on Render)
if (Environment.GetEnvironmentVariable("ASPNETCORE_ENVIRONMENT") != "Development")
{
    AppContext.SetSwitch("Microsoft.AspNetCore.Server.Kestrel.AllowSynchronousIO", true);
}

var builder = WebApplication.CreateBuilder(args);

// Clear default config sources (appsettings.json) to avoid inotify on Linux containers
// All config must come from environment variables
if (builder.Environment.IsProduction())
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

builder.Services.AddHttpClient<IKeyValueStore, UpstashRedisService>();

builder.Services.Configure<ResendSettings>(
    builder.Configuration.GetSection("Resend"));

builder.Services.AddHttpClient("resend", client =>
{
    client.BaseAddress = new Uri("https://api.resend.com/");
    // Resend p95 < 1s; SMTP timeout used to be 15s. Keep a generous ceiling
    // so the network blip on Render's free tier doesn't kill the request.
    client.Timeout = TimeSpan.FromSeconds(15);
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
        "https://trichatt.netlify.app",
        "https://www.trichatt.netlify.app"
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
