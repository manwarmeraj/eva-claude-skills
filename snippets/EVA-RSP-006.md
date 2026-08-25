`ErrorHandlingMiddleware` maps a route to the response code its unhandled failures should surface. A route missing from the map falls back to `Err_UnhandledException`, so the client sees a generic code instead of the real reason.

```csharp
// EVA.<Domain>.API\Infrastructure\ErrorHandlingMiddleware.cs
private static readonly Dictionary<string, ResponseCode> _endpointResponseMap = new(StringComparer.OrdinalIgnoreCase)
{
    // ...existing entries...
    { "/api/pricing/PriceList/GetActive", ResponseCode.Err_PriceList_LoadFailed }
};
```

The key is the **full request path including the module prefix**, written the way the route renders
it — the comparer is `OrdinalIgnoreCase`, so casing is forgiving but the segments must match.

The enum name differs by repo (`ResponseCode` in `eva-crm-api`, `ResponseType` in
`EVA.FinishedGoods.API`). Read the local one.

Add an entry when the endpoint has a meaningful failure code of its own; skip it when the generic
unhandled code really is the right answer.
