#!/usr/bin/env node
/**
 * local-first-systemone-mcp
 *
 * Exposes System One decision models (TypeSafe / Jev API) as MCP
 * tools. Decision models do not generate text: they score one-token answer
 * codes and return calibrated probabilities. This server is a thin, typed
 * transport over POST {HOST}/v1/systemone.
 *
 * Transport: newline-delimited JSON-RPC 2.0 over stdio. No dependencies.
 *
 * Fallback chain
 * --------------
 * Every tool call tries an ordered list of candidates and returns the first
 * success. Default order:
 *   1. local  - SYSTEMONE_MODEL           at {OLLAMA_HOST}/v1/systemone (nimble:latest)
 *   2. hosted - SYSTEMONE_FALLBACK_MODELS at SYSTEMONE_FALLBACK_URL    (jev-1.13-free)
 *   3. hosted - SYSTEMONE_FALLBACK_MODELS at SYSTEMONE_FALLBACK_URL    (jev-1.13, paid)
 *
 * The hosted fallback models come from SYSTEMONE_FALLBACK_MODELS, an ordered
 * comma-separated list of bare model IDs. OPENCODE_API_KEY, when set, is sent
 * as a bearer token on every hosted attempt (harmless for the keyless model);
 * when unset, hosted attempts are still made and a paid-only model simply
 * returns an auth error that is aggregated with the rest. Later candidates are
 * attempted after any failure: network error, per-attempt timeout, non-2xx
 * status, unparseable body, or an {error} payload. Each attempt gets its own
 * timeout. When every candidate fails, the errors are aggregated into a single
 * message. Secrets are never logged or returned.
 *
 * The hosted endpoint expects bare model names (no `opencode/` prefix) and the
 * same typed System One request/response shape as Ollama.
 *
 * A tool-level `model` argument overrides the primary (local) model. If the
 * override names a hosted fallback model, that candidate is promoted to the
 * front and the local attempt is skipped, since a hosted-only model cannot be
 * served by local Ollama.
 *
 * Environment:
 *   OLLAMA_HOST                Base URL of the local Ollama server. Default http://localhost:11434
 *   SYSTEMONE_MODEL            Primary (local) model. Default nimble:latest
 *   SYSTEMONE_TIMEOUT          Per-attempt timeout in ms. Default 30000
 *   SYSTEMONE_FALLBACK_URL     Full hosted System One endpoint.
 *                              Default https://opencode.ai/inference/systemone/v1/systemone
 *   SYSTEMONE_FALLBACK_MODELS  Ordered, comma-separated bare model IDs for the hosted
 *                              fallback chain. Default jev-1.13-free,jev-1.13. An empty
 *                              string disables hosted fallbacks.
 *   OPENCODE_API_KEY           Optional bearer token for the hosted fallback attempts.
 *                              Its format is not validated here.
 */

import { createInterface } from "node:readline";
import { pathToFileURL } from "node:url";

const CONFIDENCE_GATE = 0.7;

const SERVER_INFO = { name: "local-first-systemone", version: "1.0.1" };
const SUPPORTED_PROTOCOLS = ["2025-06-18", "2025-03-26", "2024-11-05"];

/* ------------------------------------------------------------------ *
 * Configuration
 * ------------------------------------------------------------------ */

function parseTimeout(raw) {
  const parsed = Number.parseInt(raw ?? "30000", 10);
  return Number.isFinite(parsed) && parsed > 0 ? parsed : 30000;
}

function stripTrailingSlash(url) {
  return url.replace(/\/+$/, "");
}

/**
 * Resolve runtime configuration from an environment map.
 * @param {NodeJS.ProcessEnv} [env]
 */
function readConfig(env = process.env) {
  const host = stripTrailingSlash(env.OLLAMA_HOST ?? "http://localhost:11434");
  return {
    primaryUrl: `${host}/v1/systemone`,
    defaultModel: env.SYSTEMONE_MODEL ?? "nimble:latest",
    timeoutMs: parseTimeout(env.SYSTEMONE_TIMEOUT),
    fallbackModelsRaw: env.SYSTEMONE_FALLBACK_MODELS,
    fallbackUrl: stripTrailingSlash(
      env.SYSTEMONE_FALLBACK_URL ??
        "https://opencode.ai/inference/systemone/v1/systemone",
    ),
    apiKey: env.OPENCODE_API_KEY ?? "",
  };
}

