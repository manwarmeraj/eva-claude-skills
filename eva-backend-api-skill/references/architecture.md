# EvA backend architecture

How an EvA API is put together, and where your code goes.

## 1. Is this repo in scope?

**Yes** if the repo contains an `EVA.<Domain>.Business` project *and* an `EVA.<Domain>.Repositories`
project. That is the fingerprint of the shared template every service was cloned from.

**Explicitly out of scope** — these do not follow the conventions in this skill, and applying them
here produces wrong advice:

`eva-eims-api` · `eva-survey-app` · `eva-sql-manager` · `eva-perf-profiler` · `eva-api-debugger`

`eva-api-gateway` is in the estate but is an Ocelot router, not an N-tier service. It has no
Business/Repository layers and none of the layering rules apply to it.

## 2. The shape of every request

```
HTTP  ->  AuthorizationTokenFilter        global IAsyncAuthorizationFilter: reads the JWT,
          (Infrastructure/)               puts claims into HttpContext.Items
            |
            v
          Controller                      thin. bind -> guard ModelState -> call ONE Business
          (API/Controllers/)              method -> Ok / BadRequest. Nothing else.
            |
            v
          I<X>Business  ->  <X>Business   orchestration, OrgId guard, BaseResponse<T> shaping
          (Business/Contracts, Business/Business/)
            |
            v
          I<X>Repository -> <X>Repository data access only. Raw shapes, no BaseResponse.
          (Repositories/)
            |
            +--> DbContext            EF Core, via IUnitOfWork
            +--> IExecuterSqlProc     stored procs  (the dominant path)
            +--> Dapper               rare; only where a proc does not fit
            |
            v
          SQL Server                  one database per tenant, OrgId column inside it
```

**Dependencies never flow backwards.** A Repository never references the Business project, and
neither references the API project. If you find yourself needing `HttpContext` in a Repository, the
value belongs in a method parameter instead.

## 3. Projects in a service repo

| Project | Holds | Notes |
|---|---|---|
| `EVA.<Domain>.API` | Controllers, `Program.cs`, `Startup.cs`, `Infrastructure/`, `Middleware/` | The only project with ASP.NET types |
| `EVA.<Domain>.Business` | `Contracts/I<X>Business.cs`, `Business/<X>Business.cs` | Orchestration |
| `EVA.<Domain>.Repositories` | `<X>Repository.cs`, `Common/UnitOfWork.cs`, `Mapper/` (Mapster) | Data access |
| `EVA.<Domain>.DbEntities` | `DbModels/<Domain>DbContext.cs` plus entities | Scaffolded, Fluent-mapped |
| `EVA.<Domain>.ViewModel(s)` | request/response `*Model` classes | Never suffixed `ViewModel` |
| `EVA.<Domain>.Common` | `BuildConnectionString`, `TranscodeBase64`, `BaseResponse<T>`, `KeyConstant`, `ProcedureConstants` | |
| `EVA.Logging` | NLog wrapper | **Vendored** — copied into each repo, not a NuGet package |

Naming varies: some repos use `.Repositories`, some `.Repository`; some `.ViewModel`, some
`.ViewModels`; entities live in `.DbEntities`, `.Entities` or `.Business.Entities`. **Read the
repo's solution file before assuming** — do not rename anything to match another repo.

Every in-scope project targets **`net10.0`**.

## 4. Repo, module and route prefix

Controllers are routed `[Route("api/<module>/[controller]/[action]")]`. The module segment is fixed
per repo — this table is the authority (it mirrors the registry in
`eva-code-review-mcp-server/appsettings.json`).

