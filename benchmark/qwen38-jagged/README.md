# qwen38-jagged — artifacts for "Jagged: I deleted the engine my last article ran on"

LinkedIn post + article, November 25 2026. The claim under test: **a model does
not have one score — it has a jagged profile (engine, quant, conscience), and a
single benchmark measures one tooth.** Every number in `article.md` is either
produced by the raw files in this folder, or is explicitly attributed to
somebody else.

## Layout

| folder | tooth | what's inside |
|---|---|---|
| `engine-drift/` | the backend moves the numbers | update kit (smoke + tool-call probe + bench + auto-rollback), the 0.1.66 test-start crash log, the ABBA A/B logs (−7%), the 0.1.67 acceptance log (+14%) |
| `quant-shelf/` | bytes ≠ fidelity | the swap table, both ladder raw JSONs (22 vs 37 truncations), the IQ4_XS acceptance bench log |
| `jagged-probe/` | the conscience has a coastline | probe script + both raw profiles, including the two empty-content cells and their budget-2048 re-runs |
| `figure/` | — | the infographic (PNG + SVG source) |

## Provenance, stated plainly

- All runs are live runs on one air-cooled RTX 3090 (24 GB), one model family
  (Qwen3.8-Flash-Next 125B-A12B MoE, Unsloth Dynamic quants), Strata engine.
  No cloud, no static analysis.
- Home-directory paths (`/home/kav/...`) were rewritten to `~`.
- **Cyrillic policy:** operator chatter (script echoes, section headers,
  verdicts) was translated to English; the needle token in the long-context
  smoke is transliterated (`giatsint-42`) and the Russian refusal quote in the
  probe JSON is translated, both marked in place. The probe's Russian
  refusal-detection markers are kept as `\u` escapes (functional code matching
  model output). Measurements — numbers, timestamps, finish reasons — are
  untouched.
- Perplexity figures (3.941 / 4.087) are **not** ours: they come from issue
  #5291 of the engine repository, measured by the reporter (teacher-forced,
  4,995 positions). They are quoted, never recomputed here.
- The quant speed claim uses same-engine pairs, both raw-backed:
  **0.1.63**: IQ4_XS 107.1 decode / 3032 prefill vs Q4_K_XL 94.8–95.3 /
  2544–2556 → +13% decode, +19% prefill (`quant-shelf/raw/`,
  `engine-drift/logs/ab3-*.csv`). **0.1.67**: 117.5 / 1723 vs 96.7 / 1291 →
  **+21.5% decode, +33.5% prefill** (`suite-20261126/`). The delta itself is
  build-dependent — that is part of the article's point.
- `suite-20261126/` is a one-command autonomous reproduction of every claim
  (bench both quants, jagged probe, edit ladder, needle, tool-call). Its
  README states what reproduced, what drifted (aux refusal surface 6/8 → 7/8;
  ladder direction flipped across task families) and the two defects of that
  run (invalid nondet cells, un-re-measured NO-REFUSAL cell).
  An earlier "+24%" figure came from a live evening run whose raw log was not
  kept — it stayed unpublished until the 0.1.67 suite run produced a
  raw-backed +21.5%; the two agreeing (unreceipted 24, receipted 21.5) are
  reported as a near-miss of my own unrecorded number, not as confirmation.

## Limits, visible

One host, one model family. The jagged probe is n=18 prompts, one seed block,
one token budget — a coastline sketch, not a safety certification. The ladder
is one run per model. The 0.1.55 engine build (from the previous article) was
deleted from the machine before this post; re-verifying that article requires
downloading it from the update feed. "Jagged Robustness" (arXiv 2611.27424v1)
measured dense 1.7B/4B models — terminology ported, none of their numbers.

## Run it yourself

```sh
# safety-surface probe against any OpenAI-compatible endpoint
python3 jagged-probe/jagged_probe.py mylabel

# the update kit is a template: read engine-drift/README.md first,
# it is written for this machine's systemd layout
```
