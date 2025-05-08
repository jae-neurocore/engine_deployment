#!/bin/bash
# Check if jq is installed, if not install it
if ! command -v jq &> /dev/null; then
    echo "jq is not installed. Installing jq..."

    # Detect OS
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS=$ID
    elif [ -f /etc/debian_version ]; then
        OS=debian
    elif [ -f /etc/redhat-release ]; then
        OS=redhat
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        OS=macos
    else
        echo "Unsupported OS. Please install jq manually."
        exit 1
    fi

    # Install jq based on OS
    case $OS in
        ubuntu|debian)
            sudo apt-get update
            sudo apt-get install -y jq
            ;;
        centos|fedora|redhat)
            sudo yum install -y jq
            ;;
        macos)
            if command -v brew &> /dev/null; then
                brew install jq
            else
                echo "Homebrew not found. Please install homebrew first or install jq manually."
                exit 1
            fi
            ;;
        *)
            echo "Unsupported OS. Please install jq manually."
            exit 1
            ;;
    esac
fi

echo "All dependencies installed successfully!"