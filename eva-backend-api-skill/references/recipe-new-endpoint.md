# Recipe: add an endpoint

The full path from "add an endpoint that returns the active price list" to something you can call in
Postman. Ten steps. Skipping step 6 is the single most common failure.

Worked example: a `GetActive` read on `PriceList`, in `eva-pricing-api` (module `pricing`).

Every step names the rules it satisfies — the same rule IDs the PR bot will quote back at you.

---

## Before you start

1. `git status` — repos here sit on whatever branch was last used, and several working trees are
   dirty. Branch from an agreed base (`main`, `Dev_Testing`, `QA_Testing`).
2. Read the **local** `BaseResponse<T>` and the local `ResponseType` / `ResponseCode` enum. Nine
   drifted copies exist across the estate; the one in the repo you are in is the only one that
   matters.
3. Find the repo's module prefix in [architecture.md](architecture.md#4-repo-module-and-route-prefix).

---

## Step 1 — the model

`EVA.Pricing.ViewModel/PriceList/PriceListModel.cs`

```csharp
using Newtonsoft.Json;

namespace EVA.Pricing.ViewModel.PriceList
{
    public class PriceListModel
    {
        [JsonProperty("priceListId")]
        public long PriceListId { get; set; }

        [Required]
        [StringLength(50)]
        [JsonProperty("code")]
        public string Code { get; set; }

        [JsonProperty("isActive")]
        public bool IsActive { get; set; }
    }
}
```

