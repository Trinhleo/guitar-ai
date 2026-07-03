# MVP Backend Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Scaffold and implement a testable Node.js/Express MVP backend with PostgreSQL, core REST APIs, and a TDD-built evaluation engine.

**Architecture:** Express REST API with layered structure (`api/` → `services/` → `config/database`). Pure evaluation logic isolated in `services/evaluationEngine.js`. PostgreSQL for persistence via raw SQL migrations. Jest + Supertest for unit and integration tests against a real test database.

**Tech Stack:** Node.js 20, Express 4, `pg`, `node-pg-migrate`, Jest, Supertest, Docker Compose (PostgreSQL 16)

**Design spec:** `docs/superpowers/specs/2026-07-03-mvp-backend-design.md`

---

## File Map

| File | Responsibility |
|------|----------------|
| `docker-compose.yml` | Postgres service for dev/test |
| `.env.example` | DB URL, port config |
| `backend/package.json` | Scripts: start, test, migrate |
| `backend/jest.config.js` | Test runner config |
| `backend/src/app.js` | Express app factory (exportable for tests) |
| `backend/src/server.js` | HTTP listen entrypoint |
| `backend/src/config/database.js` | `pg` Pool |
| `backend/src/services/evaluationEngine.js` | Pure scoring logic |
| `backend/src/services/contentService.js` | Content queries |
| `backend/src/services/practiceService.js` | Session lifecycle |
| `backend/src/api/instruments.js` | Instrument routes |
| `backend/src/api/content.js` | Content routes |
| `backend/src/api/practice.js` | Practice routes |
| `backend/src/middleware/errorHandler.js` | Centralized errors |
| `backend/migrations/001_initial.sql` | Schema + seed data |
| `backend/tests/unit/evaluationEngine.test.js` | Unit tests |
| `backend/tests/integration/*.test.js` | HTTP integration tests |
| `backend/tests/helpers/testDb.js` | Test DB setup/teardown |

---

## Task 1: Repository Infrastructure

**Files:**
- Create: `docker-compose.yml`
- Create: `.env.example`
- Create: `.gitignore`

- [ ] **Step 1: Create docker-compose.yml**

```yaml
services:
  postgres:
    image: postgres:16-alpine
    environment:
      POSTGRES_USER: guitar
      POSTGRES_PASSWORD: guitar
      POSTGRES_DB: guitar_ai
    ports:
      - "5432:5432"
    volumes:
      - pgdata:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U guitar -d guitar_ai"]
      interval: 5s
      timeout: 5s
      retries: 5

volumes:
  pgdata:
```

- [ ] **Step 2: Create .env.example**

```env
DATABASE_URL=postgresql://guitar:guitar@localhost:5432/guitar_ai
DATABASE_URL_TEST=postgresql://guitar:guitar@localhost:5432/guitar_ai_test
PORT=5000
NODE_ENV=development
```

- [ ] **Step 3: Create .gitignore**

```
node_modules/
.env
coverage/
dist/
*.log
.DS_Store
```

- [ ] **Step 4: Start Postgres and create test database**

Run:
```bash
cp .env.example .env
docker-compose up -d
docker-compose exec postgres psql -U guitar -d guitar_ai -c "CREATE DATABASE guitar_ai_test;"
```
Expected: `CREATE DATABASE`

- [ ] **Step 5: Commit**

```bash
git add docker-compose.yml .env.example .gitignore
git commit -m "chore: add docker-compose and environment template"
```

---

## Task 2: Backend Scaffold

**Files:**
- Create: `backend/package.json`
- Create: `backend/jest.config.js`

- [ ] **Step 1: Create backend/package.json**

```json
{
  "name": "guitar-ai-backend",
  "version": "0.1.0",
  "private": true,
  "main": "src/server.js",
  "scripts": {
    "start": "node src/server.js",
    "dev": "node --watch src/server.js",
    "test": "NODE_ENV=test jest --runInBand",
    "test:watch": "NODE_ENV=test jest --watch --runInBand",
    "migrate": "node scripts/migrate.js"
  },
  "dependencies": {
    "dotenv": "^16.4.5",
    "express": "^4.21.0",
    "pg": "^8.13.0",
    "uuid": "^10.0.0"
  },
  "devDependencies": {
    "jest": "^29.7.0",
    "supertest": "^7.0.0"
  }
}
```

- [ ] **Step 2: Create backend/jest.config.js**

