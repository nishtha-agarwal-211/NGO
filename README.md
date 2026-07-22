<p align="center">
  <h1 align="center">🌿 NGO Manager</h1>
  <p align="center">
    <strong>A complete management & engagement platform for non-profit organizations</strong>
  </p>
  <p align="center">
    Built with Flutter · Powered by Supabase · Designed for impact
  </p>
</p>

---

## ✨ Overview

**NGO Manager** is an all-in-one mobile and web application that helps non-profit organizations centralize their operations — from managing members and donors to tracking projects, documenting events with photos, and archiving press coverage. Built for single-admin use with a clean, modern interface.

> **Why this exists:** NGOs often juggle spreadsheets, WhatsApp groups, and paper records to manage their operations. This app replaces all of that with a single, unified platform — at zero hosting cost.

---

## 🎯 Key Features

### 📊 Dashboard

- At-a-glance stats: total members, donors, monthly donations, events held
- Upcoming events for the current week
- Birthday & anniversary reminders (next 7 days)
- Recently added donors

### 👥 Member Management

- Full member directory with search & filtering
- Profile details: name, photo, mobile, email, address, DOB, anniversary, role
- One-tap WhatsApp/SMS/call shortcuts for quick outreach
- Automated birthday & anniversary reminders

### 💰 Donor Management

- Add donors manually or auto-create during event logging
- Track donation history: type (cash/kind/service), amount, linked project
- Duplicate detection by mobile number
- Tag donors as one-time or recurring

### 📋 Project & Event Management

- **Recurring projects** — e.g., weekly food donation drives with auto-generated event instances
- **Ongoing campaigns** — e.g., school fee sponsorships, medical aid
- Per-event tracking: attendance, beneficiaries, donations, expenses, photos, notes
- Calendar view of all upcoming events

### 📸 Media & Photo Management

- Upload photos directly from camera or gallery per event
- Auto-tagged with project name + event date
- Compressed thumbnails for fast gallery loading
- Photo/video gallery views per project and event

### 📰 News & Media Coverage

- Archive third-party press coverage (newspaper articles, YouTube videos)
- Auto-embedded YouTube player for video items
- Upload clipping images for print coverage
- Filterable by type (Articles / Videos) and year
- **Public-facing** — viewable without login for donors and sponsors

### 🔐 Authentication

- Single admin login via email/password (Supabase Auth)
- Public read-only access for the News archive
- Designed for future multi-role expansion

---

## 🛠 Tech Stack

| Layer                | Technology                                                  |
| -------------------- | ----------------------------------------------------------- |
| **Frontend**         | Flutter 3.x (Dart)                                          |
| **State Management** | Riverpod (with code generation)                             |
| **Navigation**       | GoRouter                                                    |
| **Backend & Auth**   | Supabase (PostgreSQL + Auth + Storage)                      |
| **Local Database**   | Drift (SQLite) for offline support                          |
| **Data Classes**     | Freezed + JSON Serializable                                 |
| **Notifications**    | flutter_local_notifications                                 |
| **Background Tasks** | Workmanager                                                 |
| **UI Components**    | Google Fonts, Shimmer, Table Calendar, Staggered Animations |
| **Image Handling**   | image_picker, flutter_image_compress, cached_network_image  |
| **Connectivity**     | connectivity_plus (offline detection & sync)                |

---

## 🏗 Architecture

```
┌─────────────────────────────────────────────────┐
│                  Flutter App                    │
│                                                 │
│  ┌───────────┐  ┌───────────┐  ┌─────────────┐  │
│  │  Screens  │  │  Widgets  │  │   Config    │  │
│  │           │  │           │  │ (Theme,     │  │
│  │ Dashboard │  │ App Shell │  │  Router,    │  │
│  │ Members   │  │ Volunteer │  │  Constants) │  │
│  │ Donors    │  │  Picker   │  │             │  │
│  │ Projects  │  └───────────┘  └─────────────┘  │
│  │ Events    │                                  │
│  │ Photos    │  ┌───────────────────────────┐   │
│  │ News      │  │        Services           │   │
│  │ Auth      │  │  Auth · Member · Donor    │   │
│  └───────────┘  │  Project · Event · Photo  │   │
│                 │  News · Notification      │   │
│                 │  Background Worker        │   │
│                 └───────────────────────────┘   │
│                                                 │
│  ┌──────────────────────────────────────────┐   │
│  │          Models (Freezed + JSON)         │   │
│  │  Member · Donor · Donation · Project     │   │
│  │  Event · Photo · NewsItem · Enums        │   │
│  └──────────────────────────────────────────┘   │
└──────────────────────┬──────────────────────────┘
                       │ REST API (HTTPS)
              ┌────────┴────────┐
              │    Supabase     │
              │                 │
              │  ┌───────────┐  │
              │  │ PostgreSQL│  │
              │  │ Database  │  │
              │  └───────────┘  │
              │  ┌───────────┐  │
              │  │  Storage  │  │
              │  │ (Photos)  │  │
              │  └───────────┘  │
              │  ┌───────────┐  │
              │  │   Auth    │  │
              │  └───────────┘  │
              └─────────────────┘
```

