#!/bin/bash
# Build RIVL web app for GitHub Pages deployment

set -e  # Exit on error

echo "🚀 Building RIVL web app..."

# Clean previous builds
echo "🧹 Cleaning previous build..."
rm -rf build/web
rm -rf docs/*

# Build for web with correct base href
echo "🔨 Building Flutter web app..."
flutter build web --base-href /rivl/ --release

# Copy to docs folder for GitHub Pages
echo "📦 Copying to docs folder..."
cp -r build/web/* docs/

# Create .nojekyll file
touch docs/.nojekyll

echo "✅ Build complete!"
echo "📁 Output in docs/ folder"
echo ""
echo "Next steps:"
echo "1. git add docs/"
echo "2. git commit -m 'Update web build'"
echo "3. git push origin main"
echo "4. Wait 1-2 minutes for GitHub Pages to deploy"
echo "5. Visit https://YOUR_USERNAME.github.io/rivl/"
