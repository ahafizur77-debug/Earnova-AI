# Earnova AI — Community Preview

Earnova is an early-stage community/social platform concept for sharing progress, discovering people, and exploring career opportunities.

## Current front-end preview
- Responsive desktop and mobile layout
- Community feed tabs: For you, Following, Trending
- Stories-style row, profile preview, discover, sample jobs, messages and notifications views
- Create posts, appreciate/like, comment, save and share actions
- Browser-local persistence for prototype posts/follows/likes/saves
- Topic tags, search, accessibility labels, keyboard shortcut (Ctrl/Cmd + K)
- PWA manifest and app icon

## Theme engine
- App-wide light/dark/automatic appearance with approximate sunrise/sunset calculation after explicit location permission; configurable fallback times.
- Accent color presets and separate appearance per preview conversation.
- Preferences are currently stored in the browser on this device. Cross-device sync requires authentication, a database, and authorized preference APIs and is not yet implemented.

## Dual-engine architecture
Earnova's target is to pair optional AI assistance with a reliable rules/API fallback for each major feature. See [docs/DUAL_ENGINE_ARCHITECTURE.md](docs/DUAL_ENGINE_ARCHITECTURE.md) for the feature map, production architecture, delivery sequence, acceptance gates, and safety rules.

## Quality checks
- Dependency-free regression tests live in [tests/smoke.test.js](tests/smoke.test.js).
- GitHub Actions workflow at [.github/workflows/quality.yml](.github/workflows/quality.yml) is configured to run them with Node.js 22 on pushes and pull requests.
- The checks cover source syntax, required UI entry points, theme preference keys, responsive CSS, and PWA manifest metadata. They are smoke checks, not full browser end-to-end tests.

## Current backend integration and demo limitations

This branch adds an initial Supabase email/password sign-up and sign-in flow plus a shared database-backed feed for posts, likes, comments, follows, and deleting one's own posts. The frontend uses only the Supabase publishable key; service-role credentials must never be placed in browser code. This integration is an early foundation and has **not** yet passed browser end-to-end testing with two separate accounts. Before merging or launching, verify the deployed Render URL in Supabase Auth redirect/URL configuration, test email confirmation and recovery flows, and validate cross-account visibility and ownership with separate accounts.

Earnova is still not a production-ready multi-user social network. Sample profiles, story circles, trend counts, and job cards remain illustrative; the signed-out preview stores interactions locally. There is no durable public Reels/video upload pipeline, production live messaging, server-side AI integration, payments, moderation dashboard, or verified job feed yet. Do not treat sample vacancies as real opportunities.

## Balanced production roadmap
1. Preserve existing features and establish automated regression checks.
2. Build secure authentication, sessions, recovery, API and database foundations.
3. Add account preferences and per-conversation themes with cross-device sync.
4. Move profiles, posts, follows, comments, reactions, Reels media, and notifications to real APIs.
5. Add real-time messaging, block/report flows, moderation queues, and anti-spam controls.
6. Integrate verified job sources and employer verification; build safe application tracking.
7. Add genuine earning workflows only with server-side transaction records and provider-confirmed payout status.
8. Add scoped AI agents through server-side endpoints with consent, output validation, rate limits, usage caps, and reliable fallbacks.
9. Add privacy controls, data export/deletion, security testing, backups, monitoring, localization, and a limited beta.

The full priority-wise plan and testable acceptance criteria are in [docs/IMPLEMENTATION_ROADMAP.md](docs/IMPLEMENTATION_ROADMAP.md). This is a roadmap, not a claim that all production capabilities exist. Keep Earnova AI separate from MoneyMind AI.

## Deploy
The static preview is deployed separately from MoneyMind AI using Render Static Sites. Root directory is the repository root and publish path is `.`. No build command is required.
