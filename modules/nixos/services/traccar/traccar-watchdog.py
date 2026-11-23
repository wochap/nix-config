#!/usr/bin/env python3
"""Traccar Stationary Watchdog daemon with Telegram alerts and Bearer-auth webhooks."""

from __future__ import annotations

import asyncio
import base64
from dataclasses import asdict, dataclass, field
import hashlib
import hmac
import html
import http.cookies
import json
import logging
import math
import os
from pathlib import Path
import signal
import ssl
import struct
import sys
import time
from typing import Any
import urllib.error
import urllib.parse
import urllib.request

logging.basicConfig(
    level=os.environ.get("LOG_LEVEL", "INFO").upper(),
    format="%(asctime)s %(levelname)s [%(name)s] %(message)s",
)
log = logging.getLogger("traccar-watchdog")

WS_GUID = "258EAFA5-E914-47DA-95CA-C5AB0DC85B11"


def _parse_bool(value: str | None, default: bool = False) -> bool:
    if value is None or value == "":
        return default
    return value.strip().lower() in {"1", "true", "yes", "on"}


def _require_env(name: str) -> str:
    value = os.environ.get(name, "").strip()
    if not value:
        raise RuntimeError(f"Missing required environment variable: {name}")
    return value


def haversine_meters(lat1: float, lon1: float, lat2: float, lon2: float) -> float:
    """Return great-circle distance in meters between two WGS84 coordinates."""
    radius_m = 6_371_000.0
    phi1 = math.radians(lat1)
    phi2 = math.radians(lat2)
    dphi = math.radians(lat2 - lat1)
    dlambda = math.radians(lon2 - lon1)
    a = (
        math.sin(dphi / 2.0) ** 2
        + math.cos(phi1) * math.cos(phi2) * math.sin(dlambda / 2.0) ** 2
    )
    return 2.0 * radius_m * math.atan2(math.sqrt(a), math.sqrt(1.0 - a))


def maps_url(lat: float, lon: float) -> str:
    """Return a Google Maps pin URL for the given coordinates."""
    return f"https://maps.google.com/?q={lat:.6f},{lon:.6f}"


@dataclass(frozen=True)
class WatchdogConfig:
    traccar_url: str
    traccar_email: str
    traccar_password: str
    traccar_device_unique_id: str
    auto_bootstrap_admin: bool
    telegram_bot_token: str
    telegram_chat_id: str
    telegram_api_base: str
    webhook_host: str
    webhook_port: int
    webhook_token: str
    state_file: Path
    movement_threshold_meters: float
    ignition_grace_seconds: float
    signal_loss_seconds: float
    alert_cooldown_seconds: float
    signal_check_interval_seconds: float

    @classmethod
    def from_env(cls) -> "WatchdogConfig":
        state_dir = os.environ.get("STATE_DIRECTORY", "/var/lib/traccar-watchdog")
        default_state = str(Path(state_dir) / "state.json")
        return cls(
            traccar_url=os.environ.get("TRACCAR_URL", "http://127.0.0.1:8082").rstrip("/"),
            traccar_email=_require_env("TRACCAR_EMAIL"),
            traccar_password=_require_env("TRACCAR_PASSWORD"),
            traccar_device_unique_id=os.environ.get("TRACCAR_DEVICE_UNIQUE_ID", "").strip(),
            auto_bootstrap_admin=_parse_bool(
                os.environ.get("AUTO_BOOTSTRAP_ADMIN"), default=True
            ),
            telegram_bot_token=os.environ.get("TELEGRAM_BOT_TOKEN", "").strip(),
            telegram_chat_id=os.environ.get("TELEGRAM_CHAT_ID", "").strip(),
            telegram_api_base=os.environ.get(
                "TELEGRAM_API_BASE", "https://api.telegram.org"
            ).rstrip("/"),
            webhook_host=os.environ.get("WEBHOOK_HOST", "127.0.0.1").strip(),
            webhook_port=int(os.environ.get("WEBHOOK_PORT", "8083")),
            webhook_token=_require_env("WEBHOOK_TOKEN"),
            state_file=Path(os.environ.get("STATE_FILE", default_state)),
            movement_threshold_meters=float(
                os.environ.get("MOVEMENT_THRESHOLD_METERS", "35")
            ),
            ignition_grace_seconds=float(
                os.environ.get("IGNITION_GRACE_SECONDS", "15")
            ),
            signal_loss_seconds=float(os.environ.get("SIGNAL_LOSS_SECONDS", "120")),
            alert_cooldown_seconds=float(
                os.environ.get("ALERT_COOLDOWN_SECONDS", "300")
            ),
            signal_check_interval_seconds=float(
                os.environ.get("SIGNAL_CHECK_INTERVAL_SECONDS", "1.0")
            ),
        )

    @property
    def telegram_enabled(self) -> bool:
        return bool(
            self.telegram_bot_token
            and self.telegram_chat_id
            and self.telegram_bot_token != "CHANGE_ME"
            and self.telegram_chat_id != "CHANGE_ME"
        )


@dataclass
class WatchdogState:
    armed: bool = False
    anchor_lat: float | None = None
    anchor_lon: float | None = None
    armed_at: float | None = None
    device_id: int | None = None
    device_name: str | None = None
    last_lat: float | None = None
    last_lon: float | None = None
    last_valid: bool | None = None
    last_valid_at: float | None = None
    last_packet_at: float | None = None
    last_ignition: bool | None = None
    device_status: str | None = None
    status_lost_at: float | None = None
    in_signal_loss_alert: bool = False
    last_alert_at: dict[str, float] = field(default_factory=dict)

    @classmethod
    def load(cls, path: Path) -> "WatchdogState":
        if not path.exists():
            return cls()
        try:
            raw = json.loads(path.read_text(encoding="utf-8"))
        except (OSError, json.JSONDecodeError) as exc:
            log.warning("Failed to load %s (%s); starting with fresh state", path, exc)
            return cls()
        known = {f.name for f in cls.__dataclass_fields__.values()}
        filtered = {k: v for k, v in raw.items() if k in known}
        state = cls(**filtered)
        if not isinstance(state.last_alert_at, dict):
            state.last_alert_at = {}
        return state

    def save(self, path: Path) -> None:
        path.parent.mkdir(parents=True, exist_ok=True)
        tmp = path.with_name(f".{path.name}.{os.getpid()}.tmp")
        payload = json.dumps(asdict(self), indent=2, sort_keys=True) + "\n"
        tmp.write_text(payload, encoding="utf-8")
        os.replace(tmp, path)


