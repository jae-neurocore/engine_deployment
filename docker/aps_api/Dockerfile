FROM python:3.10 AS builder

RUN apt-get update && apt-get install -y \
    git \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /build

ARG GITHUB_TOKEN
ARG ENGINE_REPOSITORY_URL
ARG BRANCH_NAME
ARG COMMIT_HASH

RUN git clone -b ${BRANCH_NAME} https://oauth2:${GITHUB_TOKEN}@github.com/${ENGINE_REPOSITORY_URL}.git .
#&& git reset --hard ${COMMIT_HASH}
RUN pip install --no-cache-dir uv
RUN uv pip install --no-cache-dir pyinstaller --system
RUN uv  pip install --no-cache-dir -r src/config/requirements.txt --system

RUN pyinstaller --onefile \
    --clean \
    --name target_app \
    --paths src/ \
    src/main.py

FROM python:3.10

WORKDIR /app

COPY requirements-fastapi.txt .
RUN pip install --no-cache-dir uv
RUN uv pip install --no-cache-dir -r requirements-fastapi.txt --system

COPY --from=builder /build/dist/target_app /app/target_app
RUN chmod +x /app/target_app

COPY ./app /app

COPY ./config.ini /app/config.ini

EXPOSE 8000

CMD ["python", "main.py"]