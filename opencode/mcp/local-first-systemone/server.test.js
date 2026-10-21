import { test } from "node:test";
import assert from "node:assert/strict";
import http from "node:http";

import {
  callSystemOne,
  readConfig,
  buildFallbackCandidates,
  resolveCandidates,
} from "./server.js";

/* ------------------------------------------------------------------ *
 * Test harness: mock HTTP servers + config factory (no network egress)
 * ------------------------------------------------------------------ */

function createMockServer(responder) {
  const requests = [];
  const server = http.createServer((req, res) => {
    let raw = "";
    req.on("data", (chunk) => {
      raw += chunk;
    });
    req.on("end", () => {
      let body = null;
      try {
        body = JSON.parse(raw);
      } catch {
        body = null;
      }
      const record = { method: req.method, url: req.url, headers: req.headers, body, raw };
      requests.push(record);
      responder(record, res);
    });
  });
  return { server, requests };
}

async function startMock(responder) {
  const { server, requests } = createMockServer(responder);
  await new Promise((resolve) => server.listen(0, "127.0.0.1", resolve));
  const { port } = server.address();
  return {
    url: `http://127.0.0.1:${port}/v1/systemone`,
    requests,
    close: () =>
      new Promise((resolve) => {
        server.closeAllConnections?.();
        server.close(() => resolve());
      }),
  };
}

function json(res, status, payload) {
  const text = JSON.stringify(payload);
  res.writeHead(status, { "Content-Type": "application/json" });
  res.end(text);
}

function makeConfig(overrides = {}) {
  return {
    primaryUrl: "http://127.0.0.1:1/v1/systemone",
    defaultModel: "nimble:latest",
    timeoutMs: 2000,
    fallbackModelsRaw: undefined,
    fallbackUrl: "http://127.0.0.1:1/v1/systemone",
    apiKey: "",
    ...overrides,
  };
}

const PAYLOAD = { state: "the state", questions: { q: { type: "noul", instructions: "?" } } };

/* ------------------------------------------------------------------ *
 * Config / candidate resolution
 * ------------------------------------------------------------------ */

test("readConfig applies documented defaults", () => {
  const config = readConfig({});
  assert.equal(config.primaryUrl, "http://localhost:11434/v1/systemone");
  assert.equal(config.defaultModel, "nimble:latest");
  assert.equal(config.timeoutMs, 30000);
  assert.equal(config.fallbackUrl, "https://opencode.ai/inference/systemone/v1/systemone");
  assert.equal(config.fallbackModelsRaw, undefined);
  assert.equal(config.apiKey, "");
});

test("readConfig strips trailing slashes and honours env overrides", () => {
  const config = readConfig({
    OLLAMA_HOST: "http://localhost:9999///",
    SYSTEMONE_MODEL: "custom:latest",
    SYSTEMONE_TIMEOUT: "1500",
    SYSTEMONE_FALLBACK_URL: "https://example.test/api/v1/systemone/",
    SYSTEMONE_FALLBACK_MODELS: "m-one, m-two",
    OPENCODE_API_KEY: "k",
  });
  assert.equal(config.primaryUrl, "http://localhost:9999/v1/systemone");
  assert.equal(config.defaultModel, "custom:latest");
  assert.equal(config.timeoutMs, 1500);
  assert.equal(config.fallbackUrl, "https://example.test/api/v1/systemone");
  assert.equal(config.fallbackModelsRaw, "m-one, m-two");
  assert.equal(config.apiKey, "k");
});

test("readConfig falls back to 30000ms for invalid timeout", () => {
  assert.equal(readConfig({ SYSTEMONE_TIMEOUT: "nope" }).timeoutMs, 30000);
  assert.equal(readConfig({ SYSTEMONE_TIMEOUT: "-5" }).timeoutMs, 30000);
});

test("default fallback chain is free then paid on the hosted URL", () => {
  const config = makeConfig({ fallbackUrl: "https://hosted.test/v1/systemone" });
  assert.deepEqual(buildFallbackCandidates(config), [
    { url: "https://hosted.test/v1/systemone", model: "jev-1.13-free", source: "hosted" },
    { url: "https://hosted.test/v1/systemone", model: "jev-1.13", source: "hosted" },
  ]);
});

