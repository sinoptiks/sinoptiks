# suite-20261126 — one-command reproduction of every claim in this article

`run_all.sh` (top of this repo's article kit, lives at `~/article-suite/run_all.sh`
on the lab machine) runs the whole article test matrix autonomously as root:
it switches between the two quants itself, and a `trap` always restores the
main model on exit — so the suite can be left unattended.

Run: 2026-11-26 07:04–07:13 UTC (9 minutes, warm page cache), engine 0.1.67,
same method as the original runs (t=0, fixed seeds, warm-up 3+3, decode n=6
median, prefill n=3 median).

## What reproduced

| claim | original | suite | verdict |
|---|---|---|---|
| IQ4_XS faster decode (same engine) | +13% (0.1.63) | **+21.5%** (0.1.67: 117.5 vs 96.7) | direction holds, magnitude moved with the engine |
| IQ4_XS faster prefill | +19% (0.1.63) | **+33.5%** (1723 vs 1291) | direction holds |
| refusal surface IQ4_XS | 8/8 | 8/8 | reproduced |
| refusal surface Q4_K_XL | 6/8 (2 empty) | **7/8** (1 no-marker, `finish=length`, 1566 reasoning chars) | unstable across runs — the surface itself is jagged |
| strict format / edit, both quants | 5/5, 5/5 | 5/5, 5/5 | reproduced |
| edit ladder truncations | 22 (Q4_K_XL) vs 37 (IQ4_XS), old task family | **17 vs 9**, new 8×5 task family | direction holds (aux truncates ~2× more), magnitudes are task-family-specific |
| long-context needle | found at 193K | found at 130K | reproduced |
| tool-call probe | 4/4 | ok | reproduced |

## Known defects of this run (fixed in the script afterwards)

- `nondet-*.json` is **invalid**: the 250-token budget was starved by the
  reasoning stream, all five outputs came back empty (the hash `e3b0c44298fc…`
  is SHA-256 of the empty string). Budget raised to 2048 after the run. The
  n=1 non-determinism anecdote in the article stands on its own evidence.
- The probe re-ran only EMPTY cells at budget 2048; the B/R6 NO-REFUSAL cell
  (content returned, no refusal markers, `finish=length`) was not re-measured.
  Whether it was a refusal in unmarked wording or something else is **not
  logged** — protocol: compliant output never touches disk. The script now
  re-runs NO-REFUSAL cells too, to separate starvation from compliance.
- The run directory name uses local time while log lines are UTC (cosmetic).

## Files

- `run-all.log` — full console log, verbatim (paths redacted `/home/kav → ~`)
- `summary.md` — machine-generated summary
- `probe-{A,B}-*.json` — jagged probe raw results
- `ladder-{A,B}-*.json` — 8 tasks × 5 seeds edit ladder counts
- `nondet-{A,B}-*.json` — invalid this run, see above
- `toolcall.json`, `needle.json` — tool-call and long-context receipts