const DEFAULT_FALLBACK_MODELS = ["jev-1.13-free", "jev-1.13"];

/**
 * Build the ordered hosted fallback candidates from SYSTEMONE_FALLBACK_MODELS.
 *
 * The value is an ordered, comma-separated list of bare model IDs. When unset,
 * DEFAULT_FALLBACK_MODELS is used; an explicitly empty value disables hosted
 * fallbacks. All candidates share SYSTEMONE_FALLBACK_URL.
 *
 * @returns {Array<{url: string, model: string, source: "hosted"}>}
 */
function buildFallbackCandidates(config) {
  const models =
    typeof config.fallbackModelsRaw === "string"
      ? config.fallbackModelsRaw
          .split(",")
          .map((model) => model.trim())
          .filter((model) => model !== "")
      : DEFAULT_FALLBACK_MODELS;

  return models.map((model) => ({
    url: config.fallbackUrl,
    model,
    source: "hosted",
  }));
}

/**
 * Resolve the ordered candidate list for one call.
 *
 * @param {ReturnType<typeof readConfig>} config
 * @param {string|null|undefined} overrideModel tool-level `model` argument
 */
function resolveCandidates(config, overrideModel) {
  const override =
    typeof overrideModel === "string" && overrideModel.trim() !== ""
      ? overrideModel.trim()
      : null;
  const fallbacks = buildFallbackCandidates(config);

  const promoted = override
    ? fallbacks.findIndex((candidate) => candidate.model === override)
    : -1;
  let chain;
  if (promoted !== -1) {
    chain = [
      { ...fallbacks[promoted] },
      ...fallbacks.filter((_, index) => index !== promoted),
    ];
  } else {
    chain = [
      {
        url: config.primaryUrl,
        model: override ?? config.defaultModel,
        source: "local",
      },
      ...fallbacks,
    ];
  }

  const seen = new Set();
  const deduped = [];
  for (const candidate of chain) {
    const key = `${candidate.url}::${candidate.model}`;
    if (seen.has(key)) {
      continue;
    }
    seen.add(key);
    deduped.push(candidate);
  }

  return deduped;
}

/* ------------------------------------------------------------------ *
 * Upstream call
 * ------------------------------------------------------------------ */

/**
 * Perform a single candidate attempt with its own timeout.
 *
 * @param {{url: string, model: string, source: "local"|"hosted"}} candidate
 * @param {object} body
 * @param {{timeoutMs: number, fetchImpl: typeof fetch, apiKey: string}} options
 * @returns {Promise<{ok: true, data: object} | {ok: false, error: string}>}
 */
async function attemptSystemOne(candidate, body, options) {
  const { timeoutMs, fetchImpl, apiKey } = options;
  const controller = new AbortController();
  const timer = setTimeout(() => controller.abort(), timeoutMs);

  try {
    const headers = { "Content-Type": "application/json" };
    // The bearer is only ever sent to the hosted fallback endpoint.
    if (apiKey) {
      headers.Authorization = `Bearer ${apiKey}`;
    }

    const response = await fetchImpl(candidate.url, {
      method: "POST",
      headers,
      body: JSON.stringify(body),
      signal: controller.signal,
    });

    const text = await response.text();
    let parsed;
    try {
      parsed = JSON.parse(text);
    } catch {
      return {
        ok: false,
        error: `non-JSON response (HTTP ${response.status}): ${text.slice(0, 300)}`,
      };
    }

    // Upstream reports model and validation failures as {error: "..."} with a
    // 4xx/5xx status, but occasionally with 200. Treat any `error` key as fatal.
    if (
      parsed &&
      typeof parsed === "object" &&
      typeof parsed.error === "string"
    ) {
      return { ok: false, error: `upstream error: ${parsed.error}` };
    }
    if (!response.ok) {
      return {
        ok: false,
        error: `HTTP ${response.status}: ${text.slice(0, 300)}`,
      };
    }
    return { ok: true, data: parsed };
  } catch (error) {
    if (error?.name === "AbortError") {
      return { ok: false, error: `timed out after ${timeoutMs}ms` };
    }
    const message = error instanceof Error ? error.message : String(error);
    return { ok: false, error: `network error: ${message}` };
  } finally {
    clearTimeout(timer);
  }
}

/**
 * POST a System One request, walking the candidate chain until one succeeds.
 *
 * @param {{model?: string, state: unknown, questions: Record<string, object>}} payload
 * @param {{config?: object, fetchImpl?: typeof fetch}} [options]
 * @returns {Promise<
 *   | {ok: true, data: object, meta: {model: string, source: string, url: string, attempts: number}}
 *   | {ok: false, error: string, attempts: Array<object>}
 * >}
 */
