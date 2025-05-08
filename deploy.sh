#!/bin/bash
set -e

CONFIG_FILE="deployment_config.yml"

# Step 1: Get enabled services from config
echo "Reading configuration from $CONFIG_FILE..."
SERVICES=$(python ./deployment_scripts/parse_deployment_config.py $CONFIG_FILE services)

if [ -z "$SERVICES" ]; then
    echo "Error: No enabled services found in configuration"
    exit 1
fi

echo "Enabled services: $SERVICES"

# Step 2: Update repositories for services
echo "Updating repositories for services..."
python ./deployment_scripts/update_repositories_for_services.py $CONFIG_FILE

if [ $? -ne 0 ]; then
    echo "Error: Failed to update repositories"
    exit 1
fi

# Step 3: Build docker images for services
echo "Building docker images for services..."
for SERVICE in $SERVICES; do
    ENV=$(grep -o "env:.*" $CONFIG_FILE | grep -A 1 "$SERVICE:" | tail -n 1 | awk '{print $2}')
    if [ -z "$ENV" ]; then
        ENV="develop"  # Default environment
    fi

    DOCKERFILE="./docker/$SERVICE/Dockerfile"
    ENV_FILE="./env/$ENV/$SERVICE.env"

    if [ ! -f "$DOCKERFILE" ]; then
        echo "Error: Dockerfile not found for service $SERVICE: $DOCKERFILE"
        exit 1
    fi

    if [ ! -f "$ENV_FILE" ]; then
        echo "Error: Environment file not found for service $SERVICE: $ENV_FILE"
        exit 1
    fi

    echo "Building image for $SERVICE with environment $ENV..."
    docker build -t "$SERVICE:$ENV" -f "$DOCKERFILE" --build-arg ENV_FILE="$ENV_FILE" ./services/$SERVICE

    if [ $? -ne 0 ]; then
        echo "Error: Failed to build docker image for $SERVICE"
        exit 1
    fi
done

# Step 4: Run docker-compose with enabled services
echo "Starting services with docker-compose..."
docker-compose up -d $SERVICES

echo "Deployment completed successfully!"