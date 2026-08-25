```csharp
// WRONG - exhausts sockets under load, ignores DNS changes
using var client = new HttpClient();

// RIGHT - IHttpClientFactory is already registered in Startup (services.AddHttpClient())
public class FgIntegrationRepository : IFgIntegrationRepository
{
    private readonly IHttpClientFactory _httpClientFactory;

    public FgIntegrationRepository(IHttpClientFactory httpClientFactory)
    {
        _httpClientFactory = httpClientFactory;
    }

    public async Task<BaseResponse<string>> Push(FgPushModel model)
    {
        var client = _httpClientFactory.CreateClient();
        // ...
    }
}
```
