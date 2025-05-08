# Engine Deployment 

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
    ├── deploy_config.yml
    └── docker-compose.yml
```
