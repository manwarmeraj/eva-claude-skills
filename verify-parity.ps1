<#
.SYNOPSIS
    Regression test for eva-backend-api-skill.

.DESCRIPTION
    Fails (exit 1) if any of the following is true:

      1. An enabled rule in eva-standards.json is missing from references/rules.md.
      2. A disabled rule is missing from references/anti-rules.md.
      3. A disabled rule leaked into references/rules.md.
      4. Any secret-shaped literal appears anywhere in the skill folder.
      5. An out-of-scope repo is referenced as though it were in scope.
      6. A required file is missing, or SKILL.md lost its frontmatter.

    Run after editing eva-standards.json (and re-running sync-rules.ps1), and
    before pushing any change to this repo.

.EXAMPLE
    .\verify-parity.ps1

.NOTES
    Author: Manwar Meraj
#>
[CmdletBinding()]
param(
    [string]$StandardsPath,
    [string]$SkillDir
)

$ErrorActionPreference = 'Stop'
$root = $PSScriptRoot

if (-not $StandardsPath) {
    $StandardsPath = Join-Path (Split-Path $root -Parent) 'eva-code-review-mcp-server\Standards\eva-standards.json'
}
if (-not $SkillDir) { $SkillDir = Join-Path $root 'eva-backend-api-skill' }

$refDir    = Join-Path $SkillDir 'references'
$rulesMd   = Join-Path $refDir 'rules.md'
$antiMd    = Join-Path $refDir 'anti-rules.md'

$failures = New-Object System.Collections.Generic.List[string]
function Fail($m) { $failures.Add($m) }
function Pass($m) { Write-Host "  OK   $m" -ForegroundColor DarkGreen }

Write-Host "Verifying $SkillDir" -ForegroundColor Cyan
Write-Host ""

# --- 6. required files ---------------------------------------------------
Write-Host "Files"
$required = @(
    'SKILL.md',
    'references\rules.md',
    'references\anti-rules.md',
    'references\architecture.md',
    'references\recipe-new-endpoint.md',
    'references\data-access.md',
    'references\known-defects.md',
    'assets\templates\Controller.cs.tmpl',
    'assets\templates\Business.cs.tmpl',
    'assets\templates\IBusiness.cs.tmpl',
    'assets\templates\Repository.cs.tmpl',
    'assets\templates\IRepository.cs.tmpl'
)
foreach ($f in $required) {
    if (Test-Path (Join-Path $SkillDir $f)) { Pass $f } else { Fail "missing file: $f" }
}

$skillMd = Join-Path $SkillDir 'SKILL.md'
if (Test-Path $skillMd) {
    $head = (Get-Content $skillMd -TotalCount 12 -Encoding UTF8) -join "`n"
    if ($head -notmatch '(?m)^---\s*$')            { Fail 'SKILL.md: frontmatter delimiter missing' }
    if ($head -notmatch '(?m)^name:\s*\S')         { Fail 'SKILL.md: frontmatter has no name:' }
    if ($head -notmatch '(?m)^description:')       { Fail 'SKILL.md: frontmatter has no description:' }
    if ($head -match '(?m)^name:\s*eva-backend-api-skill') { Pass 'SKILL.md frontmatter' }
}
Write-Host ""

# --- 1-3. rule parity ----------------------------------------------------
Write-Host "Rule parity"
if (-not (Test-Path $StandardsPath)) {
    Fail "standards file not found: $StandardsPath"
}
else {
    $json     = Get-Content $StandardsPath -Raw -Encoding UTF8 | ConvertFrom-Json
    $enabled  = $json.rules | Where-Object { $_.enabled -ne $false }
    $disabled = $json.rules | Where-Object { $_.enabled -eq $false }

    $rulesText = if (Test-Path $rulesMd) { Get-Content $rulesMd -Raw -Encoding UTF8 } else { '' }
    $antiText  = if (Test-Path $antiMd)  { Get-Content $antiMd  -Raw -Encoding UTF8 } else { '' }

    $missingEnabled = $enabled  | Where-Object { $rulesText -notmatch [regex]::Escape($_.id) }
    $missingAnti    = $disabled | Where-Object { $antiText  -notmatch [regex]::Escape($_.id) }
    $leaked         = $disabled | Where-Object { $rulesText -match "###\s+$([regex]::Escape($_.id))\s" }

    if ($missingEnabled) { Fail ("rules.md missing enabled rule(s): {0}" -f ($missingEnabled.id -join ', ')) }
    else { Pass ("all {0} enabled rules documented in rules.md" -f $enabled.Count) }

    if ($missingAnti) { Fail ("anti-rules.md missing disabled rule(s): {0}" -f ($missingAnti.id -join ', ')) }
    else { Pass ("all {0} disabled rules documented in anti-rules.md" -f $disabled.Count) }

    if ($leaked) { Fail ("disabled rule(s) present as sections in rules.md: {0}" -f ($leaked.id -join ', ')) }
    else { Pass 'no disabled rule leaked into rules.md' }

    $ver = if ($rulesText -match 'eva-standards\.json`?\s*v(\d+(?:\.\d+)*)') { $matches[1] } else { $null }
    if ($ver -and $ver -ne $json.version) {
        Fail "rules.md was generated from v$ver but eva-standards.json is v$($json.version) - re-run sync-rules.ps1"
    }
    elseif ($ver) { Pass "rules.md generated from the current standards version (v$ver)" }
}
Write-Host ""