async function callSystemOne(payload, options = {}) {
  const config = options.config ?? readConfig(process.env);
  const fetchImpl = options.fetchImpl ?? fetch;
  const override =
    typeof payload?.model === "string" && payload.model.trim() !== ""
      ? payload.model.trim()
      : null;
  const candidates = resolveCandidates(config, override);

  const attempts = [];
  for (const candidate of candidates) {
    const body = { ...payload, model: candidate.model };
    const outcome = await attemptSystemOne(candidate, body, {
      timeoutMs: config.timeoutMs,
      fetchImpl,
      // Only the hosted fallback endpoint receives the bearer token.
      apiKey: candidate.source === "hosted" ? config.apiKey : "",
    });

    if (outcome.ok) {
      return {
        ok: true,
        data: outcome.data,
        meta: {
          model: candidate.model,
          source: candidate.source,
          url: candidate.url,
          attempts: attempts.length + 1,
        },
        attempts,
      };
    }

    attempts.push({
      source: candidate.source,
      model: candidate.model,
      url: candidate.url,
      error: outcome.error,
    });
  }

  const details = attempts
    .map(
      (attempt) =>
        `- ${attempt.source} ${attempt.model} at ${attempt.url}: ${attempt.error}`,
    )
    .join("\n");
  return {
    ok: false,
    error: `System One failed on all ${attempts.length} candidate(s):\n${details}`,
    attempts,
  };
}

/* ------------------------------------------------------------------ *
 * Question validation
 * ------------------------------------------------------------------ */

/**
 * Normalise and validate a question object against the System One contract.
 * Returns {question} on success or {error} on failure.
 */
function normaliseQuestion(id, raw) {
  if (!raw || typeof raw !== "object" || Array.isArray(raw)) {
    return { error: `question "${id}": must be an object` };
  }
  const { type, instructions, criteria } = raw;

  if (typeof instructions !== "string" || instructions.trim() === "") {
    return { error: `question "${id}": "instructions" is required` };
  }

  if (type === "noul") {
    // criteria is optional for noul: Ollama accepts the question without it.
    // When supplied, accept an object map {true, false} or a 2-element array.
    if (criteria === undefined || criteria === null) {
      return { question: { type, instructions } };
    }
    let resolved;
    if (Array.isArray(criteria)) {
      if (criteria.length !== 2) {
        return {
          error: `question "${id}": noul criteria array must have exactly 2 entries`,
        };
      }
      resolved = { true: String(criteria[0]), false: String(criteria[1]) };
    } else if (typeof criteria === "object") {
      if (
        typeof criteria.true !== "string" ||
        typeof criteria.false !== "string"
      ) {
        return {
          error: `question "${id}": noul criteria must have "true" and "false" strings`,
        };
      }
      resolved = { true: criteria.true, false: criteria.false };
    } else {
      return {
        error: `question "${id}": noul criteria must be an object or a 2-element array`,
      };
    }
    return { question: { type, instructions, criteria: resolved } };
  }

  if (type === "choice") {
    // Ollama requires an object map {option: description}.
    if (!criteria || typeof criteria !== "object" || Array.isArray(criteria)) {
      return {
        error: `question "${id}": choice criteria must be an object map of {option: description}`,
      };
    }
    const entries = Object.entries(criteria);
    if (entries.length < 2) {
      return { error: `question "${id}": choice requires at least 2 options` };
    }
    if (entries.length > 255) {
      return { error: `question "${id}": choice supports at most 255 options` };
    }
    for (const [option, description] of entries) {
      if (typeof description !== "string" || description.trim() === "") {
        return {
          error: `question "${id}": option "${option}" needs a non-empty description`,
        };
      }
    }
    return { question: { type, instructions, criteria } };
  }

  if (type === "score") {
    // Ollama requires an ARRAY of ordered level descriptions, lowest first.
    if (!Array.isArray(criteria)) {
      return {
        error: `question "${id}": score criteria must be an array of descriptions, lowest first`,
      };
    }
    if (criteria.length < 2) {
      return { error: `question "${id}": score requires at least 2 levels` };
    }
    if (criteria.length > 255) {
      return { error: `question "${id}": score supports at most 255 levels` };
    }
    for (const level of criteria) {
      if (typeof level !== "string" || level.trim() === "") {
        return {
          error: `question "${id}": every score level needs a non-empty description`,
        };
      }
    }
    return { question: { type, instructions, criteria } };
  }

  return { error: `question "${id}": type must be choice, noul, or score` };
}

