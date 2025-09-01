# Multi-stage build untuk optimasi ukuran image
FROM golang:1.21-alpine AS builder

# Install dependencies yang diperlukan
RUN apk add --no-cache git ca-certificates tzdata

# Set working directory
WORKDIR /app

# Copy go mod files dari backend
COPY ../backend/go.mod ../backend/go.sum ./

# Download dependencies
RUN go mod download

# Copy source code dari backend
COPY ../backend/ .

# Build aplikasi dengan optimasi
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build \
    -ldflags='-w -s -extldflags "-static"' \
    -a -installsuffix cgo \
    -o main ./cmd/server

# Final stage - image production minimal
FROM alpine:3.18

# Install ca-certificates untuk HTTPS dan timezone data
RUN apk --no-cache add ca-certificates tzdata && \
    addgroup -g 1001 -S appgroup && \
    adduser -u 1001 -S appuser -G appgroup

# Set timezone ke Asia/Jakarta
ENV TZ=Asia/Jakarta

# Create app directory and storage directory
WORKDIR /app

# Create storage directories with proper permissions
RUN mkdir -p /app/storage/uploads && \
    chown -R appuser:appgroup /app/storage && \
    chmod -R 755 /app/storage

# Copy binary dari builder stage
COPY --from=builder /app/main .
COPY --from=builder /app/database_schema.sql .

# Change ownership
RUN chown -R appuser:appgroup /app

# Switch ke non-root user untuk keamanan
USER appuser

# Expose port
EXPOSE 8080

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=30s --retries=3 \
    CMD wget --no-verbose --tries=1 --spider http://localhost:8080/health || exit 1

# Command to run
CMD ["./main"]
