# Care Ledger User Stories

## Epic 1: Shared Ledger Setup

### Story 1.1
As a participant, I want to create a shared ledger so both parties track care efforts in one place.

**Acceptance Criteria**
- User can create a ledger with title.
- User can invite one counterparty.
- Both users can access the same ledger after invite acceptance.

### Story 1.2
As a participant, I want to archive a ledger when no longer needed so old records remain accessible but inactive.

**Acceptance Criteria**
- Archived ledgers are read-only.
- Archived ledgers remain viewable in history.

## Epic 2: Care Work Logging

### Story 2.1
As a caregiver, I want care tasks auto-detected so effort is captured without constant manual input.

**Acceptance Criteria**
- System creates suggested entries from activity patterns and context.
- Suggested entries are clearly labeled and editable.
- User can still add manual entries when needed.

### Story 2.2
As a caregiver, I want to edit my pending entry so I can correct mistakes.

**Acceptance Criteria**
- Author can edit while entry is pending review.
- Edits are versioned in history.

### Story 2.3
As a participant, I want to review all suggested entries weekly so I can approve quickly without daily admin work.

**Acceptance Criteria**
- Weekly review queue groups all unreviewed suggested entries.
- User can batch-approve, batch-reject, or edit entries.
- Weekly review shows estimated time remaining.

## Epic 3: Review and Confirmation

### Story 3.1
As a counterparty, I want to confirm or dispute an entry so credits are fair.

**Acceptance Criteria**
- Counterparty can confirm, request edit, or reject.
- Request edit and reject require optional reason.
- Decision appears in activity history.

### Story 3.2
As both participants, I want transparent status labels so I know what counts toward balance.

**Acceptance Criteria**
- Entry statuses are visible: Pending, Confirmed, Needs Edit, Rejected.
- Only confirmed entries affect final balance.

## Epic 4: Balance and Settlement

### Story 4.1
As a participant, I want to see current credit balance so we know who is owed.

**Acceptance Criteria**
- Summary shows each party’s confirmed totals.
- Summary shows net balance and pending credits.

### Story 4.1b
As a participant, I want a visual timeline/dashboard so effort is visible and easier to appreciate.

**Acceptance Criteria**
- Timeline displays completed work by day/week.
- Visual summary highlights categories and contribution trends.
- User can filter by participant and date range.

### Story 4.2
As a participant, I want to propose settlement so credits can be resolved.

**Acceptance Criteria**
- User can propose method, amount, and optional due date.
- Counterparty can accept, decline, or request change.

### Story 4.3
As both participants, I want to mark settlement complete so balance updates correctly.

**Acceptance Criteria**
- Accepted settlement can be marked complete.
- Completion reduces outstanding balance.

## Epic 5: Multi-User Serverless Sync

### Story 5.1
As a participant, I want my ledger to sync directly with the other participant without a central server.

**Acceptance Criteria**
- App can exchange updates peer-to-peer or via encrypted direct-share channels.
- Offline edits are synced later when connection is available.
- Merge conflicts are visible with clear resolution history.

## Primary User Flows

## Flow A: Auto-Capture and Weekly Review
1. User opens ledger.
2. App has pre-filled weekly suggested entries.
3. User batch-approves, edits, or discards suggestions.
4. Counterparty receives notification.
5. Counterparty confirms or disputes.
6. Confirmed credits update balance.

## Flow B: Dispute and Resolve
1. Counterparty marks entry as needs edit.
2. Author receives reason and edits entry.
3. Counterparty re-reviews.
4. Entry is confirmed or rejected.

## Flow C: Settle Balance
1. One party reviews outstanding balance.
2. User proposes settlement method and credits.
3. Counterparty accepts or negotiates.
4. Settlement marked complete.
5. Balance adjusts and history records action.

## Flow D: Serverless Sync
1. Participant A makes updates while online or offline.
2. App stores changes locally as sync events.
3. When peer channel is available, app exchanges encrypted updates.
4. Both devices merge events and show resolved history.
