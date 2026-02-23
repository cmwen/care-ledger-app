# Astro Docs Site Design Pack (Orchestrated)

This document consolidates outputs from four roles:
- Product Owner
- Experience Designer
- Researcher
- Architect

## 1) Product Owner Output

### 1.1 Product Goal
Ship a fast documentation website that explains setup, customization, releases, and onboarding for this repository.

### 1.2 MVP Scope
- Home, About, Install, Releases pages
- Clear project identity aligned with Care Ledger branding
- Release download guidance and links
- GitHub Pages deployment compatibility

### 1.3 Success Metrics
- New contributor can run project locally in under 15 minutes.
- First-time reader finds install instructions in under 2 clicks.
- Release page clearly routes users to latest artifacts.

### 1.4 Priority Backlog
P0:
1. Rebrand site copy from template naming to Care Ledger naming
2. Align navigation with repo docs hierarchy
3. Tighten install flow and prerequisites

P1:
1. Add docs index page grouped by user maturity (beginner/intermediate/advanced)
2. Add FAQ from troubleshooting patterns

## 2) Experience Designer Output

### 2.1 Information Architecture
Top-level pages:
1. Home
2. Install
3. Releases
4. About

Support links:
- Product vision
- MVP requirements
- Roadmap

### 2.2 Content UX Rules
- Each page starts with a one-sentence purpose summary.
- Include one primary CTA per page.
- Keep command snippets copy-paste ready.
- Use consistent “What you will do” checklists in setup pages.

### 2.3 Key UX Flows
Flow A: New developer onboarding
1. Land on Home
2. Click Install
3. Follow prerequisites + setup commands
4. Run app locally

Flow B: Release consumer
1. Open Releases page
2. Identify latest stable artifact
3. Download and verify

## 3) Researcher Output

### 3.1 Documentation Best-Practice Recommendations
- Prefer task-based sections over technology-first sections.
- Keep code blocks minimal and validated.
- Use progressive disclosure: summary -> details -> reference links.

### 3.2 Content Gaps Identified
- Some Astro copy still references template-era names and URLs.
- Install and release docs can be more explicit about platform assumptions.
- Docs site does not yet expose a consolidated architecture map.

### 3.3 Recommended Fixes
1. Normalize naming and repository links site-wide.
2. Add a docs landing section for “start here” pathways.
3. Cross-link to core design docs for product and architecture context.

## 4) Architect Output

### 4.1 Site Architecture
- Keep static Astro pages with shared `BaseLayout` and lightweight components.
- Preserve low-complexity structure: pages + components + styles.
- Avoid introducing runtime JS unless required.

### 4.2 Deployment Architecture
- Build static site in CI.
- Publish via GitHub Pages on release/manual trigger.
- Keep base path configurable in Astro config for repo deployments.

### 4.3 Content Maintenance Contract
- Source of truth remains repository markdown docs.
- Astro pages summarize and route to canonical docs.
- Any product scope changes require updating both repo docs and site summaries.

### 4.4 Milestones
1. **D1**: Rebrand and link validation
2. **D2**: Install flow improvements
3. **D3**: Release UX and docs index improvements

## 5) Final Design Decisions (Approved)

1. Keep docs site minimal and static-first.
2. Optimize for onboarding and release discoverability.
3. Use existing markdown docs as canonical sources.
4. Rebrand all template-era references to current project identity.
