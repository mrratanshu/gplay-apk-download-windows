# Setup script for gplay-downloader webapp on Windows
# Installs dependencies and prepares the server

$ErrorActionPreference = "Stop"

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$VenvDir = Join-Path $ScriptDir ".venv"

Write-Host "================================================" -ForegroundColor Cyan
Write-Host "  GPlay APK Downloader - Windows Server Setup" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan
Write-Host ""

# [1/6] Check system dependencies
Write-Host "[1/6] Checking system dependencies..." -ForegroundColor Yellow

# Check Java
$javaCmd = Get-Command java -ErrorAction SilentlyContinue
if (-not $javaCmd -and $env:JAVA_HOME) {
    $javaFromHome = Join-Path $env:JAVA_HOME "bin\java.exe"
    if (Test-Path $javaFromHome) {
        $env:PATH = "$($env:JAVA_HOME)\bin;$($env:PATH)"
        $javaCmd = Get-Command java -ErrorAction SilentlyContinue
    }
}
if (-not $javaCmd) {
    $defaultJdk = Get-ChildItem "C:\Program Files\Java\jdk*" -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($defaultJdk) {
        $env:PATH = "$($defaultJdk.FullName)\bin;$($env:PATH)"
        $javaCmd = Get-Command java -ErrorAction SilentlyContinue
    }
}
if (-not $javaCmd) {
    Write-Host "  - Java: not detected on PATH. Install Java 17+ (e.g. winget install Microsoft.OpenJDK.17)" -ForegroundColor DarkYellow
} else {
    Write-Host "  - Java: found at $($javaCmd.Source)" -ForegroundColor Green
}

# Check apksigner
$apksignerCmd = Get-Command apksigner -ErrorAction SilentlyContinue
if (-not $apksignerCmd) {
    $apksignerCandidate = Get-ChildItem "C:\Android\sdk\build-tools\*\apksigner.bat", "$env:LOCALAPPDATA\Android\Sdk\build-tools\*\apksigner.bat" -ErrorAction SilentlyContinue | Select-Object -Last 1
    if ($apksignerCandidate) {
        $env:PATH = "$($apksignerCandidate.DirectoryName);$($env:PATH)"
        $apksignerCmd = Get-Command apksigner -ErrorAction SilentlyContinue
    }
}
if (-not $apksignerCmd) {
    Write-Host "  - apksigner: not found on PATH (merged APKs will remain unsigned until apksigner is installed)" -ForegroundColor DarkYellow
} else {
    Write-Host "  - apksigner: found at $($apksignerCmd.Source)" -ForegroundColor Green
}

# Check Python
$pythonCmd = Get-Command python -ErrorAction SilentlyContinue
if (-not $pythonCmd) {
    Write-Error "Python 3 is required. Install Python 3.8+ and rerun."
    exit 1
} else {
    $pyVer = & python --version
    Write-Host "  - Python: $pyVer" -ForegroundColor Green
}

# [2/6] Setting up virtual environment
Write-Host ""
Write-Host "[2/6] Setting up Python virtual environment..." -ForegroundColor Yellow
if (-not (Test-Path $VenvDir)) {
    python -m venv $VenvDir
    Write-Host "  Created: $VenvDir" -ForegroundColor Green
} else {
    Write-Host "  Already exists: $VenvDir" -ForegroundColor Green
}

$VenvPy = Join-Path $VenvDir "Scripts\python.exe"
$VenvPip = Join-Path $VenvDir "Scripts\pip.exe"

# [3/6] Installing dependencies
Write-Host ""
Write-Host "[3/6] Installing Python dependencies..." -ForegroundColor Yellow
& $VenvPip install --upgrade pip --quiet
& $VenvPip install -r (Join-Path $ScriptDir "requirements.txt") --quiet
Write-Host "  Python packages installed successfully." -ForegroundColor Green

# [4/6] APKEditor.jar
Write-Host ""
Write-Host "[4/6] Setting up APKEditor..." -ForegroundColor Yellow
$ApkEditorJar = Join-Path $ScriptDir "APKEditor.jar"
if (-not (Test-Path $ApkEditorJar)) {
    Write-Host "  Downloading APKEditor.jar..." -ForegroundColor Cyan
    Invoke-WebRequest -Uri "https://github.com/REAndroid/APKEditor/releases/download/V1.4.1/APKEditor-1.4.1.jar" -OutFile $ApkEditorJar
    Write-Host "  Downloaded APKEditor.jar" -ForegroundColor Green
} else {
    Write-Host "  Already exists: APKEditor.jar" -ForegroundColor Green
}

# [5/6] Debug keystore
Write-Host ""
Write-Host "[5/6] Setting up APK signing keystore..." -ForegroundColor Yellow
$KeystoreDir = Join-Path $env:USERPROFILE ".android"
$KeystoreFile = Join-Path $KeystoreDir "debug.keystore"
if (-not (Test-Path $KeystoreFile)) {
    if (-not (Test-Path $KeystoreDir)) {
        New-Item -ItemType Directory -Path $KeystoreDir -Force | Out-Null
    }
    $keytoolCmd = Get-Command keytool -ErrorAction SilentlyContinue
    if ($keytoolCmd) {
        & keytool -genkey -v -keystore $KeystoreFile -storepass android -alias androiddebugkey -keypass android -keyalg RSA -keysize 2048 -validity 10000 -dname "CN=Android Debug,O=Android,C=US" | Out-Null
        Write-Host "  Created: $KeystoreFile" -ForegroundColor Green
    } else {
        Write-Host "  keytool not found; debug keystore not created yet." -ForegroundColor DarkYellow
    }
} else {
    Write-Host "  Already exists: $KeystoreFile" -ForegroundColor Green
}

# [6/6] Done
Write-Host ""
Write-Host "[6/6] Setup complete!" -ForegroundColor Green
Write-Host "  - To start the web server: .\start-server.ps1 (or start-server.bat)" -ForegroundColor Cyan
Write-Host "  - To use the CLI:          .\gplay.cmd search whatsapp" -ForegroundColor Cyan
