import sys
import yaml
import os


def parse_yaml(file_path, output_format="services"):
    """
    Parse the deployment config YAML file and return information based on the output format.

    Args:
        file_path (str): Path to the deployment config YAML file
        output_format (str): Type of output to generate:
            - "services": Space-separated list of enabled services
            - "env_paths": JSON object with service name and env file path
            - "full": All configuration details in JSON format

    Returns:
        str: Formatted output based on the output_format parameter
    """
    try:
        with open(file_path, 'r') as file:
            data = yaml.safe_load(file)

            if not data:
                print("Error: Empty or invalid configuration file", file=sys.stderr)
                return ""

            # Filter only enabled services
            enabled_services = {name: config for name, config in data.items()
                                if isinstance(config, dict) and config.get('enabled', False)}

            if output_format == "services":
                # Return space-separated list of service names
                return " ".join(enabled_services.keys())

            elif output_format == "env_paths":
                # Return service and environment path mapping
                env_paths = {}
                for service, config in enabled_services.items():
                    env = config.get('env', 'develop')  # Default to develop if not specified
                    env_file_path = f"./env/{env}/{service}.env"
                    if os.path.exists(env_file_path):
                        env_paths[service] = env_file_path
                    else:
                        print(f"Warning: Environment file {env_file_path} not found", file=sys.stderr)

                import json
                return json.dumps(env_paths)

            elif output_format == "full":
                # Return full configuration for enabled services
                import json
                return json.dumps(enabled_services)

            else:
                print(f"Error: Unknown output format '{output_format}'", file=sys.stderr)
                return ""

    except Exception as e:
        print(f"Error parsing YAML file: {str(e)}", file=sys.stderr)
        return ""


if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python parse_deployment_config.py <config_file> [output_format]", file=sys.stderr)
        sys.exit(1)

    config_file = sys.argv[1]
    output_format = sys.argv[2] if len(sys.argv) > 2 else "services"

    result = parse_yaml(config_file, output_format)
    print(result, end='')