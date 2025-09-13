#!/bin/bash

# Setup MinIO bucket for BlogCMS
echo "Setting up MinIO bucket..."

# Wait for MinIO to be ready
echo "Waiting for MinIO to be ready..."
until curl -f http://localhost:9001/minio/health/live 2>/dev/null; do
    echo "Waiting for MinIO..."
    sleep 5
done

echo "MinIO is ready!"

# Install mc (MinIO client) if not exists
if ! command -v mc &> /dev/null; then
    echo "Installing MinIO client..."
    curl https://dl.min.io/client/mc/release/linux-amd64/mc -o mc
    chmod +x mc
    sudo mv mc /usr/local/bin/
fi

# Configure MinIO client
echo "Configuring MinIO client..."
mc alias set local http://localhost:9001 blogcms_minio blogcms_minio_2024

# Create bucket
echo "Creating bucket: blogcms-uploads"
mc mb local/blogcms-uploads --ignore-existing

# Set bucket policy to public-read for uploads
echo "Setting bucket policy..."
mc anonymous set public local/blogcms-uploads

echo "MinIO setup completed!"
echo "Bucket: blogcms-uploads"
echo "Access: http://localhost:9001/blogcms-uploads"
echo "Console: http://localhost:9002"
echo "Credentials: blogcms_minio / blogcms_minio_2024"
