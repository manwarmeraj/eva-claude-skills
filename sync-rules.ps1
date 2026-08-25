<#
.SYNOPSIS
    Regenerates eva-backend-api-skill/references/rules.md from the review bot's
    eva-standards.json, so the skill and the PR gate can never disagree.

.DESCRIPTION
    eva-standards.json is the single source of truth for EvA coding rules. It has
    HotReload:true, so it changes. Run this after any change to it.

    Hand-written code examples live in snippets\<RULE-ID>.md and are merged in,
    so regenerating never destroys them.

.EXAMPLE
    .\sync-rules.ps1
    .\sync-rules.ps1 -StandardsPath D:\1_EvaDev\eva-code-review-mcp-server\Standards\eva-standards.json

.NOTES
    Author: Manwar Meraj
#>
[CmdletBinding()]
param(
    [string]$StandardsPath,
    [string]$OutFile,
    [string]$SnippetsDir
)

$ErrorActionPreference = 'Stop'
$root = $PSScriptRoot

if (-not $StandardsPath) {
    $StandardsPath = Join-Path (Split-Path $root -Parent) 'eva-code-review-mcp-server\Standards\eva-standards.json'
}
if (-not $OutFile)     { $OutFile     = Join-Path $root 'eva-backend-api-skill\references\rules.md' }
if (-not $SnippetsDir) { $SnippetsDir = Join-Path $root 'snippets' }

if (-not (Test-Path $StandardsPath)) {
    throw "Standards file not found: $StandardsPath`nClone eva-code-review-mcp-server next to this folder, or pass -StandardsPath."
}

$json  = Get-Content $StandardsPath -Raw -Encoding UTF8 | ConvertFrom-Json
$rules = $json.rules

# Rules with enabled:false are NOT enforced. They belong in anti-rules.md, not here.
$enforced = $rules | Where-Object { $_.enabled -ne $false }
$disabled = $rules | Where-Object { $_.enabled -eq $false }

# Error first: these block approval (BlockApproveOnError:true).
$sevRank = @{ 'Error' = 0; 'Warning' = 1; 'Info' = 2 }

# Categories in the order a developer meets them while writing a feature.
$catOrder = @(
    'Tenancy', 'Security', 'Async', 'Controller', 'Response',
    'ErrorHandling', 'DataAccess', 'DependencyInjection', 'Naming', 'Project'
)
function Get-CatRank($name) {
    $i = $catOrder.IndexOf($name)
    if ($i -lt 0) { return 999 }
    return $i
}

$catBlurb = @{
    'Tenancy'             = 'EvA is database-per-tenant AND row-filtered by OrgId. Both are required; neither substitutes for the other. These are the most damaging rules to break.'
    'Security'            = 'Never parameterise SQL by string building, never commit a secret, never add an EF migration.'
    'Async'               = 'Every one of these is an Error. Blocking a thread pool thread under IIS is how EvA APIs deadlock.'
    'Controller'          = 'Controllers are plumbing: bind, guard ModelState, call one Business method, map to Ok/BadRequest. Nothing else.'
    'Response'            = 'Every public Business/Repository method speaks BaseResponse<T>. Codes come from ResponseMessages.resx, never literals.'
    'ErrorHandling'       = 'catch (Exception ex) is fine. Catching it and doing nothing is not.'
    'DataAccess'          = 'Proc names from constants, explicit SqlDbType on every parameter, Fluent config for every DbSet.'
    'DependencyInjection' = 'All registration is manual and Scoped. Forgetting the AddScoped pair is the single most common break.'
    'Naming'              = 'Mostly Warning/Info, but they are what makes a diff look like it belongs in EvA.'
    'Project'             = 'csproj contract, package bumps, branch names, commit messages.'
}

$sb = New-Object System.Text.StringBuilder
function W($t = '') { [void]$sb.AppendLine($t) }

