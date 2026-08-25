---
name: eva-backend-api-skill
description: >
  EvA ERP backend house standards for .NET 10 N-tier APIs
  (Controller -> Business -> Repository -> EF Core / Dapper / stored procs).
  Use when writing, reviewing, or debugging C# in any eva-*-api or EVA.*.API
  repository: adding endpoints, Business/Repository methods, models, DI
  registrations, stored-proc calls, or BaseResponse handling. Encodes the 69
  EVA-* rules the PR review bot gates on, and the patterns that must NOT be
  "fixed" because they are intentional.
---

<!-- eva-backend-api-skill - Author: Manwar Meraj -->

# EvA backend API standards

The EvA PR review bot enforces 69 rules from `eva-standards.json` on every pull request. This skill
is those rules, moved into the editor so you meet them before the PR, not after it.

## Am I in scope?

**Yes** if the repo contains an `EVA.<Domain>.Business` project *and* an `EVA.<Domain>.Repositories`
project — the fingerprint of the template every EvA service was cloned from.

**No** for: `eva-eims-api`, `eva-survey-app`, `eva-sql-manager`, `eva-perf-profiler`,
`eva-api-debugger`. Also no for `eva-api-gateway` (Ocelot router, no Business/Repository layers).

If the repo is out of scope, say so and do not apply these rules to it.

## When the surrounding code disagrees with these rules

**The rules win for new code.** Do not infer the standard from the file you happen to be editing.

Large parts of the estate predate these rules and contradict them — `eva-pricing-api` has Business
methods returning raw `List<>` and a controller that does `new BaseResponse<bool>()`;
`EVA.Template.API` is worse. Matching the neighbouring file feels safe and produces exactly the code
the PR bot blocks.

The bot analyses **added and modified lines only**, so:

- **New code follows the rules**, even in a file where nothing else does.
- **Existing lines are left alone** — no drive-by rewrites of code you were not asked to touch.
- If a rule and the local code disagree, say so in your reply rather than silently picking one.

The exceptions are in `references/anti-rules.md` — patterns that look wrong and are deliberate. Those
you *do* match.

## The shape of every request

```
Controller (thin)  ->  I<X>Business  ->  I<X>Repository  ->  DbContext | IExecuterSqlProc  ->  SQL Server
   IActionResult      BaseResponse<T>      raw List<>/bool/entity
```

Dependencies never flow backwards: a Repository never references the Business project, and neither
references the API project.

## Eleven non-negotiables

Each is an `Error` that blocks PR approval. The wording matches what the bot will post.

1. Controller actions return `Task<IActionResult>` — never `ActionResult<T>`, never `Task<T>`, never
   a non-async action. 663 uses, zero exceptions. `EVA-CTL-001`
2. No business logic in a controller: no `try`/`catch`, no `ILogger`, no `DbContext`, no
   `IRepository`. Exceptions belong to `ErrorHandlingMiddleware`. `EVA-CTL-007`
3. **Exactly one layer builds `BaseResponse<T>`: Business.** `EVA-RSP-001`, `EVA-RSP-007`

   | Layer | Returns |
   |---|---|
   | Controller | `Task<IActionResult>` — passes the Business response through to `Ok` / `BadRequest`. Never constructs one. |
   | **Business** | **`BaseResponse<T>`** — every public method, always. |
   | Repository | raw shapes — `List<>`, `bool`, `int`, entity. **Never `BaseResponse<T>`.** |

   The repository hands up a raw `List<>` or `bool`; the Business method wraps it and returns
   `BaseResponse<T>`; the controller just chooses the status code.
4. Build it with `.Success(...)` / `.Failure(...)` — never `new BaseResponse<T> { ... }` or direct
   property assignment. `EVA-RSP-002`
5. **A read never fails.** `Get` / `GetAll` / `GetList` / `GetById` always return `.Success(...)` —
   no rows is a successful *empty* result, not `Err_NoRecordFound`. Only `Add` / `Update` / `Delete`
   may `.Failure(...)`. `EVA-RSP-008`
6. No literal user-facing messages and no magic status ints. Text lives in `ResponseMessages.resx`,
   resolved through the response-code enum. `EVA-RSP-003`, `EVA-RSP-004`
7. Every EF query and every stored-proc call filters by `OrgId`. The tenant database is chosen per
   request *and* rows are filtered — both, always. `EVA-SEC-001`, `EVA-SEC-002`
8. Never add an EF migration. DBAs own the schema, in `eva-tenant-sql` / `eva-database-sql`.
   `EVA-SEC-010`
9. No `.Result`, no `.Wait()`, no `.GetAwaiter().GetResult()`, no `Task.Run` around sync code, no
   `async void`, no `new HttpClient()`. `EVA-ASY-001`..`006`
