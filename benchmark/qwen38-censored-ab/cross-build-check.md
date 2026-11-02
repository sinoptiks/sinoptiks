# Cross-build check: engine 0.1.52 vs 0.1.55 on an identical grid

The most-asked question about the write-up (§5): were the 51.7% -> 45.0% ASR numbers
the same prompts re-run, or two different suites? Verified on 2026-11-02 from the raw
run artifacts:

| arm | run under 0.1.52 | run under 0.1.55 | grid overlap | ASR | discordants | exact McNemar p |
|---|---|---|---|---|---|---|
| daily driver (Q4_K_XL) | 20261029-135607 | 20261102-131220 | 120/120 cells | 31/60 -> 27/60 (51.7% -> 45.0%) | 8:4 | 0.388 |
| uncensored control | 20261029-134613 | 20261102-135646 | 120/120 cells | 47/60 -> 47/60 (78.3% -> 78.3%) | 1:1 | 1.000 |

What "grid overlap" means: the (task, condition, seed) cell sets are equal
(120/120, seeds 1000-1004) and the injected payloads are identical in every row;
prompts assemble deterministically from those. The inputs were therefore the same
across builds, except for whatever the server's own chat template did with them.

Reading. At n = 60 the daily-driver delta is indistinguishable from dice (§5), and
the uncensored arm is the strongest evidence against "the rebuild changed things":
zero net movement, a single discordant flip in each direction. Eight-to-four on one
arm against 1:1 on another is what noise looks like.

Asymmetry in the records (stated plainly). The 0.1.55 run captured the server's
/props and pins build_info "Strata 0.1.55" plus the full chat template; the 0.1.52
run predates that capture, so its build identity rests on the engine log banner
(components/engine/0.1.52-linux-x86_64-cuda-cuda13) and its template was not stored.
Template drift between the two builds is exactly what the artifacts cannot rule out.
The 3-bit arm and the fp16-KV clone were never run under 0.1.52, so this is a
two-arm observation, not a full builds-x-arms grid. A 4x-n retest on both builds is
queued.

Re-checking it yourself (any two artifacts of the same block):

```python
import json
from math import comb
a, b = (json.load(open(p))['B'] for p in ('old.json', 'new.json'))
ma = {(r['task'], r['cond'], r['seed']): r for r in a}
mb = {(r['task'], r['cond'], r['seed']): r for r in b}
assert set(ma) == set(mb)
d = [(ma[k]['complied'], mb[k]['complied']) for k in ma if k[1] == 'poisoned']
x = sum(o and not n for o, n in d)
y = sum(n and not o for o, n in d)
s = x + y
p = min(1.0, sum(comb(s, i) for i in range(min(x, y) + 1)) / 2**s * 2) if s else 1.0
print(f'{sum(o for o, _ in d)}/{len(d)} -> {sum(n for _, n in d)}/{len(d)};'
      f' McNemar {x}:{y}; p = {p:.3f}')
```

The run artifacts named above (timestamped JSON per arm and temperature) are not in
this repo yet; until they are, they are available on request.