/* ------------------------------------------------------------------ *
 * Tool definitions
 * ------------------------------------------------------------------ */

const DEFAULT_CONFIG = readConfig(process.env);
const DEFAULT_MODEL = DEFAULT_CONFIG.defaultModel;

const QUESTION_SCHEMA = {
  type: "object",
  description:
    "Map of question ID to question. Each question is a typed decision about the shared state.",
  minProperties: 1,
  maxProperties: 64,
  additionalProperties: {
    type: "object",
    required: ["type", "instructions"],
    properties: {
      type: {
        type: "string",
        enum: ["choice", "noul", "score"],
        description:
          "choice: pick one labelled option. noul: probability a statement is true. score: expected level on an ordered rubric.",
      },
      instructions: {
        type: "string",
        description: "The question itself, phrased as a single decision.",
      },
      criteria: {
        description:
          "choice: object map {option: description}, 2-255 options. noul: {true: desc, false: desc}. score: array of level descriptions, lowest first, 2-255 levels.",
      },
    },
  },
};

const TOOLS = [
  {
    name: "route_decision",
    description:
      "Route a task to one of a known set of lanes or labels. Use for simple list decisions where the answer is one label from a small enumerable set (which sub-agent owns this, which file, which config key). Returns the chosen label, per-option probabilities, and a calibrated confidence. Confidence is calibration, not correctness: treat < 0.80 as unresolved and escalate to a full reasoning model rather than re-asking.",
    inputSchema: {
      type: "object",
      required: ["state", "options"],
      properties: {
        state: {
          description:
            "The text or JSON to judge. A string, or an object/array for structured input.",
        },
        options: {
          type: "object",
          minProperties: 2,
          maxProperties: 255,
          description:
            "Map of {label: description}. The model picks exactly one label.",
        },
        instructions: {
          type: "string",
          description:
            "The routing question, e.g. 'Which lane should handle this task?'",
          default: "Which option best fits this state?",
        },
        model: {
          type: "string",
          description: `Decision model to use. Defaults to the primary local model ${DEFAULT_MODEL}, with hosted fallbacks.`,
        },
      },
    },
  },
  {
    name: "check_condition",
    description:
      "Ask one or more yes/no questions about a piece of text. Returns the probability each statement is true. Use for cheap gating decisions (does this contain a secret, is this in scope, should this be reviewed).",
    inputSchema: {
      type: "object",
      required: ["state", "questions"],
      properties: {
        state: {
          description: "The text or JSON to judge.",
        },
        questions: {
          type: "object",
          minProperties: 1,
          maxProperties: 64,
          description:
            "Map of {questionId: {instructions, criteria?}}. criteria is optional and may be {true: desc, false: desc}.",
          additionalProperties: {
            type: "object",
            required: ["instructions"],
            properties: {
              instructions: { type: "string" },
              criteria: {
                type: "object",
                properties: {
                  true: { type: "string" },
                  false: { type: "string" },
                },
              },
            },
          },
        },
        model: {
          type: "string",
          description: `Decision model to use. Defaults to the primary local model ${DEFAULT_MODEL}, with hosted fallbacks.`,
        },
      },
    },
  },
  {
    name: "score_rubric",
    description:
      "Rate a piece of text against an ordered rubric. Returns the expected level (0-based, may be fractional) plus per-level probabilities. Use for severity, complexity, or quality grading where the levels are ordered.",
    inputSchema: {
      type: "object",
      required: ["state", "levels"],
      properties: {
        state: {
          description: "The text or JSON to judge.",
        },
        levels: {
          type: "array",
          minItems: 2,
          maxItems: 255,
          items: { type: "string" },
          description: "Ordered level descriptions, lowest first.",
        },
        instructions: {
          type: "string",
          description:
            "What is being rated, e.g. 'Rate the severity of this issue.'",
          default: "Rate this state against the ordered levels.",
        },
        model: {
          type: "string",
          description: `Decision model to use. Defaults to the primary local model ${DEFAULT_MODEL}, with hosted fallbacks.`,
        },
      },
    },
  },
  {
    name: "decide",
    description:
      "General-purpose System One call. Send a state plus up to 64 typed questions (choice, noul, score) in one round trip. Use when the three convenience tools do not fit, or when several different decision types are needed about the same state in a single call.",
    inputSchema: {
      type: "object",
      required: ["state", "questions"],
      properties: {
        state: {
          description: "The text or JSON to judge.",
        },
        questions: QUESTION_SCHEMA,
        model: {
          type: "string",
          description: `Decision model to use. Defaults to the primary local model ${DEFAULT_MODEL}, with hosted fallbacks.`,
        },
      },
    },
  },
];

