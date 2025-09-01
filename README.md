# BlogCMS - Full-Stack Blog Content Management System

A modern, full-stack blog CMS built with Go backend and Vue 3 frontend, featuring clean architecture, responsive design, and production-ready deployment.

## 🌟 Overview

BlogCMS is a comprehensive content management system designed for bloggers, content creators, and organizations who need a robust, scalable blogging platform. It combines a powerful Go backend with a modern Vue 3 frontend to deliver excellent performance and user experience.
- `backend/` contains the Go API server
- `frontend/` will contain the Vue.js application (coming soon)

## 🚀 Features

### Backend (Go + Gin)
- **Clean Architecture** (Repository + Service + Handler pattern)
- **JWT Authentication** (Login, Register, Protected routes)
- **Role-based Access Control** (Admin, Author)
- **RESTful API** with JSON responses
- **Database ORM** using GORM
- **Pagination** support
- **Input Validation**
- **CORS Support**
- **Docker Support**

### Database
- **MySQL** with GORM ORM
- **Auto Migration** support
- **Soft Delete** implementation
- **Foreign Key Constraints**
- **Optimized Indexes**

### Frontend (Vue.js) - Coming Soon
- **Vue 3** with Composition API
- **Vite** for fast development and building
- **Tailwind CSS** for styling
- **Pinia** for state management
- **Vue Router** for routing
- **TypeScript** support
- **PWA** capabilities
- **Responsive Design**

### API Features
- **CRUD Operations** for Posts, Categories, Comments
- **User Management** with role-based permissions
- **Content Moderation** (Comment approval)
- **SEO-friendly Slugs**
- **Content Status** (Draft, Published, Archived)

## 📁 Project Structure

```
.
├── backend/                       # Backend Go application
│   ├── cmd/
│   │   └── server/
│   │       └── main.go           # Application entry point
│   ├── internal/
│   │   ├── config/
│   │   │   └── config.go         # Configuration management
│   │   ├── database/
│   │   │   └── database.go       # Database connection & migration
│   │   ├── models/
│   │   │   ├── models.go         # Data models
│   │   │   └── dto.go            # Request/Response DTOs
│   │   ├── repositories/
│   │   │   ├── user_repository.go     # User data access
│   │   │   ├── post_repository.go     # Post data access
│   │   │   ├── category_repository.go # Category data access
│   │   │   └── comment_repository.go  # Comment data access
│   │   ├── services/
│   │   │   ├── auth_service.go        # Authentication logic
│   │   │   ├── post_service.go        # Post business logic
│   │   │   ├── category_service.go    # Category business logic
│   │   │   └── comment_service.go     # Comment business logic
│   │   ├── handlers/
│   │   │   ├── middleware.go          # JWT & CORS middleware
│   │   │   ├── auth_handler.go        # Auth endpoints
│   │   │   ├── post_handler.go        # Post endpoints
│   │   │   ├── category_handler.go    # Category endpoints
│   │   │   └── comment_handler.go     # Comment endpoints
│   │   └── routes/
│   │       └── routes.go              # Route definitions
│   ├── pkg/
│   │   └── utils/
│   │       ├── jwt.go                 # JWT utilities
│   │       ├── password.go            # Password hashing
│   │       └── helpers.go             # Helper functions
│   ├── go.mod                        # Go module definition
│   ├── go.sum                        # Go module checksums (auto-generated)
│   ├── .env.example                  # Environment variables template
│   ├── .gitignore                    # Git ignore for backend
│   ├── Dockerfile                    # Docker configuration for development
│   ├── docker-compose.yml           # Docker Compose for development
│   ├── Makefile                     # Build automation for backend
│   ├── README.md                    # Backend documentation
│   └── database_schema.sql          # Complete database schema
├── deployment/                       # Production deployment configuration
│   ├── nginx/
│   │   ├── conf.d/
│   │   │   └── blog-api.conf        # Nginx virtual host
│   │   └── nginx.conf               # Nginx main configuration
│   ├── mysql/
│   │   └── conf.d/
│   │       └── mysql.cnf            # MySQL optimization
│   ├── Dockerfile                   # Production Dockerfile
│   ├── docker-compose.yml          # Production Docker Compose
│   ├── .env.production              # Production environment template
│   ├── setup-vps.sh                # VPS setup script
│   ├── deploy.sh                   # Deployment script
│   ├── quick-deploy.sh             # One-command deployment
│   ├── backup.sh                   # Database backup script
│   ├── monitor.sh                  # System monitoring script
│   ├── generate-ssl.sh             # SSL certificate generator
│   ├── README.md                   # Deployment documentation
│   └── QUICK_START.md              # Quick deployment guide
├── frontend/                         # Frontend Vue.js application (coming soon)
├── .gitignore                        # Global git ignore
├── API_DOCUMENTATION.md             # API documentation
├── DATABASE_README.md               # Database documentation
└── README.md                        # This file (main project documentation)
```

