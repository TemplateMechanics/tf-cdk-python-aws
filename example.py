#!/usr/bin/env python
"""
Example script demonstrating how to use the AWS Terraform CDK infrastructure builder.
This file creates a simple VPC, subnet, and EC2 instance using a YAML configuration.
"""

import yaml
from awsterraform import AWSResourceBuilder
from cdktf import App, TerraformStack
from constructs import Construct

class ExampleStack(TerraformStack):
    def __init__(self, scope: Construct, id: str):
        super().__init__(scope, id)
        
        # Define a simple configuration in code
        # In a real scenario, you would load this from config.yaml
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
        
        # Create the AWS resource builder and build the resources
        builder = AWSResourceBuilder(self, config)
        builder.build()


def main():
    app = App()
    ExampleStack(app, "example-stack")
    app.synth()


if __name__ == "__main__":
    main()
