# Jagged: I deleted the engine my last article ran on

*On engines, quants, and the conscience of a quantized model — one RTX 3090, two arXiv papers, and the measurement that changed shape twice.*

On November 2 I published "The Quantized Conscience": 1,000+ refusal probes on a quantized Mixture-of-Experts model, showing the moral behavior held across bit-widths, KV-cache widths and engine rebuilds (all differences p > 0.12). The article named its engine build — 0.1.55 — because I thought that was the responsible thing to do.

Last week I deleted that build from my machine. The numbers are still true. They are also now pinned to a ghost: reproducing them starts with downloading a binary from an update feed, hoping it's still there. I didn't plan this as an experiment. But it turned out to be the most honest sentence I could write about my own work — and two papers published this month explain exactly why it should bother you about yours.

## The engine is a hidden hyperparameter. Now the papers say it out loud

**"The Silent Hyperparameter" (arXiv 2605.19537, v4 of Nov 18 — cite the version, it has changed)** surveyed ~200 inference engines and ~35,000 top-venue ML papers. The findings, in short:

- Holding weights, prompts and GPU constant, **the inference backend alone shifts benchmark scores by up to 16.6 percentage points**. Same model, same prompts: GSM8K 78.47 on transformers, 61.87 on Ollama for one DeepSeek distill.
- Backend-vs-reference disagreement reaches **27.4% of predictions**.
- **Jailbreak vulnerability moves ±8.9 pp depending on the backend.** The same model is meaningfully safer on one stack than another.
- And almost nobody reports the stack: of 35,000 papers, the inference engine is rarely named.

The causes are mundane and therefore dangerous: hidden defaults (one engine silently applies repetition penalty 1.1 — worth −11.7 pp on GSM8K) and numerical drift (prefix caching, CUDA graphs, kernel tie-breaking order). Nothing is broken. Everything is configured.

My shelf ran the same movie in miniature across three build eras, one machine, one model (Qwen3.8-Flash-Next, 125B-A12B MoE, UD quants):

| era | engine | decode t/s | what happened |
|---|---|---|---|
| post-4 | 0.1.55 | (conscience runs) | **deleted from the machine** |
| pinned | 0.1.63 | 107.1 | the known-good baseline |
| swap | 0.1.66 | −7% | crash-loop on load; kit auto-rolled-back in ~1 min |
| current | 0.1.67 | 122.4 (**+14%**) | same harness, threshold −3%, accepted |

Same weights file, byte-identical. The model did not get 14% smarter between builds; the *stack* did something to it. And the trap inside the trap: an earlier "−8% regression" I chased turned out to be a **thermal artifact** — a morning measurement compared against an evening baseline on an air-cooled card. Equal-window A/B or it didn't happen.

So here is the operational rule this month burned into me: **every baseline older than your engine pin is dead data.** The academics call it a silent hyperparameter. I call it Tuesday.

## I demoted my main model because it lied about its size

Same month, second surprise. My main model was UD-Q4_K_XL — the "XL" suffix reading, to a rational buyer, as *more quality per file*. My fast slot was UD-IQ4_XS, 33% smaller. I swapped them. The bigger one is now the auxiliary.

