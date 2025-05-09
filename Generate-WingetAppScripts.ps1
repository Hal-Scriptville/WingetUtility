# Check for Winget
if (-not (Get-Command "winget.exe" -ErrorAction SilentlyContinue)) {
    Write-Host "Winget is not installed. Please install it first." -ForegroundColor Red
    exit 1
}

# Check for IntuneWinAppUtil.exe
$intuneUtil = Get-Command "IntuneWinAppUtil.exe" -ErrorAction SilentlyContinue
if (-not $intuneUtil) {
    $localPath = Join-Path -Path $PSScriptRoot -ChildPath "IntuneWinAppUtil.exe"
    if (Test-Path $localPath) {
        $intuneUtil = $localPath
    }
}

# Prompt user for search query
$query = Read-Host "Enter search term for winget packages (e.g., chrome, vscode)"
if ([string]::IsNullOrWhiteSpace($query)) {
    Write-Host "Search term is required. Exiting..." -ForegroundColor Red
    exit 1
}

# Perform winget search
$rawResults = winget search "$query" | Select-String -Pattern '^\S+\s+\S+\s+.+$'
$parsedApps = $rawResults | ForEach-Object {
    $line = $_.Line.Trim()
    $parts = $line -split '\s{2,}', 3
    if ($parts.Count -eq 3) {
        [PSCustomObject]@{
            ID    = $parts[0]
            Name  = $parts[1]
            Source = $parts[2]
        }
    }
} | Sort-Object Name | Out-GridView -Title "Select one or more apps to generate scripts for" -PassThru

if (-not $parsedApps) {
    Write-Host "No selections made. Exiting..." -ForegroundColor Yellow
    exit 0
}

# Ask user whether to package into .intunewin
$makeWin = Read-Host "Would you like to create .intunewin packages for each app? (y/n)"
$createIntunewin = $makeWin -match '^[Yy]'

# Output path
$RootOutputDir = "$PSScriptRoot\WingetScripts"
New-Item -ItemType Directory -Path $RootOutputDir -Force | Out-Null

