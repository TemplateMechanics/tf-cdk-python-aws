"""
This module defines the data structures for our configuration.
Currently, the dataclasses are defined for potential future integration
with a configuration parsing/validation library.
"""

from dataclasses import dataclass
from typing import Dict, List, Any

@dataclass
class AWSResource:
    name: str
    type: str
    args: Dict[str, Any]
    custom_name: str = None

@dataclass
class Config:
    team: str
    service: str
    environment: str
    region: str
    tags: Dict[str, str]
    aws_resources: List[AWSResource]