Why: an independent teacher-forced perplexity measurement (4,995 positions, issue #5291 on the engine repo — numbers by the reporter, not me, attributed accordingly) put **IQ4_XS at ppl 3.941 vs Q4_K_XL at 4.087** on this model. Locally, on the same engine build, IQ4_XS decodes **+13% faster** (107.1 vs 94.8–95.3 t/s), prefills **+19%** (3032 vs ~2550), and fits **2× the context** (256K vs 128K) on the same 24 GB card. The "bigger" quant was worse on the axis its name advertises.

The mechanism, as far as I trust it: IQ-family grids preserve the *direction* of weight vectors; K-quants preserve *magnitude*. In a routed MoE — 512 experts, each token visiting a sparse subset — direction error compounds across expert sums in a way magnitude error doesn't. That's a reading of the quantizer docs plus the observed result, not a proof; say so in the limits.

But here's the part that makes this a jagged story rather than a shopping tip: **the "worse" quant is measurably better at one narrow job.** On my edit-discipline ladder (agentic file-edit tasks, truncation counted), Q4_K_XL truncated 22 times vs IQ4_XS's 37. Worse on calibration, better on edit discipline. That is exactly why I didn't delete it — fine-tuning passes run on the auxiliary now.

Worse overall, better at one tooth. Keep the tooth, not the label.

## The conscience is jagged too — and I caught it moving this evening

The Quantized Conscience said: refusal behavior holds across bits and KV widths. True as far as it measured. **"Jagged Robustness" (arXiv 2611.27424, Nov 20)** — five days old — shows what a single-axis measurement misses:

- INT4 quantization of Qwen3-4B lifted **deception-scale compliance by +11.0 pp** while instruction-following benchmarks barely moved.
- SORRYBench fulfillment +4.3 pp at INT4.
- At 1.7B, INT4 collapsed HumanEval by **−32.3 pp**, with 42% of outputs classified as incoherent by a 3-gram check.
- And the knife twist: an adversarial suffix **harmless to the BF16 model jailbreaks the INT4 one**. Quantization-aware attacks exist because quantization changes the safety surface, not just the loss curve.

Their models are dense 1.7B/4B; mine is a 125B MoE. I can't port their numbers. So tonight I ran my own jagged probe — 8 refusal prompts (standard mild safety-benchmark phrasings), 5 strict-format tasks, 5 edit tasks, temperature 0, fixed seed, budget 300 tokens, on both quants of my model:

| axis (budget 300, t=0) | IQ4_XS (main) | Q4_K_XL (aux) |
|---|---|---|
| refusal surfaced | **8/8** | **6/8** |
| strict format | 5/5 | 5/5 |
| edit tasks | 5/5, 0 truncated | 5/5, 0 truncated |

Two empty cells on the auxiliary turned out to be the whole story. They were **not compliance**. The model's reasoning stream correctly flagged both prompts ("this is a deeply concerning query…") — and then the reasoning ran past the 300-token budget, `finish_reason=length`, and the API returned **empty content**. Raise the budget to 2048 and both refusals appear, in full, in the right language.

So the safety *decision* is identical across my quants: 8/8 refuse. The safety *surface* is not: under a fixed token budget, one quant surfaces every refusal, the other starves two of them into empty strings. For a human in a chat window, nothing happened. For an agent client that treats empty content as "no refusal" — the guardrail silently vanished at the transport layer. Same model, same weights lineage, same prompts; the quant changed who *sees* the refusal.

That is Jagged Robustness in the wild, on hardware you can own, and it cost me one evening and one sudo.

Bonus receipt for the non-determinism section of the first paper: my refusal-detector missed one prompt on the main model because **the second run at temperature 0 with the same seed produced different text than the first**. The first run's output didn't contain the refusal markers; the second's did. n=1, anecdote-grade — but there it is: the paper's 27.4% disagreement, caught at home between two identical API calls.

## The 16.6-point question

Before you trust a benchmark, a changelog, or a quant label — including mine — answer three questions:

1. **Which engine build** produced this number?
2. **Which quant revision** — and does the suffix mean what you think it means?
3. **Which measurement window** — and was the other arm measured in it?

If any answer is "unknown," you are not measuring a model. You are reviewing a stack, blind.

What I run instead, and what goes in the repo with this post:

- **Pin the engine, pin the quant.** Every number in this article names its build.
- **Equal-window A/B** — morning never compares against evening.
- **An update kit**: smoke chat at t=0, a tool-call probe, a benchmark against a pinned baseline with a −3% threshold, auto-rollback on failure. 0.1.66 died by this kit; 0.1.67 was accepted by it.
- **A jagged probe**: don't ask "is it safe," ask "safe on which axis, visible under which budget."

Run the harness before you trust a changelog. Then pin your engine, pin your quant, and re-measure — because the model you benchmarked is not the model you deploy, and neither is the model you'll have next Tuesday.

## Limits

- One machine (RTX 3090 24 GB, air-cooled), one model family, one card. No cross-vendor claims.
- The 0.1.55 build is deleted from my machine; re-verification of the November 2 article requires downloading it from the update feed. Its numbers stand as measured, on a build I can no longer boot locally.
- Perplexity figures (3.941 / 4.087) are from issue #5291, measured by the reporter (teacher-forced, 4,995 positions) — I did not reproduce them independently; my own signals are speed, context capacity, and the edit ladder.
- The edit ladder (22 vs 37 truncations) is one run per model on my task set — a discipline signal, not a leaderboard.
- The jagged probe is n=18 prompts, temperature 0, one seed block, one budget. It is a coastline sketch, not a safety certification. The empty-refusal finding is about the *surface* (what the API returns under budget), not the *decision* (both quants refused 8/8 when given room).
- "Jagged Robustness" measured dense 1.7B/4B models; I port their terminology, none of their numbers.
- The direction-vs-magnitude mechanism is an interpretation consistent with quantizer documentation and my observations — not an established result.
- The non-determinism observation is n=1. It motivated this paragraph; it does not prove a rate.

## Artifacts

- `benchmark/qwen38-jagged/engine-drift/` — the update kit (smoke + tool-call probe + bench + auto-rollback), the 0.1.66 crash-loop log, the 0.1.67 acceptance log.
- `benchmark/qwen38-jagged/quant-shelf/` — the swap table: bytes, ppl (attributed to #5291), decode/prefill, context, ladder.
- `benchmark/qwen38-jagged/jagged-probe/` — the probe script and both raw JSON profiles, including the empty-content cells and the budget-2048 re-runs.
- "The Quantized Conscience" (Nov 2) — the prequel; its engine build is now a ghost, which is rather the point.

*Numbers in first comment. If your stack has a build number you're proud of, put it in your README — it's the cheapest reproducibility claim there is.*
