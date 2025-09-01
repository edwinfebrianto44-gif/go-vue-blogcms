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
	Storage  StorageConfig
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

type StorageConfig struct {
	Driver      string
	UploadDir   string
	BaseURL     string
	MaxFileSize int64
	// S3/MinIO settings
	S3Endpoint   string
	S3Region     string
	S3Bucket     string
	S3AccessKey  string
	S3SecretKey  string
	S3BaseURL    string
	S3ForcePathStyle bool
}

func LoadConfig() *Config {
	// Load .env file if exists
	if err := godotenv.Load(); err != nil {
		log.Println("No .env file found, using environment variables")
	}

	maxFileSize, _ := strconv.ParseInt(getEnv("STORAGE_MAX_FILE_SIZE", "5242880"), 10, 64) // 5MB default

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
		Storage: StorageConfig{
			Driver:           getEnv("STORAGE_DRIVER", "local"),
			UploadDir:        getEnv("UPLOAD_DIR", "./storage/uploads"),
			BaseURL:          getEnv("BASE_URL", "http://localhost:8080"),
			MaxFileSize:      maxFileSize,
			S3Endpoint:       getEnv("S3_ENDPOINT", ""),
			S3Region:         getEnv("AWS_REGION", "us-east-1"),
			S3Bucket:         getEnv("S3_BUCKET_NAME", ""),
			S3AccessKey:      getEnv("AWS_ACCESS_KEY_ID", ""),
			S3SecretKey:      getEnv("AWS_SECRET_ACCESS_KEY", ""),
			S3BaseURL:        getEnv("S3_BASE_URL", ""),
			S3ForcePathStyle: getEnv("S3_FORCE_PATH_STYLE", "true") == "true",
		},
	}
}

func getEnv(key, defaultValue string) string {
	if value := os.Getenv(key); value != "" {
		return value
	}
	return defaultValue
}
