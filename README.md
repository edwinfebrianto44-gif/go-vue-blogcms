# 📝 BlogCMS - Modern Full-Stack Blog Management System

[![Go](https://img.shields.io/badge/Go-1.21+-00ADD8?style=flat&logo=go)](https://golang.org)
[![Vue.js](https://img.shields.io/badge/Vue.js-3.x-4FC08D?style=flat&logo=vue.js)](https://vuejs.org)
[![Docker](https://img.shields.io/badge/Docker-Ready-2496ED?style=flat&logo=docker)](https://docker.com)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

A production-ready, full-stack blog content management system with Go backend and Vue 3 frontend. Features enterprise-grade security, automated deployments, and comprehensive API documentation.

![BlogCMS Architecture](docs/images/architecture-overview.png)

## ⚡ Quick Start

Get BlogCMS running in under 2 minutes with demo data:

```bash
# Clone the repository
git clone https://github.com/yourusername/go-vue-blogcms.git
cd go-vue-blogcms

# Option 1: Quick demo setup (recommended)
./scripts/demo-setup.sh

# Option 2: Manual setup
docker compose up -d
./scripts/quick-seed.sh

# Access the application
# 🌐 Frontend: http://localhost:3000
# 🔌 API: http://localhost:8080
# 📚 API Docs: http://localhost:8080/swagger/index.html
```

### 👤 Demo Accounts
- **Admin**: `admin@demo.com` / `Admin123!` (Full access)
- **Editor**: `editor@demo.com` / `Editor123!` (Content management)
- **Author**: `author@demo.com` / `Author123!` (Write posts)

## 🌟 Features

### 🔧 **Backend (Go + Gin)**
- **Clean Architecture** - Repository + Service + Handler pattern
- **JWT Authentication** - Secure login with role-based access
- **RESTful API** - OpenAPI 3.0 documented endpoints
- **Database ORM** - GORM with auto-migrations
- **File Upload** - Image handling with validation
- **Observability** - Structured logging, metrics, health checks
- **Security** - Rate limiting, CORS, input validation

### 🎨 **Frontend (Vue 3 + TypeScript)**
- **Modern UI** - Responsive design with Tailwind CSS
- **State Management** - Pinia for reactive data flow
- **TypeScript** - Type-safe development experience
- **PWA Ready** - Service worker and offline support
- **Real-time** - WebSocket integration for live updates
- **SEO Optimized** - Meta tags and structured data

### 🗃️ **Database & Storage**
- **MySQL 8.0** - Relational database with ACID compliance
- **Auto Migrations** - Version-controlled schema updates
- **Soft Deletes** - Data preservation with recovery options
- **File Storage** - Local and cloud storage support
- **Backup System** - Automated daily backups to S3/MinIO

### 🚀 **DevOps & Production**
- **Docker Compose** - One-command deployment
- **CI/CD Pipeline** - GitHub Actions automation
- **SSL/TLS** - Let's Encrypt auto-renewal
- **Security Hardening** - UFW firewall + fail2ban
- **Monitoring** - Prometheus metrics + health endpoints
- **Backup Automation** - Multi-tier retention strategy

## 🏗️ Architecture

```

BlogCMS/
├── 🔧 Backend (Go)
│   ├── cmd/server/           # Application entry point
│   ├── internal/            # Private application code
│   │   ├── handlers/        # HTTP request handlers
│   │   ├── services/        # Business logic layer
│   │   ├── repositories/    # Data access layer
│   │   ├── models/          # Database entities
│   │   ├── middleware/      # HTTP middleware
│   │   └── utils/           # Helper utilities
│   ├── pkg/                 # Public libraries
│   │   ├── auth/            # Authentication utilities
│   │   ├── database/        # Database connection
│   │   ├── logger/          # Structured logging
│   │   ├── metrics/         # Prometheus metrics
│   │   └── validation/      # Input validation
│   └── migrations/          # Database migrations
│
├── 🎨 Frontend (Vue 3)
│   ├── src/
│   │   ├── components/      # Reusable Vue components
│   │   ├── views/           # Page components
│   │   ├── stores/          # Pinia state management
│   │   ├── composables/     # Vue composition functions
│   │   ├── types/           # TypeScript type definitions
│   │   └── utils/           # Frontend utilities
│   ├── public/              # Static assets
│   └── dist/                # Built frontend (generated)
│
├── 🐳 DevOps
│   ├── scripts/             # Production deployment scripts
│   ├── nginx/               # Web server configuration
│   ├── .github/workflows/   # CI/CD pipelines
│   └── docs/                # Comprehensive documentation
│
└── 📊 Data & Config
    ├── .env.example         # Environment template
    ├── docker-compose.yml   # Container orchestration
    └── init.sql             # Database initialization
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

## 🎯 Demo Data & Portfolio Assets

### Demo Data Seeding
BlogCMS includes comprehensive demo data for immediate showcase:

```bash
# Quick demo data (recommended for testing)
./scripts/quick-seed.sh

# Comprehensive demo data (full showcase)
./scripts/seed-demo-data.sh

# Complete demo setup (build + seed + open browser)
./scripts/demo-setup.sh --open-browser
```

**Demo Content Includes:**
- 👤 **3 User Roles**: Admin, Editor, Author with realistic permissions
- 📁 **8 Categories**: Technology, Web Development, DevOps, etc.
- 📝 **10+ Blog Posts**: Realistic technical content with proper formatting
- 💬 **25+ Comments**: Engaging user interactions across posts
- 🖼️ **Sample Images**: Properly sized and optimized media assets

### Portfolio Screenshots
Generate professional screenshots for your portfolio:

```bash
# Create screenshot resources and instructions
./scripts/generate-portfolio-assets.sh

# Manual screenshot guide
cat screenshots/README.md

# Automated screenshot capture (requires Node.js)
cd screenshots && npm install puppeteer && node capture-screenshots.js
```

**Screenshot Coverage:**
- 🏠 Homepage with blog feed
- 👑 Admin dashboard and management
- ✏️ Content editor and creation
- 📱 Mobile responsive views
- 🔌 API documentation interface
- 🎨 Dark/light theme variants

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

This project follows a comprehensive development lifecycle with validated phases:

### 🏗️ Development Phases
- ✅ **Phase 13**: Core functionality & API integration
- ✅ **Phase 14**: Production hardening & security
- ✅ **Phase 15**: Documentation & showcase readiness
- ✅ **Phase 16**: Performance & UX Polish

### 📊 Performance Optimization (Phase 16)

BlogCMS includes comprehensive performance optimizations for production deployment:

#### Server-Side Optimizations
- **Nginx Compression**: Gzip level 6 + Brotli support
- **Smart Caching**: Cache-control headers for static assets
- **Asset Optimization**: Long-term caching with invalidation

#### Frontend Optimizations  
- **Code Splitting**: Route-based lazy loading
- **Bundle Optimization**: Vendor chunk separation (Vue, Pinia, UI, Utils)
- **Asset Inlining**: Small files (<4KB) inlined for fewer requests
- **Minification**: Terser with console removal in production

#### UX Enhancements
- **Skeleton Loading**: Animated placeholders for all major views
- **Loading States**: Centralized loading management with `useLoading` composable
- **Smooth Transitions**: Enhanced user experience with proper loading feedback

#### Performance Monitoring
- **Lighthouse Audits**: Automated performance testing
- **Bundle Analysis**: Size tracking and optimization recommendations
- **Core Web Vitals**: FCP, LCP, CLS, TTI monitoring

#### Performance Tools
```bash
# Run comprehensive performance audit
./scripts/performance-audit.sh

# Analyze bundle sizes and get optimization tips  
./scripts/bundle-analysis.sh

# Apply all performance optimizations
./scripts/optimize-performance.sh
```

**Performance Targets Achieved:**
- 🎯 Bundle size optimized with intelligent chunking
- 🎯 TTI improved through lazy loading and code splitting
- 🎯 UX enhanced with skeleton components and smooth loading states
- 🎯 Lighthouse-ready with automated performance auditing

### Current Development Tasks

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
