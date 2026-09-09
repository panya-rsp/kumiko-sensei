---
title: "Edge swipe dismissed the wrong sheet on iOS"
slug: "sample-edge-swipe-review-pack"
source_repo: "sample-mobile-app"
branch_or_commit: "fix/APP-1204-edge-swipe @ 9c1f2ab"
created_at: "2026-08-14"
status: ready
visual_format: pr-review-pack
audience: developer
tags: [navigation, gestures]
---

# One-line takeaway

The edge-swipe gesture recognizer was attached to the window, so it dismissed whichever sheet was topmost instead of the one that owned the gesture; scoping it to the presenting controller fixes PR #482.

## Goal and context

Users swiping from the left edge while a confirmation sheet was open saw the sheet *behind* it disappear.

## The story: what happened and why

1. `EdgeSwipeCoordinator` installed one `UIScreenEdgePanGestureRecognizer` on `UIWindow`.
2. Every presented controller registered a dismiss handler with the coordinator.
3. The coordinator called the **last registered** handler, which belonged to the sheet presented first.
4. Scoping the recognizer to `presentingViewController.view` and removing the shared registry makes ownership explicit.

## Before → after

**Before.** Swipe with two sheets open → the lower sheet dismisses, the top sheet stays.

**After.** Swipe → only the topmost sheet dismisses. One swipe, one sheet.

## Evidence to verify

- `Sources/Navigation/EdgeSwipeCoordinator.swift`: `register(handler:)` — the shared registry that was removed
- `Sources/Navigation/SheetPresenter.swift`: `attachEdgeSwipe()` — recognizer now added to the presenting view
- `Tests/NavigationTests/EdgeSwipeTests.swift`: `testSwipeDismissesTopmostSheetOnly` — new regression test
- Verification run: `swift test --filter NavigationTests` → 14 tests passing
- Not yet done: manual walk on a physical device with reduced motion enabled

## Key decisions and trade-offs

- Rejected keeping the registry with a stack discipline; ownership by the presenter is simpler and removes a global.

## Caveats and non-goals

- Android is unaffected; its back gesture is handled by the platform.

## Visual request

Format: pr-review-pack. Before/after cheatsheet of the gesture ownership.

## PR review pack (required when visual_format is pr-review-pack)

### Reviewer takeaway
A window-level gesture dismissed the wrong sheet; scoping it to the presenter fixes ownership.

### Why this matters
Any future sheet would have inherited the same bug.

### Review focus
- `SheetPresenter.attachEdgeSwipe()` — the recognizer's target view
- `EdgeSwipeCoordinator` deletion — confirm no remaining callers
- `EdgeSwipeTests` — asserts topmost-only dismissal

### PR placement
Top of PR #482's existing description.

## Accuracy check

- The device walk with reduced motion has **not** been performed.
- Exactly one recognizer existed before; do not imply several were leaking.
