#!/bin/bash

# Bundle Analysis Script for BlogCMS Frontend
# Analyzes build output, bundle sizes, and optimization opportunities

set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
PURPLE='\033[0;35m'
NC='\033[0m'

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

step() {
    echo -e "${PURPLE}[$(date +'%H:%M:%S')] STEP: $1${NC}"
}

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
FRONTEND_DIR="$PROJECT_ROOT/frontend"
ANALYSIS_DIR="$PROJECT_ROOT/bundle-analysis"

# Parse arguments
REBUILD=false
OPEN_REPORT=false
DETAILED=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --rebuild)
            REBUILD=true
            shift
            ;;
        --open)
            OPEN_REPORT=true
            shift
            ;;
        --detailed)
            DETAILED=true
            shift
            ;;
        -h|--help)
            echo "Bundle Analysis Script for BlogCMS"
            echo ""
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --rebuild     Rebuild frontend before analysis"
            echo "  --open        Open analysis report in browser"
            echo "  --detailed    Generate detailed analysis"
            echo "  -h, --help    Show this help message"
            exit 0
            ;;
        *)
            error "Unknown option: $1"
            exit 1
            ;;
    esac
done

echo -e "${PURPLE}"
echo "╔══════════════════════════════════════════════════════════════════════════════╗"
echo "║                        BlogCMS Bundle Analysis                              ║"
echo "║                     Optimize Build Size & Performance                       ║"
echo "╚══════════════════════════════════════════════════════════════════════════════╝"
echo -e "${NC}"
echo ""

# Check prerequisites
check_prerequisites() {
    step "Checking prerequisites..."
    
    if [[ ! -d "$FRONTEND_DIR" ]]; then
        error "Frontend directory not found: $FRONTEND_DIR"
        exit 1
    fi
    
    cd "$FRONTEND_DIR"
    
    if [[ ! -f "package.json" ]]; then
        error "package.json not found in frontend directory"
        exit 1
    fi
    
    log "✅ Prerequisites met"
}

# Install analysis tools
install_tools() {
    step "Installing analysis tools..."
    
    cd "$FRONTEND_DIR"
    
    # Check if tools are already installed
    if ! npm list webpack-bundle-analyzer &> /dev/null; then
        info "Installing webpack-bundle-analyzer..."
        npm install --save-dev webpack-bundle-analyzer
    fi
    
    if ! npm list vite-bundle-analyzer &> /dev/null; then
        info "Installing vite-bundle-analyzer..."
        npm install --save-dev vite-bundle-analyzer
    fi
    
    log "✅ Analysis tools ready"
}

# Build frontend if requested
build_frontend() {
    if [[ "$REBUILD" == true ]]; then
        step "Building frontend..."
        
        cd "$FRONTEND_DIR"
        
        # Clean previous build
        rm -rf dist/
        
        # Build with analysis
        npm run build
        
        log "✅ Frontend built"
    else
        info "Using existing build (use --rebuild to rebuild)"
    fi
}

# Analyze bundle sizes
analyze_bundle_sizes() {
    step "Analyzing bundle sizes..."
    
    cd "$FRONTEND_DIR"
    
    if [[ ! -d "dist" ]]; then
        warn "No dist directory found, building first..."
        npm run build
    fi
    
    # Create analysis directory
    mkdir -p "$ANALYSIS_DIR"
    
    # Generate size report
    local size_report="$ANALYSIS_DIR/bundle-sizes.json"
    
    echo "{" > "$size_report"
    echo "  \"timestamp\": \"$(date -Iseconds)\"," >> "$size_report"
    echo "  \"files\": [" >> "$size_report"
    
    local first=true
    while IFS= read -r -d '' file; do
        if [[ "$first" == true ]]; then
            first=false
        else
            echo "," >> "$size_report"
        fi
        
        local relative_path
        relative_path=$(realpath --relative-to="$FRONTEND_DIR/dist" "$file")
        
        local size
        size=$(stat -c%s "$file")
        
        local size_kb
        size_kb=$((size / 1024))
        
        local gzipped_size
        gzipped_size=$(gzip -c "$file" | wc -c)
        
        local gzipped_kb
        gzipped_kb=$((gzipped_size / 1024))
        
        cat >> "$size_report" << EOF
    {
      "path": "$relative_path",
      "size": $size,
      "sizeKB": $size_kb,
      "gzippedSize": $gzipped_size,
      "gzippedKB": $gzipped_kb
    }
EOF
    done < <(find "$FRONTEND_DIR/dist" -type f \( -name "*.js" -o -name "*.css" \) -print0)
    
    echo "  ]" >> "$size_report"
    echo "}" >> "$size_report"
    
    log "✅ Bundle sizes analyzed"
}

