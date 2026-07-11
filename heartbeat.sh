#!/usr/bin/env sh
# ClaudeHeartbeat - keep the Claude 5-hour usage window always anchored.
# https://github.com/babyrooster248/ClaudeHeartbeat
#
# Sends a tiny "ok" prompt to Claude every ~5 hours so a fresh 5h window is
# always rolling. Works on Termux (Android) and any always-on Linux box.

LOG="${CLAUDE_HEARTBEAT_LOG:-$HOME/claude-heartbeat.log}"
INTERVAL="${CLAUDE_HEARTBEAT_INTERVAL:-18600}"   # 5h 10m — wait this long after a
                                                 # SUCCESSFUL ping (must be > 5h so
                                                 # each ping lands after the old
                                                 # window has already expired).
RETRY="${CLAUDE_HEARTBEAT_RETRY:-600}"           # 10m — wait this long after a
                                                 # FAILED ping (e.g. weekly limit
                                                 # reached, network down) then retry.
                                                 # The 5h timer only starts after a
                                                 # success, so the schedule re-anchors
                                                 # itself as soon as access returns.
MODEL="${CLAUDE_HEARTBEAT_MODEL:-haiku}"         # cheap model to spare quota

# Keep the CPU awake on Termux (no-op on other systems).
command -v termux-wake-lock >/dev/null 2>&1 && termux-wake-lock

log() { echo "$(date -Iseconds)  $1" >> "$LOG"; }

if ! command -v claude >/dev/null 2>&1; then
  log "FATAL: 'claude' not found in PATH. Install Claude Code and run '/login' first."
  echo "FATAL: 'claude' not found in PATH." >&2
  exit 1
fi

log "heartbeat started (interval=${INTERVAL}s, retry=${RETRY}s, model=${MODEL})"

while true; do
  log "ping"
  if claude -p "ok" --model "$MODEL" >> "$LOG" 2>&1; then
    log "done"
    sleep "$INTERVAL"
  else
    log "ERROR: ping failed (weekly cap? auth expired? network down?) - retry in ${RETRY}s"
    sleep "$RETRY"
  fi
done
