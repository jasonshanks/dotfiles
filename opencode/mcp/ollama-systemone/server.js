#!/usr/bin/env node
/**
 * ollama-systemone-mcp
 *
 * Exposes local Ollama System One decision models (TypeSafe / Jev API) as MCP
 * tools. Decision models do not generate text: they score one-token answer
 * codes and return calibrated probabilities. This server is a thin, typed
 * transport over POST {OLLAMA_HOST}/v1/systemone.
 *
 * Transport: newline-delimited JSON-RPC 2.0 over stdio. No dependencies.
 *
 * Environment:
 *   OLLAMA_HOST        Base URL of the Ollama server. Default http://localhost:11434
 *   SYSTEMONE_MODEL    Default model. Default nimble:latest
 *   SYSTEMONE_TIMEOUT  Per-request timeout in ms. Default 30000
 */

import { createInterface } from "node:readline";

const OLLAMA_HOST = (process.env.OLLAMA_HOST ?? "http://localhost:11434").replace(/\/+$/, "");
const DEFAULT_MODEL = process.env.SYSTEMONE_MODEL ?? "nimble:latest";
const CONFIDENCE_GATE = 0.7;
const TIMEOUT_MS = Number.parseInt(process.env.SYSTEMONE_TIMEOUT ?? "30000", 10);
const SYSTEMONE_URL = `${OLLAMA_HOST}/v1/systemone`;

const SERVER_INFO = { name: "ollama-systemone", version: "1.0.0" };
const SUPPORTED_PROTOCOLS = ["2025-06-18", "2025-03-26", "2024-11-05"];

/* ------------------------------------------------------------------ *
 * Upstream call
 * ------------------------------------------------------------------ */

/**
 * POST a System One request to Ollama.
 * @param {{model?: string, state: unknown, questions: Record<string, object>}} payload
 * @returns {Promise<{ok: true, data: object} | {ok: false, error: string}>}
 */
async function callSystemOne(payload) {
  const controller = new AbortController();
  const timer = setTimeout(() => controller.abort(), TIMEOUT_MS);

  try {
    const response = await fetch(SYSTEMONE_URL, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(payload),
      signal: controller.signal,
    });

    const text = await response.text();
    let parsed;
    try {
      parsed = JSON.parse(text);
    } catch {
      return {
        ok: false,
        error: `Ollama returned non-JSON (HTTP ${response.status}): ${text.slice(0, 300)}`,
      };
    }

    // Ollama reports model and validation failures as {error: "..."} with a
    // 4xx/5xx status, but occasionally with 200. Treat any `error` key as fatal.
    if (parsed && typeof parsed === "object" && typeof parsed.error === "string") {
      return { ok: false, error: parsed.error };
    }
    if (!response.ok) {
      return { ok: false, error: `Ollama HTTP ${response.status}: ${text.slice(0, 300)}` };
    }
    return { ok: true, data: parsed };
  } catch (error) {
    if (error?.name === "AbortError") {
      return { ok: false, error: `Request timed out after ${TIMEOUT_MS}ms at ${SYSTEMONE_URL}` };
    }
    const message = error instanceof Error ? error.message : String(error);
    return {
      ok: false,
      error: `Could not reach Ollama at ${SYSTEMONE_URL}: ${message}. Is \`ollama serve\` running?`,
    };
  } finally {
    clearTimeout(timer);
  }
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
        return { error: `question "${id}": noul criteria array must have exactly 2 entries` };
      }
      resolved = { true: String(criteria[0]), false: String(criteria[1]) };
    } else if (typeof criteria === "object") {
      if (typeof criteria.true !== "string" || typeof criteria.false !== "string") {
        return { error: `question "${id}": noul criteria must have "true" and "false" strings` };
      }
      resolved = { true: criteria.true, false: criteria.false };
    } else {
      return { error: `question "${id}": noul criteria must be an object or a 2-element array` };
    }
    return { question: { type, instructions, criteria: resolved } };
  }

  if (type === "choice") {
    // Ollama requires an object map {option: description}.
    if (!criteria || typeof criteria !== "object" || Array.isArray(criteria)) {
      return { error: `question "${id}": choice criteria must be an object map of {option: description}` };
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
        return { error: `question "${id}": option "${option}" needs a non-empty description` };
      }
    }
    return { question: { type, instructions, criteria } };
  }

  if (type === "score") {
    // Ollama requires an ARRAY of ordered level descriptions, lowest first.
    if (!Array.isArray(criteria)) {
      return { error: `question "${id}": score criteria must be an array of descriptions, lowest first` };
    }
    if (criteria.length < 2) {
      return { error: `question "${id}": score requires at least 2 levels` };
    }
    if (criteria.length > 255) {
      return { error: `question "${id}": score supports at most 255 levels` };
    }
    for (const level of criteria) {
      if (typeof level !== "string" || level.trim() === "") {
        return { error: `question "${id}": every score level needs a non-empty description` };
      }
    }
    return { question: { type, instructions, criteria } };
  }

  return { error: `question "${id}": type must be choice, noul, or score` };
}

