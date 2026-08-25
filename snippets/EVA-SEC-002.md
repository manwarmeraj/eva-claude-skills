```csharp
// WRONG - proc runs unscoped
var sqlParams = new List<Parameters>
{
    new() { ParameterName = "OpportunityQuotesId", Value = quoteId, ParameterType = SqlDbType.BigInt }
};

// RIGHT - OrgId is always the first parameter
var sqlParams = new List<Parameters>
{
    new() { ParameterName = "OrgId", Value = _orgId, ParameterType = SqlDbType.BigInt, ParameterDirection = ParameterDirection.Input },
    new() { ParameterName = "OpportunityQuotesId", Value = quoteId, ParameterType = SqlDbType.BigInt, ParameterDirection = ParameterDirection.Input }
};
await _sqlExecuterStoreProc.ExecuteProcedureAsync<int>(ProcedureConstants.sp_CopyExtraCostHeads, sqlParams);
```
