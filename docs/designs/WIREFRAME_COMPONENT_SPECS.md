# Wireframe Spec: Component Library for Per-Participant UI

## Purpose

Concrete widget specifications and layout measurements for implementing
the per-participant experience. Each component includes dimensions,
color tokens, typography, and Flutter implementation guidance.

---

## 1. ParticipantAvatar Widget

### Variants

| Variant    | Diameter | Font Size | Use Case                          |
|------------|----------|-----------|-----------------------------------|
| compact    | 24 dp    | 10 sp     | Inline in entry cards, app bar    |
| standard   | 36 dp    | 14 sp     | List tiles, review cards          |
| large      | 48 dp    | 20 sp     | Settings profile, onboarding      |

### Visual Spec

```
     YOU avatar               PARTNER avatar
  ┌─────────────┐          ┌─────────────┐
  │  ┌───────┐  │          │             │
  │  │       │  │          │  ┌───────┐  │
  │  │   M   │  │          │  │   S   │  │
  │  │       │  │          │  │       │  │
  │  └───────┘  │          │  └───────┘  │
  │  2dp ring   │          │  no ring    │
  └─────────────┘          └─────────────┘

  BG: primaryContainer       BG: tertiaryContainer
  Text: onPrimaryContainer    Text: onTertiaryContainer
  Ring: primary (2dp)         Ring: none
```

### Flutter Implementation

```dart
class ParticipantAvatar extends StatelessWidget {
  final String name;
  final bool isCurrentUser;
  final AvatarSize size;

  // size enum: compact(24), standard(36), large(48)

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final diameter = size.diameter;
    final fontSize = size.fontSize;

    final bgColor = isCurrentUser
        ? cs.primaryContainer
        : cs.tertiaryContainer;
    final textColor = isCurrentUser
        ? cs.onPrimaryContainer
        : cs.onTertiaryContainer;
    final ringColor = isCurrentUser ? cs.primary : null;

    return Container(
      width: diameter,
      height: diameter,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: bgColor,
        border: ringColor != null
            ? Border.all(color: ringColor, width: 2)
            : null,
      ),
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : '?',
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
      ),
    );
  }
}
```

---

## 2. OwnershipStrip (Entry Card Left Border)

### Spec

```
Width:       4 dp
Height:      Full card height (IntrinsicHeight)
Radius:      Top-left: 12dp, Bottom-left: 12dp (matches card border radius)
Color:
  Your entry:    colorScheme.primary
  Partner entry: colorScheme.tertiary
```

### Implementation in Card

```dart
Row(
  children: [
    // Ownership strip
    Container(
      width: 4,
      decoration: BoxDecoration(
        color: isMyEntry
            ? theme.colorScheme.primary
            : theme.colorScheme.tertiary,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(12),
          bottomLeft: Radius.circular(12),
        ),
      ),
    ),
    // Card content
    Expanded(child: _CardContent(...)),
  ],
)
```

---

## 3. PersonalizedStatusChip

### Layout

```
┌─────────────────────────────────┐
│  [icon 12dp] [4dp gap] [label] │
│                                 │
│  padding: H8, V2                │
│  border-radius: 12dp           │
│  bg: statusColor @ 12% alpha   │
│  text: statusColor @ 100%      │
│  font: 11sp, w500              │
└─────────────────────────────────┘
```

### Status → Visual Mapping

```
Status                          Icon              Color     Label (your entry)
─────────────────────────────────────────────────────────────────────────────
needsReview                     Icons.pending     amber     "Needs your review"
pendingCounterpartyReview       Icons.send        blue      "Waiting for [Partner]"
confirmed                       Icons.check_circle green    "Confirmed"
needsEdit                       Icons.edit_note   orange    "[Partner] requested changes"
rejected                        Icons.cancel      red       "Rejected by [Partner]"

                                                            Label (partner's entry)
─────────────────────────────────────────────────────────────────────────────
needsReview                     Icons.pending     amber     "Needs your review"
pendingCounterpartyReview       Icons.inbox       blue      "Waiting for your review"
confirmed                       Icons.check_circle green    "Confirmed"
needsEdit                       Icons.edit_note   orange    "You requested changes"
rejected                        Icons.cancel      red       "You rejected this"
```

