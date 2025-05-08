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

# Get port settings from config
echo "Reading port settings from $CONFIG_FILE..."
PORT_SETTINGS=$(python ./deployment_scripts/parse_deployment_config.py $CONFIG_FILE port_settings)

# Step 2: Update repositories for all services
echo "Updating repositories for all services..."
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

    # Read TAG from the env file
    TAG=$(grep "TAG=" "$ENV_FILE" | cut -d'=' -f2)
    if [ -z "$TAG" ]; then
        TAG="latest"  # Default tag
    fi

    # Create image tag in the format env-tag
    IMAGE_TAG="$ENV-$TAG"

    echo "Building image for $SERVICE with tag $IMAGE_TAG..."

    # Handle service-specific build requirements
    case "$SERVICE" in
        "aps_api")
            # Read Git-related variables from the env file for aps_api
            GITHUB_TOKEN=$(grep "GIT_TOKEN=" "$ENV_FILE" | cut -d'=' -f2)
            ENGINE_REPOSITORY_URL=$(grep "ENGINE_REPOSITORY_URL=" "$ENV_FILE" | cut -d'=' -f2)
            BRANCH_NAME=$(grep "BRANCH=" "$ENV_FILE" | cut -d'=' -f2)
            COMMIT_HASH=$TAG  # Use TAG as COMMIT_HASH if needed

            if [ -z "$GITHUB_TOKEN" ] || [ -z "ENGINE_REPOSITORY_URL" ] || [ -z "$BRANCH_NAME" ]; then
                echo "Warning: Missing required Git variables in $ENV_FILE for aps_api"
                echo "Ensure REPOSITORY_URL, BRANCH, and GIT_TOKEN are set"
            fi

            # Build with Git-related build args for aps_api
            docker build -t "$SERVICE:$IMAGE_TAG" -f "$DOCKERFILE" \
                --build-arg GITHUB_TOKEN="$GITHUB_TOKEN" \
                --build-arg ENGINE_REPOSITORY_URL="$ENGINE_REPOSITORY_URL" \
                --build-arg BRANCH_NAME="$BRANCH_NAME" \
                --build-arg COMMIT_HASH="$COMMIT_HASH" \
                --build-arg ENV_FILE="$ENV_FILE" \
                ./services/$SERVICE
            ;;

        "rag")
            # For rag service, use the repositories directory as the build context
            docker build -t "$SERVICE:$IMAGE_TAG" -f "$DOCKERFILE" \
                --build-arg ENV_FILE="$ENV_FILE" \
                ./services/$SERVICE
            ;;

        *)
            # Generic build for other services
            docker build -t "$SERVICE:$IMAGE_TAG" -f "$DOCKERFILE" \
                --build-arg ENV_FILE="$ENV_FILE" \
                ./services/$SERVICE
            ;;
    esac

    if [ $? -ne 0 ]; then
        echo "Error: Failed to build docker image for $SERVICE"
        exit 1
    fi

    # Also tag as just the env for backwards compatibility
    docker tag "$SERVICE:$IMAGE_TAG" "$SERVICE:$ENV"

    SERVICE_UPPER=$(echo "$SERVICE" | tr '[:lower:]' '[:upper:]')
    export "${SERVICE_UPPER}_ENV"="$ENV"
    export "${SERVICE_UPPER}_IMAGE_TAG"="$IMAGE_TAG"

    # Extract and set port settings from config if available
    if [ ! -z "$PORT_SETTINGS" ]; then
        INTERNAL_PORT=$(echo $PORT_SETTINGS | jq -r ".$SERVICE.internal // empty")
        EXTERNAL_PORT=$(echo $PORT_SETTINGS | jq -r ".$SERVICE.external // empty")

        if [ ! -z "$INTERNAL_PORT" ]; then
            export "${SERVICE_UPPER}_INTERNAL_PORT"="$INTERNAL_PORT"
            echo "Setting ${SERVICE_UPPER}_INTERNAL_PORT=$INTERNAL_PORT"
        fi

        if [ ! -z "$EXTERNAL_PORT" ]; then
            export "${SERVICE_UPPER}_EXTERNAL_PORT"="$EXTERNAL_PORT"
            echo "Setting ${SERVICE_UPPER}_EXTERNAL_PORT=$EXTERNAL_PORT"
        fi
    fi
done

# Step 4: Run docker-compose with enabled services
echo "Starting services with docker-compose..."
docker compose up -d $SERVICES

echo "Deployment completed successfully!"