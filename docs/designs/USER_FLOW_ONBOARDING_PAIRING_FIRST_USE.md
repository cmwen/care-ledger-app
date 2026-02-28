# User Flow: Onboarding, Pairing & First-Use Experience

## Overview

This document maps the complete journey from app install to first weekly review,
covering both the "Creator" path (first person to set up) and the "Joiner" path
(partner who receives an invite).

---

## Flow 1: Creator Path (Marcus)

```
┌─────────────┐    ┌─────────────┐    ┌─────────────┐    ┌─────────────┐
│  App Install │ →  │  Identity   │ →  │  Create     │ →  │  Invite     │
│  + First     │    │  Setup      │    │  Ledger     │    │  Partner    │
│  Launch      │    │             │    │             │    │             │
└─────────────┘    └─────────────┘    └─────────────┘    └─────────────┘
                                                                │
       ┌────────────────────────────────────────────────────────┘
       ▼
┌─────────────┐    ┌─────────────┐    ┌─────────────┐
│  Waiting     │ →  │  Partner    │ →  │  Normal Use │
│  for Partner │    │  Connected  │    │  (Ledger)   │
│  (can add    │    │  Toast      │    │             │
│  entries)    │    │             │    │             │
└─────────────┘    └─────────────┘    └─────────────┘
```

### Step 1: First Launch

**Screen**: Splash → Welcome
**Trigger**: App opened for the first time (no `currentUserId` in local storage)
**Duration**: < 5 seconds

```
┌──────────────────────────────────────┐
│                                      │
│         [App Icon Animation]         │
│                                      │
│          Care Ledger                 │
│   Make care work visible and fair.   │
│                                      │
│        [Get Started →]               │
│                                      │
└──────────────────────────────────────┘
```

### Step 2: Identity Setup

**Screen**: Name entry
**Required input**: Display name (1+ characters)
**Optional input**: Avatar color preference
**Persistence**: Generates UUID, stores to local storage
**Validation**: Name must not be empty; trimmed and title-cased

```
User enters: "Marcus"
→ System generates: { id: "usr_a1b2c3...", name: "Marcus" }
→ Stored in SharedPreferences: currentUserId, currentUserName
→ SettingsProvider.init() reads this on every future launch
```

**Accessibility notes**:
- Auto-focus on name text field
- "Continue" button disabled until name entered
- Screen reader: "Welcome screen. Enter your name to get started."

### Step 3: Create or Join

**Screen**: Choice screen
**Two options**: "Create a New Ledger" / "Join an Existing Ledger"
**Layout**: Two large tappable cards, vertically stacked

**Decision logic**:
- Creator: The first person to set up. They define the ledger name and partner placeholder.
- Joiner: The second person. They have an invite code from the creator.

### Step 4: Create Ledger

**Screen**: Ledger creation form
**Required inputs**:
  - Ledger title (e.g., "Kids School & Home Care")
  - Partner's first name (e.g., "Sarah")
**Defaults**:
  - Ledger status: `awaitingPair`
  - participantAId: currentUserId (Marcus)
  - participantBId: placeholder generated ID

**What happens**:
```
1. LedgerService.createLedger() called
2. Ledger stored locally with status = awaitingPair
3. Pairing invite code generated (deterministic from ledger ID + device key)
4. Navigate to Invite Screen
```

### Step 5: Invite Partner

**Screen**: Invite display
**Shows**:
  - QR code encoding invite payload
  - 12-character alphanumeric code (human-readable)
  - Share button (system share sheet)
  - Copy button
**Status indicator**: "Waiting for Sarah to connect..."

**Invite payload** (encrypted):
```json
{
  "ledgerId": "ldg_...",
  "creatorName": "Marcus",
  "ledgerTitle": "Kids School & Home Care",
  "partnerPlaceholderName": "Sarah",
  "publicKey": "...",
  "timestamp": "2024-..."
}
```

### Step 6: Waiting State

**Screen**: Main Ledger tab with pre-pairing empty state
**Behavior**:
  - User can add entries immediately (they work locally)
  - Periodic check for partner connection
  - Banner at top: "Waiting for Sarah to join. [Show Invite →]"
  - Full app is usable in single-user mode

### Step 7: Partner Connected

**Trigger**: Sync handshake completes
**UI**: Toast notification: "Sarah has connected! Your ledger is now shared."
**Effect**: Ledger status transitions from `awaitingPair` to `active`

---