---

## 📁 Project Structure

```
ngo/
├── ngo_app/                     # Flutter application
│   ├── lib/
│   │   ├── main.dart            # App entry point & initialization
│   │   ├── config/
│   │   │   ├── constants.dart   # App-wide constants
│   │   │   ├── router.dart      # GoRouter route definitions
│   │   │   ├── supabase_config.dart  # Supabase client setup
│   │   │   └── theme.dart       # Material theme & design tokens
│   │   ├── models/              # Freezed data classes
│   │   │   ├── member.dart
│   │   │   ├── donor.dart
│   │   │   ├── donation.dart
│   │   │   ├── project.dart
│   │   │   ├── event.dart
│   │   │   ├── event_volunteer.dart
│   │   │   ├── photo.dart
│   │   │   ├── news_item.dart
│   │   │   └── enums.dart
│   │   ├── screens/             # Feature screens
│   │   │   ├── auth/            # Login & authentication
│   │   │   ├── dashboard/       # Home dashboard
│   │   │   ├── members/         # Member directory & forms
│   │   │   ├── donors/          # Donor management
│   │   │   ├── projects/        # Project listing & details
│   │   │   ├── events/          # Event tracking & logging
│   │   │   ├── photos/          # Photo galleries
│   │   │   └── news/            # News & media archive
│   │   ├── services/            # Business logic & API layer
│   │   │   ├── auth_service.dart
│   │   │   ├── member_service.dart
│   │   │   ├── donor_service.dart
│   │   │   ├── project_service.dart
│   │   │   ├── event_service.dart
│   │   │   ├── photo_service.dart
│   │   │   ├── news_service.dart
│   │   │   ├── notification_service.dart
│   │   │   └── background_worker.dart
│   │   └── widgets/             # Shared UI components
│   │       ├── app_shell.dart
│   │       └── volunteer_picker.dart
│   ├── assets/
│   │   └── images/              # Static image assets
│   ├── android/                 # Android platform config
│   ├── ios/                     # iOS platform config
│   ├── web/                     # Web platform config
│   └── pubspec.yaml             # Dependencies & metadata
│
├── supabase/                    # Backend configuration
│   ├── migrations/
│   │   ├── 001_initial_schema.sql    # Core database schema
│   │   └── 002_add_video_support.sql # Video content type support
│   └── storage_policies.sql     # Storage bucket access policies
│
├── NGO_App_PRD.md               # Product Requirements Document
└── README.md                    # ← You are here
```

---

## 🚀 Getting Started

### Prerequisites

- **Flutter SDK** ≥ 3.8.1 — [Install Flutter](https://docs.flutter.dev/get-started/install)
- **Dart SDK** ≥ 3.8.1 (bundled with Flutter)
- **Supabase Account** — [Create free account](https://supabase.com)
- **Chrome** (for web) or Android/iOS device/emulator

### 1. Clone the repository

```bash
git clone <repository-url>
cd ngo
```

### 2. Set up Supabase

1. Create a new project on [Supabase](https://app.supabase.com)
2. Run the migration scripts in order:
   ```
   supabase/migrations/001_initial_schema.sql
   supabase/migrations/002_add_video_support.sql
   ```
3. Apply storage policies:
   ```
   supabase/storage_policies.sql
   ```
4. Note your **Project URL** and **Anon Key** from the Supabase dashboard

### 3. Configure the app

Update `ngo_app/lib/config/supabase_config.dart` with your Supabase credentials:

```dart
static const String supabaseUrl = 'https://YOUR_PROJECT.supabase.co';
static const String supabaseAnonKey = 'YOUR_ANON_KEY';
```

### 4. Install dependencies

```bash
cd ngo_app
flutter pub get
```

### 5. Generate code (Freezed & Riverpod)

```bash
dart run build_runner build --delete-conflicting-outputs
```

### 6. Run the app

```bash
# Web
flutter run -d chrome

# Android
flutter run -d <device-id>

# iOS
flutter run -d <device-id>
```

---

## 💰 Cost

This app runs entirely within **Supabase's free tier**:

| Resource         | Free Tier Limit | Typical Usage                                 |
| ---------------- | --------------- | --------------------------------------------- |
| Database         | 500 MB          | More than sufficient for thousands of records |
| File Storage     | 1 GB            | Ample with compressed thumbnails              |
| Auth             | 50,000 MAU      | Only 1 admin user needed                      |
| **Monthly Cost** |                 | **$0**                                        |

---

## 🗺 Roadmap

- [x] **Phase 1 (MVP)** — Member management, donor tracking, project & event management, photo uploads, news archive
- [ ] **Phase 2** — Dashboard analytics, multi-role permissions, push notifications, shareable news links
- [ ] **Phase 3** — Online donation/payment integration, beneficiary case files, PDF/Excel report exports

---

## 📄 License

This project is private and intended for internal NGO use.

---

<p align="center">
  <sub>Built with ❤️ for non-profits that make a difference</sub>
</p>
