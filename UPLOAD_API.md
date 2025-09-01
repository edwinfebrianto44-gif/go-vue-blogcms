# Image Upload API Documentation

## Overview

The BlogCMS system provides comprehensive image upload functionality with support for both local storage and S3-compatible storage (including MinIO). This document explains how to configure and use the image upload features.

## Configuration

### Environment Variables

Add the following environment variables to your `.env` file:

```bash
# Storage Configuration
STORAGE_DRIVER=local
# Options: local, s3

# Local Storage Settings
UPLOAD_DIR=./storage/uploads
BASE_URL=http://localhost:8080
STORAGE_MAX_FILE_SIZE=5242880  # 5MB in bytes

# S3/MinIO Settings (when STORAGE_DRIVER=s3)
S3_ENDPOINT=http://localhost:9000  # For MinIO
AWS_REGION=us-east-1
S3_BUCKET_NAME=blog-uploads
AWS_ACCESS_KEY_ID=minioadmin
AWS_SECRET_ACCESS_KEY=minioadmin123
S3_BASE_URL=http://localhost:9000/blog-uploads
S3_FORCE_PATH_STYLE=true  # Required for MinIO
```

### Local Storage Setup

1. Create the upload directory:
   ```bash
   mkdir -p ./storage/uploads
   chmod 755 ./storage/uploads
   ```

2. Set `STORAGE_DRIVER=local` in your `.env` file

### MinIO/S3 Setup

1. Start MinIO using Docker Compose:
   ```bash
   cd backend
   docker-compose -f docker-compose.minio.yml up -d
   ```

2. Access MinIO Console at `http://localhost:9001` with:
   - Username: `minioadmin`
   - Password: `minioadmin123`

3. Set `STORAGE_DRIVER=s3` in your `.env` file

## API Endpoints

### Upload Information

Get information about upload requirements and limits:

```http
GET /api/v1/uploads/info
```

**Response:**
```json
{
  "success": true,
  "data": {
    "max_file_size": "5242880 bytes",
    "max_file_size_mb": 5.0,
    "max_file_size_bytes": 5242880,
    "allowed_types": [".jpg", ".jpeg", ".png", ".gif", ".webp"],
    "allowed_mime_types": ["image/jpeg", "image/jpg", "image/png", "image/gif", "image/webp"],
    "storage_driver": "local"
  }
}
```

### Upload Image

Upload an image file:

```http
POST /api/v1/uploads/images
Authorization: Bearer <your-jwt-token>
Content-Type: multipart/form-data

image: <file>
```

**Requirements:**
- Authentication: Author or Admin role required
- File size: Maximum 5MB (configurable)
- File types: JPG, JPEG, PNG, GIF, WebP
- Field name: `image`

**Success Response:**
```json
{
  "success": true,
  "message": "File uploaded successfully",
  "filename": "uuid_timestamp.jpg",
  "url": "http://localhost:8080/uploads/uuid_timestamp.jpg",
  "size": 1024567,
  "mime_type": "image/jpeg"
}
```

**Error Responses:**

*File too large:*
```json
{
  "success": false,
  "error": "file size exceeds maximum allowed size of 5242880 bytes"
}
```

*Invalid file type:*
```json
{
  "success": false,
  "error": "file type not allowed. Allowed types: JPG, JPEG, PNG, GIF, WebP"
}
```

*Invalid MIME type:*
```json
{
  "success": false,
  "error": "invalid MIME type. Expected image type, got: text/plain"
}
```

### Serve Local Images

For local storage, images are served directly by the application:

```http
GET /uploads/<filename>
```

**Response Headers:**
- `Cache-Control: public, max-age=31536000` (1 year)
- `Expires: Thu, 31 Dec 2025 23:59:59 GMT`

### Delete Image (Admin Only)

Delete an uploaded image:

```http
DELETE /api/v1/uploads/images/<filename>
Authorization: Bearer <admin-jwt-token>
```

**Requirements:**
- Authentication: Admin role required

## Usage in Posts

When creating or updating posts, use the returned URL in the `thumbnail_url` field:

```http
POST /api/v1/posts
Authorization: Bearer <your-jwt-token>
Content-Type: application/json

{
  "title": "My Blog Post",
  "content": "Post content here...",
  "thumbnail_url": "http://localhost:8080/uploads/uuid_timestamp.jpg",
  "category_id": 1,
  "status": "published"
}
```

## Frontend Implementation Example

### JavaScript/Fetch

```javascript
// Upload image
async function uploadImage(file) {
  const formData = new FormData();
  formData.append('image', file);
  
  const response = await fetch('/api/v1/uploads/images', {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${localStorage.getItem('token')}`
    },
    body: formData
  });
  
  if (!response.ok) {
    throw new Error('Upload failed');
  }
  
  return await response.json();
}

