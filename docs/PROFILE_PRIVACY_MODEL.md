# Earnova AI — Profile privacy model

**Status:** design guardrail only. No database or frontend changes are applied by this document.

## Separate public identity from private account data

The existing `public.profiles` table is intended only for fields that a signed-in user may discover on another user's profile:

- `id` — account identifier
- `display_name` — public display name
- `avatar_url` — public avatar URL
- `created_at` / `updated_at` — profile timestamps

The current authenticated SELECT policy permits every signed-in account to read rows in this table. That is acceptable only while the table contains public-facing fields. **Do not add email, phone, date of birth, precise location, private job-search status, identity documents, payment details, private notes, or security settings to this table.**

## Where private data belongs

Before introducing private fields, design a separate table or server-only store with:

- one row per account, keyed to `auth.users.id`;
- RLS enabled and SELECT/INSERT/UPDATE restricted to `auth.uid() = user_id`;
- no public or anonymous read policy;
- explicit server-side validation and a documented retention/deletion policy;
- privileged access only through reviewed server-side operations where required.

Do not copy authentication email into a public profile merely for convenience. Use Supabase Auth's supported account APIs for account email and recovery flows.

## Required review before connecting the frontend

1. Inspect the exact target project and existing tables; do not assume a dashboard label proves it is disposable.
2. Apply schema changes only to the confirmed dedicated development project after reviewing the SQL.
3. Create two ordinary test accounts and verify account A cannot read or update account B's private rows.
4. Verify anonymous clients cannot read protected data and no client can grant itself a privileged role.
5. Test deletion/export and failure paths before adding real personal data.
6. Keep service-role keys and database passwords on the server only.

## Scope and current truth

This document is a guardrail, not an implemented private-data store. Earnova's current frontend remains a static prototype with browser-local interactions. It is not yet connected to a shared database or real authentication. SQL structure checks in GitHub Actions are not a substitute for PostgreSQL execution or two-account RLS tests.
