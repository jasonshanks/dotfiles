---
name: raycast-plus-models
description: Dynamically scrapes and curates AI models in Raycast's Plus AI plan. Guides the user through a structured multi-step flow (Curation Mode -> Presentation Format -> Optional Chart for detailed formats). Performs mandatory live web searches to verify release dates, official benchmarks, and community use cases. Generates an adaptive, smart dark-theme chart that dynamically visualizes capabilities (MCP, Vision, Reasoning, Context, Speed, Cost) tailored to the user's selected mode and presentation format, and copies the complete, uncorrupted text output to the macOS clipboard.
metadata:
  version: 5.3.0
---

# Raycast Plus Models Dynamic Curator & Live Benchmark Analyzer

This skill must work from live sources every single time it runs. **NEVER hardcode brand names, model names, release dates, benchmark numbers, costs, or use cases.** Everything must be scraped, researched, and charted dynamically.

---

## ⚡ Step 1: Ask for Curation Mode (Question 1)

When triggered by `@skills raycast plus` or a similar request, do not fetch, analyze, or output the model list yet. Ask this question first:

> Which curation mode do you want?
>
> 1. **Full / Long** — Keep up to the two latest active models per dynamically discovered brand, with capabilities, benchmarks, release dates, cost, and use cases.
> 2. **Latest / Short** — Keep only the latest active model for each dynamically discovered brand.
> 3. **Best & Recent** — Keep active models rated 3–5 intelligence bars and released within the last six months.
>
> Reply with **1**, **2**, or **3**.

_Wait for the user's answer. If the user already provided this choice in their prompt, proceed to Step 2 directly._

---

## ⚡ Step 2: Ask for Presentation Format (Question 2 — Numbers Only, No Chart)

After the curation mode is known, ask the second question using **numbers only** (no letters, and **do not suggest a chart here**):

> How should I present the selected models?
>
> 1. **Full analysis** — Rich Markdown cards with capability tags (MCP, Vision, Web Search, Reasoning Effort, Context), live-verified benchmarks, cost, and recommendation matrix.
> 2. **Simple list** — Brand on one line followed by comma-separated model names. Minimal, clean text.
> 3. **Both** — Put the simple list first, followed immediately by the full Markdown analysis.
>
> Reply with **1**, **2**, or **3**.

_Wait for the user's answer._

---

## ⚡ Step 3: Conditional Chart Question (Question 3)

The chart prompt depends strictly on what the user chose in **Step 2**:

- **If user chose Option 2 (Simple list)**:
  - **SKIP QUESTION 3 ENTIRELY.** A simple list does not need a graphic. Proceed immediately to scraping, formatting the simple list, and copying it to the clipboard.
- **If user chose Option 1 (Full analysis) OR Option 3 (Both)**:
  - Ask the third question:
  > Would you like an inline visual chart included with your results?
  >
  > 1. **Yes** — Render a tailored, high-contrast dark theme chart directly in chat matching your selected mode and capabilities.
  > 2. **No** — Text only, no graphic.
  > 3. **Both**
  >
  > Reply with **1**, **2**, or **3**.

_Wait for the user's answer before executing._

---

## Step 4: Dynamic Live Catalog Scraping

Fetch:
`https://www.raycast.com/core-features/ai/models`

Extract the embedded JSON payload containing the `models` dictionary:

1. Target **`models`** exclusively.
2. **Exclude deprecated models** (`status == "deprecated"`) unless a brand has no active alternative.
3. Dynamically extract for every active model:
   - `id`, `name`, `description`, `provider`, `provider_name`, `provider_brand`, `status`
   - `speed` (1 to 5 scale)
   - `intelligence` (1 to 5 scale)
   - `context` (token count)
   - `abilities`:
     - **AI Extensions / MCP**: `abilities.tools.supported == true`
     - **Vision**: `"vision"` key present in `abilities`
     - **Web Search**: `"web_search"` present in `abilities`
     - **Reasoning Effort**: `abilities.reasoning_effort.supported == true`

---

## Step 5: Dynamic Brand Normalization & Curation

Group models using live metadata, not a fixed list:

- If `provider == "gateway"`: Parse sub-organization from `id` (e.g. `gateway-deepseek/...` -> **DeepSeek**, `gateway-moonshotai/...` -> **Moonshot AI**, `gateway-zai/...` -> **Z.AI**, `gateway-alibaba/...` -> **Alibaba**).
- If `provider == "groq"`: Brand as **Groq (Open-Source)**.
- Standard Providers: Use `provider_name` or capitalize `provider`.

**Apply Curation Mode**:

- **Mode 1 (Full / Long)**: Sort by release date/generation; keep up to the 2 latest active models per brand.
- **Mode 2 (Latest / Short)**: Keep strictly the single latest active model per brand.
- **Mode 3 (Best & Recent)**: Filter to models with `intelligence >= 3` and verified release within the last 6 months.

---

## Step 6: 🔍 MANDATORY Live Deep Web Research

**CRITICAL RULE: Whenever Format 1 (Full Analysis) or Format 3 (Both) is selected, the LLM MUST call the `web_search` tool across the retained models before drafting the cards.**

Perform multi-query searches to gather real-time data:

1. **Release Date Verification**: `"<Model Name>" release date launch announcement`
2. **Benchmark Results Verification**: `"<Model Name>" benchmark LMSYS Chatbot Arena Elo SWE-bench MMLU`
3. **Community & Practical Use Cases**: `"<Model Name>" site:reddit.com/r/LocalLLaMA OR site:news.ycombinator.com "good for"`
4. **Cost**: `"<Model Name>" cost per 1M tokens, site:llmpricing.dev OR site:modelgrep.com/pricing OR site:langtail.com/llm-price-comparison "good for"`

