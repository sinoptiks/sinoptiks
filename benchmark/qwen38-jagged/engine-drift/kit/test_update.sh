#!/usr/bin/env bash
# test_0167.sh — ЗАПУСКАТЬ ОТ ROOT: sudo bash ~/ab-0167/test_0167.sh
# Тест движка 0.1.67 (v0.2.21) на главной strata.service (UD-IQ4_XS 256K).
# Цикл: снапшот -> стоп -> strata update (скачает 0.1.67, пин держит 0.1.63)
#       -> components use 0.1.67 -> старт -> health -> смоук -> бенч -> вердикт.
# Любой сбой или проигрыш по скорости = автоматический откат на 0.1.63.
# Базлайн (24.11, тот же профиль/железо): decode 107.1, prefill 3032, probeB 8/8.
set -u
D=~/ab-0167; mkdir -p "$D"
LOG="$D/run-$(date +%Y%m%dT%H%M%S).log"
exec > >(tee -a "$LOG") 2>&1
BASELINE_DECODE=107.1; MIN_DECODE=104   # 107.1 - 3%
KAV() { runuser -u kav -- env HOME=~ PATH=~/.local/bin:/usr/local/bin:/usr/bin:/bin bash -lc "$1"; }
health_ok() { local i n=$(( $1 / 10 )); for i in $(seq 1 $n); do curl -s -m 3 http://127.0.0.1:5001/health 2>/dev/null | grep -q '"loaded": true' && return 0; sleep 10; done; return 1; }
rollback() {
  echo "=== ОТКАТ на 0.1.63 ($(date +%H:%M:%S)) ==="
  systemctl stop strata.service
  KAV 'strata components use 0.1.63 --wait 60' || echo "ВНИМАНИЕ: components use 0.1.63 вернул rc=$?"
  systemctl start strata.service
  health_ok 2100 && echo "откат OK: 0.1.63 живёт" || echo "!!! ОТКАТ НЕ ПОДНЯЛ СЕРВЕР — journalctl -u strata"
}

echo "== 0. снапшот =="
KAV 'strata components engine' | grep -E 'in use|installed' | head -3
cp ~/.local/share/strata/components/.updates/state.json "$D/state.pre.json" || exit 1
df -h /home | tail -1

echo "== 1. стоп сервиса и обновление компонентов (пин держит 0.1.63 активным) =="
systemctl stop strata.service
KAV 'strata update' ; RC=$?
echo "strata update rc=$RC (5=подпись, 6=сеть/тест-старт, 7=модель сервится)"
KAV 'strata components engines' | grep -q '0\.1\.67' || { echo "0.1.67 не появился в списке — откат запуска"; rollback; exit 1; }

echo "== 2. переключение на 0.1.67 и старт =="
KAV 'strata components use 0.1.67 --wait 60' || { echo "use 0.1.67 не удалось"; rollback; exit 1; }
systemctl start strata.service
health_ok 2100 || { echo "0.1.67 не поднялся за 35 мин"; rollback; exit 1; }
pgrep -f 'engine/0\.1\.67-linux' >/dev/null || { echo "в процессе нет 0.1.67 — откат"; rollback; exit 1; }
echo "движок в процессе: 0.1.67, health ok"

echo "== 3. смоук =="
A=$(curl -s -m 180 http://127.0.0.1:5001/v1/chat/completions -H 'Content-Type: application/json' \
 -d '{"model":"qwen3.8-flash-next-ud-iq4_xs","messages":[{"role":"user","content":"Сколько будет 17*23? Ответь только числом."}],"max_tokens":2000,"temperature":0,"seed":5}' \
 | python3 -c "import json,sys; print(json.load(sys.stdin)['choices'][0]['message'].get('content',''))")
echo "chat: '$A'"; [ "$A" = "391" ] || { echo "смоук chat провален"; rollback; exit 1; }
cd ~/toolcall-lab
P=$(KAV 'cd ~/toolcall-lab && python3 toolcall_probe.py --probe B --pack ud-iq4-xs-0167 --n 4 --reasoning default')
echo "$P"
echo "$P" | grep -q '"bool-ok": 4' || { echo "tool-call провален"; rollback; exit 1; }

echo "== 4. бенч (база: decode $BASELINE_DECODE, порог $MIN_DECODE) =="
B=$(KAV 'bash ~/ab-0166/bench_arm.sh 0167')
DEC=$(echo "$B" | awk '{print $1}'); PRE=$(echo "$B" | awk '{print $2}')
echo "0.1.67: decode=$DEC prefill=$PRE"
OK=$(python3 -c "print('yes' if $DEC >= $MIN_DECODE else 'no')")
if [ "$OK" = "yes" ]; then
  echo "ВЕРДИКТ: 0.1.67 ПРИНЯТ (decode $DEC >= $MIN_DECODE, смоуки чистые). Осталось решить: пин на 0.1.63 снять или переставить на 0.1.67."
else
  echo "ВЕРДИКТ: 0.1.67 МЕДЛЕННЕЕ базлайна более чем на 3% — откат."
  rollback
fi
echo "Лог: $LOG"
