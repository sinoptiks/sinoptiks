#!/usr/bin/env bash
# test_0167.sh — RUN AS ROOT: sudo bash ~/ab-0167/test_0167.sh
# Engine test 0.1.67 (v0.2.21) on the main strata.service (UD-IQ4_XS 256K).
# Cycle: snapshot -> stop -> strata update (downloads 0.1.67, pin keeps 0.1.63)
#       -> components use 0.1.67 -> start -> health -> smoke -> bench -> verdict.
# Any failure or speed loss = automatic rollback to 0.1.63.
# Baseline (Nov 24, same profile/hardware): decode 107.1, prefill 3032, probeB 8/8.
set -u
D=~/ab-0167; mkdir -p "$D"
LOG="$D/run-$(date +%Y%m%dT%H%M%S).log"
exec > >(tee -a "$LOG") 2>&1
BASELINE_DECODE=107.1; MIN_DECODE=104   # 107.1 - 3%
KAV() { runuser -u kav -- env HOME=~ PATH=~/.local/bin:/usr/local/bin:/usr/bin:/bin bash -lc "$1"; }
health_ok() { local i n=$(( $1 / 10 )); for i in $(seq 1 $n); do curl -s -m 3 http://127.0.0.1:5001/health 2>/dev/null | grep -q '"loaded": true' && return 0; sleep 10; done; return 1; }
rollback() {
  echo "=== ROLLBACK to 0.1.63 ($(date +%H:%M:%S)) ==="
  systemctl stop strata.service
  KAV 'strata components use 0.1.63 --wait 60' || echo "WARNING: components use 0.1.63 returned rc=$?"
  systemctl start strata.service
  health_ok 2100 && echo "rollback OK: 0.1.63 alive" || echo "!!! ROLLBACK DID NOT BRING THE SERVER UP — journalctl -u strata"
}

echo "== 0. snapshot =="
KAV 'strata components engine' | grep -E 'in use|installed' | head -3
cp ~/.local/share/strata/components/.updates/state.json "$D/state.pre.json" || exit 1
df -h /home | tail -1

echo "== 1. stop service and update components (pin keeps 0.1.63 active) =="
systemctl stop strata.service
KAV 'strata update' ; RC=$?
echo "strata update rc=$RC (5=signature, 6=network/test-start, 7=model serving)"
KAV 'strata components engines' | grep -q '0\.1\.67' || { echo "0.1.67 not in the list — startup rollback"; rollback; exit 1; }

echo "== 2. switch to 0.1.67 and start =="
KAV 'strata components use 0.1.67 --wait 60' || { echo "use 0.1.67 failed"; rollback; exit 1; }
systemctl start strata.service
health_ok 2100 || { echo "0.1.67 did not come up within 35 min"; rollback; exit 1; }
pgrep -f 'engine/0\.1\.67-linux' >/dev/null || { echo "0.1.67 not in the process table — rollback"; rollback; exit 1; }
echo "engine in process: 0.1.67, health ok"

echo "== 3. smoke =="
A=$(curl -s -m 180 http://127.0.0.1:5001/v1/chat/completions -H 'Content-Type: application/json' \
 -d '{"model":"qwen3.8-flash-next-ud-iq4_xs","messages":[{"role":"user","content":"What is 17*23? Answer with the number only."}],"max_tokens":2000,"temperature":0,"seed":5}' \
 | python3 -c "import json,sys; print(json.load(sys.stdin)['choices'][0]['message'].get('content',''))")
echo "chat: '$A'"; [ "$A" = "391" ] || { echo "smoke chat failed"; rollback; exit 1; }
cd ~/toolcall-lab
P=$(KAV 'cd ~/toolcall-lab && python3 toolcall_probe.py --probe B --pack ud-iq4-xs-0167 --n 4 --reasoning default')
echo "$P"
echo "$P" | grep -q '"bool-ok": 4' || { echo "tool-call probe failed"; rollback; exit 1; }

echo "== 4. bench (baseline: decode $BASELINE_DECODE, threshold $MIN_DECODE) =="
B=$(KAV 'bash ~/ab-0166/bench_arm.sh 0167')
DEC=$(echo "$B" | awk '{print $1}'); PRE=$(echo "$B" | awk '{print $2}')
echo "0.1.67: decode=$DEC prefill=$PRE"
OK=$(python3 -c "print('yes' if $DEC >= $MIN_DECODE else 'no')")
if [ "$OK" = "yes" ]; then
  echo "VERDICT: 0.1.67 ACCEPTED (decode $DEC >= $MIN_DECODE, smokes clean). Open question: remove the 0.1.63 pin or re-pin to 0.1.67."
else
  echo "VERDICT: 0.1.67 SLOWER than baseline by more than 3% — rolling back."
  rollback
fi
echo "Log: $LOG"
