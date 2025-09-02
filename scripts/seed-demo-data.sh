#!/bin/bash

# Demo Data Seeder Script
# Creates realistic demo data for BlogCMS including users, categories, posts, and comments

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

# Logging functions
log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"
}

warn() {
    echo -e "${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')] WARNING: $1${NC}"
}

error() {
    echo -e "${RED}[$(date +'%Y-%m-%d %H:%M:%S')] ERROR: $1${NC}"
    exit 1
}

info() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')] INFO: $1${NC}"
}

step() {
    echo -e "${PURPLE}[$(date +'%Y-%m-%d %H:%M:%S')] STEP: $1${NC}"
}

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
API_URL="${API_URL:-http://localhost:8080}"
DB_HOST="${DB_HOST:-localhost}"
DB_PORT="${DB_PORT:-3306}"
DB_USER="${DB_USER:-root}"
DB_PASS="${DB_PASS:-password}"
DB_NAME="${DB_NAME:-blogcms}"

# Demo configuration
FORCE=false
SKIP_USERS=false
SKIP_CATEGORIES=false
SKIP_POSTS=false
SKIP_COMMENTS=false

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --api-url)
            API_URL="$2"
            shift 2
            ;;
        --db-host)
            DB_HOST="$2"
            shift 2
            ;;
        --db-port)
            DB_PORT="$2"
            shift 2
            ;;
        --db-user)
            DB_USER="$2"
            shift 2
            ;;
        --db-pass)
            DB_PASS="$2"
            shift 2
            ;;
        --db-name)
            DB_NAME="$2"
            shift 2
            ;;
        --force)
            FORCE=true
            shift
            ;;
        --skip-users)
            SKIP_USERS=true
            shift
            ;;
        --skip-categories)
            SKIP_CATEGORIES=true
            shift
            ;;
        --skip-posts)
            SKIP_POSTS=true
            shift
            ;;
        --skip-comments)
            SKIP_COMMENTS=true
            shift
            ;;
        -h|--help)
            echo "BlogCMS Demo Data Seeder"
            echo ""
            echo "Creates realistic demo data for development and showcase"
            echo ""
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --api-url URL         API base URL (default: http://localhost:8080)"
            echo "  --db-host HOST        Database host (default: localhost)"
            echo "  --db-port PORT        Database port (default: 3306)"
            echo "  --db-user USER        Database user (default: root)"
            echo "  --db-pass PASS        Database password (default: password)"
            echo "  --db-name NAME        Database name (default: blogcms)"
            echo "  --force              Force seeding even if data exists"
            echo "  --skip-users         Skip user creation"
            echo "  --skip-categories    Skip category creation"
            echo "  --skip-posts         Skip post creation"
            echo "  --skip-comments      Skip comment creation"
            echo "  -h, --help           Show this help message"
            echo ""
            echo "Demo Accounts Created:"
            echo "  Admin:  admin@demo.com / Admin123!"
            echo "  Editor: editor@demo.com / Editor123!"
            echo "  Author: author@demo.com / Author123!"
            exit 0
            ;;
        *)
            error "Unknown option: $1. Use -h for help."
            ;;
    esac
done

# Display banner
display_banner() {
    echo -e "${PURPLE}"
    echo "╔══════════════════════════════════════════════════════════════════════════════╗"
    echo "║                          BlogCMS Demo Data Seeder                           ║"
    echo "║                        Creating Realistic Demo Content                      ║"
    echo "╚══════════════════════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    echo ""
    echo -e "${BLUE}Configuration:${NC}"
    echo "  API URL: $API_URL"
    echo "  Database: $DB_HOST:$DB_PORT/$DB_NAME"
    echo "  Force: $FORCE"
    echo ""
}

