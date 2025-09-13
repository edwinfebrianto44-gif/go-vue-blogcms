-- ====================================
-- Blog CMS Database Schema
-- ====================================

-- Drop database if exists and create new one
DROP DATABASE IF EXISTS blogcms;
CREATE DATABASE blogcms;
USE blogcms;

-- ====================================
-- Table: users
-- ====================================
CREATE TABLE users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(50) NOT NULL UNIQUE,
    email VARCHAR(100) NOT NULL UNIQUE,
    password VARCHAR(255) NOT NULL,
    role ENUM('admin', 'author') NOT NULL DEFAULT 'author',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- ====================================
-- Table: categories
-- ====================================
CREATE TABLE categories (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    slug VARCHAR(100) NOT NULL UNIQUE,
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- ====================================
-- Table: posts
-- ====================================
CREATE TABLE posts (
    id INT AUTO_INCREMENT PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    slug VARCHAR(255) NOT NULL UNIQUE,
    content TEXT NOT NULL,
    excerpt TEXT,
    thumbnail_url VARCHAR(500),
    category_id INT NOT NULL,
    author_id INT NOT NULL,
    status ENUM('draft', 'published', 'archived') DEFAULT 'draft',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (category_id) REFERENCES categories(id) ON DELETE CASCADE,
    FOREIGN KEY (author_id) REFERENCES users(id) ON DELETE CASCADE,
    
    -- Full-text search index for title and content
    FULLTEXT KEY idx_posts_fulltext (title, content),
    FULLTEXT KEY idx_posts_title_fulltext (title),
    FULLTEXT KEY idx_posts_content_fulltext (content)
);

-- ====================================
-- Table: comments
-- ====================================
CREATE TABLE comments (
    id INT AUTO_INCREMENT PRIMARY KEY,
    post_id INT NOT NULL,
    user_id INT NOT NULL,
    content TEXT NOT NULL,
    status ENUM('pending', 'approved', 'rejected') DEFAULT 'pending',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (post_id) REFERENCES posts(id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

-- ====================================
-- Create Indexes for better performance
-- ====================================

-- Posts table indexes
CREATE INDEX idx_posts_category_id ON posts(category_id);
CREATE INDEX idx_posts_author_id ON posts(author_id);
CREATE INDEX idx_posts_status ON posts(status);
CREATE INDEX idx_posts_created_at ON posts(created_at);
CREATE INDEX idx_posts_updated_at ON posts(updated_at);
CREATE INDEX idx_posts_status_created_at ON posts(status, created_at);
CREATE INDEX idx_posts_category_status ON posts(category_id, status);
CREATE INDEX idx_posts_author_status ON posts(author_id, status);

-- Categories table indexes  
CREATE INDEX idx_categories_created_at ON categories(created_at);

-- Comments table indexes
CREATE INDEX idx_comments_post_id ON comments(post_id);
CREATE INDEX idx_comments_user_id ON comments(user_id);
CREATE INDEX idx_comments_status ON comments(status);
CREATE INDEX idx_comments_created_at ON comments(created_at);

-- Users table indexes
CREATE INDEX idx_users_role ON users(role);
CREATE INDEX idx_users_created_at ON users(created_at);

-- ====================================
-- Insert Data Dummy
-- ====================================

-- Insert users (20 records)
INSERT INTO users (username, email, password, role) VALUES
('admin', 'admin@blogcms.com', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'admin'),
('john_doe', 'john.doe@example.com', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'author'),
('jane_smith', 'jane.smith@example.com', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'author'),
('mike_wilson', 'mike.wilson@example.com', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'author'),
('sarah_connor', 'sarah.connor@example.com', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'admin'),
('david_brown', 'david.brown@example.com', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'author'),
('lisa_taylor', 'lisa.taylor@example.com', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'author'),
('robert_johnson', 'robert.johnson@example.com', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'author'),
('emily_davis', 'emily.davis@example.com', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'author'),
('chris_anderson', 'chris.anderson@example.com', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'author'),
('amanda_white', 'amanda.white@example.com', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'author'),
('kevin_martin', 'kevin.martin@example.com', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'author'),
('jennifer_garcia', 'jennifer.garcia@example.com', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'author'),
('daniel_lee', 'daniel.lee@example.com', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'author'),
('michelle_clark', 'michelle.clark@example.com', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'author'),
('jason_rodriguez', 'jason.rodriguez@example.com', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'author'),
('stephanie_walker', 'stephanie.walker@example.com', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'author'),
('thomas_hall', 'thomas.hall@example.com', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'author'),
('nicole_young', 'nicole.young@example.com', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'author'),
('matthew_king', 'matthew.king@example.com', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'author');

-- Insert categories (20 records)
INSERT INTO categories (name, slug, description) VALUES
('Technology', 'technology', 'Articles about latest technology trends and innovations'),
('Programming', 'programming', 'Coding tutorials, tips, and programming languages'),
('Web Development', 'web-development', 'Frontend and backend web development topics'),
('Mobile Development', 'mobile-development', 'iOS and Android app development'),
('Database', 'database', 'Database design, optimization, and management'),
('DevOps', 'devops', 'Deployment, CI/CD, and infrastructure topics'),
('Security', 'security', 'Cybersecurity, data protection, and privacy'),
('AI & Machine Learning', 'ai-machine-learning', 'Artificial intelligence and ML algorithms'),
('Data Science', 'data-science', 'Data analysis, visualization, and statistics'),
('Cloud Computing', 'cloud-computing', 'AWS, Google Cloud, Azure, and cloud services'),
('Blockchain', 'blockchain', 'Cryptocurrency, DeFi, and blockchain technology'),
('UI/UX Design', 'ui-ux-design', 'User interface and user experience design'),
('Gaming', 'gaming', 'Game development and gaming industry news'),
('Business', 'business', 'Entrepreneurship, startups, and business strategy'),
('Marketing', 'marketing', 'Digital marketing, SEO, and content strategy'),
('Lifestyle', 'lifestyle', 'Personal development and work-life balance'),
('Travel', 'travel', 'Travel tips, destinations, and experiences'),
('Health', 'health', 'Wellness, fitness, and mental health topics'),
('Education', 'education', 'Learning resources and educational content'),
('News', 'news', 'Industry news and current events');

-- Insert posts (20 records)
INSERT INTO posts (title, slug, content, excerpt, category_id, author_id, status) VALUES
('Getting Started with Go Programming', 'getting-started-go-programming', 'Go, also known as Golang, is a statically typed, compiled programming language designed at Google. In this comprehensive guide, we will explore the basics of Go programming, including syntax, data types, functions, and more. Go is known for its simplicity, efficiency, and excellent support for concurrent programming.', 'Learn the fundamentals of Go programming language', 2, 2, 'published'),
('Building RESTful APIs with Vue.js Frontend', 'building-restful-apis-vue-frontend', 'Creating modern web applications requires a solid understanding of both backend APIs and frontend frameworks. In this tutorial, we will build a complete RESTful API and connect it to a Vue.js frontend application. We will cover authentication, data validation, and best practices.', 'Complete guide to building APIs with Vue.js frontend', 3, 3, 'published'),
('Database Design Best Practices', 'database-design-best-practices', 'Proper database design is crucial for application performance and maintainability. This article covers normalization, indexing strategies, foreign key relationships, and common pitfalls to avoid when designing your database schema.', 'Essential tips for effective database design', 5, 4, 'published'),
('Introduction to Docker and Containerization', 'introduction-docker-containerization', 'Docker has revolutionized how we deploy and manage applications. Learn the basics of containerization, Docker images, containers, and how to use Docker in your development workflow.', 'Get started with Docker containers', 6, 5, 'published'),
('Cybersecurity Fundamentals for Developers', 'cybersecurity-fundamentals-developers', 'Security should be a top priority in every development project. This guide covers essential security practices, common vulnerabilities, and how to protect your applications from attacks.', 'Essential security practices for developers', 7, 6, 'published'),
('Machine Learning with Python', 'machine-learning-python', 'Python is one of the most popular languages for machine learning. In this comprehensive tutorial, we explore popular ML libraries like scikit-learn, pandas, and numpy to build predictive models.', 'Learn ML with Python libraries', 8, 7, 'published'),
('Data Visualization Techniques', 'data-visualization-techniques', 'Effective data visualization is key to understanding complex datasets. We explore various charting libraries and techniques to create compelling visual representations of your data.', 'Master data visualization techniques', 9, 8, 'published'),
('AWS Cloud Services Overview', 'aws-cloud-services-overview', 'Amazon Web Services offers a vast array of cloud computing services. This guide provides an overview of essential AWS services including EC2, S3, RDS, and Lambda.', 'Complete overview of AWS services', 10, 9, 'published'),
('Understanding Blockchain Technology', 'understanding-blockchain-technology', 'Blockchain technology goes beyond cryptocurrency. Learn about distributed ledgers, smart contracts, and real-world applications of blockchain technology.', 'Comprehensive guide to blockchain', 11, 10, 'published'),
('Modern UI/UX Design Principles', 'modern-ui-ux-design-principles', 'Creating user-friendly interfaces requires understanding of design principles, user psychology, and current trends. This article covers essential UI/UX concepts for modern applications.', 'Essential UI/UX design principles', 12, 11, 'published'),
('Game Development with Unity', 'game-development-unity', 'Unity is a powerful game development platform. Learn the basics of game development, including scripting, physics, animation, and publishing your games across multiple platforms.', 'Start your game development journey', 13, 12, 'published'),
('Startup Business Strategy', 'startup-business-strategy', 'Building a successful startup requires more than just a good idea. Learn about market validation, business models, funding options, and scaling strategies for your startup.', 'Essential startup business strategies', 14, 13, 'published'),
('Digital Marketing in 2025', 'digital-marketing-2025', 'Digital marketing continues to evolve rapidly. Stay ahead with the latest trends in social media marketing, content strategy, SEO, and paid advertising.', 'Latest digital marketing trends', 15, 14, 'published'),
('Work-Life Balance for Developers', 'work-life-balance-developers', 'Maintaining a healthy work-life balance is crucial for long-term career success. Learn strategies to manage stress, improve productivity, and maintain personal well-being.', 'Achieve better work-life balance', 16, 15, 'published'),
('Travel Photography Tips', 'travel-photography-tips', 'Capture stunning travel photos with these professional tips and techniques. Learn about composition, lighting, equipment, and post-processing for amazing travel photography.', 'Professional travel photography guide', 17, 16, 'published'),
('Mental Health and Wellness', 'mental-health-wellness', 'Mental health is just as important as physical health. This article discusses strategies for maintaining mental wellness, managing stress, and seeking help when needed.', 'Guide to mental health and wellness', 18, 17, 'published'),
('Online Learning Best Practices', 'online-learning-best-practices', 'Online education has become increasingly popular. Learn effective strategies for online learning, time management, and getting the most out of digital educational resources.', 'Maximize your online learning experience', 19, 18, 'published'),
('Tech Industry News Roundup', 'tech-industry-news-roundup', 'Stay updated with the latest developments in the technology industry. This weekly roundup covers major announcements, product launches, and industry trends.', 'Latest tech industry updates', 20, 19, 'published'),
('Advanced JavaScript Techniques', 'advanced-javascript-techniques', 'Take your JavaScript skills to the next level with advanced concepts including closures, prototypes, async/await, and modern ES6+ features.', 'Master advanced JavaScript concepts', 2, 20, 'published'),
('Mobile App Performance Optimization', 'mobile-app-performance-optimization', 'Learn techniques to optimize your mobile applications for better performance, reduced battery usage, and improved user experience across different devices.', 'Optimize your mobile app performance', 4, 2, 'published');

-- Insert comments (20 records)
INSERT INTO comments (post_id, user_id, content, status) VALUES
(1, 3, 'Great introduction to Go! Very helpful for beginners like me.', 'approved'),
(1, 4, 'I have been looking for a comprehensive Go tutorial. This is exactly what I needed.', 'approved'),
(2, 5, 'The Vue.js examples are really well explained. Thanks for sharing!', 'approved'),
(2, 6, 'Could you provide more examples of authentication implementation?', 'approved'),
(3, 7, 'Database design is often overlooked. This article highlights important concepts.', 'approved'),
(3, 8, 'The normalization examples really helped me understand the concept better.', 'approved'),
(4, 9, 'Docker has been a game-changer for our development workflow.', 'approved'),
(4, 10, 'Clear explanation of containerization concepts. Very useful!', 'approved'),
(5, 11, 'Security should indeed be a priority. Thanks for the practical tips.', 'approved'),
(5, 12, 'This article opened my eyes to several security vulnerabilities I wasn\'t aware of.', 'approved'),
(6, 13, 'Python ML libraries are amazing. Great tutorial!', 'approved'),
(6, 14, 'The code examples are very helpful for understanding the concepts.', 'approved'),
(7, 15, 'Data visualization is an art. These techniques are really valuable.', 'approved'),
(8, 16, 'AWS can be overwhelming, but this overview makes it much clearer.', 'approved'),
(9, 17, 'Blockchain technology has so much potential beyond cryptocurrency.', 'approved'),
(10, 18, 'UI/UX design principles are fundamental. Great article!', 'approved'),
(11, 19, 'Unity is such a powerful platform for game development.', 'approved'),
(12, 20, 'These business strategies are gold for any entrepreneur.', 'approved'),
(13, 2, 'Digital marketing keeps evolving. Thanks for keeping us updated!', 'approved'),
(14, 3, 'Work-life balance is so important, especially in tech. Great advice!', 'approved');

-- ====================================
-- Additional useful queries for testing
-- ====================================

-- Query to show all posts with their authors and categories
/*
SELECT 
    p.id,
    p.title,
    p.slug,
    u.username as author,
    c.name as category,
    p.status,
    p.created_at
FROM posts p
JOIN users u ON p.author_id = u.id
JOIN categories c ON p.category_id = c.id
ORDER BY p.created_at DESC;
*/

-- Query to show comments for a specific post
/*
SELECT 
    c.id,
    c.content,
    u.username as commenter,
    c.status,
    c.created_at
FROM comments c
JOIN users u ON c.user_id = u.id
WHERE c.post_id = 1
ORDER BY c.created_at ASC;
*/

-- Query to show post count by category
/*
SELECT 
    cat.name as category_name,
    COUNT(p.id) as post_count
FROM categories cat
LEFT JOIN posts p ON cat.id = p.category_id
GROUP BY cat.id, cat.name
ORDER BY post_count DESC;
*/

-- Query to show user statistics
/*
SELECT 
    u.username,
    u.role,
    COUNT(p.id) as total_posts,
    COUNT(c.id) as total_comments
FROM users u
LEFT JOIN posts p ON u.id = p.author_id
LEFT JOIN comments c ON u.id = c.user_id
GROUP BY u.id, u.username, u.role
ORDER BY total_posts DESC;
*/
