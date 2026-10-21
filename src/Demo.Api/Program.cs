using Demo.Api;

var builder = WebApplication.CreateBuilder(args);
builder.Services.AddHealthChecks();
builder.Services.AddSingleton<PriceCalculator>();

var app = builder.Build();

// Used by the pipeline's post-deploy health check
app.MapHealthChecks("/health");

app.MapGet("/", () => new { service = "Demo.Api", version = typeof(Program).Assembly.GetName().Version?.ToString() });

app.MapGet("/api/price", (decimal amount, int quantity, PriceCalculator calc) =>
    Results.Ok(new { total = calc.Total(amount, quantity) }));

app.Run();

public partial class Program { }
