#!/bin/bash

# Quick Demo Data Seeder for Docker Compose Environment
# Simple script to populate BlogCMS with demo data after docker-compose up

set -e

echo "🌱 BlogCMS Quick Demo Data Seeder"
echo "=================================="

# Wait for services to be ready
echo "⏳ Waiting for services to start..."
sleep 10

# Check if API is responding
echo "🔍 Checking API health..."
for i in {1..30}; do
    if curl -s http://localhost:8080/health &> /dev/null; then
        echo "✅ API is ready!"
        break
    fi
    
    if [ $i -eq 30 ]; then
        echo "❌ API not responding after 60 seconds"
        exit 1
    fi
    
    echo "   Waiting for API... (attempt $i/30)"
    sleep 2
done

# Create admin user
echo "👤 Creating admin user..."
curl -s -X POST http://localhost:8080/api/v1/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Demo Administrator",
    "email": "admin@demo.com",
    "password": "Admin123!",
    "role": "admin"
  }' > /dev/null

# Get admin token
echo "🔐 Getting admin token..."
ADMIN_TOKEN=$(curl -s -X POST http://localhost:8080/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "admin@demo.com",
    "password": "Admin123!"
  }' | jq -r '.data.token // .token' 2>/dev/null || echo "")

if [ -z "$ADMIN_TOKEN" ] || [ "$ADMIN_TOKEN" = "null" ]; then
    echo "❌ Failed to get admin token"
    exit 1
fi

echo "✅ Admin token obtained"

# Create categories
echo "📁 Creating categories..."
curl -s -X POST http://localhost:8080/api/v1/categories \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -d '{"name": "Technology", "description": "Latest technology trends and innovations"}' > /dev/null

curl -s -X POST http://localhost:8080/api/v1/categories \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -d '{"name": "Web Development", "description": "Frontend and backend development tutorials"}' > /dev/null

curl -s -X POST http://localhost:8080/api/v1/categories \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -d '{"name": "Tutorial", "description": "Step-by-step guides and how-to articles"}' > /dev/null

echo "✅ Categories created"

# Create sample posts
echo "📝 Creating demo posts..."

# Post 1
curl -s -X POST http://localhost:8080/api/v1/posts \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -d '{
    "title": "Welcome to BlogCMS Demo",
    "content": "# Welcome to BlogCMS!\n\nThis is a demo blog post to showcase the capabilities of our BlogCMS system.\n\n## Features\n\n- **User Management**: Admin, Editor, and Author roles\n- **Content Management**: Create, edit, and publish blog posts\n- **Categories**: Organize content with categories\n- **Comments**: Engage with readers through comments\n- **Responsive Design**: Works on all devices\n\n## Getting Started\n\nYou can log in with these demo accounts:\n\n- **Admin**: admin@demo.com / Admin123!\n- **Editor**: editor@demo.com / Editor123!\n- **Author**: author@demo.com / Author123!\n\n## Technology Stack\n\n- **Backend**: Go with Gin framework\n- **Frontend**: Vue.js 3 with Composition API\n- **Database**: MySQL\n- **Deployment**: Docker & Docker Compose\n\nEnjoy exploring the demo!",
    "excerpt": "Welcome to BlogCMS demo! Explore our content management system with demo accounts and sample data.",
    "status": "published",
    "category_id": 1
  }' > /dev/null

# Post 2
curl -s -X POST http://localhost:8080/api/v1/posts \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -d '{
    "title": "Building Modern Web Applications with Go and Vue.js",
    "content": "# Building Modern Web Applications\n\nCombining Go for the backend and Vue.js for the frontend creates a powerful stack for modern web applications.\n\n## Why Go?\n\n- **Performance**: Compiled language with excellent performance\n- **Simplicity**: Clean syntax and easy to learn\n- **Concurrency**: Built-in support for concurrent programming\n- **Standard Library**: Comprehensive standard library\n\n## Why Vue.js?\n\n- **Progressive**: Can be adopted incrementally\n- **Reactive**: Reactive data binding\n- **Component-based**: Reusable components\n- **Ecosystem**: Rich ecosystem with Vue Router, Vuex, etc.\n\n## Project Structure\n\n```\nblogcms/\n├── backend/\n│   ├── main.go\n│   ├── models/\n│   ├── handlers/\n│   └── middleware/\n├── frontend/\n│   ├── src/\n│   ├── components/\n│   └── views/\n└── docker-compose.yml\n```\n\n## Best Practices\n\n1. **API Design**: RESTful APIs with proper HTTP methods\n2. **Error Handling**: Consistent error responses\n3. **Authentication**: JWT tokens for secure authentication\n4. **Validation**: Input validation on both frontend and backend\n5. **Testing**: Comprehensive test coverage\n\nThis combination provides a solid foundation for building scalable web applications.",
    "excerpt": "Learn how to build modern web applications using Go backend and Vue.js frontend with best practices and real examples.",
    "status": "published",
    "category_id": 2
  }' > /dev/null

echo "✅ Demo posts created"

# Create additional users
echo "👥 Creating additional demo users..."

curl -s -X POST http://localhost:8080/api/v1/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Demo Editor",
    "email": "editor@demo.com",
    "password": "Editor123!",
    "role": "editor"
  }' > /dev/null

curl -s -X POST http://localhost:8080/api/v1/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Demo Author",
    "email": "author@demo.com",
    "password": "Author123!",
    "role": "author"
  }' > /dev/null

echo "✅ Additional users created"

echo ""
echo "🎉 Demo data seeding completed!"
echo ""
echo "📋 Demo Accounts:"
echo "   👑 Admin:  admin@demo.com  / Admin123!"
echo "   ✏️  Editor: editor@demo.com / Editor123!"
echo "   📝 Author: author@demo.com / Author123!"
echo ""
echo "🌐 Access your application:"
echo "   Frontend: http://localhost:3000"
echo "   API:      http://localhost:8080"
echo "   Docs:     http://localhost:8080/swagger/index.html"
echo ""
echo "✨ Happy blogging!"