```js
module.exports = {
  testEnvironment: 'node',
  testMatch: ['**/tests/**/*.test.js'],
  collectCoverageFrom: ['src/**/*.js'],
  coveragePathIgnorePatterns: ['/node_modules/'],
};
```

- [ ] **Step 3: Install dependencies**

Run:
```bash
cd backend && npm install
```
Expected: `added N packages`

- [ ] **Step 4: Commit**

```bash
git add backend/package.json backend/jest.config.js backend/package-lock.json
git commit -m "chore: scaffold backend package with jest"
```

---

## Task 3: Health Endpoint (TDD)

**Files:**
- Create: `backend/tests/integration/health.test.js`
- Create: `backend/src/app.js`
- Create: `backend/src/server.js`

- [ ] **Step 1: Write the failing test**

Create `backend/tests/integration/health.test.js`:

```js
const request = require('supertest');
const createApp = require('../../src/app');

describe('GET /health', () => {
  it('returns ok status', async () => {
    const app = createApp();
    const res = await request(app).get('/health');
    expect(res.status).toBe(200);
    expect(res.body).toEqual({ status: 'ok' });
  });
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd backend && npm test -- tests/integration/health.test.js`
Expected: FAIL — `Cannot find module '../../src/app'`

- [ ] **Step 3: Write minimal implementation**

Create `backend/src/app.js`:

```js
const express = require('express');
const errorHandler = require('./middleware/errorHandler');

function createApp() {
  const app = express();
  app.use(express.json());

  app.get('/health', (_req, res) => {
    res.json({ status: 'ok' });
  });

  app.use(errorHandler);
  return app;
}

module.exports = createApp;
```

Create `backend/src/middleware/errorHandler.js`:

```js
function errorHandler(err, _req, res, _next) {
  console.error(err);
  res.status(err.status || 500).json({ error: err.message || 'Internal server error' });
}

module.exports = errorHandler;
```

Create `backend/src/server.js`:

```js
require('dotenv').config({ path: require('path').resolve(__dirname, '../../.env') });
const createApp = require('./app');

const PORT = process.env.PORT || 5000;
const app = createApp();

app.listen(PORT, () => {
  console.log(`API listening on http://localhost:${PORT}`);
});
```

- [ ] **Step 4: Run test to verify it passes**

Run: `cd backend && npm test -- tests/integration/health.test.js`
Expected: PASS (1 test)

- [ ] **Step 5: Commit**

```bash
git add backend/src/app.js backend/src/server.js backend/src/middleware/errorHandler.js backend/tests/integration/health.test.js
git commit -m "feat: add health endpoint with integration test"
```

---

## Task 4: Database Layer

**Files:**
- Create: `backend/src/config/database.js`
- Create: `backend/scripts/migrate.js`
- Create: `backend/migrations/001_initial.sql`
- Create: `backend/tests/helpers/testDb.js`

- [ ] **Step 1: Write failing DB connectivity test**

Create `backend/tests/integration/database.test.js`:

```js
const { pool, query } = require('../../src/config/database');

