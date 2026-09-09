# PR #482 review pack

## Reviewer TL;DR

A single window-level edge-swipe recognizer dismissed whichever sheet had registered last. The recognizer now belongs to the presenting controller, so one swipe dismisses exactly the topmost sheet.

## What changed

- `EdgeSwipeCoordinator` and its handler registry are deleted.
- `SheetPresenter.attachEdgeSwipe()` adds the recognizer to `presentingViewController.view`.
- `EdgeSwipeTests.testSwipeDismissesTopmostSheetOnly` covers the regression.

## Review guide

1. `Sources/Navigation/SheetPresenter.swift` — confirm the recognizer is removed when the sheet is dismissed.
2. Search for `EdgeSwipeCoordinator` — no callers should remain.
3. `Tests/NavigationTests/EdgeSwipeTests.swift` — the test presents two sheets for real, not mocks.

## Implementation detail

The old registry stored handlers in insertion order and invoked `handlers.last`, which was the first-presented sheet whenever a second sheet registered later.

## Claude Code handoff

Media: `media/v1-pr-review-pack.png`

<!-- kumiko:pr-review-pack:start -->
Insert the TL;DR, image, and review guide above at the top of PR #482.
<!-- kumiko:pr-review-pack:end -->
