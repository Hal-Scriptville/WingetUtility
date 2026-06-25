# Uninstall script for Google Chrome
$PackageName = "Google.Chrome"
$LogDir  = "$env:ProgramData\Microsoft\IntuneManagementExtension\Logs"
$LogFile = Join-Path -Path $LogDir -ChildPath "$PackageName-Uninstall.log"

if (-not (Test-Path -Path $LogDir)) { New-Item -Path $LogDir -ItemType Directory -Force | Out-Null }
Start-Transcript -Path $LogFile -Append -Force

function Write-Log {
    param ([string]$Message, [string]$Color = "White")
    $ts = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Host "[$ts] $Message" -ForegroundColor $Color
}

if (-not (Get-Command "winget.exe" -ErrorAction SilentlyContinue)) {
    Write-Log "Winget not found. Aborting..." -Color Red
    Stop-Transcript; exit 1
}

# Pre-flight: confirm installed before attempting removal
try {
    $check = & winget list --id $PackageName --exact --source winget 2>&1
    if ($LASTEXITCODE -ne 0 -or ($check -notmatch [regex]::Escape($PackageName))) {
        Write-Log "$PackageName does not appear to be installed. Nothing to do." -Color Yellow
        Stop-Transcript; exit 0
    }
} catch {
    Write-Log "Pre-flight check failed: $($_.Exception.Message)" -Color Red
    Stop-Transcript; exit 1
}

try {
    Write-Log "Uninstalling $PackageName..." -Color Cyan
    $argList = "uninstall --id `"$PackageName`" --silent --force"
    $p = Start-Process -FilePath "winget.exe" -ArgumentList $argList -NoNewWindow -Wait -PassThru
    if ($p.ExitCode -eq 0) {
        Write-Log "Uninstalled successfully." -Color Green
    } else {
        Write-Log "Uninstall failed with exit code $($p.ExitCode)" -Color Red
        Stop-Transcript; exit $p.ExitCode
    }
} catch {
    Write-Log "Error: $($_.Exception.Message)" -Color Red
    Stop-Transcript; exit 1
}

Write-Log "Done." -Color Cyan
Stop-Transcript
exit 0