# Generate detailed analysis
generate_detailed_analysis() {
    if [[ "$DETAILED" != true ]]; then
        return 0
    fi
    
    step "Generating detailed analysis..."
    
    cd "$FRONTEND_DIR"
    
    # Create analysis with vite-bundle-analyzer
    npx vite-bundle-analyzer dist/ --output "$ANALYSIS_DIR/bundle-analysis.html" &> /dev/null || warn "Detailed analysis failed"
    
    log "✅ Detailed analysis generated"
}

# Generate optimization recommendations
generate_recommendations() {
    step "Generating optimization recommendations..."
    
    local recommendations_file="$ANALYSIS_DIR/recommendations.md"
    
    cat > "$recommendations_file" << 'EOF'
# Bundle Optimization Recommendations

## Current Analysis Results

### Bundle Size Analysis
- Total bundle size: Check bundle-sizes.json
- Largest chunks: Review for optimization opportunities
- Compression ratio: Should be 60-70% with gzip

## Optimization Strategies

### 1. Code Splitting
```javascript
// Implement route-based splitting
const HomePage = () => import('./views/HomePage.vue')
const AboutPage = () => import('./views/AboutPage.vue')

// Component-based splitting
const HeavyComponent = defineAsyncComponent(() =>
  import('./components/HeavyComponent.vue')
)
```

### 2. Tree Shaking
```javascript
// Use named imports instead of default imports
import { specificFunction } from 'large-library'

// Avoid importing entire libraries
// BAD: import _ from 'lodash'
// GOOD: import debounce from 'lodash/debounce'
```

### 3. Dynamic Imports
```javascript
// Lazy load heavy dependencies
const heavyLibrary = await import('heavy-library')

// Conditional loading
if (userNeedsFeature) {
  const { feature } = await import('./advanced-features')
}
```

### 4. Asset Optimization
- Use WebP/AVIF images where supported
- Implement responsive images with srcset
- Optimize SVG files
- Use font-display: swap for web fonts

### 5. Bundle Analysis Actions

#### Large Dependencies (>50KB)
- Consider alternatives or partial imports
- Evaluate if dependency is necessary
- Check for smaller alternatives

#### Duplicate Code
- Extract common code into shared chunks
- Use module federation for micro-frontends
- Implement proper vendor splitting

#### Unused Code
- Remove unused imports and dependencies
- Use tree-shaking effectively
- Audit and remove dead code

## Performance Targets

### Bundle Size Targets
- Initial bundle: < 250KB (gzipped)
- Total bundle: < 1MB (gzipped)
- Individual chunks: < 100KB (gzipped)

### Loading Performance
- First Contentful Paint: < 1.8s
- Largest Contentful Paint: < 2.5s
- Time to Interactive: < 3.8s

## Implementation Steps

1. **Immediate Wins**
   - Enable gzip/brotli compression
   - Optimize images and assets
   - Remove unused dependencies

2. **Code Changes**
   - Implement route-based code splitting
   - Add dynamic imports for heavy components
   - Optimize vendor chunk splitting

3. **Advanced Optimizations**
   - Implement service workers for caching
   - Use preloading for critical resources
   - Optimize critical rendering path

## Monitoring

- Set up bundle size monitoring in CI/CD
- Track Core Web Vitals in production
- Regular performance audits with Lighthouse
EOF

    log "✅ Recommendations generated: $recommendations_file"
}

