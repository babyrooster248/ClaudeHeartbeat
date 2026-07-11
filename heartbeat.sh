#!/usr/bin/env sh
# ClaudeHeartbeat - keep the Claude 5-hour usage window always anchored.
# https://github.com/babyrooster248/ClaudeHeartbeat
#
# Sends a tiny "ok" prompt to Claude every ~5 hours so a fresh 5h window is
# always rolling. Works on Termux (Android) and any always-on Linux box.

LOG="${CLAUDE_HEARTBEAT_LOG:-$HOME/claude-heartbeat.log}"
INTERVAL="${CLAUDE_HEARTBEAT_INTERVAL:-18120}"   # 5h 02m — slightly over 5h so
                                                 # each ping lands AFTER the
                                                 # previous window expires.
MODEL="${CLAUDE_HEARTBEAT_MODEL:-haiku}"         # cheap model to spare quota

# Keep the CPU awake on Termux (no-op on other systems).
command -v termux-wake-lock >/dev/null 2>&1 && termux-wake-lock

log() { echo "$(date -Iseconds)  $1" >> "$LOG"; }

if ! command -v claude >/dev/null 2>&1; then
  log "FATAL: 'claude' not found in PATH. Install Claude Code and run '/login' first."
  echo "FATAL: 'claude' not found in PATH." >&2
  exit 1
fi

log "heartbeat started (interval=${INTERVAL}s, model=${MODEL})"

while true; do
  log "ping"
  if claude -p "ok" --model "$MODEL" >> "$LOG" 2>&1; then
    log "done"
  else
    log "ERROR: claude exited non-zero (auth expired? network down?)"
  fi
  sleep "$INTERVAL"
done
