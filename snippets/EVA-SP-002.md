```csharp
// WRONG - no ParameterType, so the reflection mapper mis-binds and the proc
//         sees a NULL, with no exception to tell you
var sqlParams = new List<Parameters>()
{
    new() { ParameterName = "OrgId", Value = _orgId },
    new() { ParameterName = "PriceListId", Value = InputModel.PriceListId }
};

// RIGHT - all four properties, every time
var sqlParams = new List<Parameters>()
{
    new() { ParameterName = "OrgId",       Value = _orgId,                 ParameterType = SqlDbType.BigInt,  ParameterDirection = ParameterDirection.Input },
    new() { ParameterName = "PriceListId", Value = InputModel.PriceListId, ParameterType = SqlDbType.BigInt,  ParameterDirection = ParameterDirection.Input },
    new() { ParameterName = "Code",        Value = InputModel.Code,        ParameterType = SqlDbType.VarChar, ParameterDirection = ParameterDirection.Input },
    new() { ParameterName = "TotalCount",  Value = 0,                      ParameterType = SqlDbType.Int,     ParameterDirection = ParameterDirection.Output }
};
```

Match the `SqlDbType` to the column, not to the C# type: a SQL `bigint` is `SqlDbType.BigInt` even though `int` would compile.
