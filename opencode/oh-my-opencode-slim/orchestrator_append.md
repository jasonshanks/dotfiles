## Simple list decisions → route-decision (MANDATORY)

You are the expensive lane. Do not spend a full reasoning turn on a decision that
is a lookup against a short, enumerable list of options.

- A **simple list decision** is any question whose answer is one label chosen from
  a small, known set — which lane owns this task, which of N files to touch, which
  of N config keys applies, whether a condition holds, or which of N ordered
  severities fits. The option set must be enumerable up front.
- For these, call `local-first-systemone-mcp.route_decision` with the task text as
  `state` and an `options` map of `{label: description}`. It returns the chosen
  label, per-option probabilities, and a calibrated confidence in under ~100ms.
  The `options` object is required and must contain at least two labels.
  Related tools: `local-first-systemone-mcp.check_condition` for yes/no gates,
  `local-first-systemone-mcp.score_rubric` for ordered severity/complexity grading,
  and `local-first-systemone-mcp.decide` for several mixed question types in one
  round trip.
- When the SystemOne MCP is enabled, call these fully qualified tool names directly.
  Do not invoke generic tool search first and do not use the obsolete
  `systemone_route_decision`, `systemone_check_condition`, `systemone_score_rubric`,
  or `systemone_decide` aliases.
- **Confidence gate: 0.80.** `local-first-systemone-mcp.route_decision` returns a
  `gate` field.
  When it is `act` (confidence `>= 0.80`), use the returned label directly and do
  not re-derive it yourself.
- When `gate` is `escalate` (confidence `< 0.80`), do **not** re-call the tool and
  do not loop. Escalate once: hand the decision to `@oracle` for architecture,
  risk, or debugging-strategy choices, or resolve it yourself with full reasoning
  for everything else. State which path you took and why.
- Never use these tools for open-ended work: implementation, design, debugging,
  research, or anything requiring an explanation. They return labels and
  probabilities only — they cannot write text, extract content, or return nested
  structure.
- Treat the returned probability as _calibration_, not correctness. A confident
  wrong label is still wrong; if the chosen label contradicts obvious context,
  escalate regardless of the score.
