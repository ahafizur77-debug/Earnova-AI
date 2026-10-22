# Earnova AI — development database setup checklist

This guide is for a **separate development-only Supabase project**. It does not create a project, apply migrations, connect the preview, or deploy anything.

## Before creating a project

- Use a project name that clearly says `earnova-dev`.
- Check Supabase's current free-plan limits, pausing rules, data-retention terms, and regional availability before relying on it. Free tiers and quotas can change.
- Do not use real user data, production credentials, or payment information in development.
- Keep the existing Render Static Site unchanged. The frontend must remain a static preview until a backend integration is intentionally reviewed.

## Credential handling

- The Supabase project URL and publishable/anon key are client identifiers, not substitutes for authorization. They may only be used in a browser when Row Level Security (RLS) and policies are correctly configured.
- Never put a service-role key, database password, JWT signing secret, or other privileged credential in `index.html`, `app.js`, committed files, screenshots, or chat.
- Store server-only secrets in a backend provider's private environment settings, never in the static frontend.
- If a privileged secret is accidentally exposed, rotate it immediately.

## Migration review — do not run on production

The social schema draft currently lives at:

- `supabase/migrations/202610200001_core_security.sql`
- `supabase/migrations/202610200002_social_data_foundation.sql`
- `supabase/migrations/202610210001_social_rls_hardening.sql` (follow-up hardening; apply third)

Before applying anything to a development database:

1. Read both migrations from top to bottom and confirm the intended schema.
2. Check that the SQL parses against the current Supabase/PostgreSQL version. The repository smoke tests are text-level regression checks; they are not a substitute for running the migration in a disposable database.
3. Review every RLS policy using at least two test accounts, including blocks in both directions, self-only writes, and report privacy.
4. Apply only to the dedicated development project after review, then test CRUD operations as authenticated and unauthenticated users.
5. Do not point the public static preview at the project until API integration, authorization tests, and data deletion/backup procedures have been reviewed.

## Next engineering tasks

- Add a server-side API boundary and typed request/response contracts.
- Add integration tests that run against an isolated test database.
- Implement signup/login/session recovery and profile ownership checks.
- Connect the UI only after the backend endpoints and authorization tests pass.
- Keep deployment, public launch, payments, and production database changes blocked pending explicit approval.

## Current status (verified 2026-10-21)

The connected development project `ujaxlwtyaopvdekghzgo` is active in `ap-south-1`. The following schema changes were applied directly through the Supabase connection during development:
- Core security and social data foundation migrations.
- Social RLS block-check hardening.
- Internal helper-function restrictions and least-privilege table grants.

Verification observed 9 public tables with RLS enabled and the Supabase security advisor returned no current security lints at the time of the check. This is a structural check only: it does **not** prove all policy behavior is correct.

Important remaining gaps:
- No two-account integration tests have been completed.
- The static Render frontend is not connected to Supabase Auth or the database.
- No real account signup/login, cross-user post sharing, block behavior, or privacy tests have been completed.
- The repository migration history and the connected project's applied migration history were created through different paths; reconcile them before using automated migration tooling against this project.
- No production deployment or public launch has been approved by this document.

Never put a service-role/secret key in the browser, repository, screenshots, or chat. Keep the existing Render preview clearly labelled as a prototype until the gaps above are closed.


## Browser auth integration added

The prototype now includes a browser-side Supabase client, email/password sign-in and sign-up, profile upsert, and database-backed post creation/listing/reactions/comments. The browser config contains only the project's **publishable** key. Never replace it with a service-role or secret key.

Before testing on the Render preview:
1. In Supabase Dashboard, open **Authentication → URL Configuration**.
2. Set the Site URL to `https://earnova-ai.onrender.com`.
3. Add `https://earnova-ai.onrender.com/**` to Redirect URLs (and add the exact local development URL only if you use one).
4. In **Authentication → Providers → Email**, decide whether email confirmation stays enabled. If enabled, test with an email you can access.
5. Ensure the Render static site is deployed from the branch containing `index.html`, `supabase-config.js`, and `auth.js`; the current live URL may still be serving the main branch until the PR is merged.
6. Test with two different email accounts: create/confirm/sign in, publish a post, verify it appears for the other account, react/comment, sign out, and confirm unauthenticated writes are rejected.
7. Check browser console and Supabase Auth/Postgres logs for errors. Do not paste passwords, OTPs, access tokens, or secret keys into chat.

## Remaining release gates

- No real browser-based two-account test has yet been run.
- Follow suggestions, messaging, jobs, media upload, moderation dashboard, payment, and n8n are still preview/unconnected features.
- n8n workflows could not be inspected or activated via a direct connection in this session.
- The UI must continue to be described as a prototype until the tests above pass.