## 🛠️ Tech Stack

### Backend
- **Go 1.21+**
- **Gin Web Framework** - HTTP router and middleware
- **GORM** - ORM for database operations
- **JWT-Go** - JSON Web Token implementation
- **Bcrypt** - Password hashing
- **Godotenv** - Environment variable management

### Database
- **MySQL 8.0+**

### DevOps
- **Docker** & **Docker Compose**
- **Makefile** for build automation

## 📋 Prerequisites

- Go 1.21 or higher
- MySQL 8.0 or higher
- Docker (optional)
- Git

## 🚀 Quick Start

### 1. Clone the Repository
```bash
git clone https://github.com/your-username/go-vue-blogcms.git
cd go-vue-blogcms
```

### 2. Setup Backend Environment
```bash
# Navigate to backend directory
cd backend

# Copy environment file
cp .env.example .env

# Edit the .env file with your configuration
nano .env
```

### 3. Install Backend Dependencies
```bash
# From the backend directory
go mod download
```

### 4. Setup Database
```bash
# Create MySQL database
mysql -u root -p -e "CREATE DATABASE blog_cms;"

# Run migrations (from backend directory)
mysql -u root -p blog_cms < database_schema.sql
```

### 5. Run the Backend Application
```bash
# From the backend directory
go run cmd/server/main.go

# Or using Makefile
make run
```

The API will be available at `http://localhost:8080`

## 🐳 Docker Setup

### Using Docker Compose (Recommended for Development)
```bash
# Navigate to backend directory
cd backend

# Start all services (MySQL + API + phpMyAdmin)
docker-compose up -d

# View logs
docker-compose logs -f

# Stop services
docker-compose down
```

Services:
- **API**: http://localhost:8080
- **phpMyAdmin**: http://localhost:8081
- **MySQL**: localhost:3306

### Using Docker only
```bash
# Navigate to backend directory
cd backend

# Build image
docker build -t go-vue-blogcms .

# Run container
docker run -p 8080:8080 --env-file .env go-vue-blogcms
```

## 🚀 Production Deployment (VPS)

### Quick Deploy (One Command)
```bash
# On your Ubuntu VPS
curl -fsSL https://raw.githubusercontent.com/your-username/go-vue-blogcms/main/deployment/quick-deploy.sh | bash -s your-domain.com
```

### Manual Deployment
```bash
# 1. Setup VPS
wget https://raw.githubusercontent.com/your-username/go-vue-blogcms/main/deployment/setup-vps.sh
chmod +x setup-vps.sh && ./setup-vps.sh

# 2. Clone and deploy
sudo mkdir -p /opt/blogcms && sudo chown $USER:$USER /opt/blogcms
cd /opt/blogcms
git clone https://github.com/your-username/go-vue-blogcms.git .
cd deployment && cp .env.production .env
# Edit .env with your domain and secure passwords
./deploy.sh
```

**Production Features:**
- ✅ Nginx reverse proxy with SSL
- ✅ Let's Encrypt SSL certificates
- ✅ MySQL with persistent storage
- ✅ Adminer database management
- ✅ Automated backups
- ✅ System monitoring
- ✅ Security best practices

