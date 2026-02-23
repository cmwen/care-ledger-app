# Care Ledger MVP Technical Design Handoff

## Document Purpose

This document is the implementation handoff for developers building the Care Ledger MVP.
It consolidates product constraints, architecture decisions, UX specifications, and delivery milestones into one execution guide.

Primary source alignment:
- `docs/REQUIREMENTS_CARE_LEDGER_MVP.md`
- `docs/designs/CARE_LEDGER_DESIGN_PACK.md`

## 1. Scope and Constraints

### 1.1 MVP Scope
- Two-party shared ledger (equal permissions)
- Care entry capture (manual + auto-suggested)
- Weekly review workflow with triage and batch actions
- Entry confirmation/dispute loop with history
- Balance calculation (pending vs confirmed)
- Settlement proposal lifecycle
- Serverless/local-first sync between two participants

### 1.2 Non-Negotiable Constraints
- Local-first and durable offline behavior
- No required central backend for core ledger workflows
- Auto-captured entries are never auto-confirmed
- Full auditability of status and value changes
- Privacy by default for family data

### 1.3 UX Performance Targets
- Common manual entry flow under 20 seconds
- Weekly review completion under 10 minutes for typical volume

## 2. System Architecture

### 2.1 Architecture Style
Local-first Clean Architecture with append-only event log and deterministic merge reducer.

Layer responsibilities:
- Presentation: screens/widgets/view-models
- Application: use cases and transaction boundaries
- Domain: entities, invariants, transition rules
- Infrastructure: SQLite, crypto/key storage, sync transports

### 2.2 Proposed Project Structure
```
lib/
  app/
  core/
    clock/
    ids/
    result/
    crypto/
    logging/
  features/
    ledger/
      domain/
      application/
      infrastructure/
      presentation/
    care_entries/
      domain/
      application/
      infrastructure/
      presentation/
    reviews/
      domain/
      application/
      infrastructure/
      presentation/
    balance/
      domain/
      application/
      infrastructure/
      presentation/
    settlements/
      domain/
      application/
      infrastructure/
      presentation/
  sync/
    domain/
    application/
    infrastructure/
  data/
    db/
    migrations/
```

## 3. Domain Model and Rules

### 3.1 Core Models
- `Ledger`
  - id, title, participantAId, participantBId, status, createdAt, archivedAt
- `CareEntry`
  - id, ledgerId, authorId, occurredAt, category, description, durationMin, creditsProposed, creditsConfirmed, sourceType, sourceHint, status, revision, baseRevision
- `EntryReview`
  - id, entryId, reviewerId, decision, reason, entryRevisionReviewed, createdAt
- `Settlement`
  - id, ledgerId, proposerId, method, credits, status, dueDate, completedAt, revision
- `SyncEvent`
  - eventId, ledgerId, actorId, deviceId, entityType, entityId, opType, payload, lamport, vector, prevHash, hash, createdAt

### 3.2 Invariants and Transition Rules
- Ledger has exactly two distinct participants.
- Archived ledgers are read-only.
- `creditsProposed >= 0`; settlement credits are strictly positive.
- Reviewer cannot be the entry author for confirm/reject decisions.
- Only confirmed entries affect confirmed balance.
- `needs_edit` requires reviewer reason.
- Accepted settlement can be completed once; completion reduces outstanding balance exactly once.

### 3.3 Entry Status Machine
- `needs_review -> pending_counterparty_review` (author approves)
- `needs_review -> rejected`
- `pending_counterparty_review -> confirmed | needs_edit | rejected`
- `needs_edit -> pending_counterparty_review` (author resubmits)

Optional reopen policy:
- `confirmed -> needs_edit` within bounded window (default 7 days) with required reason.

## 4. Service Contracts

### 4.1 Interfaces
- `LedgerService`
  - createLedger, archiveLedger, watchLedger
- `CareEntryService`
  - proposeEntry, editEntry, deleteDraft, watchWeeklyReviewQueue
- `ReviewService`
  - reviewEntry, watchEntryReviews
- `BalanceService`
  - watchBalance, recompute
- `SettlementService`
  - proposeSettlement, respondSettlement, completeSettlement
