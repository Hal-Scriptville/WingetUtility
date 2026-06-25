# Install script for Google Chrome
$PackageName = "Google.Chrome"
$LogDir  = "$env:ProgramData\Microsoft\IntuneManagementExtension\Logs"
$LogFile = Join-Path -Path $LogDir -ChildPath "$PackageName-Install.log"

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

try {
    Write-Log "Installing $PackageName..." -Color Cyan
    $argList = "install --id `"$PackageName`" --silent --accept-source-agreements --accept-package-agreements --force"
    $p = Start-Process -FilePath "winget.exe" -ArgumentList $argList -NoNewWindow -Wait -PassThru
    if ($p.ExitCode -eq 0) {
        Write-Log "$PackageName installed successfully." -Color Green
    } else {
        Write-Log "Install failed with exit code $($p.ExitCode)" -Color Red
        Stop-Transcript; exit $p.ExitCode
    }
} catch {
    Write-Log "Error: $($_.Exception.Message)" -Color Red
    Stop-Transcript; exit 1
}

Write-Log "Done." -Color Cyan
Stop-Transcript
exit 0