class TraccarAuthError(RuntimeError):
    """Raised when Traccar returns 401/403."""


class TraccarClient:
    """Async Traccar HTTP + WebSocket client using JSESSIONID cookie auth."""

    def __init__(self, cfg: WatchdogConfig) -> None:
        self.cfg = cfg
        self.cookies: dict[str, str] = {}
        self._lock = asyncio.Lock()

    def _cookie_header(self) -> str:
        return "; ".join(f"{k}={v}" for k, v in self.cookies.items())

    def _store_cookies(self, headers: Any) -> None:
        for raw_cookie in headers.get_all("Set-Cookie", []):
            jar = http.cookies.SimpleCookie()
            jar.load(raw_cookie)
            for name, morsel in jar.items():
                self.cookies[name] = morsel.value

    def _http_sync(
        self,
        method: str,
        path: str,
        body: bytes | None = None,
        headers: dict[str, str] | None = None,
        timeout: float = 15.0,
    ) -> tuple[int, Any]:
        url = f"{self.cfg.traccar_url}{path}"
        req_headers = dict(headers or {})
        cookie_hdr = self._cookie_header()
        if cookie_hdr:
            req_headers["Cookie"] = cookie_hdr
        req = urllib.request.Request(url, data=body, headers=req_headers, method=method)
        try:
            with urllib.request.urlopen(req, timeout=timeout) as resp:
                self._store_cookies(resp.headers)
                raw = resp.read()
                if not raw:
                    return resp.status, None
                try:
                    return resp.status, json.loads(raw.decode("utf-8"))
                except json.JSONDecodeError:
                    return resp.status, raw.decode("utf-8", errors="replace")
        except urllib.error.HTTPError as err:
            raw = err.read()
            msg = raw.decode("utf-8", errors="replace")
            if err.code in (401, 403):
                raise TraccarAuthError(f"{method} {path} -> HTTP {err.code}: {msg}") from err
            raise RuntimeError(f"{method} {path} -> HTTP {err.code}: {msg}") from err

    async def _http(
        self,
        method: str,
        path: str,
        body: bytes | None = None,
        headers: dict[str, str] | None = None,
        timeout: float = 15.0,
    ) -> tuple[int, Any]:
        return await asyncio.to_thread(self._http_sync, method, path, body, headers, timeout)

    async def login(self) -> None:
        async with self._lock:
            form = urllib.parse.urlencode(
                {"email": self.cfg.traccar_email, "password": self.cfg.traccar_password}
            ).encode("utf-8")
            headers = {"Content-Type": "application/x-www-form-urlencoded"}
            try:
                await self._http("POST", "/api/session", body=form, headers=headers)
            except TraccarAuthError:
                if not self.cfg.auto_bootstrap_admin:
                    raise
                log.info("Traccar login failed; attempting first-run admin bootstrap")
                bootstrap_payload = json.dumps(
                    {
                        "name": "admin",
                        "email": self.cfg.traccar_email,
                        "password": self.cfg.traccar_password,
                    }
                ).encode("utf-8")
                await self._http(
                    "POST",
                    "/api/users",
                    body=bootstrap_payload,
                    headers={"Content-Type": "application/json"},
                )
                await self._http("POST", "/api/session", body=form, headers=headers)
            if "JSESSIONID" not in self.cookies:
                raise RuntimeError("Traccar /api/session succeeded without JSESSIONID cookie")
            log.info("Authenticated with Traccar at %s", self.cfg.traccar_url)

    async def _authed_get(self, path: str) -> Any:
        try:
            _, data = await self._http("GET", path)
            return data
        except TraccarAuthError:
            await self.login()
            _, data = await self._http("GET", path)
            return data

    async def fetch_devices(self) -> list[dict[str, Any]]:
        data = await self._authed_get("/api/devices")
        return data if isinstance(data, list) else []

    async def fetch_positions(self) -> list[dict[str, Any]]:
        data = await self._authed_get("/api/positions")
        return data if isinstance(data, list) else []

    async def send_command(self, device_id: int, command_data: str) -> Any:
        payload = json.dumps(
            {
                "deviceId": device_id,
                "type": "custom",
                "attributes": {"data": command_data},
            }
        ).encode("utf-8")
        headers = {"Content-Type": "application/json"}
        try:
            _, data = await self._http("POST", "/api/commands/send", body=payload, headers=headers)
            return data
        except TraccarAuthError:
            await self.login()
            _, data = await self._http("POST", "/api/commands/send", body=payload, headers=headers)
            return data

    @staticmethod
    async def _send_ws_frame(writer: asyncio.StreamWriter, opcode: int, payload: bytes) -> None:
        mask_key = os.urandom(4)
        length = len(payload)
        header = bytearray([0x80 | opcode])
        if length < 126:
            header.append(0x80 | length)
        elif length < 65536:
            header.append(0x80 | 126)
            header.extend(struct.pack("!H", length))
        else:
            header.append(0x80 | 127)
            header.extend(struct.pack("!Q", length))
        header.extend(mask_key)
        masked = bytes(b ^ mask_key[i % 4] for i, b in enumerate(payload))
        writer.write(bytes(header) + masked)
        await writer.drain()

    @staticmethod
    async def _read_ws_frame(reader: asyncio.StreamReader) -> tuple[bool, int, bytes]:
        b1, b2 = await reader.readexactly(2)
        fin = bool(b1 & 0x80)
        opcode = b1 & 0x0F
        masked = bool(b2 & 0x80)
        length = b2 & 0x7F
        if length == 126:
            (length,) = struct.unpack("!H", await reader.readexactly(2))
        elif length == 127:
            (length,) = struct.unpack("!Q", await reader.readexactly(8))
        mask_key = await reader.readexactly(4) if masked else b""
        payload = await reader.readexactly(length)
        if masked:
            payload = bytes(b ^ mask_key[i % 4] for i, b in enumerate(payload))
        return fin, opcode, payload

    async def subscribe_socket(self, on_message: Any, stop_event: asyncio.Event) -> None:
        parsed = urllib.parse.urlparse(self.cfg.traccar_url)
        use_tls = parsed.scheme == "https"
        host = parsed.hostname or "127.0.0.1"
        port = parsed.port or (443 if use_tls else 80)
        base_path = parsed.path.rstrip("/")
        ws_path = f"{base_path}/api/socket"
        ssl_ctx = ssl.create_default_context() if use_tls else None

        if not self.cookies.get("JSESSIONID"):
            await self.login()

        reader, writer = await asyncio.open_connection(host, port, ssl=ssl_ctx)
        try:
            ws_key = base64.b64encode(os.urandom(16)).decode("ascii")
            host_hdr = f"{host}:{port}"
            req = (
                f"GET {ws_path} HTTP/1.1\r\n"
                f"Host: {host_hdr}\r\n"
                "Upgrade: websocket\r\n"
                "Connection: Upgrade\r\n"
                f"Sec-WebSocket-Key: {ws_key}\r\n"
                "Sec-WebSocket-Version: 13\r\n"
                f"Cookie: {self._cookie_header()}\r\n"
                "\r\n"
            )
            writer.write(req.encode("ascii"))
            await writer.drain()

            raw_head = await asyncio.wait_for(reader.readuntil(b"\r\n\r\n"), timeout=10.0)
            lines = raw_head.decode("latin-1").split("\r\n")
            status_line = lines[0]
            if " 101 " not in status_line:
                if " 401 " in status_line or " 403 " in status_line:
                    self.cookies.clear()
                    raise TraccarAuthError(f"WebSocket upgrade rejected: {status_line}")
                raise RuntimeError(f"WebSocket upgrade failed: {status_line}")

            resp_headers: dict[str, str] = {}
            for line in lines[1:]:
                if ":" in line:
                    k, v = line.split(":", 1)
                    resp_headers[k.strip().lower()] = v.strip()

            expected_accept = base64.b64encode(
                hashlib.sha1((ws_key + WS_GUID).encode("ascii")).digest()
            ).decode("ascii")
            if resp_headers.get("sec-websocket-accept") != expected_accept:
                raise RuntimeError("Invalid Sec-WebSocket-Accept from Traccar")

            log.info("Subscribed to Traccar WebSocket %s", ws_path)
            fragments = bytearray()
            while not stop_event.is_set():
                try:
                    fin, opcode, payload = await asyncio.wait_for(
                        self._read_ws_frame(reader), timeout=45.0
                    )
                except asyncio.TimeoutError:
                    await self._send_ws_frame(writer, 0x9, b"hb")
                    continue

                if opcode == 0x8:  # CLOSE
                    await self._send_ws_frame(writer, 0x8, b"")
                    break
                if opcode == 0x9:  # PING
                    await self._send_ws_frame(writer, 0xA, payload)
                    continue
                if opcode == 0xA:  # PONG
                    continue
                if opcode in (0x1, 0x0):
                    fragments.extend(payload)
                    if not fin:
                        continue
                    text = bytes(fragments).decode("utf-8")
                    fragments.clear()
                    if text:
                        await on_message(json.loads(text))
        finally:
            writer.close()
            try:
                await writer.wait_closed()
            except Exception:
                pass