### Icon Change Note

For `pendingCounterpartyReview`:
- Your entry → `Icons.send` (you sent it out, waiting)
- Partner's entry → `Icons.inbox` (it's in your inbox, waiting for you)

This subtle icon change reinforces the asymmetric mental model.

---

## 4. OwnershipEntryCard (Full Spec)

### Dimensions

```
Card padding:        16 dp (all sides)
Card border-radius:  12 dp
Card border:         0.5 dp, outlineVariant
Ownership strip:     4 dp wide, full height
Category icon box:   48 × 48 dp, 12dp radius, 12% category color bg
Gap after icon:      12 dp
Gap after title:     4 dp
Gap before status:   8 dp (if source hint present)
Source hint padding:  8 dp all sides, 8dp radius
Source hint bg:      surfaceContainerHighest
Min touch target:    48 × 48 dp (full card is tappable)
```

### Layout Tree

```
IntrinsicHeight
└─ Row
   ├─ OwnershipStrip (4dp)
   └─ Expanded
      └─ Card
         └─ InkWell (onTap)
            └─ Padding (16dp)
               └─ Row
                  ├─ CategoryIconBox (48×48)
                  ├─ SizedBox (w:12)
                  ├─ Expanded
                  │  └─ Column (crossAxisStart)
                  │     ├─ Text (description, bodyLarge)
                  │     ├─ SizedBox (h:4)
                  │     ├─ Row (author avatar + name + date + duration + auto-icon)
                  │     ├─ SizedBox (h:4)
                  │     └─ PersonalizedStatusChip
                  └─ Column (crossAxisEnd)
                     └─ Text (credits, titleSmall, bold)
```

### Semantics Label

```dart
Semantics(
  label: '${isMyEntry ? "Your" : "$partnerName's"} entry: '
      '${entry.description}, '
      '${entry.creditsProposed} credits, '
      '${personalizedStatusLabel(...)}',
  child: ...,
)
```

---

## 5. SuggestionCard (Auto-Detection)

### Dimensions

```
Card padding:        16 dp
Card border-radius:  12 dp
Card border:         1 dp, tertiary @ 30% (distinct from regular entries)
Card bg:             surfaceContainerLow (slightly different from regular cards)
Badge "Auto-detected": top-right, tertiaryContainer bg, 8dp padding
Confidence dots:     8dp diameter, 4dp gap between
Source hint box:     Same as OwnershipEntryCard
Action buttons row:  Right-aligned, compact visual density
"Don't suggest" link: labelSmall, onSurfaceVariant color, underlined
```

### Layout

```
┌──────────────────────────────────────────┐
│  ✨ Auto-detected             ●●●○ High │
│                                          │
│  ┌────┐                                  │
│  │ 🚗 │  School pickup          2.0 cr   │
│  └────┘  Today at 3:15 PM               │
│                                          │
│  ┌────────────────────────────────────┐  │
│  │ 📍 Detected from: Repeated school │  │
│  │    route (Mon/Wed/Fri pattern,    │  │
│  │    matched 3 consecutive weeks)   │  │
│  └────────────────────────────────────┘  │
│                                          │
│  [🗑 Dismiss]  [✏️ Edit First] [✓ Confirm]│
│                                          │
│  🔇 Don't suggest this type again       │
└──────────────────────────────────────────┘
```

---

## 6. ConfidenceIndicator Widget

### Visual

