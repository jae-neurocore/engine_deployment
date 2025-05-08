import sys
import yaml

def parse_yaml(file_path):
    with open(file_path, 'r') as file:
        data = yaml.safe_load(file)
        services = " ".join(data.get('services', {}).keys())
        print(services, end='')

if __name__ == "__main__":
    if len(sys.argv) > 1:
        parse_yaml(sys.argv[1])