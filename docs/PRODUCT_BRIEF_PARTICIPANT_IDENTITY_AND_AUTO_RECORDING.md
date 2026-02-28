# Product Brief: Participant Identity, Per-User Interface, and Auto-Recording

---

**Created**: 2025-01-24
**Scope**: MVP refinement — participant identity model, per-user UI, auto-recording
**Status**: Product Decision (ready for implementation)
**Stakeholders**: Product, Engineering, Design
**Version**: 1.0
**References**:
- `docs/REQUIREMENTS_CARE_LEDGER_MVP.md`
- `docs/USER_STORIES_CARE_LEDGER.md`
- `docs/VISION_CARE_LEDGER.md`
- `docs/designs/CARE_LEDGER_TECH_DESIGN_HANDOFF.md`
- `docs/ROADMAP_CARE_LEDGER.md`

---

## Executive Summary

This brief resolves three open product questions that block a trustworthy multi-participant experience:

1. **Should the MVP enforce one device per participant?** → **Yes, with escape hatches.**
2. **How should the interface differ per participant?** → **Everything is "my perspective" by default.**
3. **How should auto-recording work?** → **Passive timeline capture → user-driven review → counterparty confirmation.**

Each section includes the decision, rationale grounded in the codebase, impact on existing code, and acceptance criteria.

---

## Table of Contents

