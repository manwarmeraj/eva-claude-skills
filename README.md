# eva-claude-skills

Claude Code skills for EvA ERP engineering.

**Author:** Manwar Meraj

Currently one plugin: **`eva-backend-api`**, the backend API house standards for every
`eva-*-api` and `EVA.*.API` repository.

---

## What it does

`eva-backend-api-skill` teaches Claude Code how EvA API repos are actually written: the layering, the
`BaseResponse<T>` envelope, the tenancy rules, the stored-proc conventions — and the 67 `EVA-*` rules
that the PR review bot gates on.

The point is timing. Those rules already exist in
`eva-code-review-mcp-server/Standards/eva-standards.json`, but only the bot can read them, so a
developer learns a rule *after* opening a PR. This skill moves them into the editor.

It also records the patterns that look wrong but are **intentional** — no `Async` suffix, no
`CancellationToken`, `catch (Exception)`, `sp_PascalCase` — so nobody wastes a review cycle
"fixing" them.

Cost: ~205 tokens always-on, ~3k when it fires.

---

## Install (developers)

Two commands. Ask your lead which source line to use.

```powershell
claude plugin marketplace add \\<fileserver>\<share>\eva-claude-skills
claude plugin install eva-backend-api@eva
```

or, if the repo is on GitHub:

```powershell
claude plugin marketplace add evaerp/eva-claude-skills
claude plugin install eva-backend-api@eva
```

Then start a **new** Claude Code session in any EvA API repo. The skill loads automatically — you
never invoke it by name.

Check it worked:

```powershell
claude plugin list
```

### Which source to use

| Source | Behaviour | Use when |
|---|---|---|
| **Network share / folder path** | Referenced **in place** — nothing is copied. Edits to the share are live for everyone on their next session, with no re-install. | No git. Everyone is on the LAN or VPN. |
| **GitHub repo** | Cloned to `~\.claude\plugins\marketplaces\eva`. Works offline. Update with `claude plugin marketplace update eva`. | The repo is hosted and devs work off-network. |

The share route trades offline access for zero-effort updates. If a dev is off VPN, a share-sourced
marketplace is unreachable and the skill will not load.

### No Claude CLI on PATH?

`dist\EvA-Backend-Skill-Installer.md` is a single self-contained file — mail or Teams it, and the
recipient either hands it to Claude Code or pastes the PowerShell block inside it. Slower to update
(you must re-send after every change), so prefer a marketplace where you can.

---

## Update (maintainer)

The rule reference is generated, not hand-written. After anyone edits `eva-standards.json`:

```powershell
.\sync-rules.ps1        # regenerate eva-backend-api-skill\references\rules.md
.\verify-parity.ps1     # must print PASS
.\make-installer.ps1    # only if you also distribute the single-file installer
```

Then bump `version` in `.claude-plugin\plugin.json` and publish (push, or copy to the share).

- **Share-sourced** devs pick it up on their next session automatically.
- **GitHub-sourced** devs run `claude plugin marketplace update eva`.

`sync-rules.ps1` expects `eva-code-review-mcp-server` to be cloned as a sibling of this folder. Pass
`-StandardsPath` if yours lives elsewhere.

Hand-written code examples live in `snippets\<RULE-ID>.md` and are merged into `rules.md` at
generation time — regenerating never destroys them. To improve an example, edit the snippet and
re-run `sync-rules.ps1`. To change *rule wording*, edit `eva-standards.json`, so the bot and the
skill change together.

---

## Layout

```
eva-claude-skills\
├─ .claude-plugin\
│  ├─ marketplace.json         marketplace manifest ("eva")
│  └─ plugin.json              plugin manifest ("eva-backend-api")
├─ sync-rules.ps1              regenerate rules.md from eva-standards.json
├─ verify-parity.ps1           regression test (run before publishing)
├─ make-installer.ps1          pack everything into one mailable .md
├─ install.ps1                 manual copy into ~\.claude\skills (fallback)
├─ snippets\                   hand-written code examples, merged into rules.md
├─ dist\                       generated single-file installer
└─ eva-backend-api-skill\
   ├─ SKILL.md                 always loaded: scope, non-negotiables, routing table
   ├─ references\
   │  ├─ architecture.md       layers, repo->module->route registry, DI, tenancy, logging
   │  ├─ rules.md              GENERATED - the 67 enforced rules
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

```powershell
.\verify-parity.ps1                       # rule parity + secret scan + scope
claude plugin validate . --strict         # manifests
```

`verify-parity.ps1` fails if:

- an enabled rule is missing from `rules.md`, or a disabled one is missing from `anti-rules.md`
- a disabled rule leaked into `rules.md`
- `rules.md` was generated from an older `eva-standards.json` version
- **any secret-shaped literal appears anywhere in the skill folder**
- an out-of-scope repo is referenced as though it were in scope
- a required file is missing, or `SKILL.md` lost its frontmatter

The secret check is not decoration: the skill teaches `EVA-SEC-006`, so it must not contain a
credential itself — not even as an illustrative example. Use obvious placeholders.

`make-installer.ps1` refuses to package unless `verify-parity.ps1` passes.

---

## Scope

**Covered:** every repo with an `EVA.<Domain>.Business` + `EVA.<Domain>.Repositories` pair.

**Not covered:** `eva-eims-api`, `eva-survey-app`, `eva-sql-manager`, `eva-perf-profiler`,
`eva-api-debugger`, `eva-api-gateway`.

---

## Contributing

- New rule, or changed wording → edit `eva-standards.json`, then `sync-rules.ps1`.
- Better example for an existing rule → edit `snippets\<RULE-ID>.md`, then `sync-rules.ps1`.
- New defect discovered → add it to `known-defects.md` with the file, the line, and what the correct
  pattern is. It is only useful while it stays specific.
- A junior hit something this skill did not answer → that question is the backlog. Add the answer to
  the reference file it belongs in.

Run `verify-parity.ps1` and `claude plugin validate . --strict` before publishing.
