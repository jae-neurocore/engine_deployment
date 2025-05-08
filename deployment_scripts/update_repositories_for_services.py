#!/usr/bin/env python3
import sys
import os
import json
import subprocess
import shutil
import re


def read_env_file(env_file_path):
    """
    Read environment variables from a .env file

    Args:
        env_file_path (str): Path to the environment file

    Returns:
        dict: Dictionary of environment variables
    """
    env_vars = {}
    try:
        with open(env_file_path, 'r') as file:
            for line in file:
                line = line.strip()
                if line and not line.startswith('#'):
                    key, *value = line.split('=', 1)
                    if value:  # Check if there's a value after the equals sign
                        env_vars[key] = value[0]
                    else:
                        env_vars[key] = ""  # Empty string for keys with no value
    except Exception as e:
        print(f"Error reading environment file {env_file_path}: {str(e)}", file=sys.stderr)

    return env_vars


def run_command(command, cwd=None, env=None):
    """
    Run a shell command and return the output

    Args:
        command (list): Command to run as a list of arguments
        cwd (str, optional): Current working directory
        env (dict, optional): Environment variables for the command

    Returns:
        tuple: (success, output)
    """
    try:
        result = subprocess.run(
            command,
            cwd=cwd,
            capture_output=True,
            text=True,
            check=True,
            env=env
        )
        return True, result.stdout.strip()
    except subprocess.CalledProcessError as e:
        return False, f"Command failed: {e.stderr.strip()}"
    except Exception as e:
        return False, f"Error executing command: {str(e)}"


def is_git_repo(path):
    """Check if a directory is a git repository"""
    return os.path.exists(os.path.join(path, '.git'))


def update_repository(service_name, env_file_path):
    """
    Update or clone a repository based on environment variables

    Args:
        service_name (str): Name of the service
        env_file_path (str): Path to the environment file

    Returns:
        bool: True if successful, False otherwise
    """
    print(f"Updating repository for service: {service_name}", file=sys.stderr)

    # Read environment variables from .env file
    env_vars = read_env_file(env_file_path)

    # Check required environment variables
    repository_url = env_vars.get('REPOSITORY_URL')
    branch = env_vars.get('BRANCH')
    tag = env_vars.get('TAG')
    git_token = env_vars.get('GIT_TOKEN', '')
    git_username = env_vars.get('GIT_USERNAME', '')

    if not repository_url:
        print(f"Error: REPOSITORY_URL not defined in {env_file_path}", file=sys.stderr)
        return False

    # If token and username are provided but not in the URL, add them
    if git_token and git_username and 'https://' in repository_url and '@' not in repository_url:
        # Format: https://username:token@host/path
        url_parts = repository_url.split('https://')
        if len(url_parts) == 2:
            repository_url = f"https://{git_username}:{git_token}@{url_parts[1]}"

    # Ensure services directory exists
    services_dir = os.path.join(os.getcwd(), 'services')
    os.makedirs(services_dir, exist_ok=True)

    service_dir = os.path.join(services_dir, service_name)

    # Create a clean environment dictionary for git commands
    git_env = os.environ.copy()
    if git_token:
        # Set Git credential helper to store credentials temporarily
        # This helps with HTTP authentication without exposing the token in process lists
        git_env['GIT_ASKPASS'] = 'echo'
        git_env['GIT_USERNAME'] = git_username
        git_env['GIT_PASSWORD'] = git_token

    # Check if repository already exists
    if is_git_repo(service_dir):
        print(f"Repository for {service_name} already exists. Updating...", file=sys.stderr)

        # Fetch the latest changes
        success, output = run_command(['git', 'fetch', '--all'], cwd=service_dir, env=git_env)
        if not success:
            print(output, file=sys.stderr)
            return False

    else:
        print(f"Cloning repository for {service_name}...", file=sys.stderr)

        # Remove directory if it exists but is not a git repository
        if os.path.exists(service_dir):
            shutil.rmtree(service_dir)

        # Clone the repository
        success, output = run_command(['git', 'clone', repository_url, service_dir], env=git_env)
        if not success:
            print(output, file=sys.stderr)
            return False

    # Checkout to the specified branch
    if branch:
        print(f"Checking out branch: {branch}", file=sys.stderr)
        success, output = run_command(['git', 'checkout', branch], cwd=service_dir, env=git_env)
        if not success:
            print(output, file=sys.stderr)
            return False

        # Only pull if we're on a branch
        print(f"Pulling latest changes for branch: {branch}", file=sys.stderr)
        success, output = run_command(['git', 'pull'], cwd=service_dir, env=git_env)
        if not success:
            print(output, file=sys.stderr)
            return False

    # Checkout to the specified tag if provided
    if tag:
        print(f"Checking out tag: {tag}", file=sys.stderr)
        success, output = run_command(['git', 'checkout', tag], cwd=service_dir, env=git_env)
        if not success:
            print(output, file=sys.stderr)
            return False

        # When checking out a tag, we're in "detached HEAD" state
        # We don't need to pull as a tag is a specific point in history
        print(f"Successfully checked out tag: {tag} (in detached HEAD state)", file=sys.stderr)

    print(f"Repository for {service_name} updated successfully.", file=sys.stderr)
    return True


def main():
    """
    Main function to update repositories for services
    """
    if len(sys.argv) < 2:
        print("Usage: python update_repositories_for_services.py <config_file>", file=sys.stderr)
        sys.exit(1)

    config_file = sys.argv[1]

    # Get env file paths for enabled services
    command = ['python', './deployment_scripts/parse_deployment_config.py', config_file, 'env_paths']
    success, output = run_command(command)

    if not success:
        print(f"Failed to parse deployment config: {output}", file=sys.stderr)
        sys.exit(1)

    try:
        env_paths = json.loads(output)
    except json.JSONDecodeError:
        print(f"Invalid JSON output from parse_deployment_config.py: {output}", file=sys.stderr)
        sys.exit(1)

    if not env_paths:
        print("No enabled services found in configuration", file=sys.stderr)
        sys.exit(1)

    # Update repositories for each service
    success_count = 0
    for service_name, env_file_path in env_paths.items():
        if update_repository(service_name, env_file_path):
            success_count += 1

    # Print summary
    print(f"Updated {success_count} of {len(env_paths)} repositories", file=sys.stderr)

    # Return success if all repositories were updated
    return success_count == len(env_paths)


if __name__ == "__main__":
    success = main()
    sys.exit(0 if success else 1)