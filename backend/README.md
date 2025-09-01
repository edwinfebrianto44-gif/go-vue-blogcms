# Blog CMS Backend

Backend API untuk aplikasi Blog CMS yang dibangun dengan Go dan Gin framework menggunakan clean architecture pattern.

## 🚀 Features

- **Authentication & Authorization**: JWT-based authentication dengan role-based access control (Admin/Author)
- **User Management**: Registrasi, login, dan profile management
- **Post Management**: CRUD operations untuk blog posts dengan slug support
- **Category Management**: Kategori posts dengan hierarchical structure support
- **Comment System**: Sistem komentar dengan moderasi
- **Search & Filter**: Pencarian posts berdasarkan kategori, author, dan keyword
- **Pagination**: Support pagination untuk semua list endpoints
- **Database**: MySQL dengan GORM ORM dan auto-migration
- **Security**: Password hashing dengan bcrypt, CORS middleware
- **Docker**: Containerization dengan Docker dan Docker Compose

## 🏗️ Architecture

Proyek ini menggunakan **Clean Architecture** pattern dengan struktur sebagai berikut:

```
backend/
├── cmd/
│   └── server/
│       └── main.go              # Application entry point
├── internal/
│   ├── config/
│   │   └── config.go            # Configuration management
│   ├── database/
│   │   └── database.go          # Database connection & migration
│   ├── models/
│   │   ├── models.go            # Data models
│   │   └── dto.go               # Request/Response DTOs
│   ├── repositories/
│   │   ├── user_repository.go   # User data access layer
│   │   ├── post_repository.go   # Post data access layer
│   │   ├── category_repository.go # Category data access layer
│   │   └── comment_repository.go # Comment data access layer
│   ├── services/
│   │   ├── auth_service.go      # Authentication business logic
│   │   ├── post_service.go      # Post business logic
│   │   ├── category_service.go  # Category business logic
│   │   └── comment_service.go   # Comment business logic
│   ├── handlers/
│   │   ├── auth_handler.go      # HTTP handlers for auth
│   │   ├── post_handler.go      # HTTP handlers for posts
│   │   ├── category_handler.go  # HTTP handlers for categories
│   │   └── comment_handler.go   # HTTP handlers for comments
│   ├── middleware/
│   │   └── middleware.go        # JWT auth, CORS, admin-only middleware
│   └── routes/
│       └── routes.go            # Route definitions
├── pkg/
│   └── utils/
│       ├── jwt.go               # JWT utilities
│       ├── password.go          # Password hashing utilities
│       └── helpers.go           # Helper utilities
├── go.mod                       # Go module definition
├── .env.example                 # Environment variables template
├── Dockerfile                   # Docker configuration for development
├── docker-compose.yml          # Docker Compose for development
├── Makefile                     # Build automation
├── README.md                    # Backend documentation
└── database_schema.sql          # Complete database schema
```

## 📋 Requirements

- Go 1.21+
- MySQL 8.0+
- Docker & Docker Compose (optional)

## 🛠️ Installation

### Local Development

1. **Clone repository**
   ```bash
   git clone <repository-url>
   cd go-vue-blogcms/backend
   ```

2. **Install dependencies**
   ```bash
   make deps
   ```

3. **Setup environment variables**
   ```bash
   cp .env.example .env
   # Edit .env file dengan konfigurasi yang sesuai
   ```

4. **Setup database**
   - Buat database MySQL dengan nama `blogcms`
   - Import schema dari `../database_schema.sql`

5. **Run application**
   ```bash
   make dev
   ```

### Docker Development

1. **Setup environment**
   ```bash
   cp .env.example .env
   ```

2. **Start services**
   ```bash
   make docker-up
   ```

3. **View logs**
   ```bash
   make docker-logs
   ```

## 📚 API Documentation

### Base URL
```
http://localhost:8080/api/v1
```

### Authentication Endpoints

#### Register
```http
POST /auth/register
Content-Type: application/json

{
  "name": "John Doe",
  "email": "john@example.com",
  "password": "password123",
  "role": "author"
}
```

#### Login
```http
POST /auth/login
Content-Type: application/json

{
  "email": "john@example.com",
  "password": "password123"
}
```

#### Get Profile
```http
GET /auth/profile
Authorization: Bearer <jwt_token>
```

### Posts Endpoints

#### List Posts
```http
GET /posts?page=1&limit=10&category_id=1&author_id=2&search=keyword
```

#### Get Post by ID
```http
GET /posts/:id
```

#### Get Post by Slug
```http
GET /posts/slug/:slug
```

#### Create Post (Requires Auth)
```http
POST /posts
Authorization: Bearer <jwt_token>
Content-Type: application/json

{
  "title": "Post Title",
  "content": "Post content here...",
  "summary": "Brief summary",
  "category_id": 1,
  "status": "published"
}
```

