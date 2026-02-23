# Care Ledger Design Pack (Orchestrated)

This document consolidates outputs from four roles:
- Product Owner
- Experience Designer
- Researcher
- Architect

## 1) Product Owner Output

### 1.1 Product Goal
Help two family participants track, review, and settle caregiving effort with low friction and high trust.

### 1.2 MVP Scope (Locked)
- One shared ledger between two participants
- Suggested care entries + weekly review queue
- Entry confirmation/dispute flow
- Credit balance and basic settlement flow
- Local-first storage with serverless sync path

### 1.3 Prioritized Feature Backlog
P0 (must ship):
1. Ledger setup and invitation handshake
2. Care entry model (manual + suggested)
3. Weekly review inbox (approve/edit/reject)
4. Entry status workflow (Pending, Confirmed, Needs Edit, Rejected)
5. Balance summary (confirmed vs pending)
6. Settlement proposal lifecycle
7. Device-to-device sync event log

P1 (after MVP stabilization):
1. Recurring templates
2. Better timeline analytics
3. Export (CSV/PDF)

### 1.4 Acceptance Gate for MVP
- Two users complete one full weekly cycle end-to-end.
- Review completion median under 10 minutes for pilot data volume.
- No data loss across app restarts and offline transitions.
- Dispute flow and settlement completion update balance correctly.

## 2) Experience Designer Output

### 2.1 Information Architecture
Primary navigation (bottom tabs):
1. Ledger
2. Review
3. Timeline
4. Balance
5. Settings

### 2.2 Core Screens
1. **Ledger Home**
   - Current week summary card
   - Pending review count
   - Quick add entry action
2. **Weekly Review Queue**
   - Group by day/category
   - Bulk actions: Approve, Reject
   - Inline edit entry
3. **Entry Detail + Decision**
   - Source hint (why suggested)
   - Proposed credits, notes, attachments
   - Decision controls with reason for disputes
4. **Balance & Settlement**
   - Confirmed contribution totals by participant
   - Net balance and pending credits
   - Settlement proposal CTA
5. **Timeline**
   - Day/week toggle
   - Status and category markers

### 2.3 UX Rules
- Common add-entry flow must fit within 20 seconds.
- Weekly review supports bulk decisions first, details second.
- Every auto-suggested entry shows transparent source hint.
- Color/status semantics remain consistent across all screens.

### 2.4 Empty and Edge States
- No suggestions: show “Nothing to review this week” with add-entry CTA.
- Conflict detected from sync: show comparison and “keep both / choose latest” action.
- Rejected entry: preserve history and surface follow-up edit shortcut.

## 3) Researcher Output

### 3.1 State Management Recommendation
- Use Flutter built-in patterns for MVP simplicity: `ChangeNotifier` + repository layer.
- Keep state features separated by domain:
  - ledger_state
  - review_state
  - balance_state
  - sync_state

Reasoning: lowest complexity for MVP, fast onboarding, easy future migration to Riverpod/Bloc if needed.

### 3.2 Local Data and Sync Recommendation
- Primary local store: lightweight SQLite-backed persistence (through existing Flutter-friendly approach), with append-only sync events.
- Event model: immutable `SyncEvent` entries per mutation.
- Deterministic merge: timestamp + actor + event sequence ordering.

### 3.3 Auto-Capture Suggestion Pipeline
Candidate sources for MVP-safe suggestions:
1. Repeated time/location pattern labels (privacy-safe abstraction)
2. User-confirmed templates from prior accepted entries
3. Calendar-linked hints (optional permission)

Safety policy:
- Never auto-confirm; always `Needs Review`.
- Always include a human-readable capture reason.

### 3.4 Risks and Mitigations
- False positives in suggestions → confidence labels + one-tap reject.
- Trust erosion from opaque scoring → no hidden scoring in MVP.
- Sync ambiguity → explicit history and conflict review UI.

## 4) Architect Output

### 4.1 Target Layering
`presentation -> application -> domain -> data`

### 4.2 Proposed MVP Folder Structure
```
lib/
  features/
    ledger/
    review/
    timeline/
    balance/
    settlement/
    sync/
  core/
    storage/
    network/
    models/
```

### 4.3 Domain Models (MVP)
- `Ledger`: id, title, participantIds, status
- `CareEntry`: id, ledgerId, authorId, category, description, datetime, creditsProposed, sourceType, sourceHint, status
- `EntryReview`: id, entryId, reviewerId, decision, reason, timestamp
- `Settlement`: id, ledgerId, proposerId, method, credits, status, dueDate, completedAt
- `SyncEvent`: id, ledgerId, actorId, eventType, payload, version, createdAt

### 4.4 Service Contracts
- `LedgerRepository`: create/open/archive ledger, list entries
- `ReviewService`: batch approve/reject/edit, transition validation
- `BalanceService`: calculate pending and confirmed balances
- `SettlementService`: propose/respond/complete
- `SyncService`: export/import/apply events + conflict resolution

### 4.5 Milestone Plan
1. **M1 (Foundation)**: models, repositories, seeded local data
2. **M2 (Core UX)**: review workflow + statuses + history
3. **M3 (Balance/Settlement)**: complete settlement lifecycle
4. **M4 (Serverless Sync)**: event exchange and deterministic merge
5. **M5 (Pilot Readiness)**: hardening, telemetry, onboarding polish

## 5) Final Design Decisions (Approved)

1. Two-party ledger only for MVP.
2. Credits are proposed then confirmed (no automatic fairness scoring).
3. Weekly review is the primary interaction pattern.
4. Local-first event sourcing powers offline-first sync.
5. Timeline and balance remain read-optimized; editing happens in review/detail flows.
