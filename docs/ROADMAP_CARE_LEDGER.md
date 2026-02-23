# Care Ledger Roadmap

## Product Phasing

## Phase 0: Discovery and Alignment (1-2 weeks)

### Outcomes
- Finalize terminology: care credits, settlement, confirmation.
- Align on fairness model (fixed credits vs negotiable credits).
- Confirm privacy and consent expectations.
- Define auto-capture policy and acceptable data sources.
- Select serverless sync approach for two-party usage.

### Deliverables
- Finalized product vocabulary
- Signed-off MVP requirements
- Low-fidelity wireframes for core flows
- Technical decision note for local-first multi-user sync

## Phase 1: MVP Build (4-8 weeks)

### Scope
- Shared ledger setup
- Auto-capture care entry suggestions
- Weekly review workflow and batch approval
- Entry review and status workflow
- Basic balance summary
- Visual timeline and weekly contribution dashboard
- Settlement proposal and completion
- Basic notifications
- Serverless two-party sync (no central app server)

### Exit Criteria
- Two participants can fully use app end-to-end.
- At least 10 pilot families test complete flow.
- Critical bugs resolved for daily usage.
- Majority of pilot users complete weekly review without daily manual logging.

## Phase 2: Post-MVP (6-10 weeks)

### Potential Enhancements
- Multi-ledger support (different child/family contexts)
- Recurring task templates
- Better analytics (monthly contribution trends)
- Photo/document evidence controls
- Export reports (PDF/CSV)
- Smarter auto-capture confidence scoring and explanation UI

## Phase 3: Scale and Trust Features

### Potential Enhancements
- Mediation mode (neutral third-party reviewer)
- Role-based privacy settings
- Integrations (calendar sync, reminders)
- Optional payment integrations

## Open Product Decisions

1. **Credit valuation model**
   - Fixed by category?
   - Negotiated per entry?
   - Hybrid model?

2. **Settlement currencies**
   - Credits only?
   - Cash equivalent support?
   - Non-cash reciprocity catalog?

3. **Dispute handling boundaries**
   - Maximum rounds of revision?
   - Escalation path if unresolved?

4. **Privacy model**
   - Can participants hide private notes permanently?
   - Are attachments mandatory for high-value entries?

5. **Child visibility**
   - Should children see ledger records in future versions?

6. **Serverless sync mechanism**
   - Direct local-network sync?
   - End-to-end encrypted relay messages?
   - User-driven export/import fallback?

7. **Auto-capture boundaries**
   - Which data sources are allowed by default?
   - How much evidence is shown before approval?
   - What privacy controls are required per source?

## Suggested Next Execution Steps

1. Confirm MVP decisions in a 60-minute product workshop.
2. Translate stories into Flutter issue backlog.
3. Build clickable wireframes for 3 core flows.
4. Start implementation with local-first data model.
5. Pilot with 3-5 families before wider release.