class TelegramBot:
    """Long-polling Telegram Bot API client strictly locked to TELEGRAM_CHAT_ID."""

    def __init__(self, cfg: WatchdogConfig) -> None:
        self.cfg = cfg
        self.enabled = cfg.telegram_enabled
        if not self.enabled:
            log.warning(
                "Telegram bot disabled (TELEGRAM_BOT_TOKEN or TELEGRAM_CHAT_ID is unset/CHANGE_ME)"
            )

    async def _post_json(
        self, method: str, payload: dict[str, Any], timeout: float
    ) -> Any:
        url = f"{self.cfg.telegram_api_base}/bot{self.cfg.telegram_bot_token}/{method}"
        parsed = urllib.parse.urlparse(url)
        use_tls = parsed.scheme == "https"
        host = parsed.hostname or "api.telegram.org"
        port = parsed.port or (443 if use_tls else 80)
        path = parsed.path or "/"
        if parsed.query:
            path = f"{path}?{parsed.query}"
        ssl_ctx = ssl.create_default_context() if use_tls else None

        body = json.dumps(payload).encode("utf-8")
        host_hdr = host if port in (80, 443) else f"{host}:{port}"

        async def _do_request() -> Any:
            reader, writer = await asyncio.open_connection(host, port, ssl=ssl_ctx)
            try:
                req = (
                    f"POST {path} HTTP/1.1\r\n"
                    f"Host: {host_hdr}\r\n"
                    "Content-Type: application/json\r\n"
                    f"Content-Length: {len(body)}\r\n"
                    "Connection: close\r\n"
                    "\r\n"
                ).encode("ascii") + body
                writer.write(req)
                await writer.drain()

                raw_head = await reader.readuntil(b"\r\n\r\n")
                lines = raw_head.decode("latin-1").split("\r\n")
                status_parts = lines[0].split(" ", 2)
                status_code = int(status_parts[1]) if len(status_parts) > 1 else 0
                headers: dict[str, str] = {}
                for line in lines[1:]:
                    if ":" in line:
                        k, v = line.split(":", 1)
                        headers[k.strip().lower()] = v.strip()

                if "chunked" in headers.get("transfer-encoding", "").lower():
                    chunks = bytearray()
                    while True:
                        size_line = await reader.readline()
                        size = int(size_line.split(b";", 1)[0].strip(), 16)
                        if size == 0:
                            break
                        chunks.extend(await reader.readexactly(size))
                        await reader.readexactly(2)
                    raw_body = bytes(chunks)
                elif "content-length" in headers:
                    raw_body = await reader.readexactly(int(headers["content-length"]))
                else:
                    raw_body = await reader.read()

                data = json.loads(raw_body.decode("utf-8"))
                if status_code >= 400 or not data.get("ok", False):
                    raise RuntimeError(f"Telegram API {method} HTTP {status_code}: {data}")
                return data.get("result")
            finally:
                writer.close()
                try:
                    await writer.wait_closed()
                except Exception:
                    pass

        return await asyncio.wait_for(_do_request(), timeout=timeout)

    async def call(
        self, method: str, payload: dict[str, Any], timeout: float = 15.0
    ) -> Any:
        if not self.enabled:
            return None
        return await self._post_json(method, payload, timeout)

    async def send_message(
        self, text: str, reply_markup: dict[str, Any] | None = None
    ) -> Any:
        if not self.enabled:
            return None
        payload: dict[str, Any] = {
            "chat_id": self.cfg.telegram_chat_id,
            "text": text,
            "parse_mode": "HTML",
            "disable_web_page_preview": True,
        }
        if reply_markup is not None:
            payload["reply_markup"] = reply_markup
        try:
            return await self.call("sendMessage", payload)
        except Exception as exc:
            log.error("Failed to send Telegram message: %s", exc)
            return None

    async def edit_reply_markup(
        self, chat_id: str | int, message_id: int, reply_markup: dict[str, Any]
    ) -> None:
        if not self.enabled:
            return
        try:
            await self.call(
                "editMessageReplyMarkup",
                {
                    "chat_id": chat_id,
                    "message_id": message_id,
                    "reply_markup": reply_markup,
                },
            )
        except Exception as exc:
            log.debug("Failed to edit reply markup: %s", exc)

    async def answer_callback(
        self, callback_id: str, text: str | None = None, show_alert: bool = False
    ) -> None:
        if not self.enabled:
            return
        payload: dict[str, Any] = {
            "callback_query_id": callback_id,
            "show_alert": show_alert,
        }
        if text:
            payload["text"] = text
        try:
            await self.call("answerCallbackQuery", payload)
        except Exception as exc:
            log.debug("Failed to answer callback query: %s", exc)