| Repo | Module | Route prefix |
|---|---|---|
| `eva-api` | core | `api` |
| `eva-crm-api` | crm | `api/crm` |
| `eva-rbac-api` | rbac | `api/rbac` |
| `eva-order-api` | order | `api/order` |
| `eva-pricing-api` | pricing | `api/pricing` |
| `eva-planning-api` | planning | `api/planning` |
| `eva-machine-api` | machine | `api/machine` |
| `eva-mes-api` | mes | `api/mes` |
| `eva-wms-api` | wms | `api/wms` |
| `eva-shopfloor-api` | shopfloor | `api/shopfloor` |
| `eva-checklist-api` | checklist | `api/checklist` |
| `eva-survey-api` | survey | `api/survey` |
| `eva-surveyfg-api` | surveyfg | `api/surveyfg` |
| `eva-presurvey-api` | presurvey | `api/presurvey` |
| `eva-smart-quote-api` | smartquote | `api/smartquote` |
| `eva-fgsystems-api` | fgsystems | `api/fgsystems` |
| `eva-fgreports-api` | fgreports | `api/fgreports` |
| `eva-reports-api` | reports | `api/reports` |
| `eva-generalreports-api` | generalreports | `api/generalreports` |
| `eva-filehandling-api` | filehandling | `api/filehandling` |
| `eva-healthcheck-api` | healthcheck | `api/healthcheck` |
| `eva-integration-api` | integration | `api/integration` |
| `eva-configuration-api` | configuration | `api/configuration` |
| `eva.EasyQuote.api` | easyquote | `api/easyquote` |
| `EVA.FinishedGoods.API` | finishedgoods | `api/finishedgoods` |
| `EVA.Caching.API` | caching | `api/caching` |
| `EVA.Dashboard.API` | dashboard | `api/dashboard` |
| `EVA.Template.API` | template | `api/template` |
| `EVA.InventoryReports.API` | inventoryreports | `api/inventoryreports` |
| `EVA.InventoryManagement.API` | inventorymanagement | `api/inventorymanagement` |
| `EVA.StockManagement.API` | stockmanagement | `api/stockmanagement` |
| `EvA.AISHosted.Integration.API` | aishosted | `api/aishosted` |
| `dummy-crm-api` | crm | `api/crm` (scratch copy of `eva-crm-api` — safe to break) |

Registered with the review bot but not N-tier services:
`eva-customertoeva-event-publisher`, `eva-evatocustomer-event-subscriber`, `eva-console-app`.

Repo name is **not** a string transform of the project name. `eva-configuration-api` builds
`EVA.TaskFlow.API`; `eva-smart-quote-api` builds `EVA.SmartQuotes.API` (plural); `eva-api` builds
both `EVA.API` and `EVA.Tenant.API`. Read the solution file.

The gateway strips the module segment before forwarding, so a cURL copied from `evaerp.cloud` must
have that segment removed before it will hit a locally-run service.

## 5. Startup

`Program.cs` plus `Startup.cs` — the classic hosting model, **not** minimal APIs, even on .NET 10.
Do not "modernise" it.

`ConfigureServices` runs: localization, `AddControllers` (plus OData in some repos), `AddDbContext`,
Swagger, CORS, response compression, memory cache, `AddHttpClient`, `AppConfig` / `LoggerConfig`
options, health checks, rate limiter, then `DIConfiguration.CustomDependencies(services)` **last**.

`Configure` pipeline order:

```
UseSwagger -> UseSwaggerUI -> UseMiddleware<SanitizationMiddleware>
  -> UseRequestLocalization -> UseHttpsRedirection -> UseRouting
  -> UseAuthorization -> UseCors -> UseRateLimiter -> UseEndpoints
```

There is **no `AddAuthentication` and no `AddJwtBearer`.** All token handling is done by
`AuthorizationTokenFilter`, registered as a global MVC filter. `UseAuthorization()` is present but
has no scheme behind it.

`Startup` reads **only `appsettings.json`** plus environment variables. The `appsettings-UAT.json`
style files committed in-repo are *not* picked up by config layering — Jenkins copies the real one
in at deploy time. Switching environment locally means overwriting `appsettings.json` itself.

The connection string in `appsettings.json` is **Base64-encoded**, decoded at startup by
`TranscodeBase64.DecodeBase64`.

## 6. Dependency injection

All registration is manual, in `EVA.<Domain>.API/Infrastructure/DIConfiguration.cs`:

```csharp
public static class DIConfiguration
{
    public static void CustomDependencies(IServiceCollection services)
    {
        #region Common Dependencies
        services.AddSingleton<IHttpContextAccessor, HttpContextAccessor>();
        services.AddScoped<DbContext, PricingDbContext>();
        services.AddScoped<IUnitOfWork, UnitOfWork>();
        services.AddScoped<ILogger, Logger>();                 // EVA.Logging.Interface.ILogger
        services.AddScoped<IExecuterSqlProc, SqlProcExecuterRepository>();
        services.AddScoped<IBuildConnectionString, BuildConnectionString>();
        services.AddControllers(options =>
        {
            options.Filters.Add<AuthorizationTokenFilter>();   // global token filter
            options.EnableEndpointRouting = false;
        })
        .AddNewtonsoftJson(options => options.SerializerSettings.Formatting = Formatting.Indented);
        services.AddMapster();
        #endregion Common Dependencies

        #region Custom Depedencies
        services.AddScoped<IPricingBusiness, PricingBusiness>();
        services.AddScoped<IPricingRepository, PricingRepository>();
        #endregion Custom Depedencies
    }
}
```

Note the signature: a plain `static void` taking `IServiceCollection`, **not** an extension method —
all 30 copies in the estate agree. The `Custom Depedencies` typo is in every repo; leave it alone.

