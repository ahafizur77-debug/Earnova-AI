const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');

const migration = fs.readFileSync(path.join(__dirname, '../supabase/migrations/202610220002_jobs_companies_foundation.sql'), 'utf8');
const policy = (name) => {
  const start = migration.toLowerCase().indexOf('create policy ' + name.toLowerCase());
  if (start < 0) return '';
  const end = migration.indexOf(';', start);
  return migration.slice(start, end < 0 ? migration.length : end + 1);
};

test('jobs and companies tables enable RLS and constrain status values', () => {
  assert.ok(migration.includes('create table if not exists public.companies'));
  assert.ok(migration.includes('create table if not exists public.jobs'));
  assert.ok(migration.includes('alter table public.companies enable row level security'));
  assert.ok(migration.includes('alter table public.jobs enable row level security'));
  assert.ok(migration.includes("verification_status in ('pending','verified','rejected','suspended')"));
  assert.ok(migration.includes("status in ('pending_review','published','rejected','expired','paused')"));
});

test('only verified employers can expose published non-expired jobs publicly', () => {
  const publicRead = policy('jobs_public_published_verified');
  assert.ok(publicRead.includes("status = 'published'"));
  assert.ok(publicRead.includes('expires_at > now()'));
  assert.ok(publicRead.includes("c.verification_status = 'verified'"));
  const companyInsert = policy('companies_owner_insert_pending');
  const jobInsert = policy('jobs_employer_insert_pending');
  assert.ok(companyInsert.includes('for insert to authenticated'));
  assert.ok(companyInsert.includes("verification_status = 'pending'"));
  assert.ok(jobInsert.includes('for insert to authenticated'));
  assert.ok(jobInsert.includes("status = 'pending_review'"));
});

test('employers cannot self-approve listings through client policies', () => {
  const jobInsert = policy('jobs_employer_insert_pending');
  const jobUpdate = policy('jobs_employer_update_pending');
  assert.ok(jobInsert.includes("status = 'pending_review'"));
  assert.ok(jobUpdate.includes("status in ('pending_review','paused')"));
  assert.ok(!jobUpdate.includes("status = 'published'"));
});

test('salary, listing source and text inputs have database constraints', () => {
  assert.ok(migration.includes('salary_min numeric(12,2)'));
  assert.ok(migration.includes('salary_min >= 0'));
  assert.ok(migration.includes('salary_max >= 0'));
  assert.ok(migration.includes('salary_max >= salary_min'));
  assert.ok(migration.includes("source_type = 'employer_submitted' or source_url is not null"));
  assert.ok(migration.includes('char_length(trim(name)) between 2 and 160'));
  assert.ok(migration.includes('char_length(trim(description)) between 20 and 12000'));
});
