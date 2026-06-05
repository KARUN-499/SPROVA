#!/bin/bash
set -e

git clone https://github.com/flutter/flutter.git --depth 1 -b stable flutter-sdk
export PATH="$PATH:$(pwd)/flutter-sdk/bin"
flutter config --enable-web
flutter pub get --no-example
flutter build web --release \
  --dart-define=SUPABASE_URL=$SUPABASE_URL \
  --dart-define=SUPABASE_ANON_KEY=$SUPABASE_ANON_KEY \
  --dart-define=RAZORPAY_KEY_ID=$RAZORPAY_KEY_ID