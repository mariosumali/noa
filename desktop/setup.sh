#!/bin/bash

# noa Desktop App Setup Script
# This creates the Xcode project structure

echo "🚀 Setting up noa desktop app..."

# Check for Xcode
if ! command -v xcodebuild &> /dev/null; then
    echo "❌ Xcode is not installed. Please install Xcode from the App Store."
    exit 1
fi

cd "$(dirname "$0")"

# Create Xcode project using swift package
echo "📦 Creating Xcode project..."

cat > Package.swift << 'EOF'
// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "noa",
    platforms: [.macOS(.v13)],
    products: [
        .executable(name: "noa", targets: ["noa"])
    ],
    targets: [
        .executableTarget(
            name: "noa",
            path: "noa"
        )
    ]
)
EOF

# Generate Xcode project
swift package generate-xcodeproj

if [ -f "noa.xcodeproj/project.pbxproj" ]; then
    echo "✅ Xcode project created: noa.xcodeproj"
    echo ""
    echo "📝 Next steps:"
    echo "1. Open noa.xcodeproj in Xcode"
    echo "2. Set your development team in Signing & Capabilities"
    echo "3. Update Info.plist with required permissions"
    echo "4. Create ~/.noa_config with your OPENAI_API_KEY"
    echo "5. Build and run!"
else
    echo "❌ Failed to create Xcode project"
    echo "Please create the project manually in Xcode (see README.md)"
fi
