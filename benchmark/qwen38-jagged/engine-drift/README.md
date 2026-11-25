# engine-drift — the backend is a hidden hyperparameter, receipts

Same weights file, byte-identical, one machine. Three build eras, and one
build that could not start at all.

## The era table

| build | decode t/s | verdict | raw |
|---|---|---|---|
| 0.1.55 | (conscience runs, see `../../qwen38-censored-ab/`) | **deleted from the machine Nov 24** — the previous article's numbers are pinned to a ghost | — |
| 0.1.63 | 107.1 (IQ4_XS) / 94.8–95.3 (Q4_K_XL) | pinned baseline | `logs/run-20261124T205716.log` §0, `../quant-shelf/raw/` |
| 0.1.66 | 90.1 / 87.6 (−7%) | **rejected**: test-start crash + −7% in ABBA | `logs/ab-20261123-122011.log`, `logs/test-start-0.1.66-failed.engine.log`, `logs/ab3-*` |
| 0.1.67 | 122.4 (+14%) | accepted by the kit | `logs/run-20261124T205716.log` |

## What the 0.1.66 failure actually looked like

Two independent walls, same day:

1. **The updater's own test-start refused it** (`ab-20261123-122011.log`):
   "The engine started but stopped before it answered a test question" —
   rc=6, current engine untouched. The engine-side reason is in
   `test-start-0.1.66-failed.engine.log`: CUDA-graph capture died on this
   machine — `verify: layer 0 never rang (operation not supported on
   global/shared address space)` → `native ERR verify: begin capture failed`.
2. **When forced to run with a workaround** (`STRATA_HC_Q8=0`, `ab3-*.log`),
   it was measurably slower: ABBA arms A1/A2 = 94.8/95.3 vs B1/B2 = 90.1/87.6
   decode. −7%, beyond the −3% threshold. Rolled back.

## The trap inside the trap

An earlier "−8% regression" (Nov 20) turned out to be a **thermal artifact**:
a morning measurement compared against an evening baseline on an air-cooled
card. The kit therefore measures both arms in one window, alternating
(A-B-B-A). Equal-window A/B or it didn't happen.

## The kit (`kit/`)

`test_update.sh` — the acceptance procedure for a new engine build:
snapshot component state → update → smoke chat at t=0 → tool-call probe →
bench vs the pinned baseline with a −3% threshold → auto-rollback on failure.
`rollback.sh` — the manual escape hatch.

They are **templates written for this machine's systemd layout** (unit names,
profile paths, the 107.1 baseline). Read before running anywhere else; the
procedure, not the paths, is the artifact.
