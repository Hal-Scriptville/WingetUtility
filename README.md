# WingetUtility

PowerShell scripts for deploying, uninstalling, and detecting applications via Winget in Microsoft Intune (Win32 app deployments).

---

## What's Included

| File | Purpose |
|------|---------|
| `Generate-WingetAppScripts.ps1` | Interactive script that searches Winget and generates install/uninstall/detect scripts for any app |
| `WingetScripts/` | Pre-built, ready-to-upload script sets for common applications |

---

## Pre-Built Scripts

Ready-to-use script sets are available in the `WingetScripts/` folder. Each app folder includes an install script, uninstall script, detection script, and Intune setup README.

| App | Folder | Winget ID |
|-----|--------|-----------|
| Google Chrome | [`WingetScripts/Google_Chrome/`](WingetScripts/Google_Chrome/) | `Google.Chrome` |

See the app's `README.md` for step-by-step Intune deployment instructions.

---

## Generate Scripts for Any App

To generate scripts for additional apps interactively:

```powershell
.\Generate-WingetAppScripts.ps1
```

You'll be prompted to search for packages, select apps via Out-GridView, and optionally package them as `.intunewin` files. Output lands in `WingetScripts\<AppName>\`.

---

## Requirements

- Windows 10/11 endpoints with `winget.exe` available (via App Installer)
- Internet access to Winget sources
- [IntuneWinAppUtil.exe](https://github.com/microsoft/Microsoft-Win32-Content-Prep-Tool/releases) to create `.intunewin` packages
- Microsoft Intune admin permissions

---

## Deploying a Script Set in Intune

### 1. Package

```cmd
IntuneWinAppUtil.exe -c ".\WingetScripts\<AppName>" -s "Install-<AppName>.ps1" -o ".\WingetScripts\<AppName>"
```

### 2. Create Win32 App

1. **Intune admin center** → **Apps** → **All apps** → **+ Add** → **Windows app (Win32)**
2. Upload the `.intunewin` file

### 3. Program settings

| Field | Value |
|-------|-------|
| Install command | `powershell.exe -ExecutionPolicy Bypass -File Install-<AppName>.ps1` |
| Uninstall command | `powershell.exe -ExecutionPolicy Bypass -File Uninstall-<AppName>.ps1` |
| Install behavior | **System** |

### 4. Detection rule

- Rule format: **Use a custom detection script**
- Upload `Detect-<AppName>.ps1`
- Run as 32-bit: **No** | Enforce signature check: **No**

### 5. Assign

Assign to device or user groups with the appropriate intent (Required / Available / Uninstall).

---

## Known Limitations

- Winget detection (`winget list`) can be inconsistent for some package IDs. Pre-built detection scripts use registry and file-path signals instead.
- Microsoft Store-sourced MSIX packages may not uninstall cleanly with `--silent`.
- Ensure `winget.exe` is present on target devices, or deploy App Installer as a dependency first.

---

## License

MIT — free to adapt, extend, and use in enterprise or consulting environments.