describe('database', () => {
  afterAll(async () => {
    await pool.end();
  });

  it('connects and returns current timestamp', async () => {
    const result = await query('SELECT NOW() AS now');
    expect(result.rows[0].now).toBeDefined();
  });
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd backend && npm test -- tests/integration/database.test.js`
Expected: FAIL — module not found

- [ ] **Step 3: Implement database config**

Create `backend/src/config/database.js`:

```js
require('dotenv').config({ path: require('path').resolve(__dirname, '../../../.env') });
const { Pool } = require('pg');

const connectionString =
  process.env.NODE_ENV === 'test'
    ? process.env.DATABASE_URL_TEST
    : process.env.DATABASE_URL;

const pool = new Pool({ connectionString });

async function query(text, params) {
  return pool.query(text, params);
}

module.exports = { pool, query };
```

- [ ] **Step 4: Create migration SQL**

Create `backend/migrations/001_initial.sql`:

```sql
CREATE TABLE IF NOT EXISTS instruments (
  id VARCHAR(50) PRIMARY KEY,
  name VARCHAR(255) NOT NULL,
  family VARCHAR(100) NOT NULL,
  frequency_range_min INT,
  frequency_range_max INT,
  note_range_low VARCHAR(10),
  note_range_high VARCHAR(10),
  tuning JSONB DEFAULT '[]',
  techniques JSONB DEFAULT '[]',
  config JSONB DEFAULT '{}'
);

CREATE TABLE IF NOT EXISTS musical_content (
  id UUID PRIMARY KEY,
  type VARCHAR(20) NOT NULL CHECK (type IN ('lesson', 'solo', 'chord')),
  title VARCHAR(255) NOT NULL,
  instrument_id VARCHAR(50) REFERENCES instruments(id),
  difficulty_level INT NOT NULL CHECK (difficulty_level BETWEEN 1 AND 5),
  duration_seconds INT,
  bpm INT,
  key VARCHAR(10),
  expected_notes JSONB DEFAULT '[]',
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS practice_sessions (
  id UUID PRIMARY KEY,
  user_id UUID NOT NULL,
  content_id UUID REFERENCES musical_content(id),
  instrument_id VARCHAR(50) REFERENCES instruments(id),
  overall_score DECIMAL(5,2),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS performance_metrics (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  session_id UUID REFERENCES practice_sessions(id) ON DELETE CASCADE,
  pitch_accuracy DECIMAL(5,2),
  timing_accuracy DECIMAL(5,2),
  technique_score DECIMAL(5,2),
  expression_score DECIMAL(5,2),
  consistency_score DECIMAL(5,2),
  instrument_specific_metrics JSONB DEFAULT '{}'
);

INSERT INTO instruments (id, name, family, frequency_range_min, frequency_range_max, note_range_low, note_range_high, tuning, techniques, config)
VALUES (
  'guitar',
  'Guitar',
  'stringed',
  82,
  1319,
  'E2',
  'E6',
  '["E2","A2","D3","G3","B3","E4"]',
  '["bend","vibrato","slide","hammer-on","pull-off"]',
  '{"pitchToleranceCents": 50, "timingToleranceMs": 80}'
) ON CONFLICT (id) DO NOTHING;

INSERT INTO musical_content (id, type, title, instrument_id, difficulty_level, bpm, key, expected_notes)
VALUES (
  '11111111-1111-1111-1111-111111111111',
  'lesson',
  'Open String Exercise',
  'guitar',
  1,
  80,
  'E',
  '[
    {"note":"E4","startMs":0,"durationMs":500},
    {"note":"E4","startMs":600,"durationMs":500},
    {"note":"E4","startMs":1200,"durationMs":500}
  ]'
) ON CONFLICT (id) DO NOTHING;
```

- [ ] **Step 5: Create migrate script**

Create `backend/scripts/migrate.js`:

```js
const fs = require('fs');
const path = require('path');
const { pool } = require('../src/config/database');

async function migrate() {
  const sqlPath = path.join(__dirname, '../migrations/001_initial.sql');
  const sql = fs.readFileSync(sqlPath, 'utf8');
  await pool.query(sql);
  console.log('Migration 001 applied');
  await pool.end();
}

migrate().catch((err) => {
  console.error(err);
  process.exit(1);
});
```

- [ ] **Step 6: Run migration and test**

Run:
```bash
cd backend && npm run migrate
cd backend && npm test -- tests/integration/database.test.js
```
Expected: Migration succeeds, test PASS

- [ ] **Step 7: Create test DB helper**

Create `backend/tests/helpers/testDb.js`:

```js
const fs = require('fs');
const path = require('path');
const { pool, query } = require('../../src/config/database');

async function resetDatabase() {
  await query('DELETE FROM performance_metrics');
  await query('DELETE FROM practice_sessions');
  await query('DELETE FROM musical_content WHERE id != $1', ['11111111-1111-1111-1111-111111111111']);
  await query('DELETE FROM instruments WHERE id != $1', ['guitar']);
}

async function setupTestDatabase() {
  const sqlPath = path.join(__dirname, '../../migrations/001_initial.sql');
  const sql = fs.readFileSync(sqlPath, 'utf8');
  await pool.query(sql);
}

module.exports = { resetDatabase, setupTestDatabase, pool };
```

- [ ] **Step 8: Commit**

```bash
git add backend/src/config/database.js backend/scripts/migrate.js backend/migrations/001_initial.sql backend/tests/integration/database.test.js backend/tests/helpers/testDb.js
git commit -m "feat: add postgres layer, migrations, and seed data"
```

---

## Task 5: Evaluation Engine (TDD)

**Files:**
- Create: `backend/tests/unit/evaluationEngine.test.js`
- Create: `backend/src/services/evaluationEngine.js`

- [ ] **Step 1: Write failing tests**

Create `backend/tests/unit/evaluationEngine.test.js`:

```js
const { evaluatePerformance } = require('../../src/services/evaluationEngine');

const config = { pitchToleranceCents: 50, timingToleranceMs: 80 };

describe('evaluatePerformance', () => {
  it('returns perfect score when all notes match exactly', () => {
    const notes = [
      { note: 'E4', startMs: 0, durationMs: 500 },
      { note: 'E4', startMs: 600, durationMs: 500 },
    ];
    const result = evaluatePerformance({
      expectedNotes: notes,
      playedNotes: notes,
      instrumentConfig: config,
    });
    expect(result.overallScore).toBe(100);
    expect(result.pitchAccuracy).toBe(100);
    expect(result.timingAccuracy).toBe(100);
  });

  it('penalizes wrong pitch', () => {
    const expected = [{ note: 'E4', startMs: 0, durationMs: 500 }];
    const played = [{ note: 'G4', startMs: 0, durationMs: 500 }];
    const result = evaluatePerformance({
      expectedNotes: expected,
      playedNotes: played,
      instrumentConfig: config,
    });
    expect(result.pitchAccuracy).toBeLessThan(100);
    expect(result.overallScore).toBeLessThan(100);
  });

  it('penalizes timing drift beyond tolerance', () => {
    const expected = [{ note: 'E4', startMs: 0, durationMs: 500 }];
    const played = [{ note: 'E4', startMs: 200, durationMs: 500 }];
    const result = evaluatePerformance({
      expectedNotes: expected,
      playedNotes: played,
      instrumentConfig: config,
    });
    expect(result.timingAccuracy).toBeLessThan(100);
  });

  it('handles empty played notes', () => {
    const expected = [{ note: 'E4', startMs: 0, durationMs: 500 }];
    const result = evaluatePerformance({
      expectedNotes: expected,
      playedNotes: [],
      instrumentConfig: config,
    });
    expect(result.overallScore).toBe(0);
    expect(result.instrumentSpecificMetrics.matchedNotes).toBe(0);
  });
});
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `cd backend && npm test -- tests/unit/evaluationEngine.test.js`
Expected: FAIL — module not found

- [ ] **Step 3: Implement evaluation engine**

Create `backend/src/services/evaluationEngine.js`:

```js
const NOTE_TO_SEMITONE = {
  C: 0, D: 2, E: 4, F: 5, G: 7, A: 9, B: 11,
};

function parseNote(note) {
  const match = note.match(/^([A-G])(#|b)?(\d+)$/);
  if (!match) return null;
  let semitone = NOTE_TO_SEMITONE[match[1]];
  if (match[2] === '#') semitone += 1;
  if (match[2] === 'b') semitone -= 1;
  return semitone + (parseInt(match[3], 10) + 1) * 12;
}

function noteMatches(expected, played) {
  const e = parseNote(expected.note);
  const p = parseNote(played.note);
  if (e === null || p === null) return false;
  return e === p;
}

function timingMatches(expected, played, toleranceMs) {
  return Math.abs(expected.startMs - played.startMs) <= toleranceMs;
}

function clampScore(value) {
  return Math.max(0, Math.min(100, Math.round(value * 100) / 100));
}

function evaluatePerformance({ expectedNotes, playedNotes, instrumentConfig }) {
  const toleranceMs = instrumentConfig.timingToleranceMs ?? 80;
  const total = expectedNotes.length;

  if (total === 0) {
    return {
      overallScore: 0,
      pitchAccuracy: 0,
      timingAccuracy: 0,
      techniqueScore: 0,
      expressionScore: 0,
      consistencyScore: 0,
      instrumentSpecificMetrics: { matchedNotes: 0, totalNotes: 0 },
    };
  }

  let pitchHits = 0;
  let timingHits = 0;
  let matchedNotes = 0;

  for (let i = 0; i < total; i++) {
    const expected = expectedNotes[i];
    const played = playedNotes[i];
    if (!played) continue;

    const pitchOk = noteMatches(expected, played);
    const timingOk = timingMatches(expected, played, toleranceMs);

    if (pitchOk) pitchHits += 1;
    if (timingOk) timingHits += 1;
    if (pitchOk && timingOk) matchedNotes += 1;
  }

  const pitchAccuracy = clampScore((pitchHits / total) * 100);
  const timingAccuracy = clampScore((timingHits / total) * 100);
  const techniqueScore = clampScore((matchedNotes / total) * 100);
  const expressionScore = clampScore(timingAccuracy * 0.9);
  const consistencyScore = clampScore(pitchAccuracy * 0.95);

  const overallScore = clampScore(
    pitchAccuracy * 0.4 +
    timingAccuracy * 0.35 +
    techniqueScore * 0.15 +
    expressionScore * 0.07 +
    consistencyScore * 0.03
  );

  return {
    overallScore,
    pitchAccuracy,
    timingAccuracy,
    techniqueScore,
    expressionScore,
    consistencyScore,
    instrumentSpecificMetrics: { matchedNotes, totalNotes: total },
  };
}

module.exports = { evaluatePerformance, parseNote };
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `cd backend && npm test -- tests/unit/evaluationEngine.test.js`
Expected: PASS (4 tests)

- [ ] **Step 5: Commit**

```bash
git add backend/src/services/evaluationEngine.js backend/tests/unit/evaluationEngine.test.js
git commit -m "feat: add evaluation engine with unit tests"
```

---

## Task 6: Instruments API (TDD)

**Files:**
- Create: `backend/tests/integration/instruments.test.js`
- Create: `backend/src/api/instruments.js`
- Modify: `backend/src/app.js`

- [ ] **Step 1: Write failing integration tests**

Create `backend/tests/integration/instruments.test.js`:

```js
const request = require('supertest');
const createApp = require('../../src/app');
const { setupTestDatabase, resetDatabase, pool } = require('../helpers/testDb');

describe('Instruments API', () => {
  let app;

  beforeAll(async () => {
    await setupTestDatabase();
    app = createApp();
  });

  beforeEach(async () => {
    await resetDatabase();
    await setupTestDatabase();
  });

  afterAll(async () => {
    await pool.end();
  });

  it('GET /api/instruments returns seeded guitar', async () => {
    const res = await request(app).get('/api/instruments');
    expect(res.status).toBe(200);
    expect(res.body).toEqual(
      expect.arrayContaining([
        expect.objectContaining({ id: 'guitar', name: 'Guitar' }),
      ])
    );
  });

  it('GET /api/instruments/guitar returns details', async () => {
    const res = await request(app).get('/api/instruments/guitar');
    expect(res.status).toBe(200);
    expect(res.body.id).toBe('guitar');
    expect(res.body.family).toBe('stringed');
  });

  it('GET /api/instruments/unknown returns 404', async () => {
    const res = await request(app).get('/api/instruments/unknown');
    expect(res.status).toBe(404);
    expect(res.body.error).toMatch(/not found/i);
  });
});
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `cd backend && npm test -- tests/integration/instruments.test.js`
Expected: FAIL — 404 on `/api/instruments`

- [ ] **Step 3: Implement instruments router**

Create `backend/src/api/instruments.js`:

```js
const express = require('express');
const { query } = require('../config/database');

const router = express.Router();

router.get('/', async (_req, res, next) => {
  try {
    const result = await query('SELECT * FROM instruments ORDER BY name');
    res.json(result.rows);
  } catch (err) {
    next(err);
  }
});

router.get('/:id', async (req, res, next) => {
  try {
    const result = await query('SELECT * FROM instruments WHERE id = $1', [req.params.id]);
    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Instrument not found' });
    }
    res.json(result.rows[0]);
  } catch (err) {
    next(err);
  }
});

module.exports = router;
```

Modify `backend/src/app.js` — add after `express.json()`:

```js
const instrumentsRouter = require('./api/instruments');
// ...
app.use('/api/instruments', instrumentsRouter);
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `cd backend && npm test -- tests/integration/instruments.test.js`
Expected: PASS (3 tests)

- [ ] **Step 5: Commit**

```bash
git add backend/src/api/instruments.js backend/src/app.js backend/tests/integration/instruments.test.js
git commit -m "feat: add instruments API with integration tests"
```

---

## Task 7: Content API (TDD)

**Files:**
- Create: `backend/tests/integration/content.test.js`
- Create: `backend/src/api/content.js`
- Modify: `backend/src/app.js`

- [ ] **Step 1: Write failing tests**

Create `backend/tests/integration/content.test.js`:

```js
const request = require('supertest');
const createApp = require('../../src/app');
const { setupTestDatabase, resetDatabase, pool } = require('../helpers/testDb');

describe('Content API', () => {
  let app;

  beforeAll(async () => {
    await setupTestDatabase();
    app = createApp();
  });

  beforeEach(async () => {
    await resetDatabase();
    await setupTestDatabase();
  });

  afterAll(async () => {
    await pool.end();
  });

  it('GET /api/content returns seeded lesson', async () => {
    const res = await request(app).get('/api/content');
    expect(res.status).toBe(200);
    expect(res.body.length).toBeGreaterThanOrEqual(1);
    expect(res.body[0]).toMatchObject({ type: 'lesson', instrument_id: 'guitar' });
  });

  it('GET /api/content?type=lesson filters by type', async () => {
    const res = await request(app).get('/api/content?type=lesson');
    expect(res.status).toBe(200);
    expect(res.body.every((c) => c.type === 'lesson')).toBe(true);
  });

  it('GET /api/content/:id returns single item', async () => {
    const res = await request(app).get('/api/content/11111111-1111-1111-1111-111111111111');
    expect(res.status).toBe(200);
    expect(res.body.title).toBe('Open String Exercise');
  });

  it('GET /api/content/:id returns 404 for missing', async () => {
    const res = await request(app).get('/api/content/00000000-0000-0000-0000-000000000000');
    expect(res.status).toBe(404);
  });
});
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `cd backend && npm test -- tests/integration/content.test.js`
Expected: FAIL — 404

- [ ] **Step 3: Implement content router**

Create `backend/src/api/content.js`:

```js
const express = require('express');
const { query } = require('../config/database');

const router = express.Router();

router.get('/', async (req, res, next) => {
  try {
    const { type, instrument, difficulty } = req.query;
    const conditions = [];
    const params = [];

    if (type) {
      params.push(type);
      conditions.push(`type = $${params.length}`);
    }
    if (instrument) {
      params.push(instrument);
      conditions.push(`instrument_id = $${params.length}`);
    }
    if (difficulty) {
      params.push(Number(difficulty));
      conditions.push(`difficulty_level = $${params.length}`);
    }

    const where = conditions.length ? `WHERE ${conditions.join(' AND ')}` : '';
    const result = await query(
      `SELECT * FROM musical_content ${where} ORDER BY title`,
      params
    );
    res.json(result.rows);
  } catch (err) {
    next(err);
  }
});

router.get('/:id', async (req, res, next) => {
  try {
    const result = await query('SELECT * FROM musical_content WHERE id = $1', [req.params.id]);
    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Content not found' });
    }
    res.json(result.rows[0]);
  } catch (err) {
    next(err);
  }
});

module.exports = router;
```

Modify `backend/src/app.js`:

```js
const contentRouter = require('./api/content');
app.use('/api/content', contentRouter);
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `cd backend && npm test -- tests/integration/content.test.js`
Expected: PASS (4 tests)

- [ ] **Step 5: Commit**

```bash
git add backend/src/api/content.js backend/src/app.js backend/tests/integration/content.test.js
git commit -m "feat: add content API with filters and integration tests"
```

---

## Task 8: Practice Flow (TDD)

**Files:**
- Create: `backend/tests/integration/practice.test.js`
- Create: `backend/src/services/practiceService.js`
- Create: `backend/src/api/practice.js`
- Modify: `backend/src/app.js`

- [ ] **Step 1: Write failing tests**

Create `backend/tests/integration/practice.test.js`:

```js
const request = require('supertest');
const createApp = require('../../src/app');
const { setupTestDatabase, resetDatabase, pool } = require('../helpers/testDb');

const DEMO_USER = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa';
const CONTENT_ID = '11111111-1111-1111-1111-111111111111';

describe('Practice API', () => {
  let app;

  beforeAll(async () => {
    await setupTestDatabase();
    app = createApp();
  });

  beforeEach(async () => {
    await resetDatabase();
    await setupTestDatabase();
  });

  afterAll(async () => {
    await pool.end();
  });

  it('POST /api/practice/start/:contentId creates a session', async () => {
    const res = await request(app)
      .post(`/api/practice/start/${CONTENT_ID}`)
      .send({ userId: DEMO_USER, instrumentId: 'guitar' });
    expect(res.status).toBe(201);
    expect(res.body.sessionId).toBeDefined();
  });

  it('POST /api/practice/:sessionId/evaluate returns scores', async () => {
    const start = await request(app)
      .post(`/api/practice/start/${CONTENT_ID}`)
      .send({ userId: DEMO_USER, instrumentId: 'guitar' });

    const res = await request(app)
      .post(`/api/practice/${start.body.sessionId}/evaluate`)
      .send({
        playedNotes: [
          { note: 'E4', startMs: 0, durationMs: 500 },
          { note: 'E4', startMs: 600, durationMs: 500 },
          { note: 'E4', startMs: 1200, durationMs: 500 },
        ],
      });

    expect(res.status).toBe(200);
    expect(res.body.overallScore).toBe(100);
    expect(res.body.pitchAccuracy).toBe(100);
  });

  it('GET /api/practice/:sessionId/results returns stored evaluation', async () => {
    const start = await request(app)
      .post(`/api/practice/start/${CONTENT_ID}`)
      .send({ userId: DEMO_USER, instrumentId: 'guitar' });

    await request(app)
      .post(`/api/practice/${start.body.sessionId}/evaluate`)
      .send({ playedNotes: [{ note: 'E4', startMs: 0, durationMs: 500 }] });

    const res = await request(app).get(`/api/practice/${start.body.sessionId}/results`);
    expect(res.status).toBe(200);
    expect(res.body.metrics).toBeDefined();
    expect(res.body.metrics.pitch_accuracy).toBeDefined();
  });

  it('POST evaluate returns 400 when playedNotes missing', async () => {
    const start = await request(app)
      .post(`/api/practice/start/${CONTENT_ID}`)
      .send({ userId: DEMO_USER, instrumentId: 'guitar' });

    const res = await request(app)
      .post(`/api/practice/${start.body.sessionId}/evaluate`)
      .send({});
    expect(res.status).toBe(400);
  });
});
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `cd backend && npm test -- tests/integration/practice.test.js`
Expected: FAIL — route not found

- [ ] **Step 3: Implement practice service**

Create `backend/src/services/practiceService.js`:

```js
const { v4: uuidv4 } = require('uuid');
const { query } = require('../config/database');
const { evaluatePerformance } = require('./evaluationEngine');

async function startSession({ contentId, userId, instrumentId }) {
  const content = await query('SELECT * FROM musical_content WHERE id = $1', [contentId]);
  if (content.rows.length === 0) {
    const err = new Error('Content not found');
    err.status = 404;
    throw err;
  }

  const sessionId = uuidv4();
  await query(
    `INSERT INTO practice_sessions (id, user_id, content_id, instrument_id)
     VALUES ($1, $2, $3, $4)`,
    [sessionId, userId, contentId, instrumentId]
  );
  return { sessionId };
}

async function evaluateSession(sessionId, playedNotes) {
  const sessionResult = await query(
    `SELECT ps.*, mc.expected_notes, i.config AS instrument_config
     FROM practice_sessions ps
     JOIN musical_content mc ON mc.id = ps.content_id
     JOIN instruments i ON i.id = ps.instrument_id
     WHERE ps.id = $1`,
    [sessionId]
  );

  if (sessionResult.rows.length === 0) {
    const err = new Error('Session not found');
    err.status = 404;
    throw err;
  }

  const session = sessionResult.rows[0];
  const scores = evaluatePerformance({
    expectedNotes: session.expected_notes,
    playedNotes,
    instrumentConfig: session.instrument_config,
  });

  await query('UPDATE practice_sessions SET overall_score = $1 WHERE id = $2', [
    scores.overallScore,
    sessionId,
  ]);

  await query(
    `INSERT INTO performance_metrics
     (session_id, pitch_accuracy, timing_accuracy, technique_score, expression_score, consistency_score, instrument_specific_metrics)
     VALUES ($1, $2, $3, $4, $5, $6, $7)`,
    [
      sessionId,
      scores.pitchAccuracy,
      scores.timingAccuracy,
      scores.techniqueScore,
      scores.expressionScore,
      scores.consistencyScore,
      JSON.stringify(scores.instrumentSpecificMetrics),
    ]
  );

  return scores;
}

async function getResults(sessionId) {
  const sessionResult = await query('SELECT * FROM practice_sessions WHERE id = $1', [sessionId]);
  if (sessionResult.rows.length === 0) {
    const err = new Error('Session not found');
    err.status = 404;
    throw err;
  }

  const metricsResult = await query(
    'SELECT * FROM performance_metrics WHERE session_id = $1 ORDER BY id DESC LIMIT 1',
    [sessionId]
  );

  return {
    session: sessionResult.rows[0],
    metrics: metricsResult.rows[0] || null,
  };
}

module.exports = { startSession, evaluateSession, getResults };
```

- [ ] **Step 4: Implement practice router**

Create `backend/src/api/practice.js`:

```js
const express = require('express');
const { startSession, evaluateSession, getResults } = require('../services/practiceService');

const router = express.Router();
const DEMO_USER = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa';

router.post('/start/:contentId', async (req, res, next) => {
  try {
    const { userId = DEMO_USER, instrumentId = 'guitar' } = req.body;
    const result = await startSession({
      contentId: req.params.contentId,
      userId,
      instrumentId,
    });
    res.status(201).json(result);
  } catch (err) {
    next(err);
  }
});

router.post('/:sessionId/evaluate', async (req, res, next) => {
  try {
    const { playedNotes } = req.body;
    if (!Array.isArray(playedNotes)) {
      return res.status(400).json({ error: 'playedNotes array is required' });
    }
    const scores = await evaluateSession(req.params.sessionId, playedNotes);
    res.json(scores);
  } catch (err) {
    next(err);
  }
});

router.get('/:sessionId/results', async (req, res, next) => {
  try {
    const results = await getResults(req.params.sessionId);
    res.json(results);
  } catch (err) {
    next(err);
  }
});

module.exports = router;
```

Modify `backend/src/app.js`:

```js
const practiceRouter = require('./api/practice');
app.use('/api/practice', practiceRouter);
```

Update `backend/src/middleware/errorHandler.js` to respect `err.status`:

```js
function errorHandler(err, _req, res, _next) {
  console.error(err);
  const status = err.status || 500;
  res.status(status).json({ error: err.message || 'Internal server error' });
}
```

- [ ] **Step 5: Run tests to verify they pass**

Run: `cd backend && npm test -- tests/integration/practice.test.js`
Expected: PASS (4 tests)

- [ ] **Step 6: Commit**

```bash
git add backend/src/services/practiceService.js backend/src/api/practice.js backend/src/app.js backend/src/middleware/errorHandler.js backend/tests/integration/practice.test.js
git commit -m "feat: add practice session flow with evaluation"
```

---

## Task 9: Full Test Suite & Smoke Verification

**Files:**
- Modify: `backend/package.json` (add smoke script)

- [ ] **Step 1: Run full test suite**

Run: `cd backend && npm test`
Expected: All tests PASS (≥15 tests total)

- [ ] **Step 2: Add smoke script to package.json**

Add to `backend/package.json` scripts:

```json
"smoke": "node scripts/smoke.js"
```

Create `backend/scripts/smoke.js`:

```js
const http = require('http');

const PORT = process.env.PORT || 5000;

function get(path) {
  return new Promise((resolve, reject) => {
    http.get(`http://localhost:${PORT}${path}`, (res) => {
      let data = '';
      res.on('data', (chunk) => { data += chunk; });
      res.on('end', () => resolve({ status: res.statusCode, body: JSON.parse(data) }));
    }).on('error', reject);
  });
}