**Every one of the 221 registrations across the estate is `AddScoped`.** There is no assembly
scanning. A new `I<X>Business` / `I<X>Repository` that is not added here compiles fine and throws
`Unable to resolve service for type` on the first request. See [`EVA-DI-001`](rules.md#eva-di-001).

Serialization is **Newtonsoft** (`AddNewtonsoftJson`), so DTOs use `[JsonProperty]`.
`[JsonPropertyName]` compiles and does nothing — see [`EVA-NAM-009`](rules.md#eva-nam-009).

## 7. Multi-tenancy — two mechanisms, both required

**(a) Database per tenant.** `AuthorizationTokenFilter.AddTokenPropertiesInHttpContext` puts the JWT
claims into `HttpContext.Items`:

| `KeyConstant` | Claim | Meaning |
|---|---|---|
| `TenantId` | `tid` | tenant database name |
| `ServerId` | `sid` | SQL Server host, Base64-encoded |
| `OrgId` | `org` | organisation |
| `AppOrgId` | `aoid` | **the value repositories filter on** |
| `AppUserId` | `auid` | user |
| `UserName` / `Sub` | `sub` | login |
| `Subid` | `subid` | user GUID |
| `AccessToken` | — | the raw bearer token |
| `ImsClaim` | — | the whole deserialized claim model |

`<Domain>DbContext.OnConfiguring` then calls
`_buildConnectionString.PreparedConnection(IMSClaimDetails.tid)`, which swaps `Server` (decoded from
`sid`) and `Initial Catalog` (from `tid`) into the decoded base connection string, per request.

**(b) `OrgId` row filter.** One tenant database still holds many organisations. Every EF query and
every stored proc must additionally filter on `OrgId` — see [`EVA-SEC-001`](rules.md#eva-sec-001)
and [`EVA-SEC-002`](rules.md#eva-sec-002).

Getting (a) right is **not** a substitute for (b). Skipping (b) is a cross-tenant data leak.

A request with no JWT claims cannot resolve a connection at all, which is why local testing needs a
real token.

## 8. Responses

**The Business layer owns the envelope. The Repository does not.**

| Layer | Returns | Why |
|---|---|---|
| Controller | `Task<IActionResult>` wrapping the Business response | `Ok` / `BadRequest` only |
| Business | `BaseResponse<T>` | the single place the envelope is built ([`EVA-RSP-001`](rules.md#eva-rsp-001)) |
| Repository | **raw shapes** — `List<>`, `bool`, `int`, entity | no envelope, no response codes ([`EVA-RSP-007`](rules.md#eva-rsp-007)) |

A repository signals "nothing found" with an empty list or `null`, and a failed write with `false` or
an affected-row count of `0`. Translating that into a response code happens one layer up.

**Reads never fail.** `Get` / `GetAll` / `GetList` / `GetById` always return `.Success(...)` — an
empty result is a successful read, not `Err_NoRecordFound`
([`EVA-RSP-008`](rules.md#eva-rsp-008)). Only `Add` / `Update` / `Delete` may `.Failure(...)`. The
one exception is the `_orgId <= 0` guard: no tenant context means the request was never valid.

This is the same contract the controller expresses from the other side — reads return `Ok(response)`
regardless, writes return `BadRequest(response)` on failure
([`EVA-CTL-006`](rules.md#eva-ctl-006)).

The envelope itself:

```csharp
public class BaseResponse<T>
{
    public int Code { get; set; }              // a ResponseType value
    public bool Success { get; set; }
    public string Message { get; set; }        // resolved from ResponseMessages.resx
    public T Data { get; set; }
    public int RecordsAffected { get; set; }
    // some repos add OutputData / Steps / Exception / AdditionalMessage
}
```

Build it only through the fluent extensions — the typo in the extension class name
(`BaseResposneExtension`) is real, do not correct it:

```csharp
return response.Success(result, ResponseType.Common_DataSaveMsg);
return response.Failure(ResponseType.Err_DataSaveFailed);
```

`ResponseType` member names are `ResponseMessages.resx` keys, resolved by `GetDescription()` through
`ResourceManager`. Never put a literal message string in code — see
[`EVA-RSP-004`](rules.md#eva-rsp-004).

**There are nine drifted copies of `BaseResponse<T>` across the estate** (`eva-crm-api` adds
`Exception` and `AdditionalMessage`; `EVA.FinishedGoods.API` has `Steps`). Always read the local
copy — never assume a property exists because you saw it in another repo.

## 9. Logging

The injected logger is `EVA.Logging.Interface.ILogger` — **not**
`Microsoft.Extensions.Logging.ILogger<T>`. There is no generic parameter and no message template.
The signature is fixed at four strings:

```csharp
void Error(string className, string methodName, string message, string stackTrace);
void Warn (string className, string methodName, string message, string stackTrace);
void Info (string className, string methodName, string message, string stackTrace);
void Debug(string className, string methodName, string message, string stackTrace);
```

Use `nameof()` for the first two arguments — see [`EVA-ERR-004`](rules.md#eva-err-004).

`EVA.Logging` is vendored into roughly 29 repos. A fix to one copy does not propagate to the others.

## 10. Exemplars

**Follow:** `EVA.FinishedGoods.API` — the cleanest expression of the layering, response shaping and
proc-calling style. `eva-surveyfg-api` — 100% route consistency, a good model for controllers.

**Do not imitate:** `eva-api` (102 controllers, no `DIConfiguration.cs`, filters under `Filters/`
instead of `Infrastructure/`, four different route shapes) and `EVA.Template.API` (despite the name
— see [known-defects.md](known-defects.md)). Read them; do not copy them.

## 11. Build and test reality

`dotnet build EVA.<Name>.API.sln` is the only gate that exists.

**`eva-wms-api` is the only in-scope repo with a test project at all.** Everywhere else there is no
test project, so `dotnet test` is a no-op. Never invent tests, never run `dotnet test` and report it
as verification, and never claim tests pass. The API surface is exercised manually through the
`Postman-*.postman_collection.json` at each repo root.

## 12. Deployment

`Jenkinsfile` plus `properties.yaml` per repo: pick a server block by the agent IP, restore
`appsettings.json` and `web.config` from `RESTORATION_PATH`, build Release, msdeploy to IIS, then
optionally run SonarQube. Several `properties.yaml` files still carry copy-pasted values from the
template — verify `PATH_TO_SLN_FILE` and `IIS_APPLICATIONNAME` before trusting them.

Default local ports collide across repos and `launchSettings.json` is not reliable for "the real
port". Read the actual `Now listening on:` line from `dotnet run`.
