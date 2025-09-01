# Blog CMS API Documentation

## Base URL
```
http://localhost:8080/api/v1
```

## Authentication
All protected endpoints require a Bearer token in the Authorization header:
```
Authorization: Bearer <your_jwt_token>
```

## Endpoints

### Authentication

#### Register User
```http
POST /auth/register
```

**Request Body:**
```json
{
  "username": "johndoe",
  "email": "john@example.com",
  "password": "password123",
  "role": "author" // optional, defaults to "author"
}
```

**Response:**
```json
{
  "success": true,
  "message": "User registered successfully",
  "data": {
    "id": 1,
    "username": "johndoe",
    "email": "john@example.com",
    "role": "author",
    "created_at": "2025-09-01T10:00:00Z"
  }
}
```

#### Login
```http
POST /auth/login
```

**Request Body:**
```json
{
  "username": "johndoe",
  "password": "password123"
}
```

**Response:**
```json
{
  "success": true,
  "message": "Login successful",
  "data": {
    "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "user": {
      "id": 1,
      "username": "johndoe",
      "email": "john@example.com",
      "role": "author"
    }
  }
}
```

#### Get Profile
```http
GET /auth/profile
Authorization: Bearer <token>
```

### Categories

#### List Categories
```http
GET /categories?page=1&per_page=10
```

#### Get Category by ID
```http
GET /categories/{id}
```

#### Get Category by Slug
```http
GET /categories/slug/{slug}
```

#### Create Category (Admin Only)
```http
POST /categories
Authorization: Bearer <admin_token>
```

**Request Body:**
```json
{
  "name": "Technology",
  "description": "Tech-related articles"
}
```

#### Update Category (Admin Only)
```http
PUT /categories/{id}
Authorization: Bearer <admin_token>
```

#### Delete Category (Admin Only)
```http
DELETE /categories/{id}
Authorization: Bearer <admin_token>
```

### Posts

#### List Posts
```http
GET /posts?page=1&per_page=10&status=published&category_id=1
```

#### Get Post by ID
```http
GET /posts/{id}
```

#### Get Post by Slug
```http
GET /posts/slug/{slug}
```

#### Get Posts by Author
```http
GET /posts/author/{author_id}?page=1&per_page=10
```

#### Get Posts by Category
```http
GET /posts/category/{category_id}?page=1&per_page=10
```

#### Create Post
```http
POST /posts
Authorization: Bearer <token>
```

**Request Body:**
```json
{
  "title": "My First Post",
  "content": "This is the content of my first post...",
  "excerpt": "Short description",
  "category_id": 1,
  "status": "published" // optional, defaults to "draft"
}
```

#### Update Post
```http
PUT /posts/{id}
Authorization: Bearer <token>
```

**Note:** Authors can only update their own posts. Admins can update any post.

#### Delete Post
```http
DELETE /posts/{id}
Authorization: Bearer <token>
```

### Comments

#### List Comments
```http
GET /comments?page=1&per_page=10&status=approved&post_id=1
```

#### Get Comment by ID
```http
GET /comments/{id}
```

#### Get Comments by Post
```http
GET /comments/post/{post_id}?page=1&per_page=10
```

#### Get Comments by User
```http
GET /comments/user/{user_id}?page=1&per_page=10
```

#### Create Comment
```http
POST /comments
Authorization: Bearer <token>
```

**Request Body:**
```json
{
  "post_id": 1,
  "content": "Great article!"
}
```

#### Update Comment
```http
PUT /comments/{id}
Authorization: Bearer <token>
```

**Request Body:**
```json
{
  "content": "Updated comment content",
  "status": "approved" // only admins can change status
}
```

#### Delete Comment
```http
DELETE /comments/{id}
Authorization: Bearer <token>
```

## Error Responses

All endpoints return errors in this format:
```json
{
  "success": false,
  "message": "Error description",
  "error": "Detailed error message"
}
```

## HTTP Status Codes

- `200` - Success
- `201` - Created
- `400` - Bad Request
- `401` - Unauthorized
- `403` - Forbidden
- `404` - Not Found
- `500` - Internal Server Error

## Pagination Response Format

```json
{
  "success": true,
  "message": "Data retrieved successfully",
  "data": {
    "data": [...], // array of items
    "total": 100,
    "page": 1,
    "per_page": 10,
    "total_pages": 10
  }
}
```

## Role-Based Access Control

### Admin
- Full CRUD access to all resources
- Can manage categories
- Can change comment status
- Can edit/delete any post or comment

### Author
- Can create, read, update, delete their own posts
- Can create, read, update, delete their own comments
- Cannot manage categories
- Cannot change comment status

## Query Parameters

### Pagination
- `page` - Page number (default: 1)
- `per_page` - Items per page (default: 10, max: 100)

### Filters
- Posts: `status`, `category_id`
- Comments: `status`, `post_id`
