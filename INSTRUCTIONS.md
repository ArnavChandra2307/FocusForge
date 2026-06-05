# 🧪 Focus Forge — Tester Instructions

> This document is for QA testers. It lists every feature of the app and exactly what to check when testing each one.

---

## Before You Begin

- Install the APK (Android) or run via `flutter run` on a connected device
- **Flutter version required:** Flutter stable channel (3.x or above)
- Make sure you have a working internet connection
- Allow all permissions when prompted: **Camera**, **Notifications**, **Storage/Photos**
- Use a **fresh email address** to test the registration flow from scratch
- For iOS testing: ensure the provisioning profile has notification and camera entitlements

---

## 1. Authentication

| # | Action | Expected Result |
|---|---|---|
| 1.1 | Open the app for the first time | Login screen appears — NOT home |
| 1.2 | Try logging in with wrong credentials | Error message shown below the form; no crash |
| 1.3 | Register with a new email + password | Account created, redirected to Home tab |
| 1.4 | Close and reopen the app | User stays logged in automatically |
| 1.5 | Logout from Settings tab | Redirected to Login screen immediately |
| 1.6 | Press back after logout | Should NOT go back to Home — login wall must hold |

---

## 2. Home Tab

| # | Element | Expected Result |
|---|---|---|
| 2.1 | Streak Info | Shows current streak count (e.g. "🔥 5 Day Streak") with badge |
| 2.2 | Profile section | Displays name and profile photo (avatar placeholder if not set) |
| 2.3 | To-Do List | Can add tasks, tap to mark complete, swipe or button to delete |
| 2.4 | Scheduled Important Tasks | Can add tasks with future dates; list sorted by date |
| 2.5 | Pie Chart | Renders correctly with time distribution per subject for this week |
| 2.6 | Pie Chart — no data | Shows empty state or "No sessions this week" message |
| 2.7 | Start Session Button | Present ONLY on Home tab; not visible on Stats or Settings |
| 2.8 | Tap "Start Session" | Navigates to a **new full-screen page** (not a dialog or bottom sheet) |

---

## 3. Start Session Flow

| # | Step | Expected Result |
|---|---|---|
| 3.1 | Tap "Start Session" | Full-screen session page opens with slide/fade animation |
| 3.2 | Subject selector | All 9 subjects listed: Physics, Chemistry, Biology, Maths, Hindi, English, Computer Application, Geography, History and Civics |
| 3.3 | Select a subject | Selection is highlighted in neon; previously selected item deselects |
| 3.4 | Topic input field | Free text entry; keyboard appears; accepts any text |
| 3.5 | Try starting without subject | Validation error shown — session should NOT start |
| 3.6 | Try starting without topic | Validation error shown — session should NOT start |
| 3.7 | Photo prompt | Tapping photo area shows a menu: "Take Photo" and "Choose from Gallery" |
| 3.8 | Take photo via camera | Camera opens; captured photo shows as thumbnail on session screen |
| 3.9 | Upload from gallery | Gallery opens; selected photo shows as thumbnail |
| 3.10 | Try starting without photo | Validation error shown — session should NOT start |
| 3.11 | Start session (all fields filled) | Timer starts counting up from 00:00:00 |
| 3.12 | Ambient music | Soft music starts automatically within 1–2 seconds of session start |
| 3.13 | UI during session | Background is darker; timer digits glow in neon; glass card effect visible |
| 3.14 | End session before 2 hours | Session is saved; streak is NOT updated; stats are updated |
| 3.15 | End session after 2 hours | Session saved AND streak increments by 1 |
| 3.16 | Return to Home after session | Streak count on Home reflects the update |

---

## 4. Daily Streak Logic

| # | Scenario | Expected Result |
|---|---|---|
| 4.1 | Complete a ≥ 2-hour session | Streak increments by 1 |
| 4.2 | Complete a < 2-hour session | Streak does NOT increment; session still logged |
| 4.3 | Miss a day (no session for 24+ hrs) | Streak resets to 0 on next app open |
| 4.4 | Complete multiple sessions in one day | Streak counts only once; all sessions appear in stats |
| 4.5 | Streak info after app restart | Streak count is same after fully closing and reopening the app |
| 4.6 | Longest streak | Check if longest streak is separately tracked and displayed |

> **Tip for testers:** To simulate a missed day, ask the developer to manually change `lastSessionDate` in Firestore to 2 days ago for your test UID, then reopen the app.

---

## 5. Push Notifications

| # | Scenario | Expected Result |
|---|---|---|
| 5.1 | No session completed by 8:00 PM | Notification received: "Don't break your streak! 🔥" |
| 5.2 | Session already completed today | No notification appears |
| 5.3 | Tap on the notification | App opens and navigates directly to the session start screen |
| 5.4 | Notification with app in background | Notification appears in system tray |
| 5.5 | Notification with app fully killed | Notification still arrives (FCM/workmanager delivery) |
| 5.6 | Notification permission denied | App works normally; just no notifications — no crash |

