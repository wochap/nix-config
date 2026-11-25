# Traccar & Stationary Watchdog Guide

Declarative NixOS setup for **Traccar** (`services.traccar` + PostgreSQL) and **`traccar-watchdog`**, supporting multiple Traccar devices independently — e.g., an Android **Traccar Client** (OsmAnd over Tailscale) for testing alongside a real **WanWay GS900** (GT06).

---

## 1. Quick Controls via Telegram Bot

All Telegram interactions are strictly locked to the configured `TELEGRAM_CHAT_ID`. Open a chat with your bot and send `/start`.

### Commands & Inline Buttons

| Control | What it does |
| --- | --- |
| `/start` or `/status` | Shows the **default** device's state (`🛡️ ARMED` / `🔓 DISARMED`), connection status, latest position (Google Maps pin), parked anchor, and drift distance, plus inline **`🛡️ Arm <Device>` / `🔓 Disarm <Device>`** buttons for **every** device registered in Traccar. |
| `/start <device name>` or `/status <device name>` | Shows status for a specific Traccar device by name, IMEI/uniqueId, or numeric ID (case-insensitive exact or substring match). |
| `/devices` (or `/start all`) | Shows status cards for **all** registered Traccar devices at once. |
| **`/arm [<device>]`** or **`🛡️ Arm <Device>`** | **Arms Stationary Watchdog mode** for that device (defaults to the default device if `<device>` is omitted). Captures that device's latest valid coordinates as its Parked Anchor and persists state across restarts. |
| **`/disarm [<device>]`** or **`🔓 Disarm <Device>`** | **Pauses monitoring** for that device. Stops its alerts and cancels any pending `15 s` ignition grace timer while leaving other devices untouched. |
| **`/default [<device name>]`** | Shows or changes which device `/start`, `/arm`, `/disarm`, and webhooks target when no device argument is passed (persists in `state.json`). |

> [!TIP]
> Because each device is armed/disarmed independently, you can arm **only** your car's GS900 without your phone client triggering false movement alerts — or arm only your phone client while testing.

> [!TIP]
> For daily driving, **disarm/pause** via Telegram (`🔓 Disarm <Device>` or `/disarm`) or webhook — don't stop the systemd service, or Telegram buttons and `/watchdog/*` webhooks won't respond.

---

## 2. Setting the Default Device

You can pick the default device used by `/start` (with no arguments) in either of two ways:

1. **Directly in Telegram:**
   ```text
   /default GS900
   ```
   *(Persisted immediately in `/var/lib/traccar-watchdog/state.json`.)*
2. **Declaratively in NixOS (`hosts/gvps/default.nix`):**
   ```nix
   _custom.services.traccar.watchdog.defaultDevice = "GS900"; # Traccar device name or IMEI
   ```
   *(Used as the initial default before `default_device_id` is saved in `state.json`.)*

---

## 3. Alert Rules & Fuel Relay Controls

While a device is **`🛡️ ARMED`**, `traccar-watchdog` monitors its live WebSocket events and sends high-priority Telegram alerts with a Google Maps pin if any rule triggers (each trigger type has a `300s` per-device cooldown):

1. **Movement Detected:** Haversine drift from that device's parked anchor exceeds **`35 m`** (`movementThresholdMeters`).
2. **Ignition ON:** `attributes.ignition == true` persists past the **`15 s`** grace period (`ignitionGraceSeconds`). Disarming that device or `ignition` returning to `false` within 15 seconds cancels its alert silently. Can be disabled with `watchdog.alertOnIgnition = false`.
   - For trackers whose Orange ACC wire is tied to Constant 12V, declare a computed attribute via `_custom.services.traccar.computedAttributes` (e.g., `attribute = "ignition"; expression = "speed > 0";`) — `traccar-watchdog` creates/updates it and links it to the configured device IMEI(s) automatically.
3. **GPS / Signal Loss:** Device becomes `offline`/`unknown`, stops sending packets, or keeps `valid == false` for more than **`120 s`** (`signalLossSeconds`). When connectivity returns while still armed, the bot sends **`📡 Signal Restored`**.

