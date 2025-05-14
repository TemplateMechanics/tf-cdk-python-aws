#!/usr/bin/env pwsh
# setup.ps1 - Cross-platform setup script for Terraform CDK Python AWS

Write-Host "Setting up Terraform CDK Python AWS project..." -ForegroundColor Cyan
Write-Host "===============================================" -ForegroundColor Cyan

# Detect OS
$isWindowsOS = $env:OS -eq 'Windows_NT' -or $PSVersionTable.PSEdition -eq 'Desktop'
$isMacOSEnv = $IsMacOS -or ($PSVersionTable.Platform -eq 'Unix' -and (bash -c "uname" 2>$null) -eq "Darwin")
$isLinuxEnv = $IsLinux -or ($PSVersionTable.Platform -eq 'Unix' -and -not $isMacOSEnv)

# Check if Node.js is installed
try {
    $nodeVersion = node -v
    Write-Host "Node.js version $nodeVersion detected." -ForegroundColor Green
} catch {
    Write-Host "Node.js is required but not installed. Please install Node.js and npm first." -ForegroundColor Red
    Write-Host "You can install it from: https://nodejs.org/" -ForegroundColor Yellow
    exit 1
}

# Check if npm is installed
try {
    $npmVersion = npm -v
    Write-Host "npm version $npmVersion detected." -ForegroundColor Green
} catch {
    Write-Host "npm is required but not installed. Please install npm first." -ForegroundColor Red
    exit 1
}

# Install Node.js dependencies
Write-Host "Installing Node.js dependencies..." -ForegroundColor Cyan
npm install

# Function to find Python interpreter
function Find-PythonInterpreter {
    $pythonCommands = @()
    
    if ($isWindowsOS) {
        $pythonCommands = @("python", "py")
    } else {
        # On macOS/Linux try python3 first, then python
        $pythonCommands = @("python3", "python")
    }
    
    foreach ($cmd in $pythonCommands) {
        try {
            $pythonVersion = & $cmd --version 2>&1
            Write-Host "Found $pythonVersion using command: $cmd" -ForegroundColor Green
            return $cmd
        } catch {
            # Command not found, try next one
            continue
        }
    }
    
    Write-Host "Python is required but not found. Please install Python first." -ForegroundColor Red
    return $null
}

# Find Python interpreter
$pythonCmd = Find-PythonInterpreter
if ($null -eq $pythonCmd) {
    exit 1
}

# Create Python virtual environment
Write-Host "Creating Python virtual environment..." -ForegroundColor Cyan
try {
    & $pythonCmd -m venv .venv
    Write-Host "Virtual environment created successfully." -ForegroundColor Green
} catch {
    Write-Host "Failed to create virtual environment: $_" -ForegroundColor Red
    exit 1
}

# Activate virtual environment and install dependencies
Write-Host "Installing Python dependencies..." -ForegroundColor Cyan
if ($isWindowsOS) {
    try {
        & .\.venv\Scripts\Activate.ps1
        & python -m pip install --upgrade pip
        & pip install -r requirements.txt
        Write-Host "Dependencies installed successfully." -ForegroundColor Green
    } catch {
        Write-Host "Failed to install dependencies: $_" -ForegroundColor Red
        exit 1
    }
} else {
    # For macOS/Linux, use bash to activate virtual environment and install dependencies
    try {
        Write-Host "Installing dependencies on Unix-like system..." -ForegroundColor Cyan
        & bash -c "source .venv/bin/activate && pip install --upgrade pip && pip install -r requirements.txt"
        if ($LASTEXITCODE -eq 0) {
            Write-Host "Dependencies installed successfully through bash." -ForegroundColor Green
        } else {
            throw "Failed to install dependencies through bash."
        }
    } catch {
        Write-Host "Failed to install dependencies: $_" -ForegroundColor Red
        Write-Host "You may need to manually activate the environment and install dependencies:" -ForegroundColor Yellow
        Write-Host "    source .venv/bin/activate" -ForegroundColor White
        Write-Host "    pip install --upgrade pip" -ForegroundColor White
        Write-Host "    pip install -r requirements.txt" -ForegroundColor White
        exit 1
    }
}

# Generate AWS provider bindings if needed
if (-not (Test-Path "imports/aws")) {
    Write-Host "Generating AWS provider bindings with CDKTF..." -ForegroundColor Cyan
    npx cdktf get
    if ($LASTEXITCODE -eq 0) {
        Write-Host "AWS provider bindings generated successfully." -ForegroundColor Green
    } else {
        Write-Host "Failed to generate AWS provider bindings." -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "Setup complete!" -ForegroundColor Green
Write-Host "To activate the environment in future sessions:" -ForegroundColor Yellow
if ($isWindowsOS) {
    Write-Host "    .\.venv\Scripts\Activate.ps1" -ForegroundColor White
} else {
    Write-Host "    source .venv/bin/activate  # In bash/zsh" -ForegroundColor White
    Write-Host "    # Or in PowerShell:" -ForegroundColor White
    Write-Host "    & bash -c 'source .venv/bin/activate && exec pwsh'" -ForegroundColor White
}

Write-Host ""
Write-Host "Useful commands:" -ForegroundColor Cyan
Write-Host "- ./make.ps1 plan     # Preview infrastructure changes" -ForegroundColor White
Write-Host "- ./make.ps1 deploy   # Deploy infrastructure" -ForegroundColor White
Write-Host "- ./make.ps1 destroy  # Destroy infrastructure" -ForegroundColor White
Write-Host "- ./make.ps1 test     # Run tests" -ForegroundColor White
Write-Host "- ./make.ps1 example  # Run example deployment" -ForegroundColor White
