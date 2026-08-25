```csharp
// WRONG - the name drifts the moment the DBA renames the proc
var rows = await _sqlExecuterStoreProc
    .ExecuteProcedureAsync<PriceListResultModel>("sp_GetActivePriceList", sqlParams);

// RIGHT - one place to change, and the compiler finds every call site
var rows = await _sqlExecuterStoreProc
    .ExecuteProcedureAsync<PriceListResultModel>(ProcedureConstants.sp_GetActivePriceList, sqlParams);
```

The constant lives beside its siblings in `EVA.<Domain>.Common\Constants\ProcedureConstants.cs`:

```csharp
public const string sp_GetActivePriceList = "sp_GetActivePriceList";
```

`sp_PascalCase` on the constant is deliberate - see [anti-rules.md](anti-rules.md). Do not rename it to `SpGetActivePriceList`.
