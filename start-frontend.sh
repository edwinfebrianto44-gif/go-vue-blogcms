#!/bin/bash

# Frontend development start script
echo "🚀 Starting Vue 3 Frontend Development Server..."

# Change to frontend directory
cd /workspaces/go-vue-blogcms/frontend

# Install dependencies if node_modules doesn't exist
if [ ! -d "node_modules" ]; then
    echo "📦 Installing dependencies..."
    npm install
fi

# Start development server
echo "🔥 Starting Vite development server..."
npm run dev
