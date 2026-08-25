```csharp
// WRONG - resolves nothing; EvA does not register Microsoft's generic logger
private readonly ILogger<FgDesignRepository> _logger;   // Microsoft.Extensions.Logging

// RIGHT - EVA.Logging.Interface.ILogger, registered AddScoped<ILogger, Logger>()
private readonly ILogger _logger;                       // aliased in using.cs

public FgDesignRepository(ILogger logger)
{
    _logger = logger;
}
```

The EvA logger has one fixed four-argument signature and routes to
NLog / Blob / Elastic depending on `LoggerConfig.LogWriteType`:

```csharp
void Error(string className, string methodName, string message, string stackTrace);
```

There is no `LogInformation`, no message template, no structured-logging overload.
