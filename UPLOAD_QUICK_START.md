# Quick Start: Image Upload Setup

This guide will help you quickly set up and test the image upload functionality in the BlogCMS.

## Prerequisites

- Go 1.19+ installed
- MySQL or compatible database running
- Git

## Quick Setup

### 1. Clone and Setup Project

```bash
git clone <repository-url>
cd go-vue-blogcms/backend
```

### 2. Install Dependencies

```bash
go mod tidy
```

### 3. Environment Configuration

Copy the example environment file:

```bash
cp .env.example .env
```

Edit `.env` with your settings:

```bash
# Basic configuration for local development
STORAGE_DRIVER=local
UPLOAD_DIR=./storage/uploads
BASE_URL=http://localhost:8080
STORAGE_MAX_FILE_SIZE=5242880

# Database settings
DB_HOST=localhost
DB_PORT=3306
DB_USER=root
DB_PASS=yourpassword
DB_NAME=blog_cms

# JWT Secret (change in production!)
JWT_SECRET=your-super-secret-jwt-key-here
```

### 4. Create Storage Directory

```bash
mkdir -p storage/uploads
chmod 755 storage/uploads
```

### 5. Database Setup

Create the database:

```sql
CREATE DATABASE blog_cms CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
```

### 6. Run the Application

```bash
go run cmd/server/main.go
```

The server will start on `http://localhost:8080`

## Test Upload Functionality

### Option 1: Use the Test Script

```bash
chmod +x test_upload.sh
./test_upload.sh
```

### Option 2: Manual Testing

1. **Check upload info:**
   ```bash
   curl http://localhost:8080/api/v1/uploads/info
   ```

2. **Register a user:**
   ```bash
   curl -X POST http://localhost:8080/api/v1/auth/register \
     -H "Content-Type: application/json" \
     -d '{
       "username": "testuser",
       "email": "test@example.com", 
       "password": "testpass123",
       "name": "Test User",
       "role": "author"
     }'
   ```

3. **Login to get token:**
   ```bash
   curl -X POST http://localhost:8080/api/v1/auth/login \
     -H "Content-Type: application/json" \
     -d '{
       "email": "test@example.com",
       "password": "testpass123"
     }'
   ```

4. **Upload an image:**
   ```bash
   curl -X POST http://localhost:8080/api/v1/uploads/images \
     -H "Authorization: Bearer YOUR_TOKEN_HERE" \
     -F "image=@/path/to/your/image.jpg"
   ```

## MinIO Setup (Optional)

For S3-compatible storage using MinIO:

### 1. Start MinIO

```bash
docker-compose -f docker-compose.minio.yml up -d
```

### 2. Update Environment

```bash
# In .env file
STORAGE_DRIVER=s3
S3_ENDPOINT=http://localhost:9000
AWS_REGION=us-east-1
S3_BUCKET_NAME=blog-uploads
AWS_ACCESS_KEY_ID=minioadmin
AWS_SECRET_ACCESS_KEY=minioadmin123
S3_BASE_URL=http://localhost:9000/blog-uploads
S3_FORCE_PATH_STYLE=true
```

### 3. Access MinIO Console

- URL: http://localhost:9001
- Username: minioadmin
- Password: minioadmin123

## Frontend Integration

### Upload Function (JavaScript)

```javascript
async function uploadImage(file, token) {
  const formData = new FormData();
  formData.append('image', file);
  
  const response = await fetch('/api/v1/uploads/images', {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${token}`
    },
    body: formData
  });
  
  if (!response.ok) {
    throw new Error('Upload failed');
  }
  
  return await response.json();
}
```

### Create Post with Thumbnail

```javascript
async function createPost(title, content, thumbnailFile, categoryId, token) {
  // First upload the image
  const uploadResult = await uploadImage(thumbnailFile, token);
  
  // Then create the post with thumbnail URL
  const response = await fetch('/api/v1/posts', {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${token}`,
      'Content-Type': 'application/json'
    },
    body: JSON.stringify({
      title: title,
      content: content,
      thumbnail_url: uploadResult.url,
      category_id: categoryId,
      status: 'published'
    })
  });
  
  return await response.json();
}
```

## Nginx Configuration (Production)

Add to your Nginx config:

```nginx
# Upload endpoints
location /api/v1/uploads/ {
    client_max_body_size 10M;
    proxy_pass http://backend;
    proxy_read_timeout 60s;
}

# Serve local uploads (if using local storage)
location /uploads/ {
    alias /var/www/uploads/;
    expires 1y;
    add_header Cache-Control "public, immutable";
}
```

## Troubleshooting

### Common Issues

1. **Permission denied errors:**
   ```bash
   sudo chown -R $USER:$USER storage/uploads
   chmod 755 storage/uploads
   ```

2. **Database connection errors:**
   - Check MySQL is running
   - Verify credentials in `.env`
   - Ensure database exists

3. **Large file uploads fail:**
   - Check `STORAGE_MAX_FILE_SIZE` setting
   - For Nginx: increase `client_max_body_size`

4. **Images not accessible:**
   - For local storage: check file permissions
   - For S3: verify bucket policy and credentials

### Health Check

```bash
curl http://localhost:8080/health
```

### View Logs

The application logs important events. Check console output for:
- Storage driver initialization
- Upload attempts
- Authentication issues
- File validation errors

## Next Steps

1. **Security:** Change JWT secret in production
2. **Storage:** Consider S3 for production deployments
3. **CDN:** Add CloudFront or similar for better performance
4. **Monitoring:** Add file usage tracking and cleanup policies
5. **Backup:** Implement backup strategy for uploaded files

## Support

For more detailed information, see:
- [UPLOAD_API.md](UPLOAD_API.md) - Complete API documentation
- [API_DOCUMENTATION.md](API_DOCUMENTATION.md) - Full API reference
- Test files in `tests/` directory
