# GPlay APK Downloader (Windows Edition)

[![Platform: Windows](https://img.shields.io/badge/Platform-Windows%2010%20%7C%2011-0078D6?logo=windows)](https://www.microsoft.com/windows)
[![Python: 3.8+](https://img.shields.io/badge/Python-3.8%2B-3776AB?logo=python&logoColor=white)](https://www.python.org/)
[![License: GPL-3.0](https://img.shields.io/badge/License-GPL--3.0-blue.svg)](LICENSE)
[![Original Upstream: alltechdev](https://img.shields.io/badge/Upstream-alltechdev%2Fgplay--apk--downloader-orange)](https://github.com/alltechdev/gplay-apk-downloader)

A high-performance Google Play Store APK downloader and split installer designed for **Windows**, Linux, and Docker. Download any free app directly from Google Play, preserve 100% original cryptographic signatures in **APKS** / **XAPK** bundles, merge App Bundles into standalone APKs, or install directly to a connected Android phone using **WebUSB ADB**.

---

## 🌟 Acknowledgements & Original Credits

> [!IMPORTANT]
> **Original Project Credits**: This repository is a Windows-optimized edition and fork of [**alltechdev/gplay-apk-downloader**](https://github.com/alltechdev/gplay-apk-downloader), created and maintained by [**alltechdev**](https://github.com/alltechdev).
> 
> All credit for the core reverse engineering of the Google Play Store Protobuf APIs, device profile collection, checkin logic, and initial downloader architecture belongs to the original author. This edition expands upon the original work by adding complete native Windows support (Waitress WSGI, PowerShell/Batch tooling, automated Chrome/Edge sign-in, thread-safe file locking) and signature-preserving `.apks` and `.xapk` archive generation.

---

## Table of Contents

- [Features](#features)
- [System Requirements & Installation](#system-requirements--installation)
- [Quick Start on Windows](#quick-start-on-windows)
- [Export Formats & Signature Integrity](#export-formats--signature-integrity)
- [Google Account Authentication](#google-account-authentication)
- [Web Interface](#web-interface)
- [Command Line Interface (CLI)](#command-line-interface-cli)
- [WebUSB Direct Device Install](#webusb-direct-device-install)
- [Docker Deployment](#docker-deployment)
- [Troubleshooting for Windows](#troubleshooting-for-windows)
- [License](#license)

---

## Features

- **Native Windows Support**: Full out-of-the-box support for Windows 10 & 11 via PowerShell (`setup.ps1`, `start-server.ps1`, `gplay.ps1`) and Batch (`start-server.bat`, `gplay.cmd`).
- **Signature-Preserving Bundles**:
  - **APKS Bundle (`.apks`)**: For SAI (Split APKs Installer), Shizuku, and Bundletool — **100% original Google Play cryptographic signatures preserved**.
  - **XAPK Bundle (`.xapk`)**: For APKPure, XAPK Installer — **100% original Google Play signatures preserved**.
  - **Single Merged APK (`.apk`)**: Split APKs fused and merged via APKEditor.
  - **Raw Split ZIP (`.zip`)**: Direct archive of base APK and config splits.
- **1-Click Google Sign-In**: Automated sign-in on Windows using Microsoft Edge, Google Chrome, Brave, or Vivaldi via Google's `EmbeddedSetup` flow.
- **WebUSB ADB Direct Install**: Connect your phone via USB and install APKs/splits directly from Google Chrome or Microsoft Edge without downloading files first.
- **Multi-Architecture**: Supports both **ARM64** (modern phones) and **ARMv7** (legacy phones) with 23 realistic device profiles.
- **Production Server for Windows**: Powered by [Waitress](https://docs.pylonsproject.org/projects/waitress/), supporting multithreaded requests and real-time Server-Sent Events (SSE).

---

## System Requirements & Installation

Before running the downloader on Windows, install the following required and optional dependencies.

### Summary Table

| Requirement | Purpose | Necessity | Official Source | Easy Install Command |
| :--- | :--- | :---: | :--- | :--- |
| **Python 3.8+** | Server & CLI backend | **Required** | [python.org](https://www.python.org/downloads/windows/) | `winget install Python.Python.3.12` |
| **Java 17+** | Running APKEditor | **Required for Merged APKs** | [Adoptium Temurin 17](https://adoptium.net/temurin/releases/?version=17) | `winget install EclipseAdoptium.Temurin.17.JRE` |
| **Edge or Chrome** | 1-Click Google Sign-in | **Optional** (Built-in) | Preinstalled on Windows | Preinstalled (Edge) |
| **apksigner** | Re-signing merged APKs | **Optional** (Not needed for APKS/XAPK) | [Android Command-Line Tools](https://developer.android.com/studio#command-line-tools-only) | See [apksigner options](#3-apksigner-optional--only-for-merged-apks) below |
| **Git for Windows** | Cloning the repo | **Optional** (Can download ZIP) | [git-scm.com](https://git-scm.com/download/win) | `winget install Git.Git` |

---

### Step-by-Step Requirements Installation

#### 1. Python 3.8+ (Required)
Install Python 3.10, 3.11, or 3.12 from the official website or via Windows Package Manager:
```powershell
winget install Python.Python.3.12
```
> [!IMPORTANT]
> If using the manual `.exe` installer from [python.org](https://www.python.org/downloads/windows/), be sure to check the box:  
> **☑ Add python.exe to PATH** at the bottom of the first setup screen!

#### 2. Java 17+ (Required for Merging Splits into Single APKs)
Java 17 or higher is required to run `APKEditor.jar` when merging split APKs into a single `.apk`. You can install Eclipse Temurin (Adoptium) or Microsoft OpenJDK:
```powershell
# Using Winget (Eclipse Temurin JRE 17):
winget install EclipseAdoptium.Temurin.17.JRE

# Or Microsoft OpenJDK 17:
winget install Microsoft.OpenJDK.17
```
- **Official Manual Download**: [Eclipse Adoptium Temurin 17](https://adoptium.net/temurin/releases/?version=17)

#### 3. apksigner (Optional — Only Needed if Merging Splits into a Single `.apk`)

> [!NOTE]
> **Full Android Studio is NOT required!**
> 
> - If you download **APKS Bundles** (for SAI/Shizuku) or **XAPK Bundles** (for APKPure) or use **WebUSB direct install**, you **do not need apksigner at all** because original Google Play signatures are preserved untouched.
> - `apksigner` is only used if you choose to merge split APKs into a single combined `.apk` that needs re-signing.

If you want to merge and re-sign APKs, you can get `apksigner` without Android Studio:
- **Option A (Lightweight Android Command-Line Tools ~130MB)**:  
  Download `commandlinetools-win-*_latest.zip` from [Android Studio Downloads (Scroll to Command Line Tools Only)](https://developer.android.com/studio#command-line-tools-only), extract it, and install build-tools:
  ```powershell
  cmdline-tools\bin\sdkmanager.bat "build-tools;34.0.0"
  ```
- **Option B (If you already have Android Studio installed)**:  
  `apksigner.bat` is already on your PC at `%LOCALAPPDATA%\Android\Sdk\build-tools\<version>\`. Just ensure that folder is added to your system `PATH`.
- **Option C (Package Managers)**:
  ```powershell
  # Chocolatey
  choco install uber-apk-signer
  # or Scoop
  scoop install uber-apk-signer
  ```

#### 4. Chromium-Based Web Browser (For 1-Click Login)
Google Account login uses a local Chromium browser window:
- **Microsoft Edge** (preinstalled on Windows 10 & 11) works out-of-the-box — no install needed!
- Alternatively, Google Chrome, Brave, or Vivaldi are automatically detected if installed.

#### 5. Git for Windows (Optional)
Git is **not required** to run the downloader. You only need Git if you want to clone and update via `git clone` or push commits to GitHub:
```powershell
winget install Git.Git
```
Otherwise, you can simply click **Code → Download ZIP** on GitHub and extract the folder anywhere on your PC.

---

## Quick Start on Windows

### 1. Clone or Download the Repository

Using Git:
```powershell
git clone --depth 1 https://github.com/mrratanshu/gplay-apk-download-windows.git
cd gplay-apk-download-windows
```
*(Or download and extract the ZIP file from GitHub into a folder).*

### 2. Run the Windows Setup Script

Open **PowerShell** in the project folder and run:
```powershell
.\setup.ps1
```

> [!NOTE]
> If PowerShell shows an `Execution_Policies` restriction error, run:
> ```powershell
> powershell.exe -ExecutionPolicy Bypass -File .\setup.ps1
> ```

The automated setup script will:
1. Verify Java, Python, and apksigner availability.
2. Create an isolated Python virtual environment in `.venv\`.
3. Install all required Python libraries (Waitress, Flask, Cryptography, Protobuf, Requests).
4. Download `APKEditor.jar` (if not already present).
5. Generate an Android debug keystore (`%USERPROFILE%\.android\debug.keystore`).

### 3. Start the Web Server

Run either:
```powershell
.\start-server.ps1
```
Or double-click:
```cmd
start-server.bat
```

The server will launch on **[http://localhost:5000](http://localhost:5000)**.

To run on a different port:
```powershell
.\start-server.ps1 -Port 8080
```

---

## Export Formats & Signature Integrity

Modern apps on the Google Play Store are delivered as **Android App Bundles (AAB)** and split into multiple component APKs (`base.apk`, `split_config.arm64_v8a.apk`, `split_config.xxhdpi.apk`, language packs, etc.).

This downloader gives you complete control over how bundles are packaged:

| Format | File Extension | Google Play Signature | Best For / Compatibility |
| :--- | :--- | :---: | :--- |
| **APKS Bundle** | `.apks` | **100% Original (Untouched)** | **SAI (Split APKs Installer)**, **Shizuku**, **Bundletool**.<br>Safest for banking apps, WhatsApp, and Google Play Integrity. |
| **XAPK Bundle** | `.xapk` | **100% Original (Untouched)** | **APKPure App**, **XAPK Installer**.<br>Standard format with internal `manifest.json`. |
| **Merged APK** | `.apk` | Re-signed (Debug Key) | Direct sideloading without any third-party installer app.<br>*(Not recommended for banking/Meta/Google apps)*. |
| **Split ZIP** | `.zip` | **100% Original (Untouched)** | Manual extraction or custom deployment scripts. |

### Why Signature Preservation Matters
> [!WARNING]
> When split APKs are merged into a single standalone `.apk`, the original cryptographic signature from Google is broken and the APK is re-signed with a debug key.
> 
> Apps with strict security checks (e.g. **Banking apps, WhatsApp, Uber, Snapchat, Google Play Integrity / SafetyNet**) will detect that the signature has changed and may block access or restrict accounts.
> 
> **For banking and security-sensitive apps, always choose `APKS Bundle` or `XAPK Bundle`, or use WebUSB ADB direct install.**

---

## Google Account Authentication

Google Play requires authentication to download apps. You can authenticate using a personal (burner) Google account or an anonymous token dispenser.

### Recommended: Google Account Login (Burner Account)

> [!CAUTION]
> Always use a **throwaway/burner Google account**, not your primary personal account, as automated third-party Play Store access violates Google's Terms of Service.

#### From the Web UI:
1. Open [http://localhost:5000](http://localhost:5000).
2. Click **Sign in with Google**.
3. A browser window (Chrome or Edge) will open to Google's official Android setup page (`accounts.google.com/EmbeddedSetup`).
4. Enter your burner account credentials.
5. The window will close automatically, capturing your authorization token and registering virtual ARM64 and ARMv7 device profiles.

#### Manual Token Fallback:
If browser automation is disabled or running headless:
1. In the Web UI, expand the **Manual Token Input** section under the sign-in card.
2. Click the link to open Google's `EmbeddedSetup` page.
3. Inspect Network / Cookies to copy the `oauth_token` cookie (starts with `oauth2_4/`).
4. Paste it into the form with your email and submit.

#### From the CLI:
```powershell
.\gplay.ps1 auth-account --browser
```

Tokens are cached locally in `%USERPROFILE%\.gplay-auth.json` and `%USERPROFILE%\.gplay-auth-armv7.json` and refreshed automatically.

---

## Web Interface

Navigate to `http://localhost:5000` in your browser.

1. **Search**: Enter an app name (e.g., `Spotify`, `VLC`) or a package ID (e.g., `com.spotify.music`).
2. **Architecture**:
   - `ARM64` (default): For all modern Android devices.
   - `ARMv7`: For older 32-bit devices or Android TV.
3. **Format**: Select between `APKS Bundle`, `XAPK Bundle`, `Merged APK`, or `Split ZIP`.
4. **Download**: Click **Download** to stream real-time progress and receive your file.
5. **Activity Log**: The live terminal panel shows token acquisition, split downloading, and packaging details in real time.

---

## Command Line Interface (CLI)

Use `.\gplay.ps1` (PowerShell) or `.\gplay.cmd` (Command Prompt) to run CLI commands directly without manually activating the virtual environment.

### 1. Search for Apps
```powershell
.\gplay.ps1 search "firefox"
.\gplay.ps1 search "vlc" --limit 5
.\gplay.ps1 search "whatsapp" --json
```

### 2. View App Details & Version
```powershell
.\gplay.ps1 info com.spotify.music
.\gplay.ps1 check-version com.spotify.music
```

### 3. Download Apps
```powershell
# Download APKS bundle (original signatures preserved)
.\gplay.ps1 download com.spotify.music -f apks

# Download XAPK bundle (original signatures preserved)
.\gplay.ps1 download com.spotify.music -f xapk

# Download and merge into a single APK (re-signed with debug key)
.\gplay.ps1 download com.spotify.music -f merged

# Download for ARMv7 devices
.\gplay.ps1 download com.spotify.music -a armv7 -f apks

# Download and install directly to connected phone via ADB
.\gplay.ps1 download com.spotify.music -i
```

### 4. Backup & Restore Installed Apps
Export a list of all apps currently installed on your connected Android phone and restore them anytime:
```powershell
# Backup installed apps to a JSON file
.\gplay.ps1 backup -o my-apps.json

# Download and reinstall all apps from backup
.\gplay.ps1 restore my-apps.json -i
```

---

## WebUSB Direct Device Install

You can install split APKs directly from your browser to your Android phone without downloading files or installing ADB on Windows:

1. Enable **Developer Options** on your Android device:
   - Go to *Settings* → *About Phone* → tap *Build Number* 7 times.
2. Enable **USB Debugging**:
   - Go to *Settings* → *Developer Options* → toggle on **USB Debugging**.
3. Connect your phone to your Windows PC via USB cable.
4. In Google Chrome or Microsoft Edge, open `http://localhost:5000`.
5. Click **Connect Device** in the web interface and select your device in the browser prompt.
6. Check your phone screen and tap **Allow USB Debugging**.
7. When you download an app, click **Install to Device**. Splits will be pushed directly using Android's native package manager session install with original signatures intact!

---

## Docker Deployment

If you prefer running inside a Docker container on Windows via Docker Desktop:

```powershell
docker compose up -d
```
The container includes Python 3.11, OpenJDK 17, and APKEditor pre-installed. The server will be accessible at `http://localhost:5000`.

---

## Troubleshooting for Windows

### 1. `setup.ps1 : File cannot be loaded because running scripts is disabled on this system`
Windows PowerShell restricts script execution by default. To allow running local scripts:
```powershell
Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned
```
Or execute the script bypassing policy for that single session:
```powershell
powershell.exe -ExecutionPolicy Bypass -File .\setup.ps1
```

### 2. `Python was not found; run without arguments to install from the Microsoft Store...`
Python is either not installed or not added to your system PATH.
- Open Windows Settings → *Installed apps* → *Python* → *Modify* → check **Add Python to environment variables**.
- Or reinstall via Winget: `winget install Python.Python.3.12`.

### 3. `Java not found` or `java is not recognized as an internal or external command`
APKEditor requires Java 17+.
- Install Temurin 17: `winget install EclipseAdoptium.Temurin.17.JRE`.
- Close and reopen your terminal window so the updated PATH takes effect.

### 4. `Port 5000 is already in use`
Another application is using port 5000. Start the server on another port:
```powershell
.\start-server.ps1 -Port 8080
```

### 5. `DevTools endpoint never came up` or Browser Sign-In doesn't open
This occurs if orphaned background Chrome processes hold locks on the login profile.
- Close any open Chrome or Edge processes.
- Delete the temporary profile directory if needed:
  ```powershell
  Remove-Item -Recurse -Force "$env:USERPROFILE\.gplay-login-profile"
  ```
- Alternatively, use the **Manual Token Input** option in the web UI.

---

## Project Structure

```
gplay-apk-downloader/
├── server.py              # Flask + Waitress WSGI application with SSE endpoints
├── gplay-downloader.py    # Core CLI download engine
├── bundle_builder.py      # APKS, XAPK, and ZIP archive packaging engine
├── account_auth.py        # Windows interactive Google account sign-in
├── device_profiles.py     # Android device profile management (23 profiles)
├── profiles/              # Aurora Store hardware profiles (.properties)
├── public/                # Web UI frontend (HTML, CSS, JS, WebUSB ADB)
│   ├── index.html         # Modern web interface with format selector
│   ├── app.js             # Frontend controller & SSE event listeners
│   └── adb.js             # WebUSB ADB protocol implementation
├── setup.ps1              # Windows automated setup script
├── start-server.ps1       # Windows server launcher (Waitress)
├── start-server.bat       # Windows batch file server launcher
├── gplay.ps1              # Windows CLI launcher for PowerShell
├── gplay.cmd              # Windows CLI launcher for CMD
├── requirements.txt       # Python dependencies
├── Dockerfile             # Multi-stage Docker container specification
├── docker-compose.yml     # Docker Compose configuration
└── LICENSE                # GNU General Public License v3.0
```

---

## License & Credits

- **Original Project**: [alltechdev/gplay-apk-downloader](https://github.com/alltechdev/gplay-apk-downloader) by [alltechdev](https://github.com/alltechdev).
- **License**: [GNU General Public License v3.0 (GPLv3)](LICENSE).
- **Third-Party Components**:
  - [APKEditor](https://github.com/REAndroid/APKEditor) by REAndroid (Apache 2.0).
  - Device profiles sourced from [Aurora Store](https://gitlab.com/AuroraOSS/AuroraStore).
