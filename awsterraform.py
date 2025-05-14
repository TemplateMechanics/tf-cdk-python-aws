#!/usr/bin/env python
import re
import inspect
from typing import Any, Dict, Set
from cdktf import TerraformStack, TerraformOutput
from imports.aws.provider import AwsProvider
import importlib

# AWS region abbreviations for consistent naming
AWS_REGION_ABBREVIATIONS = {
    "us-east-1": "use1",
    "us-east-2": "use2",
    "us-west-1": "usw1",
    "us-west-2": "usw2",
    "af-south-1": "afs1",
    "ap-east-1": "ape1",
    "ap-south-1": "aps1",
    "ap-northeast-1": "apne1",
    "ap-northeast-2": "apne2",
    "ap-northeast-3": "apne3",
    "ap-southeast-1": "apse1",
    "ap-southeast-2": "apse2",
    "ca-central-1": "cac1",
    "eu-central-1": "euc1",
    "eu-west-1": "euw1",
    "eu-west-2": "euw2",
    "eu-west-3": "euw3",
    "eu-north-1": "eun1",
    "eu-south-1": "eus1",
    "me-south-1": "mes1",
    "sa-east-1": "sae1",
    "us-gov-east-1": "usge1",
    "us-gov-west-1": "usgw1",
    "cn-north-1": "cnn1",
    "cn-northwest-1": "cnnw1",
}

def to_snake_case(name: str) -> str:
    """Convert a camel case string to snake case."""
    return re.sub(r'(?<!^)(?=[A-Z])', '_', name).lower()

def resolve_value(value: Any, resources: Dict[str, Any]) -> Any:
    """Resolve referenced values in the configuration."""
    if isinstance(value, dict):
        return {k: resolve_value(v, resources) for k, v in value.items()}
    elif isinstance(value, list):
        return [resolve_value(item, resources) for item in value]
    elif isinstance(value, str):
        if value.startswith("secret:"):
            # In a real implementation, this would fetch from Terraform variables
            secret_key = value[len("secret:"):]
            # Placeholder for secret resolution
            print(f"WARNING: Secret references like {secret_key} are not fully implemented")
            return f"${{{secret_key}}}"
        elif value.startswith("ref:"):
            ref_text = value[4:]
            if "." in ref_text:
                ref_res, ref_attr = ref_text.split(".", 1)
            else:
                ref_res, ref_attr = ref_text, "id"
            if ref_res not in resources:
                raise ValueError(f"Referenced resource '{ref_res}' not found.")
            
            resource_obj = resources[ref_res]
            # In CDKTF, we need to use the appropriate property references
            try:
                # Try to access the attribute directly as a property
                return getattr(resource_obj, ref_attr)
            except AttributeError:
                # Some CDKTF resource types might have different attribute access patterns
                print(f"WARNING: Attribute '{ref_attr}' not found directly on resource '{ref_res}'")
                return resource_obj.get_string(ref_attr)
        else:
            return value
    else:
        return value

def get_lookup_params(required_params: Set, resolved_args: dict) -> dict:
    """Extract parameters needed for data source lookups."""
    lookup_params = {}
    for param in required_params:
        snake_key = to_snake_case(param)
        if snake_key in resolved_args:
            lookup_params[param] = resolved_args[snake_key]
        elif param in resolved_args:
            lookup_params[param] = resolved_args[param]
    return lookup_params