// Usage
const fileInput = document.getElementById('thumbnail');
const file = fileInput.files[0];

if (file) {
  try {
    const result = await uploadImage(file);
    console.log('Upload successful:', result.url);
    // Use result.url as thumbnail_url in post creation
  } catch (error) {
    console.error('Upload failed:', error);
  }
}
```

### Vue.js Example

```vue
<template>
  <div>
    <input
      type="file"
      @change="handleFileSelect"
      accept="image/*"
      ref="fileInput"
    />
    <button @click="uploadImage" :disabled="!selectedFile || uploading">
      {{ uploading ? 'Uploading...' : 'Upload' }}
    </button>
    <img v-if="uploadedImageUrl" :src="uploadedImageUrl" alt="Uploaded" />
  </div>
</template>

<script>
export default {
  data() {
    return {
      selectedFile: null,
      uploading: false,
      uploadedImageUrl: null
    }
  },
  methods: {
    handleFileSelect(event) {
      this.selectedFile = event.target.files[0];
    },
    
    async uploadImage() {
      if (!this.selectedFile) return;
      
      this.uploading = true;
      
      try {
        const formData = new FormData();
        formData.append('image', this.selectedFile);
        
        const response = await fetch('/api/v1/uploads/images', {
          method: 'POST',
          headers: {
            'Authorization': `Bearer ${this.$store.state.auth.token}`
          },
          body: formData
        });
        
        if (!response.ok) {
          throw new Error('Upload failed');
        }
        
        const result = await response.json();
        this.uploadedImageUrl = result.url;
        
        // Emit event or update parent component
        this.$emit('image-uploaded', result.url);
        
      } catch (error) {
        console.error('Upload failed:', error);
        // Handle error (show toast, etc.)
      } finally {
        this.uploading = false;
      }
    }
  }
}
</script>
```

## Nginx Configuration

For production deployments, ensure Nginx is configured to handle uploads and serve static files:

```nginx
# Upload endpoints with file size limits
location /api/v1/uploads/ {
    limit_req zone=api burst=10 nodelay;
    client_max_body_size 10M;
    
    proxy_pass http://backend_servers;
    proxy_http_version 1.1;
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;
    
    # Extended timeouts for file uploads
    proxy_connect_timeout 60s;
    proxy_send_timeout 60s;
    proxy_read_timeout 60s;
}

# Static file serving for local uploads
location /uploads/ {
    alias /var/www/uploads/;
    
    # Cache settings for images
    location ~* \.(jpg|jpeg|png|gif|webp|ico|svg)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
        add_header Vary Accept-Encoding;
        
        # Security headers for images
        add_header X-Content-Type-Options nosniff always;
        add_header X-Frame-Options DENY always;
        
        gzip_static on;
    }
    
    # Deny access to non-image files
    location ~* \.(php|php\d+|phtml|pl|py|jsp|asp|sh|cgi)$ {
        deny all;
    }
    
    # Prevent hotlinking (optional)
    valid_referers none blocked server_names *.yourdomain.com;
    if ($invalid_referer) {
        return 403;
    }
}
```

## Security Considerations

1. **File Type Validation**: Only image files are allowed (JPG, JPEG, PNG, GIF, WebP)
2. **MIME Type Checking**: Server validates actual MIME type, not just extension
3. **File Size Limits**: Configurable maximum file size (default 5MB)
4. **Authentication Required**: Only authenticated authors/admins can upload
5. **Unique Filenames**: UUIDs prevent filename conflicts and enumeration
6. **Path Traversal Protection**: Filenames are sanitized
7. **Hotlinking Protection**: Nginx configuration can prevent hotlinking

## Troubleshooting

### Common Issues

1. **"Permission denied" errors**:
   ```bash
   chmod 755 ./storage/uploads
   chown -R www-data:www-data ./storage/uploads  # For production
   ```

2. **"File too large" errors**:
   - Check `STORAGE_MAX_FILE_SIZE` environment variable
   - Check Nginx `client_max_body_size` setting
   - Check Go server timeout settings

3. **S3/MinIO connection issues**:
   - Verify MinIO is running: `docker-compose -f docker-compose.minio.yml ps`
   - Check bucket exists and is accessible
   - Verify credentials and endpoint URL

4. **Images not loading**:
   - For local storage: Check file permissions and path
   - For S3: Verify bucket policy allows public read access
   - Check CORS settings if accessing from browser

### Testing

Run the upload tests:

```bash
cd backend
go test ./tests -v -run TestUpload
```

Check upload info endpoint:

```bash
curl http://localhost:8080/api/v1/uploads/info
```

Test file upload:

```bash
curl -X POST \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -F "image=@test.jpg" \
  http://localhost:8080/api/v1/uploads/images
```
