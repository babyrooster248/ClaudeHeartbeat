# ClaudeHeartbeat 💓

> Keep Claude's **5-hour usage window** always anchored, 24/7, so it's ready the moment you sit down to work — no waiting for a reset.

The recommended way to run it is a **free, always-on Linux VM** (Google Cloud or Oracle Cloud *Always Free* — forever-free tiers, not trials). It also runs on a Raspberry Pi or an Android phone (Termux). Every ~5 hours it sends a tiny message to Claude to keep opening a fresh window.

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

A cloud VM is the most reliable host: server-grade uptime, no background-killing, and it side-steps the [Android sideloading restrictions coming in Sept 2026](#-a-note-on-android--sept-2026). Both options below are **Always Free** tiers (forever free, not a time-limited trial). They ask for a card to verify identity but **do not charge** on the free tier — use a virtual/limit card if you want extra peace of mind.

> ✅ **Field-tested** on a Google Cloud `e2-micro` (Ubuntu 22.04, 1 GB RAM + 2 GB swap).

### Option A — Google Cloud "Always Free" e2-micro ⭐ (recommended: reliably available)

1. **Sign up** at [console.cloud.google.com](https://console.cloud.google.com), set up billing (a card is required; the e2-micro stays free), and create a project.
2. **Create the VM**: *Compute Engine → VM instances → Create instance*.
   - **Region** ⚠️: must be **`us-central1`**, `us-west1`, or `us-east1` — any other region is billed.
   - **Machine**: series **E2** → **`e2-micro`**.
   - **Boot disk**: Ubuntu 22.04 LTS, **Standard persistent disk**, **≤ 30 GB** (⚠️ not *Balanced*/SSD — those aren't free).
   - **SSH key**: *Advanced options → Security → Add manually generated SSH keys* → paste your public key. The login **username comes from the key's trailing comment** (a key ending in `... claudeheartbeat` logs in as `claudeheartbeat`).
   - **Create**, wait until it's running, and note the **External IP**.

   > 💡 The cost estimate may show ~$7/month — that's the sticker price. Google applies the Always Free discount automatically at billing time, so a qualifying e2-micro is **$0**. Set a **$1 budget alert** (*Billing → Budgets & alerts*) for peace of mind.

3. **SSH in** from your laptop (use `/` in the key path on Windows):

   ```sh
   ssh -i ~/.ssh/your_key USERNAME@YOUR_EXTERNAL_IP
   ```

4. **Add 2 GB swap** (the e2-micro only has ~1 GB RAM):

   ```sh
   sudo fallocate -l 2G /swapfile && sudo chmod 600 /swapfile
   sudo mkswap /swapfile && sudo swapon /swapfile
   echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab
   ```

5. **Install Node + Claude Code and clone this repo**:

   ```sh
   curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
   sudo apt-get install -y nodejs git
   sudo npm install -g @anthropic-ai/claude-code
   git clone https://github.com/babyrooster248/ClaudeHeartbeat.git ~/ClaudeHeartbeat
   chmod +x ~/ClaudeHeartbeat/*.sh
   ```

6. **Log in to Claude**:

   ```sh
   claude
   ```

   Pick a theme, trust the folder, type `/login`, and follow the URL (sign in with your Claude subscription account — Google/email). Paste the code back if asked, then `/exit`.

7. **Run it durably with systemd** (survives reboots and logout):

   ```sh
   sudo loginctl enable-linger "$USER"
   export XDG_RUNTIME_DIR="/run/user/$(id -u)"     # needed for systemctl --user over SSH
   mkdir -p ~/.config/systemd/user
   cp ~/ClaudeHeartbeat/systemd/claude-heartbeat.service ~/.config/systemd/user/
   systemctl --user daemon-reload
   systemctl --user enable --now claude-heartbeat
   ```

   Confirm the first ping:

   ```sh
   systemctl --user status claude-heartbeat
   tail -n 20 ~/claude-heartbeat.log     # should show:  ping ... done
   ```

That's it — the VM now keeps your 5-hour window anchored 24/7.

### Option B — Oracle Cloud "Always Free" (more powerful, but often out of capacity)

Oracle's Arm **`VM.Standard.A1.Flex`** gives up to **4 OCPU / 24 GB free forever** — much beefier than the e2-micro. The catch: the Arm shape is **frequently "out of capacity"** in popular regions (and the AMD `VM.Standard.E2.1.Micro` can be too), and your **home region can't be changed** after signup, so pick carefully.

Sign up at [cloud.oracle.com](https://cloud.oracle.com), create an **Ubuntu 22.04** instance (shape `VM.Standard.A1.Flex` at 1 OCPU / 6 GB, or `E2.1.Micro` as fallback), paste your SSH **public key**, then follow **steps 3–7 above** (the default SSH user for Oracle's Ubuntu image is `ubuntu`; you can skip the swap step if the VM has ≥ 4 GB RAM).

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
| `CLAUDE_HEARTBEAT_INTERVAL` | `18600` | Seconds between pings. 5h10m — comfortably over 5h so each ping lands *after* the old window expires. |
| `CLAUDE_HEARTBEAT_MODEL` | `haiku` | Model used for the ping (haiku is light on quota). |
| `CLAUDE_HEARTBEAT_LOG` | `$HOME/claude-heartbeat.log` | Log file path. |

---

## 🩺 Managing the deployment

**Connect to the VM** (Windows users: double-click [`connect-vm.bat`](connect-vm.bat) after editing it with your key path / user / IP):

```sh
ssh -i ~/.ssh/your_key USERNAME@YOUR_EXTERNAL_IP
```

**Once on the VM** (cloud / Pi, systemd):

```sh
# View heartbeat pings
tail -n 20 ~/claude-heartbeat.log
tail -f  ~/claude-heartbeat.log      # live follow (Ctrl+C to stop)

# Service control
systemctl --user status  claude-heartbeat
systemctl --user restart claude-heartbeat
systemctl --user stop    claude-heartbeat
systemctl --user start   claude-heartbeat
```

> If `systemctl --user` prints *"Failed to connect to bus"*, run this first (non-login SSH sessions don't set it):
> ```sh
> export XDG_RUNTIME_DIR="/run/user/$(id -u)"
> ```

**Termux / manual run** (instead of systemd):

```sh
tail -n 20 ~/claude-heartbeat.log
pkill -f heartbeat.sh; termux-wake-unlock 2>/dev/null   # stop
```

### 🪟 Windows one-click helpers (.bat)

Two batch files let you manage the VM without typing SSH commands. Open each one, edit the three values at the top (`KEY`, `VMUSER`, `VMIP`) to match your setup, then **double-click** to run:

| File | What it does |
|---|---|
| [`connect-vm.bat`](connect-vm.bat) | Opens an interactive SSH session into the VM. |
| [`next-ping.bat`](next-ping.bat) | Prints when the next auto-ping will fire (runs [`next-ping.sh`](next-ping.sh) on the VM), then exits. |

Notes:
- `next-ping.bat` needs [`next-ping.sh`](next-ping.sh) on the VM — it ships in this repo, so it's already there after you `git clone`.
- These rely on the built-in **Windows OpenSSH client** (default on Windows 10/11).
- In the key path use forward slashes or `%USERPROFILE%` (e.g. `%USERPROFILE%\.ssh\your_key`) to avoid backslash-escaping issues.
- 💡 Keep your real, filled-in copies as `*.local.bat` (e.g. `connect-vm.local.bat`); add `*.local.bat` to `.gitignore` so your VM's IP never gets committed.

---

## ⚠️ Notes & risks (please read)

- **Token security:** after `/login`, your Claude token is stored on the host (`~/.claude/`). Anyone who gets the host/token can **use your subscription**. Lock down the VM (SSH keys only, no password login) and keep the device secure.
- **Fair use / ToS:** this automatically calls the API to **keep a window open**. It uses **your own quota** and each ping is a tiny message, but it is still a way of gaming the limit from a fair-use standpoint. **Use at your own risk.**
- **Weekly limit (Max plan):** beyond the 5h window there's also a weekly cap — the heartbeat nibbles at it too.
- No guarantee you'll always have a *full* 5 hours when you sit down: you land at an arbitrary point in the current window (0–5h left). The upside: you **never wait long**, because a fresh window always follows right after.

---

## 📄 License

[MIT](LICENSE) — free to use, at your own risk.