#### Update Post (Requires Auth + Ownership)
```http
PUT /posts/:id
Authorization: Bearer <jwt_token>
Content-Type: application/json

{
  "title": "Updated Title",
  "content": "Updated content...",
  "summary": "Updated summary",
  "category_id": 2,
  "status": "published"
}
```

#### Delete Post (Requires Auth + Ownership)
```http
DELETE /posts/:id
Authorization: Bearer <jwt_token>
```

### Categories Endpoints

#### List Categories
```http
GET /categories
```

#### Get Category by ID
```http
GET /categories/:id
```

#### Get Category by Slug
```http
GET /categories/slug/:slug
```

#### Create Category (Admin Only)
```http
POST /categories
Authorization: Bearer <jwt_token>
Content-Type: application/json

{
  "name": "Technology",
  "description": "Tech related posts"
}
```

### Comments Endpoints

#### List Comments by Post
```http
GET /comments/post/:post_id?page=1&limit=10
```

#### Create Comment (Requires Auth)
```http
POST /comments
Authorization: Bearer <jwt_token>
Content-Type: application/json

{
  "post_id": 1,
  "content": "Great post!"
}
```

## 🔧 Available Commands

```bash
# Development
make dev              # Run in development mode
make build            # Build the application
make run              # Run the built binary
make test             # Run tests
make test-coverage    # Run tests with coverage

# Code Quality
make fmt              # Format code
make lint             # Lint code

# Docker
make docker-build     # Build Docker image
make docker-up        # Start with Docker Compose
make docker-down      # Stop Docker services
make docker-logs      # View logs

# Utilities
make clean            # Clean build artifacts
make deps             # Download dependencies
make help             # Show all commands
```

## 🔐 Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `PORT` | Server port | `8080` |
| `ENVIRONMENT` | Environment mode | `development` |
| `DATABASE_URL` | MySQL connection string | Required |
| `JWT_SECRET` | JWT signing secret | Required |

## 🗄️ Database Schema

Database terdiri dari 4 tabel utama:
- **users**: User accounts dengan role-based access
- **categories**: Post categories
- **posts**: Blog posts dengan relasi ke users dan categories
- **comments**: User comments pada posts

Lihat `../database_schema.sql` untuk schema lengkap dengan sample data.

## 🚦 Health Check

```http
GET /health
```

Response:
```json
{
  "status": "ok",
  "message": "Blog CMS API is running"
}
```

## 📝 Response Format

### Success Response
```json
{
  "success": true,
  "message": "Operation successful",
  "data": { ... }
}
```

### Error Response
```json
{
  "success": false,
  "error": "Error message",
  "details": "Detailed error information"
}
```

### Pagination Response
```json
{
  "success": true,
  "data": [...],
  "pagination": {
    "page": 1,
    "limit": 10,
    "total": 100,
    "total_pages": 10
  }
}
```

## 🧪 Testing

```bash
# Run all tests
make test

# Run tests with coverage
make test-coverage

# Run specific test
go test -v ./internal/services/...
```

## 🐳 Docker

### Development dengan Docker Compose
```bash
# Start semua services (MySQL + Backend + phpMyAdmin)
make docker-up

# Stop semua services
make docker-down

# View logs
make docker-logs
```

Services yang akan berjalan:
- **Backend API**: http://localhost:8080
- **MySQL**: localhost:3306
- **phpMyAdmin**: http://localhost:8081

## 🔒 Security Features

- **Password Hashing**: Menggunakan bcrypt dengan cost 14
- **JWT Authentication**: Stateless authentication dengan expiry
- **Role-based Access Control**: Admin dan Author roles
- **CORS Protection**: Configured untuk development dan production
- **Input Validation**: Comprehensive validation untuk semua endpoints
- **SQL Injection Prevention**: Menggunakan GORM parameterized queries

## 🚀 Deployment

### Production Build
```bash
# Build optimized binary
CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o main ./cmd/server

# Atau menggunakan Dockerfile
docker build -t blogcms-backend:latest .
```

### Environment Setup untuk Production
```bash
# Set production environment variables
export ENVIRONMENT=production
export JWT_SECRET=<strong-random-secret>
export DATABASE_URL=<production-database-url>
```

## 🤝 Contributing

1. Fork repository
2. Buat feature branch (`git checkout -b feature/amazing-feature`)
3. Commit changes (`git commit -m 'Add amazing feature'`)
4. Push ke branch (`git push origin feature/amazing-feature`)
5. Open Pull Request

## 📄 License

This project is licensed under the MIT License.

## 👥 Authors

- **Your Name** - Initial work

## 🆘 Support

Jika mengalami masalah, silakan buat issue di repository atau hubungi tim development.