- `SyncService`
  - exportSince, importBundle, syncWithPeer

### 4.2 Write Path Rule
All write operations must append a `SyncEvent` and update projections in the same local transaction.

## 5. Sync and Conflict Resolution

### 5.1 Deterministic Merge Algorithm
1. Validate event authenticity (hash/signature/membership/monotonic sequence)
2. Deduplicate by eventId
3. Canonical ordering:
   - lamport ascending
   - actorId lexical ascending
   - sequence ascending
4. Apply domain reducer with role and state validation
5. Rebuild projections from canonical log

### 5.2 Conflict Handling
- Stale base revision triggers conflict flag and `needs_edit` workflow.
- Concurrent settlement responses on same revision:
  - causally later wins;
  - true concurrency falls back to `change_requested` with full audit trail.
- Balance is never merged directly; it is recomputed from events.

## 6. UX Specification for Implementation

### 6.1 Navigation
Bottom tabs:
1. Ledger
2. Review
3. Timeline
4. Balance
5. Settings

Global behavior:
- Top bar with ledger title, participants, sync indicator
- Add Entry action accessible from Ledger and Review
- Review and Balance badge counts for pending user actions

### 6.2 Screen Specs (Build Order)
1. Ledger Home
   - Week summary, pending counts, recent activity, quick add
2. Quick Add Entry (bottom sheet)
   - category chips, description, datetime, credits, optional extras
3. Weekly Review Queue
   - grouped entries, filters, bulk actions, inline edits
4. Entry Detail + Decision
   - capture reason, metadata, history, confirm/needs-edit/reject actions
5. Timeline
   - day/week, participant filter, read-first history
6. Balance + Settlements
   - totals, net balance, proposal lifecycle
7. Settings (MVP-minimal)
   - participants, sync health, notifications

### 6.3 UX Behavior Rules
- Every suggested entry must expose source type + human-readable reason.
- Action visibility must mirror allowed status transitions.
- Bulk reject requires reason template or custom reason.
- Queue must preserve scroll position after detail/edit return.
- Invalid transitions are blocked with explicit user feedback.

### 6.4 Accessibility and Quality Rules
- 48x48dp minimum interactive targets
- Text scale support up to 200%
- Status semantics not color-only (icon + label)
- Screen-reader announcements for entry status and required action

## 7. Data, Security, and Privacy

### 7.1 Storage
- Local database with migrations and durable transactions
- Attachments encrypted at rest
- Event log immutable for audit

### 7.2 Cryptography and Keys
- Device master key in Android Keystore
- Per-ledger symmetric key
- Sync payload encryption and signature verification

### 7.3 Privacy Policy in MVP
- Private notes are author-local by default
- Only ledger participants can decrypt synced ledger data

## 8. Testing and Acceptance

### 8.1 Technical Test Matrix
- Unit tests: entities, transitions, balance math, reducers
- Repository tests: migrations, transaction integrity
- Sync tests: deterministic convergence with concurrent updates
- Widget tests: review queue, status actions, settlement actions

### 8.2 UX Acceptance Checklist
- Median manual add flow under 20 seconds (5-trial check)
- Weekly review of 30 mixed items under 10 minutes
- Suggested entries always show source and reason before decision
- Confirmed-only entries affect confirmed balance
- Dispute flow preserves revision history
- Settlement completion updates balance once

## 9. Delivery Plan

### Milestone Sequence
1. Foundation
   - modules, entities, service interfaces, DB schema
2. Core Entry Flow
   - ledger + manual/suggested entries + queue projection
3. Review + Balance
   - transitions, history, balance projector
4. Settlement
   - proposal lifecycle + completion effect
5. Sync Engine
   - export/import + deterministic reducer + conflict flags
6. Hardening
   - crypto, replay checks, perf and accessibility verification

## 10. Definition of Done (Handoff)

The MVP implementation is handoff-complete when:
1. Architecture and module boundaries follow this document.
2. All status transitions and invariants are enforced in domain/application layers.
3. UX rules and accessibility constraints are verified in widget/integration tests.
4. Two devices converge to identical state after offline concurrent edits.
5. End-to-end flow works: add -> review -> confirm/dispute -> settle -> sync.
