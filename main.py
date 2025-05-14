#!/usr/bin/env python
import yaml
from constructs import Construct
from cdktf import App, TerraformStack
from awsterraform import AWSResourceBuilder
from typing import Any, Dict

def load_config(file_path: str) -> Dict[str, Any]:
    """Load and validate YAML configuration from the given file path."""
    with open(file_path, "r") as file:
        config_data = yaml.safe_load(file)
    
    # Ensure required keys exist
    required_keys = ["team", "service", "environment", "region"]
    for key in required_keys:
        if key not in config_data:
            raise ValueError(f"Missing required configuration key: {key}")
    
    return config_data

class AwsClassicStack(TerraformStack):
    def __init__(self, scope: Construct, id: str):
        super().__init__(scope, id)
        
        try:
            # Load YAML configuration
            config_data = load_config("config.yaml")
            
            # Create AWS Resource Builder
            builder = AWSResourceBuilder(self, config_data)
            
            # Build the resources defined in the YAML
            builder.build()
        except Exception as e:
            print(f"Error in stack creation: {e}")
            raise

def main():
    app = App()
    AwsClassicStack(app, "tf-cdk-python-aws")
    app.synth()

if __name__ == "__main__":
    main()
