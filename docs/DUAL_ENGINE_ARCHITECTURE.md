# Earnova AI — Dual-Engine Architecture

## Definition
Each major feature has two cooperating paths:
- **Smart engine:** optional AI assistance for discovery, drafting, translation, recommendations, matching, or prioritization.
- **Reliable engine:** deterministic rules, validated APIs, normal controls, trusted provider status, and graceful fallback when AI or the network is unavailable.

The reliable engine is not another AI model. AI must not be the authority for identity, job verification, permissions, balances, or payout completion.

## Feature map
| Feature | Smart engine | Reliable engine |
|---|---|---|
| Feed/discovery | Topic summaries and personalized ranking | Search, following feed, user-controlled ranking |
| Reels | Script, captions, translation, accessibility help | Validated upload, storage, processing, playback, retry |
| Chat | Optional translation and writing help | Normal messages, delivery states, block/report |
| Jobs | Skills matching and resume feedback | Active verified listings, filters, application tracking |
| Earnings | Campaign matching and explanations | Server-side ledger, eligibility checks, provider-confirmed payouts |
| Safety | Spam/fraud signals and queue prioritization | Rate limits, rules, reports, appeals, human review |
| Themes | Optional personalization | Manual light/dark controls, cached preferences, accessible defaults |
| Support/admin | Case summaries and suggested replies | Role-based permissions, audit trail, human escalation |

## Target architecture
1. Responsive web/PWA client; no provider secrets in frontend code.
2. API layer with authentication, authorization, schema validation, rate limits and safe errors.
3. Database for accounts, posts, relationships, conversations, jobs, reports and transactions.
4. Media pipeline with validated uploads, durable storage, processing states and retry.
5. Server-only AI gateway with task permissions, output validation, timeouts, usage limits and fallback.
6. Trust/operations layer: employer verification, moderation queue, audit logs, privacy export/deletion, metrics and backups.
7. Payment, messaging and job-source integrations behind provider adapters; disabled integrations must fail clearly, never fake success.

## Delivery sequence and acceptance gates

### D0 — Preserve and baseline
Inventory existing screens, scripts, local-storage keys and deploy settings. Add smoke tests for navigation, posts, theme settings, mobile layout and refresh.
**Gate:** existing preview works; no secrets in client files.

### D1 — Backend foundation
Select a backend/database within the budget; verify free-tier limits. Add configuration, migrations, health checks, secure sessions, account recovery, rate limits and audit events.
**Gate:** unauthenticated access is denied; one user cannot read or change another user's private data.

### D2 — Cross-device preferences
Add authenticated account-theme and per-conversation appearance APIs. Validate mode/preset IDs. Use server timestamps or versions to reconcile offline changes.
**Gate:** two-device sync works; one chat's theme never changes another chat; stale offline state cannot silently overwrite newer server settings.

### D3 — Social and Reels backend
Move profiles, posts, follows, reactions, comments, saves and notifications to APIs. Add upload/storage/processing, retry, reporting and moderation.
**Gate:** a second account sees permitted shared posts and Reels after refresh; invalid uploads are rejected.

### D4 — Jobs and earning
Add employer verification, listing review, applications, immutable transaction records and provider adapters after provider setup and operational review.
**Gate:** unverified jobs cannot publish; replayed payout requests cannot double-pay; provider failures never show success.

### D5 — AI gateway and agents
Start with lower-risk drafting, translation and resume feedback. Add matching and safety triage only with evaluation and human review. Keep deterministic fallback available.
**Gate:** provider outage falls back cleanly; invalid AI output is rejected; AI cannot perform privileged actions.

### D6 — Beta hardening
Test accessibility, low-bandwidth performance, localization, privacy controls, backups, monitoring, abuse handling and incident procedures before expanding beyond a small beta.
**Gate:** regression, security, restore, moderation and cost checks pass.

## Definition of done
Every feature needs a real user flow, both paths tested, auth/privacy checks, loading/empty/offline/error/retry states, mobile and desktop checks, and passing acceptance tests before it is marked complete.

## Non-negotiable rules
- No guaranteed-income promises or pay-to-unlock earning.
- No “verified job” label without trusted verification data.
- No “payout complete” state without payment-provider confirmation.
- No secrets or privileged tokens in frontend files or Git history.
- AI alone cannot make irreversible moderation, employment, identity or payment decisions.
- Consent, block/report, account deletion and human escalation must be discoverable.

## Current status
Earnova AI is currently a static front-end preview. This document is a target architecture and delivery plan, not a claim that authentication, shared database, public video storage, live messaging, payments or AI agents are already implemented. Preserve the preview while adding production foundations incrementally.
