#!/bin/bash

# BlogCMS Performance Audit Script
# Runs Lighthouse audits and generates performance reports

set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
PURPLE='\033[0;35m'
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

step() {
    echo -e "${PURPLE}[$(date +'%H:%M:%S')] STEP: $1${NC}"
}

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
REPORTS_DIR="$PROJECT_ROOT/performance-reports"
BASE_URL="${BASE_URL:-http://localhost:3000}"
API_URL="${API_URL:-http://localhost:8080}"

# Lighthouse configuration
LIGHTHOUSE_CONFIG='{
  "extends": "lighthouse:default",
  "settings": {
    "onlyAudits": [
      "first-contentful-paint",
      "largest-contentful-paint",
      "first-meaningful-paint",
      "speed-index",
      "interactive",
      "cumulative-layout-shift",
      "total-blocking-time",
      "server-response-time",
      "render-blocking-resources",
      "unused-css-rules",
      "unused-javascript",
      "modern-image-formats",
      "efficient-animated-content",
      "image-size-responsive",
      "preload-lcp-image",
      "critical-request-chains"
    ]
  }
}'

# Parse arguments
MOBILE_ONLY=false
DESKTOP_ONLY=false
FULL_AUDIT=false
GENERATE_REPORT=true
OPEN_REPORT=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --mobile-only)
            MOBILE_ONLY=true
            shift
            ;;
        --desktop-only)
            DESKTOP_ONLY=true
            shift
            ;;
        --full-audit)
            FULL_AUDIT=true
            shift
            ;;
        --no-report)
            GENERATE_REPORT=false
            shift
            ;;
        --open)
            OPEN_REPORT=true
            shift
            ;;
        --url)
            BASE_URL="$2"
            shift 2
            ;;
        -h|--help)
            echo "BlogCMS Performance Audit Script"
            echo ""
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --mobile-only     Run audit only for mobile"
            echo "  --desktop-only    Run audit only for desktop"
            echo "  --full-audit      Run complete Lighthouse audit"
            echo "  --no-report       Skip HTML report generation"
            echo "  --open            Open reports in browser after completion"
            echo "  --url URL         Override base URL (default: http://localhost:3000)"
            echo "  -h, --help        Show this help message"
            exit 0
            ;;
        *)
            error "Unknown option: $1. Use -h for help."
            exit 1
            ;;
    esac
done

echo -e "${PURPLE}"
echo "╔══════════════════════════════════════════════════════════════════════════════╗"
echo "║                     BlogCMS Performance Audit                               ║"
echo "║                    Lighthouse Performance Testing                           ║"
echo "╚══════════════════════════════════════════════════════════════════════════════╝"
echo -e "${NC}"
echo ""

# Check prerequisites
check_prerequisites() {
    step "Checking prerequisites..."
    
    # Check Node.js and npm
    if ! command -v node &> /dev/null; then
        error "Node.js is not installed. Please install Node.js first."
        exit 1
    fi
    
    # Check if Lighthouse CLI is installed
    if ! command -v lighthouse &> /dev/null; then
        info "Installing Lighthouse CLI..."
        npm install -g lighthouse
    fi
    
    # Check if application is running
    if ! curl -s "$BASE_URL" &> /dev/null; then
        error "Application is not running at $BASE_URL"
        echo "Please start the application first: docker-compose up -d"
        exit 1
    fi
    
    log "✅ Prerequisites met"
}

# Create reports directory
setup_reports() {
    step "Setting up reports directory..."
    
    mkdir -p "$REPORTS_DIR"
    
    # Create timestamp for this audit run
    TIMESTAMP=$(date +"%Y%m%d-%H%M%S")
    RUN_DIR="$REPORTS_DIR/run-$TIMESTAMP"
    mkdir -p "$RUN_DIR"
    
    log "✅ Reports will be saved to: $RUN_DIR"
}

# Test URLs to audit
get_test_urls() {
    local urls=(
        "$BASE_URL/"
        "$BASE_URL/posts"
        "$BASE_URL/login"
    )
    
    # Try to get a real post URL for more realistic testing
    local post_url
    post_url=$(curl -s "$API_URL/api/v1/posts?limit=1" | jq -r '.data[0].slug // empty' 2>/dev/null || echo "")
    if [[ -n "$post_url" ]]; then
        urls+=("$BASE_URL/posts/$post_url")
    fi
    
    echo "${urls[@]}"
}

