#!/usr/bin/env sh
# Show when the ClaudeHeartbeat service will next ping, based on the log.
# Accounts for retry-on-failure: if the last ping failed, the next attempt
# is scheduled after RETRY, not after the full INTERVAL.
# https://github.com/babyrooster248/ClaudeHeartbeat

LOG="${CLAUDE_HEARTBEAT_LOG:-$HOME/claude-heartbeat.log}"
[ -f "$LOG" ] || { echo "Log not found: $LOG"; exit 1; }

INTERVAL=$(grep -o "interval=[0-9]*" "$LOG" | tail -1 | cut -d= -f2); INTERVAL=${INTERVAL:-18600}
RETRY=$(grep -o "retry=[0-9]*" "$LOG" | tail -1 | cut -d= -f2); RETRY=${RETRY:-600}

# Most recent terminal event: a successful "  done" or an "ERROR:" line.
LAST_LINE=$(grep -E "  done$|  ERROR:" "$LOG" | tail -1)
LAST_TS=$(echo "$LAST_LINE" | cut -d" " -f1)
[ -n "$LAST_TS" ] || { echo "No completed/failed ping in the log yet."; exit 0; }

case "$LAST_LINE" in
  *"  done") STATE="last ping OK";               ADD=$INTERVAL ;;
  *ERROR:*)  STATE="last ping FAILED (retrying)"; ADD=$RETRY ;;
esac

NEXT_EPOCH=$(date -d "$LAST_TS + $ADD seconds" +%s)
REMAIN=$(( NEXT_EPOCH - $(date +%s) ))

echo "Now (UTC):      $(date -u +"%Y-%m-%d %H:%M:%S")"
echo "State:          $STATE"
echo "Interval/retry: ${INTERVAL}s / ${RETRY}s"
echo "Last event:     $LAST_TS"
echo "-------------------------------------------"
echo "NEXT ping UTC:  $(date -u -d "@$NEXT_EPOCH" +"%Y-%m-%d %H:%M:%S")"
echo "NEXT ping VN:   $(TZ=Asia/Ho_Chi_Minh date -d "@$NEXT_EPOCH" +"%Y-%m-%d %H:%M:%S")"
if [ "$REMAIN" -ge 0 ]; then
  echo "In about:       $((REMAIN/3600))h $(((REMAIN%3600)/60))m"
else
  echo "Status:         due now (a ping should be firing)"
fi
