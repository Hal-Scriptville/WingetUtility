# Google Chrome — Intune Deployment via Winget

Deploys Google Chrome silently using Winget as a Win32 app in Microsoft Intune.

## Files

| File | Purpose |
|------|---------|
| `Install-Google_Chrome.ps1` | Installs Chrome via `winget install` |
| `Uninstall-Google_Chrome.ps1` | Removes Chrome via `winget uninstall` |
| `Detect-Google_Chrome.ps1` | Detection script — checks registry keys and `chrome.exe` on disk |

---

## Prerequisites

- **Winget** must be available on target endpoints (Windows 10 1809+ / Windows 11 with App Installer)
- Devices must be **Intune-enrolled**
- **IntuneWinAppUtil.exe** — [download from Microsoft](https://github.com/microsoft/Microsoft-Win32-Content-Prep-Tool/releases)

---

## Step 1 — Package the Scripts

1. Download or clone this folder to your local machine.
2. Open a command prompt and run:

```cmd
IntuneWinAppUtil.exe -c "C:\path\to\Google_Chrome" -s "Install-Google_Chrome.ps1" -o "C:\path\to\output"
```

This produces `Install-Google_Chrome.intunewin` in your output folder.

---

## Step 2 — Create the Win32 App in Intune

1. Go to **Intune admin center** → **Apps** → **All apps** → **+ Add**
2. Select **App type: Windows app (Win32)** → **Select**

### App information
| Field | Value |
|-------|-------|
| Name | Google Chrome |
| Description | Deploys Google Chrome via Winget |
| Publisher | Google LLC |

Upload the `.intunewin` file when prompted.

---

## Step 3 — Program Settings

| Field | Value |
|-------|-------|
| Install command | `powershell.exe -ExecutionPolicy Bypass -File Install-Google_Chrome.ps1` |
| Uninstall command | `powershell.exe -ExecutionPolicy Bypass -File Uninstall-Google_Chrome.ps1` |
| Install behavior | **System** |
| Device restart behavior | **No specific action** |

---

## Step 4 — Requirements

| Field | Recommended value |
|-------|-------------------|
| Operating system architecture | 64-bit (or Both) |
| Minimum OS | Windows 10 21H2 or later |

---

## Step 5 — Detection Rule

1. Under **Detection rules**, select **Rule format: Use a custom detection script**
2. Upload `Detect-Google_Chrome.ps1`
3. Set **Run script as 32-bit process on 64-bit clients** → **No**
4. Set **Enforce script signature check** → **No**

The detection script checks three independent signals:
- `HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\Google Chrome`
- `HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\chrome.exe`
- `C:\Program Files\Google\Chrome\Application\chrome.exe`

Exit 0 = detected. Exit 1 = not detected.

---

## Step 6 — Assignments

Assign to the appropriate **device** or **user** group and set the intent:

| Intent | Use case |
|--------|----------|
| Required | Mandatory deployment |
| Available | Self-service via Company Portal |
| Uninstall | Forced removal |

---

## Logs

Install and uninstall logs are written to:

```
C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\Google.Chrome-Install.log
C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\Google.Chrome-Uninstall.log
```

You can also review the Intune Management Extension log at:

```
C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\IntuneManagementExtension.log
```

---

## Notes

- Winget exit code `0` = success. Non-zero exits are passed directly back to Intune.
- The uninstall script exits `0` cleanly if Chrome is not present (idempotent).
- Chrome's machine-wide installer writes to `Program Files` regardless of user context — **System** install behavior is correct.
