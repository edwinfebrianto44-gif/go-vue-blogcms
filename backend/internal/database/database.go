package database

import (
	"fmt"
	"log"

	"backend/internal/config"
	"backend/internal/models"

	"gorm.io/driver/mysql"
	"gorm.io/gorm"
	"gorm.io/gorm/logger"
)

var DB *gorm.DB

// Connect initializes database connection with provided DSN
func Connect(dsn string) (*gorm.DB, error) {
	db, err := gorm.Open(mysql.Open(dsn), &gorm.Config{
		Logger: logger.Default.LogMode(logger.Info),
	})

	if err != nil {
		return nil, fmt.Errorf("failed to connect to database: %w", err)
	}

	log.Println("Database connected successfully")
	return db, nil
}

// AutoMigrate runs database migrations for the provided database instance
func AutoMigrate(db *gorm.DB) error {
	log.Println("Running database migrations...")
	
	err := db.AutoMigrate(
		&models.User{},
		&models.Category{},
		&models.Post{},
		&models.Comment{},
		&models.RefreshToken{},
		&models.FileUpload{},
	)
	
	if err != nil {
		return fmt.Errorf("migration failed: %w", err)
	}
	
	log.Println("Database migrations completed successfully")
	return nil
}

func InitDatabase(cfg *config.Config) {
	dsn := fmt.Sprintf("%s:%s@tcp(%s:%s)/%s?charset=utf8mb4&parseTime=True&loc=Local",
		cfg.Database.User,
		cfg.Database.Password,
		cfg.Database.Host,
		cfg.Database.Port,
		cfg.Database.Name,
	)

	var err error
	DB, err = gorm.Open(mysql.Open(dsn), &gorm.Config{
		Logger: logger.Default.LogMode(logger.Info),
	})

	if err != nil {
		log.Fatal("Failed to connect to database:", err)
	}

	// Set global DB variable for backward compatibility
	DB = db
	log.Println("Database connected successfully")

	// Auto migrate the schema
	if err := AutoMigrate(db); err != nil {
		log.Fatal("Failed to auto migrate:", err)
	}
}

func AutoMigrateOld() error {
	return AutoMigrate(DB)
}

func GetDB() *gorm.DB {
	return DB
}
