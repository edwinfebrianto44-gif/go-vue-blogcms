.PHONY: build run test clean dev docker-build docker-up docker-down migrate docs validate-docs generate-postman serve-docs docs-tools help

# Variables
BINARY_NAME=blogcms-server
BUILD_DIR=./build
MAIN_PATH=./cmd/server/main.go

# Default target
all: build

# Build the application
build:
	@echo "Building $(BINARY_NAME)..."
	@mkdir -p $(BUILD_DIR)
	go build -o $(BUILD_DIR)/$(BINARY_NAME) $(MAIN_PATH)

# Run the application in development mode
dev:
	@echo "Starting development server..."
	go run $(MAIN_PATH)

# Run the built binary
run: build
	@echo "Running $(BINARY_NAME)..."
	./$(BUILD_DIR)/$(BINARY_NAME)

# Install dependencies
deps:
	@echo "Installing Go dependencies..."
	go mod download
	go mod tidy

# Run all tests (Phase 11 - Comprehensive Testing)
test: deps
	@echo "🧪 Running all tests..."
	go test -race -timeout 300s ./...

# Test with coverage (Phase 11 requirement: 100% service coverage)
test-coverage: deps
	@echo "📊 Running tests with coverage..."
	go test -race -timeout 300s -coverprofile=coverage.out ./...
	go tool cover -html=coverage.out -o coverage.html
	@echo "Coverage report generated: coverage.html"
	@go tool cover -func=coverage.out | grep "total:" | awk '{print "Total coverage: " $$3}'

# Run unit tests only
test-unit: deps
	@echo "🔬 Running unit tests..."
	go test -race -timeout 60s -short ./internal/services/... ./internal/repositories/tests/...

# Run integration tests with MySQL containers
test-integration: deps
	@echo "🔗 Running integration tests..."
	go test -race -timeout 300s ./integration/...

# Run tests with verbose output
test-verbose: deps
	@echo "📝 Running tests with verbose output..."
	go test -race -timeout 300s -v ./...

# Test authentication features
test-auth:
	@echo "🔐 Running authentication tests..."
	go test -v ./internal/services/ -run TestAuthService

# Test security middleware
test-security:
	@echo "🛡️ Running security middleware tests..."
	go test -v ./tests/middleware_test.go

# Test Phase 6 security features
test-phase6:
	@echo "� Running Phase 6 security tests..."
	@$(MAKE) test-auth
	@$(MAKE) test-security
	@echo "✅ Phase 6 security tests completed"

# Phase 11 - Complete testing suite
test-phase11: deps
	@echo "🎯 Running Phase 11 comprehensive tests..."
	@echo "1️⃣ Unit tests for services..."
	@$(MAKE) test-unit
	@echo "2️⃣ Integration tests with MySQL containers..."
	@$(MAKE) test-integration
	@echo "3️⃣ HTTP endpoint tests..."
	go test -race -timeout 300s ./integration/... -run TestAPI
	@echo "4️⃣ Coverage analysis..."
	@$(MAKE) test-coverage
	@echo "✅ Phase 11 testing completed successfully!"

# Run tests using Docker containers for database dependencies
docker-test: deps
	@echo "🐳 Running tests with Docker containers..."
	docker run --rm -d --name test-mysql -e MYSQL_ROOT_PASSWORD=testpass -e MYSQL_DATABASE=testdb -p 3307:3306 mysql:8.0
	@echo "Waiting for MySQL to be ready..."
	@sleep 15
	@echo "Running tests..."
	MYSQL_TEST_DSN="root:testpass@tcp(localhost:3307)/testdb?charset=utf8mb4&parseTime=True&loc=Local" go test -race -timeout 300s ./...
	@echo "Cleaning up..."
	docker stop test-mysql || true

# Clean build artifacts
clean:
	@echo "Cleaning build artifacts..."
	rm -rf $(BUILD_DIR)
	rm -f coverage.out coverage.html

# Download dependencies
deps:
	@echo "Downloading dependencies..."
	go mod download
	go mod tidy

# Format code
fmt:
	@echo "Formatting code..."
	go fmt ./...

# Lint code
lint:
	@echo "Linting code..."
	golangci-lint run

# Initialize modules
mod-init:
	go mod init backend

# Build Docker image
docker-build:
	@echo "Building Docker image..."
	docker build -t blogcms-backend:latest .

# Start services with Docker Compose
docker-up:
	@echo "Starting services with Docker Compose..."
	docker-compose up -d

