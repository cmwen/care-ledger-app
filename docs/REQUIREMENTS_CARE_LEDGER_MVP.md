# Care Ledger MVP Requirements

## 1. Scope

This MVP focuses on recording caregiving efforts, converting them to credits, and managing simple settlement proposals between two parties.

### In Scope
- Create and manage a shared ledger between two participants
- Auto-capture candidate caregiving entries from device signals and user activity context
- Log caregiving entries with date, category, notes, and optional attachments
- Assign or propose credit value per entry
- Confirm, dispute, or edit entries
- Show credit balance over time
- Provide visual timeline and weekly summary views of completed work
- Propose and mark settlement actions
- Sync ledger state directly between participants without requiring a central app server

### Out of Scope
- Automatic legal enforcement
- Third-party payment integration
- Multi-family networks
- AI-based scoring of effort fairness

## 1.1 Architecture Constraint

- The product must be **local-first and serverless by default** for core ledger operations.
- Multi-user sync can use peer-to-peer, local network, relay-by-consent, or manual encrypted share/export models.
- A hosted backend is optional for future enhancements, but not required for MVP core use.

## 2. User Roles

1. **Participant A**: Parent/child/family member contributing effort.
2. **Participant B**: Counterparty who reviews entries and settles balances.

Both roles have the same permissions in MVP.

## 3. Core Jobs To Be Done

- “When I do care work, I want it captured automatically so I only need to review it later.”
- “When I review partner activity, I want transparent details before confirming credit.”
- “When I open the app weekly, I want a visual summary of what happened so I can approve quickly.”
- “When a balance grows, I want clear settlement options so we can close it fairly.”

## 4. Functional Requirements

## 4.1 Ledger Setup
- Users can create a shared ledger with a name (example: “Kids School & Home Care”).
- Users can invite one counterparty to the ledger.
- Ledger status can be active or archived.

## 4.2 Care Entry Logging
Each entry must include:
- Date/time
- Category (drive, pickup, laundry, holiday activity, childcare, other)
- Short description
- Proposed credit value

Optional fields:
- Duration (minutes/hours)
- Attachment/photo proof
- Private note (visible only to author)

### Auto-Capture Requirements
- System can create **suggested entries** automatically (for example: repeated school-route drives, calendar-linked child activities, location/time pattern matches).
- Suggested entries are marked as **Needs Review** until user confirmation.
- Users can batch-approve, edit, or discard suggested entries.
- System must show why an entry was suggested (for transparency).

## 4.3 Weekly Review Workflow
- Users receive a weekly review prompt summarizing suggested and pending entries.
- Weekly review supports one-screen triage: approve, edit, reject.
- Review completion should take less than 10 minutes for typical weekly volume.

## 4.4 Entry Review Workflow
- Counterparty can mark entry as **Confirmed**, **Needs Edit**, or **Rejected**.
- If **Needs Edit**, counterparty provides a reason.
- Entry history (who changed what and when) is preserved.

## 4.5 Credit Balance
- System calculates net balance per ledger.
- Users can view:
  - total contributed credits by each party
  - pending (unconfirmed) credits
  - confirmed net balance

## 4.6 Visual Views
- Timeline view of care activities by day/week with category indicators.
- Weekly summary card showing total credits, pending confirmations, and disputes.
- Comparison view showing both parties’ confirmed contributions over selected period.

## 4.7 Settlement
- Either party can create a settlement proposal with:
  - method (cash, reciprocal task, item/gift, other)
  - value/credit amount
  - due date (optional)
- Counterparty can accept, decline, or request change.
- Settlements can be marked complete and linked to balance reduction.

## 4.8 Notifications (Basic)
- Notify users when:
  - a new entry is added
  - an entry is disputed
  - a settlement is proposed or updated
  - weekly review is ready

## 4.9 Multi-User Sync (Serverless)
- Two participants can exchange encrypted ledger updates directly.
- Conflict resolution uses deterministic merge rules and per-entry version history.
- Offline changes are queued and synced when peer connection is available.

## 5. Non-Functional Requirements

- **Usability**: Add a new entry in less than 20 seconds for common categories.
- **Review Efficiency**: Complete weekly review in less than 10 minutes for normal usage.
- **Reliability**: Entry and settlement actions must be durable after app restart.
- **Privacy**: Ledger data is accessible only by invited participants.
- **Auditability**: Store timestamped change history for entries and settlements.
- **Transparency**: Auto-captured entries must expose capture reason/source label.

## 6. MVP Data Model (Conceptual)

- **User**: id, displayName
- **Ledger**: id, title, participantIds, status
- **CareEntry**: id, ledgerId, authorId, category, description, date, creditsProposed, status, sourceType(manual|auto), sourceHint
- **EntryReview**: id, entryId, reviewerId, decision, reason, timestamp
- **Settlement**: id, ledgerId, proposerId, method, credits, status, dueDate, completedAt
- **SyncEvent**: id, ledgerId, actorId, eventType, vectorClock/version, createdAt

## 7. Acceptance Criteria (MVP)

1. Two users can share one ledger and both can add entries.
2. System creates suggested entries automatically and users can batch-review them weekly.
3. Each entry can be reviewed and transitioned through statuses.
4. Confirmed entries affect ledger balance; pending/rejected do not.
5. Settlement proposals can be accepted and completed.
6. Activity history is visible for all ledger actions.
7. Data can sync between two users without requiring a central backend server.

## 8. Risks and Mitigations

- **Disagreement on value**: Use “proposed + confirmed” two-step model.
- **Overhead of logging**: Offer category presets and defaults.
- **Automation false positives**: Keep all auto-captured items in Needs Review until approved.
- **Peer sync complexity**: Start with two-party sync and deterministic merge rules.
- **Trust concerns**: Include transparent history and status transitions.
