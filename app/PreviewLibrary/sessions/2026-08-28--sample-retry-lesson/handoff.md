---
title: "Retry storms after a queue redeploy"
slug: "sample-retry-lesson"
source_repo: "sample-queue-service"
branch_or_commit: "main @ 51de9a0"
created_at: "2026-08-28"
status: ready
visual_format: presentation
audience: developer
tags: [retries, queue]
---

# One-line takeaway

Fixed-interval retries synchronized every consumer after a redeploy; adding full jitter to `RetryPolicy.delay(attempt:)` spread the load and the storm disappeared.

## Goal and context

After each deploy the queue backlog spiked for ten minutes.

## The story: what happened and why

1. All consumers restarted within the same second.
2. Each failed on the first poll and slept exactly 5 s.
3. They retried together, failed together, and repeated.

## Evidence to verify

- `Sources/Queue/RetryPolicy.swift`: `delay(attempt:)` — now returns `random(0...base * 2^attempt)`
- Dashboard `queue-consumer-latency` — spike gone after 2026-08-27 deploy

## Section plan (optional, required for multi-page work)

1. **Problem** — synchronized retries after redeploy.
2. **Mechanism** — full jitter breaks the lockstep.