test("SYSTEMONE_FALLBACK_MODELS is an ordered comma-separated bare-ID list", () => {
  const config = makeConfig({
    fallbackModelsRaw: " a-model , b-model ,, c-model ",
    fallbackUrl: "https://hosted.test/v1/systemone",
  });
  assert.deepEqual(buildFallbackCandidates(config), [
    { url: "https://hosted.test/v1/systemone", model: "a-model", source: "hosted" },
    { url: "https://hosted.test/v1/systemone", model: "b-model", source: "hosted" },
    { url: "https://hosted.test/v1/systemone", model: "c-model", source: "hosted" },
  ]);
});

test("an empty SYSTEMONE_FALLBACK_MODELS disables hosted fallbacks", () => {
  const config = makeConfig({ fallbackModelsRaw: "" });
  assert.deepEqual(buildFallbackCandidates(config), []);
  const candidates = resolveCandidates(config, null);
  assert.equal(candidates.length, 1);
  assert.equal(candidates[0].source, "local");
});

test("resolveCandidates orders local, then hosted fallbacks", () => {
  const candidates = resolveCandidates(makeConfig(), null);
  assert.deepEqual(
    candidates.map((c) => [c.source, c.model]),
    [
      ["local", "nimble:latest"],
      ["hosted", "jev-1.13-free"],
      ["hosted", "jev-1.13"],
    ],
  );
});

test("resolveCandidates promotes a hosted override ahead of other fallbacks", () => {
  const candidates = resolveCandidates(makeConfig(), "jev-1.13");
  assert.deepEqual(
    candidates.map((c) => [c.source, c.model]),
    [
      ["hosted", "jev-1.13"],
      ["hosted", "jev-1.13-free"],
    ],
  );
  // The local primary is dropped: a hosted-only model cannot run locally.
  assert.ok(candidates.every((c) => c.source === "hosted"));
});

test("resolveCandidates keeps local primary for a local override", () => {
  const candidates = resolveCandidates(makeConfig(), "custom:latest");
  assert.equal(candidates[0].source, "local");
  assert.equal(candidates[0].model, "custom:latest");
  assert.equal(candidates.length, 3);
});

/* ------------------------------------------------------------------ *
 * Fallback behaviour
 * ------------------------------------------------------------------ */

test("returns the local primary result without touching fallbacks", async () => {
  const local = await startMock((req, res) =>
    json(res, 200, { answers: { q: { noul: 0.9 } }, usage: { total: 3 } }),
  );
  const hosted = await startMock((req, res) => json(res, 200, { answers: {} }));
  try {
    const result = await callSystemOne(PAYLOAD, {
      config: makeConfig({ primaryUrl: local.url, fallbackUrl: hosted.url }),
    });
    assert.equal(result.ok, true);
    assert.equal(result.meta.source, "local");
    assert.equal(result.meta.model, "nimble:latest");
    assert.equal(result.meta.attempts, 1);
    assert.equal(local.requests.length, 1);
    assert.equal(hosted.requests.length, 0);
    assert.equal(local.requests[0].body.model, "nimble:latest");
  } finally {
    await local.close();
    await hosted.close();
  }
});

test("falls back to the free hosted model on primary HTTP error", async () => {
  const local = await startMock((req, res) => json(res, 500, { error: "model not found" }));
  const hosted = await startMock((req, res) => json(res, 200, { answers: { q: { noul: 0.2 } } }));
  try {
    const result = await callSystemOne(PAYLOAD, {
      config: makeConfig({ primaryUrl: local.url, fallbackUrl: hosted.url }),
    });
    assert.equal(result.ok, true);
    assert.equal(result.meta.source, "hosted");
    assert.equal(result.meta.model, "jev-1.13-free");
    assert.equal(result.meta.attempts, 2);
    assert.equal(local.requests.length, 1);
    assert.equal(hosted.requests.length, 1);
    assert.equal(hosted.requests[0].body.model, "jev-1.13-free");
    // Hosted models are bare names, never prefixed.
    assert.ok(!hosted.requests[0].body.model.includes("opencode/"));
    // No key configured: no Authorization header on the keyless candidate.
    assert.equal(hosted.requests[0].headers.authorization, undefined);
  } finally {
    await local.close();
    await hosted.close();
  }
});