class WatchdogEngine:
    """Core Stationary Watchdog state machine, alert evaluator, and command handler."""

    def __init__(
        self, cfg: WatchdogConfig, traccar: TraccarClient, telegram: TelegramBot
    ) -> None:
        self.cfg = cfg
        self.traccar = traccar
        self.telegram = telegram
        self.state = WatchdogState.load(cfg.state_file)
        self._state_lock = asyncio.Lock()
        self._ignition_task: asyncio.Task[None] | None = None

    def toggle_keyboard(self) -> dict[str, Any]:
        btn = (
            {"text": "🔓 Disarm Watchdog", "callback_data": "watchdog:disarm"}
            if self.state.armed
            else {"text": "🛡️ Arm Watchdog", "callback_data": "watchdog:arm"}
        )
        return {"inline_keyboard": [[btn]]}

    def alert_keyboard(self) -> dict[str, Any]:
        toggle_btn = (
            {"text": "🔓 Disarm Watchdog", "callback_data": "watchdog:disarm"}
            if self.state.armed
            else {"text": "🛡️ Arm Watchdog", "callback_data": "watchdog:arm"}
        )
        return {
            "inline_keyboard": [
                [
                    {"text": "✂️ Cut Gas", "callback_data": "gas:cut_prompt"},
                    {"text": "✅ Restore Gas", "callback_data": "gas:restore"},
                ],
                [toggle_btn],
            ]
        }

    def confirm_cut_keyboard(self) -> dict[str, Any]:
        toggle_btn = (
            {"text": "🔓 Disarm Watchdog", "callback_data": "watchdog:disarm"}
            if self.state.armed
            else {"text": "🛡️ Arm Watchdog", "callback_data": "watchdog:arm"}
        )
        return {
            "inline_keyboard": [
                [
                    {
                        "text": "⚠️ CONFIRM Cut Gas (RELAY,1#)",
                        "callback_data": "gas:cut_confirm",
                    },
                    {"text": "↩️ Cancel", "callback_data": "gas:cut_cancel"},
                ],
                [toggle_btn],
            ]
        }

    def _select_device(self, devices: list[dict[str, Any]]) -> dict[str, Any] | None:
        if not devices:
            return None
        if self.cfg.traccar_device_unique_id:
            for dev in devices:
                if str(dev.get("uniqueId", "")) == self.cfg.traccar_device_unique_id:
                    return dev
            return None
        if self.state.device_id is not None:
            for dev in devices:
                if dev.get("id") == self.state.device_id:
                    return dev
        if len(devices) > 1:
            log.warning(
                "Multiple Traccar devices found (%d); picking first (%s). Set deviceUniqueId to pin one.",
                len(devices),
                devices[0].get("uniqueId"),
            )
        return devices[0]

    def _save_state(self) -> None:
        self.state.save(self.cfg.state_file)

    def _cancel_ignition_timer(self) -> None:
        if self._ignition_task and not self._ignition_task.done():
            self._ignition_task.cancel()
        self._ignition_task = None

    async def sync_from_traccar(self) -> None:
        devices = await self.traccar.fetch_devices()
        target = self._select_device(devices)
        positions = await self.traccar.fetch_positions()

        async with self._state_lock:
            now = time.time()
            if target is not None:
                self.state.device_id = int(target["id"])
                self.state.device_name = str(
                    target.get("name") or target.get("uniqueId") or target["id"]
                )
                status = target.get("status")
                self.state.device_status = str(status) if status is not None else None
                if self.state.device_status in ("offline", "unknown"):
                    if self.state.status_lost_at is None:
                        self.state.status_lost_at = now
                else:
                    self.state.status_lost_at = None

            if self.state.device_id is not None:
                matching = [p for p in positions if p.get("deviceId") == self.state.device_id]
                if matching:
                    pos = matching[-1]
                    self._apply_position_locked(pos, now=now, from_sync=True)
            self._save_state()

    def _apply_position_locked(
        self, pos: dict[str, Any], now: float, from_sync: bool = False
    ) -> dict[str, Any]:
        lat = pos.get("latitude")
        lon = pos.get("longitude")
        valid = pos.get("valid")
        attrs = pos.get("attributes") if isinstance(pos.get("attributes"), dict) else {}
        ignition = attrs.get("ignition")

        if not from_sync or self.state.last_packet_at is None:
            self.state.last_packet_at = now

        has_coords = lat is not None and lon is not None and not (
            float(lat) == 0.0 and float(lon) == 0.0 and valid is False
        )
        if valid is True and lat is not None and lon is not None:
            self.state.last_lat = float(lat)
            self.state.last_lon = float(lon)
            self.state.last_valid = True
            self.state.last_valid_at = now
            if self.state.armed and self.state.anchor_lat is None:
                self.state.anchor_lat = self.state.last_lat
                self.state.anchor_lon = self.state.last_lon
        elif valid is False:
            self.state.last_valid = False
        elif has_coords and self.state.last_lat is None:
            self.state.last_lat = float(lat)
            self.state.last_lon = float(lon)

        if "ignition" in attrs and ignition is not None:
            self.state.last_ignition = bool(ignition)

        return {
            "valid": valid,
            "lat": float(lat) if lat is not None else None,
            "lon": float(lon) if lon is not None else None,
            "ignition": bool(ignition) if "ignition" in attrs and ignition is not None else None,
        }

    def _can_fire_alert_locked(self, key: str, now: float) -> bool:
        last = self.state.last_alert_at.get(key)
        if last is not None and (now - last) < self.cfg.alert_cooldown_seconds:
            return False
        self.state.last_alert_at[key] = now
        return True

    def _format_pin(self, lat: float | None, lon: float | None) -> str:
        if lat is None or lon is None:
            return "Unavailable"
        url = maps_url(lat, lon)
        return f'<a href="{url}">{lat:.6f}, {lon:.6f}</a>'

    def _device_label(self) -> str:
        return html.escape(self.state.device_name or "GS900")

    async def _send_alert(self, title: str, details: str, lat: float | None, lon: float | None) -> None:
        pin = self._format_pin(lat, lon)
        text = (
            f"🚨 <b>WATCHDOG ALERT: {html.escape(title)}</b>\n"
            f"Device: <b>{self._device_label()}</b>\n"
            f"{details}\n"
            f"Location: {pin}"
        )
        await self.telegram.send_message(text, reply_markup=self.alert_keyboard())

    async def _ignition_grace_worker(self) -> None:
        try:
            await asyncio.sleep(self.cfg.ignition_grace_seconds)
            async with self._state_lock:
                if not self.state.armed:
                    return
                now = time.time()
                if not self._can_fire_alert_locked("ignition", now):
                    return
                lat, lon = self.state.last_lat, self.state.last_lon
                if lat is None or lon is None:
                    lat, lon = self.state.anchor_lat, self.state.anchor_lon
                self._save_state()

            await self._send_alert(
                "Ignition ON",
                f"Ignition remained ON past {int(self.cfg.ignition_grace_seconds)}s grace period.",
                lat,
                lon,
            )
        except asyncio.CancelledError:
            log.info("Pending ignition alert cancelled (watchdog disarmed)")
            raise

    async def arm(self, source: str) -> dict[str, Any]:
        try:
            await self.sync_from_traccar()
        except Exception as exc:
            log.warning("Pre-arm Traccar sync failed (%s); using cached coordinates", exc)

        async with self._state_lock:
            now = time.time()
            self._cancel_ignition_timer()
            self.state.armed = True
            self.state.armed_at = now
            self.state.in_signal_loss_alert = False
            self.state.last_alert_at = {}
            if self.state.last_lat is not None and self.state.last_lon is not None:
                self.state.anchor_lat = self.state.last_lat
                self.state.anchor_lon = self.state.last_lon
            else:
                self.state.anchor_lat = None
                self.state.anchor_lon = None
            if self.state.device_status in ("offline", "unknown"):
                self.state.status_lost_at = now
            self._save_state()
            anchor_lat, anchor_lon = self.state.anchor_lat, self.state.anchor_lon

        pin = self._format_pin(anchor_lat, anchor_lon)
        msg = (
            f"🛡️ <b>Watchdog ARMED</b> ({html.escape(source)})\n"
            f"Device: <b>{self._device_label()}</b>\n"
            f"Parked Anchor: {pin}"
        )
        await self.telegram.send_message(msg, reply_markup=self.toggle_keyboard())
        return self.status_payload()

    async def disarm(self, source: str) -> dict[str, Any]:
        async with self._state_lock:
            self._cancel_ignition_timer()
            self.state.armed = False
            self.state.in_signal_loss_alert = False
            self.state.last_alert_at = {}
            self._save_state()

        msg = (
            f"🔓 <b>Watchdog DISARMED</b> ({html.escape(source)})\n"
            f"Device: <b>{self._device_label()}</b>"
        )
        await self.telegram.send_message(msg, reply_markup=self.toggle_keyboard())
        return self.status_payload()

    async def toggle(self, source: str) -> dict[str, Any]:
        if self.state.armed:
            return await self.disarm(source)
        return await self.arm(source)

    def status_payload(self) -> dict[str, Any]:
        anchor = (
            {"lat": self.state.anchor_lat, "lon": self.state.anchor_lon}
            if self.state.anchor_lat is not None and self.state.anchor_lon is not None
            else None
        )
        return {
            "ok": True,
            "armed": self.state.armed,
            "anchor": anchor,
            "device_id": self.state.device_id,
            "device_name": self.state.device_name,
            "device_status": self.state.device_status,
        }

    def status_text(self) -> str:
        badge = "🛡️ <b>ARMED</b>" if self.state.armed else "🔓 <b>DISARMED</b>"
        lines = [
            f"Status: {badge}",
            f"Device: <b>{self._device_label()}</b> ({html.escape(self.state.device_status or 'unknown')})",
            f"Last Position: {self._format_pin(self.state.last_lat, self.state.last_lon)}",
        ]
        if self.state.armed:
            lines.append(
                f"Parked Anchor: {self._format_pin(self.state.anchor_lat, self.state.anchor_lon)}"
            )
            if (
                self.state.anchor_lat is not None
                and self.state.anchor_lon is not None
                and self.state.last_lat is not None
                and self.state.last_lon is not None
            ):
                dist = haversine_meters(
                    self.state.anchor_lat,
                    self.state.anchor_lon,
                    self.state.last_lat,
                    self.state.last_lon,
                )
                lines.append(f"Drift from Anchor: <b>{dist:.1f} m</b>")
        return "\n".join(lines)

    async def send_status(self) -> None:
        await self.telegram.send_message(
            self.status_text(), reply_markup=self.toggle_keyboard()
        )

    async def handle_ws_message(self, payload: dict[str, Any]) -> None:
        devices = payload.get("devices")
        if isinstance(devices, list):
            for dev in devices:
                await self._on_device(dev)

        positions = payload.get("positions")
        if isinstance(positions, list):
            for pos in positions:
                await self._on_position(pos)

    async def _on_device(self, dev: dict[str, Any]) -> None:
        restored_coords: tuple[float | None, float | None] | None = None
        async with self._state_lock:
            now = time.time()
            if self.state.device_id is None:
                if (
                    not self.cfg.traccar_device_unique_id
                    or str(dev.get("uniqueId", "")) == self.cfg.traccar_device_unique_id
                ):
                    self.state.device_id = int(dev["id"])
                else:
                    return
            elif dev.get("id") != self.state.device_id:
                return

            self.state.device_name = str(
                dev.get("name") or dev.get("uniqueId") or dev["id"]
            )
            self.state.device_status = (
                str(dev["status"]) if dev.get("status") is not None else None
            )
            self.state.last_packet_at = now
            if self.state.device_status in ("offline", "unknown"):
                if self.state.status_lost_at is None:
                    self.state.status_lost_at = now
            else:
                self.state.status_lost_at = None
                if (
                    self.state.armed
                    and self.state.in_signal_loss_alert
                    and self.state.last_valid is not False
                ):
                    self.state.in_signal_loss_alert = False
                    restored_coords = (self.state.last_lat, self.state.last_lon)
            self._save_state()

        if restored_coords is not None:
            await self.telegram.send_message(
                f"📡 <b>Signal Restored</b>\nDevice: <b>{self._device_label()}</b>\n"
                f"Location: {self._format_pin(*restored_coords)}",
                reply_markup=self.toggle_keyboard(),
            )

    async def _on_position(self, pos: dict[str, Any]) -> None:
        movement_alert: tuple[float, float, float] | None = None
        restored_coords: tuple[float | None, float | None] | None = None

        async with self._state_lock:
            if self.state.device_id is None and pos.get("deviceId") is not None:
                self.state.device_id = int(pos["deviceId"])
            elif pos.get("deviceId") != self.state.device_id:
                return

            now = time.time()
            info = self._apply_position_locked(pos, now=now, from_sync=False)

            if self.state.armed:
                if (
                    info["valid"] is True
                    and self.state.anchor_lat is not None
                    and self.state.anchor_lon is not None
                    and self.state.last_lat is not None
                    and self.state.last_lon is not None
                ):
                    dist = haversine_meters(
                        self.state.anchor_lat,
                        self.state.anchor_lon,
                        self.state.last_lat,
                        self.state.last_lon,
                    )
                    if dist > self.cfg.movement_threshold_meters and self._can_fire_alert_locked(
                        "movement", now
                    ):
                        movement_alert = (dist, self.state.last_lat, self.state.last_lon)

                if info["ignition"] is True:
                    last_ign = self.state.last_alert_at.get("ignition")
                    in_cooldown = (
                        last_ign is not None
                        and (now - last_ign) < self.cfg.alert_cooldown_seconds
                    )
                    if not in_cooldown and (
                        self._ignition_task is None or self._ignition_task.done()
                    ):
                        self._ignition_task = asyncio.create_task(
                            self._ignition_grace_worker()
                        )

                if (
                    self.state.in_signal_loss_alert
                    and info["valid"] is True
                    and self.state.device_status not in ("offline", "unknown")
                ):
                    self.state.in_signal_loss_alert = False
                    restored_coords = (self.state.last_lat, self.state.last_lon)

            self._save_state()

        if movement_alert is not None:
            dist, lat, lon = movement_alert
            await self._send_alert(
                "Movement Detected",
                f"Moved <b>{dist:.1f} m</b> from parked anchor (limit: {self.cfg.movement_threshold_meters:.0f} m).",
                lat,
                lon,
            )

        if restored_coords is not None:
            await self.telegram.send_message(
                f"📡 <b>Signal Restored</b>\nDevice: <b>{self._device_label()}</b>\n"
                f"Location: {self._format_pin(*restored_coords)}",
                reply_markup=self.toggle_keyboard(),
            )

    async def signal_loss_loop(self, stop_event: asyncio.Event) -> None:
        while not stop_event.is_set():
            try:
                await asyncio.wait_for(
                    stop_event.wait(), timeout=self.cfg.signal_check_interval_seconds
                )
                break
            except asyncio.TimeoutError:
                pass

            reason: str | None = None
            lat: float | None = None
            lon: float | None = None

            async with self._state_lock:
                if not self.state.armed:
                    continue
                now = time.time()
                armed_at = self.state.armed_at or now
                timeout = self.cfg.signal_loss_seconds

                if self.state.device_status in ("offline", "unknown"):
                    since = max(self.state.status_lost_at or armed_at, armed_at)
                    elapsed = now - since
                    if elapsed > timeout:
                        reason = (
                            f"Device status is <b>{html.escape(self.state.device_status)}</b> "
                            f"for {int(elapsed)}s."
                        )

                if reason is None:
                    last_pkt = max(self.state.last_packet_at or 0.0, armed_at)
                    pkt_elapsed = now - last_pkt
                    if pkt_elapsed > timeout:
                        reason = f"No tracker packet received for {int(pkt_elapsed)}s."

                if reason is None and self.state.last_valid is False:
                    since_valid = max(self.state.last_valid_at or 0.0, armed_at)
                    invalid_elapsed = now - since_valid
                    if invalid_elapsed > timeout:
                        reason = f"Invalid GPS fix persisted for {int(invalid_elapsed)}s."

                if reason is not None:
                    self.state.in_signal_loss_alert = True
                    if self._can_fire_alert_locked("signal_loss", now):
                        lat = self.state.last_lat or self.state.anchor_lat
                        lon = self.state.last_lon or self.state.anchor_lon
                        self._save_state()
                    else:
                        reason = None

            if reason is not None:
                await self._send_alert("GPS / Signal Loss", reason, lat, lon)

    async def execute_gas_command(self, cut: bool) -> str:
        device_id = self.state.device_id
        if device_id is None:
            await self.sync_from_traccar()
            device_id = self.state.device_id
        if device_id is None:
            raise RuntimeError("No Traccar device selected yet")
        cmd = "RELAY,1#" if cut else "RELAY,0#"
        await self.traccar.send_command(device_id, cmd)
        return cmd

    async def handle_telegram_update(self, update: dict[str, Any]) -> None:
        expected_chat = str(self.cfg.telegram_chat_id)

        if "message" in update and isinstance(update["message"], dict):
            msg = update["message"]
            chat_id = str(msg.get("chat", {}).get("id", ""))
            if chat_id != expected_chat:
                log.warning("Ignoring Telegram message from unauthorized chat_id=%s", chat_id)
                return
            text = str(msg.get("text", "")).strip()
            cmd = text.split()[0].split("@")[0].lower() if text else ""
            if cmd in ("/start", "/status"):
                await self.send_status()
            elif cmd == "/arm":
                await self.arm("telegram")
            elif cmd == "/disarm":
                await self.disarm("telegram")
            return

        if "callback_query" in update and isinstance(update["callback_query"], dict):
            cb = update["callback_query"]
            cb_id = str(cb.get("id", ""))
            msg = cb.get("message") if isinstance(cb.get("message"), dict) else {}
            chat_id = str(msg.get("chat", {}).get("id", ""))
            if not chat_id:
                chat_id = str(cb.get("from", {}).get("id", ""))
            if chat_id != expected_chat:
                log.warning("Ignoring Telegram callback from unauthorized chat_id=%s", chat_id)
                return

            data = str(cb.get("data", ""))
            message_id = msg.get("message_id")

            if data == "watchdog:arm":
                await self.telegram.answer_callback(cb_id, "Arming watchdog...")
                await self.arm("telegram")
            elif data == "watchdog:disarm":
                await self.telegram.answer_callback(cb_id, "Disarming watchdog...")
                await self.disarm("telegram")
            elif data == "watchdog:toggle":
                await self.telegram.answer_callback(cb_id, "Toggling watchdog...")
                await self.toggle("telegram")
            elif data == "gas:cut_prompt":
                await self.telegram.answer_callback(
                    cb_id, "Tap CONFIRM to send RELAY,1#", show_alert=False
                )
                if message_id is not None:
                    await self.telegram.edit_reply_markup(
                        chat_id, int(message_id), self.confirm_cut_keyboard()
                    )
            elif data == "gas:cut_cancel":
                await self.telegram.answer_callback(cb_id, "Cancelled")
                if message_id is not None:
                    await self.telegram.edit_reply_markup(
                        chat_id, int(message_id), self.alert_keyboard()
                    )
            elif data == "gas:cut_confirm":
                try:
                    cmd = await self.execute_gas_command(cut=True)
                    await self.telegram.answer_callback(cb_id, f"Sent {cmd}")
                    if message_id is not None:
                        await self.telegram.edit_reply_markup(
                            chat_id, int(message_id), self.alert_keyboard()
                        )
                    await self.telegram.send_message(
                        f"✂️ <b>Fuel Cut Command Dispatched</b> (<code>{cmd}</code>)\n"
                        f"Device: <b>{self._device_label()}</b>",
                        reply_markup=self.alert_keyboard(),
                    )
                except Exception as exc:
                    log.error("Failed to send RELAY,1#: %s", exc)
                    await self.telegram.answer_callback(cb_id, f"Error: {exc}", show_alert=True)
            elif data == "gas:restore":
                try:
                    cmd = await self.execute_gas_command(cut=False)
                    await self.telegram.answer_callback(cb_id, f"Sent {cmd}")
                    await self.telegram.send_message(
                        f"✅ <b>Fuel Restore Command Dispatched</b> (<code>{cmd}</code>)\n"
                        f"Device: <b>{self._device_label()}</b>",
                        reply_markup=self.toggle_keyboard(),
                    )
                except Exception as exc:
                    log.error("Failed to send RELAY,0#: %s", exc)
                    await self.telegram.answer_callback(cb_id, f"Error: {exc}", show_alert=True)


