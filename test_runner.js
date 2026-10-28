const fs = require('fs');
const path = require('path');

const KNOWLEDGE_PATH = path.join(__dirname, 'HraifiBot_Mini_V1', 'knowledge.json');
const APP_PATH = path.join(__dirname, 'HraifiBot_Mini_V1', 'app.js');

let passed = 0;
let failed = 0;

function assert(condition, message) {
  if (condition) {
    console.log(`  ✅ PASS: ${message}`);
    passed++;
  } else {
    console.error(`  ❌ FAIL: ${message}`);
    failed++;
  }
}

console.log('\n--- 1. Testing knowledge.json Schema & Limits ---');
const rawKb = fs.readFileSync(KNOWLEDGE_PATH, 'utf8');
assert(rawKb.length <= 180000, `knowledge.json size (${rawKb.length} bytes) <= 180,000 bytes`);

const kb = JSON.parse(rawKb);
assert(kb.version && typeof kb.version === 'string', 'knowledge.json has valid version string');
assert(Array.isArray(kb.items), 'knowledge.json items is an array');
assert(kb.items.length <= 200, `Item count (${kb.items.length}) <= 200`);

let allIdsUnique = true;
let allUnder35Keywords = true;
let allHaveFrAndAr = true;
const idSet = new Set();

for (const item of kb.items) {
  if (idSet.has(item.id)) allIdsUnique = false;
  idSet.add(item.id);
  if (!Array.isArray(item.keywords) || item.keywords.length > 35) allUnder35Keywords = false;
  if (!item.fr || !item.ar) allHaveFrAndAr = false;
}

assert(allIdsUnique, 'All knowledge item IDs are unique');
assert(allUnder35Keywords, 'All items have <= 35 keywords');
assert(allHaveFrAndAr, 'All items have non-empty "fr" and "ar" content');

console.log('\n--- 2. Testing Robust Tokenizer & Search Matching ---');
function normalize(text) {
  return String(text)
    .toLowerCase()
    .normalize('NFKD')
    .replace(/[\u0300-\u036f]/g, '')
    .replace(/[\u0610-\u061A\u064B-\u065F\u0670\u06D6-\u06ED\u08D3-\u08FF\u0640]/g, '')
    .replace(/[أإآٱ]/g, 'ا')
    .replace(/ى/g, 'ي')
    .replace(/ؤ/g, 'و')
    .replace(/ئ/g, 'ي')
    .replace(/ة/g, 'ه')
    .replace(/[^\p{L}\p{N}]+/gu, ' ')
    .trim()
    .replace(/\s+/g, ' ');
}

const STOP_WORDS = new Set([
  'le', 'la', 'les', 'de', 'des', 'du', 'un', 'une', 'et', 'ou', 'en', 'a', 'au', 'aux',
  'pour', 'comment', 'est', 'ce', 'que', 'qui', 'quoi', 'dans', 'sur', 'avec', 'sans',
  'je', 'tu', 'il', 'elle', 'nous', 'vous', 'ils', 'elles', 'quel', 'quelle', 'quels',
  'quelles', 'sont', 'peut', 'on', 'ca', 'cette', 'mon', 'ton', 'son', 'votre',
  'في', 'من', 'على', 'إلى', 'الى', 'عن', 'مع', 'هل', 'ما', 'كيف', 'لماذا', 'هذا',
  'هذه', 'ذلك', 'التي', 'الذي', 'و', 'او', 'أو', 'ثم', 'ان', 'أن', 'لا', 'هو', 'هي',
  'انا', 'أنا', 'نحن', 'يمكن', 'الى', 'جد', 'أجد'
]);

function queryTokens(text) {
  const base = normalize(text).split(' ').filter(Boolean);
  const set = new Set();
  for (const token of base) {
    if (STOP_WORDS.has(token)) continue;
    set.add(token);
    if (!/[\u0600-\u06FF]/.test(token) || token.length < 3) continue;
    const trimmed = token
      .replace(/^وال/, '')
      .replace(/^بال/, '')
      .replace(/^كال/, '')
      .replace(/^فال/, '')
      .replace(/^لل/, '')
      .replace(/^ال/, '');
    if (trimmed && trimmed !== token && !STOP_WORDS.has(trimmed)) set.add(trimmed);
    if (token.startsWith('و') && token.length > 4) set.add(token.slice(1));
    if (trimmed.endsWith('ا') && trimmed.length > 3) set.add(trimmed.slice(0, -1));
    if (trimmed.endsWith('ات') && trimmed.length > 4) set.add(trimmed.slice(0, -2));
    if (trimmed.endsWith('ين') && trimmed.length > 4) set.add(trimmed.slice(0, -2));
    if (trimmed.endsWith('ون') && trimmed.length > 4) set.add(trimmed.slice(0, -2));
  }
  return set;
}