> **Tip:** To test without waiting until 8 PM, ask the developer to set the `workmanager` trigger to 2–3 minutes from now in the debug build.

---

## 6. Stats Tab

| # | Element | Expected Result |
|---|---|---|
| 6.1 | Hours per Subject chart | Bar chart showing hours per subject for the current week |
| 6.2 | Accuracy check | Hours in chart match what was actually entered in sessions |
| 6.3 | My Progress on Each Topic | Expandable sections per subject; each topic shows date it was studied |
| 6.4 | New topic appears | After completing a session with a new topic, it shows up in Stats |
| 6.5 | Weekly Report section | Summary text generated for past 7 days: total hours, top subject, streak maintained/broken, topics covered |
| 6.6 | Weekly Report — no data | Appropriate empty state or "Study this week to see your report" message |
| 6.7 | Filter (if implemented) | Switching week/month filter updates chart correctly |

---

## 7. Settings Screen

| # | Element | Expected Result |
|---|---|---|
| 7.1 | Profile photo displayed | Shows current photo or default avatar |
| 7.2 | Change profile photo | Tapping photo opens picker; new photo saved to Firebase Storage and shown |
| 7.3 | Photo reflects on Home | After changing, Home tab profile section shows updated photo |
| 7.4 | Name field | Editable; changes saved to Firestore; shown on Home tab |
| 7.5 | Email field | Displayed but NOT editable |
| 7.6 | Logout button | Signs out user; navigates to Login screen |
| 7.7 | Data after re-login | All data (streak, sessions, tasks) is intact on next login |

---

## 8. Music Playback

| # | Scenario | Expected Result |
|---|---|---|
| 8.1 | Session starts | Music begins within 1–2 seconds |
| 8.2 | Music volume | Subtle and low; should not overpower; does not require user to lower manually |
| 8.3 | Music loops | No silence or gaps; plays continuously |
| 8.4 | Session ends | Music stops cleanly |
| 8.5 | Navigate away mid-session (if allowed) | Music continues if session is still running |
| 8.6 | Incoming phone call | Music pauses (audio focus lost); resumes when call ends |
| 8.7 | Headphones plugged in | Music plays through headphones correctly |

---

## 9. UI & Theme

| # | Element | Expected Result |
|---|---|---|
| 9.1 | Overall dark theme | Deep dark background on all screens |
| 9.2 | Neon accents | Neon purple/cyan/pink visible on buttons, highlights, and active elements |
| 9.3 | Glass effect cards | Cards look frosted/translucent with a blur behind them |
| 9.4 | Session screen UI | Noticeably darker and more immersive than regular screens |
| 9.5 | Timer glow effect | Timer digits have a neon glow animation |
| 9.6 | Fonts | Bold and legible on all screen sizes; not system default |
| 9.7 | Bottom navigation | Home, Stats, Settings tabs always accessible (except during active session) |
| 9.8 | Navigation animations | Smooth slide or fade transitions between screens |
| 9.9 | Pie chart renders | Chart visible and correctly colored per subject |

---

## 10. Edge Cases & Crash Testing

| # | Scenario | Expected Result |
|---|---|---|
| 10.1 | Start session with no internet | Graceful error shown ("No internet connection"); no crash |
| 10.2 | Deny camera permission | App shows explanation dialog; does not crash; user can retry |
| 10.3 | Deny notification permission | App continues to function; just no notifications |
| 10.4 | Upload a very large image | App compresses or resizes image; does not crash or hang |
| 10.5 | Stats tab with zero sessions | Empty state UI shown; no null errors or blank screen |
| 10.6 | Rotate phone during active session | Timer and session state preserved (no reset) |
| 10.7 | Kill app during active session | Session may be lost (known limitation); app should reopen cleanly |
| 10.8 | Multiple rapid taps on "Start Session" | Should not open multiple session screens |
| 10.9 | Very long topic name entered | Text wraps or truncates gracefully; no overflow |
| 10.10 | Login on two devices simultaneously | Both sessions should work; data synced via Firestore |

---

## Bug Reporting Format

When filing a bug report, include:

1. **Device model and OS version** (e.g. Pixel 7, Android 14 or iPhone 13, iOS 17)
2. **Flutter build type** (debug / profile / release)
3. **Steps to reproduce** (numbered, step by step)
4. **Expected behaviour**
5. **Actual behaviour**
6. **Screenshot or screen recording**
7. **Flutter logs** if available (`flutter logs` or logcat output)

---

## Test Accounts

> Ask the developer for shared test credentials, or register a fresh account for isolated testing.

---

*Document version: 1.0 — Focus Forge Alpha Build (Flutter)*
