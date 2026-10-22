const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');

const migration = fs.readFileSync(path.join(__dirname, '../supabase/migrations/202610220002_jobs_companies_foundation.sql'), 'utf8');

test('jobs and companies tables enable RLS and constrain status values', () => {
  assert.match(migration, /create table if not exists public\.companies/i);
  assert.match(migration, /create table if not exists public\.jobs/i);
  assert.match(migration, /alter table public\.companies enable row level security/i);
  assert.match(migration, /alter table public\.jobs enable row level security/i);
  assert.match(migration, /verification_status in \('pending','verified','rejected','suspended'\)/i);
  assert.match(migration, /status in \('pending_review','published','rejected','expired','paused'\)/i);
});

test('only verified employers can expose published non-expired jobs publicly', () => {
  assert.match(migration, /status = 'published'[\s\S]*?expires_at is null or expires_at > now\(\)[\s\S]*?verification_status = 'verified'/i);
  assert.match(migration, /verification_status = 'pending'[\s\S]*?for insert to authenticated/i);
  assert.match(migration, /status = 'pending_review'[\s\S]*?for insert to authenticated/i);
});

test('employers cannot self-approve listings through client policies', () => {
  assert.match(migration, /jobs_employer_insert_pending[\s\S]*?status = 'pending_review'/i);
  assert.match(migration, /jobs_employer_update_pending[\s\S]*?status in \('pending_review','paused'\)/i);
  assert.doesNotMatch(migration, /create policy[^;]+for update[^;]+with check[^;]*status\s*=\s*'published'/i);
});

test('salary, listing source and text inputs have database constraints', () => {
  assert.match(migration, /salary_min is null or salary_min >= 0/i);
  assert.match(migration, /salary_max is null or salary_max >= 0/i);
  assert.match(migration, /salary_max >= salary_min/i);
  assert.match(migration, /source_type = 'employer_submitted' or source_url is not null/i);
  assert.match(migration, /char_length\(trim\(name\)\) between 2 and 160/i);
  assert.match(migration, /char_length\(trim\(description\)\) between 20 and 12000/i);
});
