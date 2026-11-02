Notes for article-v2.md (not part of the article body)

Primary keyword: "local LLM safety" / "prompt injection test"
Secondary: GGUF quantization, KV-cache quantization, RTX 3090 LLM, Qwen3.8-Flash-Next,
int8 KV-cache, attack success rate ASR, McNemar test LLM, decision flip rate

Suggested LinkedIn headline (H1, keyword-front):
  The Quantized Conscience: a 10-minute reality check against whitepaper panic
Alt titles (A/B):
  I ran the scary LLM safety papers on one RTX 3090 — here is what survived
  45% injection ASR at home: what two 2026 papers got wrong about my quantized model

Meta description (152 chars, for the article preview / cross-post to blog):
  Two 2026 papers warn quantized local LLMs destroy alignment. Paired-seed tests on
  one RTX 3090 say the wall held — but prompt injection ate the system prompt alive.

Image alt text (infographic):
  Infographic: refusal wall set by checkpoint not bits; injection ASR by quantization;
  int8 versus fp16 KV-cache; engine 0.1.52 versus 0.1.55; one RTX 3090

Hashtags (end of article and of post):
  #LLM #LocalLLM #PromptInjection #AIresearch #RTX3090 #Quantization

Structure already SEO-relevant in article-v2.md:
- H1 contains primary concept + curiosity ("reality check vs whitepaper panic")
- "In one minute" summary block = featured-snippet-style bullet list above the fold
- Question-style section headings ("did not erode", "no silent destruction") match
  long-tail queries
- Numbers in headings/bullets (41.9%, 45% ASR, p < 10^-10) improve snippet capture
- Italic stack anchor right under the bullets (RTX 3090 / sm_86 + full engine
  component string) — puts the primary hardware keyword in the first ~120 words and
  doubles as the trust anchor for both readers and reviewers

Posting mechanics:
- Article: the graphic is embedded under the lead in this repo copy
  (figure/quantized-conscience.png); on LinkedIn the same PNG goes at the same spot —
  it is also the first image the feed card pulls for the article preview.
- Post: short teaser (post4-quantized-conscience.txt), same PNG; then the numbers
  comment. The 1250-sign comment limit silently truncated the single 1536-sign
  version at 1249 — the "+5.2% … 21 → 293" line and both GitHub URLs were lost;
  restored as a reply under that comment with the full https folder URLs.
