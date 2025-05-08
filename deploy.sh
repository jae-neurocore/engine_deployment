#!/bin/bash

# Parse deploy_config.yml to determine which services to deploy
# You could use yq, python, or other tools to parse YAML
SERVICES=$(parse_yaml_function deploy_config.yml)

# Build the docker-compose command with the specified services
docker-compose up -d $SERVICES