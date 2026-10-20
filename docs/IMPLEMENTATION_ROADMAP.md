# Earnova AI — Product & Implementation Roadmap

This roadmap extends the existing Earnova AI community preview. Preserve the current responsive feed, stories, profiles, discovery, sample jobs, messages, notifications, post actions, topic tags, search, accessibility, keyboard shortcut, PWA manifest, and app icon while implementing new work incrementally.

## Product vision

Earnova AI aims to combine social posts and short-form video, genuine job and skills opportunities, creator tools, and transparent earning features. Build reliable social foundations and trust/safety before monetization. Keep this project separate from MoneyMind AI.

## Current state and honest limitations

The repository currently contains a front-end prototype. Browser-local state is not multi-user persistence. Sample job listings are illustrative. Real authentication, API-backed multi-device data, durable video storage, production messaging, AI integrations, payment processing, and a verified-job pipeline are not yet implemented. Do not describe a prototype feature as production-ready until its acceptance tests pass.

## Priority order

### P0 — Preserve and stabilize the foundation
- [ ] Audit current routes, event handlers, responsive layout, and local-storage keys before editing.
- [ ] Keep existing feed, stories, profile, discovery, jobs preview, messages, notifications, post actions, search, keyboard shortcut, PWA assets, and mobile navigation working.
- [ ] Add regression checks for desktop and mobile navigation and browser refresh.
- [ ] Add clear empty, loading, and error states without replacing existing features.

**Acceptance checks**
- Existing screens still open on mobile and desktop.
- Existing prototype interactions still work after the theme engine is added.
- No secrets or provider credentials are placed in frontend code.

### P1 — Theme engine (requested feature)

#### A. Automatic sunrise/sunset app theme
- [ ] Add Settings controls: Automatic (sunrise/sunset), Light, Dark, and Manual/custom accent where supported.
- [ ] In automatic mode, use the device's local sunrise/sunset data for the user's selected location.
- [ ] Request browser location permission only after a clear user action and explain why it is needed.
- [ ] If location permission is denied or location data is unavailable, provide a manual city/time-zone fallback; do not silently track location.
- [ ] Recalculate the theme when the day changes, location/time-zone changes, or the app becomes active again. Avoid frequent visual flicker.
- [ ] Use accessible color tokens for backgrounds, text, borders, focus rings, and buttons; check contrast in both themes.
- [ ] Persist the user's global theme preference locally immediately and sync it to the account when signed in.
- [ ] Manual Light/Dark selection must override automatic mode until the user switches back to Automatic.

**Acceptance checks**
1. In automatic mode, simulate sunrise and sunset times and verify light/dark transition at the configured boundary.
2. Denying location permission does not break the app; the manual fallback is usable.
3. Refreshing the app retains the selected mode.
4. Changing theme does not reset the current route, scroll unnecessarily, or erase draft content.
5. Keyboard focus, buttons, form fields, Reels, Jobs, and chat remain readable in both themes.

#### B. Separate theme per chat
- [ ] Add a chat appearance menu with supported wallpaper/background and accent presets.
- [ ] Store theme settings by conversation ID, not as one global chat style.
- [ ] Keep chat content, timestamps, unread state, and message actions independent of appearance.
- [ ] Use readable foreground/background combinations and a reset-to-default option.
- [ ] Do not create a separate theme for a conversation until the conversation has a stable ID.
- [ ] In the current prototype, show local-only behavior clearly until server-backed conversations exist.

**Acceptance checks**
1. Change Chat A's theme; Chat B and the app-wide theme remain unchanged.
2. Refreshing the same browser retains each chat's separate theme.
3. Resetting one chat affects only that chat.
4. Long messages, links, errors, selected text, and keyboard focus remain accessible in every preset.

#### C. Cross-device theme synchronization
- [ ] Treat server-side account preferences as the source of truth when authenticated; browser storage is a cache/fallback, not the shared database.
- [ ] Suggested account preference fields: theme_mode, theme_accent, theme_location_mode, theme_timezone, updated_at.
- [ ] Suggested conversation appearance table: user_id, conversation_id, wallpaper_id, accent_id, updated_at; enforce authorization so users can only modify their own preferences.
- [ ] Add authenticated API endpoints to read/update account theme preferences and per-conversation appearance.
- [ ] Validate preset IDs and mode values server-side; never accept arbitrary CSS or HTML from preference fields.
- [ ] Resolve conflicts with a documented last-write-wins policy using server timestamps, or a version field if needed. Avoid overwriting newer server settings with stale cached data.
- [ ] When offline, apply the last cached preference and queue a safe update for the next successful sync.
- [ ] If the user is signed out, keep preferences local and explain that cross-device sync requires signing in.

