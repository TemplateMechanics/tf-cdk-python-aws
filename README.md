# Terraform CDK YAML-Based Infrastructure Builder for AWS

A fully cross-platform, PowerShell-driven Terraform CDK (CDKTF) solution for AWS infrastructure-as-code. This project provides a dynamic and extensible infrastructure framework fully configured using YAML files. It automatically manages resource naming (with custom name overrides), supports referencing existing resources, allows dynamic linking between resources, and integrates secret resolution.

## 📂 Project Structure

```
.
├── main.py                # Entry point: loads YAML and builds AWS resources
├── awsterraform.py        # AWS-specific logic, naming conventions, and secret resolution
├── config.py              # Dataclasses and dynamic resource mapping
├── config-old.yaml        # Reference YAML configuration
├── main-test.py           # Tests for main functionality
├── example.py             # Example infrastructure built programmatically
├── lambda/                # Lambda function code
│   └── index.js           # Simple Lambda handler placeholder
├── lambda-placeholder.zip # Packaged Lambda for deployment 
├── cdktf.json             # Terraform CDK configuration
├── imports/               # Generated AWS provider bindings
├── setup.ps1              # Fully cross-platform setup script for development environment
├── run.ps1                # PowerShell task runner (cross-platform)
└── README.md              # Documentation (this file)
```

## 🚀 Features

- **YAML-defined infrastructure**: Define all infrastructure clearly in YAML.
- **Dynamic resource mapping**: Automatically maps YAML definitions to Terraform resource classes.
- **Intelligent resource naming**: Automatically incorporates team, service, environment, and region abbreviations.
- **AWS region abbreviation**: Converts full AWS region names (e.g., `us-east-1`) into standardized abbreviations (e.g., `use1`).
- **Resource referencing**: Use `ref:<resource-name>.<attribute>` syntax to dynamically link resources.
- **New and existing resources**: Seamlessly create new resources or fetch existing ones.
- **Custom name overrides**: Override generated names with a `custom_name` field for resources with strict naming rules.
- **Secret resolution**: Use `secret:<key>` in your YAML to securely reference sensitive data from Terraform variables.
- **Cross-platform workflow**: Fully supports Windows, macOS, and Linux with both Bash and PowerShell scripts.
- **Lambda function support**: Includes scaffolding for Lambda functions with proper IAM role setup.
- **Extensive AWS provider support**: Integrates with the full range of AWS services through auto-generated provider bindings.

## 📄 Example `config.yaml`

```yaml
team: "Business"
service: "WebApp"
environment: "prod"
region: "us-east-1"
tags:
  owner: "Business-team"
  project: "WebSocketApplication"

aws_resources:
  # IAM Roles for Lambda functions
  - name: "lambda-authorizer-role"
    type: "iam_role.IamRole"
    args:
      name: "lambda-authorizer-role"
      assume_role_policy: "{\"Version\":\"2012-10-17\",\"Statement\":[{\"Effect\":\"Allow\",\"Principal\":{\"Service\":\"lambda.amazonaws.com\"},\"Action\":\"sts:AssumeRole\"}]}"

  # S3 Web App (UI)
  - name: "s3-webapp"
    type: "s3_bucket.S3Bucket"
    args:
      bucket: "business-webapp-ui"
      force_destroy: true
      tags: 
        Name: "Web app UI"
        
  # Reference existing VPC
  - name: "existing-vpc"
    type: "vpc.Vpc"
    args:
      existing: true
      vpc_id: "vpc-0abc12345def67890"  # Replace with an actual VPC ID

  # Reference other resources with the ref: syntax
  - name: "subnet-01"
    type: "vpc.Subnet"
    args:
      vpc_id: "ref:vpc-01.id"
      cidr_block: "10.0.1.0/24"
      availability_zone: "us-east-1a"

  # Use custom name and secrets
  - name: "ec2-instance"
    type: "ec2.Instance"
    custom_name: "myinstance"  # Custom override for resources with naming restrictions
    args:
      ami: "ami-0abcdef1234567890"
      instance_type: "t2.micro"
      key_name: "secret:awsKeyPairName"
```

## 🛠 Getting Started

### Prerequisites

- Node.js (>= 14.x)
- Python (>= 3.8)
- AWS CLI configured with appropriate credentials
- Dependencies (automatically installed by setup scripts):
  - cdktf >= 0.19.0
  - cdktf-cdktf-provider-aws >= 18.0.0 
  - PyYAML >= 5.4.1
  - constructs >= 10.0.0
- For Windows users or cross-platform workflow:
  - PowerShell (included on Windows; installable on macOS/Linux)

### Quick Setup

1. **Setup the development environment**:

**On macOS/Linux:**
```bash
# Run the PowerShell setup script (recommended for cross-platform support)
./setup.ps1

# Or alternatively use bash directly:
python3 -m venv .venv
source .venv/bin/activate
pip install --upgrade pip
pip install -r requirements.txt
npx cdktf get
```

**On Windows or cross-platform (PowerShell):**
```powershell
# Run the PowerShell setup script
./setup.ps1

# After running the setup script:
# The virtual environment will be created and dependencies installed
# To activate the environment in future sessions:
# - On Windows: .\.venv\Scripts\Activate.ps1
# - On macOS/Linux: source .venv/bin/activate
```

