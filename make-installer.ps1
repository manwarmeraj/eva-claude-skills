<#
.SYNOPSIS
    Packs eva-backend-api-skill into ONE self-contained file you can email or
    send over Teams. No git, no zip attachment, nothing for the junior to unpack.

.DESCRIPTION
    Produces dist\EvA-Backend-Skill-Installer.md - a plain markdown file that
    carries the whole skill as a base64 payload. Markdown is never blocked by
    Outlook or Teams, unlike .ps1 and .zip.

    The junior either:
      - opens Claude Code and says "install the EvA skill from <path to file>", or
      - pastes the PowerShell block printed inside the file.

    Re-run this after sync-rules.ps1 whenever the standards change, and send the
    new file out.

.EXAMPLE
    .\make-installer.ps1

.NOTES
    Author: Manwar Meraj
#>
[CmdletBinding()]
param(
    [string]$SkillDir,
    [string]$OutFile
)

$ErrorActionPreference = 'Stop'
$root = $PSScriptRoot

if (-not $SkillDir) { $SkillDir = Join-Path $root 'eva-backend-api-skill' }
if (-not $OutFile)  { $OutFile  = Join-Path $root 'dist\EvA-Backend-Skill-Installer.md' }

if (-not (Test-Path (Join-Path $SkillDir 'SKILL.md'))) {
    throw "SKILL.md not found under $SkillDir - refusing to package an incomplete skill."
}

# Refuse to ship a payload that has not passed the parity + secret gate.
$verify = Join-Path $root 'verify-parity.ps1'
if (Test-Path $verify) {
    Write-Host "Running verify-parity.ps1 before packaging..." -ForegroundColor Cyan
    & powershell -NoProfile -ExecutionPolicy Bypass -File $verify -SkillDir $SkillDir | Out-Null
    if ($LASTEXITCODE -ne 0) {
        throw "verify-parity.ps1 failed. Fix it before packaging - do not ship an unverified skill."
    }
    Write-Host "  verify-parity: PASS" -ForegroundColor DarkGreen
}

$outDir = Split-Path $OutFile -Parent
if (-not (Test-Path $outDir)) { New-Item -ItemType Directory -Path $outDir -Force | Out-Null }

# --- zip the skill folder ------------------------------------------------
$tmpZip = Join-Path $env:TEMP ("eva-skill-{0}.zip" -f [guid]::NewGuid().ToString('N'))
Compress-Archive -Path (Join-Path $SkillDir '*') -DestinationPath $tmpZip -CompressionLevel Optimal -Force

$bytes = [System.IO.File]::ReadAllBytes($tmpZip)
Remove-Item $tmpZip -Force

# 76-char lines keep the markdown readable and diff-able.
$b64   = [Convert]::ToBase64String($bytes)
$wrapped = ($b64 -split '(.{76})' | Where-Object { $_ }) -join "`n"

$fileCount = (Get-ChildItem $SkillDir -Recurse -File).Count
$kb        = [Math]::Round($bytes.Length / 1KB)

# --- build the markdown --------------------------------------------------
$sb = New-Object System.Text.StringBuilder
function W($t = '') { [void]$sb.AppendLine($t) }

W '# EvA backend API skill - installer'
W ''
W 'Save this file anywhere (Downloads is fine), then follow **one** of the two options below.'
W 'It installs the EvA backend standards into Claude Code so it writes C# our way from the start.'
W ''
W ('Contains {0} files, {1} KB compressed. Author: Manwar Meraj.' -f $fileCount, $kb)
W ''
W '---'
W ''
W '## Option 1 - let Claude do it (easiest)'
W ''
W 'Open Claude Code in any folder and paste this, with the real path to this file:'
W ''
W '```'
W 'Install the EvA backend skill from C:\Users\<you>\Downloads\EvA-Backend-Skill-Installer.md'
W '- do not read the base64 payload, just run the PowerShell block in that file.'
W '```'
W ''
W '## Option 2 - do it yourself'
W ''
W 'Open **Windows PowerShell**, set the path on the first line, then paste the whole block:'
W ''
W '```powershell'
W '$File = "C:\Users\<you>\Downloads\EvA-Backend-Skill-Installer.md"   # <-- edit this'
W ''
W '$lines  = Get-Content $File'
W "`$start  = (`$lines | Select-String -SimpleMatch 'PAYLOAD-BEGIN' | Select-Object -Last 1).LineNumber"
W "`$end    = (`$lines | Select-String -SimpleMatch 'PAYLOAD-END'   | Select-Object -Last 1).LineNumber"
W '$b64    = ($lines[$start..($end - 2)]) -join ""'
W ''
W '$zip    = Join-Path $env:TEMP "eva-skill.zip"'
W '[IO.File]::WriteAllBytes($zip, [Convert]::FromBase64String($b64))'
W ''
W '$target = Join-Path $env:USERPROFILE ".claude\skills\eva-backend-api-skill"'
W 'if (Test-Path $target) {'
W '    $n = 1; while (Test-Path "$target.bak-$n") { $n++ }'
W '    Move-Item $target "$target.bak-$n"'
W '    Write-Host "Backed up your previous copy to $target.bak-$n"'
W '}'
W 'New-Item -ItemType Directory -Path $target -Force | Out-Null'
W 'Expand-Archive -Path $zip -DestinationPath $target -Force'
W 'Remove-Item $zip -Force'
W ''
W 'Write-Host "Installed to $target" -ForegroundColor Green'
W 'Get-ChildItem $target -Recurse -File | Measure-Object | ForEach-Object { "  $($_.Count) files" }'
W '```'
W ''
W '---'
W ''
W '## Check it worked'
W ''
W 'Start a **new** Claude Code session inside any EvA API repo and type `/skills`.'
W '`eva-backend-api-skill` should be listed.'
W ''
W 'You never invoke it by name - it loads by itself whenever you touch C# in an'
W '`eva-*-api` or `EVA.*.API` repo. Ask it to add an endpoint and it should produce'
W '`Task<IActionResult>`, a `BaseResponse<T>`, the right `api/<module>/...` route, an'
W '`OrgId` filter, and the `AddScoped` pair in `DIConfiguration.cs`.'
W ''
W '## If PowerShell refuses to run'
W ''
W 'Nothing above needs admin rights or an execution-policy change - it is pasted'
W 'commands, not a script file. If your window is locked down anyway, use Option 1'
W 'and let Claude run it.'
W ''
W '## Updating later'
W ''
W 'You will be sent a new copy of this file when the standards change. Run it again -'
W 'it backs up your old copy rather than deleting it.'
W ''
W '---'
W ''
W '<sub>Everything below this line is the packaged skill. Ignore it.</sub>'
W ''
W '<!--EVA-SKILL-PAYLOAD-BEGIN-->'
W $wrapped
W '<!--EVA-SKILL-PAYLOAD-END-->'

[System.IO.File]::WriteAllText($OutFile, $sb.ToString(), (New-Object System.Text.UTF8Encoding($false)))

$outKb = [Math]::Round((Get-Item $OutFile).Length / 1KB)
Write-Host ""
Write-Host "Wrote $OutFile" -ForegroundColor Green
Write-Host ("  {0} skill files, {1} KB on disk - safe to attach to email or Teams" -f $fileCount, $outKb)
