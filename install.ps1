<#
.SYNOPSIS
    Installs eva-backend-api-skill into the current user's Claude Code skills folder.

.DESCRIPTION
    Copies eva-backend-api-skill\ to $env:USERPROFILE\.claude\skills\eva-backend-api-skill.
    Any existing copy is moved aside to eva-backend-api-skill.bak-<n> rather than deleted.

    Run this once on day one, and again whenever you pull an update to this repo.

.EXAMPLE
    .\install.ps1
    .\install.ps1 -Force            # overwrite without keeping a backup
    .\install.ps1 -WhatIf           # show what would happen

.NOTES
    Author: Manwar Meraj
#>
[CmdletBinding(SupportsShouldProcess)]
param(
    [switch]$Force
)

$ErrorActionPreference = 'Stop'
$root = $PSScriptRoot

$SkillName = 'eva-backend-api-skill'
$source    = Join-Path $root $SkillName
$skillsDir = Join-Path $env:USERPROFILE '.claude\skills'
$target    = Join-Path $skillsDir $SkillName

if (-not (Test-Path $source)) {
    throw "Source skill folder not found: $source"
}
if (-not (Test-Path (Join-Path $source 'SKILL.md'))) {
    throw "SKILL.md missing from $source - refusing to install an incomplete skill."
}

if (-not (Test-Path $skillsDir)) {
    if ($PSCmdlet.ShouldProcess($skillsDir, 'Create skills directory')) {
        New-Item -ItemType Directory -Path $skillsDir -Force | Out-Null
        Write-Host "Created $skillsDir"
    }
}

if (Test-Path $target) {
    if ($Force) {
        if ($PSCmdlet.ShouldProcess($target, 'Remove existing installation')) {
            Remove-Item $target -Recurse -Force
            Write-Host "Removed existing $target"
        }
    }
    else {
        $n = 1
        while (Test-Path "$target.bak-$n") { $n++ }
        $backup = "$target.bak-$n"
        if ($PSCmdlet.ShouldProcess($target, "Back up to $backup")) {
            Move-Item $target $backup
            Write-Host "Backed up existing install to $backup"
        }
    }
}

if ($PSCmdlet.ShouldProcess($target, "Copy skill from $source")) {
    Copy-Item $source $target -Recurse -Force

    $files = Get-ChildItem $target -Recurse -File
    Write-Host ""
    Write-Host "Installed $SkillName -> $target" -ForegroundColor Green
    Write-Host ("  {0} files, {1:N0} KB" -f $files.Count, (($files | Measure-Object Length -Sum).Sum / 1KB))
    Write-Host ""
    Write-Host "Start a new Claude Code session in any EvA API repo. The skill loads automatically -"
    Write-Host "you do not need to invoke it. Verify with /skills or by asking Claude to add an endpoint."
}