test("attaches the bearer key to hosted fallbacks and reaches the paid model", async () => {
  const local = await startMock((req, res) => json(res, 503, { error: "down" }));
  const hosted = await startMock((req, res) => {
    if (req.body.model === "jev-1.13-free") {
      json(res, 503, { error: "free unavailable" });
      return;
    }
    json(res, 200, { answers: { q: { noul: 0.7 } } });
  });
  try {
    const result = await callSystemOne(PAYLOAD, {
      config: makeConfig({ primaryUrl: local.url, fallbackUrl: hosted.url, apiKey: "test-key" }),
    });
    assert.equal(result.ok, true);
    assert.equal(result.meta.model, "jev-1.13");
    assert.equal(result.meta.attempts, 3);
    assert.equal(hosted.requests.length, 2);
    assert.equal(hosted.requests[0].body.model, "jev-1.13-free");
    assert.equal(hosted.requests[0].headers.authorization, "Bearer test-key");
    assert.equal(hosted.requests[1].headers.authorization, "Bearer test-key");
    assert.equal(hosted.requests[1].body.model, "jev-1.13");
  } finally {
    await local.close();
    await hosted.close();
  }
});

test("attempts every hosted fallback and aggregates errors when no key is set", async () => {
  const local = await startMock((req, res) => json(res, 500, { error: "local down" }));
  const hosted = await startMock((req, res) =>
    json(res, 500, {
      error: req.body.model === "jev-1.13-free" ? "free down" : "paid down",
    }),
  );
  try {
    const result = await callSystemOne(PAYLOAD, {
      config: makeConfig({ primaryUrl: local.url, fallbackUrl: hosted.url, apiKey: "" }),
    });
    assert.equal(result.ok, false);
    assert.match(result.error, /local down/);
    assert.match(result.error, /free down/);
    assert.match(result.error, /paid down/);
    assert.equal(hosted.requests.length, 2);
    assert.equal(hosted.requests[0].headers.authorization, undefined);
    assert.equal(hosted.requests[1].headers.authorization, undefined);
    assert.equal(result.attempts.length, 3);
  } finally {
    await local.close();
    await hosted.close();
  }
});

test("falls back on a network error at the primary", async () => {
  // Grab an ephemeral port and close it so connections are refused.
  const dead = await startMock((req, res) => json(res, 200, {}));
  const deadUrl = dead.url;
  await dead.close();

  const hosted = await startMock((req, res) => json(res, 200, { answers: {} }));
  try {
    const result = await callSystemOne(PAYLOAD, {
      config: makeConfig({ primaryUrl: deadUrl, fallbackUrl: hosted.url }),
    });
    assert.equal(result.ok, true);
    assert.equal(result.meta.model, "jev-1.13-free");
    assert.match(result.attempts[0].error, /network error/);
  } finally {
    await hosted.close();
  }
});

test("applies a per-attempt timeout and falls back", async () => {
  const local = await startMock((req, res) => {
    setTimeout(() => json(res, 200, { answers: {} }), 400);
  });
  const hosted = await startMock((req, res) => json(res, 200, { answers: { q: { noul: 0.5 } } }));
  try {
    const result = await callSystemOne(PAYLOAD, {
      config: makeConfig({ primaryUrl: local.url, fallbackUrl: hosted.url, timeoutMs: 80 }),
    });
    assert.equal(result.ok, true);
    assert.equal(result.meta.source, "hosted");
    assert.equal(local.requests.length, 1);
    assert.match(result.attempts[0].error, /timed out after 80ms/);
  } finally {
    await local.close();
    await hosted.close();
  }
});