/* ------------------------------------------------------------------ *
 * Tool definitions
 * ------------------------------------------------------------------ */

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
          description: "Map of {label: description}. The model picks exactly one label.",
        },
        instructions: {
          type: "string",
          description: "The routing question, e.g. 'Which lane should handle this task?'",
          default: "Which option best fits this state?",
        },
        model: {
          type: "string",
          description: `Ollama decision model to use. Defaults to ${DEFAULT_MODEL}.`,
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
                properties: { true: { type: "string" }, false: { type: "string" } },
              },
            },
          },
        },
        model: {
          type: "string",
          description: `Ollama decision model to use. Defaults to ${DEFAULT_MODEL}.`,
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
          description: "What is being rated, e.g. 'Rate the severity of this issue.'",
          default: "Rate this state against the ordered levels.",
        },
        model: {
          type: "string",
          description: `Ollama decision model to use. Defaults to ${DEFAULT_MODEL}.`,
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
          description: `Ollama decision model to use. Defaults to ${DEFAULT_MODEL}.`,
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

async function handleRouteDecision(args) {
  const { state, options, instructions, model } = args ?? {};
  if (state === undefined || state === null) {
    return errorResult("`state` is required");
  }
  if (!options || typeof options !== "object" || Array.isArray(options)) {
    return errorResult("`options` must be an object map of {label: description}");
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
    model: model ?? DEFAULT_MODEL,
    state,
    questions: { route: built.question },
  });
  if (!result.ok) {
    return errorResult(result.error);
  }

  const answer = result.data?.answers?.route ?? {};
  const confidence = typeof answer.confidence === "number" ? answer.confidence : null;
  return textResult({
    choice: answer.choice ?? null,
    probabilities: answer.probabilities ?? {},
    confidence,
    // Surface the gate decision so the caller does not have to re-derive it.
    gate: confidence === null ? "unknown" : confidence >= CONFIDENCE_GATE ? "act" : "escalate",
    threshold: CONFIDENCE_GATE,
    usage: result.data?.usage ?? null,
  });
}

async function handleCheckCondition(args) {
  const { state, questions, model } = args ?? {};
  if (state === undefined || state === null) {
    return errorResult("`state` is required");
  }
  if (!questions || typeof questions !== "object" || Array.isArray(questions)) {
    return errorResult("`questions` must be an object map of {questionId: {instructions}}");
  }

  const built = {};
  for (const [id, raw] of Object.entries(questions)) {
    const normalised = normaliseQuestion(id, { ...raw, type: "noul" });
    if (normalised.error) {
      return errorResult(normalised.error);
    }
    built[id] = normalised.question;
  }

  const result = await callSystemOne({ model: model ?? DEFAULT_MODEL, state, questions: built });
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
  return textResult({ answers: out, usage: result.data?.usage ?? null });
}

async function handleScoreRubric(args) {
  const { state, levels, instructions, model } = args ?? {};
  if (state === undefined || state === null) {
    return errorResult("`state` is required");
  }
  if (!Array.isArray(levels)) {
    return errorResult("`levels` must be an array of ordered descriptions, lowest first");
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
    model: model ?? DEFAULT_MODEL,
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
    confidence: typeof answer.confidence === "number" ? answer.confidence : null,
    usage: result.data?.usage ?? null,
  });
}

async function handleDecide(args) {
  const { state, questions, model } = args ?? {};
  if (state === undefined || state === null) {
    return errorResult("`state` is required");
  }
  if (!questions || typeof questions !== "object" || Array.isArray(questions)) {
    return errorResult("`questions` must be an object map of question ID to question");
  }
  const ids = Object.keys(questions);
  if (ids.length === 0) {
    return errorResult("`questions` must contain at least one question");
  }
  if (ids.length > 64) {
    return errorResult(`System One supports at most 64 questions per call; got ${ids.length}`);
  }

  const built = {};
  for (const [id, raw] of Object.entries(questions)) {
    const normalised = normaliseQuestion(id, raw);
    if (normalised.error) {
      return errorResult(normalised.error);
    }
    built[id] = normalised.question;
  }

  const result = await callSystemOne({ model: model ?? DEFAULT_MODEL, state, questions: built });
  if (!result.ok) {
    return errorResult(result.error);
  }
  return textResult(result.data);
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
  send({ jsonrpc: "2.0", id, error: { code, message, ...(data ? { data } : {}) } });
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
    queue = queue.then(() => handleMessage(message)).catch((error) => {
      const text = error instanceof Error ? error.message : String(error);
      replyError(message?.id ?? null, -32603, `Internal error: ${text}`);
    });
  });

  rl.on("close", () => process.exit(0));
}

let queue = Promise.resolve();
main();