```
High:    ●  ●  ●  ○    "High"
Medium:  ●  ●  ○  ○    "Medium"
Low:     ●  ○  ○  ○    "Low"

Filled dot: status color (green/amber/grey)
Empty dot:  outlineVariant @ 30%
Dot size:   8 dp diameter
Gap:        4 dp between dots
Label:      12 dp gap after dots, labelSmall, statusColor
```

### Flutter Implementation

```dart
class ConfidenceIndicator extends StatelessWidget {
  final ConfidenceLevel level; // high, medium, low

  @override
  Widget build(BuildContext context) {
    final filled = level.dotCount; // high=3, medium=2, low=1
    final total = 4;
    final color = level.color; // green, amber, outline

    return Semantics(
      label: 'Confidence: ${level.label}, $filled of $total',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ...List.generate(total, (i) => Padding(
            padding: EdgeInsets.only(right: 4),
            child: Container(
              width: 8, height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: i < filled
                    ? color
                    : Theme.of(context).colorScheme.outlineVariant
                        .withOpacity(0.3),
              ),
            ),
          )),
          SizedBox(width: 8),
          Text(level.label, style: TextStyle(
            fontSize: 11,
            color: color,
            fontWeight: FontWeight.w500,
          )),
        ],
      ),
    );
  }
}
```

---

## 7. SyncStatusIndicator

### States & Visuals

```
State         Widget                                 Tooltip
──────────────────────────────────────────────────────────────────
synced        Icon(Icons.cloud_done, color: green)   "Synced with Sarah"
              size: 18dp                             + last sync time

syncing       SizedBox(18×18)                        "Syncing with Sarah..."
              CircularProgressIndicator(strokeWidth:2)

pending       Icon(Icons.cloud_queue, color: amber)  "3 changes pending sync"
              + Badge(label: "3")

offline       Icon(Icons.cloud_off, color: outline)  "Offline — changes saved locally"

neverPaired   Icon(Icons.link_off, color: error)     "Not yet connected to partner"
              + tappable → navigate to pairing
```

### Tap Behavior

Tapping the sync indicator shows a bottom sheet with sync details:

```
┌──────────────────────────────────────┐
│  Sync Status                         │
│                                      │
│  Connected to: Sarah                 │
│  Last synced: 2 hours ago            │
│  Pending changes: 0                  │
│                                      │
│  [Sync Now]  [View Sync Log]         │
│                                      │
└──────────────────────────────────────┘
```

---

## 8. WeekSummaryCard (Redesigned Split View)

### Layout

```
┌──────────────────────────────────────────┐
│  📅 This Week                            │
│                                          │
│  ┌─────────────────┐ ┌─────────────────┐ │
│  │  Your Entries    │ │  Sarah's        │ │
│  │                  │ │  Entries        │ │
│  │   8 entries      │ │   5 entries     │ │
│  │   12.0 cr earned │ │   8.0 cr earned │ │
│  │                  │ │                 │ │
│  │  primaryContainer│ │ tertiaryContainer│ │
│  └─────────────────┘ └─────────────────┘ │
│                                          │
│  ┌────────────────────────────────────┐  │
│  │ ⏳ 3 entries waiting for Sarah     │  │
│  └────────────────────────────────────┘  │
│  ┌────────────────────────────────────┐  │
│  │ 📥 2 entries waiting for your      │  │
│  │    review  [Review Now →]          │  │
│  └────────────────────────────────────┘  │
│                                          │
│  Card bg: surfaceContainerLow            │
│  Inner stat boxes: primaryContainer      │
│  and tertiaryContainer respectively      │
│  Action prompts: tertiaryContainer bg    │
│  Card padding: 20dp                      │
│  Inner box padding: 16dp                 │
│  Gap between boxes: 12dp                 │
│  Stat box border-radius: 12dp            │
└──────────────────────────────────────────┘
```

### Responsive Behavior

- **Phone portrait (< 400dp wide)**: Stat boxes stack vertically
- **Phone landscape / tablet**: Stat boxes side by side (as shown)
- **Stat numbers**: headlineSmall, bold, onPrimaryContainer / onTertiaryContainer
- **Stat labels**: labelSmall, 70% alpha

