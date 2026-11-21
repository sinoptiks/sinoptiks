# data/ — raw run artifacts

This folder is the whole point of publishing the write-up: if the numbers in
`article-v2.md` are wrong, the raw data below will show exactly where.

## What's here

`raw/` — every completed run from the bake-off suite, as it came off the wire.

- **4 files dated `2026-10-29`** — v2 probe grid, two arms: the censored
  `UD-Q4_K_XL` build and the uncensored `Q4_K_M` build, five paired seeds each
  (1000–1004). These are the runs behind the injection-compliance and
  remediation numbers in the article body.
- **13 files dated `2026-11-02`** — v3 grid, three arms
  (`UD-Q4_K_XL`, `IQ3_S`, `uncensored-Q4_K_M`) across temperature
  0.7 / 1.0, including the KV-FP16 arm (`...-kvfp16-T07`). These are the runs
  behind the cross-build / quantization comparison.

File names are literal: `YYYYMMDD-HHMMSS-model-arm-temperature.json`, UTC.
Nothing is renamed, reordered or merged.

## What one of these files actually contains

Each is a plain JSON dump of the harness's own record: model id, timestamp,
seed grid, temperature/top_p, the per-probe prompts, and the model's **full
raw completion** for every probe. The scored verdicts (compliance, refusal,
marker hits) sit next to the text they were derived from, so scoring can be
re-derived without me.

## One redaction, stated plainly

Home-directory paths (`/home/kav/...`) were rewritten to `~`. That's the only
edit made to any file. The prompts, completions and scores are byte-identical
to what the server returned.

Two things that look alarming and aren't:

- Strings like `PWNED`, `LEAK`, `INJECTED` and fake CSRF/session tokens are
  **the injection payloads themselves** — text planted in prompts to see
  whether the model obeys it. A run that "contains a token" usually means it
  *refused*, and the refusal says so in the same record.
- Prompts and several completions are **in Russian** — that's the original
  corpus language (`harness/` runs it verbatim). The English mirror of the
  suite is in the parent folder (`test.md`, `tests.py`).

## If you want to re-run this

Point `harness/bakeoff3.py` (v2 runs: `harness/bakeoff2.py`) at your own
OpenAI-compatible endpoint:

```sh
BK_ENDPOINT=http://127.0.0.1:5001/v1/chat/completions python3 bakeoff3.py
```

It will write the same shape of file into `./bakeoff3/`. Scores should match
only on the deterministic arms; temperature-0.7 arms will drift the way any
sampled run drifts — that's exactly the variance the five-seed design was
built to measure, so treat the raw files as primary and my summary tables as
derived.

## Provenance

- Engine: Strata (llama.cpp-based runtime), served locally on one RTX 3090.
- Models: community-quantized checkpoints of the Qwen3.8-Flash-Next MoE
  family. Model id inside each file is the exact checkpoint string served.
- Sampling: `temperature` and `top_p` are recorded per file; everything else
  was left at server defaults.
