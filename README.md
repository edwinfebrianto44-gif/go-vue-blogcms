# Go Vue Blog CMS

A modern full-stack blog Content Management System built with Go (backend) and Vue.js (frontend) with complete Docker containerization for seamless deployment.

## ⚡ Quick Start (One Command Setup)

Get your blog running instantly with all services integrated:

```bash
# Clone and start everything
git clone <repository-url>
cd go-vue-blogcms
docker-compose up -d

# Access your application:
# 🌐 Frontend (Main App): http://localhost:3001
# 🔌 Backend API: http://localhost:8081  
# � MinIO Console: http://localhost:9001 (admin/minioadmin)
# � Production Nginx: http://localhost
```

**Ready in under 3 minutes with all services running!**

## 🌟 Features

### 🔧 **Backend (Go + Gin)**
- **RESTful API** with comprehensive endpoints
- **JWT Authentication** with refresh tokens
- **MySQL Database** with GORM ORM
- **Redis Caching** for performance optimization
- **MinIO Object Storage** for file uploads
- **Health Checks** and monitoring endpoints
- **Security Middleware** (CORS, validation, rate limiting)

### 🎨 **Frontend (Vue 3)**
- **Responsive SPA** with Vue Router
- **Modern UI** with Tailwind CSS
- **Pinia State Management** for data flow
- **Real-time API Integration** 
- **Production-ready** Nginx deployment
- **PWA Ready** with service workers

### 🐳 **Complete Docker Stack**
- **Multi-service orchestration** with unique ports
- **MySQL 8.0** database (port 3307)
- **Redis 7** caching layer (port 6380)
- **MinIO** object storage (ports 9001/9002)
- **Nginx** reverse proxy with SSL support
- **Auto health checks** and service dependencies
- **Persistent volumes** for data protection

## 🏗️ Architecture & Ports

```
┌─ Production Stack ─┐    ┌─ Development Ports ─┐
│                    │    │                      │
│  🌐 Nginx (80/443) │────│  Frontend :3001      │
│     │              │    │  Backend  :8081      │
│     ├─ Frontend    │    │  MySQL    :3307      │
│     └─ Backend API │    │  Redis    :6380      │
│                    │    │  MinIO    :9001/9002 │
│  🗄️ MySQL (3307)  │    │                      │
│  🚀 Redis (6380)   │    └──────────────────────┘
│  📁 MinIO (9001)   │
└────────────────────┘
```

### Service Details

| Service  | Internal | External | Purpose                    |
|----------|----------|----------|----------------------------|
| Frontend | 80       | 3001     | Vue.js SPA Application    |
| Backend  | 8080     | 8081     | Go API Server             |
| MySQL    | 3306     | 3307     | Primary Database          |
| Redis    | 6379     | 6380     | Caching & Sessions        |
| MinIO    | 9000/9001| 9001/9002| File Storage & Console    |
| Nginx    | 80/443   | 80/443   | Reverse Proxy & SSL       |

## 🛠️ Development Mode

### Backend Development
```bash
cd backend
go mod download
cp .env.example .env  # Configure your environment
go run cmd/server/main.go
# Backend available at: http://localhost:8080
```

### Frontend Development
```bash
cd frontend
npm install
npm run dev  # Development server with hot reload
# Frontend available at: http://localhost:5173
```

### Docker Development
```bash
# Start all services for development
docker-compose up -d

# View logs
docker-compose logs -f backend
docker-compose logs -f frontend

# Rebuild specific service
docker-compose build backend --no-cache
docker-compose up -d backend
```

## � Configuration

### Environment Variables

Create `.env` file in backend directory:
```env
# Database Configuration
DB_HOST=mysql
DB_PORT=3306
DB_USER=bloguser
DB_PASSWORD=blogpass
DB_NAME=blogcms

# JWT Configuration
JWT_SECRET=your-super-secret-jwt-key-change-this-in-production
JWT_EXPIRE_HOURS=24

# Redis Configuration
REDIS_HOST=redis
REDIS_PORT=6379
REDIS_PASSWORD=

# MinIO Configuration
MINIO_ENDPOINT=minio:9000
MINIO_ACCESS_KEY=minioadmin
MINIO_SECRET_KEY=minioadmin
MINIO_BUCKET=blog-uploads

# Server Configuration
SERVER_PORT=8080
CORS_ORIGINS=http://localhost:3001,http://localhost:5173
```

### Frontend Configuration

Update `frontend/src/services/api.js` if needed:
```javascript
const API_BASE_URL = import.meta.env.VITE_API_URL || 'http://localhost:8081/api'
```

## 📊 Database Schema

Complete MySQL schema with relationships:
- **users** - User authentication and profiles
- **posts** - Blog content with metadata
- **categories** - Content organization
- **comments** - User interactions and discussions
- **refresh_tokens** - Session management

Schema location: `backend/database_schema.sql`

## 📚 API Documentation

- **OpenAPI Specification**: `backend/docs/openapi.yaml`
- **Postman Collection**: `backend/docs/postman_collection.json`
- **Live API Docs**: http://localhost:8081/docs (when backend running)

### Quick API Examples

