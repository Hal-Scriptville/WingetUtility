# Detection script for Google Chrome (probable install)
# Signals checked: registry uninstall key, App Paths key, chrome.exe on disk
# Intune detection: exit 0 = detected, exit 1 = not detected

$detected = $false
$signals  = @()

try {
    # Signal 1: HKLM uninstall key (machine-wide install)
    $regPaths = @(
        "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\Google Chrome",
        "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\Google Chrome"
    )
    foreach ($rp in $regPaths) {
        if (Test-Path $rp) {
            $signals += "Registry uninstall key: $rp"
            $detected = $true
        }
    }

    # Signal 2: App Paths key (registered in PATH lookup)
    $appPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\chrome.exe"
    if (Test-Path $appPath) {
        $signals += "App Paths key: $appPath"
        $detected = $true
    }

    # Signal 3: chrome.exe on disk (covers both x64 and x86 install dirs)
    $chromePaths = @(
        "$env:ProgramFiles\Google\Chrome\Application\chrome.exe",
        "${env:ProgramFiles(x86)}\Google\Chrome\Application\chrome.exe"
    )
    foreach ($cp in $chromePaths) {
        if (Test-Path $cp) {
            $signals += "Executable on disk: $cp"
            $detected = $true
        }
    }
} catch {
    Write-Host "Detection error: $($_.Exception.Message)"
    exit 1
}

if ($detected) {
    Write-Host "Google Chrome probable install detected. Signals: $($signals -join '; ')"
    exit 0
} else {
    Write-Host "Google Chrome not detected."
    exit 1
}
