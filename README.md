# 🔥 Focus Forge — Developer Documentation

> A focused study session tracker for students with daily streaks, subject tracking, push notifications, and weekly analytics.

---

## Table of Contents

1. [Project Overview](#project-overview)
2. [Tech Stack](#tech-stack)
3. [Architecture](#architecture)
4. [Features Breakdown](#features-breakdown)
5. [Database Schema](#database-schema)
6. [UI/UX Design Guidelines](#uiux-design-guidelines)
7. [Authentication Flow](#authentication-flow)
8. [Push Notifications](#push-notifications)
9. [Music Integration](#music-integration)
10. [Screens & Navigation](#screens--navigation)
11. [Known Limitations / Future Scope](#known-limitations--future-scope)

---

## Project Overview

**Focus Forge** is a cross-platform (Android & iOS) study productivity app built with Flutter, designed for students preparing for competitive or board exams. It encourages consistent daily study habits by maintaining a **daily streak** system — the user must complete at least one 2-hour study session every 24 hours, or their streak resets.

Each session is tied to a subject and topic, registered with a photo, and logged to Firebase. The app features neon-dark UI theming, ambient background music, stats visualizations, and push notification reminders.

---

## Tech Stack

| Layer | Technology |
|---|---|
| Language | Dart |
| Framework | Flutter (stable channel) |
| Backend / Database | Firebase (Firestore + Auth + Storage) |
| Push Notifications | Firebase Cloud Messaging (FCM) + `flutter_local_notifications` |
| Charts | `fl_chart` |
| Music Playback | `audioplayers` or `just_audio` |
| Image Capture / Upload | `image_picker` |
| State Management | Riverpod (or Provider / BLoC) |
| Navigation | `go_router` |
| Background Tasks | `workmanager` (Android) / BGTaskScheduler (iOS via plugin) |
| Architecture Pattern | MVVM / Clean Architecture |
| Notifications Scheduling | `flutter_local_notifications` + `workmanager` |

---

## Architecture

```
lib/
├── main.dart
├── app.dart                    → MaterialApp, theme, router setup
├── core/
│   ├── theme/                  → Neon dark theme, colors, text styles
│   ├── router/                 → go_router route definitions
│   └── utils/                  → StreakCalculator, DateUtils, etc.
├── features/
│   ├── auth/
│   │   ├── data/               → FirebaseAuthRepository
│   │   ├── domain/             → AuthUseCase, User model
│   │   └── presentation/       → LoginScreen, RegisterScreen, AuthNotifier
│   ├── home/
│   │   ├── data/               → TaskRepository, StreakRepository
│   │   ├── domain/             → Task, StreakInfo models
│   │   └── presentation/       → HomeScreen, HomeNotifier
│   ├── session/
│   │   ├── data/               → SessionRepository
│   │   ├── domain/             → Session model, SessionUseCase
│   │   └── presentation/       → SessionStartScreen, SessionNotifier
│   ├── stats/
│   │   ├── data/               → StatsRepository
│   │   ├── domain/             → StatsUseCase
│   │   └── presentation/       → StatsScreen, StatsNotifier
│   └── settings/
│       ├── data/               → UserProfileRepository
│       └── presentation/       → SettingsScreen
├── services/
│   ├── notification_service.dart
│   └── music_service.dart
└── shared/
    └── widgets/                → GlassCard, NeonButton, SubjectChip, etc.
```

---

## Features Breakdown

### 1. Authentication

- Email/Password login and registration via **Supabase Auth**
- Persistent login session using Firebase's built-in token management (`authStateChanges` stream)
- Logout available from Settings tab
- All data (sessions, tasks, streaks) is tied to the authenticated user's UID
- `go_router` redirect guards prevent unauthenticated access to any tab

### 2. Daily Streak System

- A streak is maintained if the user completes **at least one 2-hour session within every 24-hour window**
- Streak counter resets to 0 if the requirement is missed
- Streak data is stored in Firestore under the user's document
- App checks streak validity on launch using `authStateChanges` + Firestore fetch

### 3. Session Flow

- "Start Session" button is **only on the Home tab**
- Tapping it navigates to a **new full-screen route** via `go_router` (not a modal/bottom sheet)
- On the session start page:
  - User selects a **subject** from the predefined dropdown/chip list
  - User enters the **topic** being studied (free text field)
  - A **photo must be taken or uploaded** to register the session (via `image_picker`)
  - Timer begins counting upward (`Stopwatch` + `Timer.periodic`)
  - Background plays **soft ambient music** via `audioplayers`
  - UI uses dark + neon theme with glowing timer animation
- Session is saved to Firestore on completion (minimum 2 hours counts for streak)

### 4. Subjects

The following subjects are available for selection during a session:

- Physics
- Chemistry
- Biology
- Maths
- Hindi
- English
- Computer Application
- Geography
- History and Civics

### 5. Home Tab

Displayed items:

- **Streak Info** — Current streak count and days active badge
- **Profile Preview** — Name and profile photo (tappable → Settings)
- **To-Do List for Today** — User-added tasks for the current day
- **Scheduled Important Tasks** — Future-dated reminders/tasks, sorted by date
- **Pie Chart Summary** — `fl_chart` PieChart of time per subject this week
- **Start Session Button** — The only entry point to begin a study session

### 6. Stats Tab

Displayed items:

- **Hours Spent per Subject** — `fl_chart` BarChart, filterable by week/month
- **My Progress on Each Topic** — Expandable list grouped by subject; shows dates covered
- **Weekly Generated Report** — Auto-generated summary of past 7 days: total hours, top subject, streak status, all topics covered

### 7. Settings

Accessible from the bottom nav:

- Profile Photo — editable, stored in Firebase Storage, displayed via `CachedNetworkImage`
- Name — editable, saved to Firestore
- Email Address — display only (from Firebase Auth)
- Logout — calls `FirebaseAuth.instance.signOut()`, redirects to Login via `go_router`

### 8. Push Notifications

- If the user has **not completed a 2-hour session by 8:00 PM**, a local push notification fires
- Scheduled via `flutter_local_notifications` + `workmanager` background task
- FCM used for any future server-triggered notifications
- Notification deep-links to the session start route on tap

### 9. Ambient Music

- Starts automatically when a session begins using `audioplayers` or `just_audio`
- Bundled lofi/ambient `.mp3` tracks in `assets/music/`
- Loops continuously during the session
- Volume set low by default (subtle, not intrusive)
- Stops cleanly when session ends or app is backgrounded (audio focus handling)

---

## Database Schema

All data is stored in **Firebase Firestore**.

### Collection: `users/{uid}`

```
{
  uid: string,
  name: string,
  email: string,
  photoUrl: string,
  currentStreak: number,
  longestStreak: number,
  lastSessionDate: timestamp
}
```

### Collection: `users/{uid}/sessions/{sessionId}`

```
{
  sessionId: string,
  subject: string,           // e.g. "Physics"
  topic: string,             // e.g. "Laws of Motion"
  startTime: timestamp,
  endTime: timestamp,
  durationMinutes: number,
  photoUrl: string,          // Firebase Storage URL of session photo
  countedForStreak: boolean
}
```

### Collection: `users/{uid}/tasks/{taskId}`

```
{
  taskId: string,
  title: string,
  dueDate: timestamp,
  isCompleted: boolean,
  isImportant: boolean
}
```

---

## UI/UX Design Guidelines

- **Theme:** Dark background (`#0A0A0F`) with bold neon accents — defined in `core/theme/`
- **Primary Neon:** Electric purple/violet (`#A855F7`) or cyan (`#00FFFF`)
- **Secondary Neon:** Hot pink (`#FF2079`) for highlights and CTAs
- **Glass Effect:** `BackdropFilter` + `ImageFilter.blur` with semi-transparent `Container` — reusable as `GlassCard` widget
- **Typography:** Bold sans-serif — Exo 2 or Rajdhani via `google_fonts` package
- **During Session:** Darker overlay, pulsing `AnimatedContainer` glow on timer, neon color on digits
- **Icons:** `iconsax` or `phosphor_flutter` package for consistent neon-tinted icons
- **Transitions:** `go_router` with custom `CustomTransitionPage` (slide/fade)

---

## Authentication Flow

```
App Launch
    │
    ▼
authStateChanges stream (Firebase)
    │
   User != null → Home Screen (bottom nav)
    │
   User == null → Login Screen
                    │
                    ├── Login → Home Screen
                    └── Register → Home Screen
```

`go_router` redirect callback handles this automatically — no manual Navigator calls needed.

---

## Push Notifications

`workmanager` registers a daily background task. At **8:00 PM local time**, the task checks Firestore for today's sessions. If no session ≥ 2 hours is found, `flutter_local_notifications` fires a notification:

> **"Don't break your streak! 🔥"**
> You haven't studied today yet. Start a session before midnight!

Tapping the notification navigates to `/session/start` via notification payload + `go_router`.

---

## Screens & Navigation

| Screen | Route | Description |
|---|---|---|
| Login | `/login` | Email/password login |
| Register | `/register` | New account creation |
| Home | `/home` | Main dashboard (bottom nav tab 1) |
| Start Session | `/session/start` | New page opened from Home only |
| Stats | `/stats` | Analytics (bottom nav tab 2) |
| Settings | `/settings` | Profile & logout (bottom nav tab 3) |

Bottom navigation is a persistent `NavigationBar` widget wrapping the three main tabs. Session start is a full push route outside the bottom nav shell.

---

## Flutter Packages Used

```yaml
dependencies:
  firebase_core:
  firebase_auth:
  cloud_firestore:
  firebase_storage:
  firebase_messaging:
  flutter_local_notifications:
  go_router:
  riverpod:          # or flutter_bloc
  fl_chart:
  audioplayers:      # or just_audio
  image_picker:
  workmanager:
  google_fonts:
  cached_network_image:
  intl:
```

---

## Known Limitations / Future Scope

- **Offline support:** Firestore offline persistence can be enabled via `settings: const Settings(persistenceEnabled: true)` — not enabled in v1.
- **Custom music:** Only bundled ambient tracks available; user uploads planned for v2.
- **Multiple sessions per day:** Only the first ≥2-hour session counts for streak; all sessions are still logged for stats.
- **Social features:** Leaderboards, friend comparisons, and shared study rooms planned for v2.
- **AI weekly report:** Currently template-based; Claude API integration considered for v2 to generate personalized insights.
- **iOS background tasks:** `workmanager` behavior on iOS is limited by OS restrictions; notifications may not fire reliably when app is fully killed.
