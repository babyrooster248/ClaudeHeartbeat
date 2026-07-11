#!/usr/bin/env sh
# Show when the ClaudeHeartbeat service will next ping, based on the log.
# https://github.com/babyrooster248/ClaudeHeartbeat

LOG="${CLAUDE_HEARTBEAT_LOG:-$HOME/claude-heartbeat.log}"

if [ ! -f "$LOG" ]; then echo "Log not found: $LOG"; exit 1; fi

INTERVAL=$(grep -o "interval=[0-9]*" "$LOG" | tail -1 | cut -d= -f2)
INTERVAL=${INTERVAL:-18600}
LAST_DONE=$(grep -E "  done$" "$LOG" | tail -1 | cut -d" " -f1)
LAST_PING=$(grep -E "  ping$" "$LOG" | tail -1 | cut -d" " -f1)

if [ -z "$LAST_DONE" ]; then echo "No completed ping in the log yet."; exit 0; fi

NEXT_EPOCH=$(date -d "$LAST_DONE + $INTERVAL seconds" +%s)
REMAIN=$(( NEXT_EPOCH - $(date +%s) ))

echo "Now (UTC):     $(date -u +"%Y-%m-%d %H:%M:%S")"
echo "Interval:      ${INTERVAL}s (~$((INTERVAL/3600))h $(((INTERVAL%3600)/60))m)"
echo "Last ping:     $LAST_PING"
echo "Last done:     $LAST_DONE"
echo "-------------------------------------------"
echo "NEXT ping UTC: $(date -u -d "@$NEXT_EPOCH" +"%Y-%m-%d %H:%M:%S")"
echo "NEXT ping VN:  $(TZ=Asia/Ho_Chi_Minh date -d "@$NEXT_EPOCH" +"%Y-%m-%d %H:%M:%S")"
if [ "$REMAIN" -ge 0 ]; then
  echo "In about:      $((REMAIN/3600))h $(((REMAIN%3600)/60))m"
else
  echo "Status:        overdue by $(( -REMAIN/60 ))m — a ping should be happening now"
fi
