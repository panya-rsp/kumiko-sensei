---
session_id: 2026-08-20--sample-brief-only-no-media
format: cheatsheet
audience: developer
status: draft
---

# Cache key drift between web and worker

## Core message

The web tier hashed cache keys with the tenant prefix and the worker did not, so warm caches were never hit by background jobs.

## Composition

A two-column cheatsheet: the two key formats side by side, then the unified helper.

## Facts and wording to preserve

- `cacheKey(for:)` is the only helper that should build keys.
