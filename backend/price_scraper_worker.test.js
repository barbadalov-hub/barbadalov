import { test } from 'node:test';
import assert from 'node:assert/strict';
import { parseIds, toKopecks, parseAtbHtml } from './price_scraper_worker.js';

test('toKopecks converts hryvnia to integer kopecks', () => {
  assert.equal(toKopecks('54.90'), 5490);
  assert.equal(toKopecks(12), 1200);
  assert.equal(toKopecks('0'), null);      // 0 -> falsy -> null by design
  assert.equal(toKopecks('abc'), null);    // NaN -> null
});

test('parseIds keeps known ids, drops junk, de-dups, sorts and caps', () => {
  assert.deepEqual(parseIds('eggs, milk , eggs'), ['eggs', 'milk']);
  assert.deepEqual(parseIds('eggs,unknown,rice'), ['eggs', 'rice']);
  assert.deepEqual(parseIds(''), []);
  assert.deepEqual(parseIds(null), []);
  // sorted order is stable regardless of input order
  assert.deepEqual(parseIds('rice,apple'), ['apple', 'rice']);
});

test('parseAtbHtml reads price from structured data or the price node', () => {
  assert.equal(parseAtbHtml('...\"price\":\"54.90\"...'), 5490);
  assert.equal(
    parseAtbHtml('<span class="atbproduct__price-number">1 299,00</span>'),
    129900,
  );
  assert.equal(parseAtbHtml('<div>no price here</div>'), null);
});