async def telegram_poll_loop(
    bot: TelegramBot, engine: WatchdogEngine, stop_event: asyncio.Event
) -> None:
    if not bot.enabled:
        await stop_event.wait()
        return

    offset = 0
    backoff = 1.0
    while not stop_event.is_set():
        try:
            updates = await bot.call(
                "getUpdates",
                {
                    "offset": offset,
                    "timeout": 25,
                    "allowed_updates": ["message", "callback_query"],
                },
                timeout=35.0,
            )
            backoff = 1.0
            if isinstance(updates, list):
                for upd in updates:
                    if isinstance(upd, dict):
                        offset = max(offset, int(upd.get("update_id", 0)) + 1)
                        await engine.handle_telegram_update(upd)
        except asyncio.CancelledError:
            raise
        except Exception as exc:
            log.warning("Telegram poll error (%s); retrying in %.1fs", exc, backoff)
            try:
                await asyncio.wait_for(stop_event.wait(), timeout=backoff)
                break
            except asyncio.TimeoutError:
                backoff = min(backoff * 2.0, 30.0)


async def traccar_ws_loop(
    traccar: TraccarClient, engine: WatchdogEngine, stop_event: asyncio.Event
) -> None:
    backoff = 1.0
    while not stop_event.is_set():
        try:
            await traccar.login()
            await engine.sync_from_traccar()
            backoff = 1.0
            await traccar.subscribe_socket(engine.handle_ws_message, stop_event)
        except asyncio.CancelledError:
            raise
        except Exception as exc:
            log.warning("Traccar connection error (%s); reconnecting in %.1fs", exc, backoff)
        if stop_event.is_set():
            break
        try:
            await asyncio.wait_for(stop_event.wait(), timeout=backoff)
            break
        except asyncio.TimeoutError:
            backoff = min(backoff * 2.0, 30.0)


