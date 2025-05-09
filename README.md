# WingetUtility
<h1>README — Winget App Deployment Scripts</h1>
This repository contains PowerShell scripts automatically generated to deploy, uninstall, and detect applications using Winget via Microsoft Intune Win32 app deployments.

Each selected Winget application includes:

  Install-<AppName>.ps1 — Silent install using Winget

  Uninstall-<AppName>.ps1 — Silent uninstall using Winget

  Detect-<AppName>.ps1 — Detection script for Intune

  <AppName>.intunewin (optional) — Pre-packaged for Intune Win32


<h2>Requirements</h2>
Windows 10/11 endpoints with:

  winget.exe available (usually via App Installer)

  Internet access to Winget sources

  IntuneWinAppUtil.exe (used to create .intunewin packages)

  Microsoft Endpoint Manager admin permissions

<h2>Packaging Overview</h2>
Each app folder (e.g. Google_Chrome) includes:


<code>Install-Google_Chrome.ps1     # Installs the app via winget
Uninstall-Google_Chrome.ps1   # Uninstalls the app via winget
Detect-Google_Chrome.ps1      # Detection for Intune assignment
Google_Chrome.intunewin       # Optional: Pre-packaged for Intune
</code>

If .intunewin files were not generated, you can create them manually using:


<code>.\IntuneWinAppUtil.exe -c .\Google_Chrome -s Install-Google_Chrome.ps1 -o .\Google_Chrome
</code>

<h1>How to Deploy in Intune</h1>

Go to Microsoft Intune Admin Center > Apps > Windows apps

Click Add > App type: Win32 app

Select the .intunewin file (e.g., Google_Chrome.intunewin)

Use the following configurations:

<h2>Install command:</h2>


<code>powershell.exe -ExecutionPolicy Bypass -File Install-Google_Chrome.ps1
</code>
  
<h2>Uninstall command:</h2>

<code>powershell.exe -ExecutionPolicy Bypass -File Uninstall-Google_Chrome.ps1
</code>
  
<h2>Detection rule:</h2>
Select Script, then paste contents of Detect-Google_Chrome.ps1

Assign to appropriate device or user groups

<h2>Re-Generating Scripts</h2>
To generate new scripts for additional apps:

<code>.\Generate-WingetAppScripts.ps1</code>

You’ll be prompted to search for packages, select apps via Out-GridView, and choose whether to generate .intunewin files.

<h2>Known Limitations</h2>
Detection relies on winget list—some apps with inconsistent IDs may not register cleanly.

Microsoft Store-hosted apps (MSIX) might not uninstall via Winget --silent.

Ensure winget.exe is present on target devices or deploy it as a dependency.

<h2>License</h2>
This repository is licensed under MIT. You are free to adapt, extend, and use these templates in enterprise or consulting environments.