See `deployment/README.md` for detailed deployment guide.

## 🔧 Configuration

Environment variables in `.env`:

```env
# Database
DB_HOST=localhost
DB_PORT=3306
DB_USER=root
DB_PASS=password
DB_NAME=blog_cms

# JWT
JWT_SECRET=your-super-secret-jwt-key
JWT_EXPIRE_HOURS=24

# Server
SERVER_PORT=8080
SERVER_HOST=localhost

# App
APP_ENV=development
APP_DEBUG=true
```

## 📚 API Documentation

Detailed API documentation is available in [API_DOCUMENTATION.md](./API_DOCUMENTATION.md).

### Quick API Examples

#### Register User
```bash
curl -X POST http://localhost:8080/api/v1/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "username": "johndoe",
    "email": "john@example.com",
    "password": "password123"
  }'
```

#### Login
```bash
curl -X POST http://localhost:8080/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "username": "johndoe",
    "password": "password123"
  }'
```

#### Create Post
```bash
curl -X POST http://localhost:8080/api/v1/posts \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -d '{
    "title": "My First Post",
    "content": "This is my first blog post!",
    "category_id": 1
  }'
```

## 🧪 Testing

```bash
# Navigate to backend directory
cd backend

# Run tests
make test

# Or directly with go
go test -v ./...
```

## 📦 Available Make Commands (Backend)

Navigate to the `backend` directory first: `cd backend`

```bash
make build         # Build the application
make run           # Run the application
make dev           # Run with auto-reload (requires air)
make test          # Run tests
make clean         # Clean build artifacts
make deps          # Install dependencies
make migrate       # Run database migrations
make docker-build  # Build Docker image
make docker-run    # Run Docker container
make init          # Initialize project (copy .env)
make fmt           # Format code
make lint          # Lint code (requires golangci-lint)
make install-tools # Install development tools
make help          # Show all commands
```

## 🔐 Authentication & Authorization

### User Roles
- **Admin**: Full access to all resources
- **Author**: Can manage their own posts and comments

### Protected Endpoints
- All endpoints under `/auth/profile`
- All POST, PUT, DELETE operations
- Category management (Admin only)

### JWT Token
- Expires in 24 hours (configurable)
- Contains user ID, username, and role
- Required in Authorization header: `Bearer <token>`

## 🗄️ Database Schema

The database consists of 4 main tables:

1. **users** - User accounts and authentication
2. **categories** - Post categories
3. **posts** - Blog posts/articles
4. **comments** - Post comments

Detailed database documentation is available in [DATABASE_README.md](./DATABASE_README.md).

## 🔄 Development Workflow

1. **Fork** the repository
2. **Create** a feature branch (`git checkout -b feature/amazing-feature`)
3. **Commit** your changes (`git commit -m 'Add amazing feature'`)
4. **Push** to the branch (`git push origin feature/amazing-feature`)
5. **Open** a Pull Request

## 📝 Code Style

- Follow Go best practices and conventions
- Use `gofmt` for code formatting
- Run `golangci-lint` for code quality
- Write tests for new features
- Document public functions and structs

## 🚧 Roadmap

- [ ] Unit and integration tests
- [ ] API rate limiting
- [ ] File upload for images
- [ ] Email notifications
- [ ] Search functionality
- [ ] Caching with Redis
- [ ] Swagger documentation
- [ ] Vue.js frontend
- [ ] Admin dashboard
- [ ] Content versioning

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the Project
2. Create your Feature Branch
3. Commit your Changes
4. Push to the Branch
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 📞 Support

If you have any questions or need help, please:

1. Check the [API Documentation](./API_DOCUMENTATION.md)
2. Check the [Database Documentation](./DATABASE_README.md)
3. Open an issue on GitHub
4. Contact the maintainer

## 🙏 Acknowledgments

- [Gin Web Framework](https://gin-gonic.com/)
- [GORM](https://gorm.io/)
- [JWT-Go](https://github.com/golang-jwt/jwt)
- [Go](https://golang.org/)

---

**Happy Coding! 🎉**
