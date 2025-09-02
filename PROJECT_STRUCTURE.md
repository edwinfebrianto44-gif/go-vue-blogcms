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
