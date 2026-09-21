#Requires -Version 5.1
<#
.SYNOPSIS
  Install Thermal Camera Viewer on Windows into a project-local venv.

.DESCRIPTION
<<<<<<< HEAD
  Creates .venv in the repo root and installs this package (editable) with
  its dependencies from pyproject.toml: PyQt5 / OpenCV / PyUSB and
  libusb-package (bundled libusb-1.0 DLLs for PyUSB on Windows).
=======
  Creates .venv in the repo root, installs PyQt5 / OpenCV / PyUSB,
  libusb-package (bundled libusb-1.0 DLLs for PyUSB on Windows) and pyinstaller.
>>>>>>> 80cf198 (build(windows): add build-windows.ps1 script to bundle app into a distributable exe using pyinstaller)

  USB: you must still assign WinUSB to the camera with Zadig (VID 3474).
  See README.md -> Installation -> Windows.
#>
$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $Root

# $ErrorActionPreference does not apply to native executables in
# Windows PowerShell 5.1, so check each exit code explicitly.
function Invoke-Native([string]$FilePath, [string[]]$ArgumentList) {
    & $FilePath @ArgumentList
    if ($LASTEXITCODE -ne 0) {
        throw "Command failed (exit $LASTEXITCODE): $FilePath $($ArgumentList -join ' ')"
    }
}

function Fail([string]$Message) {
    Write-Host $Message -ForegroundColor Red
    exit 1
}

$PythonHint = "Install Python 3.10+ from https://www.python.org/downloads/ or: winget install Python.Python.3.12"

# `python` may resolve to the Microsoft Store alias stub, which is not a real
# interpreter, so ask it for its version instead of trusting Get-Command.
$Python = Get-Command python -ErrorAction SilentlyContinue
$Version = $null
if ($Python) {
    try {
        $Version = & $Python.Source -c "import sys; print('%d.%d' % sys.version_info[:2])" 2>$null
    } catch {
        $Version = $null
    }
}
if (-not $Version -or $LASTEXITCODE -ne 0) {
    Fail "Python not found in PATH. $PythonHint"
}
if ([version]$Version -lt [version]"3.10") {
    Fail "Python $Version found, but 3.10+ is required. $PythonHint"
}

$VenvDir = Join-Path $Root ".venv"
$Py = Join-Path $VenvDir "Scripts\python.exe"
if (-not (Test-Path $Py)) {
    # Missing or broken venv: (re)create it.
    Invoke-Native $Python.Source @("-m", "venv", "--clear", $VenvDir)
}

Invoke-Native $Py @("-m", "pip", "install", "-U", "pip")
Invoke-Native $Py @("-m", "pip", "install", "-e", $Root)

Write-Host ""
Write-Host "=== Done ===" -ForegroundColor Green
Write-Host "Run viewer:"
Write-Host "  $Py -m thermal_camera_viewer"
Write-Host ""
Write-Host "USB (required once): Zadig -> Options -> List All Devices ->"
Write-Host "  select camera (VID 3474, PID 45A2 or 45C2) -> WinUSB driver."
Write-Host "  See: https://github.com/jvdillon/p3-ir-camera#usb-driver-windows"
Write-Host ""
Write-Host "Optional: add FFmpeg to PATH for MP4 recording (F5)."
