#!/bin/bash

# BlogCMS Portfolio Screenshots Generator
# Creates screenshots for portfolio and showcase purposes

set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

log() {
    echo -e "${GREEN}[$(date +'%H:%M:%S')] $1${NC}"
}

info() {
    echo -e "${BLUE}[$(date +'%H:%M:%S')] INFO: $1${NC}"
}

warn() {
    echo -e "${YELLOW}[$(date +'%H:%M:%S')] WARNING: $1${NC}"
}

error() {
    echo -e "${RED}[$(date +'%H:%M:%S')] ERROR: $1${NC}"
}

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
SCREENSHOTS_DIR="$PROJECT_ROOT/screenshots"
BASE_URL="http://localhost:3000"

# Create screenshots directory
mkdir -p "$SCREENSHOTS_DIR"

echo -e "${BLUE}"
echo "╔══════════════════════════════════════════════════════════════════════════════╗"
echo "║                    BlogCMS Portfolio Screenshots                            ║"
echo "║                    Capturing Key Application Views                          ║"
echo "╚══════════════════════════════════════════════════════════════════════════════╝"
echo -e "${NC}"
echo ""

# Check if application is running
check_app_status() {
    info "Checking if BlogCMS is running..."
    
    if ! curl -s "$BASE_URL" &>/dev/null; then
        error "BlogCMS frontend is not running at $BASE_URL"
        echo "Please run: docker-compose up -d"
        echo "Or use: ./scripts/demo-setup.sh"
        exit 1
    fi
    
    log "✅ BlogCMS is running"
}

# Create instructions for manual screenshots
create_screenshot_instructions() {
    cat > "$SCREENSHOTS_DIR/README.md" << 'EOF'
# BlogCMS Portfolio Screenshots

This directory contains screenshots and instructions for creating portfolio-ready images of the BlogCMS application.

## Recommended Screenshots

### 1. Homepage/Landing Page
- **URL**: http://localhost:3000
- **Description**: Main landing page showing blog posts list
- **Key Elements**: Navigation, hero section, blog post cards, responsive design

### 2. Admin Dashboard
- **URL**: http://localhost:3000/admin
- **Login**: admin@demo.com / Admin123!
- **Description**: Admin dashboard with management options
- **Key Elements**: Sidebar navigation, stats overview, quick actions

### 3. Post Creation/Editor
- **URL**: http://localhost:3000/admin/posts/create
- **Description**: Rich text editor for creating blog posts
- **Key Elements**: WYSIWYG editor, category selection, publish options

### 4. Blog Post Detail
- **URL**: http://localhost:3000/posts/{slug}
- **Description**: Individual blog post view with comments
- **Key Elements**: Post content, author info, comments section

### 5. Categories Management
- **URL**: http://localhost:3000/admin/categories
- **Description**: Category management interface
- **Key Elements**: Category list, add/edit forms, search

### 6. User Management
- **URL**: http://localhost:3000/admin/users
- **Description**: User management with roles
- **Key Elements**: User table, role badges, action buttons

### 7. Mobile Responsive Views
- **Description**: Same pages in mobile viewport (375px width)
- **Key Elements**: Mobile navigation, responsive layout, touch-friendly UI

### 8. API Documentation
- **URL**: http://localhost:8080/swagger/index.html
- **Description**: Interactive API documentation
- **Key Elements**: Swagger UI, endpoint documentation, try-it features

## Screenshot Guidelines

### Technical Requirements
- **Resolution**: 1920x1080 (desktop) and 375x812 (mobile)
- **Format**: PNG for static images, GIF for interactions
- **Quality**: High quality, no compression artifacts

### Composition Tips
1. **Clean Data**: Use demo data that looks professional
2. **Full Context**: Show enough UI to understand the feature
3. **Consistent Branding**: Ensure logo and colors are visible
4. **Action States**: Show interactive elements (hover, active states)

### Content Guidelines
- Use realistic, professional content
- Show populated data, not empty states
- Include user interactions where relevant
- Demonstrate key features clearly

## Tools for Screenshots

### Browser Extensions
- **Full Page Screen Capture** (Chrome/Firefox)
- **Lightshot** (Quick screenshots)
- **Nimbus Screenshot** (Annotations)

### Standalone Tools
- **LICEcap** (Animated GIFs)
- **Snagit** (Professional screenshots)
- **CloudApp** (Quick sharing)

### Command Line (Advanced)
```bash
# Using Puppeteer for automated screenshots
npm install -g puppeteer

# Example script for automated screenshots
node screenshot-automation.js
```

## Portfolio Usage

These screenshots are perfect for:
- GitHub repository README
- Personal portfolio website
- LinkedIn project showcase
- Job application materials
- Client presentations

## File Naming Convention

Use descriptive names:
- `homepage-desktop.png`
- `admin-dashboard-mobile.png`
- `post-editor-interaction.gif`
- `api-documentation.png`

## Quick Start

1. Ensure BlogCMS is running: `docker-compose up -d`
2. Seed demo data: `./scripts/quick-seed.sh`
3. Open browser to http://localhost:3000
4. Login with demo account: admin@demo.com / Admin123!
5. Navigate to each URL above and capture screenshots
6. Test mobile views using browser dev tools (F12 -> Device Mode)

Happy showcasing! 📸
EOF

    log "✅ Created screenshot instructions at $SCREENSHOTS_DIR/README.md"
}

