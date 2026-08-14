#!/bin/bash

echo "🔨 Building CareQA APKs for Physical Device Testing"
echo "=================================================="
echo ""

# Check if Flutter is installed
if ! command -v flutter &> /dev/null; then
    echo "❌ Flutter is not installed or not in PATH"
    echo "Please install Flutter and ensure it's available in your PATH"
    exit 1
fi

# Check if Supabase credentials are set
if [ ! -f "admin-app/.env" ] || [ ! -f "staff-app/.env" ]; then
    echo "❌ Environment files not found"
    echo "Please ensure .env files exist in both admin-app and staff-app directories"
    exit 1
fi

echo "✅ Environment check passed"
echo ""

# Build Admin App APK
echo "🔨 Building Admin App APK..."
echo "============================="
cd admin-app

# Clean previous builds
echo "🧹 Cleaning previous builds..."
flutter clean

# Get dependencies
echo "📦 Getting dependencies..."
flutter pub get

# Build release APK
echo "🏗️  Building release APK..."
flutter build apk --release

if [ $? -eq 0 ]; then
    echo "✅ Admin App APK built successfully!"
    echo "📁 Location: build/app/outputs/flutter-apk/app-release.apk"
    ADMIN_APK_PATH="build/app/outputs/flutter-apk/app-release.apk"
else
    echo "❌ Admin App build failed!"
    exit 1
fi

echo ""

# Build Staff App APK
echo "🔨 Building Staff App APK..."
echo "============================"
cd ../staff-app

# Clean previous builds
echo "🧹 Cleaning previous builds..."
flutter clean

# Get dependencies
echo "📦 Getting dependencies..."
flutter pub get

# Build release APK
echo "🏗️  Building release APK..."
flutter build apk --release

if [ $? -eq 0 ]; then
    echo "✅ Staff App APK built successfully!"
    echo "📁 Location: build/app/outputs/flutter-apk/app-release.apk"
    STAFF_APK_PATH="build/app/outputs/flutter-apk/app-release.apk"
else
    echo "❌ Staff App build failed!"
    exit 1
fi

echo ""

# Summary
echo "🎉 Build Complete!"
echo "=================="
echo ""
echo "📁 Generated APKs:"
echo "  Admin App: $ADMIN_APK_PATH"
echo "  Staff App: $STAFF_APK_PATH"
echo ""
echo "📱 Next Steps:"
echo "  1. Copy the APK files to your Android devices"
echo "  2. Install the APKs on the devices"
echo "  3. Run the test workflow using: ./test_core_workflow.sh"
echo ""
echo "🔧 Troubleshooting:"
echo "  - If builds fail, check Flutter installation and Android SDK"
echo "  - Ensure Android Studio is installed with Android SDK"
echo "  - Check that environment variables are properly set"
echo "  - Verify Supabase credentials in .env files"