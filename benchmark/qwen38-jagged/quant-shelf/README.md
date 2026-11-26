# quant-shelf — bytes ≠ fidelity, and the tooth that saved the loser

Two Unsloth Dynamic quants of the same model, same engine (0.1.63), same
harness. The bigger file lost on calibration and speed — and stayed on the
machine anyway.

## The swap table

| | UD-IQ4_XS | UD-Q4_K_XL | delta |
|---|---|---|---|
| file size | 88 GiB (4 shards) | 111 GB (4 shards) | +33% bytes |
| perplexity (teacher-forced, 4,995 pos) | **3.941** | 4.087 | +0.146 worse |
| decode t/s (engine 0.1.63) | **107.1** | 94.8 / 95.3 | **+13% for IQ4_XS** |
| prefill t/s (engine 0.1.63) | **3032** | 2544 / 2556 | **+19% for IQ4_XS** |
| decode t/s (engine 0.1.67, two runs) | **117.5 / 115.9** | 96.7 / 94.9 | **+21.5% / +22.1% for IQ4_XS** |
| prefill t/s (engine 0.1.67) | **1723** | 1291 | **+33.5% for IQ4_XS** |
| context on the same 24 GB card | 262,144 | 131,072 | 2× |
| edit ladder, TRUNCATED (old family) | 37 | **22** | Q4_K_XL wins |
| edit ladder, TRUNCATED (new 8×5 family, 0.1.67, two draws) | **9 / 10** | 17 / 14 | IQ4_XS wins — direction flipped, held |

The perplexity row is **not our measurement** — it is issue #5291 of the
engine repository, teacher-forced over 4,995 positions, measured by the
reporter. Quoted with attribution; we did not recompute it. Everything else
in the table is raw-backed by files in this folder or `../suite-20261126/`.

**The delta itself is build-dependent**: the same quant pair measured +13%
decode on 0.1.63 and +21.5% on 0.1.67. There is no engine-free number for
"how much faster is the better quant".

## What the raw files here are

- `raw/test-iq4xs-20261124T002056.log` — the IQ4_XS acceptance run on 0.1.63:
  speed section gives `107.1 3032` (warm-up 3+3, decode n=6, prefill n=3),
  plus the 193K-needle long-context smoke.
- `raw/20261120T140247Z-ladder-qwen3.8-flash-next-ud-q4_k_xl.json` — Q4_K_XL
  edit ladder: `TRUNCATED: 22`.
- `raw/20261123T222231Z-ladder-ud-iq4-xs.json` — IQ4_XS edit ladder:
  `TRUNCATED: 37`.
- The Q4_K_XL speed pair (94.8/2544, 95.3/2556) lives one folder over:
  `../engine-drift/logs/ab3-20261123-124432.csv`, arms A1/A2 (engine 0.1.63).

## Reading it honestly

- "XL" in a quant name is a byte count, not a quality claim. On this model the
  33%-bigger file calibrates worse and runs 13% slower.
- The mechanism we suspect (stated as interpretation, not proof): IQ-family
  grids preserve weight-vector *direction*, K-quants preserve *magnitude*; in
  a routed MoE (512 experts) direction error compounds across expert sums.
- The ladder rows are the honest tail — and they disagree with each other.
  On the original task family the "worse" quant had **better** edit discipline
  (22 vs 37 truncations), and that single tooth is why Q4_K_XL was demoted to
  auxiliary instead of deleted. On a fresh 8-task × 5-seed family (0.1.67) the
  direction **flipped**: 9 vs 17, with the main model failing differently
  instead (13 wrong-string edits vs 4; exact-match successes 18 vs 19 of 40).
  "Better at edit discipline" is a quant × task-family property, not a quant
  property. Worse overall, better at one tooth — until you change the task.
- An earlier "+24%" speed figure came from a live evening run whose raw log
  was not kept. It is not in this table and not in the article; the published
  number is the raw-backed same-engine pair above.
