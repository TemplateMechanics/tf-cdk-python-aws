#!/usr/bin/env python

import pytest
from cdktf import Testing

# The tests below are example tests, you can find more information at
# https://cdk.tf/testing


class TestAwsClassicStack:

    def test_my_app(self):
        assert True
        
    # These tests would work if you have the proper config.yaml and imported modules
    # Uncomment once your environment is fully set up
    
    # def test_synthesizes(self):
    #     stack = Testing.app().stack("tf-cdk-python-aws")
    #     assert Testing.to_be_valid_terraform(stack)

    # def test_has_resource(self):
    #     stack = Testing.app().stack("tf-cdk-python-aws")
    #     # Assert the stack contains a certain resource type
    #     assert Testing.to_have_resource(stack, "aws_vpc")
    
    # def test_to_match_snapshot(self):
    #     stack = Testing.app().stack("tf-cdk-python-aws")
    #     assert Testing.to_match_terraform_snapshot(stack)