foreach ($app in $parsedApps) {
    $safeName = ($app.Name -replace '[^\w\.-]', '_')
    $packageId = $app.ID
    $AppDir = Join-Path $RootOutputDir $safeName
    New-Item -Path $AppDir -ItemType Directory -Force | Out-Null

    $installPath   = Join-Path $AppDir "Install-$safeName.ps1"
    $uninstallPath = Join-Path $AppDir "Uninstall-$safeName.ps1"
    $detectPath    = Join-Path $AppDir "Detect-$safeName.ps1"

    $installScript = @"
# Install script for $($app.Name)
`$PackageName = "$packageId"
`$LogDir = "`$env:ProgramData\Microsoft\IntuneManagementExtension\Logs"
`$LogFile = Join-Path -Path `$LogDir -ChildPath "`$PackageName-Install.log"

if (-not (Test-Path -Path `$LogDir)) { New-Item -Path `$LogDir -ItemType Directory -Force | Out-Null }
Start-Transcript -Path `$LogFile -Append -Force

function Write-Log { param ([string]`$Message, [string]`$Color = "White")
    `$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Host "[`$timestamp] `$Message" -ForegroundColor `$Color }

if (-not (Get-Command "winget.exe" -ErrorAction SilentlyContinue)) {
    Write-Log "Winget not found. Aborting..." -Color Red
    Stop-Transcript; exit 1 }

try {
    Write-Log "Installing `$PackageName..." -Color Cyan
    `$args = "install `"`$PackageName`" --silent --accept-source-agreements --accept-package-agreements --force"
    `$p = Start-Process -FilePath "winget.exe" -ArgumentList `$args -NoNewWindow -Wait -PassThru
    if (`$p.ExitCode -eq 0) {
        Write-Log "`$PackageName installed successfully." -Color Green
    } else {
        Write-Log "Install failed with exit code `$(`$p.ExitCode)" -Color Red
        Stop-Transcript; exit `$p.ExitCode }
} catch {
    Write-Log "Error: `$(`$_.Exception.Message)" -Color Red
    Stop-Transcript; exit 1 }

Write-Log "Done." -Color Cyan; Stop-Transcript; exit 0
"@

    $uninstallScript = @"
# Uninstall script for $($app.Name)
`$PackageName = "$packageId"
`$LogDir = "`$env:ProgramData\Microsoft\IntuneManagementExtension\Logs"
`$LogFile = Join-Path -Path `$LogDir -ChildPath "`$PackageName-Uninstall.log"

if (-not (Test-Path -Path `$LogDir)) { New-Item -Path `$LogDir -ItemType Directory -Force | Out-Null }
Start-Transcript -Path `$LogFile -Append -Force

function Write-Log { param ([string]`$Message, [string]`$Color = "White")
    `$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Host "[`$timestamp] `$Message" -ForegroundColor `$Color }

if (-not (Get-Command "winget.exe" -ErrorAction SilentlyContinue)) {
    Write-Log "Winget not found. Aborting..." -Color Red
    Stop-Transcript; exit 1 }

try {
    `$installed = & winget list --id `$PackageName --exact --source winget
    if (`$LASTEXITCODE -ne 0 -or `$installed -notmatch `$PackageName) {
        Write-Log "`$PackageName is not installed." -Color Yellow
        Stop-Transcript; exit 0 }
} catch {
    Write-Log "Check failed: `$(`$_.Exception.Message)" -Color Red
    Stop-Transcript; exit 1 }

try {
    Write-Log "Uninstalling `$PackageName..." -Color Cyan
    `$args = "uninstall `"`$PackageName`" --silent --force"
    `$p = Start-Process -FilePath "winget.exe" -ArgumentList `$args -NoNewWindow -Wait -PassThru
    if (`$p.ExitCode -eq 0) {
        Write-Log "Uninstalled successfully." -Color Green
    } else {
        Write-Log "Uninstall failed with exit code `$(`$p.ExitCode)" -Color Red
        Stop-Transcript; exit `$p.ExitCode }
} catch {
    Write-Log "Error: `$(`$_.Exception.Message)" -Color Red
    Stop-Transcript; exit 1 }

Write-Log "Done." -Color Cyan; Stop-Transcript; exit 0
"@

    $detectScript = @"
# Detection script for $($app.Name)
`$PackageName = "$packageId"
function Write-Log { param ([string]`$Message, [string]`$Color = "White")
    `$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Host "[`$timestamp] `$Message" -ForegroundColor `$Color }

if (-not (Get-Command "winget.exe" -ErrorAction SilentlyContinue)) {
    Write-Log "Winget not found." -Color Red; exit 1 }

try {
    `$installed = & winget list --id `$PackageName --exact --source winget
    if (`$LASTEXITCODE -eq 0 -and `$installed -match `$PackageName) {
        Write-Log "`$PackageName is installed." -Color Green; exit 0
    } else {
        Write-Log "`$PackageName NOT installed." -Color Yellow; exit 1 }
} catch {
    Write-Log "Error: `$(`$_.Exception.Message)" -Color Red; exit 1 }
"@

    $installScript   | Out-File -FilePath $installPath   -Encoding UTF8 -Force
    $uninstallScript | Out-File -FilePath $uninstallPath -Encoding UTF8 -Force
    $detectScript    | Out-File -FilePath $detectPath    -Encoding UTF8 -Force

    Write-Host "`nGenerated scripts for $($app.Name):" -ForegroundColor Cyan
    Write-Host "  - Install:    $installPath"
    Write-Host "  - Uninstall:  $uninstallPath"
    Write-Host "  - Detect:     $detectPath"

    # Package into .intunewin
    if ($createIntunewin -and $intuneUtil) {
        $outFile = Join-Path $AppDir "$safeName.intunewin"
        & $intuneUtil -q `
            -c $AppDir `
            -s "Install-$safeName.ps1" `
            -o $AppDir `
            -q
        if (Test-Path $outFile) {
            Write-Host "  - IntuneWin:  $outFile" -ForegroundColor Green
        } else {
            Write-Host "  - IntuneWin packaging failed." -ForegroundColor Red
        }
    }
    elseif ($createIntunewin -and -not $intuneUtil) {
        Write-Host "  - Skipped packaging: IntuneWinAppUtil.exe not found." -ForegroundColor DarkYellow
    }
}

Write-Host "`nAll scripts saved under: $RootOutputDir" -ForegroundColor Green
