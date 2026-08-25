Writing the interface and the class is two thirds of the job. The third part is the registration, and forgetting it is the **single most common break** in EvA: it compiles cleanly, then fails on the first request with `Unable to resolve service for type 'IPriceListBusiness'`.

`EVA.<Domain>.API\Infrastructure\DIConfiguration.cs`:

```csharp
public static void CustomDependencies(IServiceCollection services)
{
    // ...existing registrations...

    // RIGHT - always a pair, always Scoped: Business and Repository together
    services.AddScoped<IPriceListBusiness, PriceListBusiness>();
    services.AddScoped<IPriceListRepositories, PriceListRepositories>();
}
```

```csharp
// WRONG - Singleton holds a DbContext across requests, and across tenants
services.AddSingleton<IPriceListBusiness, PriceListBusiness>();

// WRONG - Transient breaks the shared UnitOfWork inside one request
services.AddTransient<IPriceListRepositories, PriceListRepositories>();
```

All 221 registrations in the platform are `AddScoped`. There is no assembly scanning and no convention-based discovery: if it is not in this file, it does not exist.