## Flow 2: Joiner Path (Sarah)

```
┌─────────────┐    ┌─────────────┐    ┌─────────────┐    ┌─────────────┐
│  App Install │ →  │  Identity   │ →  │  Join       │ →  │  Confirm    │
│  + First     │    │  Setup      │    │  Ledger     │    │  Connection │
│  Launch      │    │             │    │  (enter     │    │  + Name     │
│              │    │             │    │   code)     │    │             │
└─────────────┘    └─────────────┘    └─────────────┘    └─────────────┘
                                                                │
       ┌────────────────────────────────────────────────────────┘
       ▼
┌─────────────┐    ┌─────────────┐
│  Receive     │ →  │  Normal Use │
│  Existing    │    │  (Ledger)   │
│  Entries     │    │             │
└─────────────┘    └─────────────┘
```

### Step 1–2: Same as Creator

Identity setup is identical. Sarah enters her name.

### Step 3: Join Ledger

**Screen**: Code entry / QR scan
**Input methods**:
  1. Type 12-character code (auto-formatted with dashes)
  2. Scan QR code (camera permission required)
**Validation**: Code must match a valid invite; error message if expired or invalid

### Step 4: Confirm Connection

**Screen**: Confirmation with editable name
**Shows**:
  - Ledger title from creator
  - Creator's name
  - Pre-filled partner name (what creator entered)
  - Editable text field to change name
**Action**: "Start Using Ledger" button

**What happens**:
```
1. Decrypt invite payload
2. Store ledgerId and set currentUser as participantB
3. If creator entered "Sarah" but joiner is actually "Sara", they can fix it
4. Initiate sync handshake with creator's device
5. Receive any entries creator already added
6. Navigate to main Ledger tab
```

### Step 5: Receive Existing Data

**Screen**: Main Ledger tab
**Behavior**:
  - If Marcus already added entries, they appear immediately
  - Entries from Marcus show as "Marcus's entries" with tertiary color
  - Any entries in `pendingCounterpartyReview` appear in Sarah's Review tab
  - Toast: "Connected with Marcus! You can now review and add entries."

---

## Flow 3: First Weekly Review (Either Participant)

```
┌─────────────┐    ┌─────────────┐    ┌─────────────┐    ┌─────────────┐
│  Notification│ →  │  Review     │ →  │  Review     │ →  │  Review     │
│  "Weekly     │    │  Summary    │    │  Partner's  │    │  Auto-      │
│   review     │    │  Banner     │    │  Entries    │    │  Suggestions│
│   ready"     │    │             │    │             │    │             │
└─────────────┘    └─────────────┘    └─────────────┘    └─────────────┘
                                                                │
       ┌────────────────────────────────────────────────────────┘
       ▼
┌─────────────┐    ┌─────────────┐
│  Handle Own  │ →  │  Review     │
│  Entries     │    │  Complete   │
│  Needing     │    │  Summary    │
│  Edits       │    │             │
└─────────────┘    └─────────────┘
```

### Entry Point

**Trigger**: Push notification on Sunday evening (configurable) or manual visit to Review tab
**Notification text**: "Your weekly review is ready. 5 entries from Sarah + 2 auto-suggestions."

### Review Summary Banner

```
┌──────────────────────────────────────┐
│  📋 Weekly Review                    │
│                                      │
│  This week you need to:             │
│  • Review 5 entries from Sarah       │
│  • Confirm 2 auto-detected entries   │
│  • Fix 1 entry Sarah flagged         │
│                                      │
│  Estimated time: ~4 minutes          │
│                                      │
│  [Start Review →]                    │
└──────────────────────────────────────┘
```

### Step 1: Partner's Entries

**Mode options**:
  a. "Review All" — swipe card stack (fastest)
  b. "Review One by One" — scrollable list with inline actions

**For each entry**:
  - See description, category, credits, source hint
  - Approve (single tap or swipe right)
  - Request edit (dialog with reason)
  - Reject (dialog with reason)

### Step 2: Auto-Suggestions

**For each suggestion**:
  - See detected activity, time, source reason, confidence
  - Confirm (becomes your entry, moves to `pendingCounterpartyReview`)
  - Edit first (modify details, then confirm)
  - Dismiss (deleted, pattern noted for future learning)

### Step 3: Own Entries Needing Edits

**For each flagged entry**:
  - See partner's edit reason
  - Open edit sheet (pre-filled with current values)
  - Edit and resubmit → moves back to `pendingCounterpartyReview`