**Acceptance checks**
1. Sign in on Device A, set global mode and Chat A appearance, then sign in to the same account on Device B; both preferences load from the server.
2. Changing Chat A on Device B updates Chat A on Device A after refresh/re-fetch; Chat B remains unchanged.
3. User A cannot read or change User B's preferences by changing IDs in API requests.
4. A stale offline preference does not silently overwrite a newer server value.
5. API failure falls back to cached preferences without breaking navigation or messaging.

**Dependency note:** true cross-device synchronization cannot be delivered by localStorage alone. It depends on real authentication, a database, and authorized API endpoints; build it alongside the backend foundation.

### P2 — Real social and Reels backend
- [ ] Add API-backed profiles, posts, follows, reactions, comments, saves, pagination, and notifications.
- [ ] Add validated video upload, durable object storage, thumbnails, processing states, and media delivery.
- [ ] Add block/report workflows, moderation queues, anti-spam rate limits, and copyright complaint handling.

**Acceptance checks**
- A post or uploaded Reel appears to a second authenticated account and remains after refresh.
- Invalid file types/sizes are rejected with a clear message.
- Failed uploads can be retried without duplicating posts.

### P3 — Genuine jobs and career tools
- [ ] Add employer accounts, employer verification, job posting review, job search filters, applications, and status tracking.
- [ ] Add resume and interview assistance only through server-side AI endpoints with rate limits and clear AI-generated labeling.
- [ ] Mark sample jobs as demo data until a listing is verified and active.

**Acceptance checks**
- Unverified employers cannot publish public jobs.
- Candidates can view application status and report suspicious listings.
- Job descriptions and AI suggestions do not invent guaranteed outcomes.

### P4 — Trustworthy earning and payments
- [ ] Start with real paid work and verified brand campaigns; define eligibility and fraud checks before creator rewards.
- [ ] Use a server-side ledger with immutable transaction records and idempotency keys.
- [ ] Integrate a payment provider only after merchant approval, country availability, fees, KYC, tax, and legal requirements are reviewed.
- [ ] Display payout as complete only after provider confirmation; support pending, failed, reversed, and disputed states.
- [ ] Never promise guaranteed income or require users to pay to unlock earnings.

**Acceptance checks**
- Every balance change has a traceable transaction and source.
- Replayed payout requests do not double-pay.
- Provider failure never displays a false successful payout.

### P5 — AI agents and global readiness
- [ ] Introduce a server-side orchestrator and scoped agents for content, language, job matching, resumes, career mentoring, support, safety, rewards explanations, and admin analytics.
- [ ] Use permission checks, output validation, rate limits, usage caps, audit logs, and human review for high-impact actions.
- [ ] Add localization, accessible low-bandwidth design, privacy controls, data export/deletion, and region-specific payment/job availability.
- [ ] Pilot with a limited beta before expanding to additional countries.

**Acceptance checks**
- Agents cannot perform privileged account, moderation, or payment actions without authorization.
- Job availability and payment status are checked against trusted systems, not guessed by AI.
- A regional launch checklist confirms language, moderation, payment availability, privacy, and support readiness.

## Theme implementation sequence

1. Audit existing CSS tokens, chat/message UI, settings, and current browser-local persistence.
2. Introduce theme tokens and explicit theme mode without changing existing routes or components unnecessarily.
3. Add automatic sunrise/sunset selection with location consent and a manual fallback.
4. Add per-conversation appearance keyed by stable conversation ID.
5. Add database migrations and authenticated preference APIs once auth/database are available.
6. Add cross-device synchronization and offline conflict handling.
7. Run the acceptance checks above plus mobile/desktop regression tests before deploying.

## Delivery discipline

- Work in small commits and preserve a known-good deployment.
- Never overwrite existing features without first inspecting their implementation.
- Keep secrets in deployment environment variables.
- Test the actual deployed site after each milestone.
- Mark items complete only after tests pass; a roadmap entry is not proof of implementation.