test("treats a 200 response carrying an {error} key as a failure", async () => {
  const local = await startMock((req, res) => json(res, 200, { error: "bad model" }));
  const hosted = await startMock((req, res) => json(res, 200, { answers: {} }));
  try {
    const result = await callSystemOne(PAYLOAD, {
      config: makeConfig({ primaryUrl: local.url, fallbackUrl: hosted.url }),
    });
    assert.equal(result.ok, true);
    assert.equal(result.meta.source, "hosted");
    assert.match(result.attempts[0].error, /upstream error: bad model/);
  } finally {
    await local.close();
    await hosted.close();
  }
});

test("falls back on a non-JSON body", async () => {
  const local = await startMock((req, res) => {
    res.writeHead(200, { "Content-Type": "text/plain" });
    res.end("<html>not json</html>");
  });
  const hosted = await startMock((req, res) => json(res, 200, { answers: {} }));
  try {
    const result = await callSystemOne(PAYLOAD, {
      config: makeConfig({ primaryUrl: local.url, fallbackUrl: hosted.url }),
    });
    assert.equal(result.ok, true);
    assert.match(result.attempts[0].error, /non-JSON response/);
  } finally {
    await local.close();
    await hosted.close();
  }
});

test("never leaks the API key in aggregated errors", async () => {
  const secret = "topsecret-token";
  const local = await startMock((req, res) => json(res, 500, { error: "nope" }));
  const hosted = await startMock((req, res) => json(res, 500, { error: "nope" }));
  try {
    const result = await callSystemOne(PAYLOAD, {
      config: makeConfig({ primaryUrl: local.url, fallbackUrl: hosted.url, apiKey: secret }),
    });
    assert.equal(result.ok, false);
    assert.ok(!JSON.stringify(result).includes(secret), "result must not contain the API key");
    assert.equal(hosted.requests[0].headers.authorization, `Bearer ${secret}`);
    assert.equal(hosted.requests[1].headers.authorization, `Bearer ${secret}`);
  } finally {
    await local.close();
    await hosted.close();
  }
});

test("a hosted-model override calls the hosted endpoint directly", async () => {
  const local = await startMock((req, res) => json(res, 200, { answers: {} }));
  const hosted = await startMock((req, res) => json(res, 200, { answers: {} }));
  try {
    const result = await callSystemOne(
      { ...PAYLOAD, model: "jev-1.13" },
      { config: makeConfig({ primaryUrl: local.url, fallbackUrl: hosted.url, apiKey: "k" }) },
    );
    assert.equal(result.ok, true);
    assert.equal(result.meta.model, "jev-1.13");
    assert.equal(result.meta.source, "hosted");
    assert.equal(local.requests.length, 0);
    assert.equal(hosted.requests.length, 1);
    assert.equal(hosted.requests[0].body.model, "jev-1.13");
  } finally {
    await local.close();
    await hosted.close();
  }
});

test("a local-model override is used for the primary then falls back", async () => {
  const local = await startMock((req, res) => json(res, 500, { error: "missing" }));
  const hosted = await startMock((req, res) => json(res, 200, { answers: {} }));
  try {
    const result = await callSystemOne(
      { ...PAYLOAD, model: "custom:latest" },
      { config: makeConfig({ primaryUrl: local.url, fallbackUrl: hosted.url }) },
    );
    assert.equal(result.ok, true);
    assert.equal(local.requests[0].body.model, "custom:latest");
    assert.equal(result.meta.model, "jev-1.13-free");
  } finally {
    await local.close();
    await hosted.close();
  }
});

test("a custom SYSTEMONE_FALLBACK_MODELS chain is honoured", async () => {
  const local = await startMock((req, res) => json(res, 500, { error: "down" }));
  const hosted = await startMock((req, res) => json(res, 200, { answers: {} }));
  try {
    const result = await callSystemOne(PAYLOAD, {
      config: makeConfig({
        primaryUrl: local.url,
        fallbackUrl: hosted.url,
        fallbackModelsRaw: "custom-free,custom-paid",
      }),
    });
    assert.equal(result.ok, true);
    assert.equal(result.meta.model, "custom-free");
    assert.equal(hosted.requests.length, 1);
    assert.equal(hosted.requests[0].body.model, "custom-free");
  } finally {
    await local.close();
    await hosted.close();
  }
});
