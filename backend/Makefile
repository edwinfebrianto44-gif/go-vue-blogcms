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

# Run tests
test:
	@echo "Running tests..."
	go test -v ./...

# Test with coverage
test-coverage:
	@echo "Running tests with coverage..."
	go test -v -coverprofile=coverage.out ./...
	go tool cover -html=coverage.out -o coverage.html

# Test authentication features
test-auth:
	@echo "🔐 Running authentication tests..."
	go test -v ./tests/auth_test.go

# Test security middleware
test-security:
	@echo "🛡️ Running security middleware tests..."
	go test -v ./tests/middleware_test.go

# Test integration scenarios
test-integration:
	@echo "🔗 Running integration tests..."
	go test -v -tags=integration ./tests/...

# Test Phase 6 security features
test-phase6:
	@echo "🔒 Running Phase 6 security tests..."
	@$(MAKE) test-auth
	@$(MAKE) test-security
	@echo "✅ Phase 6 security tests completed"

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