- Suffix from the allowed set: `Model`, `AddModel`, `UpdateModel`, `ReadModel`, `GetAllModel`,
  `ResultModel`, `ToCreateModel`, `ToUpdateModel`. Never `Dto`, `Request`, `Response`, `ViewModel`
  — [`EVA-NAM-005`](rules.md#eva-nam-005).
- **Newtonsoft `[JsonProperty]`.** `[JsonPropertyName]` compiles and does nothing —
  [`EVA-NAM-009`](rules.md#eva-nam-009).
- DataAnnotations here are what makes the controller's `ModelState` guard in step 4 meaningful.

For a paged read, take a `SearchParams` body and return `PaginatedResult<T>` rather than hand-rolling
`Skip`/`Take` — [`EVA-RSP-005`](rules.md#eva-rsp-005).

## Step 2 — the repository

Contract first: `EVA.Pricing.Repositories/Contracts/IPriceListRepository.cs`

```csharp
public interface IPriceListRepository
{
    Task<List<PriceListModel>> GetActive();
}
```

Implementation: `EVA.Pricing.Repositories/Repositories/PriceListRepository.cs`

```csharp
public async Task<List<PriceListModel>> GetActive()
{
    return await _unitOfWork.DataContext.Set<PriceList>()
        .AsNoTracking()
        .Where(x => x.IsActive && x.OrgId == _orgId)      // both conditions, always
        .Select(x => new PriceListModel
        {
            PriceListId = x.PriceListId,
            Code = x.Code,
            IsActive = x.IsActive
        })
        .ToListAsync();
}
```

- Returns the **raw shape** — `List<>`, `bool`, entity, `int`. **Never `BaseResponse<T>`** —
  [`EVA-RSP-007`](rules.md#eva-rsp-007). The envelope is built one layer up, in step 3.
- No `ResponseType`, no `.Success(...)` / `.Failure(...)`, no resx codes in this file.
- Signal "nothing found" with an empty list or `null`, and a failed write with `false` or an
  affected-row count of `0`. Mapping that to a response code is the Business layer's job.
- `.AsNoTracking()` on every read.
- `x.OrgId == _orgId` on every query — [`EVA-SEC-001`](rules.md#eva-sec-001). `_orgId` comes from
  `HttpContext.Items[KeyConstant.AppOrgId]`.
- No `Async` suffix on the method name — that is deliberate, see
  [anti-rules.md](anti-rules.md).

Calling a stored proc instead? See [data-access.md](data-access.md) — the proc name comes from
`ProcedureConstants` ([`EVA-SP-001`](rules.md#eva-sp-001)), every parameter needs an explicit
`SqlDbType` ([`EVA-SP-002`](rules.md#eva-sp-002)), and `OrgId` is always a parameter
([`EVA-SEC-002`](rules.md#eva-sec-002)).

## Step 3 — the business layer

Contract: `EVA.Pricing.Business/Contracts/IPriceListBusiness.cs`

```csharp
public interface IPriceListBusiness
{
    Task<BaseResponse<List<PriceListModel>>> GetActive();
}
```

Implementation: `EVA.Pricing.Business/Business/PriceListBusiness.cs`

```csharp
public class PriceListBusiness : IPriceListBusiness
{
    #region Private Variables

    private readonly IPriceListRepository _priceListRepository;
    private readonly ILogger _logger;                       // EVA.Logging.Interface.ILogger
    private readonly IHttpContextAccessor _httpContextAccessor;
    private readonly int _orgId;

    #endregion Private Variables

    #region Constructor

    public PriceListBusiness(
        IPriceListRepository priceListRepository,
        ILogger logger,
        IHttpContextAccessor httpContextAccessor)
    {
        _priceListRepository = priceListRepository;
        _logger = logger;
        _httpContextAccessor = httpContextAccessor;
        _orgId = Convert.ToInt32(_httpContextAccessor.HttpContext.Items[KeyConstant.AppOrgId]);
    }

    #endregion Constructor

    #region Public Methods

    public async Task<BaseResponse<List<PriceListModel>>> GetActive()
    {
        BaseResponse<List<PriceListModel>> response = new();

        if (_orgId <= 0)
            return response.Failure(ResponseType.Err_UnauthorizedAccess);

        var rows = await _priceListRepository.GetActive() ?? new List<PriceListModel>();

        // Read: empty is still success. Never Err_NoRecordFound here.
        return response.Success(rows, ResponseType.Common_DataFetchSuccess);
    }

    #endregion Public Methods
}
```

- **This is the only layer that builds `BaseResponse<T>`** — [`EVA-RSP-001`](rules.md#eva-rsp-001) —
  and only through `.Success(...)` / `.Failure(...)`, never `new BaseResponse<T> { ... }`
  ([`EVA-RSP-002`](rules.md#eva-rsp-002)).
- **A read never fails.** `Get` / `GetAll` / `GetList` / `GetById` always return `.Success(...)`;
  no rows is a successful empty result — [`EVA-RSP-008`](rules.md#eva-rsp-008). Only
  `Add` / `Update` / `Delete` may `.Failure(...)`.
- Plain constructor injection. You will see `IServiceProvider` + `GetRequiredService` in older
  classes; do not copy it into new ones — [`EVA-DI-003`](rules.md#eva-di-003).
- `_camelCase` private fields ([`EVA-NAM-001`](rules.md#eva-nam-001)), `#region` blocks
  ([`EVA-NAM-007`](rules.md#eva-nam-007)).
- The `_orgId <= 0` guard is the house pattern for "no tenant context" — and the one case where a
  read may still return a failure, because the request was never valid.
- Response codes come from the enum, never from a literal string —
  [`EVA-RSP-003`](rules.md#eva-rsp-003), [`EVA-RSP-004`](rules.md#eva-rsp-004).

## Step 4 — the controller action

`EVA.Pricing.API/Controllers/PriceListController.cs`

```csharp
[Route("api/pricing/[controller]/[action]")]
[ApiController]
public class PriceListController : ControllerBase
{
    private readonly IPriceListBusiness _priceListBusiness;

    public PriceListController(IPriceListBusiness priceListBusiness)
    {
        _priceListBusiness = priceListBusiness;
    }

    [HttpGet]
    public async Task<IActionResult> GetActive()
    {
        var response = await _priceListBusiness.GetActive();
        return Ok(response);                 // read: Ok even on failure
    }

    [HttpPost]
    public async Task<IActionResult> Add([FromBody] PriceListAddModel model)
    {
        if (!ModelState.IsValid)
        {
            var errors = string.Join(", ", ModelState.Values
                .SelectMany(v => v.Errors)
                .Select(e => e.ErrorMessage));

            return BadRequest(errors);
        }

        var response = await _priceListBusiness.Add(model);

        if (!response.Success)
            return BadRequest(response);     // write: BadRequest on failure

        return Ok(response);
    }
}
```

- `Task<IActionResult>`. Never `ActionResult<T>`, never `Task<T>`, never a non-async action — 663
  uses, zero exceptions — [`EVA-CTL-001`](rules.md#eva-ctl-001).
- `ControllerBase` + `[ApiController]` + `[Route]` — [`EVA-CTL-002`](rules.md#eva-ctl-002).
- `ModelState` guard on every `[HttpPost]` / `[HttpPut]` taking a model —
  [`EVA-CTL-004`](rules.md#eva-ctl-004) — and build the message with `SelectMany`, not
  `string.Join("", ModelState.Values)` which loses the text entirely
  ([`EVA-CTL-005`](rules.md#eva-ctl-005)).
- **Write ops return `BadRequest(response)` on failure; read ops return `Ok(response)` regardless** —
  [`EVA-CTL-006`](rules.md#eva-ctl-006).
- Nothing else in here: no `try`/`catch`, no `ILogger`, no `DbContext`, no `UnitOfWork` plumbing.
  Exceptions belong to `ErrorHandlingMiddleware` — [`EVA-CTL-007`](rules.md#eva-ctl-007).
- Bind payloads with `[FromBody]` and scalars with `[FromHeader]`; new `[FromQuery]` / `[FromRoute]`
  scalars break the Angular client contract — [`EVA-CTL-008`](rules.md#eva-ctl-008). New
  `[FromHeader]` names are camelCase ([`EVA-CTL-009`](rules.md#eva-ctl-009)).
- Only 200 and 400 are used across the platform. A new 201/204/404 needs justification —
  [`EVA-CTL-010`](rules.md#eva-ctl-010).

## Step 5 — the route prefix

The route must carry the repo's module segment: `api/pricing/[controller]/[action]` in
`eva-pricing-api`, `api/crm/...` in `eva-crm-api` — [`EVA-CTL-003`](rules.md#eva-ctl-003). The full
table is in [architecture.md](architecture.md#4-repo-module-and-route-prefix).

The gateway strips that segment when forwarding, so when you call your locally-run service directly
you drop it: `POST https://localhost:5001/api/PriceList/Add`.

## Step 6 — register the DI pair

`EVA.Pricing.API/Infrastructure/DIConfiguration.cs`, inside `#region Custom Depedencies`:

```csharp
services.AddScoped<IPriceListBusiness, PriceListBusiness>();
services.AddScoped<IPriceListRepository, PriceListRepository>();
```

**This is the step people forget.** It compiles without it, then throws
`Unable to resolve service for type 'IPriceListBusiness'` on the first request. Always `AddScoped`,
always both halves — [`EVA-DI-001`](rules.md#eva-di-001).

## Step 7 — response codes in resx

Add the code to the local `ResponseType` / `ResponseCode` enum **and** a matching key in
`EVA.Pricing.Common/ResponseMessages/ResponseMessages.resx`. The enum member name *is* the resx key;
`GetDescription()` resolves it through `ResourceManager` at runtime.

```csharp
Err_PriceList_LoadFailed = 1101,
```

A missing resx entry produces an empty `Message` on the wire with no error — it is silent. Check both
files — [`EVA-RSP-003`](rules.md#eva-rsp-003), [`EVA-RSP-004`](rules.md#eva-rsp-004).

## Step 8 — the endpoint response map

`EVA.Pricing.API/Infrastructure/ErrorHandlingMiddleware.cs`:

```csharp
{ "/api/pricing/PriceList/GetActive", ResponseCode.Err_PriceList_LoadFailed },
```

Without an entry, an unhandled exception on this route surfaces as the generic
`Err_UnhandledException` — [`EVA-RSP-006`](rules.md#eva-rsp-006). Add one when the endpoint has a
meaningful failure code; skip it when the generic one is genuinely right.

## Step 9 — global usings

New namespace used across the project? Add it to the project's hand-written `using.cs`, not to
`<ImplicitUsings>` — [`EVA-NAM-010`](rules.md#eva-nam-010).

## Step 10 — build and call it

```bash
cd D:\1_EvaDev\eva-pricing-api
dotnet build EVA.Pricing.API.sln
dotnet run --project EVA.Pricing.API
```

Read the actual `Now listening on:` line — `launchSettings.json` is not reliable and default ports
collide between repos.

**There are no tests.** `eva-wms-api` is the only in-scope repo with a test project at all. Do not
run `dotnet test` and report it as verification. Exercise the endpoint through the
`Postman-*.postman_collection.json` at the repo root, with a real JWT — without claims the tenant
connection cannot be resolved and nothing will work.

---

## Before you open the PR

- [ ] Route carries the module prefix
- [ ] `Task<IActionResult>`, `ModelState` guard on writes, `BadRequest` on write failure
- [ ] Every query and every proc call filters `OrgId`
- [ ] `BaseResponse<T>` in the **Business layer only**, built with `.Success(...)` / `.Failure(...)`
- [ ] Repository returns raw shapes — no `BaseResponse<T>`, no `ResponseType`
- [ ] Reads (`Get`/`GetAll`/`GetList`) return `.Success(...)` even when empty
- [ ] No literal user-facing strings — enum member plus resx key, both added
- [ ] `AddScoped` pair in `DIConfiguration.cs`
- [ ] No `.Result`, no `.Wait()`, no `Task.Run`, no `async void`, no `new HttpClient()`
- [ ] No `try`/`catch` or logger in the controller; no silent catch anywhere
- [ ] No `Async` suffix, no `CancellationToken` invented
- [ ] **No EF migration added** — DBAs own the schema
- [ ] No secret, connection string or token added to any file
- [ ] `dotnet build` clean

Branch names: `FB_EVADEV-<ticket>`, `SB_API-<n>_FB_EVADEV-<ticket>`, `EVADEV-<ticket>`,
`FB_EvA-DEV-<n>`; releases are `Release_V<maj>.<min>_<ddMMMyyyy>`
([`EVA-PRJ-004`](rules.md#eva-prj-004)).

Mergeable bases: `main`, `Dev_Testing`, `QA_Testing`. Squash merge. `Error`-severity findings block
approval, so the list above is worth a minute.

Write a real commit message — [`EVA-PRJ-005`](rules.md#eva-prj-005).
