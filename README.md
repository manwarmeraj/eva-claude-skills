# eva-claude-skills

Claude Code skills for EvA ERP engineering.

**Author:** Manwar Meraj

One plugin: **`eva-backend-api`** — the backend API house standards for every `eva-*-api` and
`EVA.*.API` repository.

---

## For developers

Two commands, once per machine. Not per repo.

```powershell
claude plugin marketplace add manwarmeraj/eva-claude-skills
claude plugin install eva-backend-api@eva
```

Then **restart Claude Code** and open any EvA API repo.

There is nothing to type after that. No skill name to remember, no command to invoke — it loads by
itself whenever you touch C# in an in-scope repository.

### Check it worked

```powershell
claude plugin list                          # want: eva-backend-api@eva ... enabled
claude plugin details eva-backend-api@eva   # want: Skills (1) eva-backend-api-skill
```

Or ask Claude directly, inside an EvA repo: *"Is a skill named eva-backend-api-skill available to
you right now?"*

### Keeping it current

The plugin is a local clone and **does not auto-update**. When the standards change:

```powershell
claude plugin marketplace update eva
claude plugin update eva-backend-api@eva
```

Without those, you silently keep the version you installed.

### No Claude CLI on PATH?

`dist\EvA-Backend-Skill-Installer.md` is a single self-contained file — mail or Teams it, and the
recipient either hands it to Claude Code or pastes the PowerShell block inside it. Slower to update,
so prefer the marketplace where you can.

---

## What the skill covers

The 69 enforced `EVA-*` rules from `eva-standards.json` — the same file the PR review bot reads, so
the two cannot drift apart. It analyses **added and modified lines only**, so you are never blamed
for code you did not touch.

| Severity | Count | Effect |
|---|---|---|
| `Error` | 33 | Blocks PR approval |
| `Warning` | 25 | Fix it or justify it |
| `Info` | 11 | Style nudge |

The point is timing. These rules already existed, but only the bot could read them — so a developer
learned a rule *after* opening a PR. The skill moves them into the editor.

The headline convention, and the one people get wrong most often:

| Layer | Returns |
|---|---|
| Controller | `Task<IActionResult>` — passes the Business response through to `Ok` / `BadRequest`. Never constructs one. |
| **Business** | **`BaseResponse<T>`** — every public method, always. Built with `.Success(...)` / `.Failure(...)`. |
| Repository | raw shapes — `List<>`, `bool`, `int`, entity. **Never `BaseResponse<T>`.** |

Reads never fail: `Get` / `GetAll` / `GetList` / `GetById` always return `.Success(...)`. No rows is
a successful *empty* result, not `Err_NoRecordFound`. Only writes may fail.

It equally records the patterns that are **intentional** and must not be "fixed" — no `Async` suffix,
no `CancellationToken`, `catch (Exception)`, `sp_PascalCase`, both namespace styles. See
`references/anti-rules.md`.

Cost: ~205 tokens always-on, ~3k when it fires.

### What it does not do

**It does not replace review.** It moves the default much closer to house style; it does not
guarantee correct output. Where existing code contradicts a rule, Claude sometimes mirrors the file
next to it — observed on Business-layer return types in the older repos. **When the skill and the PR
bot disagree, the bot wins.**

It does not invent tests either. `eva-wms-api` is the only in-scope repo with a test project;
everywhere else `dotnet test` is a no-op.

---

## Scope

**Covered:** every repo with an `EVA.<Domain>.Business` + `EVA.<Domain>.Repositories` pair.

**Not covered:** `eva-eims-api`, `eva-survey-app`, `eva-sql-manager`, `eva-perf-profiler`,
`eva-api-debugger`, `eva-api-gateway`.

---

## For maintainers

### Changing a rule

`eva-standards.json` in `eva-code-review-mcp-server` is the single source of truth. Edit it there so
the bot and the skill change together — never edit `references/rules.md` by hand, it is generated.

```powershell
.\sync-rules.ps1        # regenerate eva-backend-api-skill\references\rules.md
.\verify-parity.ps1     # must print PASS
claude plugin validate . --strict
```

Then bump `version` in `.claude-plugin\plugin.json`, commit, push, and tell the team to run the two
update commands above.

