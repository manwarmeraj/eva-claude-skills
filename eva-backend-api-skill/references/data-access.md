# Data access

Three mechanisms, one tenancy model, and a schema workflow that lives in a different repo.

> **Repositories return raw shapes.** No `BaseResponse<T>`, no `ResponseType`, no `.Success(...)` /
> `.Failure(...)` anywhere in this layer — the envelope is built in the Business layer
> ([`EVA-RSP-007`](rules.md#eva-rsp-007)). Signal "nothing found" with an empty list or `null`, and a
> failed write with `false` or an affected-row count of `0`. Every example below follows that.

---

## 1. Choosing a mechanism

| Use | When | Rule |
|---|---|---|
| **`IExecuterSqlProc`** | Anything the DBAs have written a proc for. **The dominant path in EvA.** | [`EVA-SP-001`](rules.md#eva-sp-001), [`EVA-SP-002`](rules.md#eva-sp-002) |
| **EF Core** via `IUnitOfWork` | Straightforward entity CRUD and simple projections | [`EVA-SEC-001`](rules.md#eva-sec-001) |
| **Dapper** | Rare. Only where a proc genuinely does not fit and EF cannot express the query. | [`EVA-SEC-005`](rules.md#eva-sec-005) |

When in doubt, look at what the neighbouring repository methods do. Do not introduce Dapper into a
repository that does not already use it.

---

## 2. Tenancy — two mechanisms, both mandatory

This is the highest-risk area in the platform. Getting one right does not cover the other.

### (a) The database is chosen per request

`AuthorizationTokenFilter` reads the JWT and puts the claims into `HttpContext.Items`. The
`DbContext.OnConfiguring` override then builds the connection string from them:

```csharp
protected override void OnConfiguring(DbContextOptionsBuilder optionsBuilder)
{
    ImsClaimDetailsModel claims = HttpContextExtension.GetTokenClaimsLists(_httpContextAccessor, _appSetting);
    if (claims != null)
    {
        string connectionString = _buildConnectionString.PreparedConnection(claims.tid);
        optionsBuilder.UseSqlServer(connectionString);
    }
}
```

`PreparedConnection` decodes the Base64 base connection string from `appsettings.json`, swaps
`Server` (from the `sid` claim, itself Base64) and `Initial Catalog` (the `tid` claim), and returns
it. You never write this code — it already exists in every repo. **Do not bypass it** by constructing
a `SqlConnection` yourself.

A request with no JWT claims cannot resolve a connection at all.

### (b) Rows are still filtered by `OrgId`

One tenant database holds many organisations. `_orgId` is read once in the constructor:

```csharp
_orgId = Convert.ToInt32(_httpContextAccessor.HttpContext.Items[KeyConstant.AppOrgId]);
```

and then applied to **every** query and **every** proc call:

```csharp
// EF
.Where(x => x.IsActive && x.OrgId == _orgId)

// proc
new() { ParameterName = "OrgId", Value = _orgId, ParameterType = SqlDbType.BigInt,
        ParameterDirection = ParameterDirection.Input }
```

Note the claim is `aoid` (`KeyConstant.AppOrgId`), not `org` — `org` exists in `HttpContext.Items`
too and is *not* what repositories filter on. Copy the line above rather than picking a key.

Omitting the filter is a cross-tenant data leak: [`EVA-SEC-001`](rules.md#eva-sec-001),
[`EVA-SEC-002`](rules.md#eva-sec-002). Both are `Error` and both block approval.

---

## 3. Stored procedures

The interface (`EVA.<Domain>.Repositories/Common/IExecuterSqlProc.cs`):

```csharp
Task<List<T>> ExecuteProcedureAsync<T>(string procName, IEnumerable<Parameters> sqlParam) where T : class;
Task<int>     ExceuteProcedureNonQueryAsync(string procName, IEnumerable<Parameters> parameters = null, DbTransaction dbTransaction = null);
Task<List<List<dynamic>>> ExecuteMultipleResults(string procName, List<SqlParameter> parameters, params Type[] types);
Task<List<T>> ExecuteAsync<T>(string procName) where T : class;
```

`ExceuteProcedureNonQueryAsync` is misspelled in the interface in every repo. Call it as written; do
not rename it.

A complete call:

```csharp
var sqlParams = new List<Parameters>()
{
    new() { ParameterName = "OrgId",       Value = _orgId,     ParameterType = SqlDbType.BigInt,  ParameterDirection = ParameterDirection.Input },
    new() { ParameterName = "PriceListId", Value = priceListId, ParameterType = SqlDbType.BigInt, ParameterDirection = ParameterDirection.Input },
    new() { ParameterName = "TotalCount",  Value = 0,          ParameterType = SqlDbType.Int,     ParameterDirection = ParameterDirection.Output }
};

var rows = await _sqlExecuterStoreProc
    .ExecuteProcedureAsync<PriceListResultModel>(ProcedureConstants.sp_GetActivePriceList, sqlParams);

int total = (int)((sqlParams.FirstOrDefault(x => x.ParameterName == "TotalCount")?.Value) ?? 0);
```

Four things this gets right:

1. Proc name from `ProcedureConstants`, never an inline `"sp_..."` literal —
   [`EVA-SP-001`](rules.md#eva-sp-001).
2. `OrgId` present — [`EVA-SEC-002`](rules.md#eva-sec-002).
3. Explicit `ParameterType` on every parameter. Without it the reflection mapper silently mis-binds
   and the proc sees `NULL` — [`EVA-SP-002`](rules.md#eva-sp-002). Match the **column** type, not the
   C# type: a SQL `bigint` is `SqlDbType.BigInt` even where `int` would compile.
4. Output parameters read with `?.Value ?? 0` — [`EVA-SP-003`](rules.md#eva-sp-003).

The `sp_PascalCase` constant name is intentional and Sonar `S100`/`S101` are off for it. Do not
rename it — see [anti-rules.md](anti-rules.md).

---

## 4. EF Core

```csharp
// read
var rows = await _unitOfWork.DataContext.Set<PriceList>()
    .AsNoTracking()
    .Where(x => x.IsActive && x.OrgId == _orgId)
    .ToListAsync();

// write
var strategy = _unitOfWork.DataContext.Database.CreateExecutionStrategy();
await strategy.ExecuteAsync(async () =>
{
    using var transaction = await _unitOfWork.DataContext.Database.BeginTransactionAsync();
    _unitOfWork.DataContext.Set<PriceList>().Add(entity);
    await _unitOfWork.Commit();
    await transaction.CommitAsync();
});

// bulk delete
await _unitOfWork.DataContext.Set<PriceList>()
    .Where(x => ids.Contains(x.PriceListId) && x.OrgId == _orgId)
    .ExecuteDeleteAsync();
```

- `AsNoTracking()` on every read.
- **Never sync `SaveChanges()`** — use `await _unitOfWork.Commit()`. Multi-statement writes go inside
  an execution strategy plus an explicit transaction — [`EVA-ERR-007`](rules.md#eva-err-007).
- `IUnitOfWork` exposes `DataContext`, `Commit()` and `Rollback()`. It is `Scoped`, so one instance
  spans the request.
- Bulk operations use `ExecuteDeleteAsync()` / `ExecuteUpdateAsync()` rather than loading and looping.

### Entities and mapping

- A new `DbSet<T>` needs a matching `modelBuilder.Entity<T>(entity => { ... })` Fluent block in
  `OnModelCreating`. EvA maps entirely by Fluent config — **no** `[Table]` / `[Column]` attributes and
  **no** `IEntityTypeConfiguration<T>` classes — [`EVA-SP-005`](rules.md#eva-sp-005).
- Entities are `public partial class`, start with `#nullable disable`, initialise collection
  navigations to `new HashSet<T>()` in a parameterless constructor, and mark navigations
  `public virtual` — [`EVA-SP-006`](rules.md#eva-sp-006).
- Use `Microsoft.Data.SqlClient`, not the legacy `System.Data.SqlClient` —
  [`EVA-SP-007`](rules.md#eva-sp-007).

### Paging

The repository returns the rows and the total count as raw values (a tuple, or an `out`-style pair);
the **Business layer** wraps them in `BaseResponse<PaginatedResult<T>>`
([`EVA-RSP-007`](rules.md#eva-rsp-007)).

Paged reads accept `SearchParams` and the Business layer returns `BaseResponse<PaginatedResult<T>>` rather than
hand-rolled `Skip`/`Take`. `PageSize` is capped at `MaxPageSize = 100` —
[`EVA-RSP-005`](rules.md#eva-rsp-005).

---

## 5. Dapper

Only where a proc does not fit. Always parameterised:

```csharp
var rows = await connection.QueryAsync<PriceListModel>(
    "SELECT * FROM PriceList WHERE OrgId = @OrgId AND Code = @Code",
    new { OrgId = _orgId, Code = code });
```

Never build the SQL by interpolation or concatenation — [`EVA-SEC-003`](rules.md#eva-sec-003),
[`EVA-SEC-004`](rules.md#eva-sec-004), [`EVA-SEC-005`](rules.md#eva-sec-005). All three are `Error`.

---

## 6. Schema lives in a different repo

**The API repo never owns the schema.** This is the trap that is documented nowhere else.

| Repo | What it is |
|---|---|
| `eva-tenant-sql` | `EVA.Tenant/EVA.Tenant.sqlproj` — an SDK-style `Microsoft.Build.Sql` project. `dotnet build -c Release` produces `EVA.Tenant.dacpac`. Tables and procs live under `dbo/`, seed scripts under `DML/`. |
| `eva-database-sql` | SSMS script-outs per database (`EVA-Tenant-DB`, `EVA-Catalog-DB`, `EVA-Configuration-DB`, `EVA-EIMS-DB`), each with `Tables/`, `StoredProcedures/`, `Migrations/`. The `Migrations/` folders are empty by design. |
| `eva-sql-manager` | The WPF editor DBAs use. Out of scope for this skill. |

### Adding a stored procedure — the full loop

1. Write the proc in `eva-tenant-sql` (or the relevant database folder in `eva-database-sql`).
2. Add the constant in the API repo's `ProcedureConstants`.
3. Call it through `IExecuterSqlProc`.

**There is no automated link between steps 1 and 2.** Nothing will tell you the proc does not exist
until the call fails at runtime against a database that has not been updated. Both changes ship, and
the SQL change has to be deployed first.

### Never add an EF migration

[`EVA-SEC-010`](rules.md#eva-sec-010) is an `Error`. DBAs own the schema; a migration in an API repo
will diverge from what is actually deployed and can drop objects it does not know about. If a model
change requires a schema change, it goes through the SQL repo — always.

Scaffolding an entity from an existing table is fine. Generating a migration from an entity is not.
