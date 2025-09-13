#!/bin/bash

echo "🚀 Starting BlogCMS Backend..."

# Change to backend directory
cd /home/edwin/applikasi/go-vue-blogcms/backend

# Check if we're in the right directory
echo "Current directory: $(pwd)"
echo "Files in directory:"
ls -la cmd/server/

# Load environment variables
echo "Loading environment variables from .env..."
set -a
source .env
set +a

echo "Database connection: $DB_HOST:$DB_PORT/$DB_NAME"
echo "MinIO endpoint: $MINIO_ENDPOINT"

# Run the server
echo "Starting Go server..."
go run cmd/server/main.go