- [1. Device–Participant Identity Model](#1-deviceparticipant-identity-model)
- [2. Per-Participant Interface Design](#2-per-participant-interface-design)
- [3. Auto-Recording and Passive Capture](#3-auto-recording-and-passive-capture)
- [4. Alignment Audit Against Product Principles](#4-alignment-audit-against-product-principles)
- [5. Implementation Priority and Sequencing](#5-implementation-priority-and-sequencing)
- [6. Open Questions for Future Phases](#6-open-questions-for-future-phases)

---

## 1. Device–Participant Identity Model

### 1.1 The Question

Should the MVP enforce a 1:1 mapping between a physical device and a participant identity?

### 1.2 Decision: Yes — One Device, One Owner (with read-only guest peek)

**The default model is: this device belongs to one participant. Period.**

The app binds a participant identity to the device during first-run onboarding. That identity cannot be silently swapped. Every write operation (entry creation, reviews, settlement proposals) is attributed to the device owner.

### 1.3 Rationale

| Factor | Analysis |
|--------|----------|
| **Local-first architecture** | The app stores all data locally. If two participants share one device, ALL private notes, review queues, and unsync'd entries from BOTH people live on the same device. This violates `Privacy by default`. |
| **Counterparty review integrity** | The core trust model is: "I can't confirm my own entries." If both participants use the same device, they can trivially review their own entries by switching identities. The audit trail becomes meaningless. |
| **Sync model** | `SyncEvent` already has a `deviceId` field (line 31, `sync_event.dart`). The sync design assumes device ↔ participant affinity for conflict resolution (Lamport clocks + actorId ordering). Mixing two actors on one device breaks deterministic merge guarantees. |
| **Current code bug** | `SettingsProvider` hardcodes `_currentUserId = 'participant-a'` and exposes `setCurrentUser()` which lets anyone silently switch identity. The review screen then hardcodes `participantBId` as the reviewer. This means the app currently assumes "this device is always Participant A" but has a mechanism that could break that assumption with no guardrails. |
| **Balance screen bug** | `balance_screen.dart` line 205 hardcodes `participantAId` as the settlement proposer, regardless of who `currentUserId` actually is. Switching identity wouldn't even work correctly today. |

### 1.4 What About Shared-Device Scenarios?

| Scenario | Solution |
|----------|----------|
| **"My ex and I share a tablet for the kids"** | Each person installs Care Ledger on their own phone. The tablet is NOT the right form factor for a trust-based personal ledger. If cost is a concern, the app runs on low-end Android devices. |
| **"I want to show my kid what the ledger looks like"** | **Guest Peek mode** — a read-only view that shows the timeline and balance without exposing private notes, review actions, or write capabilities. Activated via Settings > "Show Ledger" which opens a limited view. No identity switch required. |
| **"I lost my phone and need to use my partner's device temporarily"** | This is a sync/recovery problem, not an identity problem. The answer is export/import of encrypted ledger data, not multi-user on one device. This is a Phase 2 concern. |

### 1.5 Required Changes to Current Code

| Component | Current State | Required Change |
|-----------|--------------|-----------------|
| `SettingsProvider._currentUserId` | Hardcoded to `'participant-a'`, mutable via `setCurrentUser()` | Set once during onboarding, persisted to secure storage, immutable after setup. Remove `setCurrentUser()` from public API. |
| `SettingsProvider` | No onboarding concept | Add `isOnboarded` flag. First launch shows identity setup screen. |
| `SyncEvent.deviceId` | Optional, unused | Populate from a device-specific UUID generated at first launch. |
| `Ledger.participantAId/BId` | Fixed A/B slots | Keep for MVP (2-party only), but the device owner maps to ONE of these slots. |
| Review screen | Hardcodes `participantBId` as reviewer | Use `settings.currentUserId` to determine "the other participant" via `Ledger.otherParticipant()`. |
| Balance screen | Hardcodes `participantAId` as proposer | Use `settings.currentUserId` as the proposer. |

### 1.6 Acceptance Criteria

- [ ] First launch shows an identity setup screen (name entry, optional avatar initial).
- [ ] Device owner ID is persisted and cannot be changed without a factory reset flow.
- [ ] All write operations use the persisted device owner ID, never a switchable value.
- [ ] `setCurrentUser()` is removed from `SettingsProvider` public interface.
- [ ] `SyncEvent.deviceId` is populated for every event.
- [ ] Guest Peek mode exists as a read-only view accessible from Settings.
- [ ] Guest Peek hides: private notes, review actions, settlement proposal buttons, entry creation.
- [ ] Guest Peek shows: timeline, balance summary, entry list (without private notes).

---

## 2. Per-Participant Interface Design

### 2.1 The Question

How should the UI differ based on which participant is using the app?

### 2.2 Decision: Everything Is "My Perspective" — First Person by Default

The entire app renders from the device owner's point of view. There is no neutral "god view" in the MVP. The UI always answers: "What do **I** need to do?" and "What is the state from **my** side?"

### 2.3 Per-Screen Specification

#### 2.3.1 App Bar and Greeting

| Element | Current | Decision |
|---------|---------|----------|
| App bar title | Ledger title (`Family Care Ledger`) | Keep ledger title as primary. |
| Greeting | None | Add a contextual greeting below the app bar on the Ledger (home) tab only: `"Hi {name} — {action hint}"`. Example: `"Hi Sarah — 3 entries need your review"`. |
| Avatar | None | Show the device owner's initial avatar in the app bar trailing position (replaces the current `cloud_off` icon, which moves to Settings > Sync Status). |
| Sync indicator | `cloud_off` icon in app bar | Move to a dot indicator next to the avatar (green = synced, amber = local-only, red = conflict). |

#### 2.3.2 Review Tab — "Your Inbox"

**Principle**: The Review tab shows entries that **the OTHER person** submitted and that need **YOUR** decision.

| Element | Current State | Required Change |
|---------|--------------|-----------------|
| Queue contents | Loads ALL actionable entries for the ledger (`getReviewQueue(ledgerId)`) | Filter to entries where `authorId != currentUserId` AND status is `pendingCounterpartyReview`. Entries where `authorId == currentUserId` and status is `needsReview` (auto-suggestions for YOU to approve before sending) should appear in a separate "Your Drafts" section on the Ledger tab. |
| Reviewer ID | Hardcoded to `participantBId` | Use `settings.currentUserId`. |
| Empty state text | "Nothing to review this week" | Personalize: "Nothing for you to review — {otherName} hasn't submitted new entries." |
| Entry cards | Show category + description | Add author attribution: "{otherName}" badge on each card so it's clear who submitted it. |

**Two distinct queues emerge:**

| Queue | Location | Contents | Actions |
|-------|----------|----------|---------|
| **My Drafts** | Ledger tab, collapsible section | Entries where `authorId == currentUserId` AND status `needsReview` | Approve (send for counterparty review), Edit, Discard |
| **Review Inbox** | Review tab | Entries where `authorId != currentUserId` AND status `pendingCounterpartyReview` | Confirm, Request Edit, Reject |

#### 2.3.3 Ledger Tab — "My Activity"

| Element | Current State | Required Change |
|---------|--------------|-----------------|
| Entry list | Shows all entries | Keep showing all entries but add visual distinction: entries authored by "me" get a left-border accent color; entries by the other person get a different accent color. |
| Entry detail | Shows `authorId` as raw ID | Resolve to display name via `SettingsProvider.participantName()`. Show "You" for device owner, actual name for counterparty. |
| Status labels | Generic | Contextualize: `pendingCounterpartyReview` shows as "Waiting for {otherName}'s review" when you're the author, and "Needs your review" when you're the reviewer. |
| Quick Add | Uses hardcoded participant ID | Use `settings.currentUserId` as the `authorId`. |

#### 2.3.4 Balance Tab — "You and Them"

**This is the most impactful personalization.** The current balance screen shows a neutral "Participant A vs Participant B" view. Families don't think in A/B slots — they think in "me" and "you."

| Element | Current State | Required Change |
|---------|--------------|-----------------|
| Balance card header | "Participant A" / "Participant B" | "Your Credits" / "{otherName}'s Credits" |
| Net balance label | "Net: 5.0 cr" (unsigned) | Directional: **"Sarah owes you 5.0 cr"** or **"You owe Sarah 5.0 cr"** or **"Balanced!"** |
| Pending credits | "Participant A" / "Participant B" | "Your Pending" / "{otherName}'s Pending" |
| Settlement proposer | Hardcoded to `participantAId` | Use `settings.currentUserId`. |
| Settlement cards | Shows `proposerId` as raw ID | "You proposed" or "{otherName} proposed". Action buttons only appear on settlements proposed by the OTHER person (you can't accept your own proposal). |

#### 2.3.5 Timeline Tab

| Element | Current | Decision |
|---------|---------|----------|
| Entry attribution | Shows category icon only | Add small avatar initial circle (colored) per entry showing who authored it. |
| Participant filter | "Filter by participant" | "Show: All / Just mine / Just {otherName}'s" |

#### 2.3.6 Settings Tab

| Element | Current | Decision |
|---------|---------|----------|
| Participants list | Shows all with edit/remove | Show device owner at top with "You" badge (name editable, cannot remove). Counterparty below with edit name option. Remove "Add Participant" button for MVP (2-party only). |
| Current user switcher | Implicit via `setCurrentUser()` | Remove entirely. Replace with "Guest Peek" button. |

### 2.4 Role Indicators on Entries

Every entry and review action should show clear attribution:

| Context | Display Format |
|---------|---------------|
| Entry in list | Left-accent color + "{Name}" or "You" label |
| Entry detail | "Logged by {Name}" with timestamp |
| Review on entry | "{Name} approved on {date}" or "You requested edits on {date}" |
| Settlement card | "Proposed by {Name}" or "You proposed" |
| Source hint (auto) | "Auto-detected: {reason}" — no change needed, already in place |

### 2.5 Acceptance Criteria

- [ ] All screens use `settings.currentUserId` to determine perspective — no hardcoded participant IDs.
- [ ] Balance screen shows "You owe" / "They owe" directional language.
- [ ] Review tab only shows entries authored by the OTHER participant.
- [ ] Ledger tab has a "My Drafts" section for auto-suggestions the user hasn't yet sent for review.
- [ ] Entry detail shows "You" for own entries and the counterparty's name for theirs.
- [ ] Settlement proposal uses `currentUserId` as the proposer.
- [ ] Settlement accept/reject buttons only appear on proposals from the counterparty.
- [ ] Status labels are contextual ("Waiting for Sarah" vs "Needs your review").
- [ ] Greeting on home tab shows device owner's name and an action hint.
- [ ] All entry lists show author attribution with visual distinction.

---

## 3. Auto-Recording and Passive Capture

### 3.1 The Question

How should automatic logging work? What signals trigger it? How does it balance automation with privacy and trust?

### 3.2 Decision: Three-Layer Capture Pipeline

```
Layer 1: Passive Signal Collection (on-device only, no network)
    ↓
Layer 2: Pattern Matching → Draft Suggestions (never sent, never confirmed)
    ↓
Layer 3: User Review → Counterparty Confirmation (existing workflow)
```

**Core invariant (non-negotiable):** Auto-captured entries are NEVER auto-confirmed. They always enter the pipeline as `needsReview` status and require TWO human actions: the author's approval (→ `pendingCounterpartyReview`) and the counterparty's confirmation (→ `confirmed`).

### 3.3 Layer 1: Passive Signal Collection

#### 3.3.1 Which Signals, In What Order

| Signal Source | What It Detects | Privacy Impact | MVP Priority | Permission Required |
|---------------|----------------|----------------|-------------|-------------------|
| **Time patterns** | Recurring activities at consistent times (e.g., school runs at 8:00am) | **Low** — uses only clock | **P0 — MVP** | None |
| **Manual activity log** | User's own past entries as templates for recurrence | **Low** — user's own data | **P0 — MVP** | None |
| **Calendar events** (opt-in) | Child-related appointments, activities, school events | **Medium** — reads calendar data | **P1 — MVP stretch** | Calendar read permission |
| **Location patterns** (opt-in) | Geofenced zones (school, doctor, sports field) | **High** — continuous location tracking | **P2 — Post-MVP** | Fine location + background location |
| **Motion/activity recognition** | Driving detection for school runs | **Medium** — activity monitoring | **P3 — Post-MVP** | Activity recognition permission |

#### 3.3.2 Privacy Rules for Signal Collection

1. **All signal processing happens on-device.** No sensor data is ever transmitted, synced, or stored beyond the device.
2. **Location and calendar signals are opt-in per source.** Off by default. Explicit toggle in Settings with plain-language explanation of what's collected.
3. **Raw signal data is ephemeral.** The app stores only the resulting draft suggestion, not the underlying GPS coordinates or calendar event details. The `sourceHint` field stores a human-readable explanation ("Detected 8:15am weekday pattern matching school run"), never raw sensor data.
4. **Users can disable auto-capture entirely.** A global "Manual only" toggle in Settings disables all passive collection.

### 3.4 Layer 2: Pattern Matching → Draft Suggestions

#### 3.4.1 How Suggestions Are Generated

The pattern matcher runs periodically (configurable, default: daily at a quiet hour like 9pm) and produces a batch of draft suggestions. It does NOT generate suggestions in real-time to avoid notification fatigue.

**Pattern types for MVP (P0):**

| Pattern | Logic | Example Suggestion |
|---------|-------|--------------------|
| **Time recurrence** | If the user logged "School pickup" on 3+ of the last 5 weekdays, suggest it again today at the same time. | "School pickup — 3:15pm (suggested based on your recent pattern)" |
| **Weekly recurrence** | If an entry with the same category appeared in 3+ of the last 4 weeks on the same day, suggest it. | "Laundry — Saturday (weekly pattern detected)" |
| **Template from last week** | Clone the user's confirmed entries from the previous week as suggestions for the current week. | "Last week you logged 'Grocery shopping' on Sunday — add for this week?" |

**Pattern types for MVP stretch (P1):**

| Pattern | Logic | Example Suggestion |
|---------|-------|--------------------|
| **Calendar-linked** | If a calendar event matches a care category keyword (pickup, doctor, practice, school), suggest an entry for that time. | "Child dentist appointment — Tuesday 2pm (from calendar)" |

#### 3.4.2 Suggestion Quality Rules

- Suggestions must include a `sourceHint` explaining WHY they were generated. The current `CareEntry.sourceHint` field already supports this.
- Suggestions must set `sourceType` to `SourceType.suggested` (or a new `SourceType.patternMatch` / `SourceType.calendar` for finer granularity).
- Suggestions must use reasonable default values for `creditsProposed` based on the category and the user's historical average for that category. If no history, use category default.
- Suggestions must NOT duplicate: if an identical suggestion (same date, category, description) already exists in `needsReview` or later status, skip it.

#### 3.4.3 The "Activity Timeline" Concept

Instead of generating individual suggestions in isolation, the auto-capture system should produce a **draft weekly timeline** — a visual representation of "here's what we think your week looked like." The user opens this timeline and reviews it as a whole, rather than triaging individual notifications.

**This is the key UX insight:** The review experience should feel like "checking a pre-filled timesheet" rather than "processing an inbox of alerts."

```
┌─ This Week's Draft ──────────────────────────────┐
│                                                   │
│  Mon 20 Jan                                       │
│  ✅ 8:15am  School drop-off  (pattern)    2.0 cr │
│  ✅ 3:15pm  School pickup    (pattern)    2.0 cr │
│                                                   │
│  Tue 21 Jan                                       │
│  ✅ 8:15am  School drop-off  (pattern)    2.0 cr │
│  ⬜ 2:00pm  Dentist appt     (calendar)   2.5 cr │ ← tap to edit
│  ✅ 3:15pm  School pickup    (pattern)    2.0 cr │
│                                                   │
│  Wed 22 Jan                                       │
│  ✅ 8:15am  School drop-off  (pattern)    2.0 cr │
│  ⬜ (no afternoon detected)   [+ Add]             │ ← manual add
│                                                   │
│  ──────────────────────────────────────────────── │
│  📊 7 suggestions · est. 14.5 cr · ~2 min review │
│                                                   │
│  [ Approve All ✓ ]  [ Review One by One ]         │
└───────────────────────────────────────────────────┘
```

**Interaction model:**
- Check marks (✅) indicate pre-approved suggestions (toggled on by default for high-confidence patterns).
- Unchecked items (⬜) indicate lower-confidence suggestions that need explicit user action.
- User can tap any item to edit description, credits, or category.
- "Approve All" sends all checked items to `pendingCounterpartyReview` in one tap.
- Empty time slots show an `[+ Add]` button for manual entries.
- Bottom bar shows estimated review time and total credits.

### 3.5 Layer 3: The Existing Two-Step Review Workflow

Once the user approves draft suggestions, they become `pendingCounterpartyReview` entries — identical to manually created entries. The counterparty reviews them through the existing Review tab workflow. **No changes needed to the counterparty side.**

The counterparty sees:
- The entry details.
- The `sourceType` badge ("Auto-suggested" / "Pattern match" / "Calendar").
- The `sourceHint` ("Detected repeated 8:15am weekday pattern").
- The standard Confirm / Request Edit / Reject actions.

### 3.6 Low-Friction Design Principles

| Principle | Implementation |
|-----------|---------------|
| **< 20 seconds to log** | "Approve All" on the weekly draft timeline achieves this — one tap to send a whole week of entries. |
| **Review over data entry** | Users scan a pre-filled timeline, not a blank form. The default path is "approve what looks right" not "type everything from scratch." |
| **Automation first** | The app's first prompt each week is "Here's what we detected — does this look right?" not "What did you do this week?" |
| **Confidence scoring** | High-confidence suggestions (3+ matching occurrences) are pre-checked. Low-confidence (first-time detection, calendar-only) are unchecked. This reduces "approve all" regret. |
| **No notification spam** | Suggestions batch daily, not per-event. The weekly review prompt is the primary touchpoint. No push notification per individual suggestion. |

### 3.7 Settings for Auto-Capture

```
Auto-Capture Settings
─────────────────────
Detection Mode
  ● Smart (recommended) — time patterns + history
  ○ Calendar-enhanced — adds calendar event matching
  ○ Manual only — no auto-suggestions

Pattern Sensitivity
  [ Low ────●── High ]
  (Higher = more suggestions, some may be less accurate)

Weekly Draft Generation
  Day: [ Sunday ▾ ]  Time: [ 9:00 PM ▾ ]

Data Sources (when Calendar-enhanced):
  ☑ Personal calendar
  ☐ Shared family calendar
  ☐ School calendar (if connected)
```

### 3.8 Required Changes to Current Code

| Component | Current State | Required Change |
|-----------|--------------|-----------------|
| `SourceType` enum | `manual`, `suggested`, `template`, `calendar` | Add `patternMatch` for P0 time/recurrence patterns. Rename `suggested` to be the general parent concept or keep it and use `patternMatch` as the specific source. |
| `CareEntry.sourceHint` | Optional string | Strongly encourage non-null for all non-manual entries. Consider making it required when `sourceType != manual`. |
| New: `PatternMatchService` | Doesn't exist | New service that analyzes historical entries and generates draft suggestions. |
| New: `DraftTimelineProvider` | Doesn't exist | Presentation-layer provider for the weekly draft timeline view. |
| `CareEntry` status flow | `needsReview` is the initial auto-suggested status | No change — auto-captured entries still start at `needsReview` and follow existing transition rules. |
| Weekly review prompt | Basic review screen exists | Add a "Weekly Draft" entry point — either as a banner on the Ledger tab or as the initial view in the Review tab when drafts exist. |

### 3.9 Acceptance Criteria

- [ ] Auto-suggestions are generated from time patterns and entry history (P0).
- [ ] All auto-suggestions enter the pipeline as `needsReview` with `sourceType` and `sourceHint` populated.
- [ ] Auto-suggestions are NEVER auto-confirmed — they require author approval then counterparty confirmation.
- [ ] Weekly draft timeline view shows all suggestions for the current week in a scannable format.
- [ ] "Approve All" sends all checked suggestions to counterparty review in one action.
- [ ] Each suggestion shows why it was generated (source hint).
- [ ] Confidence level determines pre-checked vs unchecked state.
- [ ] Duplicate suggestions are suppressed (same date + category + description).
- [ ] Auto-capture can be fully disabled in Settings.
- [ ] No raw sensor data is stored — only human-readable source hints.
- [ ] Calendar integration is opt-in and off by default.
- [ ] Suggestion generation runs as a background batch, not real-time.
- [ ] Counterparty sees the `sourceType` badge on auto-suggested entries.

---

## 4. Alignment Audit Against Product Principles

| Principle | Decision Alignment | Status |
|-----------|--------------------|--------|
| **Fairness over perfection** | Auto-suggestions use "good enough" patterns, not precise tracking. The draft timeline invites editing, not blind acceptance. | ✅ Aligned |
| **Mutual consent** | Two-step review preserved: author approves draft → counterparty confirms. No auto-confirmation ever. | ✅ Aligned |
| **Low friction (< 20 sec)** | "Approve All" on weekly draft achieves sub-10-second approval for typical weeks. One-device-one-person avoids identity confusion overhead. | ✅ Aligned |
| **Automation first** | Passive pattern detection → pre-filled timeline → review. Manual entry is the fallback, not the primary path. | ✅ Aligned |
| **Privacy by default** | On-device-only signal processing. Opt-in sources. Ephemeral raw data. Guest Peek hides private notes. One device = one person eliminates co-mingled private data. | ✅ Aligned |
| **Local-first, serverless** | All pattern matching runs locally. No cloud ML. No data leaves the device unless explicitly synced with the counterparty. | ✅ Aligned |
| **Bidirectional care** | Both participants get the same auto-capture and review experience on their own devices. | ✅ Aligned |

---

## 5. Implementation Priority and Sequencing

### Phase 1: Identity Foundation (MUST DO FIRST)

**Why first:** Every other improvement depends on knowing WHO is using the device. The current hardcoded-identity bugs make all per-user features unreliable.

| Task | Size | Dependency |
|------|------|------------|
| First-run onboarding screen (name + avatar initial) | S | None |
| Persist device owner ID to secure storage | S | Onboarding |
| Remove `setCurrentUser()` from `SettingsProvider` | XS | Onboarding |
| Generate and persist device UUID for `SyncEvent.deviceId` | XS | Onboarding |
| Fix review screen to use `currentUserId` instead of hardcoded B | S | Onboarding |
| Fix balance screen to use `currentUserId` for proposer | XS | Onboarding |
| Fix balance screen labels to show names, not "Participant A/B" | S | Onboarding |

### Phase 2: Per-User Interface (builds on Phase 1)

| Task | Size | Dependency |
|------|------|------------|
| Personalized greeting on Ledger tab | S | Phase 1 |
| "You" vs name attribution on all entry cards | M | Phase 1 |
| Directional balance language ("You owe" / "They owe") | S | Phase 1 |
| Filter review queue to other-person's entries only | M | Phase 1 |
| "My Drafts" section on Ledger tab | M | Phase 1 |
| Contextual status labels | M | Phase 1 |
| Settlement card attribution and action gating | S | Phase 1 |
| Guest Peek read-only mode | M | Phase 1 |

### Phase 3: Auto-Recording Pipeline (builds on Phase 2)

| Task | Size | Dependency |
|------|------|------------|
| `PatternMatchService` — time recurrence detection | L | Existing entry history |
| `PatternMatchService` — weekly recurrence detection | M | Time recurrence |
| `PatternMatchService` — last-week template cloning | M | Entry history |
| Weekly draft timeline view | L | PatternMatchService |
| "Approve All" bulk action on draft timeline | M | Draft timeline view |
| Confidence scoring and pre-check logic | M | PatternMatchService |
| Auto-capture settings screen | S | Settings foundation |
| Calendar integration (P1 stretch) | L | Calendar permissions |

---

## 6. Open Questions for Future Phases

These are explicitly deferred and should NOT block MVP implementation:

| Question | Notes | Target Phase |
|----------|-------|-------------|
| **Multi-device per participant** | If a user has a phone and tablet, how do they share identity? Likely via encrypted identity export/import. | Phase 2+ |
| **More than 2 participants** | The `Ledger` model would need `List<String> participantIds` instead of `participantAId/BId`. Balance becomes a matrix, not a scalar. Review rules become "any non-author can review." | Phase 3+ |
| **Location-based auto-capture** | Technically feasible but high privacy impact. Requires geofence setup UX, background location permission, and battery optimization. | Phase 2+ |
| **Child visibility mode** | Should older children see the ledger? Read-only? With their own entries? | Phase 3+ |
| **Offline identity recovery** | If a device is lost, how does a participant recover their identity and data on a new device? | Phase 2+ |

---

## Appendix A: Critical Bugs in Current Code

These bugs were identified during this analysis and should be fixed as part of Phase 1:

### Bug 1: Review Screen Hardcodes Reviewer Identity
**File**: `lib/features/reviews/presentation/review_screen.dart`
**Lines**: 120, 199, 239, 279, 321
**Issue**: `reviewerId` is always set to `ledgerProvider.activeLedger!.participantBId` regardless of who the actual device owner is.
**Fix**: Use `context.read<SettingsProvider>().currentUserId`.

### Bug 2: Settlement Proposal Hardcodes Proposer Identity
**File**: `lib/features/balance/presentation/balance_screen.dart`
**Line**: 205
**Issue**: `proposerId` is always `ledgerProvider.activeLedger!.participantAId`.
**Fix**: Use `context.read<SettingsProvider>().currentUserId`.

### Bug 3: Balance Screen Uses Generic Labels
**File**: `lib/features/balance/presentation/balance_screen.dart`
**Lines**: 74, 78, 265, 290
**Issue**: Labels say "Participant A" and "Participant B" instead of resolved names.
**Fix**: Use `context.read<SettingsProvider>().participantName(id)` to resolve display names.

### Bug 4: Review Queue Shows All Actionable Entries
**File**: `lib/features/reviews/application/review_service.dart`
**Issue**: The review queue likely returns all entries with actionable status, not filtered to entries the current user should review.
**Fix**: Filter to entries where `authorId != currentUserId` AND status is `pendingCounterpartyReview`.

### Bug 5: No Device Identity for Sync Events
**File**: `lib/sync/domain/sync_event.dart`
**Line**: 31
**Issue**: `deviceId` is optional and never populated.
**Fix**: Generate a stable device UUID at first launch, persist it, and include it in every SyncEvent.

---

## Appendix B: New User Stories

### Story 1.3: Device Identity Setup
As a first-time user, I want to set up my identity on this device so the app knows who I am and shows me the right information.

**Acceptance Criteria:**
- First launch shows a setup screen with name input and avatar initial preview.
- Identity is persisted and used for all subsequent app sessions.
- I cannot switch to another participant's identity from within the app.

### Story 1.4: Guest Peek
As a participant, I want to show someone the ledger without giving them access to my private notes or write actions, so I can share information safely.

**Acceptance Criteria:**
- Guest Peek is accessible from Settings.
- It shows timeline, balance, and entry list in read-only mode.
- Private notes, review actions, and settlement proposals are hidden.
- Exiting Guest Peek returns to full participant view (no re-authentication needed for MVP).

### Story 2.4: Weekly Draft Timeline Review
As a caregiver, I want to see a pre-filled timeline of suggested activities for my week so I can approve them quickly instead of logging each one.

**Acceptance Criteria:**
- Draft timeline shows all auto-suggestions for the current week.
- High-confidence suggestions are pre-checked.
- I can edit any suggestion before approving.
- "Approve All" sends all checked suggestions for counterparty review.
- Each suggestion shows why it was generated.
- Review of a typical week (5–10 suggestions) takes under 2 minutes.

### Story 2.5: Pattern-Based Auto-Suggestions
As a caregiver, I want the app to learn my recurring activities and suggest them automatically so I don't have to remember to log every routine task.

**Acceptance Criteria:**
- After 3+ occurrences of a pattern (same time, same category), the app generates suggestions.
- Suggestions include a human-readable explanation of the detected pattern.
- Suggestions never bypass the two-step review process.
- I can disable auto-suggestions entirely in Settings.