---

## 9. ReviewSectionHeader

### Layout

```
┌──────────────────────────────────────────┐
│  ── [Icon] Section Title ──       [count]│
│  Subtitle description text               │
│                                          │
│  padding: H16, V8                        │
│  title: titleSmall, onSurface           │
│  subtitle: bodySmall, outline            │
│  count: labelMedium, primary             │
│  divider: outlineVariant, 0.5dp          │
└──────────────────────────────────────────┘
```

### Three Sections

```
Section 1: "📥 Sarah's Entries"
           "Entries waiting for your approval"
           Count badge: "3"

Section 2: "✨ Your Auto-Suggestions"
           "Detected activities to confirm or dismiss"
           Count badge: "2"

Section 3: "⚠️ Your Entries — Edits Requested"
           "Sarah asked you to update these"
           Count badge: "1"
```

---

## 10. BalanceOverviewCard (Redesigned)

### Layout

```
┌──────────────────────────────────────────┐
│  Balance Overview                        │
│                                          │
│  ┌───────────────┐  ┌───────────────┐    │
│  │  [Y] You      │  │  [S] Sarah    │    │
│  │    42.0       │  │    36.0      │    │
│  │  confirmed cr  │  │  confirmed cr │    │
│  │               │  │              │    │
│  │ primaryCont.  │  │ tertiaryCont.│    │
│  └───────────────┘  └───────────────┘    │
│                                          │
│  ┌────────────────────────────────────┐  │
│  │  Sarah owes you 6.0 credits       │  │
│  │  ─── or ───                        │  │
│  │  You owe Sarah 6.0 credits        │  │
│  │  ─── or ───                        │  │
│  │  You're balanced! 🎉              │  │
│  └────────────────────────────────────┘  │
│                                          │
│  Net balance pill:                       │
│    bg: onPrimaryContainer @ 10%          │
│    text: titleSmall, bold                │
│    padding: H16, V8                      │
│    border-radius: 20dp                   │
│                                          │
│  Card bg: surface                        │
│  Card padding: 20dp                      │
│  Avatar + name row per participant       │
│  Credit number: headlineMedium, bold     │
│  Label: labelSmall, 70% alpha            │
└──────────────────────────────────────────┘
```

---

## 11. SettlementCard (Perspective-Aware)

### Your Proposal

```
┌──────────────────────────────────────────┐
│  💰 You proposed                         │
│                                          │
│  [method icon] 5.0 cr via Cash           │
│  ⏳ Waiting for Sarah                    │
│  "For March balance"                     │
│                                          │
│  [Cancel Proposal]                       │
│                                          │
│  ownership strip: primary (your action)  │
└──────────────────────────────────────────┘
```

### Partner's Proposal to You

```
┌──────────────────────────────────────────┐
│  📩 Sarah proposed                       │
│                                          │
│  [method icon] 5.0 cr via Cash           │
│  📥 Needs your response                  │
│  "For March balance"                     │
│                                          │
│  [Decline]  [Request Change]  [Accept ✓] │
│                                          │
│  ownership strip: tertiary (their action)│
│  action button row: right-aligned        │
│  Accept: FilledButton, green bg          │
│  Decline: OutlinedButton, red fg         │
│  Request Change: OutlinedButton, amber fg│
└──────────────────────────────────────────┘
```

---

## 12. QuickApprovalBanner (Review Tab Top)

### Layout

