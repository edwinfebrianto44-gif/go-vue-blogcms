package config

import (
	"log"
	"os"
	"strconv"

	"github.com/joho/godotenv"
)

type Config struct {
	Database DatabaseConfig
	JWT      JWTConfig
	Server   ServerConfig
	App      AppConfig
}

type DatabaseConfig struct {
	Host     string
	Port     string
	User     string
	Password string
	Name     string
}

type JWTConfig struct {
	Secret      string
	ExpireHours int
}

type ServerConfig struct {
	Host string
	Port string
}

type AppConfig struct {
	Environment string
	Debug       bool
}

func LoadConfig() *Config {
	// Load .env file if exists
	if err := godotenv.Load(); err != nil {
		log.Println("No .env file found, using environment variables")
	}

	expireHours, _ := strconv.Atoi(getEnv("JWT_EXPIRE_HOURS", "24"))
	debug, _ := strconv.ParseBool(getEnv("APP_DEBUG", "false"))

	return &Config{
		Database: DatabaseConfig{
			Host:     getEnv("DB_HOST", "localhost"),
			Port:     getEnv("DB_PORT", "3306"),
			User:     getEnv("DB_USER", "root"),
			Password: getEnv("DB_PASS", ""),
			Name:     getEnv("DB_NAME", "blog_cms"),
		},
		JWT: JWTConfig{
			Secret:      getEnv("JWT_SECRET", "default-secret-key"),
			ExpireHours: expireHours,
		},
		Server: ServerConfig{
			Host: getEnv("SERVER_HOST", "localhost"),
			Port: getEnv("SERVER_PORT", "8080"),
		},
		App: AppConfig{
			Environment: getEnv("APP_ENV", "development"),
			Debug:       debug,
		},
	}
}

func getEnv(key, defaultValue string) string {
	if value := os.Getenv(key); value != "" {
		return value
	}
	return defaultValue
}