```bash
# Register new user
curl -X POST http://localhost:8081/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{"username":"john","email":"john@example.com","password":"password123"}'

# Login
curl -X POST http://localhost:8081/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"john@example.com","password":"password123"}'

# Create post (requires auth token)
curl -X POST http://localhost:8081/api/posts \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -d '{"title":"My Post","content":"Post content","category_id":1}'
```

## � Security Features

- **JWT Authentication** with refresh token rotation
- **Password Hashing** with bcrypt (cost 12)
- **CORS Middleware** with configurable origins
- **Request Validation** and input sanitization
- **SQL Injection Prevention** with GORM prepared statements
- **XSS Protection** headers and content security
- **Rate Limiting** middleware for API endpoints
- **Secure File Upload** validation and storage
- **Environment-based Secrets** management

## 🚀 Production Deployment

### Quick VPS Setup
```bash
# Download deployment scripts
wget https://raw.githubusercontent.com/your-repo/go-vue-blogcms/main/deployment/setup-vps.sh
chmod +x setup-vps.sh && ./setup-vps.sh

# Quick deploy
cd deployment && ./quick-deploy.sh
```

### Manual Production Steps

1. **Server Preparation (Ubuntu/Debian):**
```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh

# Install Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
```

2. **Deploy Application:**
```bash
# Clone repository
git clone <repository-url>
cd go-vue-blogcms

# Configure production environment
cp backend/.env.example backend/.env
# Edit backend/.env with production values

# Start all services
docker-compose up -d

# Verify deployment
docker-compose ps
docker-compose logs -f
```

3. **SSL Setup (Production):**
```bash
# Generate SSL certificates
cd deployment && ./generate-ssl.sh your-domain.com

# Update Nginx with SSL
docker-compose restart nginx
```

### Production Services

The production stack includes:
- **Frontend**: Nginx-served Vue.js SPA
- **Backend**: Go API server with health checks
- **MySQL**: Persistent database with custom configuration
- **Redis**: Session and cache storage
- **MinIO**: S3-compatible object storage
- **Nginx**: Reverse proxy with SSL termination

## 🔍 Troubleshooting

### Common Issues

**Port Conflicts:**
```bash
# Check port usage
sudo netstat -tulpn | grep :3001
# Stop conflicting services
docker-compose down
```

**Database Connection:**
```bash
# Check MySQL logs
docker-compose logs mysql
# Reset database
docker-compose down -v && docker-compose up -d
```

**Frontend Build Issues:**
```bash
# Clear and rebuild
cd frontend
rm -rf node_modules package-lock.json dist
npm install
docker-compose build frontend --no-cache
```

**Backend API Issues:**
```bash
# Check backend logs
docker-compose logs backend
# Restart backend service
docker-compose restart backend
```

### Health Check Endpoints

- **Backend Health**: `GET http://localhost:8081/health`
- **Frontend**: `GET http://localhost:3001` (returns index.html)
- **Database**: Automatic Docker health checks
- **Redis**: Automatic Docker health checks
- **MinIO**: `GET http://localhost:9001/minio/health/live`

### Log Monitoring

```bash
# View all logs
docker-compose logs

# Follow specific service
docker-compose logs -f backend
docker-compose logs -f frontend
docker-compose logs -f mysql

# Filter logs by timestamp
docker-compose logs --since="1h" backend
```

## 🤝 Contributing

We welcome contributions! Here's how to get started:

### Development Workflow

1. **Fork** the repository
2. **Clone** your fork: `git clone https://github.com/yourusername/go-vue-blogcms.git`
3. **Create** a feature branch: `git checkout -b feature/amazing-feature`
4. **Make** your changes with tests
5. **Commit** your changes: `git commit -m 'Add amazing feature'`
6. **Push** to the branch: `git push origin feature/amazing-feature`
7. **Submit** a pull request

### Code Standards

```bash
# Backend code quality
cd backend
go fmt ./...           # Format code
go vet ./...          # Static analysis
go test ./...         # Run tests

# Frontend code quality  
cd frontend
npm run lint          # ESLint checks
npm run format        # Prettier formatting
npm run test          # Unit tests
npm run build         # Build verification
```

### Testing

```bash
# Backend testing
cd backend && go test -v ./...

# Frontend testing
cd frontend && npm test

# Integration testing
docker-compose -f docker-compose.test.yml up --abort-on-container-exit
```

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## 🎯 Next Steps After Setup

1. **Create Admin Account**: Register your first admin user via API
2. **Add Content**: Start creating categories and blog posts
3. **Customize**: Modify themes, layouts, and branding
4. **Monitor**: Set up logging and performance monitoring
5. **Backup**: Configure automated database backups
6. **Scale**: Add load balancing and caching as needed

### Recommended Production Enhancements

- **SSL/TLS**: Configure Let's Encrypt for HTTPS
- **CDN**: Add CloudFlare or similar for global performance
- **Monitoring**: Implement Prometheus + Grafana for metrics
- **Logging**: Set up centralized logging with ELK stack
- **Backup**: Configure automated S3/cloud backups
- **Security**: Add WAF and DDoS protection

**Happy Blogging! 🎉**

---

*Built with ❤️ using Go, Vue.js, and Docker*

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