```
┌──────────────────────────────────────────┐
│  📥 Sarah submitted 3 entries            │
│     for your review this week.           │
│                                          │
│  Estimated review time: ~2 min           │
│                                          │
│  ┌──────────────┐  ┌──────────────────┐  │
│  │ Approve All  │  │ Review One by One│  │
│  │ (FilledBtn)  │  │ (OutlinedBtn)    │  │
│  └──────────────┘  └──────────────────┘  │
│                                          │
│  bg: secondaryContainer                  │
│  padding: 16dp                           │
│  border-radius: 16dp                     │
│  margin-bottom: 16dp                     │
│  title: titleSmall, onSecondaryContainer │
│  subtitle: bodySmall, onSecondaryContainer│
│  est. time: labelSmall, bold             │
└──────────────────────────────────────────┘
```

### "Approve All" Confirmation

Tapping "Approve All" shows a confirmation dialog:

```
┌──────────────────────────────────────┐
│  Approve all 3 entries?              │
│                                      │
│  This will confirm 3 entries from    │
│  Sarah totaling 6.5 credits.        │
│                                      │
│  You can undo individual approvals   │
│  within 7 days.                      │
│                                      │
│  [Cancel]         [Approve All ✓]    │
└──────────────────────────────────────┘
```

---

## 13. Color Token Reference

### M3 Semantic Roles Used

```
Token                        Light Value          Usage
──────────────────────────────────────────────────────────────
primary                      #6750A4              "You" accent, your actions
onPrimary                    #FFFFFF              Text on primary
primaryContainer             #E8DEF8              "You" card/avatar bg
onPrimaryContainer           #1D192B              Text on your bg

tertiary                     #7D5260              Partner accent
onTertiary                   #FFFFFF              Text on tertiary
tertiaryContainer            #FFD8E4              Partner card/avatar bg
onTertiaryContainer          #31111D              Text on partner bg

surface                      #FEF7FF              Main backgrounds
surfaceContainerLow          #F7F2FA              Suggestion card bg
surfaceContainerHighest      #E6E0E9              Source hint bg

error                        #B3261E              Rejection, invalid states
outlineVariant               #CAC4D0              Card borders, empty dots
```

### Status Colors (Unchanged)

```
needsReview:                 Colors.amber
pendingCounterpartyReview:   Colors.blue
confirmed:                   Colors.green
needsEdit:                   Colors.orange
rejected:                    Colors.red
```

### Category Colors (Unchanged)

Already well-defined in the existing `entry_card.dart` and `timeline_screen.dart`.

---

## 14. Typography Scale Used

```
Token              Size    Weight    Usage
────────────────────────────────────────────────────
headlineMedium     28sp    bold      Balance credit numbers
headlineSmall      24sp    bold      Week summary stat numbers
titleLarge         22sp    normal    Sheet headers ("Add Care Entry")
titleMedium        16sp    w500     Section headers ("Recent Entries")
titleSmall         14sp    w500     Card titles, net balance pill
bodyLarge          16sp    normal    Entry descriptions
bodyMedium         14sp    normal    General text
bodySmall          12sp    normal    Metadata (author, date, duration)
labelMedium        12sp    w500     Stat labels, chip text
labelSmall         11sp    w500     Secondary metadata, source type
```

---

## 15. Spacing & Layout Constants

```
Constant                    Value    Usage
──────────────────────────────────────────────────
screenPadding               16 dp    All screen edge padding
cardPadding                 16 dp    Inside card content
cardGap                     8 dp     Between stacked cards (vertical)
sectionGap                  24 dp    Between major sections
avatarGapInline             4 dp     After compact avatar in row
avatarGapStandard           8 dp     After standard avatar in row
chipPaddingH                8 dp     Status chip horizontal
chipPaddingV                2 dp     Status chip vertical
ownershipStripWidth         4 dp     Left border strip
bottomNavHeight             80 dp    Navigation bar
appBarHeight                56 dp    Standard app bar
touchTargetMin              48 dp    Minimum interactive size
categoryIconBoxSize         48 dp    In entry cards
categoryIconBoxRadius       12 dp    Rounded square
cardBorderRadius            12 dp    All cards
suggestBannerRadius         16 dp    Suggestion banner
```
