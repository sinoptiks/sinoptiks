#!/usr/bin/env bash
# rollback_0163.sh — ЗАПУСКАТЬ ОТ ROOT: sudo bash ~/ab-0167/rollback_0163.sh
# Ручной возврат движка на 0.1.63 (главная strata.service, UD-IQ4_XS 256K).
set -u
KAV() { runuser -u kav -- env HOME=~ PATH=~/.local/bin:/usr/local/bin:/usr/bin:/bin bash -lc "$1"; }
systemctl stop strata.service
KAV 'strata components use 0.1.63 --wait 60' || echo "ВНИМАНИЕ: rc=$?"
systemctl start strata.service
for i in $(seq 1 210); do curl -s -m 3 http://127.0.0.1:5001/health 2>/dev/null | grep -q '"loaded": true' && break; sleep 10; done
curl -s http://127.0.0.1:5001/health | python3 -c "import json,sys; d=json.load(sys.stdin); print('OK' if d.get('loaded') else 'НЕ ПОДНЯЛСЯ', '-', d.get('model'))"
pgrep -af 'components/engine.*--serve' | grep -o 'engine/0\.1\.[0-9]*' | head -1
