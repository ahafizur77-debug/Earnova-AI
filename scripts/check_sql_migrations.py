#!/usr/bin/env python3
"""Offline structural checks for Earnova SQL migrations.

These checks catch accidental regressions; they do NOT parse SQL or prove RLS behavior.
Run against a disposable Supabase/PostgreSQL database and execute SECURITY_TEST_PLAN.md
before any real backend connection or production launch.
"""
from pathlib import Path
import re
import sys

ROOT = Path(__file__).resolve().parents[1]
MIGRATIONS = [
    ROOT / "supabase/migrations/202610200001_core_security.sql",
    ROOT / "supabase/migrations/202610200002_social_data_foundation.sql",
    ROOT / "supabase/migrations/202610210001_social_rls_hardening.sql",
]
BOOTSTRAP = ROOT / "supabase/earnova_dev_bootstrap.sql"


def require(condition: bool, message: str) -> None:
    if not condition:
        print(f"FAIL: {message}")
        sys.exit_code = 1
    else:
        print(f"PASS: {message}")


sys.exit_code = 0
for path in MIGRATIONS:
    require(path.is_file(), f"migration exists: {path.relative_to(ROOT)}")

if all(path.is_file() for path in MIGRATIONS):
    core, social, hardening = [p.read_text(encoding="utf-8") for p in MIGRATIONS]
    profile_table = re.search(r"create\\s+table\\s+if\\s+not\\s+exists\\s+public\\.profiles\\s*\\((.*?)\\n\\);", core, re.I | re.S)
    require(profile_table is not None, "public profiles table declaration exists")
    if profile_table:
        forbidden_profile_fields = ("email", "phone", "date_of_birth", "location", "password", "payment", "identity_document", "private_notes")
        fields = profile_table.group(1).lower()
        require(
            not any(re.search(rf"\\b{re.escape(field)}\\b", fields) for field in forbidden_profile_fields),
            "public profiles schema contains no known private account fields",
        )
    privacy_doc = ROOT / "docs/PROFILE_PRIVACY_MODEL.md"
    require(privacy_doc.is_file(), "profile privacy model documented")

    for table in ("profiles", "user_roles", "admin_audit_log"):
        require(
            re.search(rf"alter\s+table\s+public\.{table}\s+enable\s+row\s+level\s+security", core, re.I) is not None,
            f"RLS enabled on {table}",
        )
    for table in ("posts", "follows", "post_reactions", "post_comments", "user_blocks", "content_reports"):
        require(
            re.search(rf"alter\s+table\s+public\.{table}\s+enable\s+row\s+level\s+security", social, re.I) is not None,
            f"RLS enabled on {table}",
        )

    require(
        re.search(r"create\s+policy\s+user_roles_(?:insert|update|delete)\w*", core, re.I) is None,
        "no client write policy for privileged user_roles",
    )
    require(
        re.search(r"create\s+policy\s+reports_(?:select|update|delete)\w*", social, re.I) is None,
        "no client read/update/delete policy for moderation reports",
    )
    require(
        "set search_path = ''" in hardening.lower(),
        "security-definer block helper pins an empty search_path",
    )
    for policy in ("follows_insert_self", "reactions_insert_self", "reactions_update_self", "comments_insert_self", "comments_update_self"):
        match = re.search(
            rf"create\s+policy\s+{policy}\b.*?;", hardening, re.I | re.S
        )
        require(
            match is not None and "earnova_users_block_each_other" in match.group(0),
            f"{policy} checks block rules",
        )

if BOOTSTRAP.is_file() and all(path.is_file() for path in MIGRATIONS):
    combined = BOOTSTRAP.read_text(encoding="utf-8")
    positions = [combined.find(path.name) for path in MIGRATIONS]
    require(all(pos >= 0 for pos in positions), "development bootstrap references all migrations")
    require(positions == sorted(positions), "development bootstrap lists migrations in dependency order")
else:
    require(False, "development bootstrap exists for migration-order check")

if sys.exit_code:
    print("\nStatic SQL checks failed. These are not a database integration test.")
    sys.exit(1)
print("\nStatic SQL checks passed. SQL syntax and runtime RLS behavior remain unverified.")
