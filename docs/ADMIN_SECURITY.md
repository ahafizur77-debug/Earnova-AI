# Earnova AI — Admin Panel Security Standard

## Security objective
The admin panel must be private and server-authorized. A hidden URL, obscure button, client-side password, or JavaScript flag is not an admin security boundary.

## Required controls before launch
1. **No public admin signup.** All new accounts start as ordinary users. Admin roles are granted only by a trusted operator workflow, never from a browser request or editable profile field.
2. **Server-side authorization on every admin API.** Check a verified authenticated session and the role from the database on every request. Deny by default. Hiding admin UI is only a usability measure.
3. **Strong authentication.** Require MFA/passkey where supported for admin accounts, short-lived sessions, secure recovery, session revocation, and re-authentication for high-risk actions.
4. **Secrets never live in Git or frontend assets.** Store server credentials in the hosting provider's secret environment settings. Never expose a database service-role key, JWT signing secret, OAuth client secret, or payment secret in HTML/JS, public config, logs, or client bundles.
5. **Least privilege.** Separate user, moderator, support, and admin capabilities. Do not share accounts. Use a dedicated emergency/break-glass procedure and rotate credentials after suspected exposure.
6. **Audit trail.** Record actor, action, target, timestamp, request/correlation ID, and minimal metadata. Restrict audit access to authorized admins; do not log passwords, tokens, full payment credentials, or unnecessary personal data.
7. **Abuse resistance.** Rate-limit login and sensitive actions, protect sessions against CSRF where cookie-based, validate every input, use safe output encoding, and return generic authentication errors.
8. **High-risk operations.** Require confirmation and, where appropriate, re-authentication/dual approval for role grants, payouts, bulk bans, data exports, and destructive actions. Use idempotency for money-related operations.
9. **Recovery and monitoring.** Alert on repeated failures, new admin grants, unusual exports, and sensitive changes. Test backup restoration and have a documented incident/credential-rotation plan.
10. **Privacy.** Limit access to user data, retain only what is necessary, and provide account export/deletion and complaint workflows before broad launch.

## Initial database foundation
The migration at supabase/migrations/202610200001_core_security.sql creates profiles, privileged role assignments, and an admin audit table with row-level security. The SQL deliberately provides no client-side role-grant policy. It is a starting migration, not proof that a Supabase project has been created or configured.

## First-admin bootstrap
Do not place an initial admin password or secret in source code. After the backend is provisioned, create the account through the identity provider, verify the account out-of-band, and grant the admin role through a one-time trusted operator procedure. Log the grant, remove/disable the bootstrap path, and test that an ordinary account cannot self-promote. Never send credentials in chat or commit them to Git.

## Launch acceptance tests
- Anonymous requests to every admin API return 401/403 and reveal no private data.
- An ordinary user cannot open admin data by changing the URL, request body, headers, or user ID.
- An ordinary user cannot insert/update/delete their role or grant a role to another user.
- A moderator cannot perform admin-only actions.
- Revoking an admin role takes effect on subsequent requests; active sessions can be revoked.
- Sensitive actions create audit events and cannot be replayed to cause duplicate payments or changes.
- Secrets are absent from repository history, built frontend assets, browser network responses, and logs.
- MFA/recovery, rate limits, backup restore, and incident response have been tested.

## Current status
Earnova is currently a static front-end preview. No real admin dashboard, authentication, backend authorization, MFA, or operational audit pipeline is deployed yet. Do not expose an admin panel publicly until the backend controls above exist and pass tests.
