<#
.SYNOPSIS
    Writes .claude\settings.json into every EvA repo so the skill installs itself
    for anyone who clones that repo. No per-developer commands.

.DESCRIPTION
    Claude Code reads extraKnownMarketplaces + enabledPlugins from a repository's
    .claude\settings.json. Committing that file means a developer who clones the
    repo gets the marketplace and the plugin automatically - they only accept the
    normal workspace trust dialog.

    This script only WRITES the files. It never stages, commits or pushes - the
    repos here sit on feature branches with dirty working trees, so review and
    commit them yourself.

.EXAMPLE
    .\rollout-to-repos.ps1 -WhatIf      # show what would change
    .\rollout-to-repos.ps1              # write the files
    .\rollout-to-repos.ps1 -Root D:\1_EvaDev

.NOTES
    Author: Manwar Meraj
#>
[CmdletBinding(SupportsShouldProcess)]
param(
    [string]$Root = 'D:\1_EvaDev',
    [string]$MarketplaceName = 'eva',
    [string]$Repo = 'manwarmeraj/eva-claude-skills',
    [string]$Plugin = 'eva-backend-api'
)

$ErrorActionPreference = 'Stop'

# Repos this skill does not cover - see eva-backend-api-skill/SKILL.md.
$outOfScope = @(
    'eva-eims-api', 'eva-survey-app', 'eva-sql-manager', 'eva-perf-profiler',
    'eva-api-debugger', 'EvaApiDebugger', 'eva-api-gateway', 'eva-claude-skills',
    'eva-code-review-mcp-server', 'eva-sql-launcher', 'eva-database-sql',
    'eva-tenant-sql', 'DevDBProject'
)

$desired = [ordered]@{
    extraKnownMarketplaces = [ordered]@{
        $MarketplaceName = [ordered]@{
            source = [ordered]@{ source = 'github'; repo = $Repo }
        }
    }
    enabledPlugins = [ordered]@{
        "$Plugin@$MarketplaceName" = $true
    }
}

# A repo is in scope if it has both a *.Business project and a data-access project.
# Data access is usually *.Repositories / *.Repository, but eva-reports-api calls
# its layer EVA.DAL - same template, different name.
function Test-EvaService([string]$path) {
    $dirs = Get-ChildItem $path -Directory -ErrorAction SilentlyContinue
    $hasBusiness = $dirs | Where-Object { $_.Name -match '\.Business$' }
    $hasData     = $dirs | Where-Object { $_.Name -match '\.(Repositor(y|ies)|DAL)$' }
    return ($hasBusiness -and $hasData)
}

# PowerShell 5.1's ConvertTo-Json right-aligns values into an unreadable mess,
# and these files get committed and read by people. Re-indent to plain 2-space
# JSON, but only if the result still parses - never risk mangling a repo's
# existing settings.
function Format-Json([string]$json) {
    $indent = 0
    $out = ($json -split "`r?`n" | ForEach-Object {
        $line = $_.Trim()
        if ($line -match '^[}\]]') { $indent = [Math]::Max(0, $indent - 1) }
        # 5.1 also pads after the colon: "key":  value -> "key": value
        $line = $line -replace '^("(?:[^"\\]|\\.)*")\s*:\s+', '$1: '
        $rendered = (' ' * 2 * $indent) + $line
        if ($line -match '[{\[]\s*$') { $indent++ }
        $rendered
    }) -join "`n"

    try { $null = $out | ConvertFrom-Json; return $out }
    catch { return $json }
}

$written = 0; $skipped = 0; $unchanged = 0

foreach ($dir in Get-ChildItem $Root -Directory | Sort-Object Name) {

    if ($outOfScope -contains $dir.Name) {
        Write-Host ("  skip  {0}  (out of scope)" -f $dir.Name) -ForegroundColor DarkGray
        $skipped++; continue
    }
    if (-not (Test-Path (Join-Path $dir.FullName '.git'))) {
        $skipped++; continue
    }
    if (-not (Test-EvaService $dir.FullName)) {
        Write-Host ("  skip  {0}  (not an EvA service)" -f $dir.Name) -ForegroundColor DarkGray
        $skipped++; continue
    }

    $claudeDir = Join-Path $dir.FullName '.claude'
    $settings  = Join-Path $claudeDir 'settings.json'

    # .claude\ must not be gitignored, or the file will never reach anyone else.
    $ignored = & git -C $dir.FullName check-ignore '.claude/settings.json' 2>$null
    if ($LASTEXITCODE -eq 0 -and $ignored) {
        Write-Warning ("{0}: .claude/settings.json is gitignored - the rollout would not be shared. Fix .gitignore first." -f $dir.Name)
        $skipped++; continue
    }

    # Merge, never clobber: a repo may already have permissions or env in here.
    $merged = $desired
    if (Test-Path $settings) {
        try {
            $existing = Get-Content $settings -Raw -Encoding UTF8 | ConvertFrom-Json
        }
        catch {
            Write-Warning ("{0}: .claude\settings.json is not valid JSON - skipping." -f $dir.Name)
            $skipped++; continue
        }

        $merged = [ordered]@{}
        foreach ($p in $existing.PSObject.Properties) { $merged[$p.Name] = $p.Value }
        $merged['extraKnownMarketplaces'] = $desired.extraKnownMarketplaces
        $merged['enabledPlugins']         = $desired.enabledPlugins
    }

    $json = Format-Json ($merged | ConvertTo-Json -Depth 10)

    if ((Test-Path $settings) -and ((Get-Content $settings -Raw -Encoding UTF8).Trim() -eq $json.Trim())) {
        Write-Host ("  same  {0}" -f $dir.Name) -ForegroundColor DarkGray
        $unchanged++; continue
    }

    if ($PSCmdlet.ShouldProcess($settings, 'Write Claude plugin settings')) {
        if (-not (Test-Path $claudeDir)) { New-Item -ItemType Directory -Path $claudeDir -Force | Out-Null }
        # UTF8 without BOM - a BOM breaks the settings parser.
        [System.IO.File]::WriteAllText($settings, $json, (New-Object System.Text.UTF8Encoding($false)))
        Write-Host ("  write {0}" -f $dir.Name) -ForegroundColor Green
        $written++
    }
}

Write-Host ""
Write-Host ("{0} written, {1} already current, {2} skipped" -f $written, $unchanged, $skipped)
Write-Host ""
Write-Host "Nothing was staged or committed. Review each repo, then commit:" -ForegroundColor Yellow
Write-Host '    git add .claude/settings.json'
Write-Host '    git commit -m "Add EvA backend skill for Claude Code"'
