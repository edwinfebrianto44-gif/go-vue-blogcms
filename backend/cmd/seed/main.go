package main

import (
	"fmt"
	"log"
	"math/rand"
	"regexp"
	"strings"
	"time"

	"backend/internal/config"
	"backend/internal/database"
	"backend/internal/models"

	"gorm.io/gorm"
)

var sampleTitles = []string{
	"Getting Started with Go Programming",
	"Advanced JavaScript Techniques",
	"Docker Container Best Practices",
	"Machine Learning Fundamentals",
	"Web Security in Modern Applications",
	"Database Design Patterns",
	"API Development with REST",
	"Frontend Framework Comparison",
	"DevOps Automation Tools",
	"Cloud Computing Strategies",
	"Mobile App Development Trends",
	"Microservices Architecture Guide",
	"Data Visualization Techniques",
	"Software Testing Methodologies",
	"Performance Optimization Tips",
	"Cybersecurity Best Practices",
	"Blockchain Technology Overview",
	"AI and Neural Networks",
	"Open Source Development",
	"Code Review Strategies",
}

var sampleContents = []string{
	"Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.",
	"Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat.",
	"Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur.",
	"Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.",
	"Sed ut perspiciatis unde omnis iste natus error sit voluptatem accusantium doloremque laudantium.",
	"Totam rem aperiam, eaque ipsa quae ab illo inventore veritatis et quasi architecto beatae vitae dicta sunt.",
	"Explicabo nemo enim ipsam voluptatem quia voluptas sit aspernatur aut odit aut fugit.",
	"Sed quia consequuntur magni dolores eos qui ratione voluptatem sequi nesciunt.",
	"Neque porro quisquam est, qui dolorem ipsum quia dolor sit amet, consectetur, adipisci velit.",
	"Ut enim ad minima veniam, quis nostrum exercitationem ullam corporis suscipit laboriosam.",
}

var categoryNames = []string{
	"Technology", "Programming", "Web Development", "Mobile Development", 
	"DevOps", "Security", "Database", "AI/ML", "Cloud Computing", "Open Source",
}

func main() {
	// Load configuration
	cfg := config.Load()

	// Initialize database
	db, err := database.Connect(cfg)
	if err != nil {
		log.Fatal("Failed to connect to database:", err)
	}

	// Seed categories first
	if err := seedCategories(db); err != nil {
		log.Fatal("Failed to seed categories:", err)
	}

	// Seed users
	if err := seedUsers(db); err != nil {
		log.Fatal("Failed to seed users:", err)
	}

	// Seed posts
	if err := seedPosts(db, 1000); err != nil {
		log.Fatal("Failed to seed posts:", err)
	}

	fmt.Println("Database seeding completed successfully!")
}

func seedCategories(db *gorm.DB) error {
	var existingCount int64
	db.Model(&models.Category{}).Count(&existingCount)
	
	if existingCount > 0 {
		fmt.Printf("Categories already exist (%d), skipping...\n", existingCount)
		return nil
	}

	for i, name := range categoryNames {
		category := models.Category{
			Name:        name,
			Slug:        generateSlug(name),
			Description: fmt.Sprintf("Content related to %s", name),
			CreatedAt:   time.Now().Add(-time.Duration(i*24) * time.Hour),
			UpdatedAt:   time.Now().Add(-time.Duration(i*24) * time.Hour),
		}
		
		if err := db.Create(&category).Error; err != nil {
			return fmt.Errorf("failed to create category %s: %v", name, err)
		}
	}
	
	fmt.Printf("Created %d categories\n", len(categoryNames))
	return nil
}

