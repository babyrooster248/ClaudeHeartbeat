# ClaudeHeartbeat 💓

> Keep Claude's **5-hour usage window** always anchored, 24/7, so it's ready the moment you sit down to work — no waiting for a reset.

Runs on any **always-on** device: an **Android phone (Termux)**, a Raspberry Pi, or a **free Linux VM** (e.g. Oracle Cloud). It sends a tiny message to Claude every ~5 hours to keep opening a fresh window.

---

## 🧠 The idea & how it works

Claude subscriptions meter usage in a **rolling 5-hour window**: the window starts at your **first message** and resets exactly 5 hours later.

The problem: if the window only starts when you sit down, you burn through your quota in 2–3 hours and then have to **wait** until the full 5 hours elapse before it resets.

What `ClaudeHeartbeat` does:

```
An always-on device pings "ok" every ~5h  ->  a 5h window is ALWAYS running
        │
        └── When you start working on your laptop, you ride the already-open
            window. Limits are per-ACCOUNT, not per-device.
        └── When the window resets, the next ping (or your own message) opens a
            new one -> seamless switch to the next session, no waiting.
```

Because **the heartbeat itself opens the window**, the reset cadence is steady and predictable.

---

## ✅ Requirements

- An **always-on** device (an Android phone kept charging, a Pi, or a free Linux VM).
- A **Claude subscription** (Pro/Max) to log in with `claude`.
- An internet connection.

---

## 📱 Setup on Android (Termux) — recommended

### Step 0 — Install two apps from F-Droid (NOT the Play Store builds)

Go to [f-droid.org](https://f-droid.org) and install:

- **Termux**
- **Termux:Boot** (so the heartbeat restarts after a reboot)

Open **Termux:Boot** once and close it (so the system registers it).

### Step 1 — Install Node + Claude Code + clone this repo

Open **Termux**:

```sh
pkg update -y && pkg upgrade -y
pkg install -y nodejs git
npm install -g @anthropic-ai/claude-code
git clone https://github.com/babyrooster248/ClaudeHeartbeat.git ~/ClaudeHeartbeat
chmod +x ~/ClaudeHeartbeat/*.sh
```

### Step 2 — Log in and run once

```sh
cd ~
claude
```

- Pick a theme, press **trust**, then type `/login` and follow the link to sign in.
- When done, type `/exit`.

Verify headless mode works (this is the "heartbeat"):

```sh
claude -p "ok"
```

If it prints a short reply → ✅ good to go.

### Step 3 — Auto-start the heartbeat on boot

```sh
mkdir -p ~/.termux/boot
cat > ~/.termux/boot/start-heartbeat.sh <<'EOF'
#!/data/data/com.termux/files/usr/bin/sh
termux-wake-lock
sh ~/ClaudeHeartbeat/heartbeat.sh >/dev/null 2>&1 &
EOF
chmod +x ~/.termux/boot/start-heartbeat.sh
```

### Step 4 — Start it now (no reboot needed)

```sh
termux-wake-lock
nohup sh ~/ClaudeHeartbeat/heartbeat.sh >/dev/null 2>&1 &
```

Check the log to confirm it's running:

```sh
tail -f ~/claude-heartbeat.log
```

Seeing `ping` then `done` means it works. Press `Ctrl+C` to stop tailing (the script keeps running in the background).

### Step 5 — Stop Android from killing it (REQUIRED)

Skip this and the script will be killed after a few hours.

1. **Settings → Apps → Termux → Battery → Unrestricted** (do the same for **Termux:Boot**).
2. In Termux, pull down the notification shade → keep **"Acquire wakelock"** enabled.
3. Keep the phone **plugged in**.
4. **Xiaomi / Samsung / Oppo / Huawei...** kill background apps aggressively → enable **Autostart** for Termux and lock the app in the Recents screen. Look up your device at [dontkillmyapp.com](https://dontkillmyapp.com).

---

## 🖥️ Setup on a Linux VM / Raspberry Pi

If you use a VM (e.g. Oracle Cloud "Always Free") or a Pi:

```sh
# Install Node + Claude Code (Debian/Ubuntu example)
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo bash -
sudo apt-get install -y nodejs git
npm install -g @anthropic-ai/claude-code

git clone https://github.com/babyrooster248/ClaudeHeartbeat.git ~/ClaudeHeartbeat
chmod +x ~/ClaudeHeartbeat/*.sh

claude          # /login then /exit
```

Run it durably with `systemd` (recommended) — see [`systemd/claude-heartbeat.service`](systemd/claude-heartbeat.service):

```sh
mkdir -p ~/.config/systemd/user
cp ~/ClaudeHeartbeat/systemd/claude-heartbeat.service ~/.config/systemd/user/
systemctl --user daemon-reload
systemctl --user enable --now claude-heartbeat
loginctl enable-linger "$USER"     # keep it running without an active login shell
```

---

## ⏰ (Optional) Pre-warm mode

Prefer the window to be **almost expired by the time you sit down in the morning** instead of running continuously 24/7? Use `ping-once.sh` with a scheduler (cron / Termux) that fires **before** your usual start time by `5h − (how long you typically work before hitting the quota)`.

Example: you usually start at **9:00 AM** and burn quota in ~**2h** → schedule a ping at **6:00 AM** (9 − 3). The window runs 6:00–11:00; you work 9:00–11:00 and hit the reset right on cue → seamless roll into the next session.

```sh
# cron on Linux: run ping-once every day at 6:00 AM
0 6 * * * /home/USER/ClaudeHeartbeat/ping-once.sh
```

On Termux, use `termux-job-scheduler` or a time-based automation app.

---

## 🔧 Configuration

`heartbeat.sh` reads these environment variables (all have defaults):

| Variable | Default | Meaning |
|---|---|---|
| `CLAUDE_HEARTBEAT_INTERVAL` | `18120` | Seconds between pings. 5h02m — slightly over 5h so each ping lands *after* the old window expires. |
| `CLAUDE_HEARTBEAT_MODEL` | `haiku` | Model used for the ping (haiku is light on quota). |
| `CLAUDE_HEARTBEAT_LOG` | `$HOME/claude-heartbeat.log` | Log file path. |

---

## 🩺 Check / Stop

```sh
# Show the last 20 log lines
tail -n 20 ~/claude-heartbeat.log

# Stop the heartbeat (Termux / manual run)
pkill -f heartbeat.sh; termux-wake-unlock 2>/dev/null

# Stop (systemd)
systemctl --user stop claude-heartbeat
```

---

## ⚠️ Notes & risks (please read)

- **Token security:** after `/login`, your Claude token is stored on the device (`~/.claude/`). Anyone who gets the device/token can **use your subscription**. Keep the device secure.
- **Fair use / ToS:** this automatically calls the API to **keep a window open**. It uses **your own quota** and each ping is a tiny message, but it is still a way of gaming the limit from a fair-use standpoint. **Use at your own risk.**
- **Weekly limit (Max plan):** beyond the 5h window there's also a weekly cap — the heartbeat nibbles at it too.
- No guarantee you'll always have a *full* 5 hours when you sit down: you land at an arbitrary point in the current window (0–5h left). The upside: you **never wait long**, because a fresh window always follows right after.

---

## 📄 License

[MIT](LICENSE) — free to use, at your own risk.