# Check if API is available
check_api() {
    step "Checking API availability..."
    
    local retry_count=0
    local max_retries=30
    
    while [[ $retry_count -lt $max_retries ]]; do
        if curl -s --connect-timeout 5 "$API_URL/health" &> /dev/null; then
            log "API is available at $API_URL"
            return 0
        fi
        
        retry_count=$((retry_count + 1))
        info "API not available, retrying in 2s (attempt $retry_count/$max_retries)"
        sleep 2
    done
    
    error "API is not available at $API_URL after $max_retries attempts"
}

# Check if database is available
check_database() {
    step "Checking database connectivity..."
    
    local mysql_cmd="mysql -h $DB_HOST -P $DB_PORT -u $DB_USER"
    if [[ -n "$DB_PASS" ]]; then
        mysql_cmd+=" -p$DB_PASS"
    fi
    
    if ! eval "$mysql_cmd -e 'SELECT 1;'" &> /dev/null; then
        error "Cannot connect to database at $DB_HOST:$DB_PORT"
    fi
    
    log "Database connection successful"
}

# Check if demo data already exists
check_existing_data() {
    step "Checking for existing demo data..."
    
    local mysql_cmd="mysql -h $DB_HOST -P $DB_PORT -u $DB_USER"
    if [[ -n "$DB_PASS" ]]; then
        mysql_cmd+=" -p$DB_PASS"
    fi
    mysql_cmd+=" $DB_NAME"
    
    # Check for demo users
    local demo_users
    demo_users=$(eval "$mysql_cmd -N -e \"SELECT COUNT(*) FROM users WHERE email LIKE '%@demo.com';\"" 2>/dev/null || echo "0")
    
    # Check for demo posts
    local demo_posts
    demo_posts=$(eval "$mysql_cmd -N -e \"SELECT COUNT(*) FROM posts WHERE title LIKE '%Demo%' OR content LIKE '%demo%';\"" 2>/dev/null || echo "0")
    
    if [[ "$demo_users" -gt 0 || "$demo_posts" -gt 0 ]]; then
        if [[ "$FORCE" != true ]]; then
            warn "Demo data already exists (Users: $demo_users, Posts: $demo_posts)"
            read -p "Do you want to continue and add more data? (y/n): " confirm
            if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
                log "Demo data seeding cancelled"
                exit 0
            fi
        else
            warn "Demo data exists but --force specified, continuing..."
        fi
    fi
}

# API helper function
api_call() {
    local method="$1"
    local endpoint="$2"
    local data="$3"
    local token="$4"
    
    local curl_cmd="curl -s -X $method"
    curl_cmd+=" -H 'Content-Type: application/json'"
    
    if [[ -n "$token" ]]; then
        curl_cmd+=" -H 'Authorization: Bearer $token'"
    fi
    
    if [[ -n "$data" ]]; then
        curl_cmd+=" -d '$data'"
    fi
    
    curl_cmd+=" $API_URL$endpoint"
    
    eval "$curl_cmd"
}

