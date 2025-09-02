#!/bin/bash

# File Cleanup Script for BlogCMS
# Organizes and removes unnecessary documentation files

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

warn() {
    echo -e "${YELLOW}[$(date +'%H:%M:%S')] WARNING: $1${NC}"
}

info() {
    echo -e "${BLUE}[$(date +'%H:%M:%S')] INFO: $1${NC}"
}

error() {
    echo -e "${RED}[$(date +'%H:%M:%S')] ERROR: $1${NC}"
}

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Parse arguments
DRY_RUN=false
KEEP_DOCS=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        --keep-docs)
            KEEP_DOCS=true
            shift
            ;;
        -h|--help)
            echo "BlogCMS File Cleanup Script"
            echo ""
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --dry-run     Show what would be done without making changes"
            echo "  --keep-docs   Keep documentation files in docs/ directory"
            echo "  -h, --help    Show this help message"
            exit 0
            ;;
        *)
            error "Unknown option: $1. Use -h for help."
            exit 1
            ;;
    esac
done

echo -e "${BLUE}"
echo "╔══════════════════════════════════════════════════════════════════════════════╗"
echo "║                          BlogCMS File Cleanup                               ║"
echo "║                        Organizing Project Structure                         ║"
echo "╚══════════════════════════════════════════════════════════════════════════════╝"
echo -e "${NC}"
echo ""

if [[ "$DRY_RUN" == true ]]; then
    warn "DRY RUN MODE - No files will be modified"
    echo ""
fi

cd "$PROJECT_ROOT"

# Files to keep (important documentation)
KEEP_FILES=(
    "README.md"
    "LICENSE"
    "CHANGELOG.md"
    ".gitignore"
    ".env.example"
    "docker-compose.yml"
    "docker-compose.prod.yml"
    "Dockerfile"
    "backend/README.md"
    "frontend/README.md"
    "scripts/README.md"
)

# Files to remove (phase documentation and temporary files)
REMOVE_FILES=(
    "PHASE*.md"
    "UPLOAD_*.md"
    "API_DOCUMENTATION.md"
    "DATABASE_README.md"
    "*_COMPLETE.md"
    "*_DOCUMENTATION.md"
    "*_SUMMARY.md"
    "*_IMPLEMENTATION.md"
    "QUICK_START.md"
)

# Directories to clean
CLEAN_DIRS=(
    "docs"
    "deployment"
)

