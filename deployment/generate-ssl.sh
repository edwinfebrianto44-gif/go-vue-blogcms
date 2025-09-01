#!/bin/bash

# SSL Certificate Generation Script
# Generates self-signed certificates for development

DOMAIN=${1:-blog-api.mydomain.com}
SSL_DIR="nginx/ssl"

echo "🔐 Generating self-signed SSL certificates for $DOMAIN"

# Create SSL directory if it doesn't exist
mkdir -p $SSL_DIR

# Generate private key
openssl genrsa -out $SSL_DIR/privkey.pem 2048

# Generate certificate signing request
openssl req -new -key $SSL_DIR/privkey.pem -out $SSL_DIR/server.csr -subj "/C=ID/ST=Jakarta/L=Jakarta/O=BlogCMS/CN=$DOMAIN"

# Generate self-signed certificate
openssl x509 -req -days 365 -in $SSL_DIR/server.csr -signkey $SSL_DIR/privkey.pem -out $SSL_DIR/fullchain.pem

# Set proper permissions
chmod 600 $SSL_DIR/privkey.pem
chmod 644 $SSL_DIR/fullchain.pem

# Clean up
rm $SSL_DIR/server.csr

echo "✅ SSL certificates generated successfully!"
echo "   Certificate: $SSL_DIR/fullchain.pem"
echo "   Private Key: $SSL_DIR/privkey.pem"
echo ""
echo "⚠️  WARNING: These are self-signed certificates for development only!"
echo "   For production, use Let's Encrypt certificates:"
echo "   sudo certbot certonly --standalone -d $DOMAIN"
