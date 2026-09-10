# Kumiko Sensei design system

Source: brand sheet generated 2026-09-09. Code tokens live in `app/KumikoSensei/Views/Theme.swift` (`Palette`, `Gradients`, `Font` extension). This file is the reference; Theme.swift is the implementation.

## Brand

- **Name:** Kumiko Sensei
- **Tagline:** Same tech. Clearer understanding. A kinder tomorrow.
- **Japanese:** 「知ることで、やさしい未来をつくろう。」 — A kinder tomorrow, through a clearer understanding.
- **Pillars:** Learn Faster · Think Deeper · Make Progress · A Kinder Tomorrow
- **Word mark strip:** KUMIKO SENSEI | LEARN × THINK × CREATE × TOGETHER
- **Mascot:** Kumiko, brown bob, round glasses, teal shirt, navy blazer, origami crane motif (teal `#2DD4BF`).

## Color

### Primary (trust, focus, action)

| Token | Hex |
|---|---|
| Primary | `#2563EB` |
| Primary Hover | `#3B82F6` |
| Primary Light | `#DBEAFE` |

### Secondary (warmth, approachability)

| Token | Hex |
|---|---|
| Secondary | `#14B8A6` |
| Secondary Hover | `#2DD4BF` |
| Secondary Light | `#CCFBF1` |

### Accent (joy, highlight, personality)

| Token | Hex |
|---|---|
| Accent Pink | `#F472B6` |
| Accent Purple | `#A78BFA` |
| Accent Yellow | `#FCD34D` |

### Neutral (structure, readability)

| Token | Hex |
|---|---|
| Navy (Dark) | `#0F172A` |
| Slate | `#334155` |
| Gray | `#64748B` |
| Light Gray | `#CBD5E1` |
| Surface | `#F1F5F9` |
| White | `#FFFFFF` |

### Semantic (system feedback and status)

| Token | Hex |
|---|---|
| Success | `#10B981` |
| Warning | `#F59E0B` |
| Error | `#EF4444` |
| Info | `#3B82F6` |

### Gradients (backgrounds and highlights)

| Token | Stops |
|---|---|
| Brand | `#2563EB` → `#14B8A6` |
| Sunrise | `#F472B6` → `#FCD34D` |
| Night | `#6366F1` → `#2563EB` |

### Glass and surface (macOS 26 inspired)

| Token | Value |
|---|---|
| Glass Light | `rgba(255,255,255,0.7)` |
| Glass Dark | `rgba(17,24,39,0.6)` |
| Surface Light | `#F8FAFC` |
| Surface Dark | `#0F172A` |

## Typography

Family: **Inter** — clean, modern, highly readable. Weights: Light, Regular, Medium, Semibold, Bold.

| Role | Spec (size/line) | Example |
|---|---|---|
| H1 | Inter Semibold 48/56 | Kumiko Sensei |
| H2 | Inter Semibold 32/40 | Same tech. Clearer understanding. |
| H3 | Inter Medium 20/28 | A kinder tomorrow. |
| Body | Inter Regular 16/24 | Learn, think, and build a kinder tomorrow. |
| Caption | Inter Regular 14/20 | 「知ることで、やさしい未来をつくろう。」 |
| Caption (EN) | Inter Regular Italic 14/20 | A kinder tomorrow, through a clearer understanding. |
| Button | Inter Medium 16/24 | Get Started |

## Components

- **Buttons:** pill/rounded (~10 pt radius). Primary = Primary fill, white text. Secondary = Secondary Hover fill, navy text. Accent = Accent Pink fill, white text. Ghost = transparent, Primary text.
- **Input field:** rounded search field, magnifier leading, placeholder “Ask Kumiko anything...”, `⌘ K` shortcut hint trailing.
- **Tags:** small pill chips on a tinted wash (`AI`, `Productivity`, `Learning`, `Design`), plus a `+` add chip.
- **Sidebar items:** Home, Chat, Library, Prompts, Projects. Selected row = Primary Light wash (light) / Primary at low alpha (dark), Primary icon + label.
- **Greeting card:** Brand-gradient wash panel with mascot on the right, `Good morning!` / `Good evening!` title, tagline body.
- **Action tiles:** Explain (Primary Light), Brainstorm (pink wash), Summarize (Secondary Light), Improve (purple wash). Icon above label.

## Iconography

Line icons, 2 px stroke, rounded joins. Simple, clean, friendly. In the app this maps to SF Symbols with default (non-filled) variants; fill only for state (selected, favorite).

Reference set: home, chat bubble, book, lightbulb, folder, gear, person, heart.

## UI preview notes

- Light theme: Surface Light window, white cards, Light Gray hairlines, navy text.
- Dark theme: Surface Dark window, slate cards, white text, Primary Hover as accent.
- Window traffic lights left, app name in the toolbar, search field spanning the content column.

## Mapping to Theme.swift

| Palette token | Light | Dark | Notes |
|---|---|---|---|
| `surface` | `#F8FAFC` | `#0F172A` | window background |
| `card` | `#FFFFFF` | `#1E293B` | dark value derived (between Navy and Slate) |
| `cardRaised` | `#FFFFFF` | `#334155` | Slate |
| `ink` | `#0F172A` | `#FFFFFF` | |
| `inkMuted` | `#64748B` | `#CBD5E1` | Gray / Light Gray |
| `rule` | `#CBD5E1` | `#334155` | hairlines |
| `primary` | `#2563EB` | `#3B82F6` | dark uses Primary Hover |
| `primaryWash` | `#DBEAFE` | `#1E3A8A` | dark value derived |
| `secondary` | `#14B8A6` | `#2DD4BF` | dark uses Secondary Hover |
| `secondaryWash` | `#CCFBF1` | `#134E4A` | dark value derived |
| `accentPink` / `accentPurple` / `accentYellow` | as sheet | same | |
| `success` / `warning` / `error` / `info` | as sheet | same | |
| `errorWash` | `#FEE2E2` | `#3F1D1D` | derived, sheet has no error wash |

Values marked derived are not on the sheet; they follow the Tailwind scale the sheet's hexes come from.
