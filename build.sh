#!/bin/bash

# CareQA Flutter Build Script
# This script helps build and run the CareQA applications

echo "🚀 CareQA Flutter Application Build Script"
echo "=========================================="

# Function to check if Flutter is installed
check_flutter() {
    if ! command -v flutter &> /dev/null; then
        echo "❌ Flutter is not installed or not in PATH"
        echo "Please install Flutter from: https://flutter.dev/docs/get-started/install"
        exit 1
    fi
    echo "✅ Flutter is installed"
}

# Function to build admin app
build_admin() {
    echo "🔨 Building Admin App..."
    cd admin-app
    flutter pub get
    if [ $? -eq 0 ]; then
        echo "✅ Admin app dependencies installed successfully"
    else
        echo "❌ Failed to install admin app dependencies"
        exit 1
    fi
    cd ..
}

# Function to build staff app
build_staff() {
    echo "🔨 Building Staff App..."
    cd staff-app
    flutter pub get
    if [ $? -eq 0 ]; then
        echo "✅ Staff app dependencies installed successfully"
    else
        echo "❌ Failed to install staff app dependencies"
        exit 1
    fi
    cd ..
}

# Function to run admin app
run_admin() {
    echo "📱 Running Admin App..."
    cd admin-app
    flutter run
    cd ..
}

# Function to run staff app
run_staff() {
    echo "📱 Running Staff App..."
    cd staff-app
    flutter run
    cd ..
}

# Function to show help
show_help() {
    echo "Usage: $0 [OPTION]"
    echo ""
    echo "Options:"
    echo "  build-admin    Build admin app dependencies"
    echo "  build-staff    Build staff app dependencies"
    echo "  build-all      Build both apps"
    echo "  run-admin      Run admin app"
    echo "  run-staff      Run staff app"
    echo "  run-all        Run both apps (in separate terminals)"
    echo "  help           Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 build-all"
    echo "  $0 run-admin"
    echo "  $0 help"
}

# Main script logic
case "$1" in
    "build-admin")
        check_flutter
        build_admin
        ;;
    "build-staff")
        check_flutter
        build_staff
        ;;
    "build-all")
        check_flutter
        build_admin
        build_staff
        echo "✅ All apps built successfully!"
        ;;
    "run-admin")
        check_flutter
        build_admin
        run_admin
        ;;
    "run-staff")
        check_flutter
        build_staff
        run_staff
        ;;
    "run-all")
        check_flutter
        build_admin
        build_staff
        echo "📱 Opening admin app in new terminal..."
        gnome-terminal --title="CareQA Admin App" -- bash -c "cd admin-app && flutter run; read -p 'Press Enter to close...'"
        echo "📱 Opening staff app in new terminal..."
        gnome-terminal --title="CareQA Staff App" -- bash -c "cd staff-app && flutter run; read -p 'Press Enter to close...'"
        ;;
    "help"|"-h"|"--help")
        show_help
        ;;
    "")
        echo "❌ No option provided"
        show_help
        exit 1
        ;;
    *)
        echo "❌ Unknown option: $1"
        show_help
        exit 1
        ;;
esac