def _normalize_webhook_path(raw_target: str) -> str:
    path = urllib.parse.urlsplit(raw_target).path or "/"
    if path == "/watchdog":
        path = "/"
    elif path.startswith("/watchdog/"):
        path = path[len("/watchdog") :]
    if len(path) > 1:
        path = path.rstrip("/")
    return path


def _http_json_response(status: int, reason: str, payload: dict[str, Any]) -> bytes:
    body = json.dumps(payload).encode("utf-8")
    head = (
        f"HTTP/1.1 {status} {reason}\r\n"
        "Content-Type: application/json\r\n"
        f"Content-Length: {len(body)}\r\n"
        "Connection: close\r\n"
        "\r\n"
    ).encode("ascii")
    return head + body


async def handle_webhook_client(
    reader: asyncio.StreamReader,
    writer: asyncio.StreamWriter,
    cfg: WatchdogConfig,
    engine: WatchdogEngine,
) -> None:
    try:
        raw_head = await asyncio.wait_for(reader.readuntil(b"\r\n\r\n"), timeout=10.0)
        lines = raw_head.decode("latin-1").split("\r\n")
        parts = lines[0].split(" ")
        if len(parts) < 2:
            writer.write(_http_json_response(400, "Bad Request", {"ok": False, "error": "bad request"}))
            await writer.drain()
            return
        method = parts[0].upper()
        path = _normalize_webhook_path(parts[1])

        headers: dict[str, str] = {}
        for line in lines[1:]:
            if ":" in line:
                k, v = line.split(":", 1)
                headers[k.strip().lower()] = v.strip()

        content_len = int(headers.get("content-length", "0") or "0")
        if 0 < content_len <= 65536:
            await asyncio.wait_for(reader.readexactly(content_len), timeout=5.0)

        if method == "GET" and path == "/health":
            writer.write(_http_json_response(200, "OK", engine.status_payload()))
            await writer.drain()
            return

        if path not in ("/arm", "/disarm", "/toggle"):
            writer.write(_http_json_response(404, "Not Found", {"ok": False, "error": "not found"}))
            await writer.drain()
            return

        if method != "POST":
            writer.write(
                _http_json_response(405, "Method Not Allowed", {"ok": False, "error": "method not allowed"})
            )
            await writer.drain()
            return

        auth = headers.get("authorization", "")
        scheme, _, token = auth.partition(" ")
        if scheme.lower() != "bearer" or not hmac.compare_digest(token, cfg.webhook_token):
            writer.write(
                _http_json_response(401, "Unauthorized", {"ok": False, "error": "unauthorized"})
            )
            await writer.drain()
            return

        if path == "/arm":
            res = await engine.arm("webhook")
        elif path == "/disarm":
            res = await engine.disarm("webhook")
        else:
            res = await engine.toggle("webhook")
        writer.write(_http_json_response(200, "OK", res))
        await writer.drain()
    except Exception as exc:
        log.debug("Webhook request error: %s", exc)
        try:
            writer.write(
                _http_json_response(500, "Internal Server Error", {"ok": False, "error": str(exc)})
            )
            await writer.drain()
        except Exception:
            pass
    finally:
        writer.close()
        try:
            await writer.wait_closed()
        except Exception:
            pass


