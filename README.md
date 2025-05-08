# Engine Deployment 

## How to
1. set deployment_config.yml
   - deployment_config.yml example
       ```yaml
       aps_api:
         enabled: true
         env: develop
         ports:
           internal: 8000
           external: 8000
        
       rag:
         enabled: true
         env: master
         ports:
           internal: 8001
           external: 8001
      ```
2. write .env files for configured services and envs
   - with deployment_config.yml example given 
     ```
     write file in ./env/aps_api/develop/.env
     write file in ./env/rag/master/.env
     ```
3. write Dockerfile for configured services
   - with deployment_config.yml example given 
     ```
     write file in ./docker/aps_api/Dockerfile
     write file in ./docker/rag/Dockerfile
     ```
4. run deploy.sh

### How deploy.sh works
1. read deployment_config.yml file with deployment_scripts/parse_deployment_config.py and get services, env file paths, and port settings
2. pull repository to services folder for each service and checkout to the branch and the tag with matching .env
3. build docker image for the services with matching .env
4. set environment variables including port settings from configuration
5. run docker compose for the services with matching .env

## Project Structure
```
.
└── project/
├── docker/
    │   ├── aps_api/
    │   │   └── Dockerfile
    │   └── rag/
    │       └── Dockerfile
    ├── env/
    │   ├── develop/
    │   │   ├── aps_api.env
    │   │   └── rag.env
    │   ├── master/
    │   │   ├── aps_api.env
    │   │   └── rag.env
    │   └── prod/
    │       ├── aps_api.env
    │       └── rag.env
    ├── services/
    │   ├── aps_api/
    │   │   └── [소스코드]
    │   └── rag/
    │       └── [소스코드]
    ├── deployment_scripts/
    │   ├── parse_deploy_config.py
    │   ├── update_repositories_for_services.py
    │   └── install_dependencies.sh
    ├── deployment_config.yml
    ├── deploy.sh
    └── docker-compose.yml
```