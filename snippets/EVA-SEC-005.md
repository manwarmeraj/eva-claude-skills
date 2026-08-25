```csharp
// WRONG - injectable, and a fresh query plan for every distinct value
var sql = $"SELECT * FROM PriceList WHERE OrgId = {orgId} AND Code = '{code}'";
var rows = await connection.QueryAsync<PriceListModel>(sql);

// RIGHT - parameterised via an anonymous object
var rows = await connection.QueryAsync<PriceListModel>(
    "SELECT * FROM PriceList WHERE OrgId = @OrgId AND Code = @Code",
    new { OrgId = _orgId, Code = code });

// RIGHT - DynamicParameters, when the set is built conditionally
var p = new DynamicParameters();
p.Add("@OrgId", _orgId, DbType.Int64);
p.Add("@Code", code, DbType.String);
var rows = await connection.QueryAsync<PriceListModel>(sql, p);
```

Dapper is the least-used of the three data paths in EvA. Reach for `IExecuterSqlProc` first and use Dapper only where a stored proc genuinely does not fit.
