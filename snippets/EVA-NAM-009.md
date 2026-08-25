The pipeline is `AddNewtonsoftJson`, so `System.Text.Json` attributes are **silently ignored**: the property serialises under its C# name and the client quietly receives the wrong key. Nothing warns you, and it compiles.

```csharp
// WRONG - ships, does nothing, wire name stays "PriceListId"
using System.Text.Json.Serialization;

public class PriceListModel
{
    [JsonPropertyName("priceListId")]
    public long PriceListId { get; set; }
}

// RIGHT - Newtonsoft, the serialiser that actually runs
using Newtonsoft.Json;

public class PriceListModel
{
    [JsonProperty("priceListId")]
    public long PriceListId { get; set; }
}
```

45 `[JsonPropertyName]` usages already exist in the platform and every one is inert. If you are editing a file that has them, correcting them changes the API contract on the wire - raise it, do not do it silently as a drive-by.
