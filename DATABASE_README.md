# Blog CMS Database Documentation

## 📖 Overview
Database MySQL untuk aplikasi Blog CMS sederhana dengan 4 tabel utama: users, posts, categories, dan comments.

## 🗄️ Database Schema

### ERD (Entity Relationship Diagram)
```
Users (1) ----< Posts (M)
              |
              v
Categories (1) ----< Posts (M)
              
Users (1) ----< Comments (M)
Posts (1) ----< Comments (M)
```

## 📋 Table Structures

### 1. users
| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| id | INT | PRIMARY KEY, AUTO_INCREMENT | User ID |
| username | VARCHAR(50) | NOT NULL, UNIQUE | Username for login |
| email | VARCHAR(100) | NOT NULL, UNIQUE | User email |
| password | VARCHAR(255) | NOT NULL | Hashed password |
| role | ENUM('admin','author') | NOT NULL, DEFAULT 'author' | User role |
| created_at | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP | Creation time |
| updated_at | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP | Last update |

### 2. categories
| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| id | INT | PRIMARY KEY, AUTO_INCREMENT | Category ID |
| name | VARCHAR(100) | NOT NULL | Category name |
| slug | VARCHAR(100) | NOT NULL, UNIQUE | URL-friendly name |
| description | TEXT | | Category description |
| created_at | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP | Creation time |
| updated_at | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP | Last update |

### 3. posts
| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| id | INT | PRIMARY KEY, AUTO_INCREMENT | Post ID |
| title | VARCHAR(255) | NOT NULL | Post title |
| slug | VARCHAR(255) | NOT NULL, UNIQUE | URL-friendly title |
| content | TEXT | NOT NULL | Post content |
| excerpt | TEXT | | Short description |
| category_id | INT | NOT NULL, FK → categories.id | Category reference |
| author_id | INT | NOT NULL, FK → users.id | Author reference |
| status | ENUM('draft','published','archived') | DEFAULT 'draft' | Post status |
| created_at | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP | Creation time |
| updated_at | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP | Last update |

### 4. comments
| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| id | INT | PRIMARY KEY, AUTO_INCREMENT | Comment ID |
| post_id | INT | NOT NULL, FK → posts.id | Post reference |
| user_id | INT | NOT NULL, FK → users.id | Commenter reference |
| content | TEXT | NOT NULL | Comment content |
| status | ENUM('pending','approved','rejected') | DEFAULT 'pending' | Comment status |
| created_at | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP | Creation time |
| updated_at | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP | Last update |

## 🔗 Relationships

1. **users → posts** (One-to-Many)
   - One user can write multiple posts
   - Each post has one author

2. **categories → posts** (One-to-Many)
   - One category can have multiple posts
   - Each post belongs to one category

3. **users → comments** (One-to-Many)
   - One user can write multiple comments
   - Each comment has one author

4. **posts → comments** (One-to-Many)
   - One post can have multiple comments
   - Each comment belongs to one post

## 🚀 How to Use

### 1. Create Database
```bash
mysql -u root -p < database_schema.sql
```

### 2. Connect to Database
```bash
mysql -u root -p blog_cms
```

### 3. Useful Queries

#### Get all posts with authors and categories:
```sql
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
```

#### Get comments for a specific post:
```sql
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
```

#### Get post count by category:
```sql
SELECT 
    cat.name as category_name,
    COUNT(p.id) as post_count
FROM categories cat
LEFT JOIN posts p ON cat.id = p.category_id
GROUP BY cat.id, cat.name
ORDER BY post_count DESC;
```

#### Get user statistics:
```sql
SELECT 
    u.username,
    u.role,
    COUNT(DISTINCT p.id) as total_posts,
    COUNT(DISTINCT c.id) as total_comments
FROM users u
LEFT JOIN posts p ON u.id = p.author_id
LEFT JOIN comments c ON u.id = c.user_id
GROUP BY u.id, u.username, u.role
ORDER BY total_posts DESC;
```

## 📊 Sample Data

Database sudah dilengkapi dengan data dummy:
- **20 Users** (1 admin, 19 authors)
- **20 Categories** (Technology, Programming, Web Development, dll.)
- **20 Posts** dengan konten yang beragam
- **20 Comments** tersebar di berbagai post

### Default Login:
- **Admin**: username: `admin`, email: `admin@blogcms.com`
- **Author**: username: `john_doe`, email: `john.doe@example.com`
- **Password** (all users): `password` (hashed: `$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi`)

## 🔧 Performance Optimizations

Database sudah dilengkapi dengan indexes untuk:
- `posts.category_id`
- `posts.author_id`
- `posts.status`
- `comments.post_id`
- `comments.user_id`
- `comments.status`

## 🛡️ Security Features

1. **Foreign Key Constraints** dengan CASCADE DELETE
2. **Password hashing** (menggunakan bcrypt format)
3. **Unique constraints** untuk username, email, dan slugs
4. **Role-based access control**
5. **Content moderation** (comment status)

## 📝 Notes

- Semua tabel menggunakan `InnoDB` engine (default MySQL)
- Timestamps otomatis untuk tracking perubahan
- Slug fields untuk SEO-friendly URLs
- Status fields untuk content management
- Prepared statements recommended untuk query execution