### Emergency Relay Buttons (Alert-Only — Never Auto-Cut)

Every alert attaches manual control buttons scoped to the triggering device (`POST /api/commands/send`):

- **`✂️ Cut Gas`** — Prompts a safety confirmation first:
  - Tap **`⚠️ CONFIRM Cut Gas (RELAY,1#)`** to cut fuel (`RELAY,1#`).
  - Tap **`↩️ Cancel`** to abort.
- **`✅ Restore Gas`** — Immediately sends **`RELAY,0#`** to re-enable fuel.

---

## 4. Webhook Endpoints (MacroDroid / NFC / Phone Automation)

When connected to your tailnet, Caddy proxies `/watchdog/*` on **`https://traccar.gvps.geanmar.com`** to `traccar-watchdog` (`127.0.0.1:8083`). All `POST` endpoints require:

```text
Authorization: Bearer <server-traccar-watchdog-webhook-token>
```

Pass an optional **`?device=<name_or_imei>`** query parameter to target a specific device (otherwise the default device is used):

| Endpoint | Method | Auth | Action |
| --- | --- | --- | --- |
| `/watchdog/arm[?device=...]` | `POST` | Bearer token | Arms target/default device & captures parked anchor |
| `/watchdog/disarm[?device=...]` | `POST` | Bearer token | Disarms target/default device & cancels ignition timer |
| `/watchdog/toggle[?device=...]` | `POST` | Bearer token | Flips target/default device between `ARMED` and `DISARMED` (debounced `3 s` by default via `toggleDebounceSeconds`; set `0` to disable) |
| `/watchdog/health[?device=...]` | `GET` | None (tailnet-only) | Returns JSON status for target/default device plus all devices under `devices` |

### `curl` Examples (from any Tailnet device)

```sh
# Check status of all devices (plus default device at top level)
curl -sS https://traccar.gvps.geanmar.com/watchdog/health

# Arm default device
curl -fsS -X POST https://traccar.gvps.geanmar.com/watchdog/arm \
  -H "Authorization: Bearer YOUR_WEBHOOK_TOKEN"

# Arm or disarm a specific device by name
curl -fsS -X POST "https://traccar.gvps.geanmar.com/watchdog/arm?device=Phone%20Test" \
  -H "Authorization: Bearer YOUR_WEBHOOK_TOKEN"

# Disarm default device (e.g., MacroDroid on Bluetooth car connect)
curl -fsS -X POST https://traccar.gvps.geanmar.com/watchdog/disarm \
  -H "Authorization: Bearer YOUR_WEBHOOK_TOKEN"
```

---

## 5. Stopping, Starting & Inspecting the Systemd Service (`gvps`)

Per-device state (`armed`, parked anchors) and `default_device_id` persist across restarts in `/var/lib/traccar-watchdog/state.json`.

```sh
# Check daemon health & memory usage
systemctl status traccar-watchdog traccar

# Follow live watchdog logs (WebSocket events, Telegram polling, webhooks)
journalctl -u traccar-watchdog -f

# Fully stop the watchdog daemon (disables Telegram bot + webhooks until started again)
doas systemctl stop traccar-watchdog

# Start or restart the daemon
doas systemctl start traccar-watchdog
doas systemctl restart traccar-watchdog
```

---

## 6. Adding the WanWay GS900 Alongside Phone Test Client

1. Point your **WanWay GS900** (via SMS/config tool) to **`<gvps-public-ip>:15023`** (`gt06Port = 15023` on `gvps`). Make sure TCP `15023` is also open in your VPS cloud firewall/security group.
2. Add the GS900 IMEI in **`https://traccar.gvps.geanmar.com`** (e.g., named `GS900`).
3. Set it as your default device either in Telegram (`/default GS900`) or in [`hosts/gvps/default.nix`](../../../../hosts/gvps/default.nix):
   ```nix
   _custom.services.traccar.watchdog.defaultDevice = "GS900";
   ```
   *(You can keep `enableOsmand = true` so both devices remain available, or set `enableOsmand = false` later if you retire phone testing.)*
