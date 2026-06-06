# TURF — AI Agent README
> Paste this at the start of EVERY prompt to any AI agent.

---

## What is TURF?
TURF is a Pakistan-based fitness and territory capture mobile app built in Flutter. 
Users run, walk, or cycle in the real world to capture map territories, compete with friends, earn XP, 
climb leaderboards, complete challenges, and track fitness goals. Think Strava + a strategy game.


---

## Tech Stack
| Layer | Technology |
|---|---|
| Frontend | Flutter (Dart) |
| Backend | Supabase (Postgres + Auth + Realtime + Storage) |
| Maps | flutter_map + OpenStreetMap + Stadia Maps dark tiles (free, no API key) |
| GPS | geolocator package |
| State | flutter_riverpod |
| Navigation | go_router |
| Auth | Supabase Auth — Email/Password + Google OAuth (optional) |

---

## Supabase Connection
```dart
URL: https://lcrfzwxkrkiuvfhkgfju.supabase.co
AnonKey: sb_publishable_hLE459WDGvetlxZvwMhyGQ_OkwjBtGm
Package: supabase_flutter (already installed)
```

---

## Database Tables (NEVER rename these)
```
profiles
activity_sessions
location_pings
territories
territory_captures
friendships
challenges
challenge_participants
leaderboard_entries
badges
user_badges
fitness_goals
notifications
```

---

## Core Rules — Follow Always
- NO mock/demo data. Everything is real-time Supabase only.
- NEVER rename any table, column, or Supabase function.
- UI is #1 priority — dark-mode-first, premium athletic design.
- App weight is #2 priority — lazy load, efficient streams, minimal rebuilds.
- All Supabase calls wrapped in try/catch with friendly error messages.
- No raw error messages shown to users ever.
- Terms & Conditions: https://www.termsfeed.com/live/340e81fc-0ff8-43cf-ae39-4a335d13462a
- Must be accepted before account creation.
- Google Sign-In is optional (not forced).
- App works on Android (API 21+) and iOS (13+).

---

## UI Theme
```
Primary color:     #00E676 (electric green)
Background:        #0A0A0A
Surface:           #141414
Card:              #1C1C1E
Text primary:      #FFFFFF
Text secondary:    #8E8E93
Font body:         Inter (Google Fonts)
Font display:      Space Grotesk (Google Fonts)
```

---

## Supabase Functions (already created)
- `public.calculate_user_level(p_xp int8)` — returns user level from XP
- `public.award_xp(p_user_id uuid, p_xp int4)` — adds XP + recalculates level
- `public.update_leaderboard()` — refreshes all leaderboard entries

## Realtime Tables (already enabled)
`location_pings, territories, territory_captures, notifications, leaderboard_entries, challenge_participants`

## Storage Buckets (already created)
- `avatars` — public read, authenticated write
- `activity_media` — private, user-scoped

---

## App Name & Identity
- Name: **TURF**
- Tagline: **Claim your ground.**
- Package ID: `com.turf.app`
- Google OAuth redirect: `com.turf.app://login-callback`
