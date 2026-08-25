# Anti-rules — things that look wrong and are not

Read this **before** "cleaning up" anything in an EvA repo.

Every item below is a .NET convention that EvA deliberately does not follow. The review bot will not
flag any of them, and neither should you. Changing them creates diff noise, breaks consistency with
hundreds of existing files, and in some cases changes behaviour.

The rule is simple: **if a pattern is in this file, leave it exactly as it is** — including in code
you are already editing for another reason.

---

## The five disabled rules

These exist in `eva-standards.json` with `enabled: false`. They are recorded there precisely so that
nobody re-adds them by mistake.

### `EVA-SP-004` — `sp_PascalCase` proc-constant naming

```csharp
// This is correct. Do not rename it.
public const string sp_GetActivePriceList = "sp_GetActivePriceList";
```

The database owns proc names and the constants mirror them **exactly**, so a grep for a proc name
finds both the SQL and the C#. Sonar `S100` (method naming) and `S101` (type naming) are switched off
in the EvA ruleset for this reason.

Do not "fix" it to `SpGetActivePriceList` or `GET_ACTIVE_PRICE_LIST`.

Source: `EVA.Common/ProcedureConstants/ProcedureConstants.cs`.

### `EVA-NAM-003` — the `Async` suffix

```csharp
// Correct EvA style — no suffix, even though it returns a Task
Task<BaseResponse<bool>> Add(PriceListAddModel model);
Task<BaseResponse<List<PriceListModel>>> GetAll();
```

**Only 7 of 670 `Task`-returning contract methods in the platform end in `Async`.** House style is
the bare verb: `Add`, `Update`, `Get`, `GetAll`, `Delete`, `GetList`.

Adding the suffix to one new method makes that file the odd one out; adding it across a repo is a
breaking rename of every interface. Do neither.

### `EVA-NAM-004` — `CancellationToken` parameters

```csharp
// Correct — no token parameter
public async Task<BaseResponse<bool>> Add(PriceListAddModel model)
```

**Zero `CancellationToken` parameters exist across the entire platform.** Adding one to a new method
means it cannot be called consistently with anything around it, and there is nothing upstream
plumbing a token through. Do not introduce them.

### `EVA-NAM-008` — mixed namespace style

```csharp
// Both of these are fine.
namespace EVA.Pricing.Business.Business   // block — 896 files
{
    public class PriceListBusiness { }
}

namespace EVA.Pricing.Business.Business;  // file-scoped — 114 files
public class PriceListBusiness { }
```

Neither style is wrong. Match whatever the file you are editing already uses, and do not convert a
file from one to the other as a drive-by change.

### `EVA-EXEMPT-S2221` — `catch (Exception ex)`

```csharp
// Correct EvA style. Sonar S2221 is Action="None" in the EvA ruleset.
try
{
    return await _repositories.Add(model);
}
catch (Exception ex)
{
    _logger.Error(nameof(PriceListBusiness), nameof(Add), ex.Message, ex.StackTrace);
    return response.Failure(ResponseType.Err_UnhandledException);
}
```

Catching the base `Exception` type is allowed and is the house pattern.

**What *is* flagged is a silent catch** — a `catch` block that swallows the exception without logging
or returning a failure. That is [`EVA-ERR-001`](rules.md#eva-err-001), and it is a real Error.

---

## SonarQube rules switched off in the EvA ruleset

From `<repo>/.sonarlint/evaerp_<repo>csharp.ruleset`. `Action="None"` means the analyzer will never
raise it, so a suggestion to fix one of these has no authority behind it.

| Sonar rule | What it would complain about | EvA setting |
|---|---|---|
| `S100` | Method name does not match PascalCase | `None` — see `EVA-SP-004` |
| `S106` | `Console.WriteLine` used for logging | `None` |
| `S109` | Magic number | `None` |
| `S138` | Method has too many lines | `None` |
| `S1192` | String literal duplicated | `None` |
| `S1541` | Cyclomatic complexity too high | `None` |
| `S2221` | `catch (Exception)` is too generic | `None` — see above |
| `S3776` | Cognitive complexity too high | `None` |

Still active, so these *are* worth acting on when you see them:

| Sonar rule | Setting | Meaning |
|---|---|---|
| `S101` | `Info` | Type name should be PascalCase |
| `S112` | `Warning` | Do not throw the base `Exception` type |
| `S125` | `Warning` | Commented-out code should be removed |
| `S927` | `Warning` | Parameter name should match the interface declaration |
| `S1481` | `Info` | Unused local variable |
| `S4457` | `Warning` | Split parameter-validation out of the `async` body |

Sonar runs **after** deployment and does not block a merge. It is advisory in EvA, not a gate.

---

## Other intentional oddities

Not rules in the JSON, but the same class of thing — real, deliberate, and not yours to fix:

- **`BaseResposneExtension`** — the typo in the response-extension class name is in every repo.
  Renaming it is a breaking change across the estate.
- **`#region Custom Depedencies`** — the typo in `DIConfiguration.cs` is in all 30 copies.
- **`Program.cs` + `Startup.cs`** on .NET 10 — the classic hosting model is deliberate. Do not
  convert a service to minimal APIs.
- **Hand-written `using.cs`** instead of `<ImplicitUsings>` — see
  [`EVA-NAM-010`](rules.md#eva-nam-010).
- **`services.AddScoped` everywhere, no assembly scanning** — the explicitness is the point.
- **`EVA.Logging` and `EVA.Common` copy-pasted per repo** — this is known technical debt and there is
  a plan for it, but it is not fixed inside a feature PR.
- **PascalCase parameter names** such as `InputModel` — common in older controllers. New code uses
  `camelCase` ([`EVA-CTL-009`](rules.md#eva-ctl-009)), but do not go renaming existing ones.

---

## What this file is *not*

It is not a licence to leave real bugs in place. Genuine defects that exist in the codebase are in
[known-defects.md](known-defects.md) — those you *should* avoid copying.

The distinction: an anti-rule is code that is **correct for EvA** and merely unusual for .NET. A
known defect is code that is **wrong**, has simply not been fixed yet, and will be copied by anyone
who reaches for the file it lives in.