---

## Step 7: Render Content & Smart Mode-Specific Chart

### 1. Text Output

- **Format 2 (Simple List)**: Plain text lines (`Brand: Model A, Model B...`) copied to clipboard.
- **Format 1 (Full Analysis)**: Full Markdown cards with ratings, capability tags (MCP, Vision, Web Search, Reasoning Effort, Context), benchmarks, and use cases, ending with a Recommendation Matrix.
- **Format 3 (Both)**: Simple list at the top, followed immediately by Full Analysis.

---

### 2. 🎨 Smart Chart Engine (Tailored to Mode & Presentation)

**The chart must dynamically tailor its metrics and visual story to the chosen curation mode:**

#### 🎯 Mode 1 (Full / Long): "Ecosystem & Generational Trade-Offs"

- **Chart Design**: Grouped Bar Chart (`type: bar`) comparing top models across 3 dynamic datasets:
  1. **Intelligence** (`#FF6363` — Coral Red, 1–5 scale)
  2. **Speed** (`#3B82F6` — Electric Blue, 1–5 scale)
  3. **Capability Score** (`#10B981` — Emerald Green, 0–4 scale: **+1 for MCP**, **+1 for Vision**, **+1 for Web Search**, **+1 for Reasoning Effort**).
  4. **Cost** (`#bc13fe` — Neon Purple, 1–5 scale)
- **Title**: `"Raycast Plus: Intelligence, Speed & Tool Capabilities (Full Catalog)"`

#### 🎯 Mode 2 (Latest / Short): "Flagship Daily Driver Shootout"

- **Chart Design**: Grouped Bar Chart (`type: bar`) highlighting:
  1. **Intelligence** (`#FF6363` — Coral Red, 1–5 scale)
  2. **Speed** (`#3B82F6` — Electric Blue, 1–5 scale)
  3. **Agentic Score** (`#A855F7` — Violet, 0–4 scale: combining MCP, Vision, and Reasoning support).
  4. **Cost** (`#bc13fe` — Neon Purple, 1–5 scale)
- **Title**: `"Raycast Plus: Flagship Comparison (Intel, Speed & Agentic Power)"`

#### 🎯 Mode 3 (Best & Recent): "Frontier Multimodal & Agentic Readiness"

- **Chart Design**: Grouped Bar Chart (`type: bar`) comparing the frontier models across:
  1. **Speed** (`#3B82F6` — Electric Blue, 1–5 scale)
  2. **Agentic Tooling (MCP + Reasoning)** (`#10B981` — Emerald Green, 0–2 scale)
  3. **Multimodal Vision & Web** (`#F59E0B` — Amber Orange, 0–2 scale)
  4. **Intelligence** (`#FF6363` — Coral Red, 1–5 scale)
  5. **Cost** (`#bc13fe` — Neon Purple, 1–5 scale)
- **Title**: `"Raycast Plus: Frontier Models — Speed vs. Agentic & Multimodal Support"`

#### 🛠️ Universal Chart Styling Rules (Strict):

- **Canvas Background**: Solid dark `#0F141C` (Raycast Native Dark UI). Never transparent or white.
- **Title**: White `#FFFFFF`, bold, size 18.
- **Axis Ticks**: Light gray `#E5E7EB`, font size 12.
- **Grid lines**: `display: false`.
- **X-Axis Labels**: Compact clean names only (e.g. `Gemini 3.8`, `DeepSeek V4`, `Grok-4.6`, `Qwen 3.8`, `GLM-5.3`, `Kimi K3`, `GLM Flash`, `GPT-5.6`).
- **Legend**: Top positioned with `#E5E7EB` labels matching the datasets.

---

## Step 8: 🔒 Robust Clipboard Automation (Prevent Truncation / Empty Fields)

⚠️ **CRITICAL BUG PREVENTION**:
When sending text to `pbcopy`, **NEVER** use shell `cat << 'EOF'` or unescaped terminal echo commands containing tick marks (`'`), backticks (`` ` ``), quotes, or special characters. Doing so causes bash to evaluate backticks as subcommands (e.g., trying to execute `` `5/5` `` or `` `✓` `` as shell commands), which strips every score and checkmark, leaving the pasted text filled with blank spaces (e.g. `Speed:  | Intelligence:  | Supports: `).

**MANDATORY CLIPBOARD IMPLEMENTATION**:
Always save the finalized markdown string into a temporary UTF-8 file or pipe it through Python's binary stdin buffer:

```python
import subprocess

markdown_output = """..."""

# Safe, unescaped clipboard pipe:
process = subprocess.Popen('pbcopy', env={'LANG': 'en_US.UTF-8'}, stdin=subprocess.PIPE)
process.communicate(markdown_output.encode('utf-8'))
```

Alternatively via bash safely:

```bash
python3 -c "import sys, subprocess; subprocess.run(['pbcopy'], input=sys.stdin.read().encode('utf-8'))" < /tmp/output.md
```

### Verification Checklist Before Responding

1. Verify that `markdown_output` contains the filled values (e.g. `Speed: 5/5`, `Intelligence: 4/5`, `MCP: ✓`).
2. Confirm briefly in chat that the selected mode and format were processed, display the chart (if requested), and confirm that the full content is safely loaded in the clipboard ready to paste (`⌘ + V`).
