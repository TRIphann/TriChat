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
using Microsoft.OpenApi.Models;
using Serilog;
using backend.swagger;

var builder = WebApplication.CreateBuilder(args);

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

// CORS — allow Netlify SPA and SignalR WebSocket connections
var allowedOrigins = builder.Environment.IsDevelopment()
    ? new[] {
        "http://localhost:5000", "http://localhost:5244",
        "http://127.0.0.1:5000", "http://127.0.0.1:5244"
      }
    : new[] {
        "https://trichatt.netlify.app",
        "https://www.trichatt.netlify.app"
      };

builder.Services.AddCors(opt =>
{
    opt.AddDefaultPolicy(policy =>
        policy
            .AllowAnyHeader()
            .AllowAnyMethod()
            .WithOrigins(allowedOrigins)
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

if (!app.Environment.IsDevelopment())
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
