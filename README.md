# ClaudeHeartbeat 💓

> Keep Claude's **5-hour usage window** always anchored, 24/7, so it's ready the moment you sit down to work — no waiting for a reset.

The recommended way to run it is a **free, always-on Linux VM** (Oracle Cloud "Always Free" — a *forever-free* tier, not a trial). It also runs on a Raspberry Pi or an Android phone (Termux). Every ~5 hours it sends a tiny message to Claude to keep opening a fresh window.

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

- An **always-on** host — a free cloud VM (recommended), a Raspberry Pi, or a charging Android phone.
- A **Claude subscription** (Pro/Max) to log in with `claude`.
- An internet connection.

---

## ☁️ Setup on a free cloud VM — recommended (no trial)

A cloud VM is the most reliable option: server-grade uptime, no background-killing, and it side-steps the [Android sideloading restrictions coming in Sept 2026](#-a-note-on-android--sept-2026). Both options below are **Always Free** tiers (forever free, not a time-limited trial). They ask for a card to verify identity but **do not charge** on the free tier.

### Option A — Oracle Cloud "Always Free" ⭐ (recommended)

1. **Sign up** at [cloud.oracle.com](https://cloud.oracle.com) → *Start for free*. Pick your home region (you can't change it later). A card is required for verification; Always Free resources are not billed.
2. **Create a VM**: Menu → *Compute* → *Instances* → *Create instance*.
   - **Image**: Canonical **Ubuntu 22.04**.
   - **Shape**: *Change shape* → **Ampere (Arm)** → `VM.Standard.A1.Flex`, set **1 OCPU / 6 GB** (well within the free 4 OCPU / 24 GB). If Arm capacity is unavailable in your region, use **`VM.Standard.E2.1.Micro`** (AMD, also Always Free).
   - **SSH keys**: *Generate a key pair* and **download the private key** (or paste your own public key).
   - Click **Create**. Note the instance's **public IP**.
3. **SSH in** from your laptop (`ubuntu` is the default user for the Ubuntu image):

   ```sh
   chmod 600 /path/to/your-private-key.key
   ssh -i /path/to/your-private-key.key ubuntu@YOUR_PUBLIC_IP
   ```

4. **Install Node + Claude Code and clone this repo** (on the VM):

   ```sh
   curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
   sudo apt-get install -y nodejs git
   sudo npm install -g @anthropic-ai/claude-code
   git clone https://github.com/babyrooster248/ClaudeHeartbeat.git ~/ClaudeHeartbeat
   chmod +x ~/ClaudeHeartbeat/*.sh
   ```

5. **Log in to Claude** (on the VM):

   ```sh
   claude
   ```

   Type `/login`. On a headless server it prints a URL — open it on any device, sign in, and paste the code back. Then type `/exit`. Verify:

   ```sh
   claude -p "ok"
   ```

6. **Run it durably with systemd** (survives reboots and logout):

   ```sh
   mkdir -p ~/.config/systemd/user
   cp ~/ClaudeHeartbeat/systemd/claude-heartbeat.service ~/.config/systemd/user/
   systemctl --user daemon-reload
   systemctl --user enable --now claude-heartbeat
   sudo loginctl enable-linger "$USER"     # keep it running without an active login shell
   ```

   Check it:

   ```sh
   systemctl --user status claude-heartbeat
   tail -n 20 ~/claude-heartbeat.log
   ```

That's it — the VM now keeps your 5-hour window anchored 24/7.

### Option B — Google Cloud "Always Free" e2-micro

Google Cloud includes one **always-free `e2-micro`** VM in `us-west1`, `us-central1`, or `us-east1` (separate from the 90-day trial credit). Create the e2-micro in one of those regions with an Ubuntu image, then follow **steps 3–6 above**. Note: e2-micro has 1 GB RAM, so it's tighter than the Oracle Arm option.

---

## 📱 Setup on Android (Termux) — alternative

> ### ⚠️ A note on Android & Sept 2026
> Starting **September 2026**, Google's [developer-verification policy](https://keepandroidopen.org/) may restrict sideloading and F-Droid apps on certified Android devices, which could make installing **Termux** harder or block it. If you want something future-proof, prefer the **cloud VM** above. This Android path is kept for people who already have Termux working.

<details>
<summary>Show Android / Termux instructions</summary>

### Step 0 — Install two apps from F-Droid (NOT the Play Store builds)

Go to [f-droid.org](https://f-droid.org) and install **Termux** and **Termux:Boot**. Open **Termux:Boot** once and close it.

### Step 1 — Install Node + Claude Code + clone this repo

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
claude          # pick theme, press trust, then /login, then /exit
claude -p "ok"  # should print a short reply
```

### Step 3 — Auto-start on boot

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
tail -f ~/claude-heartbeat.log
```

### Step 5 — Stop Android from killing it (REQUIRED)

1. **Settings → Apps → Termux → Battery → Unrestricted** (same for **Termux:Boot**).
2. In Termux's notification, keep **"Acquire wakelock"** enabled.
3. Keep the phone **plugged in**.
4. On Xiaomi / Samsung / Oppo / Huawei, enable **Autostart** and lock the app in Recents — see [dontkillmyapp.com](https://dontkillmyapp.com).

</details>

---

## ⏰ (Optional) Pre-warm mode

Prefer the window to be **almost expired by the time you sit down** instead of running continuously? Use `ping-once.sh` with a scheduler that fires **before** your usual start time by `5h − (how long you typically work before hitting the quota)`.

Example: you start at **9:00 AM** and burn quota in ~**2h** → schedule a ping at **6:00 AM**. The window runs 6:00–11:00; you work 9:00–11:00 and hit the reset right on cue → seamless roll into the next session.

```sh
# cron on the VM: run ping-once every day at 6:00 AM
0 6 * * * /home/ubuntu/ClaudeHeartbeat/ping-once.sh
```

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
# Last 20 log lines
tail -n 20 ~/claude-heartbeat.log

# systemd (cloud VM / Pi)
systemctl --user status claude-heartbeat
systemctl --user stop claude-heartbeat

# Termux / manual run
pkill -f heartbeat.sh; termux-wake-unlock 2>/dev/null
```

---

## ⚠️ Notes & risks (please read)

- **Token security:** after `/login`, your Claude token is stored on the host (`~/.claude/`). Anyone who gets the host/token can **use your subscription**. Lock down the VM (SSH keys only, no password login) and keep the device secure.
- **Fair use / ToS:** this automatically calls the API to **keep a window open**. It uses **your own quota** and each ping is a tiny message, but it is still a way of gaming the limit from a fair-use standpoint. **Use at your own risk.**
- **Weekly limit (Max plan):** beyond the 5h window there's also a weekly cap — the heartbeat nibbles at it too.
- No guarantee you'll always have a *full* 5 hours when you sit down: you land at an arbitrary point in the current window (0–5h left). The upside: you **never wait long**, because a fresh window always follows right after.

---

## 📄 License

[MIT](LICENSE) — free to use, at your own risk.
