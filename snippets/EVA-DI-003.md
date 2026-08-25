You will see the service-locator constructor throughout the estate. It works, and existing classes are not being rewritten, but **new** classes use plain constructor injection.

```csharp
// WRONG - dependencies are invisible from the signature, failures move to runtime
public PriceListBusiness(IServiceProvider serviceProvider)
{
    _repositories = serviceProvider.GetRequiredService<IPriceListRepositories>();
    _logger = serviceProvider.GetRequiredService<ILogger>();
    _httpContextAccessor = serviceProvider.GetRequiredService<IHttpContextAccessor>();
    _orgId = Convert.ToInt32(_httpContextAccessor.HttpContext.Items[KeyConstant.AppOrgId]);
}

// RIGHT - explicit, and a missing AddScoped fails loudly instead of silently
public PriceListBusiness(
    IPriceListRepositories repositories,
    ILogger logger,
    IHttpContextAccessor httpContextAccessor)
{
    _repositories = repositories;
    _logger = logger;
    _httpContextAccessor = httpContextAccessor;
    _orgId = Convert.ToInt32(_httpContextAccessor.HttpContext.Items[KeyConstant.AppOrgId]);
}
```

`ILogger` here is `EVA.Logging.Interface.ILogger`, not `Microsoft.Extensions.Logging.ILogger`.
