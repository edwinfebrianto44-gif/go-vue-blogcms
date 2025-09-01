# BlogCMS Frontend

Modern Vue 3 frontend application for the BlogCMS system with Tailwind CSS, responsive design, and comprehensive user management.

## 🚀 Features

### 🎨 Modern UI/UX
- **Responsive Design**: Mobile-first approach with Tailwind CSS
- **Dark/Light Mode**: Consistent design system
- **Smooth Animations**: Transitions and micro-interactions
- **Professional Layout**: Clean and intuitive interface

### 🔐 Authentication & Authorization
- **JWT-based Auth**: Secure token-based authentication
- **Role-based Access**: Admin and user roles with proper permissions
- **Protected Routes**: Automatic redirects and route guards
- **Session Management**: Persistent login with refresh tokens

### 📝 Content Management
- **Rich Text Editor**: Full-featured post creation and editing
- **Media Upload**: Image upload and management
- **Categories**: Organize posts with hierarchical categories
- **Comments System**: Moderated comments with approval workflow
- **SEO Optimization**: Meta tags and structured data

### 👨‍💼 Dashboard Features
- **Analytics Dashboard**: Post views, comments, and engagement metrics
- **Content Management**: CRUD operations for posts and categories
- **User Management**: Profile settings and account management
- **Real-time Updates**: Live notifications and status updates

## 🛠️ Tech Stack

### Core Framework
- **Vue 3**: Composition API with `<script setup>`
- **Vite**: Fast build tool and development server
- **Vue Router**: Client-side routing with guards
- **Pinia**: State management with TypeScript support

### UI & Styling
- **Tailwind CSS**: Utility-first CSS framework
- **Heroicons**: Beautiful SVG icons
- **HeadlessUI**: Unstyled, accessible UI components
- **Custom Design System**: Consistent colors, typography, and spacing

### HTTP & API
- **Axios**: HTTP client with interceptors
- **Request/Response Interceptors**: Automatic token handling
- **Error Handling**: Global error management
- **Loading States**: User-friendly loading indicators

### Development Tools
- **ESLint**: Code linting and style enforcement
- **Prettier**: Code formatting
- **Hot Module Replacement**: Fast development experience
- **Source Maps**: Enhanced debugging

## 📁 Project Structure

```
frontend/
├── public/                 # Static assets
├── src/
│   ├── components/        # Reusable Vue components
│   │   ├── layout/       # Layout components (navbar, footer)
│   │   ├── ui/           # UI components (buttons, cards, forms)
│   │   ├── dashboard/    # Dashboard-specific components
│   │   └── comments/     # Comment system components
│   ├── views/            # Page components
│   │   ├── auth/         # Authentication pages
│   │   └── dashboard/    # Dashboard pages
│   ├── stores/           # Pinia state stores
│   ├── services/         # API services and utilities
│   ├── router/           # Vue Router configuration
│   └── assets/           # Stylesheets and static assets
├── package.json          # Dependencies and scripts
├── vite.config.js        # Vite configuration
├── tailwind.config.js    # Tailwind CSS configuration
└── README.md            # This file
```

## 🚦 Getting Started

### Prerequisites
- Node.js 18+ and npm
- Backend API running on port 8080

### Installation

1. **Install Dependencies**
   ```bash
   cd frontend
   npm install
   ```

2. **Environment Setup**
   The frontend is configured to proxy API requests to `http://localhost:8080` in development.

3. **Start Development Server**
   ```bash
   npm run dev
   ```
   
   Or use the provided script:
   ```bash
   ../start-frontend.sh
   ```

4. **Access Application**
   - Frontend: http://localhost:5173
   - API calls proxied to: http://localhost:8080

### Build for Production

```bash
npm run build
```

The built files will be in the `dist/` directory.

## 🎯 Key Pages & Features

### Public Pages
- **Home** (`/`): Hero section, featured posts, categories
- **Posts** (`/posts`): All published posts with search and filtering
- **Post Detail** (`/posts/:slug`): Full post with comments and social sharing
- **Category** (`/category/:slug`): Posts filtered by category

### Authentication
- **Login** (`/login`): Secure user authentication
- **Register** (`/register`): User registration with validation

### Dashboard (Protected)
- **Dashboard** (`/dashboard`): Analytics and quick actions
- **Posts Management** (`/dashboard/posts`): CRUD operations for posts
- **Categories** (`/dashboard/categories`): Category management
- **Comments** (`/dashboard/comments`): Comment moderation (admin only)
- **Profile** (`/dashboard/profile`): User profile settings

## 🔧 Configuration

### API Configuration
The API base URL is configured in `src/services/api.js`:

```javascript
const API_BASE_URL = import.meta.env.VITE_API_URL || 'http://localhost:8080/api'
```

### Vite Proxy (Development)
API requests are proxied in `vite.config.js`:

```javascript
server: {
  proxy: {
    '/api': {
      target: 'http://localhost:8080',
      changeOrigin: true
    }
  }
}
```

### Tailwind Configuration
Custom design system in `tailwind.config.js` with:
- Custom color palette
- Typography scale
- Component utilities
- Responsive breakpoints

## 🎨 Design System

### Colors
- **Primary**: Blue tones for main actions
- **Secondary**: Gray tones for text and backgrounds
- **Success**: Green for positive actions
- **Warning**: Yellow for cautions
- **Error**: Red for errors and deletions

### Components
- **Buttons**: Primary, secondary, outline variations
- **Forms**: Consistent input styling with validation states
- **Cards**: Content containers with shadows and borders
- **Navigation**: Responsive navbar with mobile menu

### Typography
- **Headings**: Bold, hierarchical sizing
- **Body Text**: Readable line heights and spacing
- **Code**: Monospace font for technical content

## 🔒 Security Features

### Authentication
- JWT token storage in localStorage
- Automatic token refresh
- Secure logout with token cleanup
- Protected route guards

### Data Validation
- Client-side form validation
- XSS protection with content sanitization
- CSRF protection via JWT tokens
- Input length and format restrictions

### API Security
- Request interceptors for authentication
- Response interceptors for error handling
- Automatic logout on token expiration
- Rate limiting awareness

## 📱 Responsive Design

### Breakpoints
- **Mobile**: < 768px
- **Tablet**: 768px - 1024px
- **Desktop**: > 1024px

### Mobile Features
- Touch-friendly interface
- Collapsible navigation
- Optimized form layouts
- Swipe gestures support

## 🚀 Performance

### Optimization
- Code splitting with Vue Router
- Lazy loading of components
- Image optimization and lazy loading
- Minified production builds

### Bundle Size
- Tree shaking with Vite
- Dependency optimization
- CSS purging with Tailwind
- Gzip compression ready

## 🧪 Development

### Code Quality
- ESLint for code linting
- Prettier for formatting
- Vue 3 Composition API best practices
- TypeScript-ready structure

### Development Workflow
```bash
# Start development server
npm run dev

# Lint code
npm run lint

# Format code
npm run format

# Build for production
npm run build

# Preview production build
npm run preview
```

## 🤝 Contributing

1. Follow Vue 3 Composition API patterns
2. Use TypeScript types where beneficial
3. Maintain consistent component structure
4. Write meaningful commit messages
5. Test responsive design on multiple devices

## 📄 License

This project is part of the BlogCMS system and follows the same licensing terms.

---

Built with ❤️ using Vue 3, Vite, and Tailwind CSS
