# Earnova AI — Agent Playbook

This file is the standing instruction set for any coding agent working in this repository. Follow it on every task.

## Mission
Build Earnova into a reliable, accessible, privacy-respecting social and creator platform with jobs and earning features, while preserving existing functionality and keeping launch costs at ₹0 where practical.

## Non-negotiable rules
1. Read README.md, docs/DUAL_ENGINE_ARCHITECTURE.md, docs/IMPLEMENTATION_ROADMAP.md, and docs/ADMIN_SECURITY.md before changing architecture.
2. Preserve existing working features. Prefer small, reviewable changes and regression tests over rewrites.
3. Never claim an integration, feature, deployment, or test works unless it was actually run and verified. Label mocks and demos honestly.
4. Do not introduce paid services, paid APIs, or new recurring costs without explicit user approval. Prefer open standards and free tiers; document limits and migration paths.
5. Never commit credentials, API keys, service-role keys, private tokens, real user data, or secrets. Never expose server secrets to browser code.
6. Never bypass authorization, security checks, CI, review requirements, or production protections to make a demo appear to work.
7. Never auto-merge or auto-deploy an unreviewed security-sensitive change. Scheduled automation may test, audit, and open a proposed PR; it must not silently ship application changes.
8. For all admin, identity, moderation, money, rewards, and payouts, the server is authoritative. AI suggestions cannot grant privileges, verify identity, set balances, approve payouts, or make final enforcement decisions alone.
9. Use dual-engine design: AI-enhanced path plus deterministic fallback. Core safety, authentication, permissions, ledger and basic navigation must work without AI keys.
10. Build mobile-first, accessible, low-bandwidth experiences; test responsive layouts, keyboard navigation, readable contrast, and graceful offline/slow-network behavior.

## Required workflow for every change
1. Inspect the current implementation and relevant tests before editing.
2. State the smallest safe scope; preserve compatibility and document migrations.
3. Implement the change and add regression tests for both expected behavior and failure/abuse cases.
4. Run syntax checks, unit/smoke tests, and any available security checks. Do not mark a check passed if it did not run.
5. Review the diff for exposed secrets, unsafe HTML, authorization gaps, privacy leaks, accessibility regressions, and unnecessary dependencies.
6. Update README/roadmap with what is implemented, what remains mocked, setup requirements, free-tier constraints, and rollback steps.
7. Report exact commit/PR links, tests and results, deployment status, known risks, and any action requiring the owner.

## Product priorities
1. Keep the current static preview stable.
2. Backend/auth foundation, row-level access control, secure admin roles and audit events.
3. Cross-device profiles and preferences; then posts, follows, comments, likes, messaging and reporting with abuse controls.
4. Real video upload/storage pipeline, Reels playback, creator tools and accessibility/performance.
5. Job listings with verification/reporting, fraud prevention and clear employer/worker boundaries.
6. Earning/rewards only after a server-side ledger, eligibility rules, fraud controls, provider verification, reconciliation, and legal/compliance review exist. Never simulate a payout as real.
7. Optional AI gateway/agents with quotas, timeouts, input validation, privacy controls and deterministic fallbacks.
8. Closed beta, threat model, load/performance checks, backup restore, incident response and launch checklist.

## Admin security requirements
- No public admin registration and no client-side role assignment.
- Verify session and role on every protected server endpoint; deny by default.
- Use MFA/passkeys where supported, rate limits, short-lived sessions, revocation, and re-authentication for high-risk actions.
- Log privileged changes without logging secrets or unnecessary personal data.
- Require confirmations/idempotency for destructive or money-related operations.
- Never use an obscured URL or frontend-only password as security.

## Automation policy
Automate repeatable checks, dependency update proposals, stale issue reporting, and scheduled quality audits. Pin major versions deliberately. Review automated dependency PRs and security-sensitive diffs before merging. No recursive agent loops, uncontrolled token spend, self-granted permissions, or silent production changes.

## Definition of done
A feature is done only when it is implemented, tested, documented, accessible, secure for its risk level, compatible with existing features, and accurately reflected in the roadmap. A green static smoke test alone does not establish production readiness.

## Current reality
The repository currently includes a static front-end preview and an initial SQL security schema. The SQL has not been applied to a live database; production authentication, server-enforced admin APIs, cross-device social data, real media storage and payment/payout processing must not be described as live until provisioned and verified.
