# Known defects — real bugs you will be tempted to copy

Distinct from [anti-rules.md](anti-rules.md). An anti-rule is code that is **correct for EvA** and
merely unusual for .NET. Everything here is **wrong**, has not been fixed yet, and will spread if
copied.

None of these are yours to fix inside an unrelated feature PR. The point of this file is that you
**recognise them and do not reproduce them in new code**.

---

## `EVA.Template.API` — do not use it as a starting point

Juniors reach for this repo first because of its name. It is the least healthy service in the estate.

Copy from **`EVA.FinishedGoods.API`** instead.

Verified defects:

| Defect | Where | What good looks like |
|---|---|---|
| `ErrorHandlingMiddleware` exists but is **never registered** in the pipeline | `EVA.Template.API/Infrastructure/ErrorHandlingMiddleware.cs` — no `UseMiddleware<ErrorHandlingMiddleware>()` anywhere | Register it in `Startup.Configure`, before `UseRouting` |
| Middleware returns **HTTP 400 for every exception** | `HandleExceptionAsync` sets `HttpStatusCode.BadRequest` unconditionally | Map the exception kind to a status; EvA in practice uses 200/400 only ([`EVA-CTL-010`](rules.md#eva-ctl-010)) |
| Middleware **leaks the stack trace to the client** | serialises `{ "Message", ex.Message }, { "Stacktrace", ex.StackTrace }` into the response body | Log the stack trace via `ILogger`; return a response code, not the trace |
| `async void Rollback()` | `EVA.Template.Repositories/Common/UnitOfWork.cs:37` | `Task Rollback()` — `async void` cannot be awaited and its exceptions crash the process ([`EVA-ASY-004`](rules.md#eva-asy-004)) |
| `Task.Run` wrapping synchronous ADO | `SqlProcExecuterRepository.cs:41,74`; `EmployeeRepository.cs:42` | Call the genuinely async API ([`EVA-ASY-002`](rules.md#eva-asy-002)) |
| `Task.FromResult` faking async | `HttpContextExtension.cs:26`, `TokenClaimsHelper.cs:14`, `EmployeeRepository.cs:29` | Make the method synchronous, or make it genuinely async ([`EVA-ASY-003`](rules.md#eva-asy-003)) |
| **Duplicate registrations** | `AddSingleton<IHttpContextAccessor>` in both `Startup.cs:41` and `DIConfiguration.cs:22`; `AddControllers` in both `Startup.cs:51` and `DIConfiguration.cs:28` | Register once, in `DIConfiguration.cs` |
| Leftover `EVA.NMS_Employee.*` namespaces | 6 files — a copy-paste that was never renamed | Namespace matches the project |
| Postman collection is for a different service | `Postman-10. EVA GeneralReports API.postman_collection.json` at the repo root | — |

---

## `TranscodeBase64` is obfuscation, not encryption

```csharp
public static string DecodeBase64(string encodedString)
{
    string salt = "<hardcoded salt literal>";     // committed in plaintext, identical in every repo
    // Base64 decode -> strip salt -> Base64 decode again
}
```

Double Base64 with a hardcoded, committed "salt". Anyone with the repo can decode any connection
string in it in seconds.

**Never treat it as a security control.** Do not use it to store anything that is not already
expected to be readable, and do not describe it as encryption in code comments, documentation or PR
descriptions.

---

## Committed secrets exist across the estate

Plaintext credentials are committed in this tree: a GitHub token in `.mcp.json`, IIS credentials and
a SonarQube token in each repo's `properties.yaml`, and real credentials inside the Base64-encoded
connection strings in `appsettings.json`.

This is known and deliberately untouched. Your obligations:

- **Do not add more.** [`EVA-SEC-006`](rules.md#eva-sec-006) is an `Error` and blocks approval.
- **Do not copy an existing one** into a new file, a test fixture, or a script.
- **Do not echo one** into chat output, a commit message, a PR description, or generated code.
- Do not rotate or relocate them as a side effect of unrelated work.

Use an obvious placeholder in any example: `"Password=<from RESTORATION_PATH>"`.

---

## Nine drifted copies of `BaseResponse<T>`

`EVA.Common` and `EVA.Logging` are **copy-pasted into each repo**, not shared through a package. Nine
variants of `BaseResponse<T>` are now in circulation:

- `eva-crm-api` adds `Exception` and `AdditionalMessage`
- `EVA.FinishedGoods.API` has `Steps`
- the response-code enum is `ResponseCode` in some repos and `ResponseType` in others

**Always read the local copy** before assuming a property or an enum member exists. Code that
compiles in one repo will not necessarily compile in the next.

The same applies to `EVA.Logging`: a fix to one copy does not propagate to the other 28.

---

## `eva-pricing-api` — wrong layer builds the envelope

Verified in the current tree. Do not take this repo's response handling as the pattern:

| What it does | Where | The rule |
|---|---|---|
| Controller constructs the envelope: `var refreshQpeResponse = new BaseResponse<bool>();` | `EVA.Pricing.API/Controllers/PricingController.cs:29`, `:63` | Controllers never build one, and nobody uses `new BaseResponse<T>` — [`EVA-RSP-002`](rules.md#eva-rsp-002), [`EVA-CTL-007`](rules.md#eva-ctl-007) |
| Business methods return raw shapes: `Task<List<PriceElementDetailsModel<TKey>>> GetPriceElementsAsync(...)` | `EVA.Pricing.Business/Contracts/*.cs` | Business always returns `BaseResponse<T>` — [`EVA-RSP-001`](rules.md#eva-rsp-001) |
| `Async` suffixes on many of those same methods | same | House style has no suffix — [anti-rules.md](anti-rules.md) |

The correct split is Repository → raw, Business → `BaseResponse<T>`, Controller → pass through. New
code in this repo follows that, even though the file next to it does not.

## Estate-level inconsistencies

Facts about the codebase, not bugs to fix in a feature PR — but worth knowing before you generalise
from one repo:

- **`eva-api` has 102 controllers, no `DIConfiguration.cs`, filters under `Filters/` instead of
  `Infrastructure/`, and four different route shapes.** Read it; do not imitate it.
- **Package drift is severe** — five Swashbuckle majors and four NLog majors across the estate. There
  is no `Directory.Build.props` or `Directory.Packages.props`. Bumping a package version is a
  reviewable change ([`EVA-PRJ-002`](rules.md#eva-prj-002)).
- **`ExceuteProcedureNonQueryAsync`** is misspelled in `IExecuterSqlProc` in every repo. Call it as
  written.
- **`BaseResposneExtension`** and **`#region Custom Depedencies`** are misspelled everywhere. Leave
  them — see [anti-rules.md](anti-rules.md).
- **Default local ports collide** across repos and `launchSettings.json` is not reliable. Read the
  `Now listening on:` line from `dotnet run`.
- **Several `properties.yaml` files still carry copy-pasted values from the template.** Verify
  `PATH_TO_SLN_FILE` and `IIS_APPLICATIONNAME` before trusting a deployment config.

---

## If you find a new one

Add it here with the file and line, and what the correct pattern is. This file is only useful while
it stays specific.
