import { test, expect } from '@playwright/test';
import { randomUUID } from 'crypto';

const baseURL = process.env.E2E_BASE_URL ?? 'http://localhost:5000';
const contentID = '11111111-1111-1111-1111-111111111111';

test('health check', async ({ request }) => {
  const response = await request.get(`${baseURL}/health`);
  expect(response.ok()).toBeTruthy();
  const body = await response.json();
  expect(body.status).toBe('ok');
});

test('full practice API flow', async ({ request }) => {
  const email = `e2e-${randomUUID()}@example.com`;
  const password = 'password123';

  const register = await request.post(`${baseURL}/api/auth/register`, {
    data: { email, password },
  });
  expect(register.status()).toBe(201);
  const auth = await register.json();
  const token = auth.token as string;
  const headers = { Authorization: `Bearer ${token}` };

  const start = await request.post(`${baseURL}/api/practice/start/${contentID}`, {
    headers,
    data: { instrumentId: 'guitar' },
  });
  expect(start.status()).toBe(201);
  const session = await start.json();

  const evaluate = await request.post(
    `${baseURL}/api/practice/${session.sessionId}/evaluate`,
    {
      headers,
      data: {
        playedNotes: [
          { note: 'E4', startMs: 0, durationMs: 500 },
          { note: 'E4', startMs: 600, durationMs: 500 },
          { note: 'E4', startMs: 1200, durationMs: 500 },
        ],
      },
    },
  );
  expect(evaluate.ok()).toBeTruthy();
  const scores = await evaluate.json();
  expect(scores.pitchAccuracy).toBe(100);
  expect(Array.isArray(scores.techniqueHints)).toBeTruthy();

  const recommendations = await request.get(`${baseURL}/api/content/recommendations`, {
    headers,
  });
  expect(recommendations.ok()).toBeTruthy();
  const recBody = await recommendations.json();
  expect(Array.isArray(recBody.items)).toBeTruthy();
  expect(recBody.items[0].content).toBeTruthy();
  expect(recBody.items[0].reason).toBeTruthy();

  const results = await request.get(
    `${baseURL}/api/practice/${session.sessionId}/results`,
    { headers },
  );
  expect(results.ok()).toBeTruthy();
  const detail = await results.json();
  expect(detail.contentTitle).toBeTruthy();
  expect(detail.playedNotes.length).toBeGreaterThan(0);

  const insights = await request.get(`${baseURL}/api/stats/insights`, { headers });
  expect(insights.ok()).toBeTruthy();
  const insightsBody = await insights.json();
  expect(Array.isArray(insightsBody.insights)).toBeTruthy();
  expect(insightsBody.insights.length).toBeGreaterThan(0);

  const leaderboard = await request.get(`${baseURL}/api/stats/leaderboard`, { headers });
  expect(leaderboard.ok()).toBeTruthy();
  const leaderboardBody = await leaderboard.json();
  expect(Array.isArray(leaderboardBody.items)).toBeTruthy();
  expect(leaderboardBody.items.length).toBeGreaterThan(0);
});
