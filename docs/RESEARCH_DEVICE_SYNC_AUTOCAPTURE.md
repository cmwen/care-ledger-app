# Research: Device-Per-Participant, Auto-Capture, and Sync Patterns

> **Date**: 2025-07-11
> **Scope**: Care Ledger MVP — 2-participant, local-first, serverless Flutter app
> **Status**: Research Complete — Ready for Architecture Decision
> **Sources**: Android developer docs, pub.dev package analysis, CRDT/local-first literature, current codebase analysis

---

## Table of Contents

1. [Current Architecture Baseline](#1-current-architecture-baseline)
2. [Device-Per-Participant Pattern](#2-device-per-participant-pattern)
3. [Auto-Recording / Passive Activity Capture](#3-auto-recording--passive-activity-capture)
4. [Sync Patterns for Two-Device Family Apps](#4-sync-patterns-for-two-device-family-apps)
5. [Recommendations Summary](#5-recommendations-summary)
6. [Open Questions for Product Decision](#6-open-questions-for-product-decision)

---

## 1. Current Architecture Baseline

### What Exists Today

| Component | Current State | Notes |
|-----------|--------------|-------|
| Identity | Hardcoded `participant-a` / `participant-b` strings | No device identity, no crypto keys |
| Storage | In-memory repositories, `SharedPreferences` for settings | No persistent DB yet |
| Sync Model | `SyncEvent` domain model with Lamport clock, hash chain, append-only log | Repository interface exists, in-memory only |
| Data Model | `Ledger`, `CareEntry`, `Settlement`, `EntryReview`, `SyncEvent` | Well-structured domain layer |
| Network | Placeholder `NetworkService` — no implementation | HTTP package in deps but unused |
| Permissions | `INTERNET` + `ACCESS_NETWORK_STATE` only | Location, camera etc. commented out |
| Current User | `SettingsProvider._currentUserId` — MVP defaults to `participant-a` | Can switch in settings |
| Auto-capture | `SourceType.suggested` enum exists, seed data uses it | No actual detection logic |

### Key Architectural Constraints (from requirements)

- **Local-first, serverless by default** for core ledger operations
- Sync can use **peer-to-peer, local network, relay-by-consent, or manual encrypted share/export**
- Exactly **2 participants** per ledger in MVP
- **Auto-capture** entries are `needsReview` until user confirms
- **SyncEvent** already has `actorId` and `deviceId` fields (device-awareness designed in)

---

## 2. Device-Per-Participant Pattern

### 2.1 Problem Statement

Care Ledger has exactly 2 participants. Should each install on their own phone (1 device = 1 identity), or should we support both users on a single shared device?

### 2.2 Industry Analysis: How Other Apps Handle This

#### One-Device-Per-User (Dominant Pattern)

| App | Model | Rationale |
|-----|-------|-----------|
| **Splitwise** | Each user has own app install | Expense-splitting requires independent action from each party |
| **OurHome** (family chores) | One device per user | Chore completion requires individual accountability |
| **Cozi Family Organizer** | One device per user (shared calendar) | Calendar entries attributed to individual devices |
| **Between** (couple app) | Strictly 1 device per user | Chat/sharing model requires separate installs |
| **Life360** | One device per user | Location tracking is inherently per-device |
| **Apple Shared Notes** | Per-device, per-Apple-ID | Edit attribution requires device identity |

#### Shared-Device Support (Minority Pattern)

| App | Model | How |
|-----|-------|-----|
| **YNAB** (budgeting) | Multi-user on one device via server login | Cloud-first; identity is account, not device |
| **Google Family Link** | Parent profile on child's device | Uses Android multi-user / work profiles |
| **Kids chore chart apps** | Profile switching on shared tablet | Simple profile picker, no security boundary |

#### Key Finding

> **Apps that require independent accountability and action attribution almost universally use one-device-per-user.** Shared-device support only appears in cloud-first apps where the server is the authority, or in low-stakes kid-oriented apps.

### 2.3 Device Identity vs. User Identity in Offline-First Apps

#### The Core Distinction

In a local-first app without a central server, **device = the unit of trust**. There is no server to authenticate a user identity. The device's local storage and crypto keys ARE the identity.

| Concept | Server-First App | Local-First App |
|---------|-----------------|-----------------|
| Identity authority | Server-issued user ID | Device-generated keypair |
| Authentication | Username/password → server token | Private key in device keystore |
| Trust root | Server database | Device-local secret |
| Multi-device same user | Server resolves identity | Each device is a distinct actor |

#### Best Practice: Actor = Device

In CRDT and event-sourcing literature (Martin Kleppmann's "Local-First Software", Ink & Switch research), the standard pattern is:

1. **Each device generates a unique `actorId`** (UUID or crypto public key) at first launch
2. **The actorId is the attribution unit** for all events/operations
3. **A "user" can have multiple actors** (phone + tablet) — but each actor is independently trusted
4. **Pairing** associates two actors into a shared context (the ledger)

This is already partially reflected in Care Ledger's `SyncEvent` which has both `actorId` AND `deviceId`.

#### Recommendation for Care Ledger

**Use the one-device-per-participant model.** The `actorId` should be device-generated and device-bound.

Reasons:
- Care Ledger is about **accountability** — who did what care work. Device = person = accountability unit.
- **Auto-capture** (location patterns, calendar) is inherently device-specific. A shared device can't distinguish which person drove the kids.
- **Privacy** — co-parents may be separated/divorced. Shared device access creates trust/safety concerns.
- **Simplicity** — no profile switching UI, no multi-user session management, no risk of acting as wrong person.

### 2.4 Security Architecture for Device-Bound Identity

#### Key Generation and Storage

```
┌─────────────────────────────────────────────────┐
│ First Launch                                     │
│                                                  │
│  1. Generate Ed25519 keypair                     │
│  2. Store private key in Android Keystore        │
│     (hardware-backed on most modern devices)     │
│  3. actorId = SHA-256(publicKey) or publicKey     │
│  4. Display pairing code derived from publicKey   │
└─────────────────────────────────────────────────┘
```

#### Flutter Packages for Device Identity

| Package | Purpose | Maturity |
|---------|---------|----------|
| `flutter_secure_storage` (^9.0.0) | Encrypted key-value store backed by Android Keystore / iOS Keychain | Mature, widely used |
| `pointycastle` (^3.9.1) | Pure Dart cryptography (Ed25519, AES, SHA-256) | Mature, no native deps |
| `cryptography` (^2.7.0) | Higher-level crypto API with platform acceleration | Good, simpler API |
| `device_info_plus` (^11.0.0) | Hardware identifiers (supplement, not primary ID) | Mature |

#### Recommended Identity Flow

```
On first launch:
  1. Check flutter_secure_storage for existing keypair
  2. If none: generate Ed25519 keypair via pointycastle
  3. Store private key in flutter_secure_storage (Android Keystore-backed)
  4. Derive actorId = base64url(sha256(publicKey))[0:16]
  5. Persist actorId in SharedPreferences for quick access
  6. Display as "Your Device ID: XXXX-XXXX" in settings

On pairing:
  1. Exchange public keys (via QR code or manual code entry)
  2. Each device stores partner's public key
  3. All sync messages signed with sender's private key
  4. Recipient verifies signature with stored partner public key
```

#### Biometrics (Optional Enhancement)

For sensitive actions (settlement confirmation, entry deletion), biometric confirmation can be layered on:

| Package | Purpose |
|---------|---------|
| `local_auth` (^2.3.0) | Biometric/PIN authentication before sensitive operations |

This is a Phase 2 enhancement. For MVP, device keystore is sufficient.

### 2.5 CRDT/Event-Sourcing and Device Disambiguation

Care Ledger already has a `SyncEvent` with `actorId` and `deviceId`. The current Lamport clock + actorId tiebreaker provides deterministic ordering:

```dart
// Current sort order in InMemorySyncEventRepository
..sort((a, b) {
  final cmp = a.lamport.compareTo(b.lamport);
  if (cmp != 0) return cmp;
  return a.actorId.compareTo(b.actorId);  // deterministic tiebreaker
});
```

**This is correct for a 2-actor system.** With exactly 2 devices:
- Lamport clock ensures causal ordering
- ActorId tiebreak ensures deterministic total order for concurrent events
- Hash chain (`prevHash` → `hash`) provides tamper evidence

No changes needed to the event model. The identity layer just needs to populate `actorId` from the device-generated key instead of the hardcoded `participant-a` string.

### 2.6 Decision Matrix: One Device Per User vs. Shared Device

| Factor | 1 Device/User | Shared Device |
|--------|---------------|---------------|
| **Implementation complexity** | ✅ Simple | ❌ Profile switching, session management |
| **Auto-capture accuracy** | ✅ Device signals = this person | ❌ Can't distinguish users |
| **Privacy/safety** | ✅ Separated data per device | ❌ Risk of accessing other's data |
| **Sync simplicity** | ✅ Device A ↔ Device B | ❌ Must also handle local multi-user merge |
| **Offline identity** | ✅ Device keystore = identity | ❌ Need per-profile encryption |
| **User trust model** | ✅ Physical possession = authentication | ❌ Need login/PIN per profile |
| **Edge case: shared household tablet** | ❌ Not supported | ✅ Supported |

**Verdict: One device per participant.** The shared-device edge case can be addressed in Phase 3 with an optional profile switcher if user research shows demand.

---

## 3. Auto-Recording / Passive Activity Capture

### 3.1 Problem Statement

Care Ledger's core UX principle is "automation first" — auto-capture likely care activities so users review weekly instead of logging manually. What Android APIs and Flutter packages can detect care-related activities without constant manual input?

### 3.2 Relevant Android APIs

#### Activity Recognition API

| API | What It Detects | Accuracy | Battery Cost |
|-----|----------------|----------|--------------|
| **Activity Recognition Transition API** | IN_VEHICLE, ON_BICYCLE, ON_FOOT, RUNNING, WALKING, STILL | High for transitions | Very low (fires on transition only) |
| **Activity Recognition API** (polling) | Same activities, polled at interval | Moderate | Moderate (depends on interval) |

**Relevance to Care Ledger**: Detecting IN_VEHICLE transitions maps directly to driving entries (school runs, pickups). WALKING/ON_FOOT near specific locations maps to errands.

#### Geofencing API

| API | Capability | Battery Cost | Limits |
|-----|-----------|--------------|--------|
| **Android Geofencing API** | Enter/exit/dwell triggers for circular regions | Very low (OS-managed) | 100 active geofences per app |
| **Geofence minimum radius** | 100m recommended, 150m+ for reliability | — | Smaller radii less reliable |

**Relevance to Care Ledger**: Define geofences for school, home, doctor's office, grocery store. Enter/exit events + time = care activity inference.

#### Calendar Access

| API | Capability | Privacy | Battery |
|-----|-----------|---------|---------|
| **ContentResolver for CalendarContract** | Read calendar events | Requires READ_CALENDAR permission | Zero (on-demand read) |

**Relevance to Care Ledger**: Calendar events named "Doctor appointment", "Soccer practice", "School pickup" can pre-populate suggested entries.

#### Significant Motion / Step Counter

| API | Capability | Battery |
|-----|-----------|---------|
| **TYPE_SIGNIFICANT_MOTION** sensor | Fires once when significant movement detected | Extremely low |
| **TYPE_STEP_COUNTER** sensor | Accumulated step count | Very low |

**Relevance**: Low — only useful as supplementary signal ("user was physically active around this time").

### 3.3 Privacy-Safe Approach: Geofence + Activity Recognition (No Continuous GPS)

The key insight for Care Ledger is: **you don't need continuous location tracking.** You need:

1. **Geofence events** — "arrived at school" / "left school" — timestamps only
2. **Activity transitions** — "started driving" / "stopped driving" — timestamps only
3. **Calendar matching** — "had event called 'dentist' at 2pm" — local calendar read
4. **Time-of-day patterns** — "left home at 7:30am on a school day, arrived at school zone at 7:55am" — geofence + clock

```
┌──────────────────────────────────────────────────────────────────┐
│  Privacy-Safe Auto-Capture Architecture                          │
│                                                                  │
│  Inputs (all local, no server):                                  │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐           │
│  │  Geofence     │  │  Activity    │  │  Calendar    │           │
│  │  Enter/Exit   │  │  Transitions │  │  Events      │           │
│  │  (OS-managed) │  │  (OS-managed)│  │  (on-demand) │           │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘           │
│         │                 │                  │                    │
│         └────────┬────────┴──────────────────┘                   │
│                  ▼                                                │
│  ┌──────────────────────────────────────┐                        │
│  │  Local Activity Inference Engine      │                        │
│  │  (runs on-device, in Dart)            │                        │
│  │                                       │                        │
│  │  Rules:                               │                        │
│  │  • geofence(school) + IN_VEHICLE      │                        │
│  │    → "Drove kids to school" (2 credits)│                       │
│  │  • geofence(doctor) + calendar match  │                        │
│  │    → "Medical appointment" (2.5 credits)│                      │
│  │  • time_pattern(weekday 7:30-8:00)    │                        │
│  │    + geofence(school)                 │                        │
│  │    → "Morning school run" (2 credits) │                        │
│  └──────────────┬───────────────────────┘                        │
│                 ▼                                                  │
│  ┌──────────────────────────────────┐                            │
│  │  CareEntry(                       │                            │
│  │    sourceType: SourceType.suggested│                           │
│  │    sourceHint: "Detected school   │                            │
│  │      zone arrival at 7:55am +     │                            │
│  │      driving activity"            │                            │
│  │    status: EntryStatus.needsReview│                            │
│  │  )                                │                            │
│  └──────────────────────────────────┘                            │
│                                                                   │
│  ❌ NOT stored: GPS coordinates, continuous location trail        │
│  ✅ Stored: geofence name, timestamp, activity type, inference   │
└──────────────────────────────────────────────────────────────────┘
```

### 3.4 Flutter Packages for Auto-Capture

#### Tier 1: Comprehensive Background Geolocation (Recommended)

| Package | Version | Features | License | Notes |
|---------|---------|----------|---------|-------|
| **`locus`** | ^2.0.0 | Background tracking, geofencing, activity recognition, trip detection, offline queue, headless execution | Commercial | Full-featured SDK; built-in geofence + activity recognition + trip events. Handles all Android background limits. **Best option if budget allows.** |
| **`flutter_background_geolocation`** | ^4.16.0 | Same feature set as Locus (same author, Transistor Software) | Commercial ($0-$499 depending on use) | The original/predecessor. Well-documented. Same core engine. |

> **Note**: `locus` and `flutter_background_geolocation` are from the same developer (Transistor Software). Locus is the newer branding. Both provide: geofencing, activity recognition, motion detection, headless background execution, and Android battery-optimization compliance. The commercial license is the tradeoff — but it eliminates months of platform-specific background service work.

#### Tier 2: Compose-Your-Own (Free/Open Source)

| Package | Purpose | Battery | Maturity |
|---------|---------|---------|----------|
| **`flutter_foreground_task`** (^8.0.0) | Android foreground service for persistent background execution | Low (configurable interval) | High (89.7 benchmark). Handles boot restart, wake locks, battery optimization exemption |
| **`geolocator`** (^13.0.0) | On-demand location, distance calculation | Minimal (no background) | Very high, widely used |
| **`geofencing_api`** (^3.0.0) | Native Android/iOS geofencing via PlatformChannel | Very low (OS-managed) | Moderate; community package |
| **`flutter_activity_recognition`** (^3.0.0) | Android Activity Recognition API wrapper | Very low | Moderate |
| **`device_calendar`** (^4.3.0) | Read/write device calendar events | Zero | Mature |
| **`workmanager`** (^0.5.2) | Schedule periodic background work | Low | Mature, by Flutter Community |

#### Recommended Approach: Tier 2 Composition

For a serverless MVP that values privacy and simplicity:

```yaml
# pubspec.yaml additions for auto-capture
dependencies:
  flutter_foreground_task: ^8.0.0    # Background service host
  geofencing_api: ^3.0.0             # Geofence enter/exit events
  flutter_activity_recognition: ^3.0.0  # Driving/walking detection
  device_calendar: ^4.3.0            # Calendar event matching
  permission_handler: ^11.3.0        # Runtime permissions
```

**Why compose instead of buying Locus?**
- Care Ledger doesn't need continuous location tracking
- Only needs: geofence events (very battery-cheap) + activity transitions (very battery-cheap) + calendar reads (zero cost)
- No GPS trail to store or sync — aligns with privacy-first principle
- Avoids commercial dependency for an open-source/indie project

### 3.5 Android Background Execution Limits

Android has progressively restricted background execution. Here's how it affects Care Ledger:

| Android Version | Restriction | Impact | Mitigation |
|----------------|-------------|--------|------------|
| **8.0 (API 26)** | Background execution limits | Can't run persistent background services | Use foreground service with notification |
| **9.0 (API 28)** | Battery restrictions (App Standby Buckets) | Infrequently used apps get fewer wakeups | Request battery optimization exemption |
| **10 (API 29)** | Background location requires `ACCESS_BACKGROUND_LOCATION` | Separate permission prompt | Must request and explain to user |
| **12 (API 31)** | Foreground service launch restrictions from background | Can't start FG service from background in some cases | Use exact alarms or boot receiver |
| **13 (API 33)** | Notification permission required | FG service notification needs explicit permission | Request `POST_NOTIFICATIONS` |
| **14 (API 34)** | Foreground service type required | Must declare `foregroundServiceType` in manifest | Use `location` type |
| **15 (API 35)** | Stricter exact alarm restrictions | `SCHEDULE_EXACT_ALARM` may need settings redirect | Use `flutter_foreground_task` which handles this |

#### Practical Strategy for Care Ledger

```
1. Use a FOREGROUND SERVICE (with low-priority notification)
   "Care Ledger is monitoring your care activities"

2. Register GEOFENCES through the OS geofencing API
   (These survive app death — the OS wakes you on enter/exit)

3. Register ACTIVITY RECOGNITION transitions
   (Also OS-managed — fires broadcast on IN_VEHICLE start/stop)

4. Foreground service only needs to:
   - Process incoming geofence/activity broadcasts
   - Run inference rules
   - Write suggested CareEntries to local DB
   
5. Can be PAUSED when user manually indicates "not on duty"
```

#### Battery Impact Assessment

| Signal Source | Battery Draw | Frequency |
|--------------|-------------|-----------|
| Geofence enter/exit | Negligible (<1% daily) | Fires only on boundary cross |
| Activity transition | Negligible (<1% daily) | Fires only on transition (still→driving, etc) |
| Calendar read | Zero | On-demand, once daily or on app open |
| Foreground service (idle, processing broadcasts) | ~1-2% daily | Persistent but mostly sleeping |
| **Total estimated** | **~2-3% daily** | Very acceptable |

Compare: Life360 continuous tracking uses **5-15% daily**. Care Ledger's approach is 3-5x more efficient because it uses event-driven signals, not polling.

### 3.6 Required Android Permissions for Auto-Capture

```xml
<!-- AndroidManifest.xml additions -->
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_BACKGROUND_LOCATION" />
<uses-permission android:name="android.permission.ACTIVITY_RECOGNITION" />
<uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
<uses-permission android:name="android.permission.FOREGROUND_SERVICE_LOCATION" />
<uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED" />
<uses-permission android:name="android.permission.READ_CALENDAR" />

<!-- Optional: for battery optimization exemption -->
<uses-permission android:name="android.permission.REQUEST_IGNORE_BATTERY_OPTIMIZATIONS" />
```

#### Permission Request Flow

```
App First Launch:
  1. Explain why location is needed (for care activity detection)
  2. Request ACCESS_FINE_LOCATION (foreground only first)
  3. After user sees value, request ACCESS_BACKGROUND_LOCATION
  4. Request ACTIVITY_RECOGNITION
  5. Request POST_NOTIFICATIONS (Android 13+)
  6. Request READ_CALENDAR (optional, for calendar-linked entries)
  7. Suggest battery optimization exemption

All permissions must be OPT-IN with clear explanation.
Auto-capture should work in DEGRADED MODE if some permissions denied:
  - No location → no geofence entries, but calendar still works
  - No activity recognition → no driving detection, but geofence still works
  - No calendar → no calendar-linked suggestions, but location still works
```

### 3.7 How Comparable Apps Handle Passive Logging

| App | Passive Capture Method | Privacy Model |
|-----|----------------------|---------------|
| **Google Timeline** | Continuous GPS + activity recognition + WiFi signals | All data sent to Google servers; user can view/delete |
| **Life360** | Continuous GPS polling | Shared with family circle; high battery cost |
| **Apple Screen Time** | System-level app usage tracking | On-device only; no GPS |
| **IFTTT** | Geofence triggers → actions | User-defined geofences; no continuous tracking |
| **Tasker** (Android) | Geofence + activity + time rules → automations | Fully local, rule-based |

**Care Ledger's approach is closest to Tasker/IFTTT**: event-driven rules, geofence-based, no continuous tracking, fully local processing.

---

## 4. Sync Patterns for Two-Device Family Apps

### 4.1 Problem Statement

Two devices, each with their own append-only event log, need to exchange events to reach a consistent shared ledger state. What's the simplest reliable approach for exactly 2 devices with no central server?

### 4.2 Sync Architecture Options

#### Option A: QR Code / Manual Export-Import (Simplest)

```
Device A                          Device B
┌────────┐                        ┌────────┐
│ Events │   1. Export JSON       │ Events │
│ Log    │──────────────────►     │ Log    │
│        │   (QR, file share,    │        │
│        │    messaging app)     │        │
│        │                       │        │
│        │   2. Import & merge   │        │
│        │◄──────────────────────│        │
└────────┘                        └────────┘
```

| Aspect | Detail |
|--------|--------|
| **How it works** | Each device exports "events since last sync" as encrypted JSON. Transfer via QR code (small payloads), file share, or messaging app attachment. |
| **Complexity** | Very low — JSON serialization + merge logic |
| **Reliability** | 100% — user controls timing and channel |
| **UX** | Manual — user must initiate sync |
| **Packages** | `qr_flutter` (^4.1.0) for display, `mobile_scanner` (^6.0.0) for scan, `share_plus` (^10.0.0) for file share |
| **Encryption** | Encrypt payload with shared secret derived from pairing |
| **Latency** | Minutes to hours (depends on user) |
| **Best for** | MVP fallback; works without any network |

#### Option B: Local Network / WiFi Direct Sync

```
Device A                          Device B
┌────────┐                        ┌────────┐
│ Events │   1. Discover peer    │ Events │
│ Log    │   (mDNS / NSD)       │ Log    │
│        │──────────────────►    │        │
│        │   2. TCP connection   │        │
│        │◄─────────────────────►│        │
│        │   3. Exchange events  │        │
│        │◄─────────────────────►│        │
└────────┘                        └────────┘
```

| Aspect | Detail |
|--------|--------|
| **How it works** | Devices discover each other on same WiFi via mDNS/NSD. Open TCP socket. Exchange events since last sync Lamport. |
| **Complexity** | Moderate — service discovery + socket management |
| **Reliability** | High when on same network; fails across networks |
| **UX** | Semi-automatic — must be on same WiFi |
| **Packages** | `nsd` (^4.0.0) for service discovery, `shelf` or raw `dart:io` ServerSocket for HTTP/TCP |
| **Latency** | Seconds (real-time when co-located) |
| **Best for** | Same-household sync (both parents home) |

#### Option C: Google Nearby Connections API

```
Device A                          Device B
┌────────┐                        ┌────────┐
│ Events │   1. Advertise/       │ Events │
│ Log    │      Discover         │ Log    │
│        │   (BT+WiFi+NFC)      │        │
│        │──────────────────►    │        │
│        │   2. P2P connection   │        │
│        │◄─────────────────────►│        │
│        │   3. Exchange events  │        │
│        │◄─────────────────────►│        │
└────────┘                        └────────┘
```

| Aspect | Detail |
|--------|--------|
| **How it works** | Uses Google Play Services Nearby Connections to find and connect devices via Bluetooth, WiFi Direct, or WiFi hotspot. No internet required. |
| **Complexity** | Moderate — Google API handles transport; Flutter plugin handles marshaling |
| **Reliability** | Good for proximity (<100m); depends on Google Play Services |
| **UX** | Good — works without shared WiFi, just proximity |
| **Packages** | `nearby_connections` (^4.0.0) — Flutter wrapper for Google Nearby Connections API |
| **Limitations** | Android-only (iOS has Multipeer Connectivity, different API); requires Google Play Services |
| **Latency** | Seconds |
| **Best for** | Same-location sync without WiFi dependency |

#### Option D: Cloud Relay (Firebase / Supabase / Custom)

```
Device A                Cloud Relay             Device B
┌────────┐         ┌──────────────┐         ┌────────┐
│ Events │────────►│  Encrypted   │◄────────│ Events │
│ Log    │         │  Event Store │         │ Log    │
│        │◄────────│  (Firebase   │────────►│        │
│        │         │   Realtime   │         │        │
│        │         │   Database)  │         │        │
└────────┘         └──────────────┘         └────────┘
```

| Aspect | Detail |
|--------|--------|
| **How it works** | Both devices push encrypted events to a cloud store. Each device pulls new events from the cloud. Cloud is a "dumb pipe" — can't read data (E2E encrypted). |
| **Complexity** | Moderate — Firebase SDK + encryption layer |
| **Reliability** | Very high — works across any network, any distance |
| **UX** | Best — fully automatic, background sync |
| **Packages** | `firebase_database` (^11.0.0) or `firebase_messaging` (^15.0.0) for push, `cloud_firestore` (^5.0.0) |
| **Cost** | Firebase free tier: 1GB stored, 10GB/month transfer — more than enough for 2 users exchanging text events |
| **Privacy** | Mitigated by E2E encryption — relay sees opaque blobs |
| **Best for** | Always-connected async sync (dominant use case for separated co-parents) |
| **Tradeoff** | Violates "no central server" literally, but preserves it in spirit (server can't read data) |

#### Option E: WebRTC Data Channel (Peer-to-Peer with Signaling)

| Aspect | Detail |
|--------|--------|
| **How it works** | Devices establish direct P2P connection via WebRTC. Signaling server only helps with initial connection setup. |
| **Complexity** | High — WebRTC setup, STUN/TURN servers, NAT traversal |
| **Reliability** | Moderate — NAT traversal fails ~15% of cases (needs TURN fallback) |
| **Packages** | `flutter_webrtc` (^0.12.0) |
| **Best for** | Real-time streaming; overkill for async event exchange |
| **Verdict** | **Not recommended** — too complex for the sync volume Care Ledger needs |

### 4.3 How Comparable Apps Handle Sync

| App | Sync Method | Server? | Encryption |
|-----|------------|---------|------------|
| **Splitwise** | Central server | Yes (required) | TLS only |
| **Between** (couple) | Central server | Yes (required) | E2E optional |
| **AnyList** (shared grocery) | Central server | Yes | TLS |
| **Standard Notes** | Self-hosted or cloud server | Yes, but self-hostable | E2E encrypted |
| **Obsidian Sync** | Cloud relay | Yes (proprietary) | E2E encrypted |
| **Briar** (messenger) | Tor or local WiFi/BT | No central server | E2E encrypted |
| **Manyverse** (social) | P2P via SSB protocol | No central server | Public key crypto |
| **CRDT-based apps** (e.g. Automerge) | Any transport | Transport-agnostic | Application-layer |

**Key finding**: The most successful 2-user sync apps use a cloud relay with E2E encryption. Pure P2P apps (Briar, Manyverse) exist but have worse UX due to requiring simultaneous online presence.

### 4.4 Recommended Sync Strategy: Layered Approach

For Care Ledger, the sync volume is very low (maybe 10-50 events per week per user). The recommended strategy is **layered**, starting simple:

#### Layer 1: Manual Export/Import (MVP Day 1) ✅

```
Implementation effort: ~1 week
Dependencies: qr_flutter, mobile_scanner, share_plus
```

- Export "events since last sync" as encrypted JSON
- Share via QR code (for small payloads < 2KB — fits ~20-30 events)
- Share via file (for larger payloads) through any messaging app
- Import on receiving device, merge into local event log
- **This works offline, cross-platform, and requires zero infrastructure**

#### Layer 2: Local Network Auto-Sync (MVP + 2 weeks) ✅

```
Implementation effort: ~2 weeks
Dependencies: nsd (service discovery), dart:io (TCP socket)
```

- When both devices are on the same WiFi, discover peer via mDNS
- Automatically exchange events in background
- Show "Last synced: 5 minutes ago" indicator
- Great for same-household usage (both parents come home, phones sync)

#### Layer 3: Cloud Relay (Post-MVP, optional) 🔄

```
Implementation effort: ~2-3 weeks
Dependencies: firebase_database or custom relay
```

- For separated households (co-parents don't share WiFi often)
- E2E encrypted events pushed to Firebase Realtime Database
- Each device listens for new events from partner
- Firebase free tier is more than sufficient
- **Positioned as optional "always-sync" upgrade, not core dependency**

### 4.5 Sync Protocol Design

Regardless of transport layer, the sync protocol is the same:

```
Sync Handshake:
  1. Device A sends: { myActorId, myMaxLamport, ledgerId }
  2. Device B sends: { myActorId, myMaxLamport, ledgerId }
  3. Each device sends events where lamport > partner's maxLamport
  4. Each device merges received events into local log
  5. Each device replays events to rebuild projections (CareEntry, Settlement, etc.)

Conflict Resolution:
  - Events are APPEND-ONLY — no updates or deletes of events
  - Entity state is derived by replaying events in deterministic order
  - Deterministic order: sort by (lamport ASC, actorId ASC)
  - For same entity, last-writer-wins by Lamport clock
  - If Lamport ties: actorId string comparison breaks tie
  - Hash chain validates integrity (detect tampering or missing events)
```

This is already substantially what the `SyncEvent` model and `InMemorySyncEventRepository` implement. The main work is:

1. **Serialization**: `SyncEvent` → JSON → encrypted bytes
2. **Transport**: Plug in QR/file/mDNS/Firebase as transport
3. **Merge**: Insert remote events into local store, replay projections
4. **State tracking**: Remember `partnerLastLamport` to know what to send next

### 4.6 Encryption for Sync Payloads

```
Pairing (one-time):
  1. Device A generates keypair, displays public key as QR/code
  2. Device B scans/enters, generates own keypair, displays own public key
  3. Both devices derive shared secret: ECDH(myPrivate, partnerPublic)
  4. Shared secret stored in flutter_secure_storage

Sync message encryption:
  1. Serialize events to JSON
  2. Generate random nonce
  3. Encrypt: AES-256-GCM(sharedSecret, nonce, jsonBytes)
  4. Transmit: nonce + ciphertext
  5. Recipient decrypts with same shared secret
```

| Package | Role |
|---------|------|
| `pointycastle` (^3.9.1) | AES-GCM encryption, ECDH key exchange |
| `cryptography` (^2.7.0) | Higher-level alternative to pointycastle |
| `flutter_secure_storage` (^9.0.0) | Store shared secret and private key |

### 4.7 Sync Package Comparison

| Package | Role | Version | Notes |
|---------|------|---------|-------|
| **`qr_flutter`** | Display QR codes | ^4.1.0 | For pairing + small sync payloads |
| **`mobile_scanner`** | Scan QR codes | ^6.0.0 | Fast, ML-Kit based |
| **`share_plus`** | Share files via OS share sheet | ^10.0.0 | For exporting sync bundles |
| **`nsd`** | mDNS service discovery (LAN) | ^4.0.0 | Find peer on same WiFi |
| **`firebase_database`** | Cloud relay (optional) | ^11.0.0 | E2E encrypted event relay |
| **`connectivity_plus`** | Network state detection | ^6.0.0 | Know when to attempt sync |
| **`pointycastle`** | Crypto primitives | ^3.9.1 | Encryption for sync payloads |
| **`flutter_secure_storage`** | Secure key storage | ^9.0.0 | Store keypairs and shared secrets |

---

## 5. Recommendations Summary

### 5.1 Device Model

| Decision | Recommendation | Confidence |
|----------|---------------|------------|
| Device per participant | **Yes — one device = one identity** | High |
| Identity generation | Device-generated Ed25519 keypair, actorId derived from public key | High |
| Key storage | `flutter_secure_storage` (Android Keystore-backed) | High |
| Shared-device support | **Defer to Phase 3** — no demand signal yet | Medium |
| Biometric lock | **Phase 2** enhancement for sensitive actions | Medium |

### 5.2 Auto-Capture

| Decision | Recommendation | Confidence |
|----------|---------------|------------|
| Approach | **Geofence + Activity Recognition + Calendar** (event-driven, no continuous GPS) | High |
| Package strategy | **Compose from open-source packages** (not commercial SDK) | Medium-High |
| Core packages | `flutter_foreground_task` + `geofencing_api` + `flutter_activity_recognition` + `device_calendar` | Medium |
| Battery target | <3% daily impact | High (achievable with event-driven approach) |
| Privacy model | No GPS coordinates stored; only geofence names + timestamps + activity types | High |
| Degraded mode | Works with partial permissions (calendar-only if no location granted) | High |
| Commercial alternative | `locus` / `flutter_background_geolocation` if open-source composition proves too brittle | Fallback |

### 5.3 Sync

| Decision | Recommendation | Confidence |
|----------|---------------|------------|
| MVP sync | **Layer 1: QR/File export-import** (works immediately, zero infra) | High |
| MVP+ sync | **Layer 2: LAN auto-sync via mDNS** (same-WiFi automatic exchange) | High |
| Post-MVP sync | **Layer 3: Firebase relay** (optional, E2E encrypted, for separated households) | Medium-High |
| Protocol | Append-only events, Lamport clock ordering, actorId tiebreak (already designed) | High |
| Encryption | AES-256-GCM with ECDH-derived shared secret | High |
| WebRTC | **Not recommended** — too complex for low-volume async sync | High |

### 5.4 Package Budget (All Recommendations Combined)

```yaml
# Identity & Security
flutter_secure_storage: ^9.0.0
pointycastle: ^3.9.1
permission_handler: ^11.3.0

# Auto-Capture
flutter_foreground_task: ^8.0.0
geofencing_api: ^3.0.0
flutter_activity_recognition: ^3.0.0
device_calendar: ^4.3.0

# Sync - Layer 1 (MVP)
qr_flutter: ^4.1.0
mobile_scanner: ^6.0.0
share_plus: ^10.0.0

# Sync - Layer 2 (MVP+)
nsd: ^4.0.0
connectivity_plus: ^6.0.0

# Sync - Layer 3 (Post-MVP, optional)
firebase_database: ^11.0.0

# Storage upgrade (needed for persistence)
sqflite: ^2.4.0          # or drift: ^2.20.0 for type-safe SQL
```

**Total new dependencies**: 12-14 packages across 3 phases (not all needed at once).

---

## 6. Open Questions for Product Decision

### Must-Decide Before Implementation

1. **Geofence setup UX**: How does the user define "school", "doctor", "grocery store" geofences?
   - Option A: Manual address entry → geocode → geofence
   - Option B: "I'm at school now" button → use current location → save as geofence
   - Option C: Pre-configured from calendar event locations
   - **Recommendation**: Option B (lowest friction, aligned with "automation first")

2. **Auto-capture opt-in flow**: How aggressively do we prompt for permissions?
   - Option A: Request all permissions on first launch (simpler, but users may refuse)
   - Option B: Progressive — start with calendar only, add location after user sees value
   - **Recommendation**: Option B (progressive disclosure)

3. **Sync MVP scope**: Which sync layer ships in MVP?
   - Option A: QR/file export only (simplest, works day 1)
   - Option B: QR/file + LAN auto-sync (better UX for same-household)
   - **Recommendation**: Option A for first pilot, add B within first sprint after pilot feedback

4. **Firebase relay — is it acceptable?**: The requirements say "no central server" but Firebase-as-dumb-encrypted-relay is the best UX for separated co-parents.
   - Need product owner sign-off on "encrypted relay is acceptable as optional sync channel"

5. **Persistent storage**: Current in-memory repositories won't survive app restart. Need to pick:
   - `sqflite` (standard SQL, manual mapping)
   - `drift` (type-safe SQL, code generation, reactive queries)
   - **Recommendation**: `drift` — its reactive queries integrate well with Provider, and code-gen reduces boilerplate for the 5+ entity types

### Can-Decide-Later

6. What's the maximum QR code payload for sync? (Test with real event volumes)
7. Should sync happen on a schedule (e.g., hourly) or only on user action?
8. How do we handle clock skew between devices? (Lamport clocks handle logical ordering, but `occurredAt` timestamps may disagree)

---

## Appendix A: Reference Architecture Diagram

```
┌─────────────────────────────────────────────────────────┐
│                    Device A (Phone)                      │
│                                                          │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  │
│  │ Geofence     │  │ Activity     │  │ Calendar     │  │
│  │ Service      │  │ Recognition  │  │ Reader       │  │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘  │
│         └────────┬────────┴──────────────────┘          │
│                  ▼                                        │
│  ┌──────────────────────────────┐                       │
│  │ Activity Inference Engine    │                       │
│  │ (rule-based, on-device)     │                       │
│  └──────────────┬──────────────┘                       │
│                 ▼                                        │
│  ┌──────────────────────────────┐                       │
│  │ SyncEvent Append-Only Log    │ ◄── All writes go     │
│  │ (Lamport + hash chain)      │     through here      │
│  └──────────────┬──────────────┘                       │
│                 ▼                                        │
│  ┌──────────────────────────────┐                       │
│  │ Projection Layer             │                       │
│  │ CareEntry │ Settlement │ ... │                       │
│  └──────────────┬──────────────┘                       │
│                 ▼                                        │
│  ┌──────────────────────────────┐                       │
│  │ Sync Transport (pluggable)   │                       │
│  │ QR │ File │ LAN │ Firebase  │                       │
│  └──────────────────────────────┘                       │
│                                                          │
│  Identity: Ed25519 keypair in Android Keystore           │
│  ActorId: derived from public key                        │
└─────────────────────────────────────────────────────────┘
         ▲                              ▲
         │    Encrypted SyncEvents      │
         └──────────────────────────────┘
              (any transport layer)
```

## Appendix B: Relevant Literature and Sources

1. **"Local-First Software"** — Kleppmann et al., Ink & Switch (2019) — Foundational paper on local-first architecture patterns
2. **"Designing Data-Intensive Applications"** — Martin Kleppmann — Chapter on replication and conflict resolution
3. **Android Activity Recognition API** — developer.android.com/guide/topics/location/transitions
4. **Android Geofencing API** — developer.android.com/training/location/geofencing
5. **Android Background Execution Limits** — developer.android.com/about/versions/oreo/background
6. **Lamport Timestamps** — "Time, Clocks, and the Ordering of Events in a Distributed System" (1978)
7. **Flutter Foreground Task** — github.com/dev-hwang/flutter_foreground_task (benchmark score: 89.7)
8. **Locus Background Geolocation** — pub.dev/packages/locus (benchmark score: 66.3)
9. **Flutter Geolocator** — pub.dev/packages/geolocator (benchmark score: 75.1)