# --- 4. secret scan ------------------------------------------------------
# The skill teaches EVA-SEC-006. It must not itself contain a secret-shaped
# literal - not even as an illustrative example.
Write-Host "Secret scan"
$secretPatterns = @(
    @{ Name = 'GitHub token';        Pattern = 'gh[pousr]_[A-Za-z0-9]{16,}' },
    @{ Name = 'GitHub PAT (fine)';   Pattern = 'github_pat_[A-Za-z0-9_]{20,}' },
    @{ Name = 'AWS access key';      Pattern = 'AKIA[0-9A-Z]{16}' },
    @{ Name = 'Slack token';         Pattern = 'xox[baprs]-[A-Za-z0-9-]{10,}' },
    @{ Name = 'Private key block';   Pattern = '-----BEGIN [A-Z ]*PRIVATE KEY-----' },
    @{ Name = 'JWT';                 Pattern = 'eyJ[A-Za-z0-9_-]{10,}\.eyJ[A-Za-z0-9_-]{10,}\.' },
    @{ Name = 'SQL password';        Pattern = '(?i)(password|pwd)\s*=\s*[^;"''<\s]{4,}' },
    @{ Name = 'Sonar token';         Pattern = '(?i)sonar[._-]?(login|token)\s*[=:]\s*[A-Za-z0-9]{20,}' },
    @{ Name = 'Generic api key';     Pattern = '(?i)(api[_-]?key|secret|access[_-]?token)\s*[=:]\s*["'']?[A-Za-z0-9/+_-]{20,}' }
)

$skillFiles = Get-ChildItem $SkillDir -Recurse -File
$hits = 0
foreach ($file in $skillFiles) {
    $text = Get-Content $file.FullName -Raw -Encoding UTF8
    foreach ($p in $secretPatterns) {
        foreach ($m in [regex]::Matches($text, $p.Pattern)) {
            # Placeholders are fine: <...>, {{...}}, or the words placeholder/example/redacted.
            if ($m.Value -match '<[^>]*>|\{\{|(?i)placeholder|example|redacted|your[-_ ]') { continue }
            $hits++
            $rel = $file.FullName.Substring($SkillDir.Length + 1)
            # Report the pattern name and location only - never the matched value.
            Fail ("possible {0} in {1}" -f $p.Name, $rel)
        }
    }
}
if ($hits -eq 0) { Pass ("no secret-shaped literal in {0} files" -f $skillFiles.Count) }
Write-Host ""

# --- 5. out-of-scope repos ----------------------------------------------
Write-Host "Scope"
$outOfScope = @('eva-eims-api', 'eva-survey-app', 'eva-sql-manager', 'eva-perf-profiler', 'eva-api-debugger')
# An exclusion note often sits a line or two above the list it introduces, so
# look at a small window rather than the matched line alone.
$exclusionPhrase = '(?i)out of scope|out-of-scope|excluded|exclusion|does not cover|do not follow|does not follow|not in scope|\*\*No\*\*'
foreach ($repo in $outOfScope) {
    $bad = @()
    foreach ($file in $skillFiles) {
        $lines = @(Get-Content $file.FullName -Encoding UTF8)
        for ($i = 0; $i -lt $lines.Count; $i++) {
            if ($lines[$i] -notmatch [regex]::Escape($repo)) { continue }
            $from    = [Math]::Max(0, $i - 3)
            $context = ($lines[$from..$i]) -join ' '
            if ($context -match $exclusionPhrase) { continue }
            $bad += ("{0}:{1}: {2}" -f $file.Name, ($i + 1), $lines[$i].Trim())
        }
    }
    if ($bad) { Fail ("{0} referenced outside an exclusion note ({1} line(s)); first: {2}" -f $repo, $bad.Count, $bad[0]) }
    else { Pass "$repo only appears as excluded" }
}
Write-Host ""

# --- result --------------------------------------------------------------
if ($failures.Count -eq 0) {
    Write-Host "PASS - skill is in parity with eva-standards.json" -ForegroundColor Green
    exit 0
}

Write-Host ("FAIL - {0} problem(s)" -f $failures.Count) -ForegroundColor Red
foreach ($f in $failures) { Write-Host "  - $f" -ForegroundColor Red }
exit 1