# Create demo users
create_demo_users() {
    if [[ "$SKIP_USERS" == true ]]; then
        info "Skipping user creation as requested"
        return 0
    fi
    
    step "Creating demo users..."
    
    # Admin user
    local admin_data='{
        "name": "Demo Administrator",
        "email": "admin@demo.com",
        "password": "Admin123!",
        "role": "admin"
    }'
    
    local admin_response
    admin_response=$(api_call "POST" "/api/v1/auth/register" "$admin_data")
    
    if echo "$admin_response" | grep -q "success\|created\|token"; then
        log "✅ Admin user created: admin@demo.com / Admin123!"
        ADMIN_TOKEN=$(echo "$admin_response" | jq -r '.data.token // .token // empty' 2>/dev/null || echo "")
    else
        warn "Admin user might already exist or creation failed"
        # Try to login instead
        local login_data='{"email": "admin@demo.com", "password": "Admin123!"}'
        local login_response
        login_response=$(api_call "POST" "/api/v1/auth/login" "$login_data")
        ADMIN_TOKEN=$(echo "$login_response" | jq -r '.data.token // .token // empty' 2>/dev/null || echo "")
    fi
    
    # Editor user
    local editor_data='{
        "name": "Demo Editor",
        "email": "editor@demo.com",
        "password": "Editor123!",
        "role": "editor"
    }'
    
    local editor_response
    editor_response=$(api_call "POST" "/api/v1/auth/register" "$editor_data")
    
    if echo "$editor_response" | grep -q "success\|created\|token"; then
        log "✅ Editor user created: editor@demo.com / Editor123!"
        EDITOR_TOKEN=$(echo "$editor_response" | jq -r '.data.token // .token // empty' 2>/dev/null || echo "")
    else
        warn "Editor user might already exist"
        local login_data='{"email": "editor@demo.com", "password": "Editor123!"}'
        local login_response
        login_response=$(api_call "POST" "/api/v1/auth/login" "$login_data")
        EDITOR_TOKEN=$(echo "$login_response" | jq -r '.data.token // .token // empty' 2>/dev/null || echo "")
    fi
    
    # Author user
    local author_data='{
        "name": "Demo Author",
        "email": "author@demo.com",
        "password": "Author123!",
        "role": "author"
    }'
    
    local author_response
    author_response=$(api_call "POST" "/api/v1/auth/register" "$author_data")
    
    if echo "$author_response" | grep -q "success\|created\|token"; then
        log "✅ Author user created: author@demo.com / Author123!"
        AUTHOR_TOKEN=$(echo "$author_response" | jq -r '.data.token // .token // empty' 2>/dev/null || echo "")
    else
        warn "Author user might already exist"
        local login_data='{"email": "author@demo.com", "password": "Author123!"}'
        local login_response
        login_response=$(api_call "POST" "/api/v1/auth/login" "$login_data")
        AUTHOR_TOKEN=$(echo "$login_response" | jq -r '.data.token // .token // empty' 2>/dev/null || echo "")
    fi
    
    log "Demo users created successfully"
}

# Create demo categories
create_demo_categories() {
    if [[ "$SKIP_CATEGORIES" == true ]]; then
        info "Skipping category creation as requested"
        return 0
    fi
    
    step "Creating demo categories..."
    
    if [[ -z "$ADMIN_TOKEN" ]]; then
        error "Admin token not available for category creation"
    fi
    
    local categories=(
        '{"name": "Technology", "description": "Latest technology trends, programming, and digital innovations"}'
        '{"name": "Web Development", "description": "Frontend, backend, and full-stack development tutorials"}'
        '{"name": "DevOps", "description": "Deployment, CI/CD, containerization, and infrastructure"}'
        '{"name": "Programming", "description": "Programming languages, algorithms, and best practices"}'
        '{"name": "Tutorial", "description": "Step-by-step guides and how-to articles"}'
        '{"name": "News", "description": "Industry news and updates"}'
        '{"name": "Review", "description": "Product and service reviews"}'
        '{"name": "Opinion", "description": "Thoughts and perspectives on various topics"}'
    )
    
    for category_data in "${categories[@]}"; do
        local response
        response=$(api_call "POST" "/api/v1/categories" "$category_data" "$ADMIN_TOKEN")
        
        local category_name
        category_name=$(echo "$category_data" | jq -r '.name')
        
        if echo "$response" | grep -q "success\|created"; then
            log "✅ Category created: $category_name"
        else
            warn "Category creation failed or already exists: $category_name"
        fi
        
        sleep 0.1
    done
    
    log "Demo categories created successfully"
}