func seedUsers(db *gorm.DB) error {
	var existingCount int64
	db.Model(&models.User{}).Count(&existingCount)
	
	if existingCount > 0 {
		fmt.Printf("Users already exist (%d), skipping...\n", existingCount)
		return nil
	}

	users := []models.User{
		{
			Username: "admin",
			Email:    "admin@example.com",
			Password: "$2a$10$4qY2.zjJhKj8MiL6DX0YJ.UjG7I9x9UlC3FhJ4q8m6h8nZ1pM5f1C", // password: "admin123"
			Role:     "admin",
			IsActive: true,
			CreatedAt: time.Now().Add(-30 * 24 * time.Hour),
			UpdatedAt: time.Now().Add(-30 * 24 * time.Hour),
		},
		{
			Username: "editor",
			Email:    "editor@example.com", 
			Password: "$2a$10$4qY2.zjJhKj8MiL6DX0YJ.UjG7I9x9UlC3FhJ4q8m6h8nZ1pM5f1C", // password: "admin123"
			Role:     "editor",
			IsActive: true,
			CreatedAt: time.Now().Add(-25 * 24 * time.Hour),
			UpdatedAt: time.Now().Add(-25 * 24 * time.Hour),
		},
		{
			Username: "author",
			Email:    "author@example.com",
			Password: "$2a$10$4qY2.zjJhKj8MiL6DX0YJ.UjG7I9x9UlC3FhJ4q8m6h8nZ1pM5f1C", // password: "admin123"
			Role:     "author",
			IsActive: true,
			CreatedAt: time.Now().Add(-20 * 24 * time.Hour),
			UpdatedAt: time.Now().Add(-20 * 24 * time.Hour),
		},
	}

	for _, user := range users {
		if err := db.Create(&user).Error; err != nil {
			return fmt.Errorf("failed to create user %s: %v", user.Username, err)
		}
	}
	
	fmt.Printf("Created %d users\n", len(users))
	return nil
}

func seedPosts(db *gorm.DB, count int) error {
	var existingCount int64
	db.Model(&models.Post{}).Count(&existingCount)
	
	if existingCount > 0 {
		fmt.Printf("Posts already exist (%d), skipping...\n", existingCount)
		return nil
	}

	// Get categories and users
	var categories []models.Category
	var users []models.User
	
	db.Find(&categories)
	db.Find(&users)
	
	if len(categories) == 0 || len(users) == 0 {
		return fmt.Errorf("need categories and users before creating posts")
	}

	rand.Seed(time.Now().UnixNano())
	
	fmt.Printf("Creating %d posts...\n", count)
	
	batchSize := 100
	for i := 0; i < count; i += batchSize {
		var posts []models.Post
		end := i + batchSize
		if end > count {
			end = count
		}
		
		for j := i; j < end; j++ {
			title := fmt.Sprintf("%s %d", sampleTitles[rand.Intn(len(sampleTitles))], j+1)
			content := fmt.Sprintf("%s\n\n%s\n\n%s", 
				sampleContents[rand.Intn(len(sampleContents))],
				sampleContents[rand.Intn(len(sampleContents))],
				sampleContents[rand.Intn(len(sampleContents))],
			)
			
			createdAt := time.Now().Add(-time.Duration(rand.Intn(365*24)) * time.Hour)
			
			post := models.Post{
				Title:       title,
				Slug:        generateSlug(title),
				Content:     content,
				Excerpt:     content[:100] + "...",
				Status:      getRandomStatus(),
				AuthorID:    users[rand.Intn(len(users))].ID,
				CategoryID:  categories[rand.Intn(len(categories))].ID,
				CreatedAt:   createdAt,
				UpdatedAt:   createdAt,
			}
			
			posts = append(posts, post)
		}
		
		if err := db.CreateInBatches(posts, batchSize).Error; err != nil {
			return fmt.Errorf("failed to create post batch: %v", err)
		}
		
		if (i+batchSize)%500 == 0 {
			fmt.Printf("Created %d posts...\n", i+batchSize)
		}
	}
	
	fmt.Printf("Created %d posts successfully\n", count)
	return nil
}

func generateSlug(title string) string {
	// Simple slug generation
	slug := strings.ToLower(title)
	slug = regexp.MustCompile(`[^a-z0-9\s-]`).ReplaceAllString(slug, "")
	slug = regexp.MustCompile(`\s+`).ReplaceAllString(slug, "-")
	slug = regexp.MustCompile(`-+`).ReplaceAllString(slug, "-")
	slug = strings.Trim(slug, "-")
	
	// Add timestamp to ensure uniqueness
	return fmt.Sprintf("%s-%d", slug, time.Now().Unix())
}

func getRandomStatus() string {
	statuses := []string{"published", "draft", "published", "published"} // More published posts
	return statuses[rand.Intn(len(statuses))]
}
