param (
    [int]$Port = 5000,
    [switch]$Dev
)

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $ScriptDir

$VenvPy = Join-Path $ScriptDir ".venv\Scripts\python.exe"
$PythonExe = if (Test-Path $VenvPy) { $VenvPy } else { "python" }

function Test-PortOccupied([int]$portToCheck) {
    try {
        $listener = [System.Net.Sockets.TcpListener]::new([System.Net.IPAddress]::Loopback, $portToCheck)
        $listener.Start()
        $listener.Stop()
        return $false
    } catch {
        return $true
    }
}

# Check port availability
$occupied = Test-PortOccupied $Port
if ($occupied) {
    Write-Host "Port $Port is already in use." -ForegroundColor Yellow
    if ([Environment]::UserInteractive) {
        $newPort = Read-Host "Enter an alternate port (or press Enter to cancel)"
        if (-not $newPort) {
            Write-Host "Aborted."
            exit 1
        }
        $Port = [int]$newPort
    } else {
        Write-Error "Port $Port is already in use. Specify a different port with -Port."
        exit 1
    }
}

$env:PORT = "$Port"
$env:PROTOCOL_BUFFERS_PYTHON_IMPLEMENTATION = "python"
if ($Dev) {
    $env:FLASK_DEBUG = "true"
}

Write-Host "Starting GPlay APK Downloader on http://localhost:$Port ..." -ForegroundColor Green
& $PythonExe server.py
