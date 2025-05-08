#!/bin/bash

SERVICES=$(python ./deployment_scripts/parse_deployment_config.py deployment_config.yml)

#docker-compose up -d $SERVICES

echo $SERVICES