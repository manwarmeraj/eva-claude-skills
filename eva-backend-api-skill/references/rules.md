# EvA rule reference

<!-- GENERATED FILE - DO NOT EDIT BY HAND. -->
<!-- Regenerate with sync-rules.ps1. Code examples live in snippets\<RULE-ID>.md. -->

Generated from `eva-standards.json` v1.1.

These are the **69 enforced rules** the EvA PR review bot runs on every pull request. It analyses **added and modified lines only** — you are never blamed for code you did not touch.

The 5 rules that are deliberately **not** enforced are in [anti-rules.md](anti-rules.md). Read that file before "fixing" anything that looks non-idiomatic.

**Severity meaning**

| Severity | Effect |
|---|---|
| `Error` | Blocks approval. 33 rules. |
| `Warning` | Expected to be fixed or justified in the PR. 25 rules. |
| `Info` | Style nudge. 11 rules. |

## Index

| Rule | Severity | What it wants |
|---|---|---|
| [`EVA-SEC-001`](#eva-sec-001) | Error | Missing tenant filter (cross-tenant data leak) |
| [`EVA-SEC-002`](#eva-sec-002) | Error | Stored-proc call without OrgId parameter |
| [`EVA-SEC-003`](#eva-sec-003) | Error | SQL injection — interpolated SQL |
| [`EVA-SEC-004`](#eva-sec-004) | Error | SQL injection — concatenated SQL |
| [`EVA-SEC-005`](#eva-sec-005) | Error | Dapper call without a parameter object |
| [`EVA-SEC-006`](#eva-sec-006) | Error | Committed secret-shaped literal |
| [`EVA-SEC-007`](#eva-sec-007) | Error | Committed environment appsettings changed |
| [`EVA-SEC-008`](#eva-sec-008) | Error | Auth-surface change |
| [`EVA-SEC-009`](#eva-sec-009) | Error | Debug flag enabled |
| [`EVA-SEC-010`](#eva-sec-010) | Error | EF migration added (forbidden) |
| [`EVA-ASY-001`](#eva-asy-001) | Error | Blocking .Result on a Task |
| [`EVA-ASY-002`](#eva-asy-002) | Error | Blocking Wait/GetResult/Task.Run wrapper |
| [`EVA-ASY-003`](#eva-asy-003) | Error | Task.FromResult wrapping sync EF |
| [`EVA-ASY-004`](#eva-asy-004) | Error | async void |
| [`EVA-ASY-005`](#eva-asy-005) | Error | Blocking I/O in a constructor |
| [`EVA-ASY-006`](#eva-asy-006) | Error | new HttpClient() |
| [`EVA-CTL-001`](#eva-ctl-001) | Error | Action must return Task<IActionResult> |
| [`EVA-CTL-002`](#eva-ctl-002) | Error | Controller must derive from ControllerBase with [ApiController]+[Route] |
| [`EVA-CTL-004`](#eva-ctl-004) | Error | Missing ModelState guard on write action |
| [`EVA-CTL-007`](#eva-ctl-007) | Error | Business logic in a controller |
| [`EVA-CTL-003`](#eva-ctl-003) | Warning | Route must carry the module prefix |
| [`EVA-CTL-005`](#eva-ctl-005) | Warning | Weak ModelState message |
| [`EVA-CTL-006`](#eva-ctl-006) | Warning | Wrong failure status by operation kind |
| [`EVA-CTL-008`](#eva-ctl-008) | Warning | Non-body/header binding |
| [`EVA-CTL-009`](#eva-ctl-009) | Info | [FromHeader] parameter not camelCase |
| [`EVA-CTL-010`](#eva-ctl-010) | Info | Non-standard status code |
| [`EVA-RSP-001`](#eva-rsp-001) | Error | Public Business method must return BaseResponse<T> |
| [`EVA-RSP-002`](#eva-rsp-002) | Error | Build responses via fluent extensions |
| [`EVA-RSP-003`](#eva-rsp-003) | Error | Magic status int on response.Code |
| [`EVA-RSP-004`](#eva-rsp-004) | Error | Literal user-facing message |
| [`EVA-RSP-007`](#eva-rsp-007) | Error | Repository must not return BaseResponse<T> |
| [`EVA-RSP-008`](#eva-rsp-008) | Error | Read operation must not return a failure |
| [`EVA-RSP-005`](#eva-rsp-005) | Warning | Paged endpoint without SearchParams |
| [`EVA-RSP-006`](#eva-rsp-006) | Warning | New endpoint missing from _endpointResponseMap |
| [`EVA-ERR-001`](#eva-err-001) | Error | Silent catch |
| [`EVA-ERR-002`](#eva-err-002) | Error | Console/Debug/Trace write |
| [`EVA-ERR-003`](#eva-err-003) | Error | Wrong ILogger abstraction |
| [`EVA-ERR-004`](#eva-err-004) | Warning | Hard-coded class name in log call |
| [`EVA-ERR-005`](#eva-err-005) | Warning | Hard-coded class/method literals in log call |
| [`EVA-ERR-006`](#eva-err-006) | Warning | throw new with magic-string message |
| [`EVA-ERR-007`](#eva-err-007) | Warning | Synchronous SaveChanges() |
| [`EVA-SP-001`](#eva-sp-001) | Error | Inline stored-proc name literal |
| [`EVA-SP-002`](#eva-sp-002) | Error | Parameters entry missing ParameterType |
| [`EVA-SP-003`](#eva-sp-003) | Warning | Output parameter read without null-guard |
| [`EVA-SP-005`](#eva-sp-005) | Warning | New DbSet without Fluent config |
| [`EVA-SP-006`](#eva-sp-006) | Warning | Entity not declared partial |
| [`EVA-SP-007`](#eva-sp-007) | Warning | System.Data.SqlClient reference |
| [`EVA-DI-001`](#eva-di-001) | Error | New contract not registered (AddScoped pair) |
| [`EVA-DI-002`](#eva-di-002) | Warning | Non-Scoped lifetime in CustomDependencies |
| [`EVA-DI-003`](#eva-di-003) | Warning | Service locator in a class |
| [`EVA-DI-004`](#eva-di-004) | Warning | Legacy UnitOfWork plumbing in controller |
| [`EVA-DI-005`](#eva-di-005) | Warning | NotImplementedException in shipped code |
| [`EVA-DI-006`](#eva-di-006) | Info | AutoMapper CreateMap outside the profile |
| [`EVA-NAM-001`](#eva-nam-001) | Warning | Private field not _camelCase |
| [`EVA-NAM-002`](#eva-nam-002) | Warning | Private property wearing a field name |
| [`EVA-NAM-005`](#eva-nam-005) | Warning | Wrong DTO suffix |
| [`EVA-NAM-009`](#eva-nam-009) | Warning | [JsonPropertyName] instead of [JsonProperty] |
| [`EVA-NAM-012`](#eva-nam-012) | Warning | Large commented-out block / excluded file edited |
| [`EVA-NAM-006`](#eva-nam-006) | Info | Type not PascalCase |
| [`EVA-NAM-007`](#eva-nam-007) | Info | New class without #region scaffolding |
| [`EVA-NAM-010`](#eva-nam-010) | Info | ImplicitUsings instead of using.cs |
| [`EVA-NAM-011`](#eva-nam-011) | Info | Non target-typed response construction |
| [`EVA-NAM-013`](#eva-nam-013) | Info | Empty or stale XML doc |
| [`EVA-PRJ-001`](#eva-prj-001) | Error | New csproj missing EvA contract |
| [`EVA-PRJ-002`](#eva-prj-002) | Warning | Package version change |
| [`EVA-PRJ-003`](#eva-prj-003) | Warning | CI / config file changed |
| [`EVA-PRJ-004`](#eva-prj-004) | Info | Branch naming policy |
| [`EVA-PRJ-005`](#eva-prj-005) | Info | Low-quality commit messages |
| [`EVA-PRJ-006`](#eva-prj-006) | Info | Large diff — tests advisory |

## Tenancy

> EvA is database-per-tenant AND row-filtered by OrgId. Both are required; neither substitutes for the other. These are the most damaging rules to break.

### EVA-SEC-001 — Missing tenant filter (cross-tenant data leak)

**Error.** EF query chain in a method that never references OrgId — potential cross-tenant data leak. Filter by OrgId (x.OrgId == _orgId).

*Why:* EvA is database-per-tenant with an OrgId column filter on every query; every repository sets _orgId from HttpContext.Items[AppOrgId] and filters on it.

```csharp
// WRONG - runs against the tenant DB, but returns every org's rows in it
var rows = await _uow.DataContext.Set<DesignOverrideReason>()
    .AsNoTracking()
    .Where(x => x.IsActive)
    .ToListAsync();

// RIGHT - _orgId comes from HttpContext.Items[KeyConstant.AppOrgId]
var rows = await _uow.DataContext.Set<DesignOverrideReason>()
    .AsNoTracking()
    .Where(x => x.IsActive && x.OrgId == _orgId)
    .ToListAsync();
```

Connecting to the right tenant database is **not** a substitute for the `OrgId`
filter. One database holds many orgs. Both are required.

<sub>Applies to: `**/*.Repositories/**/*.cs`, `**/*.Business/**/*.cs`, `**/*Repository.cs`, `**/*Business.cs`</sub>

### EVA-SEC-002 — Stored-proc call without OrgId parameter

**Error.** Stored-procedure execution whose method never adds a Parameter named "OrgId" — the proc will run without tenant scoping.

*Why:* Every IExecuterSqlProc call must pass OrgId so the proc filters to the caller's tenant.

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

<sub>Applies to: `**/*.Repositories/**/*.cs`, `**/*.Business/**/*.cs`, `**/*Repository.cs`, `**/*Business.cs`</sub>

## Security

> Never parameterise SQL by string building, never commit a secret, never add an EF migration.

### EVA-SEC-003 — SQL injection — interpolated SQL

**Error.** Interpolated SQL string — SQL injection risk. Use parameters (anonymous object / DynamicParameters).

*Why:* String interpolation of user/tenant values into SQL allows injection and defeats query plan reuse.

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

<sub>Applies to: `**/*.cs`</sub>

### EVA-SEC-004 — SQL injection — concatenated SQL

**Error.** Concatenated SQL string — SQL injection risk. Parameterise the query.

*Why:* Concatenating values into SQL allows injection; the IN(...) pattern is especially dangerous.

<sub>Applies to: `**/*.cs`</sub>

### EVA-SEC-005 — Dapper call without a parameter object

**Error.** Dapper call built from an interpolated/concatenated SQL string. Pass parameters via an anonymous object or DynamicParameters.

*Why:* Unparameterised Dapper calls are injectable and bypass plan caching.

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

<sub>Applies to: `**/*.cs`</sub>

### EVA-SEC-006 — Committed secret-shaped literal

**Error.** Secret-shaped literal committed. Note: EvA's TranscodeBase64 (double-Base64 + a hard-coded salt) is obfuscation, not encryption — a Base64 blob in appsettings*.json is still a committed credential.

*Why:* Secrets belong in a secret store / environment, never in source or committed config.

<sub>Applies to: `**/*.cs`, `**/*.json`, `**/*.yaml`, `**/*.yml`, `**/*.config`, `**/*.ps1`</sub>

### EVA-SEC-007 — Committed environment appsettings changed

**Error.** Environment appsettings file changed — requires security sign-off before merge.

*Why:* Environment configs carry connection strings and toggles; changes must be reviewed by security.

<sub>Applies to: `**/appsettings-PROD.json`, `**/appsettings-UAT.json`, `**/appsettings-QA.json`</sub>

### EVA-SEC-008 — Auth-surface change

**Error.** Security-review-required change: an authentication/authorization surface file was modified.

*Why:* These files gate tenancy, tokens, sanitisation and connection building; changes need explicit security review (watch LocalServerIPAddress / IsLoopback / checkTokenValidity / RBACEnabled).

<sub>Applies to: `**/AuthorizationTokenFilter.cs`, `**/StaticJwksProvider.cs`, `**/SanitizationMiddleware.cs`, `**/BuildConnectionString.cs`, `**/TranscodeBase64.cs`</sub>

### EVA-SEC-009 — Debug flag enabled

**Error.** Debug/stacktrace flag turned on. Note: ErrorHandlingMiddleware compares AddStacktraceInResponse to lowercase "true" while dev config holds "TRUE", so the flag silently never fires — a real bug worth flagging.

*Why:* Debug/stacktrace exposure leaks internals in responses; the casing mismatch also hides the intended behaviour.

<sub>Applies to: `**/*.cs`, `**/*.json`, `**/*.config`</sub>

### EVA-SEC-010 — EF migration added (forbidden)

**Error.** EF migration/snapshot added. EvA schemas are owned by DBAs and stored procedures — migrations are forbidden.

*Why:* The platform has no EF migrations; schema is managed outside the app.

```
# WRONG - never run these in an EvA API repo
dotnet ef migrations add AddDesignOverrideReason
dotnet ef database update
```

Schema is owned by the DBA team and lives in `eva-tenant-sql` / `eva-database-sql`.
The API's `DbContext` is scaffolded DB-first and hand-maintained to match. Every
`Migrations/` folder in the estate is empty on purpose.

Adding a column means: change the SQL repo, get it deployed, **then** add the
property to the entity here. See [data-access.md](data-access.md).

<sub>Applies to: `**/Migrations/**/*.cs`, `**/*ModelSnapshot.cs`</sub>

## Async

> Every one of these is an Error. Blocking a thread pool thread under IIS is how EvA APIs deadlock.

### EVA-ASY-001 — Blocking .Result on a Task

**Error.** Blocking .Result on a Task-returning call — await it instead. (Deadlock risk under sync context.)

*Why:* Synchronously blocking on a Task risks deadlocks and thread-pool starvation.

```csharp
// WRONG - deadlocks under IIS, and hides the real exception inside AggregateException
var result = _repository.GetAll().Result;

// RIGHT
var result = await _repository.GetAll();
```

If awaiting forces you to make the caller async too, make it async. Do not stop
the propagation with `.Result`.

<sub>Applies to: `**/*.cs`</sub>

### EVA-ASY-002 — Blocking Wait/GetResult/Task.Run wrapper

**Error.** Blocking wait / GetAwaiter().GetResult() / Task.Run wrapper over sync code — use async/await end to end.

*Why:* Sync-over-async blocks threads and can deadlock.

```csharp
// WRONG - all three block a thread pool thread
_repository.Update(entity).Wait();
var x = _repository.Get(id).GetAwaiter().GetResult();
var rows = await Task.Run(() => connection.Query<FgModel>(sql).ToList());

// RIGHT
await _repository.Update(entity);
var x = await _repository.Get(id);
var rows = (await connection.QueryAsync<FgModel>(sql, new { OrgId = _orgId })).ToList();
```

`Task.Run` around a database call does not make it async — it just moves the
blocking to a different thread. Use the real `*Async` API.

<sub>Applies to: `**/*.cs`</sub>

### EVA-ASY-003 — Task.FromResult wrapping sync EF

**Error.** Task.FromResult wrapping a synchronous call — use the genuinely async EF/Dapper API (e.g. SaveChangesAsync).

*Why:* Faking async with FromResult still blocks; use real async database calls.

<sub>Applies to: `**/*.cs`</sub>

### EVA-ASY-004 — async void

**Error.** async void — exceptions escape and cannot be awaited. Return Task (except real event handlers).

*Why:* async void swallows failures and breaks composition.

<sub>Applies to: `**/*.cs`</sub>

### EVA-ASY-005 — Blocking I/O in a constructor

**Error.** Blocking I/O (await/.Result) inside a constructor. Move I/O to an async initialise method.

*Why:* A constructor cannot be async; blocking there causes full round-trips on the calling thread (e.g. an HTTP call in a ctor).

<sub>Applies to: `**/*.cs`</sub>

### EVA-ASY-006 — new HttpClient()

**Error.** Do not new-up HttpClient — use the injected IHttpClientFactory to avoid socket exhaustion.

*Why:* Directly constructing HttpClient leaks sockets and misses DNS refresh.

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

    public async Task<string> Push(FgPushModel model)
    {
        var client = _httpClientFactory.CreateClient();
        // ...
    }
}
```

<sub>Applies to: `**/*.cs`</sub>

## Controller

> Controllers are plumbing: bind, guard ModelState, call one Business method, map to Ok/BadRequest. Nothing else.

### EVA-CTL-001 — Action must return Task<IActionResult>

**Error.** Controller action must return Task<IActionResult>. ActionResult<T>, Task<T> and non-async actions are not used anywhere in EvA (663 uses of Task<IActionResult>, zero ActionResult<T>).

*Why:* Uniform return type keeps the Angular client contract and BaseResponse envelope consistent.

```csharp
// WRONG - ActionResult<T> is not used anywhere in EvA (663 actions, zero uses)
public async Task<ActionResult<DesignOverrideReasonModel>> Get([FromHeader] Guid id)

// WRONG - not async
public IActionResult Get([FromHeader] Guid id)

// RIGHT
public async Task<IActionResult> Get([FromHeader] Guid designOverrideReasonsId)
```

<sub>Applies to: `**/Controllers/**/*.cs`</sub>

### EVA-CTL-002 — Controller must derive from ControllerBase with [ApiController]+[Route]

**Error.** Controller must derive from ControllerBase (never MVC Controller) and carry [ApiController] and [Route(...)].

*Why:* These APIs are attribute-routed JSON controllers; the MVC view-based Controller base is wrong here.

<sub>Applies to: `**/Controllers/**/*.cs`</sub>

### EVA-CTL-004 — Missing ModelState guard on write action

**Error.** [HttpPost]/[HttpPut] action taking a model must guard with if (!ModelState.IsValid).

*Why:* DataAnnotations validation is the only validation layer (no FluentValidation); skipping the guard ships invalid payloads.

```csharp
// WRONG - DataAnnotations on the model are never checked
[HttpPost]
public async Task<IActionResult> Add([FromBody] DesignOverrideReasonInputModel inputModel)
{
    var response = await _designOverrideReasonBusiness.Add(inputModel);
    ...
}

// RIGHT
[HttpPost]
public async Task<IActionResult> Add([FromBody] DesignOverrideReasonInputModel inputModel)
{
    if (!ModelState.IsValid)
    {
        var message = string.Join(", ",
            ModelState.Values.SelectMany(v => v.Errors).Select(e => e.ErrorMessage));
        return BadRequest(message);
    }

    var response = await _designOverrideReasonBusiness.Add(inputModel);
    if (!response.Success)
        return BadRequest(response);

    return Ok(response);
}
```

DataAnnotations is the **only** validation layer in EvA — there is no
FluentValidation anywhere. Skip the guard and invalid payloads reach the database.

<sub>Applies to: `**/Controllers/**/*.cs`</sub>

### EVA-CTL-007 — Business logic in a controller

**Error.** No business logic in controllers: no try/catch, no ILogger injection, no DbContext/IRepository<>/EvaCrmContext. Exceptions belong to ErrorHandlingMiddleware.

*Why:* Controllers are thin; error handling is centralised in middleware.

```csharp
// WRONG - four separate violations in one action
[HttpGet]
public async Task<IActionResult> GetAll()
{
    try                                                   // no try/catch in controllers
    {
        var rows = await _dbContext.FinishedGoods         // no DbContext in controllers
            .Where(x => x.OrgId == orgId).ToListAsync();  // no business logic in controllers
        return Ok(rows);
    }
    catch (Exception ex)
    {
        _logger.Error(...);                               // no ILogger in controllers
        return BadRequest();
    }
}

// RIGHT - bind, guard, delegate, map
[HttpGet]
public async Task<IActionResult> GetAll()
{
    var response = await _finishedGoodsBusiness.GetAll();
    if (!response.Success)
        return BadRequest(response);
    return Ok(response);
}
```

`ErrorHandlingMiddleware` already catches and logs everything a controller could
throw. A try/catch here just hides the failure from it.

<sub>Applies to: `**/Controllers/**/*.cs`</sub>

### EVA-CTL-003 — Route must carry the module prefix

**Warning.** Controller route should start with the module prefix (e.g. api/crm/[controller]/[action]). Configure the prefix per repo via the override file.

*Why:* The Angular client and gateway route on the module prefix.

```csharp
// WRONG in eva-crm-api - the gateway strips the first segment and routes on the module
[Route("api/[controller]/[action]")]

// RIGHT - module prefix matches the repo
[Route("api/crm/[controller]/[action]")]
```

Look your repo's prefix up in the registry table in
[architecture.md](architecture.md) — do not guess it from the folder name.
`eva-api` is the one repo whose prefix is plain `api`.

<sub>Applies to: `**/Controllers/**/*.cs`</sub>

### EVA-CTL-005 — Weak ModelState message

**Warning.** string.Join("", ModelState.Values) loses the error text — use .SelectMany(v => v.Errors).Select(e => e.ErrorMessage).

*Why:* Joining ModelState.Values directly serialises objects, not messages, so the client sees noise.

```csharp
// WRONG - joins ModelStateEntry objects, so the client gets type names, not errors
var message = string.Join("", ModelState.Values);

// ALSO WRONG - the "" separator runs all the messages together
var message = string.Join("", ModelState.Values.SelectMany(v => v.Errors).Select(e => e.ErrorMessage));

// RIGHT
var message = string.Join(", ",
    ModelState.Values.SelectMany(v => v.Errors).Select(e => e.ErrorMessage));
```

You will see the `string.Join("")` form in older controllers. It is a real bug,
not a convention — do not copy it into new actions.

<sub>Applies to: `**/Controllers/**/*.cs`</sub>

### EVA-CTL-006 — Wrong failure status by operation kind

**Warning.** Write ops (Add/Update/Delete) must return BadRequest(response) on failure — not Ok(...). Read ops blank the payload and still return Ok(response).

*Why:* The client distinguishes success/failure by HTTP status for writes.

```csharp
// WRONG - a failed write returning 200 makes the client treat it as saved
[HttpPost]
public async Task<IActionResult> Add([FromBody] FgModel model)
{
    var response = await _fgBusiness.Add(model);
    return Ok(response);
}

// RIGHT - writes signal failure through the status code
[HttpPost]
public async Task<IActionResult> Add([FromBody] FgModel model)
{
    var response = await _fgBusiness.Add(model);
    if (!response.Success)
        return BadRequest(response);
    return Ok(response);
}

// RIGHT - reads still return 200 with an empty payload
[HttpGet]
public async Task<IActionResult> GetAll()
{
    var response = await _fgBusiness.GetAll();
    return Ok(response);
}
```

Only 200 and 400 are used platform-wide (`EVA-CTL-010`). Do not introduce 404,
422, or 500 from a controller.

<sub>Applies to: `**/Controllers/**/*.cs`</sub>

### EVA-CTL-008 — Non-body/header binding

**Warning.** Scalars bind via [FromHeader], payloads via [FromBody]; list/search endpoints POST a SearchParams body. New [FromQuery]/[FromRoute] scalars break the Angular client contract.

*Why:* The client only sends headers and JSON bodies; query/route scalars are not part of the contract.

```csharp
// WRONG - the Angular client sends neither query strings nor route values
public async Task<IActionResult> Get([FromQuery] Guid designOverrideReasonsId)
public async Task<IActionResult> Get([FromRoute] Guid designOverrideReasonsId)

// RIGHT - scalars in headers, payloads in the body
public async Task<IActionResult> Get([FromHeader] Guid designOverrideReasonsId)
public async Task<IActionResult> Add([FromBody] DesignOverrideReasonInputModel inputModel)

// RIGHT - list/search endpoints POST a SearchParams body
[HttpPost]
public async Task<IActionResult> GetList([FromBody] SearchParams searchParams)
```

<sub>Applies to: `**/Controllers/**/*.cs`</sub>

### EVA-CTL-009 — [FromHeader] parameter not camelCase

**Info.** New [FromHeader] parameter should be camelCase (legacy PascalCase names like OpportunityMastersId are grandfathered).

*Why:* Header names are camelCase by convention for new code.

<sub>Applies to: `**/Controllers/**/*.cs`</sub>

### EVA-CTL-010 — Non-standard status code

**Info.** Only 200/400 are used across the platform. New 201/204/404/StatusCode(...) usage is a deviation needing justification.

*Why:* Uniform status usage keeps the client simple.

<sub>Applies to: `**/Controllers/**/*.cs`</sub>

## Response

> Every public Business/Repository method speaks BaseResponse<T>. Codes come from ResponseMessages.resx, never literals.

### EVA-RSP-001 — Public Business method must return BaseResponse<T>

**Error.** A public Business method must return BaseResponse<T> (or Task<BaseResponse<T>>), never a raw entity/DTO/bool/List<>. Repositories are the opposite — see EVA-RSP-007.

*Why:* The envelope carries Code/Success/Message consistently to the client. The Business layer is the single place it is built.

```csharp
// WRONG - the controller cannot tell success from failure, and has no code to return
public Task<List<PriceListModel>> GetAll();
public Task<bool> Add(PriceListAddModel model);

// RIGHT - Business layer speaks BaseResponse<T>
public Task<BaseResponse<List<PriceListModel>>> GetAll();
public Task<BaseResponse<bool>> Add(PriceListAddModel model);
```

Applies to the contract (`I*Business`) as well as the implementation. Private helpers may return
whatever is convenient.

**The Business layer is the only place the envelope is built.** The Repository underneath returns the
raw shape — see [`EVA-RSP-007`](#eva-rsp-007) — so a Business method is where a raw `List<>` or
`bool` becomes a `BaseResponse<T>`:

```csharp
public async Task<BaseResponse<List<PriceListModel>>> GetAll()
{
    BaseResponse<List<PriceListModel>> response = new();

    var rows = await _priceListRepository.GetAll();     // raw List<PriceListModel>

    return response.Success(rows, ResponseType.Common_DataFetchSuccess);
}
```

<sub>Applies to: `**/*.Business/**/*.cs`, `**/*Business.cs`</sub>

### EVA-RSP-002 — Build responses via fluent extensions

**Error.** Build responses via .Success(...)/.Failure(...) from BaseResponseExtension — not direct property assignment or new BaseResponse<T>{...}.

*Why:* The fluent extensions set Code/Message consistently; hand-construction drifts.

```csharp
// WRONG - Code and Success drift apart the moment someone edits one of them
return new BaseResponse<bool> { Success = true, Data = result, Code = 1000 };

// WRONG - same problem, assigned instead of constructed
response.Success = true;
response.Data = result;

// RIGHT - the fluent extensions set Code/Success/Data consistently
public async Task<BaseResponse<bool>> Add(DesignOverrideReasonInputModel inputModel)
{
    BaseResponse<bool> response = new();

    if (_orgId <= 0)
        return response.Failure(ResponseType.Err_UnauthorizedAccess);

    var result = await _designOverrideReasonRepository.Add(inputModel);
    if (!result)
        return response.Failure(ResponseType.Err_DataSaveFailed);

    return response.Success(result, ResponseType.Common_DataSaveMsg);
}
```

<sub>Applies to: `**/*.Business/**/*.cs`, `**/*Business.cs`</sub>

### EVA-RSP-003 — Magic status int on response.Code

**Error.** No magic status ints — assign (int)ResponseCode.X, not a literal.

*Why:* Literal codes bypass the ResponseCode enum and its resx descriptions.

<sub>Applies to: `**/*.Business/**/*.cs`, `**/*Business.cs`, `**/*Controller.cs`</sub>

### EVA-RSP-004 — Literal user-facing message

**Error.** No literal user-facing messages — text belongs in ResponseMessages.resx, resolved via ResponseCode.GetDescription().

*Why:* Hard-coded strings cannot be localised and drift from the resx.

```csharp
// WRONG - cannot be localised, and drifts from the resx
return response.Failure("Finished good could not be saved");

// RIGHT - add a ResponseType member + a ResponseMessages.resx entry, then reference it
return response.Failure(ResponseType.Err_DataSaveFailed);
```

The enum member name **is** the resx key; `ResponseType.GetDescription()` resolves
it at serialisation time. Adding a message means adding both, in the same PR.

<sub>Applies to: `**/*.Business/**/*.cs`, `**/*Business.cs`</sub>

### EVA-RSP-007 — Repository must not return BaseResponse<T>

**Error.** A Repository method must return the raw shape — an entity, DTO, bool, int or List<> — never BaseResponse<T>. The envelope is built in the Business layer only (EVA-RSP-001).

*Why:* One layer owns the response envelope. A Repository that returns BaseResponse<T> forces the Business layer to unwrap and rewrap it, and pushes response codes into the data layer where they do not belong.

The mirror image of [`EVA-RSP-001`](#eva-rsp-001). The envelope belongs to the Business layer and
nowhere else.

```csharp
// WRONG - the Business layer now has to unwrap and rewrap, and response codes
//         have leaked into the data layer
public interface IPriceListRepository
{
    Task<BaseResponse<List<PriceListModel>>> GetAll();
    Task<BaseResponse<bool>> Add(PriceListAddModel model);
}

// RIGHT - raw shapes: entity, DTO, bool, int, List<>
public interface IPriceListRepository
{
    Task<List<PriceListModel>> GetAll();
    Task<PriceListModel> Get(long priceListId);
    Task<bool> Add(PriceListAddModel model);
    Task<bool> Update(PriceListUpdateModel model);
    Task<bool> Delete(List<long> priceListIds);
}
```

The implementation stays plain — no `BaseResponse` local, no `ResponseType`:

```csharp
public async Task<List<PriceListModel>> GetAll()
{
    return await _unitOfWork.DataContext.Set<PriceList>()
        .AsNoTracking()
        .Where(x => x.OrgId == _orgId)                  // tenancy is still the repository's job
        .Select(x => new PriceListModel { /* ... */ })
        .ToListAsync();
}
```

What stays in the repository: `OrgId` filtering, `AsNoTracking`, transactions, proc calls.
What moves out: `BaseResponse<T>`, `ResponseType`, `.Success(...)` / `.Failure(...)`, resx codes.

A repository signals "nothing found" with an empty list or `null`, and "write failed" with `false` or
an affected-row count of `0`. The Business layer turns that into a response code.

<sub>Applies to: `**/*.Repositories/**/*.cs`, `**/*.Repository/**/*.cs`, `**/*Repository.cs`, `**/*Repositories.cs`</sub>

### EVA-RSP-008 — Read operation must not return a failure

**Error.** Get/GetAll/GetList/GetById must always return .Success(...) — never .Failure(...). No rows is a successful empty result: return an empty list, or the default/null payload, still with Success. Only writes (Add/Update/Delete) may fail.

*Why:* "No records found" is a normal outcome, not an error. Returning a failure for it makes the Angular client treat an empty grid as a broken call, and is why read endpoints still return Ok(response) (EVA-CTL-006).

"No records found" is a **normal outcome of a successful read**, not an error.

```csharp
// WRONG - an empty grid now looks like a broken call to the Angular client
public async Task<BaseResponse<List<PriceListModel>>> GetAll()
{
    BaseResponse<List<PriceListModel>> response = new();

    var rows = await _priceListRepository.GetAll();

    if (rows == null || rows.Count == 0)
        return response.Failure(ResponseType.Err_NoRecordFound);   // no

    return response.Success(rows, ResponseType.Common_DataFetchSuccess);
}

// RIGHT - empty is still success
public async Task<BaseResponse<List<PriceListModel>>> GetAll()
{
    BaseResponse<List<PriceListModel>> response = new();

    var rows = await _priceListRepository.GetAll() ?? new List<PriceListModel>();

    return response.Success(rows, ResponseType.Common_DataFetchSuccess);
}
```

Single-item reads behave the same way — return the default payload, still with success:

```csharp
public async Task<BaseResponse<PriceListModel>> Get(long priceListId)
{
    BaseResponse<PriceListModel> response = new();

    var row = await _priceListRepository.Get(priceListId);         // may be null

    return response.Success(row, ResponseType.Common_DataFetchSuccess);
}
```

**Reads:** `Get`, `GetAll`, `GetList`, `GetById` — always `.Success(...)`.
**Writes:** `Add`, `Update`, `Delete` — may `.Failure(...)`.

This is why the controller returns `Ok(response)` for a read regardless, and `BadRequest(response)`
only for a failed write — [`EVA-CTL-006`](#eva-ctl-006). The two rules are the same contract seen
from two layers.

The `_orgId <= 0` guard is the one exception: no tenant context means the request was never valid, so
a read may still return `.Failure(ResponseType.Err_UnauthorizedAccess)`.

<sub>Applies to: `**/*.Business/**/*.cs`, `**/*Business.cs`</sub>

### EVA-RSP-005 — Paged endpoint without SearchParams

**Warning.** Manual Skip/Take without SearchParams. Paged reads should return BaseResponse<PaginatedResult<T>> from the Business layer and accept SearchParams (PageSize <= MaxPageSize = 100).

*Why:* Uniform pagination keeps the client grid contract stable.

<sub>Applies to: `**/*.Business/**/*.cs`, `**/*Business.cs`</sub>

### EVA-RSP-006 — New endpoint missing from _endpointResponseMap

**Warning.** New controller action added but ErrorHandlingMiddleware._endpointResponseMap was not touched — the endpoint will silently degrade to Err_UnhandledException. Add a map entry if it needs a specific failure code.

*Why:* The middleware maps endpoints to response codes; unmapped endpoints get a generic failure.

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

<sub>Applies to: `**/Controllers/**/*.cs`</sub>

## ErrorHandling

> catch (Exception ex) is fine. Catching it and doing nothing is not.

### EVA-ERR-001 — Silent catch

**Error.** Silent catch — the block neither logs (_logger.), rethrows, nor sets a Failure(...) response. Note: catch (Exception ex) itself is allowed (Sonar S2221 is disabled); only silence is banned.

*Why:* Swallowing exceptions hides failures; log/rethrow/return a Failure response.

```csharp
// WRONG - the failure disappears; the caller sees a success-shaped empty result
try
{
    await _repository.Update(entity);
}
catch (Exception ex)
{
}

// ALSO WRONG - a comment is not handling
catch (Exception ex)
{
    // ignore, not important
}

// RIGHT - log it
catch (Exception ex)
{
    _logger.Error(nameof(FgDesignRepository), nameof(Update), ex.Message, ex.StackTrace);
    return response.Failure(ResponseType.Err_UnhandledException);
}

// RIGHT - or let ErrorHandlingMiddleware deal with it and do not catch at all
```

`catch (Exception ex)` is explicitly allowed in EvA (Sonar S2221 is off). Only
**silence** is banned: log, rethrow, or return a `Failure(...)`.

<sub>Applies to: `**/*.cs`</sub>

### EVA-ERR-002 — Console/Debug/Trace write

**Error.** Debug/Console/Trace.Write in a non-console project — use EVA.Logging (_logger).

*Why:* Console/Debug output is invisible in production; use the structured logger.

<sub>Applies to: `**/*.cs`</sub>

### EVA-ERR-003 — Wrong ILogger abstraction

**Error.** Use EVA.Logging.Interface.ILogger (registered AddScoped<ILogger, Logger>()), not Microsoft.Extensions.Logging.ILogger<T>.

*Why:* EvA logs via its own 4-arg logger (class, method, message, stackTrace) over NLog/Blob/Elastic.

```csharp
// WRONG - resolves nothing; EvA does not register Microsoft's generic logger
private readonly ILogger<FgDesignRepository> _logger;   // Microsoft.Extensions.Logging

// RIGHT - EVA.Logging.Interface.ILogger, registered AddScoped<ILogger, Logger>()
private readonly ILogger _logger;                       // aliased in using.cs

public FgDesignRepository(ILogger logger)
{
    _logger = logger;
}
```

The EvA logger has one fixed four-argument signature and routes to
NLog / Blob / Elastic depending on `LoggerConfig.LogWriteType`:

```csharp
void Error(string className, string methodName, string message, string stackTrace);
```

There is no `LogInformation`, no message template, no structured-logging overload.

<sub>Applies to: `**/*.Business/**/*.cs`, `**/*.Repositories/**/*.cs`, `**/*Business.cs`, `**/*Repository.cs`</sub>

### EVA-ERR-004 — Hard-coded class name in log call

**Warning.** Prefer nameof(TypeName) over a hard-coded class-name string in a log call — string literals go stale.

*Why:* Literal class names drift on rename (e.g. logging "PriceStructure" from OpportunityQuoteRepository).

```csharp
// WRONG - goes stale on rename, and is already wrong here (copied from another class)
_logger.Error("PriceStructure", "Update", ex.Message, ex.StackTrace);

// RIGHT - nameof() follows renames
_logger.Error(nameof(OpportunityQuoteRepository), nameof(Update), ex.Message, ex.StackTrace);
```

<sub>Applies to: `**/*.Business/**/*.cs`, `**/*.Repositories/**/*.cs`, `**/*Business.cs`, `**/*Repository.cs`</sub>

### EVA-ERR-005 — Hard-coded class/method literals in log call

**Warning.** Two string literals (class, method) passed to the logger — verify they match the enclosing type/method; prefer nameof().

*Why:* Copy-pasted literals go stale and mislead debugging (e.g. the 'RmPriceCaategories' typo).

<sub>Applies to: `**/*.Business/**/*.cs`, `**/*.Repositories/**/*.cs`, `**/*Business.cs`, `**/*Repository.cs`</sub>

### EVA-ERR-006 — throw new with magic-string message

**Warning.** throw new with a magic-string message — ErrorHandlingMiddleware dispatches on exception.Message, so a new string must be registered there.

*Why:* The middleware maps message strings to responses; unregistered strings degrade to a generic error.

<sub>Applies to: `**/*.cs`</sub>

### EVA-ERR-007 — Synchronous SaveChanges()

**Warning.** Use an execution strategy + explicit transaction with SaveChangesAsync/CommitAsync/RollbackAsync (the ProductRange* pattern); AsNoTracking() on reads; ExecuteDeleteAsync() for bulk deletes.

*Why:* Synchronous SaveChanges blocks and skips the resilient transaction pattern.

```csharp
// WRONG - blocks the thread, and no retry on a transient SQL failure
_uow.DataContext.SaveChanges();

// RIGHT - execution strategy + explicit transaction
var strategy = _uow.DataContext.Database.CreateExecutionStrategy();
await strategy.ExecuteAsync(async () =>
{
    using var transaction = await _uow.DataContext.Database.BeginTransactionAsync();

    _uow.DataContext.Set<DesignOverrideReason>().Add(entity);
    await _uow.DataContext.SaveChangesAsync();

    await transaction.CommitAsync();
});
```

Related: `AsNoTracking()` on every read, and `ExecuteDeleteAsync()` for bulk
deletes instead of loading entities to remove them.

<sub>Applies to: `**/*.Repositories/**/*.cs`, `**/*Repository.cs`</sub>

## DataAccess

> Proc names from constants, explicit SqlDbType on every parameter, Fluent config for every DbSet.

### EVA-SP-001 — Inline stored-proc name literal

**Error.** Inline "sp_..." literal at a call site. Reference the name from ProcedureConstants/StoredProcedureConstants.

*Why:* Centralised proc names prevent typos and enable rename safety.

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

<sub>Applies to: `**/*.Business/**/*.cs`, `**/*.Repositories/**/*.cs`, `**/*Business.cs`, `**/*Repository.cs`</sub>

### EVA-SP-002 — Parameters entry missing ParameterType

**Error.** Parameters entry is missing ParameterType (explicit SqlDbType) — reflection mapping breaks silently. Set ParameterName, Value, ParameterType and ParameterDirection.

*Why:* Without an explicit SqlDbType the ADO mapping can silently mis-bind.

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

<sub>Applies to: `**/*.Repositories/**/*.cs`, `**/*.Business/**/*.cs`, `**/*Repository.cs`, `**/*Business.cs`</sub>

### EVA-SP-003 — Output parameter read without null-guard

**Warning.** Read output parameters defensively: (int)((parameters.FirstOrDefault(x => x.ParameterName == "TotalCount")?.Value) ?? 0).

*Why:* A missing output parameter throws a NullReferenceException without the ?. / ?? guard.

```csharp
// WRONG - NullReferenceException the day the proc stops returning TotalCount
int total = (int)sqlParams.FirstOrDefault(x => x.ParameterName == "TotalCount").Value;

// RIGHT - null-safe on the parameter and on its value
int total = (int)((sqlParams.FirstOrDefault(x => x.ParameterName == "TotalCount")?.Value) ?? 0);
```

The guard is cheap and the failure it prevents is a 500 with no useful message. Apply it to every output-parameter read, including ones you are certain the proc sets.

<sub>Applies to: `**/*.Repositories/**/*.cs`, `**/*Repository.cs`</sub>

### EVA-SP-005 — New DbSet without Fluent config

**Warning.** New DbSet<T> added — ensure a matching modelBuilder.Entity<T>(entity => {...}) Fluent block exists in OnModelCreating (no [Table]/[Column] attributes, no IEntityTypeConfiguration<T>).

*Why:* EvA maps entities entirely via Fluent config in the context.

<sub>Applies to: `**/*Context.cs`</sub>

### EVA-SP-006 — Entity not declared partial

**Warning.** New entity must be 'public partial class', start with '#nullable disable', init collection navigations to new HashSet<T>() in a parameterless ctor, and mark navigations 'public virtual'.

*Why:* Entities are scaffolded partial classes with nullable disabled per EvA convention.

<sub>Applies to: `**/*.Entities/**/*.cs`</sub>

### EVA-SP-007 — System.Data.SqlClient reference

**Warning.** Prefer Microsoft.Data.SqlClient over the legacy System.Data.SqlClient.

*Why:* Microsoft.Data.SqlClient is the supported, forward-looking provider.

<sub>Applies to: `**/*.cs`</sub>

## DependencyInjection

> All registration is manual and Scoped. Forgetting the AddScoped pair is the single most common break.

### EVA-DI-001 — New contract not registered (AddScoped pair)

**Error.** New IXxxBusiness/IXxxRepository must be registered as an AddScoped pair in Infrastructure/DIConfiguration.cs (CustomDependencies).

*Why:* Unregistered contracts fail at resolve time; all 221 registrations are AddScoped pairs.

Writing the interface and the class is two thirds of the job. The third part is the registration, and forgetting it is the **single most common break** in EvA: it compiles cleanly, then fails on the first request with `Unable to resolve service for type 'IPriceListBusiness'`.

`EVA.<Domain>.API\Infrastructure\DIConfiguration.cs`:

```csharp
public static void CustomDependencies(IServiceCollection services)
{
    // ...existing registrations...

    // RIGHT - always a pair, always Scoped: Business and Repository together
    services.AddScoped<IPriceListBusiness, PriceListBusiness>();
    services.AddScoped<IPriceListRepositories, PriceListRepositories>();
}
```

```csharp
// WRONG - Singleton holds a DbContext across requests, and across tenants
services.AddSingleton<IPriceListBusiness, PriceListBusiness>();

// WRONG - Transient breaks the shared UnitOfWork inside one request
services.AddTransient<IPriceListRepositories, PriceListRepositories>();
```

All 221 registrations in the platform are `AddScoped`. There is no assembly scanning and no convention-based discovery: if it is not in this file, it does not exist.

<sub>Applies to: `**/Contracts/**/*.cs`, `**/I*Business.cs`, `**/I*Repository.cs`</sub>

### EVA-DI-002 — Non-Scoped lifetime in CustomDependencies

**Warning.** AddTransient/AddSingleton in CustomDependencies — 221 registrations are AddScoped; a deviation needs a justifying comment.

*Why:* Scoped lifetime matches the per-request tenant context.

<sub>Applies to: `**/DIConfiguration.cs`</sub>

### EVA-DI-003 — Service locator in a class

**Warning.** Service-locator usage (GetRequiredService/GetService). New code should use explicit constructor injection.

*Why:* Constructor injection makes dependencies explicit and testable.

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

<sub>Applies to: `**/*.Business/**/*.cs`, `**/*.Repositories/**/*.cs`, `**/*Business.cs`, `**/*Repository.cs`</sub>

### EVA-DI-004 — Legacy UnitOfWork plumbing in controller

**Warning.** Legacy '_xxxBusiness.UnitOfWork = uow;' plumbing in a controller ctor. New code injects IUnitOfWork into the Business class (the ProductRange* pattern). Flip severity to off per repo via the override file if it hasn't migrated.

*Why:* Assigning UnitOfWork from the controller couples layers; inject it into the Business class instead.

<sub>Applies to: `**/Controllers/**/*.cs`</sub>

### EVA-DI-005 — NotImplementedException in shipped code

**Warning.** throw new NotImplementedException() in shipped code.

*Why:* Unimplemented members ship latent failures.

<sub>Applies to: `**/*.cs`</sub>

### EVA-DI-006 — AutoMapper CreateMap outside the profile

**Info.** New AutoMapper maps belong in the single AutoMapperProfiles profile (which lives in the Repositories project, not the API).

*Why:* One profile keeps mapping discoverable and avoids duplicate maps.

<sub>Applies to: `**/*.cs`</sub>

## Naming

> Mostly Warning/Info, but they are what makes a diff look like it belongs in EvA.

### EVA-NAM-001 — Private field not _camelCase

**Warning.** Private field should be _camelCase (e.g. _salesOfficeRepository), not _PascalCase.

*Why:* 981 fields follow _camelCase; only 22 violate it.

<sub>Applies to: `**/*.cs`</sub>

### EVA-NAM-002 — Private property wearing a field name

**Warning.** A private property named like a field (private IOptions<AppConfig> _config { get; set; }). Use a real 'private readonly' field.

*Why:* 60 occurrences mislead readers into thinking it's a field; prefer a readonly field.

<sub>Applies to: `**/*.cs`</sub>

### EVA-NAM-005 — Wrong DTO suffix

**Warning.** DTO suffix must be Model/ToCreateModel/ToUpdateModel/AddModel/UpdateModel/ReadModel/GetAllModel/ResultModel — not Dto/ViewModel/Request/Response.

*Why:* Consistent *Model suffix matches the client contract.

```csharp
// WRONG - .NET-default names that no EvA client contract uses
public class PriceListDto { }
public class CreatePriceListRequest { }
public class PriceListResponse { }
public class PriceListViewModel { }

// RIGHT - the EvA suffix set
public class PriceListModel { }        // general shape
public class PriceListAddModel { }     // create payload
public class PriceListUpdateModel { }  // update payload
public class PriceListReadModel { }    // single read
public class PriceListGetAllModel { }  // list read
public class PriceListResultModel { }  // proc / query projection
```

The full allowed set: `Model`, `ToCreateModel`, `ToUpdateModel`, `AddModel`, `UpdateModel`, `ReadModel`, `GetAllModel`, `ResultModel`. They live in `EVA.<Domain>.ViewModel(s)`.

Note the project is named `ViewModel` but no class is ever suffixed `ViewModel`.

<sub>Applies to: `**/*.ViewModels/**/*.cs`</sub>

### EVA-NAM-009 — [JsonPropertyName] instead of [JsonProperty]

**Warning.** Use Newtonsoft [JsonProperty], not System.Text.Json [JsonPropertyName] — the pipeline is AddNewtonsoftJson, so [JsonPropertyName] is silently ineffective.

*Why:* 45 existing [JsonPropertyName] usages do nothing because serialisation is Newtonsoft.

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

<sub>Applies to: `**/*.cs`</sub>

### EVA-NAM-012 — Large commented-out block / excluded file edited

**Warning.** Large commented-out code block added (>= 10 consecutive comment lines), or a file excluded via <Compile Remove> was edited (the compiler/analysers never see it).

*Why:* Dead commented code and excluded files rot silently.

<sub>Applies to: `**/*.cs`, `**/*.csproj`</sub>

### EVA-NAM-006 — Type not PascalCase

**Info.** Type name should be PascalCase (Sonar S101 is downgraded to Info in EvA — report, don't block).

*Why:* Consistent type casing; non-blocking per the EvA profile.

<sub>Applies to: `**/*.cs`</sub>

### EVA-NAM-007 — New class without #region scaffolding

**Info.** Expected #region scaffolding (Imports, Data Members, Constructor, Public Methods, Private Method, Dispose) is absent — 695 such regions exist across the codebase.

*Why:* Region scaffolding is the house layout for these classes.

<sub>Applies to: `**/*Business.cs`, `**/*Repository.cs`, `**/*Controller.cs`</sub>

### EVA-NAM-010 — ImplicitUsings instead of using.cs

**Info.** Global usings go in the hand-written using.cs at the project root, not the SDK ImplicitUsings property.

*Why:* EvA centralises global usings in using.cs.

```xml
<!-- WRONG - EVA.PriceList.Business.csproj -->
<PropertyGroup>
  <TargetFramework>net10.0</TargetFramework>
  <ImplicitUsings>enable</ImplicitUsings>
</PropertyGroup>
```

```csharp
// RIGHT - using.cs at the project root: hand-written, reviewable, greppable
global using System.Data;
global using Microsoft.EntityFrameworkCore;
global using EVA.PriceList.Common.ResponseMessages;
global using EVA.PriceList.ViewModel;
```

Every EvA project keeps its global usings in `using.cs`, so a reviewer can see exactly what is in scope without reasoning about SDK defaults. Add your namespace there rather than turning `ImplicitUsings` on.

<sub>Applies to: `**/*.csproj`</sub>

### EVA-NAM-011 — Non target-typed response construction

**Info.** Prefer target-typed new(): 'BaseResponse<bool> response = new();' and 'var' for other locals.

*Why:* Matches the prevailing style for the response local.

<sub>Applies to: `**/*.Business/**/*.cs`, `**/*.Repositories/**/*.cs`, `**/*Business.cs`, `**/*Repository.cs`</sub>

### EVA-NAM-013 — Empty or stale XML doc

**Info.** Empty or copy-pasted-wrong XML doc (e.g. '/// This is a Employee Controller' on a different controller). Fix or remove it. XML docs are NOT required on all members (only 163 exist).

*Why:* Wrong docs are worse than none; they mislead readers.

<sub>Applies to: `**/*.cs`</sub>

## Project

> csproj contract, package bumps, branch names, commit messages.

### EVA-PRJ-001 — New csproj missing EvA contract

**Error.** New .csproj must set <TargetFramework>net10.0</TargetFramework>, a <CodeAnalysisRuleSet> pointing at the .sonarlint ruleset, and an <AdditionalFiles ... SonarLint.xml> link.

*Why:* Every EvA project pins net10.0 and the shared Sonar ruleset.

<sub>Applies to: `**/*.csproj`</sub>

### EVA-PRJ-002 — Package version change

**Warning.** PackageReference version added/changed — surface it. There is no Directory.Packages.props, so version drift is otherwise invisible.

*Why:* No central version management means every bump must be reviewed.

<sub>Applies to: `**/*.csproj`</sub>

### EVA-PRJ-003 — CI / config file changed

**Warning.** CI/pipeline or logging config changed (workflows/Jenkinsfile/properties.yaml/nlog.config) — surface prominently.

*Why:* Pipeline/logging changes have blast radius beyond the code.

<sub>Applies to: `**/.github/workflows/**`, `**/Jenkinsfile`, `**/properties.yaml`, `**/nlog.config`</sub>

### EVA-PRJ-004 — Branch naming policy

**Info.** Head branch does not match the EvA naming policy (FB_EVADEV-<ticket>, SB_API-<n>_FB_EVADEV-<ticket>, EVADEV-<ticket>, FB_EvA-DEV-<n>, releases Release_V<maj>.<min>_<ddMMMyyyy>, QA variants suffixed _QA).

*Why:* Consistent branch names drive CI routing and traceability.

### EVA-PRJ-005 — Low-quality commit messages

**Info.** All commit messages are low quality (<= 3 words or fix/update/changes/done/minor/optimised/wip). Real examples: 'done the modification', 'Optimised changes'.

*Why:* Terse messages destroy history value.

### EVA-PRJ-006 — Large diff — tests advisory

**Info.** Large diff of business logic and no test project exists (tests are advisory only in EvA). Verify manually — this never blocks the PR.

*Why:* There is no test project or dotnet test in CI; large changes deserve manual verification.

---

Rule text and rationale are copied verbatim from `eva-standards.json`. If a rule reads wrong, fix it there — not here — so the bot and the skill stay in step.
