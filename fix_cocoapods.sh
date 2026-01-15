#!/bin/bash

# Fix CocoaPods build errors
# Run this script from the project root

echo "🧹 Cleaning Flutter..."
flutter clean

echo "📦 Cleaning iOS build artifacts..."
cd ios
rm -rf Pods
rm -rf Podfile.lock
rm -rf .symlinks
rm -rf ~/Library/Developer/Xcode/DerivedData/*

echo "📥 Getting Flutter dependencies..."
cd ..
flutter pub get

echo "🔧 Installing CocoaPods..."
cd ios
pod deintegrate || true
pod install --repo-update

echo "✅ Done! Now open Xcode and build again."
echo "💡 If errors persist, close Xcode completely and reopen it."