# Run Lighthouse audit
run_lighthouse_audit() {
    local url="$1"
    local device="$2"
    local output_dir="$3"
    
    local page_name
    page_name=$(echo "$url" | sed "s|$BASE_URL||" | sed 's|/|-|g' | sed 's|^-||')
    if [[ -z "$page_name" ]]; then
        page_name="homepage"
    fi
    
    local output_file="$output_dir/lighthouse-${page_name}-${device}"
    
    info "Running Lighthouse audit for $url ($device)..."
    
    # Lighthouse options
    local lighthouse_opts=(
        "$url"
        "--output=html,json"
        "--output-path=${output_file}"
        "--chrome-flags=--headless,--no-sandbox,--disable-dev-shm-usage"
        "--quiet"
    )
    
    # Device-specific options
    if [[ "$device" == "mobile" ]]; then
        lighthouse_opts+=(
            "--emulated-form-factor=mobile"
            "--throttling-method=simulate"
            "--throttling.cpuSlowdownMultiplier=4"
        )
    else
        lighthouse_opts+=(
            "--emulated-form-factor=desktop"
            "--throttling-method=simulate"
            "--throttling.cpuSlowdownMultiplier=1"
        )
    fi
    
    # Full audit or performance-focused
    if [[ "$FULL_AUDIT" == true ]]; then
        lighthouse_opts+=("--config-path=/tmp/lighthouse-config.json")
        echo "$LIGHTHOUSE_CONFIG" > /tmp/lighthouse-config.json
    else
        lighthouse_opts+=("--only-categories=performance")
    fi
    
    # Run Lighthouse
    if lighthouse "${lighthouse_opts[@]}" &> /dev/null; then
        log "✅ Audit completed: ${page_name} (${device})"
        
        # Extract performance score
        local json_file="${output_file}.report.json"
        if [[ -f "$json_file" ]]; then
            local score
            score=$(jq -r '.categories.performance.score * 100 | floor' "$json_file" 2>/dev/null || echo "N/A")
            echo "    Performance Score: $score/100"
        fi
    else
        warn "Audit failed for: ${page_name} (${device})"
    fi
}

