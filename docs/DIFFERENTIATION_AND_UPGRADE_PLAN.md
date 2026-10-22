# Earnova AI — Differentiation & Continuous Upgrade Plan

This plan sets a long-term direction for Earnova AI to become a useful, trustworthy, globally accessible social + opportunity platform. It is an ambition and engineering backlog, not a claim that these features already exist or a guarantee of overtaking Instagram, Facebook, or any other platform.

## Product principles

- **Useful before viral:** build features that help people learn, find work, create, collaborate, and earn transparently—not engagement tricks.
- **Privacy and user control:** clear consent, private-by-default controls where appropriate, export/delete controls, feed controls, and no secret tracking.
- **Safety by design:** block/report tools, anti-spam, scam detection, age-appropriate protections, moderation appeals, and human review for high-impact actions.
- **Accessible worldwide:** mobile-first performance, low-bandwidth mode, localization, captions, readable UI, and assistive-technology support.
- **Honest monetization:** no guaranteed earnings claims; show eligibility, fees, payout status, and reasons for holds clearly.
- **Incremental delivery:** preserve the current prototype and ship small, tested releases behind feature flags.

## Differentiators to build in stages

### Stage 1 — Reliable social foundation
- [ ] Secure signup, login, session recovery, and profile ownership.
- [ ] Server-backed feed, follows, posts, comments, reactions, and notifications.
- [ ] Block/report flows and moderator review with an audit trail.
- [ ] User-controlled feed: Following, chronological option, topic controls, mute/hide, and “why am I seeing this?”
- [ ] Media upload with file/type/size validation, safe storage rules, and abuse reporting.
- [ ] Export and account deletion workflows with clear retention disclosures.

### Stage 2 — AI that helps users make progress
- [ ] Optional AI career coach that turns a user's goals into an editable learning and job-search plan.
- [ ] Resume and portfolio helper with user approval before sharing or applying.
- [ ] Language and accessibility assistant: translation, captions, summaries, and low-bandwidth text mode.
- [ ] Creator tools for outlining, captioning, repurposing, and scheduling content with consent and attribution safeguards.
- [ ] AI output must be labeled where appropriate, checked for unsafe/scam content, rate-limited, and backed by a non-AI fallback.
- [ ] Never let an AI agent grant admin roles, approve payouts, or make irreversible account decisions by itself.

### Stage 3 — Real opportunities and transparent earnings
- [ ] Verified employer onboarding and a clear verification badge policy.
- [ ] Job feed with source, date checked, location, requirements, and a report-scam action.
- [ ] Application tracker with user-controlled reminders and status history.
- [ ] Creator monetization only after eligibility rules, provider integration, fraud controls, tax/legal review, and clear fee disclosures.
- [ ] Ledger-based earnings records; payouts must be confirmed by a payment provider before marked paid.
- [ ] No paid-to-get-a-job schemes, fake task rewards, or guaranteed income claims.

### Stage 4 — Rich media and community
- [ ] Short video/Reels with resumable uploads, adaptive playback, captions, and bandwidth-aware quality.
- [ ] Real-time messaging only after authorization, blocking, reporting, retention, and abuse-rate limits are tested.
- [ ] Communities, topic circles, collaborative posts, live events, and creator subscriptions based on validated demand.
- [ ] User controls for autoplay, recommendations, sensitive content, and notification frequency.
- [ ] Interoperable export of user-owned content in practical formats where legally and technically feasible.

### Stage 5 — Scale and reliability
- [ ] Automated tests for authorization, RLS, API contracts, mobile accessibility, and end-to-end critical flows.
- [ ] Performance budgets for low-end Android devices and slow connections.
- [ ] Backups and restore drills, monitoring, incident response, dependency updates, and security reviews.
- [ ] Privacy-preserving product analytics with documented retention and opt-out controls.
- [ ] Regional rollout, localization review, legal compliance, support processes, and a limited beta before wider launch.

## Continuous upgrade policy

For each release:
1. Create an issue describing the user problem, scope, risks, and measurable acceptance criteria.
2. Implement on a branch; do not silently alter production data or secrets.
3. Run regression, security, and accessibility checks.
4. Review database migrations and test them against a disposable development database.
5. Ship behind a feature flag or to a small beta when possible.
6. Monitor errors and user feedback; roll back if critical checks fail.
7. Update this plan and release notes with what actually shipped.

## Success measures

Track meaningful outcomes rather than raw screen time alone: successful job applications, completed learning plans, creator tool usefulness, verified opportunity quality, report-resolution time, scam prevalence, accessibility issues, app startup time, crash rate, and user-controlled retention/notification settings.

## Current status and safety gates

- This document is a roadmap only.
- The current web app remains a prototype until real backend integration and tests are complete.
- The SQL bootstrap file is for a dedicated development database only; review and test before execution.
- Do not run database changes against a production database.
- Do not merge or publish this roadmap as evidence that features are implemented.
