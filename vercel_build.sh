#!/bin/bash
# Clone the Flutter repository (stable channel)
git clone https://github.com/flutter/flutter.git -b stable
export PATH="$PATH:`pwd`/flutter/bin"

# Get project dependencies
flutter pub get

# Generate .env file from Vercel environment variables
echo "SUPABASE_URL=$SUPABASE_URL" > .env
echo "SUPABASE_ANON_KEY=$SUPABASE_ANON_KEY" >> .env

# Build the Flutter web application
flutter build web --release
