package main

import (
	"flag"
	"os"
	"testing"
)

// Test configuration and setup
func TestMain(m *testing.M) {
	flag.Parse()
	
	// Set test environment
	os.Setenv("ENVIRONMENT", "test")
	os.Setenv("JWT_SECRET", "test-jwt-secret-key-for-testing-only")
	os.Setenv("JWT_ACCESS_DURATION", "15m")
	os.Setenv("JWT_REFRESH_DURATION", "24h")
	os.Setenv("ALLOWED_ORIGINS", "http://localhost:3000,http://localhost:5173")
	
	// Run tests
	code := m.Run()
	
	// Cleanup
	// Add any cleanup code here
	
	os.Exit(code)
}