async def run_daemon() -> None:
    cfg = WatchdogConfig.from_env()
    traccar = TraccarClient(cfg)
    telegram = TelegramBot(cfg)
    engine = WatchdogEngine(cfg, traccar, telegram)
    stop_event = asyncio.Event()

    loop = asyncio.get_running_loop()
    for sig in (signal.SIGINT, signal.SIGTERM):
        loop.add_signal_handler(sig, stop_event.set)

    server = await asyncio.start_server(
        lambda r, w: handle_webhook_client(r, w, cfg, engine),
        host=cfg.webhook_host,
        port=cfg.webhook_port,
    )
    log.info("Webhook server listening on http://%s:%d", cfg.webhook_host, cfg.webhook_port)

    tasks = [
        asyncio.create_task(traccar_ws_loop(traccar, engine, stop_event), name="traccar-ws"),
        asyncio.create_task(telegram_poll_loop(telegram, engine, stop_event), name="telegram-poll"),
        asyncio.create_task(engine.signal_loss_loop(stop_event), name="signal-loss"),
    ]

    try:
        await stop_event.wait()
    finally:
        for task in tasks:
            task.cancel()
        await asyncio.gather(*tasks, return_exceptions=True)
        server.close()
        await server.wait_closed()


def main() -> int:
    try:
        asyncio.run(run_daemon())
        return 0
    except KeyboardInterrupt:
        return 0
    except Exception as exc:
        log.critical("Fatal startup error: %s", exc)
        return 1


if __name__ == "__main__":
    sys.exit(main())
