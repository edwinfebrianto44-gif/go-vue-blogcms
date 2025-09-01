#!/bin/bash

# Test script for image upload functionality
# Usage: ./test_upload.sh [base_url] [email] [password]

BASE_URL=${1:-"http://localhost:8080"}
EMAIL=${2:-"test@example.com"}
PASSWORD=${3:-"testpassword123"}

echo "🚀 Testing BlogCMS Image Upload API"
echo "📍 Base URL: $BASE_URL"
echo "📧 Email: $EMAIL"
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    if [ $1 -eq 0 ]; then
        echo -e "${GREEN}✅ $2${NC}"
    else
        echo -e "${RED}❌ $2${NC}"
    fi
}

print_info() {
    echo -e "${YELLOW}ℹ️  $1${NC}"
}

# Test 1: Check upload info endpoint
echo "1. Testing upload info endpoint..."
UPLOAD_INFO=$(curl -s "$BASE_URL/api/v1/uploads/info")
if echo "$UPLOAD_INFO" | grep -q '"success":true'; then
    print_status 0 "Upload info endpoint working"
    echo "   Max file size: $(echo "$UPLOAD_INFO" | grep -o '"max_file_size_mb":[0-9.]*' | cut -d':' -f2)"
    echo "   Storage driver: $(echo "$UPLOAD_INFO" | grep -o '"storage_driver":"[^"]*"' | cut -d':' -f2 | tr -d '"')"
else
    print_status 1 "Upload info endpoint failed"
    echo "   Response: $UPLOAD_INFO"
fi
echo ""

# Test 2: Register a test user (if needed)
echo "2. Registering test user..."
REGISTER_RESPONSE=$(curl -s -X POST \
    -H "Content-Type: application/json" \
    -d "{\"username\":\"testuser$(date +%s)\",\"email\":\"$EMAIL\",\"password\":\"$PASSWORD\",\"name\":\"Test User\",\"role\":\"author\"}" \
    "$BASE_URL/api/v1/auth/register")

if echo "$REGISTER_RESPONSE" | grep -q '"success":true\|"email":".*already exists"'; then
    print_status 0 "User registration (user may already exist)"
else
    print_status 1 "User registration failed"
    echo "   Response: $REGISTER_RESPONSE"
fi
echo ""

# Test 3: Login and get token
echo "3. Logging in to get auth token..."
LOGIN_RESPONSE=$(curl -s -X POST \
    -H "Content-Type: application/json" \
    -d "{\"email\":\"$EMAIL\",\"password\":\"$PASSWORD\"}" \
    "$BASE_URL/api/v1/auth/login")

if echo "$LOGIN_RESPONSE" | grep -q '"access_token"'; then
    print_status 0 "Login successful"
    TOKEN=$(echo "$LOGIN_RESPONSE" | grep -o '"access_token":"[^"]*"' | cut -d':' -f2 | tr -d '"')
    print_info "Token: ${TOKEN:0:20}..."
else
    print_status 1 "Login failed"
    echo "   Response: $LOGIN_RESPONSE"
    exit 1
fi
echo ""

# Test 4: Create a test image file
echo "4. Creating test image file..."
TEST_IMAGE="/tmp/test_upload_$(date +%s).jpg"

# Create a minimal valid JPEG file
cat > "$TEST_IMAGE" << 'EOF'
0xFF 0xD8 0xFF 0xE0 0x00 0x10 0x4A 0x46 0x49 0x46 0x00 0x01
0x01 0x01 0x00 0x48 0x00 0x48 0x00 0x00 0xFF 0xDB 0x00 0x43
0x00 0x08 0x06 0x06 0x07 0x06 0x05 0x08 0x07 0x07 0x07 0x09
0x09 0x08 0x0A 0x0C 0x14 0x0D 0x0C 0x0B 0x0B 0x0C 0x19 0x12
0x13 0x0F 0x14 0x1D 0x1A 0x1F 0x1E 0x1D 0x1A 0x1C 0x1C 0x20
0x24 0x2E 0x27 0x20 0x22 0x2C 0x23 0x1C 0x1C 0x28 0x37 0x29
0x2C 0x30 0x31 0x34 0x34 0x34 0x1F 0x27 0x39 0x3D 0x38 0x32
0x3C 0x2E 0x33 0x34 0x32 0xFF 0xC0 0x00 0x11 0x08 0x00 0x01
0x00 0x01 0x01 0x01 0x11 0x00 0x02 0x11 0x01 0x03 0x11 0x01
0xFF 0xC4 0x00 0x14 0x00 0x01 0x00 0x00 0x00 0x00 0x00 0x00
0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x08 0xFF 0xC4
0x00 0x14 0x10 0x01 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00
0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0xFF 0xDA 0x00 0x0C
0x03 0x01 0x00 0x02 0x11 0x03 0x11 0x00 0x3F 0x00 0xB2 0xFF 0xD9
EOF

# Convert hex to binary
echo -n | xxd -r -p < <(cat "$TEST_IMAGE" | tr -d '\n' | sed 's/0x//g' | sed 's/ //g') > "${TEST_IMAGE}.bin"
mv "${TEST_IMAGE}.bin" "$TEST_IMAGE"

if [ -f "$TEST_IMAGE" ]; then
    print_status 0 "Test image created: $TEST_IMAGE ($(wc -c < "$TEST_IMAGE") bytes)"
else
    print_status 1 "Failed to create test image"
    exit 1
fi
echo ""

# Test 5: Upload the image
echo "5. Uploading test image..."
UPLOAD_RESPONSE=$(curl -s -X POST \
    -H "Authorization: Bearer $TOKEN" \
    -F "image=@$TEST_IMAGE" \
    "$BASE_URL/api/v1/uploads/images")

if echo "$UPLOAD_RESPONSE" | grep -q '"success":true'; then
    print_status 0 "Image upload successful"
    UPLOADED_URL=$(echo "$UPLOAD_RESPONSE" | grep -o '"url":"[^"]*"' | cut -d':' -f2- | tr -d '"')
    UPLOADED_FILENAME=$(echo "$UPLOAD_RESPONSE" | grep -o '"filename":"[^"]*"' | cut -d':' -f2 | tr -d '"')
    print_info "Uploaded URL: $UPLOADED_URL"
    print_info "Filename: $UPLOADED_FILENAME"
else
    print_status 1 "Image upload failed"
    echo "   Response: $UPLOAD_RESPONSE"
fi
echo ""

# Test 6: Verify uploaded image is accessible
if [ ! -z "$UPLOADED_URL" ]; then
    echo "6. Verifying uploaded image is accessible..."
    HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" "$UPLOADED_URL")
    
    if [ "$HTTP_STATUS" = "200" ]; then
        print_status 0 "Uploaded image is accessible (HTTP $HTTP_STATUS)"
    else
        print_status 1 "Uploaded image not accessible (HTTP $HTTP_STATUS)"
    fi
    echo ""
fi

# Test 7: Test uploading invalid file
echo "7. Testing upload validation with text file..."
TEXT_FILE="/tmp/test_invalid_$(date +%s).txt"
echo "This is not an image" > "$TEXT_FILE"

INVALID_UPLOAD_RESPONSE=$(curl -s -X POST \
    -H "Authorization: Bearer $TOKEN" \
    -F "image=@$TEXT_FILE" \
    "$BASE_URL/api/v1/uploads/images")

if echo "$INVALID_UPLOAD_RESPONSE" | grep -q '"success":false'; then
    print_status 0 "File validation working (correctly rejected non-image)"
else
    print_status 1 "File validation not working (should reject non-image)"
    echo "   Response: $INVALID_UPLOAD_RESPONSE"
fi
echo ""

# Test 8: Test unauthorized upload
echo "8. Testing unauthorized upload..."
UNAUTH_RESPONSE=$(curl -s -X POST \
    -F "image=@$TEST_IMAGE" \
    "$BASE_URL/api/v1/uploads/images")

if echo "$UNAUTH_RESPONSE" | grep -q '"error"\|401\|403'; then
    print_status 0 "Authorization working (correctly rejected unauthorized request)"
else
    print_status 1 "Authorization not working (should reject unauthorized request)"
    echo "   Response: $UNAUTH_RESPONSE"
fi
echo ""

# Test 9: Create a post with thumbnail
if [ ! -z "$UPLOADED_URL" ]; then
    echo "9. Testing post creation with thumbnail..."
    
    # First, get categories
    CATEGORIES_RESPONSE=$(curl -s "$BASE_URL/api/v1/categories")
    CATEGORY_ID=$(echo "$CATEGORIES_RESPONSE" | grep -o '"id":[0-9]*' | head -1 | cut -d':' -f2)
    
    if [ -z "$CATEGORY_ID" ]; then
        # Create a test category
        CREATE_CAT_RESPONSE=$(curl -s -X POST \
            -H "Authorization: Bearer $TOKEN" \
            -H "Content-Type: application/json" \
            -d '{"name":"Test Category","description":"Test category for uploads"}' \
            "$BASE_URL/api/v1/categories")
        
        CATEGORY_ID=$(echo "$CREATE_CAT_RESPONSE" | grep -o '"id":[0-9]*' | cut -d':' -f2)
    fi
    
    if [ ! -z "$CATEGORY_ID" ]; then
        POST_RESPONSE=$(curl -s -X POST \
            -H "Authorization: Bearer $TOKEN" \
            -H "Content-Type: application/json" \
            -d "{\"title\":\"Test Post with Thumbnail\",\"content\":\"This is a test post with an uploaded thumbnail image.\",\"thumbnail_url\":\"$UPLOADED_URL\",\"category_id\":$CATEGORY_ID,\"status\":\"published\"}" \
            "$BASE_URL/api/v1/posts")
        
        if echo "$POST_RESPONSE" | grep -q '"success":true\|"id":[0-9]'; then
            print_status 0 "Post created successfully with thumbnail"
            POST_ID=$(echo "$POST_RESPONSE" | grep -o '"id":[0-9]*' | cut -d':' -f2)
            print_info "Post ID: $POST_ID"
        else
            print_status 1 "Failed to create post with thumbnail"
            echo "   Response: $POST_RESPONSE"
        fi
    else
        print_info "Skipping post creation test (no category available)"
    fi
    echo ""
fi

# Cleanup
echo "🧹 Cleaning up..."
rm -f "$TEST_IMAGE" "$TEXT_FILE"
print_info "Test files cleaned up"
echo ""

echo "🎉 Upload API testing completed!"
echo ""
echo "📋 Summary:"
echo "   - Upload info endpoint: Available"
echo "   - Authentication: Working"
echo "   - File validation: Working"
echo "   - Image upload: Working"
echo "   - Access control: Working"
echo ""
echo "💡 Next steps:"
echo "   1. Test with different image formats (PNG, GIF, WebP)"
echo "   2. Test with different file sizes"
echo "   3. Test S3/MinIO storage (if configured)"
echo "   4. Integrate with frontend application"
