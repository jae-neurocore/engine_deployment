# 엔진 배포 

## 배포 하는법
1. ./deployment_scripts/install_jq.sh 실행
2. deployment_config.yml 파일 설정
   - deployment_config.yml 예시
       ```yaml
       aps_api:
         enabled: true # 배포하고자 하는 서비스는 true로 설정
         env: develop # ./env/develop/.env 를 사용하겠다는 설정
         ports:
           internal: 8000 # 컨테이너 내부에서 사용하는 포트 (8000번 고정)
           external: 50125 # 컨테이너 외부에서 사용하는 포트 (서비스 별 변경 필요)
        
       rag:
         enabled: true
         env: develop
         ports:
           internal: 8000
           external: 50126
      ```
3. .env 파일 작성
   - (1)에 설정된 deployment_config.yml 기준 
     ```
     아래 두 경로에 .env 파일 작성
     ./env/aps_api/develop/.env
     ./env/rag/develop/.env
     ```
4. Dockerfile 작성
   - (1)에 설정된 deployment_config.yml 기준 
     ```
     아래 두 경로에 Dockerfile 작성
     ./docker/aps_api/Dockerfile
     ./docker/rag/Dockerfile
     ```
5. run deploy.sh

### deploy.sh 작동 방식
1. deployment_config.yml 설정 파일 해석
2. 각 설정에 맞도록 services 하위에 원격 저장소 clone/pull
3. 서비스 별 도커 이미지 빌드
4. docker compose up 실행

## Project Structure
```
.
└── project/
    ├── deployment_scripts/
    │   └── [scripts]
    ├── docker/
    │   ├── aps_api/
    │   │   └── Dockerfile
    │   └── rag/
    │       └── Dockerfile
    ├── env/
    │   ├── develop/
    │   │   ├── aps_api.env
    │   │   └── rag.env
    │   └── master/
    │       ├── aps_api.env
    │       └── rag.env
    ├── services/
    │   ├── aps_api/
    │   │   └── [소스코드]
    │   └── rag/
    │       └── [소스코드]
    ├── deployment_config.yml
    ├── docker-compose.yml
    ├── deploy.sh
    ├── README.md
    └── requirements.txt
```