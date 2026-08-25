```csharp
// WRONG - both of these are injectable
var sql = $"SELECT * FROM FinishedGoods WHERE FgCode = '{fgCode}'";
var sql = "SELECT * FROM FinishedGoods WHERE FgCode = '" + fgCode + "'";

// RIGHT - a stored proc with typed parameters (the EvA default)
var sqlParams = new List<Parameters>
{
    new() { ParameterName = "OrgId",  Value = _orgId, ParameterType = SqlDbType.BigInt },
    new() { ParameterName = "FgCode", Value = fgCode, ParameterType = SqlDbType.NVarChar }
};
var rows = await _sqlExecuterStoreProc.ExecuteProcedureAsync<FinishedGoodModel>(
    ProcedureConstants.sp_GetFinishedGoodsByCode, sqlParams);
```

Interpolating a value that "can only ever be an int" still trips this rule, and
still breaks the day someone changes the parameter to a string.
