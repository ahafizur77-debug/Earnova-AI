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

## Demo limitations
This is a **front-end prototype**, not a production multi-user social network. Sample profiles, job cards, messages, story circles, and trend counts are illustrative. Posts and interactions are stored locally in the current browser where supported; they are not synced to other people or devices. There is no real authentication, server-side database, upload pipeline, live messaging, AI model integration, payments, moderation dashboard, or verified job feed yet. Do not treat sample vacancies as real opportunities.

## Next production milestones
1. Choose backend and database; implement secure authentication, sessions, account recovery, and access controls.
2. Add API-backed profiles, posts, comments, follows, reactions, media upload/storage, and pagination.
3. Implement real-time messaging, notifications, block/report flows, moderation queues, and anti-spam controls.
4. Integrate verified job sources and employer verification; build safe application tracking.
5. Add privacy controls, data export/deletion, rate limits, audit logging, security tests, backups, and monitoring.
6. Add AI features only through server-side endpoints with rate limits, consent, and cost controls.

## Deploy
The static preview is deployed separately from MoneyMind AI using Render Static Sites. Root directory is the repository root and publish path is `.`. No build command is required.
