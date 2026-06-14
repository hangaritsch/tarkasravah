#!/bin/bash

# Navigate to project folder
cd "$(dirname "$0")"

echo "Initializing Git repository..."
git init

# Check if .gitignore exists, create a default one if not
if [ ! -f .gitignore ]; then
  echo "Creating default .gitignore..."
  cat <<EOT >> .gitignore
.dart_tool/
.flutter-plugins
.flutter-plugins-dependencies
.packages
.pub-cache/
.pub/
build/
EOT
fi

echo "Staging all files..."
git add .

echo "Creating initial commit..."
git commit -m "Initial commit: Tarkaśravaḥ Sanskrit Reader with offline first CDN sync"

echo "Renaming default branch to main..."
git branch -M main

echo "Adding GitHub remote origin..."
# Check if remote already exists, remove it if so, then add new
git remote remove origin 2>/dev/null
git remote add origin https://github.com/hangaritsch/tarkasravah.git

echo ""
echo "=========================================================="
echo "Local Git repository has been configured!"
echo "If you have already created the public repository on GitHub,"
echo "you can push it now by running:"
echo "  cd /opt/homebrew/var/www/app/tarkasravah && git push -u origin main"
echo "=========================================================="
EOT