# Stop services
docker-down:
	@echo "Stopping services..."
	docker-compose down

# View logs
docker-logs:
	docker-compose logs -f

# Database migration (if using migrate tool)
migrate-up:
	@echo "Running database migrations..."
	migrate -path ./migrations -database "mysql://$(DB_USER):$(DB_PASSWORD)@tcp($(DB_HOST):$(DB_PORT))/$(DB_NAME)" up

migrate-down:
	@echo "Rolling back database migrations..."
	migrate -path ./migrations -database "mysql://$(DB_USER):$(DB_PASSWORD)@tcp($(DB_HOST):$(DB_PORT))/$(DB_NAME)" down

# Create new migration
migrate-create:
	@read -p "Enter migration name: " name; \
	migrate create -ext sql -dir ./migrations $$name

# Documentation commands
docs: ## Generate and validate all documentation
	@echo "📚 Generating documentation..."
	@$(MAKE) validate-docs
	@$(MAKE) generate-postman
	@echo "✅ Documentation generated and validated"

validate-docs: ## Validate OpenAPI specification
	@echo "🔍 Validating OpenAPI specification..."
	@if command -v swagger >/dev/null 2>&1; then \
		swagger validate docs/openapi.yaml && echo "✅ OpenAPI spec is valid"; \
	else \
		echo "⚠️  swagger-cli not found. Install with: npm install -g swagger-cli"; \
		echo "   Or use online validator: https://editor.swagger.io/"; \
	fi

generate-postman: ## Generate Postman collection from OpenAPI spec
	@echo "📋 Generating Postman collection..."
	@if command -v openapi2postman >/dev/null 2>&1; then \
		openapi2postman -s docs/openapi.yaml -o docs/postman_collection_generated.json && \
		echo "✅ Postman collection generated: docs/postman_collection_generated.json"; \
	else \
		echo "⚠️  openapi-to-postman not found. Using existing collection."; \
		echo "   Install with: npm install -g openapi-to-postman"; \
	fi

serve-docs: ## Serve documentation locally
	@echo "📖 Starting documentation server..."
	@echo "📚 Swagger UI will be available at: http://localhost:8080/api/v1/docs/swagger/"
	@echo "📄 OpenAPI spec available at: http://localhost:8080/api/v1/docs/openapi.yaml"
	@echo "🔍 Health check available at: http://localhost:8080/health"
	@$(MAKE) dev

docs-tools: ## Install documentation tools
	@echo "🛠️  Installing documentation tools..."
	@if command -v npm >/dev/null 2>&1; then \
		npm install -g swagger-cli openapi-to-postman; \
		echo "✅ Documentation tools installed"; \
	else \
		echo "❌ npm not found. Please install Node.js first"; \
	fi

# Help
help:
	@echo "Available commands:"
	@echo ""
	@echo "Build & Development:"
	@echo "  build         - Build the application"
	@echo "  dev           - Run in development mode"
	@echo "  run           - Run the built binary"
	@echo ""
	@echo "Testing & Quality:"
	@echo "  test          - Run tests"
	@echo "  test-coverage - Run tests with coverage"
	@echo "  test-auth     - Run authentication tests"
	@echo "  test-security - Run security middleware tests"
	@echo "  test-integration - Run integration tests"
	@echo "  test-phase6   - Run Phase 6 security tests"
	@echo "  fmt           - Format code"
	@echo "  lint          - Lint code"
	@echo ""
	@echo "Documentation:"
	@echo "  docs          - Generate and validate all documentation"
	@echo "  validate-docs - Validate OpenAPI specification"
	@echo "  generate-postman - Generate Postman collection"
	@echo "  serve-docs    - Start server with documentation"
	@echo "  docs-tools    - Install documentation tools"
	@echo ""
	@echo "Docker:"
	@echo "  docker-build  - Build Docker image"
	@echo "  docker-up     - Start with Docker Compose"
	@echo "  docker-down   - Stop Docker services"
	@echo "  docker-logs   - View Docker logs"
	@echo ""
	@echo "Database:"
	@echo "  migrate-up    - Run database migrations"
	@echo "  migrate-down  - Rollback migrations"
	@echo "  migrate-create- Create new migration"
	@echo ""
	@echo "Utilities:"
	@echo "  clean         - Clean build artifacts"
	@echo "  deps          - Download dependencies"
	@echo "  help          - Show this help"