# Function to check if file should be kept
should_keep_file() {
    local file="$1"
    local basename_file=$(basename "$file")
    
    # Check against keep list
    for keep_pattern in "${KEEP_FILES[@]}"; do
        if [[ "$file" == "$keep_pattern" ]] || [[ "$basename_file" == "$keep_pattern" ]]; then
            return 0
        fi
    done
    
    # Keep if in docs/ and --keep-docs is set
    if [[ "$KEEP_DOCS" == true ]] && [[ "$file" == docs/* ]]; then
        return 0
    fi
    
    return 1
}

# Function to check if file should be removed
should_remove_file() {
    local file="$1"
    local basename_file=$(basename "$file")
    
    for remove_pattern in "${REMOVE_FILES[@]}"; do
        if [[ "$basename_file" == $remove_pattern ]]; then
            return 0
        fi
    done
    
    return 1
}

# Find and process markdown files
info "Scanning for markdown files..."
mapfile -t markdown_files < <(find . -name "*.md" -type f | grep -v node_modules | sort)

log "Found ${#markdown_files[@]} markdown files"
echo ""

# Categorize files
declare -a files_to_remove=()
declare -a files_to_keep=()

for file in "${markdown_files[@]}"; do
    # Remove leading ./
    clean_file="${file#./}"
    
    if should_keep_file "$clean_file"; then
        files_to_keep+=("$clean_file")
    elif should_remove_file "$clean_file"; then
        files_to_remove+=("$clean_file")
    else
        # Check content or ask for manual review
        if [[ "$clean_file" == deployment/* ]] && [[ "$KEEP_DOCS" != true ]]; then
            files_to_remove+=("$clean_file")
        else
            files_to_keep+=("$clean_file")
        fi
    fi
done

# Display categorization
echo -e "${GREEN}Files to keep (${#files_to_keep[@]}):${NC}"
for file in "${files_to_keep[@]}"; do
    echo "  ✅ $file"
done
echo ""

echo -e "${YELLOW}Files to remove (${#files_to_remove[@]}):${NC}"
for file in "${files_to_remove[@]}"; do
    echo "  🗑️  $file"
done
echo ""

# Create docs archive if keeping docs
if [[ "$KEEP_DOCS" == true ]] && [[ -d "docs" ]]; then
    info "Keeping docs directory as requested"
else
    # Archive docs before removal
    if [[ -d "docs" ]] && [[ "$DRY_RUN" != true ]]; then
        info "Creating archive of docs directory..."
        tar -czf "docs-archive-$(date +%Y%m%d-%H%M%S).tar.gz" docs/
        log "Docs archived to docs-archive-*.tar.gz"
    fi
fi

# Remove files
if [[ ${#files_to_remove[@]} -gt 0 ]]; then
    info "Removing unnecessary files..."
    
    for file in "${files_to_remove[@]}"; do
        if [[ -f "$file" ]]; then
            if [[ "$DRY_RUN" == true ]]; then
                echo "  Would remove: $file"
            else
                rm "$file"
                echo "  🗑️  Removed: $file"
            fi
        fi
    done
fi

# Clean empty directories
info "Cleaning empty directories..."
if [[ "$KEEP_DOCS" != true ]]; then
    for dir in "${CLEAN_DIRS[@]}"; do
        if [[ -d "$dir" ]]; then
            if [[ "$DRY_RUN" == true ]]; then
                echo "  Would remove directory: $dir"
            else
                # Remove if empty or only contains files we're removing
                if [[ -z "$(find "$dir" -name "*.md" | grep -v -E "($(IFS="|"; echo "${REMOVE_FILES[*]}"))")" ]]; then
                    rm -rf "$dir"
                    echo "  🗑️  Removed directory: $dir"
                fi
            fi
        fi
    done
fi

# Clean up any remaining empty directories
if [[ "$DRY_RUN" != true ]]; then
    find . -type d -empty -not -path "./node_modules/*" -not -path "./.git/*" -delete 2>/dev/null || true
fi

# Create a project structure summary
info "Creating project structure summary..."

if [[ "$DRY_RUN" != true ]]; then
    cat > PROJECT_STRUCTURE.md << 'EOF'
# BlogCMS Project Structure

This document outlines the clean, organized structure of the BlogCMS project.

## Root Directory

```
blogcms/
├── README.md              # Main project documentation
├── LICENSE                # MIT License
├── CHANGELOG.md           # Version history and changes
├── docker-compose.yml     # Development environment
├── docker-compose.prod.yml # Production environment
├── .env.example           # Environment variables template
├── .gitignore            # Git ignore rules
└── PROJECT_STRUCTURE.md   # This file
```

## Backend (Go/Gin)

```
backend/
├── README.md              # Backend documentation
├── main.go               # Application entry point
├── Dockerfile            # Container configuration
├── go.mod                # Go modules
├── go.sum                # Go modules checksum
├── config/               # Configuration management
├── controllers/          # HTTP request handlers
├── middleware/           # Custom middleware
├── models/              # Data models and database
├── routes/              # API route definitions
├── services/            # Business logic
├── utils/               # Utility functions
└── tests/               # Backend tests
```

## Frontend (Vue.js)

```
frontend/
├── README.md             # Frontend documentation
├── package.json          # Node.js dependencies
├── vite.config.js        # Vite configuration
├── Dockerfile            # Container configuration
├── public/               # Static assets
├── src/                  # Source code
│   ├── main.js          # Application entry point
│   ├── App.vue          # Root component
│   ├── components/      # Reusable components
│   ├── views/           # Page components
│   ├── router/          # Vue Router configuration
│   ├── stores/          # Pinia stores (state management)
│   ├── services/        # API services
│   ├── utils/           # Utility functions
│   └── assets/          # Assets (CSS, images)
└── tests/               # Frontend tests
```

## Scripts

```
scripts/
├── README.md             # Scripts documentation
├── deploy.sh            # Production deployment
├── backup.sh            # Database backup
├── restore.sh           # Database restore
├── seed-demo-data.sh    # Comprehensive demo data seeder
├── quick-seed.sh        # Quick demo data for development
├── ssl-setup.sh         # SSL certificate setup
├── monitoring-setup.sh  # Monitoring configuration
├── security-scan.sh     # Security vulnerability scan
└── cleanup.sh           # Project file cleanup (this script)
```

## Documentation Philosophy

This project follows a "minimal but complete" documentation approach:

1. **README.md** - Comprehensive getting started guide
2. **Component READMEs** - Specific documentation for each major component
3. **CHANGELOG.md** - Track all changes and versions
4. **Inline Comments** - Document complex code directly in source files

## Development Workflow

1. Clone repository
2. Run `docker-compose up -d`
3. Run `./scripts/quick-seed.sh` for demo data
4. Start developing!

## Production Deployment

1. Use production scripts in `scripts/` directory
2. Follow deployment documentation in main README
3. Monitor with included monitoring setup

This structure promotes:
- Easy onboarding for new developers
- Clear separation of concerns
- Minimal but effective documentation
- Production-ready deployment processes
EOF

    log "✅ Created PROJECT_STRUCTURE.md"
fi

echo ""
log "🎉 File cleanup completed!"
echo ""

if [[ "$DRY_RUN" != true ]]; then
    echo -e "${GREEN}Summary:${NC}"
    echo "  📁 Project structure organized"
    echo "  🗑️  Removed ${#files_to_remove[@]} unnecessary files"
    echo "  ✅ Kept ${#files_to_keep[@]} important files"
    echo "  📋 Created PROJECT_STRUCTURE.md"
    
    if [[ -f "docs-archive-"*".tar.gz" ]]; then
        echo "  📦 Archived docs to $(ls docs-archive-*.tar.gz | head -1)"
    fi
else
    echo -e "${YELLOW}This was a dry run. Use without --dry-run to make changes.${NC}"
fi

echo ""
echo -e "${BLUE}Your project is now clean and organized! 🚀${NC}"
