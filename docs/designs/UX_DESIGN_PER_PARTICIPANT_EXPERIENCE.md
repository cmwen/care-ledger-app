# UX Design: Per-Participant Experience

## Document Purpose

Comprehensive UX design specification for Care Ledger's one-device-per-participant model.
Covers identity, personalization, asymmetric views, onboarding/pairing, auto-recording UX,
and per-participant interface differences with concrete screen layouts and widget specs.

**Design Scope**: All five tabs (Ledger, Review, Timeline, Balance, Settings) plus
onboarding, pairing, and auto-capture flows.

**Accessibility Baseline**: WCAG AA contrast, 48dp touch targets, icon+label status
encoding, screen-reader semantics, text scaling to 200%.

---

## Table of Contents

1. [Design Principles](#1-design-principles)
2. [Identity & Color System](#2-identity--color-system)
3. [Onboarding & Pairing Flow](#3-onboarding--pairing-flow)
4. [Global Shell & App Bar](#4-global-shell--app-bar)
5. [Ledger Tab — Per-Participant](#5-ledger-tab--per-participant)
6. [Review Tab — Asymmetric Queue](#6-review-tab--asymmetric-queue)
7. [Timeline Tab — Dual-Perspective](#7-timeline-tab--dual-perspective)
8. [Balance Tab — Your Perspective](#8-balance-tab--your-perspective)
9. [Auto-Recording & Suggestion Cards](#9-auto-recording--suggestion-cards)
10. [Entry Card Component Spec](#10-entry-card-component-spec)
11. [Empty States Catalog](#11-empty-states-catalog)
12. [Settlement — Per-Participant](#12-settlement--per-participant)
13. [Settings — Identity Management](#13-settings--identity-management)
14. [Accessibility Checklist](#14-accessibility-checklist)
15. [Implementation Priority](#15-implementation-priority)

---

## 1. Design Principles

### 1.1 "You-First" Language

Every label, summary, and action is written from the perspective of the device owner.
The app never uses "Participant A / B" in user-facing text. Instead:

| Current (generic)           | Redesigned (personalized)                    |
|-----------------------------|----------------------------------------------|
| Participant A: 24.0 cr      | **You**: 24.0 credits earned                 |
| Participant B: 18.0 cr      | **Sarah**: 18.0 credits earned               |
| Net: 6.0 cr                 | Sarah owes you **6.0 credits**               |
| Entry by participant-a       | **Your entry**                               |
| Entry by participant-b       | **Sarah's entry**                            |
| Pending Review              | Waiting for **Sarah's** review               |
| Pending Review              | Waiting for **your** review                  |

### 1.2 Ownership Clarity

The device owner should always know at a glance:
- "This is MY app experience"
- "These are MY entries / THEIR entries"
- "This action is waiting on ME / waiting on THEM"

### 1.3 Reduce Cognitive Load

- Use consistent color tokens (not just names) so ownership is parseable at scroll speed
- Status labels adapt to whose action is needed, not just the raw status enum
- Badge counts reflect only what I need to act on

### 1.4 Trust Through Transparency

- Auto-captured entries always show why they were detected
- All decisions are auditable with full history
- Sync status is visible but never alarming

---

## 2. Identity & Color System

### 2.1 Participant Color Tokens

Each participant gets a semantic color role that persists across all screens.
The device owner always gets the **primary** role; the partner gets **secondary**.

```
// In AppTheme or a dedicated ParticipantTheme extension
class ParticipantColors {
  // "You" — always the device owner
  static const Color youSurface = Color(0xFFE8DEF8);     // primaryContainer
  static const Color youOnSurface = Color(0xFF1D192B);    // onPrimaryContainer
  static const Color youAccent = Color(0xFF6750A4);       // primary

  // "Partner" — the other participant
  static const Color partnerSurface = Color(0xFFD0BCFF);  // tertiaryContainer
  static const Color partnerOnSurface = Color(0xFF21005D); // onTertiaryContainer
  static const Color partnerAccent = Color(0xFF7D5260);   // tertiary
}
```

**Rationale**: Using the existing M3 primary/tertiary color roles means the
distinction works automatically in both light and dark themes without custom
palette management.

### 2.2 Avatar System

```
┌─────────────────────────────────────────┐
│  Avatar Widget Spec                     │
│                                         │
│  ┌──┐  You (device owner)              │
│  │ Y │  - Primary color background      │
│  └──┘  - White initial letter           │
│        - Subtle ring: primary border    │
│                                         │
│  ┌──┐  Partner                          │
│  │ S │  - Tertiary color background     │
│  └──┘  - White initial letter           │
│        - No ring                        │
│                                         │
│  Sizes: compact (24dp), standard (36dp),│
│         large (48dp)                    │
└─────────────────────────────────────────┘
```

### 2.3 Ownership Indicator Strip

Entry cards use a **4dp left-edge color strip** to denote ownership:
- Primary color = your entry
- Tertiary color = partner's entry

This provides instant scan-ability without reading the author name.

---

## 3. Onboarding & Pairing Flow

### 3.1 First Launch — Identity Setup

```
┌──────────────────────────────────────────┐
│                                          │
│        [Care Ledger logo/icon]           │
│                                          │
│        Welcome to Care Ledger            │
│    Make care work visible and fair.      │
│                                          │
│  ┌────────────────────────────────────┐  │
│  │  What should we call you?          │  │
│  │  ┌──────────────────────────────┐  │  │
│  │  │ Your name                    │  │  │
│  │  └──────────────────────────────┘  │  │
│  └────────────────────────────────────┘  │
│                                          │
│  [Optional: Choose avatar color]         │
│  ● Purple (default)  ○ Blue  ○ Teal     │
│                                          │
│  ┌────────────────────────────────────┐  │
│  │          Continue →                │  │
│  └────────────────────────────────────┘  │
│                                          │
│  Your data stays on this device.         │
│  No account needed.                      │
│                                          │
└──────────────────────────────────────────┘
```

**Interaction**: Single text field + continue. Name is stored as the
`currentUser` in SettingsProvider and persisted locally.

### 3.2 Ledger Setup — Two Paths

After identity setup, the user sees a choice:

```
┌──────────────────────────────────────────┐
│                                          │
│   Hi, Marcus! Let's set up your ledger.  │
│                                          │
│  ┌────────────────────────────────────┐  │
│  │  🆕  Create a New Ledger           │  │
│  │                                    │  │
│  │  Start a shared care ledger and    │  │
│  │  invite your co-parent to join.    │  │
│  └────────────────────────────────────┘  │
│                                          │
│  ┌────────────────────────────────────┐  │
│  │  🔗  Join an Existing Ledger       │  │
│  │                                    │  │
│  │  Someone shared an invite code     │  │
│  │  with you? Enter it here.          │  │
│  └────────────────────────────────────┘  │
│                                          │
└──────────────────────────────────────────┘
```

### 3.3 Create Ledger Path

```
┌──────────────────────────────────────────┐
│  ← Back                                 │
│                                          │
│  Name your shared ledger                 │
│  ┌──────────────────────────────────┐    │
│  │ Kids School & Home Care          │    │
│  └──────────────────────────────────┘    │
│  Examples: "Family Care", "Co-parenting" │
│                                          │
│  Who is your care partner?               │
│  ┌──────────────────────────────────┐    │
│  │ Partner's first name             │    │
│  └──────────────────────────────────┘    │
│  They'll set up their own name later.    │
│                                          │
│  ┌────────────────────────────────────┐  │
│  │        Create Ledger →             │  │
│  └────────────────────────────────────┘  │
│                                          │
└──────────────────────────────────────────┘
```

**After creation**: The app generates a **pairing invite** (see 3.5).

### 3.4 Join Ledger Path

```
┌──────────────────────────────────────────┐
│  ← Back                                 │
│                                          │
│  Join a shared ledger                    │
│                                          │
│  Enter the invite code shared with you:  │
│                                          │
│  ┌──────────────────────────────────┐    │
│  │  ____  ____  ____  ____  ____   │    │
│  └──────────────────────────────────┘    │
│                                          │
│  ── or ──                                │
│                                          │
│  [📷 Scan QR Code]                       │
│                                          │
│  ┌────────────────────────────────────┐  │
│  │          Join Ledger →             │  │
│  └────────────────────────────────────┘  │
│                                          │
│  🔒 The invite is encrypted.             │
│  Only you and your partner can see       │
│  the ledger data.                        │
│                                          │
└──────────────────────────────────────────┘
```

### 3.5 Pairing — Invite Generation & Acceptance

**Creator's device** (after ledger creation):

```
┌──────────────────────────────────────────┐
│                                          │
│  ✅ Ledger Created!                      │
│                                          │
│  Share this invite with Sarah:           │
│                                          │
│  ┌────────────────────────────────────┐  │
│  │          [QR Code]                 │  │
│  │                                    │  │
│  │   Invite Code: AB3K-7F2M-9XPN    │  │
│  └────────────────────────────────────┘  │
│                                          │
│  [📋 Copy Code]  [📤 Share...]           │
│                                          │
│  Sarah needs to:                         │
│  1. Install Care Ledger                  │
│  2. Tap "Join an Existing Ledger"        │
│  3. Enter this code or scan the QR       │
│                                          │
│  ┌────────────────────────────────────┐  │
│  │   Done — Go to Ledger →            │  │
│  └────────────────────────────────────┘  │
│                                          │
│  ⏳ Waiting for Sarah to connect...      │
│  You can start adding entries now.       │
│                                          │
└──────────────────────────────────────────┘
```

**Partner's device** (after scanning/entering code):

```
┌──────────────────────────────────────────┐
│                                          │
│  🔗 Connected!                           │
│                                          │
│  You're joining:                         │
│  "Kids School & Home Care"               │
│  Created by: Marcus                      │
│                                          │
│  Marcus entered your name as "Sarah".    │
│  ┌──────────────────────────────────┐    │
│  │ Sarah  ✏️                        │    │
│  └──────────────────────────────────┘    │
│  Change it if you'd like.               │
│                                          │
│  ┌────────────────────────────────────┐  │
│  │       Start Using Ledger →         │  │
│  └────────────────────────────────────┘  │
│                                          │
└──────────────────────────────────────────┘
```

### 3.6 Pairing State Machine

```
Creator device:
  [Setup Identity] → [Create Ledger] → [Show Invite Code]
       ↓                                      ↓
  Store currentUser                    ledger.status = awaitingPair
       as participantA                        ↓
                                       [Partner Accepts]
                                              ↓
                                       ledger.status = active
                                       Sync initial state

Partner device:
  [Setup Identity] → [Enter/Scan Code] → [Confirm Join]
       ↓                                      ↓
  Store currentUser                    Receive ledger data
       as participantB                 ledger.status = active
                                       Sync initial state
```

---

## 4. Global Shell & App Bar

### 4.1 Redesigned App Bar

The current app bar shows only the ledger title and a sync icon.
Redesign to include identity context:

```
┌──────────────────────────────────────────────────┐
│  [Y] Marcus    Kids School & Home Care    🔄 ●   │
│                                           synced  │
└──────────────────────────────────────────────────┘
 ↑                ↑                          ↑
 Your avatar     Ledger title          Sync status
 + name                                with partner
```

**Widget Spec — `IdentityAppBar`**:

```dart
AppBar(
  leading: Padding(
    padding: EdgeInsets.all(8),
    child: ParticipantAvatar(
      participant: currentUser,
      size: AvatarSize.compact,  // 32dp
      showYouBadge: true,        // small "you" label below
    ),
  ),
  title: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(ledger.title, style: titleSmall),
      Text(
        'with ${partnerName}',
        style: labelSmall.copyWith(color: outline),
      ),
    ],
  ),
  actions: [
    SyncStatusIndicator(status: syncStatus),
    // Show notification bell when there are pending actions
    if (pendingActionCount > 0)
      Badge(
        label: Text('$pendingActionCount'),
        child: IconButton(
          icon: Icon(Icons.notifications_outlined),
          onPressed: navigateToReview,
        ),
      ),
  ],
);
```

### 4.2 Sync Status Indicator

```
State          Icon              Color         Label (tooltip)
─────────────────────────────────────────────────────────────
synced         Icons.cloud_done  green         "Synced with Sarah"
syncing        Icons.sync (spin) primary       "Syncing..."
pendingSync    Icons.cloud_queue amber         "Changes pending sync"
offline        Icons.cloud_off   outline       "Offline — changes saved locally"
neverPaired    Icons.link_off    error         "Not yet connected"
```

### 4.3 Bottom Navigation Badge Updates

```dart
// Review tab badge: entries waiting for YOUR review
// (partner's entries in pendingCounterpartyReview status)
NavigationDestination(
  icon: Badge(
    isLabelVisible: pendingYourReviewCount > 0,
    label: Text('$pendingYourReviewCount'),
    child: Icon(Icons.inbox_outlined),
  ),
  label: 'Review',
),

// Balance tab badge: unresolved settlement proposals for YOU
NavigationDestination(
  icon: Badge(
    isLabelVisible: pendingSettlementCount > 0,
    label: Text('$pendingSettlementCount'),
    child: Icon(Icons.account_balance_wallet_outlined),
  ),
  label: 'Balance',
),
```

---

## 5. Ledger Tab — Per-Participant

### 5.1 Redesigned Week Summary Card

The week summary becomes personalized:

```
┌──────────────────────────────────────────┐
│  📅 This Week                            │
│                                          │
│  ┌──────────────┐  ┌──────────────┐      │
│  │  Your entries │  │ Sarah's      │      │
│  │     ┌──┐     │  │  entries     │      │
│  │     │ 8│     │  │   ┌──┐      │      │
│  │     └──┘     │  │   │ 5│      │      │
│  │  12.0 cr     │  │   └──┘      │      │
│  └──────────────┘  │  8.0 cr     │      │
│  ─── primary bg ─   └──────────────┘     │
│                     ─── tertiary bg ──    │
│                                          │
│  ┌────────────────────────────────────┐  │
│  │ ⏳ 3 entries waiting for Sarah     │  │
│  │ 📥 2 entries waiting for your      │  │
│  │    review — tap to review          │  │
│  └────────────────────────────────────┘  │
└──────────────────────────────────────────┘
```

**Key changes**:
- Split stats by "You" vs partner
- Action-oriented pending counts with names
- "Waiting for your review" is tappable → navigates to Review tab
- Uses participant color tokens for the two stat boxes

### 5.2 Entry List — Ownership Visual

The "Recent Entries" list uses the ownership strip and personalized labels:

```
┌──────────────────────────────────────────┐
│  Recent Entries                          │
│                                          │
│  ┃ 🚗  School pickup               2.0cr│  ← primary strip = YOUR entry
│  ┃ [Y] You · Today, 3:15 PM             │
│  ┃ ⏳ Waiting for Sarah's review         │
│  ┃                                       │
│  ┃ 🧺  Laundry                     1.0cr│  ← tertiary strip = PARTNER entry
│  ┃ [S] Sarah · Today, 10:00 AM          │
│  ┃ 📥 Waiting for your review            │
│  ┃                                       │
│  ┃ 🍳  Cooked dinner               1.5cr│  ← primary strip
│  ┃ [Y] You · Yesterday, 6:30 PM         │
│  ┃ ✅ Confirmed                          │
│                                          │
└──────────────────────────────────────────┘
```

### 5.3 Personalized Status Labels

The `EntryStatus` labels change based on who is viewing:

```
Status Enum                    Your Entry View            Partner Entry View
─────────────────────────────────────────────────────────────────────────────
needsReview                    "Needs your review"        "Needs your review"
pendingCounterpartyReview      "Waiting for Sarah"        "Waiting for your review"
confirmed                      "Confirmed ✓"              "Confirmed ✓"
needsEdit                      "Sarah requested changes"  "You requested changes"
rejected                       "Rejected by Sarah"        "You rejected this"
```

**Implementation approach** — a helper that takes `EntryStatus`, `authorId`,
`currentUserId`, and `partnerName`:

```dart
String personalizedStatusLabel({
  required EntryStatus status,
  required String authorId,
  required String currentUserId,
  required String partnerName,
}) {
  final isMyEntry = authorId == currentUserId;

  switch (status) {
    case EntryStatus.needsReview:
      return 'Needs your review';
    case EntryStatus.pendingCounterpartyReview:
      return isMyEntry
          ? 'Waiting for $partnerName'
          : 'Waiting for your review';
    case EntryStatus.confirmed:
      return 'Confirmed';
    case EntryStatus.needsEdit:
      return isMyEntry
          ? '$partnerName requested changes'
          : 'You requested changes';
    case EntryStatus.rejected:
      return isMyEntry
          ? 'Rejected by $partnerName'
          : 'You rejected this';
  }
}
```

---

## 6. Review Tab — Asymmetric Queue

### 6.1 Core Concept Change

**Current behavior**: Shows ALL entries in `pendingCounterpartyReview` status.
**Redesigned behavior**: Shows only entries **waiting for YOUR decision**.

On Marcus's device: entries authored by Sarah in `pendingCounterpartyReview`
On Sarah's device: entries authored by Marcus in `pendingCounterpartyReview`

Additionally: entries in `needsReview` that were auto-suggested for THIS user.

### 6.2 Review Queue Sections

```
┌──────────────────────────────────────────┐
│  Review                                  │
│                                          │
│  ┌────────────────────────────────────┐  │
│  │  Sarah submitted 3 entries for     │  │
│  │  your review this week.            │  │
│  │                                    │  │
│  │  Est. time: ~2 minutes             │  │
│  │  [Approve All]  [Review One by One]│  │
│  └────────────────────────────────────┘  │
│                                          │
│  ── Partner's Entries (need your OK) ──  │
│                                          │
│  ┃ 🚗  School pickup — Sarah    2.0 cr  │
│  ┃ Mon, Mar 10                           │
│  ┃ [✏️ Edit] [✗ Reject] [✓ Approve]      │
│  ┃                                       │
│  ┃ 🧹  Housework — Sarah       1.0 cr   │
│  ┃ Tue, Mar 11                           │
│  ┃ [✏️ Edit] [✗ Reject] [✓ Approve]      │
│                                          │
│  ── Your Auto-Suggestions ──             │
│  (detected activities to confirm)        │
│                                          │
│  ┃ ✨ 🚗  Driving detected      2.0 cr  │
│  ┃ Wed, Mar 12 · School route pattern    │
│  ┃ [🗑 Dismiss] [✏️ Edit] [✓ Confirm]    │
│                                          │
│  ── Your Entries Needing Edits ──        │
│  (Sarah requested changes)               │
│                                          │
│  ┃ ⚠️ 🍳  Dinner prep          1.5 cr   │
│  ┃ "Can you add the duration?"           │
│  ┃ [Open & Edit →]                       │
│                                          │
└──────────────────────────────────────────┘
```

### 6.3 Three-Section Review Architecture

| Section                        | Source Filter                                      | Actions Available            |
|--------------------------------|----------------------------------------------------|------------------------------|
| **Partner's entries for you**  | `authorId != currentUserId && status == pendingCounterpartyReview` | Approve, Reject, Request Edit |
| **Your auto-suggestions**      | `authorId == currentUserId && status == needsReview && sourceType != manual` | Confirm, Edit, Dismiss |
| **Your entries needing edits** | `authorId == currentUserId && status == needsEdit` | Open editor                   |

### 6.4 Quick-Approve Banner

When there are multiple partner entries to review, show a summary banner
at the top with a "Review All" CTA that enters a swipe-through flow:

```
┌──────────────────────────────────────────┐
│  📥 3 entries from Sarah                 │
│  Estimated review time: ~2 min           │
│                                          │
│  [Review All →]                          │
└──────────────────────────────────────────┘
```

The "Review All" flow shows entries one at a time in a card stack
with swipe-right-to-approve, swipe-left-to-reject, swipe-up-to-skip.

### 6.5 Swipe Review Card (Detail View)

```
┌──────────────────────────────────────────┐
│         ← Swipe to reject                │
│                     Swipe to approve →   │
│                                          │
│  ┌────────────────────────────────────┐  │
│  │  🚗  School pickup                │  │
│  │                                    │  │
│  │  Submitted by: Sarah              │  │
│  │  When: Mon, Mar 10 at 3:15 PM    │  │
│  │  Category: Driving                │  │
│  │  Credits proposed: 2.0            │  │
│  │  Duration: 30 min                 │  │
│  │                                    │  │
│  │  ┌──────────────────────────────┐ │  │
│  │  │ 📍 Source: Repeated school   │ │  │
│  │  │    route pattern detected    │ │  │
│  │  └──────────────────────────────┘ │  │
│  │                                    │  │
│  │  [✏️ Request Edit]                 │  │
│  └────────────────────────────────────┘  │
│                                          │
│  Card 1 of 3                  [Skip →]   │
│                                          │
└──────────────────────────────────────────┘
```

---

## 7. Timeline Tab — Dual-Perspective

### 7.1 Participant Legend

Add a visible legend bar below the filter controls:

```
┌──────────────────────────────────────────┐
│  [Day | Week]              [🔽 Filter]   │
│                                          │
│  ● You (Marcus)    ● Sarah               │
│  ─ primary dot ─   ─ tertiary dot ─      │
└──────────────────────────────────────────┘
```

### 7.2 Timeline Items — Color-Coded by Author

Each timeline dot and connector uses the participant's color:

```
  ● (primary)  Your entry: School pickup ─── 2.0 cr
  │
  ● (tertiary) Sarah: Laundry ───────────── 1.0 cr
  │
  ● (primary)  Your entry: Cooked dinner ── 1.5 cr
  │
  ● (tertiary) Sarah: Shopping ──────────── 2.0 cr
```

### 7.3 Week View — Split Contribution Bar

In week view, each week card shows a stacked horizontal bar:

```
┌──────────────────────────────────────────┐
│  Mar 4 – Mar 10                  18.0 cr │
│                                          │
│  ████████████░░░░░░  You: 12.0 cr (67%)  │
│  (primary)  (tertiary)                   │
│                      Sarah: 6.0 cr (33%) │
│                                          │
│  📋 8 entries · ✅ 5 confirmed            │
│  🚗 ×3  🧺 ×2  🍳 ×2  🏠 ×1              │
└──────────────────────────────────────────┘
```

---

## 8. Balance Tab — Your Perspective

### 8.1 Redesigned Balance Overview

Replace "Participant A / Participant B" with personalized first-person language:

```
┌──────────────────────────────────────────┐
│                                          │
│            Balance Overview              │
│                                          │
│  ┌──────────────┐  ┌──────────────┐      │
│  │     You       │  │    Sarah     │      │
│  │   ┌──────┐   │  │   ┌──────┐  │      │
│  │   │ 42.0 │   │  │   │ 36.0 │  │      │
│  │   └──────┘   │  │   └──────┘  │      │
│  │ confirmed cr │  │ confirmed cr│      │
│  └──────────────┘  └──────────────┘      │
│  ── primary bg ──  ── tertiary bg ──     │
│                                          │
│  ┌────────────────────────────────────┐  │
│  │     Sarah owes you 6.0 credits     │  │
│  │   ──────── or ────────             │  │
│  │     You owe Sarah 6.0 credits      │  │
│  │   ──────── or ────────             │  │
│  │     You're balanced! 🎉            │  │
│  └────────────────────────────────────┘  │
│                                          │
│  Pending:                                │
│  • You: 3.0 cr (2 entries in review)     │
│  • Sarah: 1.5 cr (1 entry in review)    │
│                                          │
└──────────────────────────────────────────┘
```

### 8.2 Net Balance Statement Logic

```dart
String netBalanceStatement({
  required double netBalance,
  required String currentUserId,
  required String creditorId,
  required String partnerName,
}) {
  if (netBalance == 0) return "You're balanced! 🎉";

  final youAreCreditor = creditorId == currentUserId;
  final amount = netBalance.abs().toStringAsFixed(1);

  if (youAreCreditor) {
    return '$partnerName owes you $amount credits';
  } else {
    return 'You owe $partnerName $amount credits';
  }
}
```

### 8.3 Pending Credits — Personalized

```
Pending Credits
─────────────────────────────────
[Y] You       3.0 cr  (2 entries awaiting Sarah's review)
[S] Sarah     1.5 cr  (1 entry awaiting your review)
```

---

## 9. Auto-Recording & Suggestion Cards

### 9.1 Design Decision: Hybrid Feed + Review Queue

Auto-detected activities appear in **two places**:

1. **Inline on the Ledger tab** as a dismissible "suggestion banner"
   (for real-time awareness)
2. **In the Review tab** under "Your Auto-Suggestions" section
   (for batch weekly processing)

**Rationale**: Users who check the app daily see suggestions immediately.
Users who only do weekly review still find everything in one place.

### 9.2 Suggestion Banner (Ledger Tab)

Appears above the entry list when new auto-suggestions exist:

```
┌──────────────────────────────────────────┐
│  ✨ 2 activities detected                │
│                                          │
│  🚗 School pickup — Today, 3:15 PM      │
│     Detected from: Repeated route        │
│     Confidence: ●●●○ High               │
│     Suggested credits: 2.0              │
│     [Dismiss]  [Edit & Confirm]          │
│                                          │
│  🧺 Laundry — Today, 10:00 AM           │
│     Detected from: Weekly pattern        │
│     Confidence: ●●○○ Medium             │
│     Suggested credits: 1.0              │
│     [Dismiss]  [Edit & Confirm]          │
│                                          │
│  [Confirm All 2]  [Review in Weekly →]   │
└──────────────────────────────────────────┘
```

### 9.3 Suggestion Card — Detailed Spec

```
┌──────────────────────────────────────────┐
│  ✨ Auto-detected                        │
│                                          │
│  ┌────┐                                  │
│  │ 🚗 │  School pickup                   │
│  └────┘  Today at 3:15 PM               │
│          2.0 credits (suggested)         │
│                                          │
│  ┌────────────────────────────────────┐  │
│  │ 📍 WHY: Your phone detected a trip │  │
│  │    matching your Mon/Wed/Fri school│  │
│  │    route pattern (3 weeks match).  │  │
│  └────────────────────────────────────┘  │
│                                          │
│  Confidence:  ●●●○ High                 │
│                                          │
│  ┌──────┐  ┌──────────┐  ┌───────────┐  │
│  │Dismiss│  │Edit First│  │ Confirm ✓ │  │
│  └──────┘  └──────────┘  └───────────┘  │
│                                          │
│  🔇 Don't suggest this type again       │
└──────────────────────────────────────────┘
```

### 9.4 Confidence Indicator Spec

```
Confidence   Dots    Color      Meaning
──────────────────────────────────────────
High         ●●●○    green      3+ prior confirmations of this pattern
Medium       ●●○○    amber      1-2 prior matches
Low          ●○○○    outline    First-time detection, less certain

Accessibility: Dots are supplemented with text label.
Semantics: "Confidence: High — 3 of 4 dots filled"
```

### 9.5 Transparency — "Why Detected" Panel

Every auto-captured entry MUST show a `sourceHint` in a distinct
info container. This is non-negotiable per product principles.

**Visual treatment**: Uses `surfaceContainerHighest` background with
an `info_outline` icon prefix. The text explains the detection reason
in plain language.

**Examples of `sourceHint` text**:
- "Detected from your Mon/Wed/Fri school route pattern (matched 3 weeks)"
- "Calendar event: 'Soccer practice pickup' at 4:00 PM"
- "Matched your 'Sunday laundry' weekly template"
- "Location visit matching 'Grocery Store' for 45 minutes"

### 9.6 Privacy Controls — "Don't Track This"

Each suggestion card includes a **tertiary text button**: "Don't suggest this type again"

Tapping opens a confirmation:

```
┌──────────────────────────────────────────┐
│  Stop suggesting "School route" entries?  │
│                                          │
│  You can re-enable this in:              │
│  Settings → Auto-Detection Preferences   │
│                                          │
│  [Cancel]           [Stop Suggesting]    │
└──────────────────────────────────────────┘
```

### 9.7 Activity Feed vs Review Queue — Final Decision

| Scenario                   | Where it appears          | Action model              |
|----------------------------|---------------------------|---------------------------|
| New auto-detection (today) | Ledger tab banner         | Quick confirm/dismiss     |
| Unreviewed suggestions     | Review tab, section 2     | Batch confirm in weekly   |
| Partner's submitted entry  | Review tab, section 1     | Approve/reject/edit       |
| Your entry needs edits     | Review tab, section 3     | Open editor               |

---

## 10. Entry Card Component Spec

### 10.1 Unified `OwnershipEntryCard` Widget

Replace the current `EntryCard` with a participant-aware version:

```dart
class OwnershipEntryCard extends StatelessWidget {
  final CareEntry entry;
  final String currentUserId;
  final String partnerName;
  final VoidCallback? onTap;

  // Computed internally:
  // - isMyEntry = entry.authorId == currentUserId
  // - ownershipColor = isMyEntry ? primary : tertiary
  // - statusLabel = personalizedStatusLabel(...)
  // - authorLabel = isMyEntry ? "You" : partnerName
}
```

### 10.2 Card Layout

```
┌─┬────────────────────────────────────────┐
│ │  ┌────┐                                │
│ │  │ 🚗 │  School pickup          2.0 cr │
│▌│  └────┘                                │
│ │  [Y] You · Today, 3:15 PM · 30m       │
│ │  ⏳ Waiting for Sarah's review          │
│ │                                        │
│ │  (if auto-suggested:)                  │
│ │  ┌─────────────────────────────────┐   │
│ │  │ ✨ Auto-detected: school route  │   │
│ │  └─────────────────────────────────┘   │
└─┴────────────────────────────────────────┘
 ↑
 4dp ownership strip
 (primary = you, tertiary = partner)
```

### 10.3 Status Row — Icon + Personalized Label

Always use icon + text (never color-only) for accessibility:

```
⏳ Waiting for Sarah's review      (amber icon)
📥 Waiting for your review          (blue icon)
✅ Confirmed                        (green icon)
⚠️ Sarah requested changes          (orange icon)
✏️ You requested changes             (orange icon)
❌ Rejected by Sarah                 (red icon)
🗑 You rejected this                 (red icon)
```

---

## 11. Empty States Catalog

### 11.1 Ledger Tab — No Entries (Your Perspective)

```
┌──────────────────────────────────────────┐
│                                          │
│         ┌──────────┐                     │
│         │ 📝       │                     │
│         └──────────┘                     │
│                                          │
│  No entries from you this week           │
│                                          │
│  Tap + to add your first care entry,     │
│  or wait for auto-detected suggestions.  │
│                                          │
│  ┌────────────────────────────────────┐  │
│  │         + Add Entry                │  │
│  └────────────────────────────────────┘  │
│                                          │
└──────────────────────────────────────────┘
```

### 11.2 Review Tab — Nothing to Review

```
┌──────────────────────────────────────────┐
│                                          │
│         ┌──────────┐                     │
│         │ ✅       │                     │
│         └──────────┘                     │
│                                          │
│  All caught up!                          │
│                                          │
│  No entries are waiting for your review. │
│  Sarah hasn't submitted any new entries  │
│  since your last review.                 │
│                                          │
│  You'll get a notification when there's  │
│  something to review.                    │
│                                          │
└──────────────────────────────────────────┘
```

### 11.3 Review Tab — Partner Hasn't Submitted

```
┌──────────────────────────────────────────┐
│                                          │
│         ┌──────────┐                     │
│         │ 📭       │                     │
│         └──────────┘                     │
│                                          │
│  Sarah hasn't submitted any entries      │
│  for you to review yet.                  │
│                                          │
│  In the meantime, you can add your own   │
│  entries in the Ledger tab.              │
│                                          │
│  ┌────────────────────────────────────┐  │
│  │       Go to Ledger →               │  │
│  └────────────────────────────────────┘  │
│                                          │
└──────────────────────────────────────────┘
```

### 11.4 Review Tab — Your Auto-Suggestions Empty

```
  ── Your Auto-Suggestions ──

  No activities detected this week.
  The app learns your patterns over time.
  You can always add entries manually.
```

### 11.5 Balance Tab — No Confirmed Entries Yet

```
┌──────────────────────────────────────────┐
│                                          │
│         ┌──────────┐                     │
│         │ ⚖️       │                     │
│         └──────────┘                     │
│                                          │
│  No confirmed credits yet               │
│                                          │
│  Once you and Sarah confirm entries,     │
│  the balance will appear here.           │
│                                          │
│  Add entries and complete reviews to     │
│  start building your care credit record. │
│                                          │
└──────────────────────────────────────────┘
```

### 11.6 Timeline Tab — No Data

```
┌──────────────────────────────────────────┐
│                                          │
│         ┌──────────┐                     │
│         │ 📊       │                     │
│         └──────────┘                     │
│                                          │
│  No care history yet                     │
│                                          │
│  Your shared timeline with Sarah will    │
│  show all care activities once entries   │
│  are added and reviewed.                 │
│                                          │
└──────────────────────────────────────────┘
```

### 11.7 Pre-Pairing Empty State (Ledger Created, Partner Not Joined)

```
┌──────────────────────────────────────────┐
│                                          │
│         ┌──────────┐                     │
│         │ 🔗       │                     │
│         └──────────┘                     │
│                                          │
│  Waiting for Sarah to join               │
│                                          │
│  Share the invite code so Sarah can      │
│  connect from their device.              │
│                                          │
│  ┌────────────────────────────────────┐  │
│  │      Show Invite Code →            │  │
│  └────────────────────────────────────┘  │
│                                          │
│  You can start adding entries now.       │
│  Sarah will see them once connected.     │
│                                          │
│  ┌────────────────────────────────────┐  │
│  │      + Add Entry                   │  │
│  └────────────────────────────────────┘  │
│                                          │
└──────────────────────────────────────────┘
```

---

## 12. Settlement — Per-Participant

### 12.1 Settlement Card — Perspective-Aware

**When you proposed**:

```
┌──────────────────────────────────────────┐
│  💰 You proposed                         │
│     5.0 cr via Cash                      │
│     Status: ⏳ Waiting for Sarah         │
│     "For this month's balance"           │
│                                          │
│  [Cancel Proposal]                       │
└──────────────────────────────────────────┘
```

**When partner proposed to you**:

```
┌──────────────────────────────────────────┐
│  📩 Sarah proposed                       │
│     5.0 cr via Cash                      │
│     Status: 📥 Needs your response       │
│     "For this month's balance"           │
│                                          │
│  [Decline]  [Request Change]  [Accept ✓] │
└──────────────────────────────────────────┘
```

**Accepted — waiting for completion**:

```
┌──────────────────────────────────────────┐
│  🤝 Settlement accepted                  │
│     5.0 cr via Cash                      │
│     Proposed by: Sarah                   │
│     Accepted by: You                     │
│                                          │
│  [Mark as Completed ✓]                   │
└──────────────────────────────────────────┘
```

### 12.2 Settlement Proposal Dialog — Personalized

```
┌──────────────────────────────────────────┐
│  Propose Settlement                      │
│                                          │
│  Current balance:                        │
│  Sarah owes you 6.0 credits             │
│                                          │
│  ┌──────────────────────────────────┐    │
│  │ Credits to settle: [6.0    ] cr  │    │
│  └──────────────────────────────────┘    │
│                                          │
│  Method:                                 │
│  [Cash ✓] [Bank] [Reciprocal] [Other]   │
│                                          │
│  ┌──────────────────────────────────┐    │
│  │ Note: For March balance          │    │
│  └──────────────────────────────────┘    │
│                                          │
│  [Cancel]        [Propose to Sarah →]    │
└──────────────────────────────────────────┘
```

---

## 13. Settings — Identity Management

### 13.1 Redesigned Participants Section

```
┌──────────────────────────────────────────┐
│  👤 Your Profile                         │
│  ┌────────────────────────────────────┐  │
│  │  ┌──┐                              │  │
│  │  │ M│  Marcus (You)                │  │
│  │  └──┘  This device                 │  │
│  │       [Edit Name]                  │  │
│  └────────────────────────────────────┘  │
│                                          │
│  🤝 Care Partner                         │
│  ┌────────────────────────────────────┐  │
│  │  ┌──┐                              │  │
│  │  │ S│  Sarah                       │  │
│  │  └──┘  Connected ● (last synced    │  │
│  │       2 hours ago)                 │  │
│  │       [Edit Display Name]          │  │
│  └────────────────────────────────────┘  │
│                                          │
│  🔗 Pairing                              │
│  ┌────────────────────────────────────┐  │
│  │  Invite Code: AB3K-7F2M-9XPN      │  │
│  │  [Show QR]  [Copy]  [Regenerate]   │  │
│  └────────────────────────────────────┘  │
└──────────────────────────────────────────┘
```

### 13.2 Auto-Detection Preferences

New section in Settings:

```
┌──────────────────────────────────────────┐
│  🤖 Auto-Detection                       │
│  ┌────────────────────────────────────┐  │
│  │                                    │  │
│  │  📍 Location patterns       [on]   │  │
│  │  📅 Calendar events          [on]   │  │
│  │  ⏰ Time-based patterns      [on]   │  │
│  │                                    │  │
│  │  ── Suppressed Patterns ──         │  │
│  │  🚗 "School route" — re-enable     │  │
│  │                                    │  │
│  │  [Clear all detection history]     │  │
│  └────────────────────────────────────┘  │
└──────────────────────────────────────────┘
```

### 13.3 Device Identity Persistence

The `currentUserId` MUST be persisted to device-local storage at first
launch and never change (it's the device's identity in the ledger).
The SettingsProvider should load this from `SharedPreferences` or
equivalent local storage on init.

```dart
// On first launch:
// 1. Generate stable device ID
// 2. User enters their name
// 3. Store: { currentUserId: generatedId, displayName: enteredName }
// 4. This ID becomes participantAId (creator) or participantBId (joiner)
```

---

## 14. Accessibility Checklist

### 14.1 Color + Shape Coding

| Element                | Color Signal           | Non-Color Signal              |
|------------------------|------------------------|-------------------------------|
| Your entry strip       | Primary (purple)       | Strip position = left edge    |
| Partner entry strip    | Tertiary (mauve)       | Strip position = left edge    |
| Entry confirmed        | Green                  | ✅ icon + "Confirmed" text    |
| Entry rejected         | Red                    | ❌ icon + "Rejected" text     |
| Entry needs edit       | Orange                 | ⚠️ icon + "Needs edit" text   |
| Entry pending          | Amber/Blue             | ⏳/📥 icon + status text      |
| Confidence high        | Green dots             | "High" text label             |
| Confidence medium      | Amber dots             | "Medium" text label           |
| Confidence low         | Grey dots              | "Low" text label              |

### 14.2 Semantic Labels

Every interactive element MUST have a `Semantics` label:

```dart
Semantics(
  label: 'Approve school pickup entry by Sarah, 2.0 credits',
  button: true,
  child: FilledButton(...),
)

Semantics(
  label: 'Your entry: School pickup, 2.0 credits, waiting for Sarah\'s review',
  child: OwnershipEntryCard(...),
)

Semantics(
  label: 'Auto-detected activity: Driving, high confidence, tap to review',
  child: SuggestionCard(...),
)
```

### 14.3 Touch Target Compliance

| Widget                  | Minimum Size | Current Status |
|-------------------------|-------------|----------------|
| Entry card tap area     | 48×48 dp    | ✅ Full card    |
| Approve/Reject buttons  | 48×36 dp    | ⚠️ Increase height |
| Avatar tap              | 48×48 dp    | ✅ Standard     |
| Suggestion dismiss      | 48×48 dp    | Needs implementation |
| Swipe review card       | Full width  | ✅ Cards        |
| Confidence dots         | Not tappable | N/A (info only) |

### 14.4 Screen Reader Flow

Tab order for Review screen:
1. Review summary banner (count + estimated time)
2. Partner's entries section header
3. Each partner entry card (description → credits → actions)
4. Auto-suggestions section header
5. Each suggestion card (description → source → confidence → actions)
6. Entries needing edits section header
7. Each edit-needed card

---

## 15. Implementation Priority

### Phase 1: Identity Foundation (Required for all other phases)

1. **Persist `currentUserId` to local storage** in `SettingsProvider.init()`
2. **Add `personalizedStatusLabel()` helper** function
3. **Add `netBalanceStatement()` helper** function
4. **Create `ParticipantAvatar` widget** with size variants and ownership ring
5. **Create `OwnershipEntryCard` widget** replacing current `EntryCard`
6. **Update `NavigationShell` app bar** with identity + partner name

### Phase 2: Asymmetric Views

7. **Redesign `ReviewScreen` with three sections** (partner entries, auto-suggestions, your edits)
8. **Filter review queue** by `currentUserId` — only show entries needing YOUR action
9. **Update `BalanceScreen`** with personalized names and net balance statement
10. **Update `WeekSummaryCard`** with split you/partner stats

### Phase 3: Onboarding & Pairing

11. **Create `OnboardingFlow` widget** (name entry → create/join choice)
12. **Create `PairingScreen`** (invite code generation + QR)
13. **Create `JoinLedgerScreen`** (code entry + QR scan)
14. **Add ledger `awaitingPair` status** to domain model
15. **Pre-pairing empty state** on Ledger tab

### Phase 4: Auto-Recording UX

16. **Create `SuggestionBanner` widget** for Ledger tab
17. **Create `SuggestionCard` widget** with confidence indicator + source hint
18. **Add auto-suggestions section** to Review screen
19. **Create confidence indicator widget** (dots + label)
20. **Add "Don't suggest this type" flow** in Settings

### Phase 5: Polish & Empty States

21. **Implement all 7 empty states** from catalog (Section 11)
22. **Add swipe-to-review flow** for batch partner entry review
23. **Update settlement cards** with perspective-aware labels
24. **Add participant color legend** to Timeline tab
25. **Implement split contribution bar** in Timeline week view

---

## Appendix A: Data Flow — Who Sees What

```
Marcus's Device                     Sarah's Device
═══════════════                     ═══════════════

LEDGER TAB                          LEDGER TAB
├─ Marcus's entries (primary)       ├─ Sarah's entries (primary)
├─ Sarah's entries (tertiary)       ├─ Marcus's entries (tertiary)
└─ Status: from Marcus's view       └─ Status: from Sarah's view

REVIEW TAB                          REVIEW TAB
├─ Sarah's entries to approve       ├─ Marcus's entries to approve
│  (pendingCounterpartyReview)      │  (pendingCounterpartyReview)
├─ Marcus's auto-suggestions        ├─ Sarah's auto-suggestions
│  (needsReview, auto source)       │  (needsReview, auto source)
└─ Marcus's entries needing edit    └─ Sarah's entries needing edit
   (needsEdit, authored by Marcus)     (needsEdit, authored by Sarah)

BALANCE TAB                         BALANCE TAB
├─ "You: 42.0 cr"                  ├─ "You: 36.0 cr"
├─ "Sarah: 36.0 cr"               ├─ "Marcus: 42.0 cr"
└─ "Sarah owes you 6.0"           └─ "You owe Marcus 6.0"

TIMELINE TAB                        TIMELINE TAB
├─ Same data, same view             ├─ Same data, same view
├─ Your entries = primary color     ├─ Your entries = primary color
└─ Partner entries = tertiary       └─ Partner entries = tertiary
```

## Appendix B: Status Label Quick Reference

```
                        On Author's Device        On Reviewer's Device
────────────────────────────────────────────────────────────────────────
needsReview             "Needs your review"       "Needs your review"
pendingCounterpartyReview "Waiting for [Partner]" "Waiting for your review"
confirmed               "Confirmed ✓"             "Confirmed ✓"
needsEdit               "[Partner] requested       "You requested changes"
                         changes"
rejected                "Rejected by [Partner]"    "You rejected this"
```

## Appendix C: File Change Map

Files that need modification for this design:

```
MODIFY  lib/app/navigation_shell.dart        — Identity app bar, badge logic
MODIFY  lib/app/theme.dart                    — ParticipantColors extension
MODIFY  lib/features/settings/presentation/
          settings_provider.dart              — Persist currentUserId, init from storage
MODIFY  lib/features/settings/presentation/
          settings_screen.dart               — Redesigned identity section
MODIFY  lib/features/ledger/presentation/
          widgets/entry_card.dart            — Replace with OwnershipEntryCard
MODIFY  lib/features/ledger/presentation/
          widgets/week_summary_card.dart     — Split you/partner stats
MODIFY  lib/features/ledger/presentation/
          ledger_screen.dart                 — Suggestion banner, empty states
MODIFY  lib/features/reviews/presentation/
          review_screen.dart                 — Three-section queue, filter logic
MODIFY  lib/features/reviews/presentation/
          widgets/review_entry_card.dart     — Personalized status, ownership
MODIFY  lib/features/balance/presentation/
          balance_screen.dart                — Personalized names, net statement
MODIFY  lib/features/timeline/presentation/
          timeline_screen.dart               — Color-coded dots, legend, split bar

CREATE  lib/app/widgets/participant_avatar.dart   — Reusable avatar component
CREATE  lib/app/widgets/sync_status_indicator.dart — Sync state widget
CREATE  lib/app/widgets/ownership_entry_card.dart  — Unified entry card
CREATE  lib/app/helpers/personalized_labels.dart   — Status/balance label helpers
CREATE  lib/features/onboarding/                   — Onboarding flow screens
CREATE  lib/features/pairing/                      — Pairing/invite screens
CREATE  lib/features/ledger/presentation/
          widgets/suggestion_banner.dart           — Auto-suggestion banner
CREATE  lib/features/ledger/presentation/
          widgets/suggestion_card.dart             — Individual suggestion card
CREATE  lib/features/ledger/presentation/
          widgets/confidence_indicator.dart         — Dots + label widget
```
