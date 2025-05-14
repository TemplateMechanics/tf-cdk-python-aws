#!/usr/bin/env pwsh
# make.ps1 - Cross-platform task runner for Terraform CDK Python AWS

param (
    [Parameter(Position=0)]
    [string]$Command = "help"
)

# Detect OS
$isWindowsOS = $env:OS -eq 'Windows_NT' -or $PSVersionTable.PSEdition -eq 'Desktop'
$isMacOSEnv = $IsMacOS -or ($PSVersionTable.Platform -eq 'Unix' -and (bash -c "uname" 2>$null) -eq "Darwin")
$isLinuxEnv = $IsLinux -or ($PSVersionTable.Platform -eq 'Unix' -and -not $isMacOSEnv)

# Activate Python environment depending on platform
function Activate-PythonEnv {
    if ($isWindowsOS) {
        # For Windows
        if (Test-Path ".\.venv\Scripts\Activate.ps1") {
            & .\.venv\Scripts\Activate.ps1
            return $true
        } else {
            Write-Host "Virtual environment not found. Please run './make.ps1 setup' first." -ForegroundColor Red
            return $false
        }
    } else {
        # For macOS/Linux
        if (Test-Path "./.venv/bin/activate") {
            # We're using bash to source the activate script
            return $true
        } else {
            Write-Host "Virtual environment not found. Please run './make.ps1 setup' first." -ForegroundColor Red
            return $false
        }
    }
}

# Run a Python command within the virtual environment
function Run-PythonCommand {
    param (
        [string]$Command
    )
    
    if ($isWindowsOS) {
        if (Activate-PythonEnv) {
            & python -c $Command
        }
    } else {
        & bash -c "source .venv/bin/activate && python3 -c '$Command'"
    }
}

# Execute a Python script within the virtual environment
function Run-PythonScript {
    param (
        [string]$Script,
        [string]$Arguments = ""
    )
    
    if ($isWindowsOS) {
        if (Activate-PythonEnv) {
            & python $Script $Arguments
        }
    } else {
        & bash -c "source .venv/bin/activate && python3 $Script $Arguments"
    }
}

function Setup {
    Write-Host "Setting up development environment..." -ForegroundColor Cyan
    & ./setup.ps1
}

function Init {
    Write-Host "Initializing Terraform CDK..." -ForegroundColor Cyan
    
    if (-not $isWindowsOS) {
        & bash -c "source .venv/bin/activate && npx cdktf get"
    } else {
        npx cdktf get
    }
}

function Deploy {
    Write-Host "Deploying infrastructure with Terraform CDK..." -ForegroundColor Cyan
    
    if (-not $isWindowsOS) {
        & bash -c "source .venv/bin/activate && npx cdktf deploy"
    } else {
        npx cdktf deploy
    }
}

function Plan {
    Write-Host "Planning infrastructure deployment with Terraform CDK..." -ForegroundColor Cyan
    
    # For macOS/Linux we need to ensure the environment is active when running cdktf
    if (-not $isWindowsOS) {
        & bash -c "source .venv/bin/activate && npx cdktf plan"
    } else {
        npx cdktf plan
    }
}

function Destroy {
    Write-Host "Destroying infrastructure with Terraform CDK..." -ForegroundColor Cyan
    
    if (-not $isWindowsOS) {
        & bash -c "source .venv/bin/activate && npx cdktf destroy"
    } else {
        npx cdktf destroy
    }
}

function Clean {
    Write-Host "Cleaning build artifacts..." -ForegroundColor Cyan
    
    if (Test-Path ".terraform") { Remove-Item -Recurse -Force ".terraform" }
    if (Test-Path "cdktf.out") { Remove-Item -Recurse -Force "cdktf.out" }
    if (Test-Path "node_modules") { Remove-Item -Recurse -Force "node_modules" }
    
    Get-ChildItem -Path . -Include "*.pyc" -Recurse | Remove-Item -Force
    Get-ChildItem -Path . -Include "__pycache__" -Directory -Recurse | Remove-Item -Recurse -Force
}