`sync-rules.ps1` expects `eva-code-review-mcp-server` cloned as a sibling of this folder; pass
`-StandardsPath` otherwise.

Hand-written code examples live in `snippets\<RULE-ID>.md` and are merged into `rules.md` at
generation time, so regenerating never destroys them.

### Rolling out per repo

`rollout-to-repos.ps1` writes `.claude\settings.json` into every in-scope EvA repo, declaring the
marketplace and enabling the plugin, so the requirement travels with the repo:

```powershell
.\rollout-to-repos.ps1 -WhatIf     # 33 repos targeted
.\rollout-to-repos.ps1
```

It merges into an existing `settings.json` rather than clobbering it, writes UTF-8 **without** BOM
(a BOM breaks the settings parser), skips out-of-scope repos, and refuses any repo where `.claude\`
is gitignored. It never stages or commits — the repos sit on feature branches with dirty trees, so
review and commit them yourself.

Caveat worth knowing: a committed `settings.json` declares the *source*. It was not observed to
install the plugin on its own through any CLI path tested, so keep the two install commands in
onboarding until someone confirms otherwise on a clean machine.

### Scripts

| Script | Purpose |
|---|---|
| `sync-rules.ps1` | Regenerate `references/rules.md` from `eva-standards.json` |
| `verify-parity.ps1` | Regression test — rule parity, secret scan, scope. Run before publishing. |
| `rollout-to-repos.ps1` | Write `.claude/settings.json` into every in-scope repo |
| `make-installer.ps1` | Pack the skill into one mailable `.md` (gated on `verify-parity`) |
| `install.ps1` | Manual copy into `~\.claude\skills` — fallback, pre-dates the plugin route |

---

## Layout

```
eva-claude-skills\
├─ .claude-plugin\
│  ├─ marketplace.json         marketplace manifest ("eva")
│  └─ plugin.json              plugin manifest ("eva-backend-api")
├─ sync-rules.ps1
├─ verify-parity.ps1
├─ rollout-to-repos.ps1
├─ make-installer.ps1
├─ install.ps1
├─ snippets\                   hand-written code examples, merged into rules.md
├─ dist\                       generated single-file installer
└─ eva-backend-api-skill\
   ├─ SKILL.md                 always loaded: scope, non-negotiables, routing table
   ├─ references\
   │  ├─ architecture.md       layers, repo->module->route registry, DI, tenancy, logging
   │  ├─ rules.md              GENERATED - the 69 enforced rules
   │  ├─ anti-rules.md         the 5 disabled rules + Sonar suppressions: do not "fix" these
   │  ├─ recipe-new-endpoint.md  ten-step walkthrough, rule-annotated
   │  ├─ data-access.md        EF / procs / Dapper, tenancy, the two-repo schema workflow
   │  └─ known-defects.md      real bugs that will be copied if not called out
   └─ assets\templates\        rule-clean starting files with {{Domain}} placeholders
```

`SKILL.md` is loaded on every trigger, so it stays short. Everything else is read on demand — keep it
that way when adding content.

---

## Verification

`verify-parity.ps1` fails if:

- an enabled rule is missing from `rules.md`, or a disabled one is missing from `anti-rules.md`
- a disabled rule leaked into `rules.md`
- `rules.md` was generated from an older `eva-standards.json` version
- **any secret-shaped literal appears anywhere in the skill folder**
- an out-of-scope repo is referenced as though it were in scope
- a required file is missing, or `SKILL.md` lost its frontmatter

The secret check is not decoration: the skill teaches `EVA-SEC-006`, so it must not contain a
credential itself — not even as an illustrative example. Use obvious placeholders.

---

## Contributing

- New rule, or changed wording → edit `eva-standards.json`, then `sync-rules.ps1`.
- Better example for an existing rule → edit `snippets\<RULE-ID>.md`, then `sync-rules.ps1`.
- New defect discovered → add it to `known-defects.md` with the file, the line, and the correct
  pattern. It is only useful while it stays specific.
- A developer hit something the skill did not answer, or answered wrongly → that is the backlog. Add
  the answer to the reference file it belongs in.

Run `verify-parity.ps1` and `claude plugin validate . --strict` before publishing.