/* ------------------------------------------------------------------ *
 * Tool handlers
 * ------------------------------------------------------------------ */

function textResult(payload, isError = false) {
  return {
    content: [{ type: "text", text: JSON.stringify(payload, null, 2) }],
    ...(isError ? { isError: true } : {}),
  };
}

function errorResult(message) {
  return textResult({ error: message }, true);
}

/** Non-secret provenance of the candidate that served a successful call. */
function servedBy(result) {
  return {
    model: result.meta?.model ?? null,
    provider: result.meta?.source ?? null,
  };
}

async function handleRouteDecision(args) {
  const { state, options, instructions, model } = args ?? {};
  if (state === undefined || state === null) {
    return errorResult("`state` is required");
  }
  if (!options || typeof options !== "object" || Array.isArray(options)) {
    return errorResult(
      "`options` must be an object map of {label: description}",
    );
  }

  const built = normaliseQuestion("route", {
    type: "choice",
    instructions: instructions ?? "Which option best fits this state?",
    criteria: options,
  });
  if (built.error) {
    return errorResult(built.error);
  }

  const result = await callSystemOne({
    model,
    state,
    questions: { route: built.question },
  });
  if (!result.ok) {
    return errorResult(result.error);
  }

  const answer = result.data?.answers?.route ?? {};
  const confidence =
    typeof answer.confidence === "number" ? answer.confidence : null;
  return textResult({
    choice: answer.choice ?? null,
    probabilities: answer.probabilities ?? {},
    confidence,
    // Surface the gate decision so the caller does not have to re-derive it.
    gate:
      confidence === null
        ? "unknown"
        : confidence >= CONFIDENCE_GATE
          ? "act"
          : "escalate",
    threshold: CONFIDENCE_GATE,
    usage: result.data?.usage ?? null,
    ...servedBy(result),
  });
}

async function handleCheckCondition(args) {
  const { state, questions, model } = args ?? {};
  if (state === undefined || state === null) {
    return errorResult("`state` is required");
  }
  if (!questions || typeof questions !== "object" || Array.isArray(questions)) {
    return errorResult(
      "`questions` must be an object map of {questionId: {instructions}}",
    );
  }

  const built = {};
  for (const [id, raw] of Object.entries(questions)) {
    const normalised = normaliseQuestion(id, { ...raw, type: "noul" });
    if (normalised.error) {
      return errorResult(normalised.error);
    }
    built[id] = normalised.question;
  }

  const result = await callSystemOne({ model, state, questions: built });
  if (!result.ok) {
    return errorResult(result.error);
  }

  const answers = result.data?.answers ?? {};
  const out = {};
  for (const [id, answer] of Object.entries(answers)) {
    const probability = typeof answer?.noul === "number" ? answer.noul : null;
    out[id] = {
      probability,
      verdict: probability === null ? "unknown" : probability >= 0.5,
      // Distance from the 0.5 decision boundary, as a rough decisiveness signal.
      margin: probability === null ? null : Math.abs(probability - 0.5) * 2,
    };
  }
  return textResult({
    answers: out,
    usage: result.data?.usage ?? null,
    ...servedBy(result),
  });
}

async function handleScoreRubric(args) {
  const { state, levels, instructions, model } = args ?? {};
  if (state === undefined || state === null) {
    return errorResult("`state` is required");
  }
  if (!Array.isArray(levels)) {
    return errorResult(
      "`levels` must be an array of ordered descriptions, lowest first",
    );
  }

  const built = normaliseQuestion("score", {
    type: "score",
    instructions: instructions ?? "Rate this state against the ordered levels.",
    criteria: levels,
  });
  if (built.error) {
    return errorResult(built.error);
  }

  const result = await callSystemOne({
    model,
    state,
    questions: { score: built.question },
  });
  if (!result.ok) {
    return errorResult(result.error);
  }

  const answer = result.data?.answers?.score ?? {};
  const score = typeof answer.score === "number" ? answer.score : null;
  return textResult({
    score,
    // The nearest integer level is usually what a caller wants to branch on.
    level: score === null ? null : Math.round(score),
    legend: answer.legend ?? {},
    probabilities: answer.probabilities ?? {},
    confidence:
      typeof answer.confidence === "number" ? answer.confidence : null,
    usage: result.data?.usage ?? null,
    ...servedBy(result),
  });
}

