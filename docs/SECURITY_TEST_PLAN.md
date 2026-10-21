# Earnova AI — Security and RLS Test Plan

**Status:** Test plan only. These checks have not been executed against Supabase.
**Target:** A disposable, dedicated development project with no real user data.
**Never run this plan against production.** Never place service-role keys or database passwords in the browser or Git.

## Before applying SQL

- [ ] Confirm the Supabase project is a dedicated development project, not a production project.
- [ ] Confirm the project contains no important data; take a backup/export if anything exists.
- [ ] Review the complete bootstrap SQL and apply it only after PostgreSQL syntax and policy review.
- [ ] Create two ordinary test accounts, User A and User B. Do not give either an admin role.
- [ ] Keep the service-role key private. Use ordinary authenticated sessions for authorization tests.

## Required two-user tests

| Test | Action | Expected result |
|---|---|---|
| Profile ownership | User A updates A's profile | Allowed |
| Profile ownership | User A updates User B's profile | Denied |
| Role escalation | User A attempts to insert/update their own row in `user_roles` | Denied |
| Audit log privacy | Ordinary user reads `admin_audit_log` | Denied |
| Post ownership | User A creates/edits/deletes A's post | Allowed |
| Post ownership | User A edits/deletes User B's post | Denied |
| Follow ownership | User A follows/unfollows another account | Allowed when not blocked |
| No self-follow | User A follows User A | Denied |
| Reaction ownership | User A changes User B's reaction | Denied |
| Comment ownership | User A edits/deletes User B's comment | Denied |
| Block privacy | User A reads A's own block list | Allowed |
| Block privacy | User A reads User B's private block list | Denied |
| Reports privacy | User A submits a valid report | Allowed |
| Reports privacy | User A lists reports or changes moderation status | Denied |
| Block enforcement | A and B block each other in separate test runs; try reading posts and following/reacting/commenting | Blocked interactions must fail and blocked content must not be visible |
| Anonymous access | Unauthenticated client queries protected tables | Denied |
| Input constraints | Try empty post/comment, oversized text, invalid reaction/report reason | Denied |

## Important review findings before production

1. The current `profiles_select_authenticated` policy allows every authenticated user to read every column in `profiles`. Keep that table limited to intentionally public profile fields; move private data to a separate table with stricter policies before adding private profile information.
2. The current schema is a foundation, not a complete social app. It does not connect the frontend, configure Storage buckets, implement account deletion, or provide trusted moderation APIs.
3. RLS is not a substitute for server-side validation, rate limits, spam controls, audit logging, backups, and incident response.
4. Test block behavior in both directions. Also verify follow/reaction/comment writes against blocked accounts, not just feed reads.
5. Do not grant admin/moderator roles from client-side code. Role grants require a trusted, audited server-side process.

## Launch gate

Do not merge this security work into the production branch or connect the public frontend until the SQL has been reviewed, applied to a disposable dev project, and the tests above have passed. Record actual results and fix every failure before proceeding.
