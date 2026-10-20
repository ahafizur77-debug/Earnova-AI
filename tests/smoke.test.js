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
