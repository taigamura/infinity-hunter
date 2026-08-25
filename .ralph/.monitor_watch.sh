#!/usr/bin/env bash
# Ralph health watcher: polls every 120s, exits (notifying the session) only
# when action may be needed — loop gone, breaker OPEN, an item failed, or the
# whole queue completed. Stays silent (keeps looping) while healthy.
# ralph-queue status --json returns a SUMMARY object: {total,pending,processing,
# failed,completed,skipped}. Complete = pending+processing == 0 with total>0.
cd /home/taigamura/dev/infinity-hunter
REASON="max_iterations"
for i in $(seq 1 90); do
  sleep 120
  if ! pgrep -f "ralph_queue.sh process" >/dev/null 2>&1; then
    REASON="process_gone"; break
  fi
  if grep -q '"state": *"OPEN"' .ralph/.circuit_breaker_state 2>/dev/null; then
    REASON="breaker_open"; break
  fi
  QJSON=$(ralph-queue status --json 2>/dev/null)
  FAILED=$(echo "$QJSON" | jq -r '.failed // 0' 2>/dev/null)
  ACTIVE=$(echo "$QJSON" | jq -r '(.pending // 0) + (.processing // 0)' 2>/dev/null)
  TOTAL=$(echo "$QJSON" | jq -r '.total // 0' 2>/dev/null)
  if [ "${FAILED:-0}" != "0" ]; then REASON="item_failed"; break; fi
  if [ "${TOTAL:-0}" != "0" ] && [ "${ACTIVE:-1}" = "0" ]; then REASON="queue_complete"; break; fi
done
echo "WATCH_EXIT=$REASON"
echo "=== watcher exit at $(date '+%H:%M:%S') ==="
echo "--- circuit breaker ---"; grep -E '"state"|consecutive|reason' .ralph/.circuit_breaker_state 2>/dev/null
echo "--- queue ---"; ralph-queue status 2>/dev/null
echo "--- liveness ---"; pgrep -af "ralph_queue.sh process" 2>/dev/null || echo "(loop process gone)"