10. Never swallow a catch silently. Log through `EVA.Logging.Interface.ILogger` —
    `Error(nameof(Class), nameof(Method), ex.Message, ex.StackTrace)`. `EVA-ERR-001`, `EVA-ERR-003`,
    `EVA-ERR-004`
11. Every new `I<X>Business` / `I<X>Repository` needs an `AddScoped` **pair** in
    `API/Infrastructure/DIConfiguration.cs`. This is the most commonly forgotten step — it compiles
    and then throws at runtime. `EVA-DI-001`

Two more that cost the most rework when missed: the route must carry the repo's module prefix
(`api/pricing/[controller]/[action]`, `EVA-CTL-003`), and `[HttpPost]`/`[HttpPut]` actions taking a
model must guard `ModelState` (`EVA-CTL-004`).

## Five things that look wrong and are not

Do not "fix" any of these. The bot will not flag them, and changing them creates noise and breaks
consistency with hundreds of files.

1. **No `Async` suffix.** Only 7 of 670 `Task`-returning contract methods have one. House style is
   `Add` / `Update` / `Get` / `GetAll` / `Delete` / `GetList`.
2. **No `CancellationToken` parameters.** Zero exist across the platform.
3. **`catch (Exception ex)` is fine.** Sonar S2221 is disabled in the EvA ruleset. Only a *silent*
   catch is a violation.
4. **`sp_PascalCase` proc constants are correct.** They mirror the database names exactly.
5. **Both namespace styles are OK.** Block (896 files) and file-scoped (114) both pass.

Details and the full Sonar suppression list: `references/anti-rules.md`.

## Where to look

| If the task is… | Read |
|---|---|
| Add or change an endpoint | `references/recipe-new-endpoint.md` |
| Query data, call a proc, anything touching tenancy | `references/data-access.md` |
| Look up a specific rule, or a finding the bot posted | `references/rules.md` |
| Something in the codebase looks wrong | `references/anti-rules.md`, then `references/known-defects.md` |
| Which repo / route prefix / project layout / DI / logging | `references/architecture.md` |
| Start a new file from scratch | `assets/templates/` |

`references/rules.md` is generated from `eva-standards.json` by `sync-rules.ps1` — it is always in
step with what the bot actually enforces.

## Things that surprise people

- The logger is **`EVA.Logging.Interface.ILogger`**, not `Microsoft.Extensions.Logging.ILogger<T>`.
  Fixed 4-string signature, no message templates, no generic parameter.
- Serialization is **Newtonsoft** (`AddNewtonsoftJson`), so DTOs use `[JsonProperty]`.
  `[JsonPropertyName]` compiles and is silently inert.
- `Program.cs` + `Startup.cs` on .NET 10 is deliberate. Do not convert to minimal APIs.
- Global usings live in a hand-written `using.cs`, not `<ImplicitUsings>`.
- There is **no `AddAuthentication` / `AddJwtBearer`** — a global `AuthorizationTokenFilter` reads
  the JWT into `HttpContext.Items`.
- The connection string in `appsettings.json` is Base64-encoded. `TranscodeBase64` is obfuscation
  with a committed salt, **not** encryption.
- `EVA.Common` and `EVA.Logging` are copy-pasted per repo, so **nine drifted `BaseResponse<T>`
  variants exist**. Always read the local copy before assuming a property or enum member exists.
- DTO suffixes are `Model` / `AddModel` / `UpdateModel` / `ReadModel` / `GetAllModel` /
  `ResultModel` — never `Dto`, `Request`, `Response` or `ViewModel`.

## Secrets

Plaintext credentials are already committed in this tree (`.mcp.json`, `properties.yaml`,
Base64 connection strings). They are known and deliberately untouched.

Never add a new one, never copy an existing one into another file, and never echo one into output, a
commit message or a PR description. Use an obvious placeholder in examples. `EVA-SEC-006` is an
`Error`.

## Build and test reality

`dotnet build EVA.<Name>.API.sln` is the only gate that exists.

**`eva-wms-api` is the only in-scope repo with a test project.** Everywhere else `dotnet test` is a
no-op. Never invent tests, never run `dotnet test` and present it as verification, and never claim
tests pass. Endpoints are exercised manually through the `Postman-*.postman_collection.json` at each
repo root, with a real JWT — without claims the tenant connection cannot be resolved.

Check `git status` first: repos here sit on whatever branch was last used and several working trees
are dirty. Stash rather than discard.

## Before you open a PR

Run through the checklist at the end of `references/recipe-new-endpoint.md`.

Branch names: `FB_EVADEV-<ticket>`, `SB_API-<n>_FB_EVADEV-<ticket>`, `EVADEV-<ticket>`,
`FB_EvA-DEV-<n>`; releases are `Release_V<maj>.<min>_<ddMMMyyyy>`. Mergeable bases: `main`,
`Dev_Testing`, `QA_Testing`. Squash merge.

`mcp__eva-code-review__review_pr` runs these same rules. `Error`-severity findings block approval.