function RunTest {
    Write-Host "Running tests..." -ForegroundColor Cyan
    
    if ($isWindowsOS) {
        if (Activate-PythonEnv) {
            pytest main-test.py -v
        }
    } else {
        & bash -c "source .venv/bin/activate && pytest main-test.py -v"
    }
}

function Example {
    Write-Host "Running example infrastructure deployment..." -ForegroundColor Cyan
    Run-PythonScript "example.py"
}

function Sample {
    Write-Host "Creating sample YAML configuration from example..." -ForegroundColor Cyan
    
    # Create a simple example config directly
    $pythonCmd = @"
import yaml

config = {
    "team": "Demo",
    "service": "example",
    "environment": "dev",
    "region": "us-east-1",
    "tags": {
        "Owner": "example-user",
        "Project": "TerraformExample"
    },
    "aws_resources": [
        {
            "name": "vpc-example",
            "type": "vpc.Vpc",
            "args": {
                "cidr_block": "10.0.0.0/16",
                "tags": {
                    "Name": "example-vpc"
                }
            }
        },
        {
            "name": "subnet-example",
            "type": "subnet.Subnet",
            "args": {
                "vpc_id": "ref:vpc-example.id",
                "cidr_block": "10.0.1.0/24",
                "availability_zone": "us-east-1a",
                "tags": {
                    "Name": "example-subnet"
                }
            }
        }
    ]
}

print(yaml.dump(config))
"@
    
    $tempFile = "./temp_sample_generator.py"
    $pythonCmd | Out-File -FilePath $tempFile -Encoding utf8
    
    try {
        if ($isWindowsOS) {
            if (Activate-PythonEnv) {
                python $tempFile > sample-config.yaml
                $success = $?
            }
        } else {
            & bash -c "source .venv/bin/activate && python3 $tempFile > sample-config.yaml"
            $success = $?
        }
        
        if ($success -and (Test-Path "sample-config.yaml")) {
            Write-Host "Created sample-config.yaml successfully." -ForegroundColor Green
        } else {
            Write-Host "Failed to create sample configuration." -ForegroundColor Red
        }
    }
    finally {
        if (Test-Path $tempFile) {
            Remove-Item -Path $tempFile -Force
        }
    }
}

function ShowHelp {
    Write-Host "Terraform CDK Python AWS - PowerShell Tasks" -ForegroundColor Green
    Write-Host "============================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "Usage: ./make.ps1 [command]" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Available commands:" -ForegroundColor Yellow
    Write-Host "  setup    - Set up the development environment" -ForegroundColor White
    Write-Host "  init     - Initialize Terraform CDK and download providers" -ForegroundColor White
    Write-Host "  plan     - Plan the infrastructure deployment" -ForegroundColor White
    Write-Host "  deploy   - Deploy the infrastructure" -ForegroundColor White
    Write-Host "  destroy  - Destroy the infrastructure" -ForegroundColor White
    Write-Host "  clean    - Clean build artifacts" -ForegroundColor White
    Write-Host "  test     - Run tests" -ForegroundColor White
    Write-Host "  example  - Run example infrastructure deployment" -ForegroundColor White
    Write-Host "  sample   - Create sample YAML configuration from example" -ForegroundColor White
    Write-Host "  help     - Show this help message" -ForegroundColor White
}

# Execute the command
switch ($Command.ToLower()) {
    "setup" { Setup }
    "init" { Init }
    "deploy" { Deploy }
    "plan" { Plan }
    "destroy" { Destroy }
    "clean" { Clean }
    "test" { RunTest }
    "example" { Example }
    "sample" { Sample }
    "help" { ShowHelp }
    default { 
        Write-Host "Unknown command: $Command" -ForegroundColor Red
        ShowHelp
    }
}
