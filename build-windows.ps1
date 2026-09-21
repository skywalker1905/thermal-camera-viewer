#Requires -Version 5.1
<#
.SYNOPSIS
  Bundles the Thermal Camera Viewer App into an Executable on Windows

.DESCRIPTION
  Creates a distributable Windows Executable from the project source. Assumes the project dependencies are already installed in the local .venv created by install-windows.ps1

  The resulting executable is written tot the dist/ directory.

  USB: you must still assign WinUSB to the camera with Zadig (VID 3474).
  See README.md -> Installation -> Windows.
#>


$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $Root

$VenvDir = Join-Path $Root ".venv"
$VenvPython = Join-Path $VenvDir "Scripts\python.exe"
$InstallScript = Join-Path $Root "install-windows.ps1"

if (-not (Test-Path $VenvPython)) {
  Write-Host "Virtual environment not found." -ForegroundColor Red
  Write-Host "Run install-windows.ps1 first." -ForegroundColor Yellow
  exit 1
}

Write-Host "Checking environment..."


$RequiredModules = @(
    "libusb_package",
    "numpy",
    "cv2",
    "usb",
    "PyQt5",
    "PyInstaller"
)

$Missing = @()

foreach ($Module in $RequiredModules) {
    & $VenvPython -c "import $Module" 2>$null
    if ($LASTEXITCODE -ne 0) {
        $Missing += $Module
    }
}

if ($Missing.Count -gt 0) {
    Write-Host ""
    Write-Host "Missing dependencies detected:" -ForegroundColor Red
    $Missing | ForEach-Object { Write-Host "  - $_" }

    Write-Host ""
    Write-Host "install-windows.ps1 should install these packages:" -ForegroundColor Yellow
    Write-Host "  libusb-package, numpy, opencv-python, pyusb, PyQt5 and pyinstaller"
    Write-Host ""
    Write-Host "Try running install-windows.ps1 again"
    exit 1
}

Write-Host "All required dependencies are installed." -ForegroundColor Green

Remove-Item -Recurse -Force -ErrorAction SilentlyContinue .\build, .\dist, .\*.spec

Write-Host ""
Write-Host "Building executable..."
Write-Host ""

& $VenvPython -m PyInstaller --onefile --name thermal-camera-viewer .\thermal_camera_viewer\__main__.py

if ($LASTEXITCODE -ne 0) {
    Write-Host ""
    Write-Host "PyInstaller build failed." -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "=== Setup Reminders: ===" -ForegroundColor Cyan
Write-Host "USB (required once): Zadig -> Options -> List All Devices ->"
Write-Host "  select camera (VID 3474, PID 45A2 or 45C2) -> WinUSB driver."
Write-Host "  See: https://github.com/jvdillon/p3-ir-camera#usb-driver-windows"
Write-Host ""
Write-Host "Optional: add FFmpeg to PATH for MP4 recording (F5)."

Write-Host ""
Write-Host "Build complete." -ForegroundColor Green
Write-Host "Executable is in: $Root\dist"
