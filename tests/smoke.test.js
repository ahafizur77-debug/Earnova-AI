const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const vm = require('node:vm');

const root = path.resolve(__dirname, '..');
const read = (name) => fs.readFileSync(path.join(root, name), 'utf8');

test('main HTML keeps core assets and app entry points', () => {
  const html = read('index.html');
  for (const marker of [
    'style.css', 'theme.js', 'app.js', 'manifest.webmanifest',
    'id="storiesRow"', 'id="globalSearch"', 'id="composerDialog"',
    'id="genericDialog"', 'id="toastRegion"'
  ]) assert.ok(html.includes(marker), 'Missing expected UI marker: ' + marker);
});

test('browser scripts parse without syntax errors', () => {
  for (const file of ['app.js', 'theme.js']) {
    assert.doesNotThrow(() => new vm.Script(read(file), { filename: file }), file + ' must parse');
  }
});

test('primary navigation and core feature entry points remain present', () => {
  const html = read('index.html');
  for (const view of ['home', 'discover', 'reels', 'jobs', 'messages', 'notifications', 'saved', 'profile']) {
    assert.ok(html.includes('data-view="' + view + '"'), 'Missing navigation view: ' + view);
  }
  const app = read('app.js');
  for (const marker of ['create-post', 'follow', 'comment', 'save', 'messages', 'notifications']) {
    assert.ok(app.includes(marker), 'Missing expected app interaction: ' + marker);
  }
});

test('theme engine keeps local fallback and per-chat preference support', () => {
  const theme = read('theme.js');
  assert.ok(theme.includes('earnova-theme-v1'), 'Missing app theme storage key');
  assert.ok(theme.includes('earnova-chat-themes-v1'), 'Missing per-chat theme storage key');
  assert.ok(theme.includes('localStorage'), 'Local fallback should remain available');
  assert.ok(theme.includes('sunrise') && theme.includes('sunset'), 'Sunrise/sunset support should remain');
});

test('responsive styling and PWA manifest remain available', () => {
  const css = read('style.css');
  assert.match(css, /@media\s*\(/, 'Responsive media queries should remain');
  const manifest = JSON.parse(read('manifest.webmanifest'));
  assert.equal(manifest.name, 'Earnova Community');
  assert.equal(manifest.display, 'standalone');
});

test('admin security foundation denies client-side role grants', () => {
  const sql = read('supabase/migrations/202610200001_core_security.sql');
  assert.ok(sql.includes('enable row level security'), 'RLS must be enabled');
  assert.ok(sql.includes('user_roles_select_self_or_admin'), 'Role reads must be scoped');
  assert.ok(!/create policy[^;]+on public\\.user_roles for (insert|update|delete)/is.test(sql),
    'Clients must not receive role-grant or role-edit policies');
  assert.ok(sql.includes("public.has_earnova_role('admin')"), 'Admin data must require an admin role');
  const doc = read('docs/ADMIN_SECURITY.md');
  assert.ok(doc.includes('No public admin signup'), 'Admin bootstrap restrictions must be documented');
  assert.ok(doc.includes('Secrets never live in Git'), 'Secret handling rules must be documented');
});