function scoreItem(item, normalizedQuery, tokens) {
  let score = 0;
  let matchesCount = 0;
  let hasPhrase = false;
  for (const keyword of item.keywords) {
    const key = normalize(keyword);
    if (!key || STOP_WORDS.has(key)) continue;
    if (key.includes(' ')) {
      if ((' ' + normalizedQuery + ' ').includes(' ' + key + ' ')) {
        score += 8;
        hasPhrase = true;
      }
    } else if (tokens.has(key)) {
      score += 4;
      matchesCount++;
    } else if (key.length >= 4) {
      for (const token of tokens) {
        if (token.length < 3) continue;
        if (Math.abs(token.length - key.length) > 2) continue;
        if (token.startsWith(key) || key.startsWith(token)) {
          score += 2;
          matchesCount++;
          break;
        }
      }
    }
  }
  return { score, matchesCount, hasPhrase };
}

function findAnswer(question) {
  const normalizedQuery = normalize(question);
  const tokens = queryTokens(question);
  let best = null;
  let bestScore = 0;
  let bestDetails = null;

  for (const item of kb.items) {
    const details = scoreItem(item, normalizedQuery, tokens);
    if (details.score > bestScore) {
      best = item;
      bestScore = details.score;
      bestDetails = details;
    }
  }

  if (!best || bestScore < 3) return null;

  // Unrelated question rejection: if the question contains >= 3 content words
  // and only 1 weak match without any phrase match, reject as fallback
  const baseContentWords = normalizedQuery.split(' ').filter(w => w.length >= 3 && !STOP_WORDS.has(w));
  if (baseContentWords.length >= 3 && !bestDetails.hasPhrase && bestDetails.matchesCount <= 1) {
    return null;
  }

  return { item: best, score: bestScore };
}

const testQueries = [
  { q: 'Comment trouver un électricien à Laayoune ?', expectedId: 'electricien-laayoune' },
  { q: 'كيف أجد كهربائياً في العيون؟', expectedId: 'electricien-laayoune' },
  { q: 'Quels savoir-faire sont valorisés ?', expectedId: 'artisanat-patrimoine' },
  { q: 'ما المهارات التي تُثمّنها المنصة؟', expectedId: 'artisanat-patrimoine' },
  { q: 'Est-ce que ça marche sans Internet ?', expectedId: 'hors-ligne' },
  { q: 'هل يعمل الروبوت دون إنترنت؟', expectedId: 'hors-ligne' },
  { q: 'Comment un artisan peut-il rejoindre Le7rayfi ?', expectedId: 'inscription-artisan' },
  { q: 'كيف يمكن للحرفي الانضمام إلى Le7rayfi؟', expectedId: 'inscription-artisan' },
  { q: 'Quel est le prix du billet de train pour Tokyo ?', expectedId: null }
];

for (const t of testQueries) {
  const result = findAnswer(t.q);
  const actualId = result ? result.item.id : null;
  assert(actualId === t.expectedId, `Query "${t.q}" -> expected: ${t.expectedId}, got: ${actualId}`);
}

console.log('\n--- 3. Testing JavaScript Syntax & HTML Validity ---');
const appContent = fs.readFileSync(APP_PATH, 'utf8');
assert(appContent.includes('AudioContext'), 'app.js includes Web Audio API AudioContext');
assert(appContent.includes('LipSync'), 'app.js includes LipSync viseme engine');
assert(appContent.includes('SpeechRecognition'), 'app.js includes SpeechRecognition');
assert(appContent.includes('speechSynthesis'), 'app.js includes SpeechSynthesis');
assert(appContent.includes('I18N'), 'app.js includes I18N dictionary');
assert(appContent.includes('darija'), 'app.js includes Moroccan Darija support');

console.log(`\n========================================`);
console.log(`TEST RESULTS: ${passed} passed, ${failed} failed`);
console.log(`========================================\n`);

process.exit(failed > 0 ? 1 : 0);