### Review Complete

```
┌──────────────────────────────────────┐
│  ✅ Review Complete!                  │
│                                      │
│  You reviewed 8 items:              │
│  • Approved 4 of Sarah's entries     │
│  • Requested edits on 1              │
│  • Confirmed 2 auto-suggestions      │
│  • Updated 1 of your flagged entries │
│                                      │
│  Sarah will be notified about the    │
│  entries that need her attention.     │
│                                      │
│  [Done →]                            │
└──────────────────────────────────────┘
```

---

## Flow 4: Entry Lifecycle (Full Asymmetric Path)

```
Marcus's Device                    Sarah's Device
═══════════════                    ═══════════════

1. Marcus adds entry
   Status: needsReview
   Label: "Needs your review"
   (Marcus reviews his own
    auto-suggestion or manual
    entry before submitting)

2. Marcus confirms entry              ──sync──►
   Status: pendingCounterpartyReview
   Label: "Waiting for Sarah"          Label: "Waiting for your review"
                                       Appears in Sarah's Review tab

                                    3. Sarah reviews entry
                                       ┌─ Approve → confirmed
                                       ├─ Request edit → needsEdit
                                       └─ Reject → rejected

   ◄──sync──                        4a. If confirmed:
   Label: "Confirmed ✓"                Label: "Confirmed ✓"
                                       Entry affects balance

   ◄──sync──                        4b. If needsEdit:
   Label: "Sarah requested changes"    Label: "You requested changes"
   Appears in Marcus's Review tab      Status shown in Sarah's Ledger
   (section 3: entries needing edits)

5. Marcus edits and resubmits       ──sync──►
   Status: pendingCounterpartyReview
   Label: "Waiting for Sarah"          Back in Sarah's Review tab

                                    6. Sarah reviews again
                                       (approve or reject)
```

---

## Flow 5: Settlement Negotiation (Asymmetric)

```
Marcus's Device                    Sarah's Device
═══════════════                    ═══════════════

1. Marcus views Balance tab
   "Sarah owes you 6.0 credits"

2. Marcus taps "Propose Settlement"
   Fills in: 6.0 cr, Cash method
   Taps "Propose to Sarah"

   Settlement card shows:            ──sync──►
   "You proposed 6.0 cr via Cash"    "Marcus proposed 6.0 cr via Cash"
   "Waiting for Sarah"               "Needs your response"
                                     [Decline] [Request Change] [Accept]

                                    3. Sarah taps "Accept"
   ◄──sync──
   "Accepted by Sarah"              "You accepted"
   [Mark as Completed]              [Mark as Completed]

4. Either party marks completed:
   Balance reduced by 6.0 cr
   Settlement card: "Completed ✓"
```

---

## Error States & Edge Cases

### Invite Code Invalid

```
┌──────────────────────────────────────┐
│  ❌ Invalid invite code              │
│                                      │
│  The code you entered doesn't match  │
│  any active ledger invite.           │
│                                      │
│  Check with your care partner for    │
│  the correct code, or ask them to    │
│  generate a new one.                 │
│                                      │
│  [Try Again]                         │
└──────────────────────────────────────┘
```

### Partner Offline During Pairing

```
┌──────────────────────────────────────┐
│  ⏳ Connecting...                     │
│                                      │
│  We're trying to reach Marcus's      │
│  device. This might take a moment    │
│  if they're offline.                 │
│                                      │
│  The connection will complete        │
│  automatically when both devices     │
│  are online.                         │
│                                      │
│  [Continue to Ledger →]              │
│  (You can start using the app now)   │
└──────────────────────────────────────┘
```

### Sync Conflict During Review

```
┌──────────────────────────────────────┐
│  ⚠️ Sync Conflict                    │
│                                      │
│  Sarah also reviewed this entry      │
│  while you were reviewing it.        │
│                                      │
│  Sarah's action:  Approved ✓         │
│  Your action:     Requested Edit     │
│                                      │
│  [Keep Sarah's Decision]             │
│  [Keep Your Decision]                │
│  [View Entry Details →]              │
└──────────────────────────────────────┘
```

### Network Unavailable During Settlement

```
┌──────────────────────────────────────┐
│  📵 Saved Locally                    │
│                                      │
│  Your settlement proposal has been   │
│  saved and will be sent to Sarah     │
│  when you're back online.            │
│                                      │
│  [OK]                                │
└──────────────────────────────────────┘
```