# Create summary report
create_summary_report() {
    step "Creating summary report..."
    
    local html_report="$ANALYSIS_DIR/summary.html"
    
    cat > "$html_report" << 'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>BlogCMS Bundle Analysis</title>
    <style>
        body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; margin: 0; padding: 20px; background: #f5f5f5; }
        .container { max-width: 1200px; margin: 0 auto; }
        .header { background: white; padding: 2rem; border-radius: 8px; margin-bottom: 2rem; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }
        .stats-grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(250px, 1fr)); gap: 1rem; margin-bottom: 2rem; }
        .stat-card { background: white; padding: 1.5rem; border-radius: 8px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }
        .stat-value { font-size: 2rem; font-weight: bold; margin-bottom: 0.5rem; }
        .stat-label { font-size: 0.9rem; color: #666; text-transform: uppercase; letter-spacing: 0.5px; }
        .files-table { background: white; border-radius: 8px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); overflow: hidden; }
        .table-header { background: #f8f9fa; padding: 1rem; font-weight: 600; border-bottom: 1px solid #dee2e6; }
        .file-row { padding: 1rem; border-bottom: 1px solid #dee2e6; display: grid; grid-template-columns: 2fr 1fr 1fr 1fr; gap: 1rem; align-items: center; }
        .file-row:last-child { border-bottom: none; }
        .file-name { font-family: 'Monaco', 'Menlo', monospace; font-size: 0.9rem; }
        .size-indicator { padding: 0.25rem 0.5rem; border-radius: 4px; font-size: 0.8rem; font-weight: 500; }
        .size-small { background: #d4edda; color: #155724; }
        .size-medium { background: #fff3cd; color: #856404; }
        .size-large { background: #f8d7da; color: #721c24; }
        .recommendations { background: white; padding: 2rem; border-radius: 8px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>BlogCMS Bundle Analysis</h1>
            <p>Generated on: <span id="timestamp"></span></p>
        </div>
        
        <div class="stats-grid">
            <div class="stat-card">
                <div class="stat-value" id="total-files">-</div>
                <div class="stat-label">Total Files</div>
            </div>
            <div class="stat-card">
                <div class="stat-value" id="total-size">-</div>
                <div class="stat-label">Total Size (KB)</div>
            </div>
            <div class="stat-card">
                <div class="stat-value" id="gzipped-size">-</div>
                <div class="stat-label">Gzipped Size (KB)</div>
            </div>
            <div class="stat-card">
                <div class="stat-value" id="compression-ratio">-</div>
                <div class="stat-label">Compression Ratio</div>
            </div>
        </div>
        
        <div class="files-table">
            <div class="table-header">
                <div style="display: grid; grid-template-columns: 2fr 1fr 1fr 1fr; gap: 1rem;">
                    <div>File</div>
                    <div>Size (KB)</div>
                    <div>Gzipped (KB)</div>
                    <div>Compression</div>
                </div>
            </div>
            <div id="files-list"></div>
        </div>
        
        <div class="recommendations">
            <h2>Quick Recommendations</h2>
            <div id="recommendations-list"></div>
        </div>
    </div>
    
    <script>
        fetch('./bundle-sizes.json')
            .then(response => response.json())
            .then(data => {
                document.getElementById('timestamp').textContent = new Date(data.timestamp).toLocaleString();
                
                // Calculate stats
                const totalFiles = data.files.length;
                const totalSize = data.files.reduce((sum, file) => sum + file.sizeKB, 0);
                const totalGzipped = data.files.reduce((sum, file) => sum + file.gzippedKB, 0);
                const compressionRatio = ((1 - totalGzipped / totalSize) * 100).toFixed(1);
                
                document.getElementById('total-files').textContent = totalFiles;
                document.getElementById('total-size').textContent = totalSize.toLocaleString();
                document.getElementById('gzipped-size').textContent = totalGzipped.toLocaleString();
                document.getElementById('compression-ratio').textContent = compressionRatio + '%';
                
                // Render files list
                const filesList = document.getElementById('files-list');
                data.files
                    .sort((a, b) => b.sizeKB - a.sizeKB)
                    .forEach(file => {
                        const compression = ((1 - file.gzippedKB / file.sizeKB) * 100).toFixed(1);
                        const sizeClass = file.sizeKB > 100 ? 'size-large' : file.sizeKB > 50 ? 'size-medium' : 'size-small';
                        
                        const row = document.createElement('div');
                        row.className = 'file-row';
                        row.innerHTML = `
                            <div class="file-name">${file.path}</div>
                            <div>${file.sizeKB.toLocaleString()}</div>
                            <div>${file.gzippedKB.toLocaleString()}</div>
                            <div><span class="size-indicator ${sizeClass}">${compression}%</span></div>
                        `;
                        filesList.appendChild(row);
                    });
                
                // Generate recommendations
                const recommendations = [];
                
                if (totalSize > 1024) {
                    recommendations.push('⚠️ Total bundle size is large (>1MB). Consider code splitting.');
                }
                
                if (compressionRatio < 60) {
                    recommendations.push('📦 Compression ratio is low. Ensure gzip/brotli is enabled.');
                }
                
                const largeFiles = data.files.filter(f => f.sizeKB > 100);
                if (largeFiles.length > 0) {
                    recommendations.push(`🔍 ${largeFiles.length} files are >100KB. Review for optimization.`);
                }
                
                if (recommendations.length === 0) {
                    recommendations.push('✅ Bundle size looks good! Consider monitoring in CI/CD.');
                }
                
                const recList = document.getElementById('recommendations-list');
                recList.innerHTML = recommendations.map(rec => `<p>${rec}</p>`).join('');
            })
            .catch(error => {
                console.error('Error loading bundle data:', error);
                document.body.innerHTML = '<div style="text-align: center; padding: 2rem;"><h2>Error loading bundle analysis data</h2><p>Make sure bundle-sizes.json exists.</p></div>';
            });
    </script>
</body>
</html>
EOF

    log "✅ Summary report created: $html_report"
}

# Display results
display_results() {
    echo ""
    log "🎉 Bundle analysis completed!"
    echo ""
    echo -e "${BLUE}Analysis Results:${NC}"
    echo "  📊 Bundle sizes: $ANALYSIS_DIR/bundle-sizes.json"
    echo "  📋 Summary report: $ANALYSIS_DIR/summary.html"
    echo "  💡 Recommendations: $ANALYSIS_DIR/recommendations.md"
    
    if [[ -f "$ANALYSIS_DIR/bundle-analysis.html" ]]; then
        echo "  🔍 Detailed analysis: $ANALYSIS_DIR/bundle-analysis.html"
    fi
    
    # Quick stats
    if [[ -f "$ANALYSIS_DIR/bundle-sizes.json" ]]; then
        local total_size
        total_size=$(jq '.files | map(.sizeKB) | add' "$ANALYSIS_DIR/bundle-sizes.json" 2>/dev/null || echo "0")
        
        local gzipped_size
        gzipped_size=$(jq '.files | map(.gzippedKB) | add' "$ANALYSIS_DIR/bundle-sizes.json" 2>/dev/null || echo "0")
        
        if [[ "$total_size" != "0" && "$gzipped_size" != "0" ]]; then
            local compression_ratio
            compression_ratio=$(echo "scale=1; (1 - $gzipped_size / $total_size) * 100" | bc 2>/dev/null || echo "N/A")
            
            echo ""
            echo -e "${BLUE}Quick Stats:${NC}"
            echo "  📦 Total size: ${total_size}KB"
            echo "  🗜️  Gzipped: ${gzipped_size}KB"
            echo "  📊 Compression: ${compression_ratio}%"
            
            # Performance assessment
            if (( $(echo "$total_size > 1024" | bc -l) )); then
                warn "Bundle size is large (>1MB). Consider optimization."
            elif (( $(echo "$total_size > 512" | bc -l) )); then
                info "Bundle size is moderate. Monitor growth."
            else
                log "Bundle size is good (<512KB)."
            fi
        fi
    fi
    
    if [[ "$OPEN_REPORT" == true ]]; then
        if command -v open &> /dev/null; then
            open "$ANALYSIS_DIR/summary.html"
        elif command -v xdg-open &> /dev/null; then
            xdg-open "$ANALYSIS_DIR/summary.html"
        else
            echo ""
            echo "Open $ANALYSIS_DIR/summary.html in your browser to view the results"
        fi
    fi
}

# Main execution
main() {
    check_prerequisites
    install_tools
    build_frontend
    analyze_bundle_sizes
    generate_detailed_analysis
    generate_recommendations
    create_summary_report
    display_results
}

# Run main function
main "$@"
