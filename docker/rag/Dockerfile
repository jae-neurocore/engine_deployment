FROM python:3.10-slim

WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y \
    git \
    build-essential \
    jq \
    && rm -rf /var/lib/apt/lists/*

# Copy requirements first for better caching
RUN pip install --no-cache-dir uv
COPY requirements.txt .
RUN uv pip install --no-cache-dir -r requirements.txt --system

# Copy the source code
COPY . .

RUN mkdir -p logs

EXPOSE 8001

# Run the FastAPI application
CMD ["python", "main.py"]