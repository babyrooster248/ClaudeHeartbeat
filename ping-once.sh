#!/usr/bin/env sh
# ClaudeHeartbeat - send a SINGLE heartbeat ping and exit.
# Use this with cron / a time-based automation for "pre-warm" mode:
# fire it a few hours before you usually start working so the 5h window
# resets right around the time you run out of quota.
# https://github.com/babyrooster248/ClaudeHeartbeat

LOG="${CLAUDE_HEARTBEAT_LOG:-$HOME/claude-heartbeat.log}"
MODEL="${CLAUDE_HEARTBEAT_MODEL:-haiku}"

log() { echo "$(date -Iseconds)  $1" >> "$LOG"; }

if ! command -v claude >/dev/null 2>&1; then
  echo "FATAL: 'claude' not found in PATH." >&2
  exit 1
fi

log "ping (once)"
if claude -p "ok" --model "$MODEL" >> "$LOG" 2>&1; then
  log "done (once)"
else
  log "ERROR: claude exited non-zero"
  exit 1
fi
