#!/usr/bin/env sh
# Show when the ClaudeHeartbeat service will next ping, based on the log.
# Works with method B (heartbeat.py, logs an explicit next_epoch=) and
# method A (heartbeat.sh, interval/retry-based).
# https://github.com/babyrooster248/ClaudeHeartbeat

LOG="${CLAUDE_HEARTBEAT_LOG:-$HOME/claude-heartbeat.log}"
[ -f "$LOG" ] || { echo "Log not found: $LOG"; exit 1; }

show() {
  NEXT_EPOCH=$1; STATE=$2
  REMAIN=$(( NEXT_EPOCH - $(date +%s) ))
  echo "Now (UTC):     $(date -u +"%Y-%m-%d %H:%M:%S")"
  echo "State:         $STATE"
  echo "-------------------------------------------"
  echo "NEXT ping UTC: $(date -u -d "@$NEXT_EPOCH" +"%Y-%m-%d %H:%M:%S")"
  echo "NEXT ping VN:  $(TZ=Asia/Ho_Chi_Minh date -d "@$NEXT_EPOCH" +"%Y-%m-%d %H:%M:%S")"
  if [ "$REMAIN" -ge 0 ]; then
    echo "In about:      $((REMAIN/3600))h $(((REMAIN%3600)/60))m"
  else
    echo "Status:        due now (a ping should be firing)"
  fi
}

# --- Method B: explicit next_epoch= from the last scheduled line ---
NEXT_EPOCH=$(grep -o "next_epoch=[0-9]*" "$LOG" | tail -1 | cut -d= -f2)
if [ -n "$NEXT_EPOCH" ]; then
  LAST=$(grep "next_epoch=" "$LOG" | tail -1)
  case "$LAST" in
    *RATE-LIMITED*) show "$NEXT_EPOCH" "rate-limited — waiting for reset" ;;
    *ERROR*)        show "$NEXT_EPOCH" "last ping errored — retrying" ;;
    *)              show "$NEXT_EPOCH" "last ping OK (server reset time)" ;;
  esac
  exit 0
fi

# --- Method A fallback: compute from last done/error + interval/retry ---
INTERVAL=$(grep -o "interval=[0-9]*" "$LOG" | tail -1 | cut -d= -f2); INTERVAL=${INTERVAL:-18600}
RETRY=$(grep -o "retry=[0-9]*" "$LOG" | tail -1 | cut -d= -f2); RETRY=${RETRY:-600}
LAST_LINE=$(grep -E "  done$|  ERROR:" "$LOG" | tail -1)
LAST_TS=$(echo "$LAST_LINE" | cut -d" " -f1)
[ -n "$LAST_TS" ] || { echo "No completed/failed ping in the log yet."; exit 0; }
case "$LAST_LINE" in
  *"  done") ADD=$INTERVAL; STATE="last ping OK" ;;
  *ERROR:*)  ADD=$RETRY;    STATE="last ping FAILED (retrying)" ;;
esac
show "$(date -d "$LAST_TS + $ADD seconds" +%s)" "$STATE"
