#!/usr/bin/env python3
"""ClaudeHeartbeat - method B (server-truth).

Keeps the Claude 5-hour usage window anchored by scheduling each ping from the
REAL reset time the API reports (anthropic-ratelimit-unified-5h-reset), instead
of a fixed interval. Immune to drift, manual usage, and weekly resets.

Auth: reads the Claude Code OAuth token from ~/.claude/.credentials.json. If the
access token has expired, it shells out to `claude -p` once to refresh it, then
retries. Requires Claude Code to be installed and logged in.
"""
import datetime
import json
import os
import subprocess
import time
import urllib.error
import urllib.request

CREDS = os.path.expanduser(os.environ.get("CLAUDE_CREDENTIALS", "~/.claude/.credentials.json"))
LOG = os.path.expanduser(os.environ.get("CLAUDE_HEARTBEAT_LOG", "~/claude-heartbeat.log"))
MODEL = os.environ.get("CLAUDE_HEARTBEAT_MODEL", "claude-haiku-4-5-20251001")
BUFFER = int(os.environ.get("CLAUDE_HEARTBEAT_BUFFER", "60"))       # seconds AFTER reset
FAIL_RETRY = int(os.environ.get("CLAUDE_HEARTBEAT_RETRY", "600"))   # seconds on network/other error
MIN_SLEEP = 30
API = "https://api.anthropic.com/v1/messages"


def log(msg):
    ts = datetime.datetime.now(datetime.timezone.utc).isoformat(timespec="seconds")
    with open(LOG, "a") as f:
        f.write(ts + "  " + msg + "\n")


def iso(epoch):
    return datetime.datetime.fromtimestamp(int(epoch), datetime.timezone.utc).isoformat(timespec="seconds")


def token():
    with open(CREDS) as f:
        return json.load(f)["claudeAiOauth"]["accessToken"]


def raw_ping():
    """Send a 1-token message; return (status, lowercased-headers, body_text)."""
    body = {
        "model": MODEL,
        "max_tokens": 1,
        "system": "You are Claude Code, Anthropic's official CLI for Claude.",
        "messages": [{"role": "user", "content": "ok"}],
    }
    req = urllib.request.Request(
        API, data=json.dumps(body).encode(), method="POST",
        headers={
            "authorization": "Bearer " + token(),
            "anthropic-version": "2023-06-01",
            "anthropic-beta": "oauth-2025-04-20",
            "content-type": "application/json",
        },
    )
    try:
        r = urllib.request.urlopen(req, timeout=60)
        status, headers, text = r.status, r.headers, r.read(200)
    except urllib.error.HTTPError as e:
        status, headers, text = e.code, e.headers, e.read(300)
    h = {k.lower(): v for k, v in headers.items()}
    return status, h, text.decode(errors="replace")


def refresh_token_via_claude():
    """Trigger Claude Code to refresh the OAuth token (it does so on use)."""
    try:
        subprocess.run(["claude", "-p", "ok", "--model", "haiku"],
                       capture_output=True, timeout=90)
    except Exception as e:
        log("WARN: refresh via claude failed (%s)" % e)


def ping():
    status, h, text = raw_ping()
    if status == 401:
        log("token expired (401) -> refreshing via claude")
        refresh_token_via_claude()
        status, h, text = raw_ping()  # retry with the fresh token
    return status, h, text


def main():
    log("heartbeat-B started (model=%s, buffer=%ss)" % (MODEL, BUFFER))
    while True:
        try:
            status, h, text = ping()
        except Exception as e:
            log("ERROR: request failed (%s)  retry_in=%ss  next_epoch=%d" % (e, FAIL_RETRY, int(time.time()) + FAIL_RETRY))
            time.sleep(FAIL_RETRY)
            continue

        now = int(time.time())
        reset_5h = h.get("anthropic-ratelimit-unified-5h-reset")
        util = h.get("anthropic-ratelimit-unified-5h-utilization", "?")

        if status == 200 and reset_5h:
            reset = int(reset_5h)
            wake = max(reset + BUFFER, now + MIN_SLEEP)
            log("ping ok  5h_util=%s  window_resets=%s  next_ping=%s  next_epoch=%d"
                % (util, iso(reset), iso(wake), wake))
            time.sleep(wake - now)
        elif status == 429:
            # Rate limited (likely the weekly cap). Wait until the reported reset.
            reset_raw = (h.get("anthropic-ratelimit-unified-reset")
                         or h.get("anthropic-ratelimit-unified-7d-reset"))
            reset = int(reset_raw) if reset_raw else now + FAIL_RETRY
            wake = max(reset + BUFFER, now + MIN_SLEEP)
            ustat = h.get("anthropic-ratelimit-unified-status", "?")
            log("ping RATE-LIMITED  status=%s  reset=%s  next_ping=%s  next_epoch=%d"
                % (ustat, iso(reset), iso(wake), wake))
            time.sleep(wake - now)
        else:
            log("ERROR: unexpected status=%s body=%s  retry_in=%ss  next_epoch=%d"
                % (status, text[:120].replace("\n", " "), FAIL_RETRY, now + FAIL_RETRY))
            time.sleep(FAIL_RETRY)


if __name__ == "__main__":
    main()
