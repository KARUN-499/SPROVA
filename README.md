# Sprova 📚

## Overview
Sprova is a **Flutter** application that lets users enroll in courses, make payments via **Razorpay**, and store enrollment data in **Supabase**. The codebase has been **fully cleaned** to remove any hard‑coded secrets (Supabase keys, Razorpay secrets) and includes a placeholder `.env.example` for developers.

---

## Features
- **Authentication** – Supabase client initialised via environment variables (`SUPABASE_URL` & `SUPABASE_ANON_KEY`).
- **Admin Dashboard** – Secure admin screen guarded by a fixed admin email.
- **Payments** – Razorpay integration with server‑side edge functions (`create-order`, `verify-payment`).
- **Cross‑platform** – Runs on Android, iOS, Web, macOS, Linux, and Windows.

---

## Getting Started
1. **Clone the repository**
   ```bash
   git clone https://github.com/KARUN-499/SPROVA.git
   cd SPROVA
   ```
2. **Install Flutter** (≥ 3.24) – see the official docs.
3. **Create a local `.env`** (never commit this file):
   ```dotenv
   SUPABASE_URL=your_supabase_url
   SUPABASE_ANON_KEY=your_anon_key
   RAZORPAY_KEY_ID=your_razorpay_key_id
   ```
4. **Run the app**
   ```bash
   flutter pub get
   # Android / iOS
   flutter run
   # Web (provide compile‑time defines)
   flutter run -d chrome \
     --dart-define=SUPABASE_URL=$SUPABASE_URL \
     --dart-define=SUPABASE_ANON_KEY=$SUPABASE_ANON_KEY
   ```

---

## Project Structure (visual)
```
SPROVA/
├─ .env.example          # Placeholder env file
├─ lib/                  # Flutter source
│   ├─ main.dart
│   ├─ features/         # Feature modules (admin, dashboard, enrollment…)
│   └─ prompts.dart
├─ supabase/             # Supabase edge functions & migrations
│   ├─ functions/        # Deno TS functions
│   └─ migrations/       # SQL migrations
├─ test/                 # Widget tests
└─ README.md             # This file
```

---

## Security Notes
- **Never commit the real `.env`** – it is ignored via `.gitignore`.
- **Keep API keys out of source** – use GitHub secrets or CI env variables for CI/CD.
- **Admin bypass flags** were removed to prevent accidental back‑doors.

---

## Contributing
Feel free to open issues or PRs. Follow these steps before submitting:
1. Fork the repo.
2. Create a feature branch off `main`.
3. Ensure your code runs with `flutter analyze` and passes existing tests.
4. Submit a pull request.

---

## License
This project is licensed under the **MIT License**.