2. **Use the PowerShell scripts for operations**:

```powershell
# Initialize and get providers
./run.ps1 init

# Plan the infrastructure deployment
./run.ps1 plan

# Deploy the infrastructure
./run.ps1 deploy

# Destroy the infrastructure
./run.ps1 destroy

# Run tests
./run.ps1 test

# Run the example
./run.ps1 example

# Create sample configuration
./run.ps1 sample

# Show help
./run.ps1 help
```

> **Note:** All operations are designed to work seamlessly across Windows, macOS, and Linux.

### Manual Setup

If you prefer to set up manually instead of using the automated setup script:

**Cross-platform with PowerShell:**
```powershell
# Create Python virtual environment
python -m venv .venv

# Activate environment (Windows)
# .\.venv\Scripts\Activate.ps1

# Activate environment (macOS/Linux via PowerShell)
# & bash -c "source .venv/bin/activate && exec pwsh"

# Install dependencies
pip install -r requirements.txt

# Generate AWS provider bindings
npx cdktf get
```

### Configuring AWS Credentials

Ensure your AWS credentials are properly configured:

```bash
# Configure AWS credentials
aws configure

# Set AWS region for deployment
export AWS_REGION=us-east-1
```

## 🔗 Referencing Resources

Use the syntax `ref:<resource-name>.<attribute>` to dynamically reference outputs from previously defined resources.

Example:

```yaml
vpc_id: "ref:vpc-01.id"
```

## 🏷 Resource Naming Convention

Resource names follow the pattern:

```
<team>-<service>-<environment>-<region-abbr>-<resource-name>
```

**Example:**

```
devops-test-svc-dev-use1-vpc-01
```

## ⚙️ Dynamic Resource Resolution

The system automatically maps YAML resource types to Terraform provider resources, simplifying management and ensuring new resources are available as Terraform updates.

## 🧰 Cross-Platform Support

This project is designed to work seamlessly across different operating systems using PowerShell as the primary scripting language:

### PowerShell Cross-Platform Benefits

The PowerShell scripts provide numerous advantages:
- **Unified experience**: Works consistently on Windows, macOS, and Linux
- **No shell script dependencies**: Everything runs with PowerShell, eliminating the need for separate Bash scripts
- **Rich CLI experience**: Colored output and better error handling
- **Automatic environment detection**: Adapts to the operating system automatically
- **Python environment management**: Handles virtual environment activation across platforms
- **Simplified development workflow**: One command set for all platforms

### Installing PowerShell (if not already available)

- **Windows**: Pre-installed
- **macOS**: `brew install --cask powershell`
- **Linux**: See [Microsoft's installation guide](https://docs.microsoft.com/en-us/powershell/scripting/install/installing-powershell-on-linux)

## 🔶 Lambda Functions

The project includes support for AWS Lambda functions:

- A sample Lambda function is provided in the `lambda/` directory
- The `lambda-placeholder.zip` file serves as a template for Lambda deployments
- IAM roles for Lambda execution are included in the example configuration
- Lambda integration with other AWS services (API Gateway, S3, etc.) is supported

Example of Lambda function configuration in `config.yaml`:

```yaml
# Lambda function definition
- name: "lambda-function"
  type: "lambda_function.LambdaFunction"
  args:
    function_name: "my-lambda-function"
    role: "ref:lambda-role.arn"
    handler: "index.handler"
    runtime: "nodejs14.x"
    filename: "lambda-placeholder.zip"
```

## 🔧 AWS Provider Integration

The project leverages the full AWS provider ecosystem through auto-generated bindings:

- All AWS resources are available through the `imports/aws/` directory
- Resource types are automatically mapped from the YAML configuration
- New AWS services and resources are available as they're added to the provider
- Each resource type follows the `<service>.<ResourceType>` naming pattern

The framework dynamically resolves resource imports at runtime, allowing you to use any AWS resource supported by the Terraform AWS provider without modifying the core code.

## ⚙️ Configuration Files

### cdktf.json

The `cdktf.json` file configures the Terraform CDK:

```json
{
  "language": "python",
  "app": "python main.py",
  "projectId": "36926f7c-9d50-40f3-8569-9155c170abee",
  "sendCrashReports": "false",
  "terraformProviders": [
    "aws@~>4.0"
  ],
  "terraformModules": [],
  "codeMakerOutput": "imports",
  "context": {
    "aws:region": "us-east-1"
  }
}
```

This configuration:
- Sets Python as the language
- Specifies the entry point (`python main.py`)
- Configures AWS provider version (~>4.0)
- Directs generated code to the `imports/` directory
- Sets default AWS region to us-east-1

### 🔧 PowerShell Scripts

The repository uses PowerShell as the primary scripting language for cross-platform compatibility:

- `setup.ps1`: Sets up the development environment by detecting the OS, installing dependencies, and configuring the project.
- `run.ps1`: Provides a unified command interface for all operations (plan, deploy, destroy, test, etc.)

These scripts automatically detect the operating system and adjust their behavior accordingly, providing a consistent experience across Windows, macOS, and Linux without relying on platform-specific shell scripts.

### Configuring AWS Credentials
