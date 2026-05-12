# Liminal — Portfolio Disposition

**Status:** Release Frozen (iOS App Store) — SwiftUI + SceneKit +
Metal atmospheric exploration / puzzle game on `origin/main` with
full App Store submission scaffolding (`APPSTORE-METADATA.md`,
DEVELOPMENT_TEAM, Privacy Manifest, scheme generation, copyright in
metadata + ExportOptions, privacy policy, App Store archive prep,
AI-generated final icon). Classified as **Games** (primary) +
**Entertainment** (secondary) in App Store Connect at **$4.99 paid
up-front**. Sixth iOS App Store cluster member — and the **first
paid-app iOS cluster member**, distinct from Calibrate / Chromafield
/ Ghost Routes / Nocturne / Tide Engine (all Free).

> Disposition uses strict `origin/main` verification.
> **Introduces paid-app as a relevant operator concern axis** —
> not a new sub-shape, but a meaningful distinction.

---

## Verification posture

This repo has **only `origin`** (`saagpatel/Liminal`) — no
`legacy-origin` remote. Clean migration state.

Specifically verified on `origin/main`:

- Tip: `ad9fe97` chore: replace placeholder icon with AI-generated
  app icon
- Substantive App Store prep commits:
  - `ad9fe97` AI-generated app icon (final)
  - `9ed4f5b` placeholder icon (gradient — intermediate)
  - `f4db8bd` app store archive prep (signing, icons, screenshots)
  - `62257c3` privacy policy + metadata URLs
  - `1df530b` copyright in metadata + ExportOptions
  - `1b1d7cd` App Store Connect metadata
  - `70f9354` App Store prep — DEVELOPMENT_TEAM, Privacy Manifest,
    scheme generation
- **Release scaffolding shipped on canonical main:**
  - `APPSTORE-METADATA.md` (Games + Entertainment, $4.99, all
    territories)
  - Privacy policy, DEVELOPMENT_TEAM, Privacy Manifest,
    ExportOptions.plist
  - AI-generated icon
- App Store identity:
  - Name: **Liminal**, Subtitle: **Find the Rule. Find the Exit.**
  - Bundle ID: `com.liminal.app`, SKU: `LIMINAL-001`
  - Categories: **Games** (primary) + **Entertainment** (secondary)
  - Age Rating: 4+, **Price: $4.99**, Availability: All territories
- Default branch: `main`

---

## Current state in one paragraph

Liminal is a SwiftUI + SceneKit + Metal atmospheric exploration /
puzzle game for iOS. The hook is in the subtitle: "Find the Rule.
Find the Exit." — the player is dropped into spatial puzzles
without explicit instructions and must discover the rules by
exploration. Memory: feature-complete; all phases done. The
canonical commit cadence confirms App Store prep is complete (icon
AI-generated, archive prep, privacy policy, DEVELOPMENT_TEAM, etc.).
The release-ready state matches the iOS App Store cluster
signature established by R12/R13.

---

## Why "Release Frozen (iOS App Store, paid)" — sixth cluster member

The cluster signature continues to hold for a sixth iOS app. The
distinguishing axis this row introduces is **paid pricing** ($4.99
vs Free for all prior iOS cluster members):

- App Store Connect requires explicit pricing tier selection
- 30% Apple rev share applies to gross revenue
- Refund policy = Apple's policy (operator can't override)
- Family Sharing posture (App Store Connect setting)
- Pricing localization (Apple's matrix; or manual per-territory
  pricing)
- Promotional pricing tools (limited-time free, regional discounts)

This is **not a new sub-shape** — Liminal is still in the iOS App
Store cluster, local-first sub-shape (no backend, no third-party
API per current state). The paid posture is an operator concern
modifier, not a cluster restructure.

---

## Cluster taxonomy update

