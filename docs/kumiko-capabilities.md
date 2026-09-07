# Kumiko-sensei capabilities

Ask **“What should Kumiko make from this?”** when you have the knowledge but not the format. Kumiko recommends one or two options based on the story, audience, and amount of material.

| Feature | Best for | Output |
|---|---|---|
| **Bug explainer** | A confusing symptom with a precise root cause | One vertical cheatsheet: symptom → mechanism → fix → caveats |
| **Before / after** | A behavior or implementation change | Side-by-side visual showing what changed and why |
| **Event flow** | Gestures, navigation, async work, lifecycle, or state transitions | Step sequence, timeline, or state diagram |
| **Architecture map** | Components, services, routes, ownership, or data flow | System map with boundaries and dependencies |
| **Audit board** | “Where else can this happen?” | Scannable classification: safe, bug, unknown, proposed follow-up |
| **Decision board** | Alternatives, trade-offs, and a chosen approach | Bento-style comparison with rationale and non-goals |
| **Code walkthrough** | Helping future-you understand a difficult change | Evidence-linked path through the relevant files and symbols |
| **Multi-page lesson** | A long story that should unfold progressively | One coordinated image per named section |
| **Release story** | Explaining a feature or fix to non-implementers | Outcome-first presentation with only necessary technical detail |
| **Onboarding card** | Reusable team knowledge or a recurring workflow | Compact reference cheatsheet or playbook |
| **PR review pack** | An important pull request whose reviewers need context before reading the diff | PR-ready TL;DR, visual mental model, and concrete review guide |
| **Live artifact** | A visual that should be explored, demoed, or shared | Interactive `artifact/index.html` built by Claude Code on request |

## Fast selection guide

- **One surprising bug:** Bug explainer
- **A flow across time:** Event flow
- **“Which option was right?”:** Decision board
- **“Did we check the rest of the app?”:** Audit board
- **Too much for one page:** Multi-page lesson
- **A consequential PR with hidden context:** PR review pack
- **Need to click or present it live:** Live artifact

## Ways to ask

```text
Ask Kumiko-sensei what format best teaches this handoff.
Ask Kumiko-sensei for a three-page lesson: problem, mechanism, durable fix.
Ask Kumiko-sensei to make an audit board for these call sites.
Ask Kumiko-sensei to create a PR review pack for this change: a top-of-description TL;DR, visual, and review guide.
Ask Kumiko-sensei to turn this into a live interactive artifact.
```