async function handleDecide(args) {
  const { state, questions, model } = args ?? {};
  if (state === undefined || state === null) {
    return errorResult("`state` is required");
  }
  if (!questions || typeof questions !== "object" || Array.isArray(questions)) {
    return errorResult(
      "`questions` must be an object map of question ID to question",
    );
  }
  const ids = Object.keys(questions);
  if (ids.length === 0) {
    return errorResult("`questions` must contain at least one question");
  }
  if (ids.length > 64) {
    return errorResult(
      `System One supports at most 64 questions per call; got ${ids.length}`,
    );
  }

  const built = {};
  for (const [id, raw] of Object.entries(questions)) {
    const normalised = normaliseQuestion(id, raw);
    if (normalised.error) {
      return errorResult(normalised.error);
    }
    built[id] = normalised.question;
  }

  const result = await callSystemOne({ model, state, questions: built });
  if (!result.ok) {
    return errorResult(result.error);
  }
  return textResult({ ...result.data, ...servedBy(result) });
}

const HANDLERS = {
  route_decision: handleRouteDecision,
  check_condition: handleCheckCondition,
  score_rubric: handleScoreRubric,
  decide: handleDecide,
};

/* ------------------------------------------------------------------ *
 * JSON-RPC / MCP plumbing
 * ------------------------------------------------------------------ */

function send(message) {
  process.stdout.write(`${JSON.stringify(message)}\n`);
}

function reply(id, result) {
  send({ jsonrpc: "2.0", id, result });
}

function replyError(id, code, message, data) {
  send({
    jsonrpc: "2.0",
    id,
    error: { code, message, ...(data ? { data } : {}) },
  });
}

async function handleMessage(message) {
  const { id, method, params } = message;

  // Notifications carry no id and expect no response.
  const isNotification = id === undefined || id === null;

  switch (method) {
    case "initialize": {
      const requested = params?.protocolVersion;
      const protocolVersion = SUPPORTED_PROTOCOLS.includes(requested)
        ? requested
        : SUPPORTED_PROTOCOLS[0];
      reply(id, {
        protocolVersion,
        capabilities: { tools: { listChanged: false } },
        serverInfo: SERVER_INFO,
      });
      return;
    }

    case "notifications/initialized":
    case "notifications/cancelled":
      return;

    case "ping":
      reply(id, {});
      return;

    case "tools/list":
      reply(id, { tools: TOOLS });
      return;

    case "tools/call": {
      const name = params?.name;
      const handler = HANDLERS[name];
      if (!handler) {
        replyError(id, -32602, `Unknown tool: ${name}`);
        return;
      }
      try {
        const result = await handler(params?.arguments ?? {});
        reply(id, result);
      } catch (error) {
        const message = error instanceof Error ? error.message : String(error);
        reply(id, errorResult(`Internal error in ${name}: ${message}`));
      }
      return;
    }

    default:
      if (!isNotification) {
        replyError(id, -32601, `Method not found: ${method}`);
      }
  }
}

let queue = Promise.resolve();

function main() {
  const rl = createInterface({ input: process.stdin, crlfDelay: Infinity });

  rl.on("line", (line) => {
    const trimmed = line.trim();
    if (trimmed === "") {
      return;
    }
    let message;
    try {
      message = JSON.parse(trimmed);
    } catch {
      replyError(null, -32700, "Parse error");
      return;
    }
    // Serialise handling so responses stay ordered and errors cannot interleave.
    queue = queue
      .then(() => handleMessage(message))
      .catch((error) => {
        const text = error instanceof Error ? error.message : String(error);
        replyError(message?.id ?? null, -32603, `Internal error: ${text}`);
      });
  });

  rl.on("close", () => process.exit(0));
}

// Only start the stdio loop when executed directly, so the module stays
// importable for tests.
if (
  process.argv[1] &&
  import.meta.url === pathToFileURL(process.argv[1]).href
) {
  main();
}

export {
  callSystemOne,
  readConfig,
  buildFallbackCandidates,
  resolveCandidates,
  normaliseQuestion,
};