class AWSResourceBuilder:
    """Main class for building AWS resources from YAML configurations."""
    
    def __init__(self, stack: TerraformStack, config_data: dict):
        self.stack = stack
        self.config = config_data
        self.resources: Dict[str, Any] = {}
        
        # Add AWS Provider
        AwsProvider(self.stack, "aws",
                   region=self.config.get("region", "us-east-1"))

    def get_abbreviation(self, region: str) -> str:
        """Get the standard abbreviation for an AWS region."""
        return AWS_REGION_ABBREVIATIONS.get(region.lower(), region.split("-")[0].lower())

    def generate_resource_name(self, base_name: str) -> str:
        """Generate a standardized resource name."""
        team = self.config.get("team", "team").strip().lower()
        service = self.config.get("service", "svc").strip().lower()
        env = self.config.get("environment", "dev").strip().lower()
        reg_abbr = self.get_abbreviation(self.config.get("region", "us-east-1"))
        return f"{team}-{service}-{env}-{reg_abbr}-{base_name}".lower()

    def resolve_args(self, args: dict) -> dict:
        """Resolve all argument values, including references."""
        return {key: resolve_value(value, self.resources) for key, value in args.items()}

    def _apply_common_parameters(self, resolved_args: dict, resource_type: str) -> dict:
        """Apply common parameters to resource arguments based on resource type."""
        # Resources that explicitly support tags
        tag_supporting_resources = [
            "s3_bucket.s3bucket",
            "lambda_function.lambdafunction", 
            "dynamodb_table.dynamodbtable",
            "api_gateway_rest_api.apigatewayrestapi",
            "cognito_user_pool.cognitouserpool",
            "sqs_queue.sqsqueue",
            "apigatewayv2_api.apigatewayv2api",
            "ssm_parameter.ssmparameter",
            "iam_role.iamrole",
            "cloudfront_distribution.cloudfrontdistribution"
        ]
        
        # Check if the resource supports tags
        resource_type_lower = resource_type.lower()
        supports_tags = any(tag_resource.lower() in resource_type_lower for tag_resource in tag_supporting_resources)
        
        if supports_tags:
            resource_tags = self.config.get("tags", {})
            if resource_tags:
                resolved_args.setdefault("tags", resource_tags)
                
        return resolved_args

    def build(self):
        """Build all AWS resources defined in the configuration."""
        aws_resources = self.config.get("aws_resources", [])
        
        for resource_cfg in aws_resources:
            name = resource_cfg["name"]
            resource_type = resource_cfg["type"]
            args = resource_cfg.get("args", {}).copy()
            custom_name = resource_cfg.get("custom_name", None)
            is_existing = args.pop("existing", False)
            
            # Resolve any reference variables in the arguments
            resolved_args = self.resolve_args(args)
            
            # Import the appropriate module based on resource type
            try:
                # The format in cdktf-provider-aws is different from Pulumi
                # We need to map from resource_type to the correct import path
                module_name, class_name = self._map_resource_type(resource_type)
                
                # Try to import the module
                module = importlib.import_module(f"imports.aws.{module_name}")
                ResourceClass = getattr(module, class_name)
                
                # Generate a resource name following conventions
                terraform_name = custom_name if custom_name else self.generate_resource_name(name)
                
                # Apply common parameters like tags
                resolved_args = self._apply_common_parameters(resolved_args, resource_type)
                
                # Handle data sources (existing resources)
                if is_existing:
                    # For existing resources, we should use a data source
                    data_source_module = importlib.import_module(f"imports.aws.{module_name}_data")
                    DataClass = getattr(data_source_module, f"{class_name}Data")
                    
                    # Create the data source
                    self.resources[name] = DataClass(self.stack, name, **resolved_args)
                    print(f"Created data source for: {terraform_name} ({resource_type})")
                else:
                    # Create a new resource
                    self.resources[name] = ResourceClass(self.stack, name, **resolved_args)
                    print(f"Created resource: {terraform_name} ({resource_type})")
                
            except (ImportError, AttributeError) as e:
                print(f"Error creating resource '{name}' of type '{resource_type}': {e}")
                continue
        
        # Export created resources as outputs
        for name, resource in self.resources.items():
            try:
                TerraformOutput(self.stack, f"output_{name}", value=resource.id)
            except Exception as e:
                print(f"Failed to export resource '{name}': {e}")

    def _map_resource_type(self, resource_type: str) -> tuple:
        """Map Pulumi resource type to CDKTF resource type."""
        # Example mapping from Pulumi to CDKTF
        # In Pulumi: "ec2.Vpc" -> In CDKTF: from imports.aws.vpc import Vpc
        
        # Parse the resource type
        if "." in resource_type:
            service, class_name = resource_type.split(".", 1)
        else:
            # Default to EC2 if no service specified
            service, class_name = "ec2", resource_type
            
        # Map service names that differ between Pulumi and CDKTF
        service_map = {
            "vpc": "vpc",
            "ec2": "instance",
            "s3": "s3_bucket",
            "s3_bucket": "s3_bucket",
            "iam": "iam_role",
            "lambda": "lambda_function",
            "apigateway": "api_gateway_rest_api",
            "apigatewayv2": "apigatewayv2_api",
            "dynamodb": "dynamodb_table",
            "cloudfront": "cloudfront_distribution",
            "cloudwatch": "cloudwatch_dashboard",
            "cognito": "cognito_user_pool",
            "sqs": "sqs_queue",
            "ssm": "ssm_parameter",
            "bedrock": "bedrock_agent"
        }
        
        # Convert service name to module name
        module_name = service_map.get(service.lower(), service.lower())
        
        # Return the module and class name
        return module_name, class_name