W '# EvA rule reference'
W ''
W '<!-- GENERATED FILE - DO NOT EDIT BY HAND. -->'
W '<!-- Regenerate with sync-rules.ps1. Code examples live in snippets\<RULE-ID>.md. -->'
W ''
W ("Generated from ``eva-standards.json`` v{0}." -f $json.version)
W ''
W ('These are the **{0} enforced rules** the EvA PR review bot runs on every pull request. It analyses **added and modified lines only** — you are never blamed for code you did not touch.' -f $enforced.Count)
W ''
W ('The {0} rules that are deliberately **not** enforced are in [anti-rules.md](anti-rules.md). Read that file before "fixing" anything that looks non-idiomatic.' -f $disabled.Count)
W ''
W '**Severity meaning**'
W ''
W '| Severity | Effect |'
W '|---|---|'
W ('| `Error` | Blocks approval. {0} rules. |' -f ($enforced | Where-Object severity -eq 'Error').Count)
W ('| `Warning` | Expected to be fixed or justified in the PR. {0} rules. |' -f ($enforced | Where-Object severity -eq 'Warning').Count)
W ('| `Info` | Style nudge. {0} rules. |' -f ($enforced | Where-Object severity -eq 'Info').Count)
W ''

# --- index -------------------------------------------------------------
W '## Index'
W ''
W '| Rule | Severity | What it wants |'
W '|---|---|---|'
foreach ($r in $enforced |
        Sort-Object @{ e = { Get-CatRank $_.category } }, @{ e = { $sevRank[$_.severity] } }, id) {
    $anchor = $r.id.ToLower()
    W ('| [`{0}`](#{1}) | {2} | {3} |' -f $r.id, $anchor, $r.severity, $r.name)
}
W ''

# --- body --------------------------------------------------------------
$snippetsUsed = 0
foreach ($cat in ($enforced | Select-Object -ExpandProperty category -Unique |
        Sort-Object @{ e = { Get-CatRank $_ } })) {

    $inCat = $enforced | Where-Object category -eq $cat |
             Sort-Object @{ e = { $sevRank[$_.severity] } }, id

    W ('## {0}' -f $cat)
    W ''
    if ($catBlurb.ContainsKey($cat)) { W ('> {0}' -f $catBlurb[$cat]); W '' }

    foreach ($r in $inCat) {
        W ('### {0} — {1}' -f $r.id, $r.name)
        W ''
        W ('**{0}.** {1}' -f $r.severity, $r.message)
        W ''
        if ($r.rationale) { W ('*Why:* {0}' -f $r.rationale); W '' }

        $snip = Join-Path $SnippetsDir ("{0}.md" -f $r.id)
        if (Test-Path $snip) {
            W ((Get-Content $snip -Raw -Encoding UTF8).TrimEnd())
            W ''
            $snippetsUsed++
        }

        if ($r.appliesTo) {
            W ('<sub>Applies to: {0}</sub>' -f (($r.appliesTo | ForEach-Object { "``$_``" }) -join ', '))
            W ''
        }
    }
}

W '---'
W ''
W 'Rule text and rationale are copied verbatim from `eva-standards.json`. If a rule reads wrong, fix it there — not here — so the bot and the skill stay in step.'

$outDir = Split-Path $OutFile -Parent
if (-not (Test-Path $outDir)) { New-Item -ItemType Directory -Path $outDir -Force | Out-Null }

# UTF8 without BOM: the skill loader reads these as plain markdown.
[System.IO.File]::WriteAllText($OutFile, $sb.ToString(), (New-Object System.Text.UTF8Encoding($false)))

Write-Host "Wrote $OutFile"
Write-Host ("  {0} enforced rules across {1} categories" -f $enforced.Count, ($enforced | Select-Object -ExpandProperty category -Unique).Count)
Write-Host ("  {0} disabled rules skipped (see anti-rules.md)" -f $disabled.Count)
Write-Host ("  {0} hand-written code examples merged from {1}" -f $snippetsUsed, $SnippetsDir)
