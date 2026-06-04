#!/bin/bash
set -e

if [ -d "./flutter_sdk" ]; then
  FLUTTER_DIR="./flutter_sdk"
else
  FLUTTER_DIR="./flutter-sdk"
  if [ ! -d "$FLUTTER_DIR" ]; then
    git clone https://github.com/flutter/flutter.git --depth 1 -b stable "$FLUTTER_DIR"
  fi
fi

export PATH="$PATH:$(pwd)/$FLUTTER_DIR/bin"
flutter --version
flutter config --enable-web
flutter pub get
flutter build web --release \
  --dart-define=SUPABASE_URL=${SUPABASE_URL:-} \
  --dart-define=SUPABASE_ANON_KEY=${SUPABASE_ANON_KEY:-} \
  --dart-define=RAZORPAY_KEY_ID=${RAZORPAY_KEY_ID:-} 2>&1
 echo "Exit code: $?"
