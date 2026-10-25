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
  for (const file of ['app.js', 'theme.js', 'auth.js']) {
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

test('social schema has constrained data, ownership policies, and report privacy', () => {
  const sql = read('supabase/migrations/202610200002_social_data_foundation.sql');
  for (const marker of [
    'create table if not exists public.posts',
    'create table if not exists public.follows',
    'create table if not exists public.post_reactions',
    'create table if not exists public.post_comments',
    'create table if not exists public.user_blocks',
    'create table if not exists public.content_reports',
    'alter table public.posts enable row level security',
    'posts_insert_own',
    'follows_insert_self',
    'reactions_insert_self',
    'comments_insert_self',
    'blocks_insert_self',
    'reports_insert_self',
    'constraint follows_no_self_follow',
    'constraint user_blocks_no_self_block',
    'No client SELECT/UPDATE/DELETE policies'
  ]) assert.ok(sql.includes(marker), 'Missing social security requirement: ' + marker);
  assert.ok(!/create policy[^;]+on public\\.content_reports for (select|update|delete)/is.test(sql),
    'Client users must not browse or alter moderation reports');
  assert.ok(sql.includes('char_length(body) <= 5000'), 'Post body must have a server-side length limit');
  assert.ok(sql.includes('char_length(trim(body)) between 1 and 2000'), 'Comment body must be validated');
  assert.ok(sql.includes('public.earnova_users_block_each_other'), 'Block checks must use the RLS-safe helper');
  assert.ok(sql.includes('security definer'), 'The block helper must be able to check both directions despite row-level policies');
  assert.ok(sql.includes('set search_path = public, pg_temp'), 'The security-definer helper must pin its search path');
  assert.ok(sql.includes('as $$\\n  select case') || sql.includes('as $$\n  select case'), 'The SQL function body must use valid double-dollar quoting');
  assert.ok(sql.includes('\\n$$;') || sql.includes('\n$$;'), 'The SQL function body must close its double-dollar quote');
  assert.ok(sql.includes('((select auth.uid()) <> p_user_a and (select auth.uid()) <> p_user_b)'), 'Block helper must not disclose block status for unrelated users');
  assert.ok(sql.includes('revoke all on function public.earnova_users_block_each_other(uuid, uuid) from public'), 'Block helper execution must not be public');
  assert.ok(sql.includes('grant execute on function public.earnova_users_block_each_other(uuid, uuid) to authenticated'), 'Only authenticated users should call the block helper');
  assert.ok(sql.includes('not public.earnova_users_block_each_other((select auth.uid()), posts.author_id)'), 'Post reads must account for blocks');
  assert.ok(sql.includes('post_reactions.user_id'), 'Reaction reads must account for blocks');
  assert.ok(sql.includes('post_comments.author_id'), 'Comment reads must account for blocks');
});


test('Supabase account integration uses publishable credentials and shared social APIs', () => {
  const auth = read('auth.js');
  assert.ok(auth.includes('sb_publishable_'), 'Frontend must use a publishable key');
  assert.ok(!auth.includes('service_role'), 'Service-role credentials must never be in frontend code');
  for (const marker of [
    'signUp({email,password', 'signInWithPassword({email,password',
    "from('profiles').upsert", "from('posts').select", "from('posts').insert",
    "from('post_reactions')", "from('post_comments')", "from('follows')",
    'stopImmediatePropagation', 'persistSession:true', 'resetPasswordForEmail', 'earnovaPasswordReset'
  ]) assert.ok(auth.includes(marker), 'Missing account/social integration marker: ' + marker);
  assert.ok(auth.includes("title.dataset.mode==='account'"), 'Account menu must route its action to sign-out');
  assert.ok(!auth.includes("$('#earnovaAuthToggle').onclick="), 'Account menu must not register a competing sign-out handler');
  assert.ok(auth.includes("$('#composerDialog .modal-note')"), 'Shared-feed mode must not show the local-only preview warning');
});


test('Reels upload uses authenticated Supabase Storage and owner-scoped RLS', () => {
  const app = read('app.js');
  const auth = read('auth.js');
  const migration = read('supabase/migrations/20261025113000_reels_storage.sql');
  for (const marker of [
    'id="reelCloudFeed"', 'id="reelFile"', 'id="reelPublish"',
    'async function loadCloudReels()', 'async function uploadCloudReel()',
    "client.storage.from('earnova-reels').upload", "getPublicUrl(path)",
    'file.size>50*1024*1024', "if(a==='reel-publish')"
  ]) assert.ok(app.includes(marker), 'Missing Reels upload marker: ' + marker);
  assert.ok(auth.includes('window.earnovaClient=client'), 'Reels must reuse the signed-in Supabase client');
  for (const marker of [
    "values ('earnova-reels', 'earnova-reels', true",
    'alter table public.reels enable row level security',
    'author_id = (select auth.uid())',
    "(storage.foldername(name))[1] = (select auth.uid())::text"
  ]) assert.ok(migration.includes(marker), 'Missing Reels security marker: ' + marker);
  assert.ok(!/service_role|sb_secret_/i.test(app + auth), 'No privileged Supabase key may ship in browser code');
});

test('direct messaging schema scopes access and private media view limits', () => {
  const sql = read('supabase/migrations/202610250001_disappearing_direct_messages.sql');
  for (const marker of [
    'alter table public.dm_messages enable row level security',
    'private.is_dm_member(conversation_id)',
    'create_direct_conversation(target_user uuid)',
    'consume_disappearing_media(message_uuid uuid)',
    "bucket_id='earnova-dm-media'",
    "msg.media_mode='view_once'",
    "msg.media_mode='view_twice'",
    'revoke all on function public.touch_dm_conversation_on_message() from public, anon, authenticated'
  ]) assert.ok(sql.includes(marker), 'Missing DM security control: ' + marker);
  assert.ok(!sql.includes('public.is_dm_member'), 'Membership helper must not be exposed in the public API schema');
});

test('direct messaging UI exposes private chat and disappearing-media modes', () => {
  const app = read('app.js');
  const css = read('style.css');
  for (const marker of [
    'renderDirectMessages()', 'create_direct_conversation', 'dm_conversation_members',
    'dm_messages', 'consume_disappearing_media', 'view_once', 'view_twice', 'unlimited',
    'earnova-dm-media', 'dm-view-media'
  ]) assert.ok(app.includes(marker), 'Missing direct-message behavior: ' + marker);
  for (const marker of ['dm-shell', 'dm-chat', 'dm-media-content', 'dm-expired']) {
    assert.ok(css.includes(marker), 'Missing direct-message style: ' + marker);
  }
});