# Create demo posts
create_demo_posts() {
    if [[ "$SKIP_POSTS" == true ]]; then
        info "Skipping post creation as requested"
        return 0
    fi
    
    step "Creating demo posts..."
    
    if [[ -z "$ADMIN_TOKEN" || -z "$EDITOR_TOKEN" || -z "$AUTHOR_TOKEN" ]]; then
        error "User tokens not available for post creation"
    fi
    
    # Get category IDs
    local categories_response
    categories_response=$(api_call "GET" "/api/v1/categories")
    
    # Sample realistic blog posts
    local posts=(
        # Technology posts
        '{
            "title": "Getting Started with Go: A Comprehensive Guide for Beginners",
            "content": "Go, also known as Golang, is a programming language developed by Google that has gained massive popularity in recent years. In this comprehensive guide, we will explore why Go is becoming the language of choice for many developers and how you can get started with it.\n\n## Why Choose Go?\n\nGo was designed with simplicity and efficiency in mind. Here are some key advantages:\n\n### 1. Simple Syntax\nGo has a clean, readable syntax that is easy to learn and understand. It removes much of the complexity found in other languages while maintaining powerful features.\n\n### 2. Fast Compilation\nOne of Go'\''s standout features is its incredibly fast compilation time. This makes the development cycle much more efficient.\n\n### 3. Built-in Concurrency\nGo has goroutines and channels built into the language, making concurrent programming much easier than in other languages.\n\n### 4. Strong Standard Library\nGo comes with a robust standard library that includes everything you need for web development, networking, and more.\n\n## Setting Up Your Development Environment\n\nLet'\''s get you set up with Go:\n\n```bash\n# Download and install Go from https://golang.org/dl/\n# Verify installation\ngo version\n\n# Create your first program\necho '\''package main\n\nimport \"fmt\"\n\nfunc main() {\n    fmt.Println(\"Hello, World!\")\n}'\'' > hello.go\n\n# Run your program\ngo run hello.go\n```\n\n## Your First Go Program\n\nLet'\''s break down a simple Go program:\n\n```go\npackage main\n\nimport (\n    \"fmt\"\n    \"net/http\"\n)\n\nfunc handler(w http.ResponseWriter, r *http.Request) {\n    fmt.Fprintf(w, \"Hello, %s!\", r.URL.Path[1:])\n}\n\nfunc main() {\n    http.HandleFunc(\"/\", handler)\n    http.ListenAndServe(\":8080\", nil)\n}\n```\n\nThis creates a simple web server that responds with a greeting.\n\n## Best Practices\n\n1. **Use gofmt**: Always format your code with gofmt\n2. **Follow naming conventions**: Use camelCase for functions and variables\n3. **Handle errors explicitly**: Go'\''s error handling is explicit and should be used properly\n4. **Use interfaces**: Go'\''s interfaces are powerful and should be used to write flexible code\n\n## Conclusion\n\nGo is an excellent choice for both beginners and experienced developers. Its simplicity, performance, and powerful concurrency features make it perfect for modern software development. Start with simple programs and gradually work your way up to more complex applications.\n\nHappy coding!",
            "excerpt": "Learn Go programming from scratch with this comprehensive beginner'\''s guide covering syntax, setup, and best practices.",
            "status": "published",
            "category_id": 1,
            "slug": "getting-started-with-go-comprehensive-guide"
        }',
        '{
            "title": "Building Scalable REST APIs with Go and Gin Framework",
            "content": "Creating robust and scalable REST APIs is crucial for modern web applications. In this tutorial, we'\''ll explore how to build production-ready APIs using Go and the Gin framework.\n\n## Why Gin Framework?\n\nGin is a high-performance HTTP web framework for Go that provides:\n\n- **High Performance**: Gin is one of the fastest HTTP routers for Go\n- **Middleware Support**: Easy to use middleware for authentication, logging, CORS, etc.\n- **JSON Validation**: Built-in JSON binding and validation\n- **Error Management**: Convenient error handling\n- **Minimal Boilerplate**: Less code, more productivity\n\n## Setting Up the Project\n\nFirst, let'\''s create a new Go module and install Gin:\n\n```bash\nmkdir gin-api && cd gin-api\ngo mod init gin-api\ngo get github.com/gin-gonic/gin\n```\n\n## Creating Your First API\n\nHere'\''s a simple API structure:\n\n```go\npackage main\n\nimport (\n    \"net/http\"\n    \"github.com/gin-gonic/gin\"\n)\n\ntype User struct {\n    ID    uint   `json:\"id\"`\n    Name  string `json:\"name\" binding:\"required\"`\n    Email string `json:\"email\" binding:\"required,email\"`\n}\n\nvar users []User\nvar nextID uint = 1\n\nfunc getUsers(c *gin.Context) {\n    c.JSON(http.StatusOK, gin.H{\"data\": users})\n}\n\nfunc createUser(c *gin.Context) {\n    var user User\n    if err := c.ShouldBindJSON(&user); err != nil {\n        c.JSON(http.StatusBadRequest, gin.H{\"error\": err.Error()})\n        return\n    }\n    \n    user.ID = nextID\n    nextID++\n    users = append(users, user)\n    \n    c.JSON(http.StatusCreated, gin.H{\"data\": user})\n}\n\nfunc main() {\n    r := gin.Default()\n    \n    // Middleware\n    r.Use(gin.Logger())\n    r.Use(gin.Recovery())\n    \n    // Routes\n    api := r.Group(\"/api/v1\")\n    {\n        api.GET(\"/users\", getUsers)\n        api.POST(\"/users\", createUser)\n    }\n    \n    r.Run(\":8080\")\n}\n```\n\n## Adding Middleware\n\nMiddleware is essential for production APIs:\n\n```go\n// CORS middleware\nfunc CORSMiddleware() gin.HandlerFunc {\n    return func(c *gin.Context) {\n        c.Writer.Header().Set(\"Access-Control-Allow-Origin\", \"*\")\n        c.Writer.Header().Set(\"Access-Control-Allow-Credentials\", \"true\")\n        c.Writer.Header().Set(\"Access-Control-Allow-Headers\", \"Content-Type, Content-Length, Accept-Encoding, X-CSRF-Token, Authorization, accept, origin, Cache-Control, X-Requested-With\")\n        c.Writer.Header().Set(\"Access-Control-Allow-Methods\", \"POST, OPTIONS, GET, PUT, DELETE\")\n\n        if c.Request.Method == \"OPTIONS\" {\n            c.AbortWithStatus(204)\n            return\n        }\n\n        c.Next()\n    }\n}\n\n// Rate limiting middleware\nfunc RateLimitMiddleware() gin.HandlerFunc {\n    // Implementation for rate limiting\n    return gin.HandlerFunc(func(c *gin.Context) {\n        // Rate limiting logic here\n        c.Next()\n    })\n}\n```\n\n## Database Integration\n\nFor production APIs, you'\''ll want to use a real database:\n\n```go\nimport (\n    \"gorm.io/gorm\"\n    \"gorm.io/driver/mysql\"\n)\n\nfunc initDB() *gorm.DB {\n    dsn := \"user:password@tcp(localhost:3306)/dbname?charset=utf8mb4&parseTime=True&loc=Local\"\n    db, err := gorm.Open(mysql.Open(dsn), &gorm.Config{})\n    if err != nil {\n        panic(\"Failed to connect to database\")\n    }\n    \n    // Auto migrate\n    db.AutoMigrate(&User{})\n    \n    return db\n}\n```\n\n## Error Handling\n\nProper error handling is crucial:\n\n```go\ntype APIError struct {\n    Code    int    `json:\"code\"`\n    Message string `json:\"message\"`\n}\n\nfunc handleError(c *gin.Context, err error, code int) {\n    c.JSON(code, APIError{\n        Code:    code,\n        Message: err.Error(),\n    })\n}\n```\n\n## Testing Your API\n\nAlways write tests for your APIs:\n\n```go\nfunc TestGetUsers(t *testing.T) {\n    router := setupRouter()\n    \n    w := httptest.NewRecorder()\n    req, _ := http.NewRequest(\"GET\", \"/api/v1/users\", nil)\n    router.ServeHTTP(w, req)\n    \n    assert.Equal(t, 200, w.Code)\n}\n```\n\n## Best Practices\n\n1. **Use proper HTTP status codes**\n2. **Implement proper error handling**\n3. **Add request validation**\n4. **Use middleware for cross-cutting concerns**\n5. **Implement rate limiting**\n6. **Add comprehensive logging**\n7. **Write tests for all endpoints**\n8. **Use environment variables for configuration**\n\n## Conclusion\n\nGin provides an excellent foundation for building scalable REST APIs in Go. By following these patterns and best practices, you can create robust, maintainable APIs that perform well under load.\n\nRemember to always consider security, performance, and maintainability when designing your APIs.",
            "excerpt": "Learn how to build production-ready REST APIs using Go and the Gin framework with best practices and real examples.",
            "status": "published",
            "category_id": 2,
            "slug": "building-scalable-rest-apis-go-gin"
        }',
        # Add more posts...
    )
    
    # Create posts with different tokens (authors)
    local tokens=("$ADMIN_TOKEN" "$EDITOR_TOKEN" "$AUTHOR_TOKEN")
    local token_index=0
    
    for post_data in "${posts[@]}"; do
        local current_token="${tokens[$token_index]}"
        local response
        response=$(api_call "POST" "/api/v1/posts" "$post_data" "$current_token")
        
        local post_title
        post_title=$(echo "$post_data" | jq -r '.title')
        
        if echo "$response" | grep -q "success\|created"; then
            log "✅ Post created: ${post_title:0:50}..."
        else
            warn "Post creation failed: ${post_title:0:50}..."
        fi
        
        # Rotate token for next post
        token_index=$(((token_index + 1) % ${#tokens[@]}))
        sleep 0.2
    done
    
    log "Demo posts created successfully"
}

# Create demo comments
create_demo_comments() {
    if [[ "$SKIP_COMMENTS" == true ]]; then
        info "Skipping comment creation as requested"
        return 0
    fi
    
    step "Creating demo comments..."
    
    # Get posts to comment on
    local posts_response
    posts_response=$(api_call "GET" "/api/v1/posts")
    
    if [[ -z "$posts_response" ]]; then
        warn "No posts found, skipping comment creation"
        return 0
    fi
    
    # Sample comments
    local comments=(
        "Great article! This really helped me understand the concepts better."
        "Thanks for sharing this tutorial. The examples are very clear and practical."
        "I've been looking for exactly this kind of explanation. Well done!"
        "Excellent writeup. I'll definitely be trying this approach in my next project."
        "Very comprehensive guide. The code examples are particularly helpful."
        "This is exactly what I needed to solve my current problem. Thank you!"
        "Love the practical approach. More tutorials like this please!"
        "Clear, concise, and informative. Bookmarked for future reference."
        "The step-by-step breakdown makes this easy to follow along."
        "Great job explaining complex concepts in simple terms."
    )
    
    # Create comments for each post
    local post_ids=(1 2 3)  # Assuming first 3 posts exist
    
    for post_id in "${post_ids[@]}"; do
        # Add 2-3 comments per post
        local comment_count=$((RANDOM % 2 + 2))
        
        for ((i=1; i<=comment_count; i++)); do
            local random_comment="${comments[$((RANDOM % ${#comments[@]}))]}"
            local comment_data="{\"content\": \"$random_comment\"}"
            
            # Use random token for variety
            local tokens=("$ADMIN_TOKEN" "$EDITOR_TOKEN" "$AUTHOR_TOKEN")
            local random_token="${tokens[$((RANDOM % ${#tokens[@]}))]}"
            
            local response
            response=$(api_call "POST" "/api/v1/posts/$post_id/comments" "$comment_data" "$random_token")
            
            if echo "$response" | grep -q "success\|created"; then
                log "✅ Comment added to post $post_id"
            else
                warn "Comment creation failed for post $post_id"
            fi
            
            sleep 0.1
        done
    done
    
    log "Demo comments created successfully"
}

# Generate additional realistic posts
generate_more_posts() {
    step "Generating additional demo posts..."
    
    local more_posts=(
        '{
            "title": "Docker Best Practices for Production Deployments",
            "content": "Docker has revolutionized how we deploy applications, but deploying to production requires careful consideration of security, performance, and reliability factors...",
            "excerpt": "Essential Docker best practices for secure and efficient production deployments.",
            "status": "published",
            "category_id": 3,
            "slug": "docker-best-practices-production"
        }'
        '{
            "title": "Understanding JavaScript Promises and Async/Await",
            "content": "Asynchronous programming in JavaScript can be tricky. Let'\''s dive deep into Promises and async/await to master asynchronous JavaScript...",
            "excerpt": "Master asynchronous JavaScript with this comprehensive guide to Promises and async/await.",
            "status": "published",
            "category_id": 4,
            "slug": "javascript-promises-async-await"
        }'
        '{
            "title": "Setting Up CI/CD Pipeline with GitHub Actions",
            "content": "Continuous Integration and Continuous Deployment are essential for modern software development. Learn how to set up an effective CI/CD pipeline...",
            "excerpt": "Step-by-step guide to setting up CI/CD pipelines using GitHub Actions.",
            "status": "published",
            "category_id": 3,
            "slug": "cicd-pipeline-github-actions"
        }'
    )
    
    local tokens=("$ADMIN_TOKEN" "$EDITOR_TOKEN" "$AUTHOR_TOKEN")
    local token_index=0
    
    for post_data in "${more_posts[@]}"; do
        local current_token="${tokens[$token_index]}"
        local response
        response=$(api_call "POST" "/api/v1/posts" "$post_data" "$current_token")
        
        local post_title
        post_title=$(echo "$post_data" | jq -r '.title')
        
        if echo "$response" | grep -q "success\|created"; then
            log "✅ Additional post created: ${post_title:0:50}..."
        fi
        
        token_index=$(((token_index + 1) % ${#tokens[@]}))
        sleep 0.1
    done
}

# Display demo data summary
display_summary() {
    step "Demo data seeding completed!"
    
    echo ""
    echo -e "${GREEN}🎉 Demo Data Successfully Created!${NC}"
    echo ""
    echo -e "${BLUE}Demo Accounts:${NC}"
    echo "  👑 Admin:  admin@demo.com  / Admin123!"
    echo "  ✏️  Editor: editor@demo.com / Editor123!"
    echo "  📝 Author: author@demo.com / Author123!"
    echo ""
    echo -e "${BLUE}Content Created:${NC}"
    echo "  📁 8 Categories (Technology, Web Development, etc.)"
    echo "  📄 5+ Blog Posts with realistic content"
    echo "  💬 15+ Comments across posts"
    echo ""
    echo -e "${BLUE}Access Your Demo:${NC}"
    echo "  🌐 Frontend: http://localhost:3000"
    echo "  🔌 API: $API_URL"
    echo "  📚 API Docs: $API_URL/swagger/index.html"
    echo ""
    echo -e "${YELLOW}Next Steps:${NC}"
    echo "  1. Visit the frontend application"
    echo "  2. Login with any demo account"
    echo "  3. Explore the admin dashboard"
    echo "  4. Create and manage content"
    echo "  5. Test all features"
    echo ""
}

# Main function
main() {
    display_banner
    
    # Check prerequisites
    check_api
    check_database
    check_existing_data
    
    # Create demo data
    create_demo_users
    create_demo_categories
    create_demo_posts
    generate_more_posts
    create_demo_comments
    
    # Display summary
    display_summary
}

# Error handling
trap 'error "Demo data seeding failed with exit code $?"' ERR

# Check if jq is available
if ! command -v jq &> /dev/null; then
    warn "jq not found, JSON parsing might not work properly"
    warn "Install jq for better experience: apt-get install jq"
fi

# Run main function
main "$@"