async function smoke() {
  const health = await get('/health');
  if (health.status !== 200 || health.body.status !== 'ok') {
    throw new Error('Health check failed');
  }
  const instruments = await get('/api/instruments');
  if (instruments.status !== 200 || instruments.body.length === 0) {
    throw new Error('Instruments check failed');
  }
  console.log('Smoke tests passed');
}

smoke().catch((err) => {
  console.error('Smoke tests failed:', err.message);
  process.exit(1);
});
```

- [ ] **Step 3: Manual smoke test**

Run (in separate terminal):
```bash
docker-compose up -d
cd backend && npm run migrate && npm start
cd backend && npm run smoke
```
Expected: `Smoke tests passed`

- [ ] **Step 4: Commit**

```bash
git add backend/package.json backend/scripts/smoke.js
git commit -m "test: add smoke script and verify full suite"
```

---

## Task 10: Branch, Push, and PR

- [ ] **Step 1: Create feature branch**

```bash
git checkout -b cursor/mvp-backend-6dcd
```

- [ ] **Step 2: Push branch**

```bash
git push -u origin cursor/mvp-backend-6dcd
```

- [ ] **Step 3: Open draft PR**

Title: `feat: MVP backend with TDD evaluation engine and core APIs`

Body summary:
- Docker Compose + PostgreSQL
- Health, instruments, content, practice endpoints
- Evaluation engine with unit tests
- Integration tests for full practice flow

---

## Verification Checklist (before marking complete)

- [ ] `npm test` — all green, ≥15 tests
- [ ] Each feature was test-first (RED → GREEN → commit)
- [ ] `npm run migrate` succeeds on fresh DB
- [ ] `npm run smoke` passes against running server
- [ ] No secrets committed (only `.env.example`)

---

## What Comes Next (Phase 2)

1. **Flutter monorepo** — `frontend/` per `FLUTTER_ARCHITECTURE.md`, wired to these APIs
2. **WebSocket feedback** — real-time pitch stream during practice
3. **Audio upload** — accept WAV/MP3, run pitch detection (Python sidecar or native lib)
4. **Auth** — JWT users replacing demo user ID