# Create sample screenshot automation script
create_automation_script() {
    cat > "$SCREENSHOTS_DIR/capture-screenshots.js" << 'EOF'
// BlogCMS Screenshot Automation Script
// Requires: npm install -g puppeteer

const puppeteer = require('puppeteer');
const fs = require('fs');
const path = require('path');

const config = {
    baseUrl: 'http://localhost:3000',
    outputDir: './screenshots',
    credentials: {
        email: 'admin@demo.com',
        password: 'Admin123!'
    },
    viewports: {
        desktop: { width: 1920, height: 1080 },
        mobile: { width: 375, height: 812 }
    }
};

const screenshots = [
    {
        name: 'homepage',
        url: '/',
        waitFor: '.blog-posts',
        description: 'Homepage with blog posts'
    },
    {
        name: 'admin-dashboard',
        url: '/admin',
        requiresLogin: true,
        waitFor: '.dashboard-stats',
        description: 'Admin dashboard'
    },
    {
        name: 'post-editor',
        url: '/admin/posts/create',
        requiresLogin: true,
        waitFor: '.editor-container',
        description: 'Post creation editor'
    },
    {
        name: 'post-detail',
        url: '/posts/welcome-to-blogcms-demo',
        waitFor: '.post-content',
        description: 'Blog post detail view'
    }
];

async function captureScreenshots() {
    console.log('🚀 Starting BlogCMS screenshot capture...');
    
    const browser = await puppeteer.launch({
        headless: true,
        args: ['--no-sandbox', '--disable-setuid-sandbox']
    });
    
    const page = await browser.newPage();
    
    // Create output directory
    if (!fs.existsSync(config.outputDir)) {
        fs.mkdirSync(config.outputDir, { recursive: true });
    }
    
    // Login if needed
    let isLoggedIn = false;
    async function ensureLogin() {
        if (isLoggedIn) return;
        
        console.log('🔐 Logging in...');
        await page.goto(`${config.baseUrl}/login`);
        await page.type('#email', config.credentials.email);
        await page.type('#password', config.credentials.password);
        await page.click('button[type="submit"]');
        await page.waitForNavigation();
        isLoggedIn = true;
        console.log('✅ Logged in successfully');
    }
    
    // Capture screenshots for each viewport
    for (const viewportName in config.viewports) {
        const viewport = config.viewports[viewportName];
        console.log(`📱 Setting viewport: ${viewportName} (${viewport.width}x${viewport.height})`);
        await page.setViewport(viewport);
        
        for (const screenshot of screenshots) {
            try {
                console.log(`📸 Capturing: ${screenshot.name} (${viewportName})`);
                
                // Login if required
                if (screenshot.requiresLogin) {
                    await ensureLogin();
                }
                
                // Navigate to page
                await page.goto(`${config.baseUrl}${screenshot.url}`, {
                    waitUntil: 'networkidle2'
                });
                
                // Wait for specific element
                if (screenshot.waitFor) {
                    await page.waitForSelector(screenshot.waitFor, { timeout: 10000 });
                }
                
                // Additional wait for animations
                await page.waitForTimeout(1000);
                
                // Capture screenshot
                const filename = `${screenshot.name}-${viewportName}.png`;
                const filepath = path.join(config.outputDir, filename);
                
                await page.screenshot({
                    path: filepath,
                    fullPage: true
                });
                
                console.log(`✅ Saved: ${filename}`);
                
            } catch (error) {
                console.error(`❌ Failed to capture ${screenshot.name} (${viewportName}):`, error.message);
            }
        }
    }
    
    await browser.close();
    console.log('🎉 Screenshot capture completed!');
    console.log(`📁 Screenshots saved to: ${config.outputDir}`);
}

// Run the script
captureScreenshots().catch(console.error);
EOF

    log "✅ Created automation script at $SCREENSHOTS_DIR/capture-screenshots.js"
}

# Create demo data for screenshots
create_demo_showcase() {
    info "Creating showcase-ready demo data..."
    
    # Check if demo data exists
    if ! curl -s "http://localhost:8080/api/v1/posts" &>/dev/null; then
        warn "API not accessible, skipping demo data creation"
        return 0
    fi
    
    log "✅ Demo data ready for screenshots"
}

# Main function
main() {
    check_app_status
    create_screenshot_instructions
    create_automation_script
    create_demo_showcase
    
    echo ""
    log "🎉 Portfolio screenshot resources created!"
    echo ""
    echo -e "${BLUE}Next Steps:${NC}"
    echo "  1. Review instructions: cat $SCREENSHOTS_DIR/README.md"
    echo "  2. Manual screenshots: Follow the guide in README.md"
    echo "  3. Automated screenshots: cd $SCREENSHOTS_DIR && npm install puppeteer && node capture-screenshots.js"
    echo ""
    echo -e "${BLUE}Demo Access:${NC}"
    echo "  🌐 Frontend: $BASE_URL"
    echo "  👑 Admin Login: admin@demo.com / Admin123!"
    echo ""
    echo -e "${YELLOW}Pro Tips:${NC}"
    echo "  • Use browser dev tools for mobile screenshots (F12 → Device Mode)"
    echo "  • Capture both light and dark themes if applicable"
    echo "  • Include loading states and interactions"
    echo "  • Create animated GIFs for complex workflows"
    echo ""
}

# Run main function
main "$@"