# Generate summary report
generate_summary() {
    step "Generating performance summary..."
    
    local summary_file="$RUN_DIR/summary.json"
    local html_summary="$RUN_DIR/summary.html"
    
    # Collect all JSON reports
    local reports=($(find "$RUN_DIR" -name "*.report.json"))
    
    if [[ ${#reports[@]} -eq 0 ]]; then
        warn "No reports found to summarize"
        return 1
    fi
    
    # Create summary JSON
    echo "{" > "$summary_file"
    echo "  \"timestamp\": \"$(date -Iseconds)\"," >> "$summary_file"
    echo "  \"baseUrl\": \"$BASE_URL\"," >> "$summary_file"
    echo "  \"reports\": [" >> "$summary_file"
    
    local first=true
    for report in "${reports[@]}"; do
        if [[ "$first" == true ]]; then
            first=false
        else
            echo "," >> "$summary_file"
        fi
        
        local filename
        filename=$(basename "$report")
        
        local performance_score
        performance_score=$(jq -r '.categories.performance.score' "$report" 2>/dev/null || echo "null")
        
        local fcp
        fcp=$(jq -r '.audits["first-contentful-paint"].numericValue' "$report" 2>/dev/null || echo "null")
        
        local lcp
        lcp=$(jq -r '.audits["largest-contentful-paint"].numericValue' "$report" 2>/dev/null || echo "null")
        
        local cls
        cls=$(jq -r '.audits["cumulative-layout-shift"].numericValue' "$report" 2>/dev/null || echo "null")
        
        local tti
        tti=$(jq -r '.audits.interactive.numericValue' "$report" 2>/dev/null || echo "null")
        
        cat >> "$summary_file" << EOF
    {
      "file": "$filename",
      "performanceScore": $performance_score,
      "metrics": {
        "firstContentfulPaint": $fcp,
        "largestContentfulPaint": $lcp,
        "cumulativeLayoutShift": $cls,
        "timeToInteractive": $tti
      }
    }
EOF
    done
    
    echo "  ]" >> "$summary_file"
    echo "}" >> "$summary_file"
    
    # Generate HTML summary
    cat > "$html_summary" << 'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>BlogCMS Performance Summary</title>
    <style>
        body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; margin: 0; padding: 20px; background: #f5f5f5; }
        .container { max-width: 1200px; margin: 0 auto; }
        .header { background: white; padding: 2rem; border-radius: 8px; margin-bottom: 2rem; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }
        .metrics-grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(300px, 1fr)); gap: 1rem; }
        .metric-card { background: white; padding: 1.5rem; border-radius: 8px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }
        .score { font-size: 2rem; font-weight: bold; margin-bottom: 0.5rem; }
        .score.good { color: #0f9d58; }
        .score.average { color: #ff9800; }
        .score.poor { color: #f44336; }
        .metric-name { font-size: 0.9rem; color: #666; text-transform: uppercase; letter-spacing: 0.5px; }
        .metric-value { font-size: 1.2rem; font-weight: 500; }
        .report-link { display: inline-block; margin-top: 1rem; padding: 0.5rem 1rem; background: #1976d2; color: white; text-decoration: none; border-radius: 4px; }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>BlogCMS Performance Summary</h1>
            <p>Generated on: <span id="timestamp"></span></p>
        </div>
        <div id="reports-container"></div>
    </div>
    
    <script>
        // Load and display summary data
        fetch('./summary.json')
            .then(response => response.json())
            .then(data => {
                document.getElementById('timestamp').textContent = new Date(data.timestamp).toLocaleString();
                
                const container = document.getElementById('reports-container');
                
                data.reports.forEach(report => {
                    const score = Math.round((report.performanceScore || 0) * 100);
                    const scoreClass = score >= 90 ? 'good' : score >= 50 ? 'average' : 'poor';
                    
                    const card = document.createElement('div');
                    card.className = 'metric-card';
                    card.innerHTML = `
                        <div class="metric-name">${report.file.replace('.report.json', '').replace(/lighthouse-|-/g, ' ')}</div>
                        <div class="score ${scoreClass}">${score}/100</div>
                        <div style="display: grid; grid-template-columns: repeat(2, 1fr); gap: 1rem; margin-top: 1rem;">
                            <div>
                                <div class="metric-name">FCP</div>
                                <div class="metric-value">${report.metrics.firstContentfulPaint ? Math.round(report.metrics.firstContentfulPaint) + 'ms' : 'N/A'}</div>
                            </div>
                            <div>
                                <div class="metric-name">LCP</div>
                                <div class="metric-value">${report.metrics.largestContentfulPaint ? Math.round(report.metrics.largestContentfulPaint) + 'ms' : 'N/A'}</div>
                            </div>
                            <div>
                                <div class="metric-name">CLS</div>
                                <div class="metric-value">${report.metrics.cumulativeLayoutShift ? report.metrics.cumulativeLayoutShift.toFixed(3) : 'N/A'}</div>
                            </div>
                            <div>
                                <div class="metric-name">TTI</div>
                                <div class="metric-value">${report.metrics.timeToInteractive ? Math.round(report.metrics.timeToInteractive) + 'ms' : 'N/A'}</div>
                            </div>
                        </div>
                        <a href="${report.file.replace('.report.json', '.report.html')}" class="report-link" target="_blank">View Full Report</a>
                    `;
                    
                    container.appendChild(card);
                });
            });
    </script>
</body>
</html>
EOF
    
    log "✅ Summary generated: $html_summary"
}

# Main execution
main() {
    check_prerequisites
    setup_reports
    
    local urls=($(get_test_urls))
    
    info "Testing ${#urls[@]} pages: ${urls[*]}"
    echo ""
    
    # Run audits
    for url in "${urls[@]}"; do
        if [[ "$DESKTOP_ONLY" != true ]]; then
            run_lighthouse_audit "$url" "mobile" "$RUN_DIR"
        fi
        
        if [[ "$MOBILE_ONLY" != true ]]; then
            run_lighthouse_audit "$url" "desktop" "$RUN_DIR"
        fi
    done
    
    # Generate summary
    if [[ "$GENERATE_REPORT" == true ]]; then
        generate_summary
    fi
    
    echo ""
    log "🎉 Performance audit completed!"
    echo ""
    echo -e "${BLUE}Results saved to:${NC} $RUN_DIR"
    
    if [[ "$GENERATE_REPORT" == true ]]; then
        echo -e "${BLUE}Summary report:${NC} $RUN_DIR/summary.html"
        
        if [[ "$OPEN_REPORT" == true ]]; then
            if command -v open &> /dev/null; then
                open "$RUN_DIR/summary.html"
            elif command -v xdg-open &> /dev/null; then
                xdg-open "$RUN_DIR/summary.html"
            else
                echo "Open $RUN_DIR/summary.html in your browser to view the results"
            fi
        fi
    fi
    
    echo ""
    echo -e "${YELLOW}Performance Tips:${NC}"
    echo "  • Aim for Performance Score ≥ 90"
    echo "  • First Contentful Paint < 1.8s"
    echo "  • Largest Contentful Paint < 2.5s"
    echo "  • Cumulative Layout Shift < 0.1"
    echo "  • Time to Interactive < 3.8s"
}

# Run main function
main "$@"