| Cluster | Count | Sub-shapes |
|---|---|---|
| Signing (Apple desktop) | 24 | (no sub-shapes) |
| **iOS App Store** | **6** | local-first (5) / cloud-backed (1) |
| Static-host (web) | 3 | … |
| Self-hosted service | 1 | (n/a) |
| PyPI distribution | 2 | … |
| Local-first pipeline | 1 | (n/a) |
| Operator-tool / dogfood | 1 | (n/a) |
| Chrome MV3 extension | 2 | … |
| Game (Godot) | 1 | (n/a yet) |

The iOS App Store cluster gains a 6th member; local-first sub-shape
now at 5. Pricing axis (Free vs Paid) is introduced as a new
operator concern, not a sub-shape division.

---

## Unblock trigger (operator)

When ready to ship:

1. **App Store Connect record + pricing tier selection** ($4.99 →
   Tier 5 in Apple's matrix, or custom per-territory pricing).
2. **Game-category screenshot composition** — Games category
   reviewers expect gameplay footage prominently. Spatial /
   atmospheric games can be tricky to screenshot well; consider
   animated previews (3-up to 30-second clips per device size).
3. **Privacy nutrition labels** — local-first, paid app: "Data Not
   Collected" if accurate. Verify no analytics SDK snuck in.
4. **Refund policy disclosure** — for paid apps under $5,
   Apple's standard 14-day refund window applies. Document
   internally if support requests come up.
5. **Apple's 30% rev share + 15% small business tier** — verify
   App Store Small Business Program enrollment if applicable
   (cuts to 15% for first $1M annual gross).
6. **Required screenshots** + fastlane deliver dry-run if
   fastlane is wired (this repo doesn't show explicit fastlane
   deliver commit; verify).
7. **Submit for Review.**

Estimated operator time once App Store Connect record exists:
~4-5 hours (game-category screenshot composition is the dominant
cost; the operator may want an animated preview, which is more
work than static screenshots).

---

## Portfolio operating system instructions

| Aspect | Posture |
|---|---|
| Portfolio status | `Release Frozen (iOS App Store, local-first, paid)` |
| Distribution channel | **App Store Connect** — Games (primary) + Entertainment (secondary), $4.99 |
| Pricing model | **Paid up-front** (first paid iOS cluster member) |
| Review cadence | Suspend overdue counting |
| Resurface conditions | (a) Submission to App Store Review, (b) review feedback (game-category UX scrutiny), (c) pricing decision change, or (d) v1.1 scope (more levels, content updates) |
| Co-batch with | iOS App Store cluster — **now 6 repos** |
| Special concern | **Game-category screenshot / preview composition.** Different review scrutiny from utility apps; gameplay clarity matters. |
| Special concern | **Paid pricing UX.** First paid iOS cluster member — pricing tier selection, App Store Small Business Program enrollment, family sharing posture, regional pricing all need explicit decisions. |
| Special concern | **No fastlane deliver visible.** Most other iOS cluster members have explicit fastlane deliver config commit. Verify before announcing if metadata upload should be scripted. |

---

## Reactivation procedure

1. Verify `git branch -vv` shows `main` tracking `origin/main`.
2. Review stash `r14-liminal-stash` (xcodeproj + project.yml local
   mods).
3. Open Xcode → confirm DEVELOPMENT_TEAM valid.
4. **Verify pricing tier selection in App Store Connect matches
   $4.99 intent.**
5. Run XCTest target.

---

## Last known reference

| Field | Value |
|---|---|
| `origin/main` tip | `ad9fe97` chore: replace placeholder icon with AI-generated app icon |
| Default branch | `main` |
| Build system | iOS / Swift / SwiftUI / **SceneKit + Metal** / XcodeGen (project.yml) / XCTest |
| Bundle ID | `com.liminal.app` |
| App Store category | **Games** (primary) + Entertainment |
| Price | **$4.99** (first paid iOS cluster member) |
| Phases shipped | Feature-complete per memory; full App Store prep cadence on canonical main |
| Migration state | No `legacy-origin` remote |
| Distinguishing feature | **Sixth iOS App Store cluster member AND first paid-app iOS cluster member.** Introduces paid pricing as an operator concern axis (pricing tier, 30% rev share, Small Business Program, regional pricing). |
