---
title: "Cache key audit: which call sites still hand-build keys?"
slug: "sample-cache-key-audit"
source_repo: "sample-web-app"
branch_or_commit: "main @ 7ab21c4"
created_at: "2026-09-01"
status: ready
visual_format: cheatsheet
audience: developer
---

# One-line takeaway

Three of eleven call sites still concatenate cache keys by hand; routing them through `cacheKey(for:)` closes the drift found in APP-1310.

## Goal and context

Follow-up to the web/worker cache drift.

## Evidence to verify

- `Sources/Cache/CacheKey.swift`: `cacheKey(for:)` — the single helper
- `Sources/Reports/ReportCache.swift:41` — hand-built key
- Verification: `grep -rn "\"tenant:\" +" Sources` → 3 hits

## Visual request

Format: cheatsheet listing the eleven sites with a safe/drift verdict.
