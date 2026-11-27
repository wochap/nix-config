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

BOT_COMMANDS: tuple[tuple[str, str, str], ...] = (
    ("start", "[device|all]", "Show status & controls for default or named device"),
    ("status", "[device|all]", "Alias for /start"),
    ("devices", "", "Show status for all registered devices"),
    ("arm", "[device]", "Arm watchdog & set parked anchor"),
    ("disarm", "[device]", "Disarm watchdog & pause alerts"),
    ("default", "[device]", "Show or set the default device"),
    ("help", "", "Show available commands"),
)


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


class DeviceNotFoundError(LookupError):
    """Raised when a requested Traccar device cannot be found."""


@dataclass(frozen=True)
class WatchdogConfig:
    traccar_url: str
    traccar_email: str
    traccar_password: str
    traccar_default_device: str
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
    alert_on_ignition: bool
    signal_loss_seconds: float
    alert_cooldown_seconds: float
    toggle_debounce_seconds: float
    signal_check_interval_seconds: float
    computed_attributes_file: Path | None

    @classmethod
    def from_env(cls) -> "WatchdogConfig":
        state_dir = os.environ.get("STATE_DIRECTORY", "/var/lib/traccar-watchdog")
        default_state = str(Path(state_dir) / "state.json")
        default_dev = (
            os.environ.get("TRACCAR_DEFAULT_DEVICE")
            or os.environ.get("TRACCAR_DEVICE_UNIQUE_ID", "")
        ).strip()
        return cls(
            traccar_url=os.environ.get("TRACCAR_URL", "http://127.0.0.1:8082").rstrip("/"),
            traccar_email=_require_env("TRACCAR_EMAIL"),
            traccar_password=_require_env("TRACCAR_PASSWORD"),
            traccar_default_device=default_dev,
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
            alert_on_ignition=_parse_bool(
                os.environ.get("ALERT_ON_IGNITION"), default=True
            ),
            signal_loss_seconds=float(os.environ.get("SIGNAL_LOSS_SECONDS", "120")),
            alert_cooldown_seconds=float(
                os.environ.get("ALERT_COOLDOWN_SECONDS", "300")
            ),
            toggle_debounce_seconds=max(
                0.0, float(os.environ.get("TOGGLE_DEBOUNCE_SECONDS", "3"))
            ),
            signal_check_interval_seconds=float(
                os.environ.get("SIGNAL_CHECK_INTERVAL_SECONDS", "1.0")
            ),
            computed_attributes_file=(
                Path(raw_ca)
                if (raw_ca := os.environ.get("TRACCAR_COMPUTED_ATTRIBUTES_FILE", "").strip())
                else None
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
class DeviceState:
    device_id: int
    device_name: str = ""
    unique_id: str = ""
    armed: bool = False
    anchor_lat: float | None = None
    anchor_lon: float | None = None
    armed_at: float | None = None
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
    def from_dict(cls, device_id: int, raw: dict[str, Any]) -> "DeviceState":
        known = {f.name for f in cls.__dataclass_fields__.values()}
        filtered = {k: v for k, v in raw.items() if k in known}
        filtered["device_id"] = int(device_id)
        if not isinstance(filtered.get("last_alert_at"), dict):
            filtered["last_alert_at"] = {}
        return cls(**filtered)


@dataclass
class WatchdogState:
    default_device_id: int | None = None
    devices: dict[str, DeviceState] = field(default_factory=dict)

    @classmethod
    def load(cls, path: Path) -> "WatchdogState":
        if not path.exists():
            return cls()
        try:
            raw = json.loads(path.read_text(encoding="utf-8"))
        except (OSError, json.JSONDecodeError) as exc:
            log.warning("Failed to load %s (%s); starting with fresh state", path, exc)
            return cls()
        if not isinstance(raw, dict):
            return cls()

        if isinstance(raw.get("devices"), dict):
            devices: dict[str, DeviceState] = {}
            for key, item in raw["devices"].items():
                if not isinstance(item, dict):
                    continue
                try:
                    dev_id = int(item.get("device_id", key))
                except (TypeError, ValueError):
                    continue
                devices[str(dev_id)] = DeviceState.from_dict(dev_id, item)
            raw_default = raw.get("default_device_id")
            default_id = int(raw_default) if isinstance(raw_default, int) else None
            return cls(default_device_id=default_id, devices=devices)

        if isinstance(raw.get("device_id"), int):
            dev_id = int(raw["device_id"])
            return cls(
                default_device_id=dev_id,
                devices={str(dev_id): DeviceState.from_dict(dev_id, raw)},
            )
        return cls()

    def save(self, path: Path) -> None:
        path.parent.mkdir(parents=True, exist_ok=True)
        tmp = path.with_name(f".{path.name}.{os.getpid()}.tmp")
        serializable = {
            "default_device_id": self.default_device_id,
            "devices": {k: asdict(v) for k, v in self.devices.items()},
        }
        payload = json.dumps(serializable, indent=2, sort_keys=True) + "\n"
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

    async def _authed_json(self, method: str, path: str, payload: dict[str, Any]) -> Any:
        body = json.dumps(payload).encode("utf-8")
        headers = {"Content-Type": "application/json"}
        try:
            _, data = await self._http(method, path, body=body, headers=headers)
            return data
        except TraccarAuthError:
            await self.login()
            _, data = await self._http(method, path, body=body, headers=headers)
            return data

    async def fetch_devices(self) -> list[dict[str, Any]]:
        data = await self._authed_get("/api/devices")
        return data if isinstance(data, list) else []

    async def fetch_positions(self) -> list[dict[str, Any]]:
        data = await self._authed_get("/api/positions")
        return data if isinstance(data, list) else []

    async def fetch_computed_attributes(
        self, device_id: int | None = None
    ) -> list[dict[str, Any]]:
        path = (
            f"/api/attributes/computed?deviceId={device_id}"
            if device_id is not None
            else "/api/attributes/computed?all=true"
        )
        data = await self._authed_get(path)
        return data if isinstance(data, list) else []

    async def create_computed_attribute(self, payload: dict[str, Any]) -> dict[str, Any]:
        data = await self._authed_json("POST", "/api/attributes/computed", payload)
        return data if isinstance(data, dict) else {}

    async def update_computed_attribute(
        self, attr_id: int, payload: dict[str, Any]
    ) -> dict[str, Any]:
        body = dict(payload, id=attr_id)
        data = await self._authed_json("PUT", f"/api/attributes/computed/{attr_id}", body)
        return data if isinstance(data, dict) else {}

    async def link_device_attribute(self, device_id: int, attribute_id: int) -> None:
        await self._authed_json(
            "POST",
            "/api/permissions",
            {"deviceId": device_id, "attributeId": attribute_id},
        )

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

    async def set_my_commands(self, commands: list[dict[str, str]]) -> None:
        if not self.enabled:
            return
        try:
            await self.call("setMyCommands", {"commands": commands})
        except Exception as exc:
            log.debug("Failed to register Telegram bot commands: %s", exc)


class WatchdogEngine:
    """Multi-device Stationary Watchdog state machine, alert evaluator, and command handler."""

    def __init__(
        self, cfg: WatchdogConfig, traccar: TraccarClient, telegram: TelegramBot
    ) -> None:
        self.cfg = cfg
        self.traccar = traccar
        self.telegram = telegram
        self.state = WatchdogState.load(cfg.state_file)
        self._state_lock = asyncio.Lock()
        self._ignition_tasks: dict[int, asyncio.Task[None]] = {}
        self._last_toggle_at: dict[int, float] = {}
        self._computed_specs = self._load_computed_specs(cfg.computed_attributes_file)
        self._reconciled_attrs: dict[str, int] = {}
        self._reconciled_links: set[tuple[int, int]] = set()

    @staticmethod
    def _load_computed_specs(path: Path | None) -> list[dict[str, Any]]:
        if path is None:
            return []
        try:
            raw = json.loads(path.read_text(encoding="utf-8"))
        except (OSError, json.JSONDecodeError) as exc:
            log.error("Failed to load computed attributes file %s: %s", path, exc)
            return []
        return [item for item in raw if isinstance(item, dict)] if isinstance(raw, list) else []

    @staticmethod
    def _device_label(dev: DeviceState | None) -> str:
        if dev is None:
            return "Device"
        return html.escape(dev.device_name or dev.unique_id or f"Device {dev.device_id}")

    @staticmethod
    def _plain_device_name(dev: DeviceState) -> str:
        return dev.device_name or dev.unique_id or f"Device {dev.device_id}"

    @staticmethod
    def _format_pin(lat: float | None, lon: float | None) -> str:
        if lat is None or lon is None:
            return "Unavailable"
        url = maps_url(lat, lon)
        return f'<a href="{url}">{lat:.6f}, {lon:.6f}</a>'

    @staticmethod
    def _anchor_dict(dev: DeviceState | None) -> dict[str, float] | None:
        if dev and dev.anchor_lat is not None and dev.anchor_lon is not None:
            return {"lat": dev.anchor_lat, "lon": dev.anchor_lon}
        return None

    def _device_status_dict(self, dev: DeviceState) -> dict[str, Any]:
        return {
            "armed": dev.armed,
            "anchor": self._anchor_dict(dev),
            "device_id": dev.device_id,
            "device_name": dev.device_name,
            "unique_id": dev.unique_id,
            "device_status": dev.device_status,
        }

    def _ordered_devices_locked(
        self, primary_device_id: int | None = None
    ) -> list[DeviceState]:
        lead_id = (
            primary_device_id
            if primary_device_id is not None
            else self.state.default_device_id
        )
        devices = sorted(self.state.devices.values(), key=lambda d: d.device_id)
        if lead_id is None:
            return devices
        lead = [d for d in devices if d.device_id == lead_id]
        rest = [d for d in devices if d.device_id != lead_id]
        return lead + rest

    def _device_toggle_button(self, dev: DeviceState) -> dict[str, str]:
        name = self._plain_device_name(dev)
        if dev.armed:
            return {
                "text": f"🔓 Disarm {name}",
                "callback_data": f"watchdog:disarm:{dev.device_id}",
            }
        return {
            "text": f"🛡️ Arm {name}",
            "callback_data": f"watchdog:arm:{dev.device_id}",
        }

    def toggle_keyboard(self, primary_device_id: int | None = None) -> dict[str, Any]:
        devices = self._ordered_devices_locked(primary_device_id)
        rows = [[self._device_toggle_button(d)] for d in devices]
        return {"inline_keyboard": rows}

    def alert_keyboard(self, device_id: int) -> dict[str, Any]:
        dev = self.state.devices.get(str(device_id))
        toggle_btn = (
            self._device_toggle_button(dev)
            if dev is not None
            else {"text": "🔓 Disarm Watchdog", "callback_data": f"watchdog:disarm:{device_id}"}
        )
        return {
            "inline_keyboard": [
                [
                    {"text": "✂️ Cut Gas", "callback_data": f"gas:cut_prompt:{device_id}"},
                    {"text": "✅ Restore Gas", "callback_data": f"gas:restore:{device_id}"},
                ],
                [toggle_btn],
            ]
        }

    def confirm_cut_keyboard(self, device_id: int) -> dict[str, Any]:
        dev = self.state.devices.get(str(device_id))
        toggle_btn = (
            self._device_toggle_button(dev)
            if dev is not None
            else {"text": "🔓 Disarm Watchdog", "callback_data": f"watchdog:disarm:{device_id}"}
        )
        return {
            "inline_keyboard": [
                [
                    {
                        "text": "⚠️ CONFIRM Cut Gas (RELAY,1#)",
                        "callback_data": f"gas:cut_confirm:{device_id}",
                    },
                    {"text": "↩️ Cancel", "callback_data": f"gas:cut_cancel:{device_id}"},
                ],
                [toggle_btn],
            ]
        }

    def _match_device_locked(self, query: str) -> DeviceState | None:
        q = query.strip()
        if not q:
            return None
        if q in self.state.devices:
            return self.state.devices[q]
        q_low = q.lower()
        ordered = sorted(self.state.devices.values(), key=lambda d: d.device_id)
        for dev in ordered:
            if dev.device_name.lower() == q_low or dev.unique_id.lower() == q_low:
                return dev
        for dev in ordered:
            if q_low in dev.device_name.lower() or q_low in dev.unique_id.lower():
                return dev
        return None

    def _resolve_default_device_locked(self) -> DeviceState | None:
        if self.state.default_device_id is not None:
            existing = self.state.devices.get(str(self.state.default_device_id))
            if existing is not None:
                return existing
        if self.cfg.traccar_default_device:
            matched = self._match_device_locked(self.cfg.traccar_default_device)
            if matched is not None:
                self.state.default_device_id = matched.device_id
                return matched
        ordered = sorted(self.state.devices.values(), key=lambda d: d.device_id)
        if ordered:
            self.state.default_device_id = ordered[0].device_id
            return ordered[0]
        return None

    def _find_device_locked(self, query: str | None) -> DeviceState | None:
        if query is None or not query.strip():
            return self._resolve_default_device_locked()
        return self._match_device_locked(query)

    def _save_state(self) -> None:
        self.state.save(self.cfg.state_file)

    def _cancel_ignition_timer(self, device_id: int) -> None:
        task = self._ignition_tasks.pop(device_id, None)
        if task and not task.done():
            task.cancel()

    def _upsert_device_locked(
        self, raw_dev: dict[str, Any], now: float, from_ws: bool = False
    ) -> DeviceState:
        dev_id = int(raw_dev["id"])
        key = str(dev_id)
        dev = self.state.devices.get(key)
        if dev is None:
            dev = DeviceState(device_id=dev_id)
            self.state.devices[key] = dev

        dev.unique_id = str(raw_dev.get("uniqueId") or dev.unique_id or "")
        dev.device_name = str(raw_dev.get("name") or dev.unique_id or dev_id)
        status = raw_dev.get("status")
        dev.device_status = str(status) if status is not None else None
        if from_ws:
            dev.last_packet_at = now
        if dev.device_status in ("offline", "unknown"):
            if dev.status_lost_at is None:
                dev.status_lost_at = now
        else:
            dev.status_lost_at = None
        return dev

    async def _reconcile_computed_attributes(self, devices: list[dict[str, Any]]) -> None:
        if not self._computed_specs:
            return

        need_attr_sync = any(
            str(s.get("description", "")) not in self._reconciled_attrs
            for s in self._computed_specs
        )
        if need_attr_sync:
            existing = await self.traccar.fetch_computed_attributes()
            by_desc = {
                str(a.get("description", "")): a for a in existing if a.get("id") is not None
            }
            for spec in self._computed_specs:
                desc = str(spec["description"])
                payload = {
                    "description": desc,
                    "attribute": str(spec["attribute"]),
                    "expression": str(spec["expression"]),
                    "type": str(spec.get("type", "boolean")),
                    "priority": int(spec.get("priority", 0)),
                }
                cur = by_desc.get(desc)
                if cur is None:
                    created = await self.traccar.create_computed_attribute(payload)
                    attr_id = int(created["id"])
                    log.info("Created Traccar computed attribute %r (id=%d)", desc, attr_id)
                else:
                    attr_id = int(cur["id"])
                    changed = any(
                        cur.get(k) != payload[k]
                        for k in ("attribute", "expression", "type", "priority")
                    )
                    if changed:
                        await self.traccar.update_computed_attribute(attr_id, payload)
                        log.info("Updated Traccar computed attribute %r (id=%d)", desc, attr_id)
                self._reconciled_attrs[desc] = attr_id

        device_attr_cache: dict[int, set[int]] = {}
        for spec in self._computed_specs:
            desc = str(spec["description"])
            attr_id = self._reconciled_attrs.get(desc)
            if attr_id is None:
                continue
            filters = [str(f).strip().lower() for f in spec.get("devices", []) if str(f).strip()]
            for raw_dev in devices:
                if raw_dev.get("id") is None:
                    continue
                dev_id = int(raw_dev["id"])
                if filters:
                    dev_name = str(raw_dev.get("name") or "").strip().lower()
                    dev_uid = str(raw_dev.get("uniqueId") or "").strip().lower()
                    if dev_name not in filters and dev_uid not in filters:
                        continue
                if (dev_id, attr_id) in self._reconciled_links:
                    continue
                if dev_id not in device_attr_cache:
                    dev_attrs = await self.traccar.fetch_computed_attributes(device_id=dev_id)
                    device_attr_cache[dev_id] = {
                        int(a["id"]) for a in dev_attrs if a.get("id") is not None
                    }
                if attr_id not in device_attr_cache[dev_id]:
                    await self.traccar.link_device_attribute(dev_id, attr_id)
                    device_attr_cache[dev_id].add(attr_id)
                    log.info(
                        "Linked computed attribute %r (id=%d) to device %s (id=%d)",
                        desc,
                        attr_id,
                        raw_dev.get("name") or raw_dev.get("uniqueId") or dev_id,
                        dev_id,
                    )
                self._reconciled_links.add((dev_id, attr_id))

    async def sync_from_traccar(self) -> None:
        devices = await self.traccar.fetch_devices()
        positions = await self.traccar.fetch_positions()

        if self._computed_specs:
            try:
                await self._reconcile_computed_attributes(devices)
            except Exception as exc:
                log.warning("Computed attribute reconciliation failed: %s", exc)

        latest_pos_by_id: dict[int, dict[str, Any]] = {}
        for pos in positions:
            dev_id = pos.get("deviceId")
            if dev_id is not None:
                latest_pos_by_id[int(dev_id)] = pos

        async with self._state_lock:
            now = time.time()
            for raw_dev in devices:
                if raw_dev.get("id") is None:
                    continue
                dev = self._upsert_device_locked(raw_dev, now=now, from_ws=False)
                pos = latest_pos_by_id.get(dev.device_id)
                if pos is not None:
                    self._apply_position_locked(dev, pos, now=now, from_sync=True)
            self._resolve_default_device_locked()
            self._save_state()

    def _apply_position_locked(
        self, dev: DeviceState, pos: dict[str, Any], now: float, from_sync: bool = False
    ) -> dict[str, Any]:
        lat = pos.get("latitude")
        lon = pos.get("longitude")
        valid = pos.get("valid")
        attrs = pos.get("attributes") if isinstance(pos.get("attributes"), dict) else {}
        ignition = attrs.get("ignition")

        if not from_sync or dev.last_packet_at is None:
            dev.last_packet_at = now

        has_coords = lat is not None and lon is not None and not (
            float(lat) == 0.0 and float(lon) == 0.0 and valid is False
        )
        if valid is True and lat is not None and lon is not None:
            dev.last_lat = float(lat)
            dev.last_lon = float(lon)
            dev.last_valid = True
            dev.last_valid_at = now
            if dev.armed and dev.anchor_lat is None:
                dev.anchor_lat = dev.last_lat
                dev.anchor_lon = dev.last_lon
        elif valid is False:
            dev.last_valid = False
        elif has_coords and dev.last_lat is None:
            dev.last_lat = float(lat)
            dev.last_lon = float(lon)

        if "ignition" in attrs and ignition is not None:
            dev.last_ignition = bool(ignition)

        return {
            "valid": valid,
            "lat": float(lat) if lat is not None else None,
            "lon": float(lon) if lon is not None else None,
            "ignition": bool(ignition) if "ignition" in attrs and ignition is not None else None,
        }

    def _can_fire_alert_locked(self, dev: DeviceState, key: str, now: float) -> bool:
        last = dev.last_alert_at.get(key)
        if last is not None and (now - last) < self.cfg.alert_cooldown_seconds:
            return False
        dev.last_alert_at[key] = now
        return True

    async def _send_alert(
        self,
        dev_id: int,
        dev_label: str,
        title: str,
        details: str,
        lat: float | None,
        lon: float | None,
    ) -> None:
        pin = self._format_pin(lat, lon)
        text = (
            f"🚨 <b>WATCHDOG ALERT: {html.escape(title)}</b>\n"
            f"Device: <b>{dev_label}</b>\n"
            f"{details}\n"
            f"Location: {pin}"
        )
        await self.telegram.send_message(text, reply_markup=self.alert_keyboard(dev_id))

    async def _ignition_grace_worker(self, device_id: int) -> None:
        try:
            await asyncio.sleep(self.cfg.ignition_grace_seconds)
            async with self._state_lock:
                dev = self.state.devices.get(str(device_id))
                if dev is None or not dev.armed or dev.last_ignition is not True:
                    return
                now = time.time()
                if not self._can_fire_alert_locked(dev, "ignition", now):
                    return
                lat, lon = dev.last_lat, dev.last_lon
                if lat is None or lon is None:
                    lat, lon = dev.anchor_lat, dev.anchor_lon
                dev_label = self._device_label(dev)
                self._save_state()

            await self._send_alert(
                device_id,
                dev_label,
                "Ignition ON",
                f"Ignition remained ON past {int(self.cfg.ignition_grace_seconds)}s grace period.",
                lat,
                lon,
            )
        except asyncio.CancelledError:
            log.info("Pending ignition alert cancelled for device %d (watchdog disarmed)", device_id)
            raise

    async def _resolve_device_for_action(
        self,
        device_query: str | None = None,
        device_id: int | None = None,
        sync: bool = False,
    ) -> DeviceState:
        if sync or not self.state.devices:
            try:
                await self.sync_from_traccar()
            except Exception as exc:
                log.warning("Traccar sync failed (%s); using cached state", exc)

        async with self._state_lock:
            dev = (
                self.state.devices.get(str(device_id))
                if device_id is not None
                else self._find_device_locked(device_query)
            )
            if dev is None:
                target_desc = device_query or (str(device_id) if device_id is not None else "default")
                raise DeviceNotFoundError(f"Traccar device not found: {target_desc}")
            return dev

    async def arm(
        self,
        source: str,
        device_query: str | None = None,
        device_id: int | None = None,
    ) -> dict[str, Any]:
        await self._resolve_device_for_action(
            device_query=device_query, device_id=device_id, sync=True
        )

        async with self._state_lock:
            dev = (
                self.state.devices.get(str(device_id))
                if device_id is not None
                else self._find_device_locked(device_query)
            )
            if dev is None:
                raise DeviceNotFoundError(f"Traccar device not found: {device_query or device_id}")
            now = time.time()
            self._cancel_ignition_timer(dev.device_id)
            dev.armed = True
            dev.armed_at = now
            dev.in_signal_loss_alert = False
            dev.last_alert_at = {}
            if dev.last_lat is not None and dev.last_lon is not None:
                dev.anchor_lat = dev.last_lat
                dev.anchor_lon = dev.last_lon
            else:
                dev.anchor_lat = None
                dev.anchor_lon = None
            if dev.device_status in ("offline", "unknown"):
                dev.status_lost_at = now
            self._save_state()
            anchor_lat, anchor_lon = dev.anchor_lat, dev.anchor_lon
            dev_label = self._device_label(dev)
            dev_id = dev.device_id

        pin = self._format_pin(anchor_lat, anchor_lon)
        msg = (
            f"🛡️ <b>Watchdog ARMED</b> ({html.escape(source)})\n"
            f"Device: <b>{dev_label}</b>\n"
            f"Parked Anchor: {pin}"
        )
        await self.telegram.send_message(msg, reply_markup=self.toggle_keyboard(dev_id))
        return self.status_payload(device_id=dev_id)

    async def disarm(
        self,
        source: str,
        device_query: str | None = None,
        device_id: int | None = None,
    ) -> dict[str, Any]:
        await self._resolve_device_for_action(
            device_query=device_query, device_id=device_id, sync=False
        )

        async with self._state_lock:
            dev = (
                self.state.devices.get(str(device_id))
                if device_id is not None
                else self._find_device_locked(device_query)
            )
            if dev is None:
                raise DeviceNotFoundError(f"Traccar device not found: {device_query or device_id}")
            self._cancel_ignition_timer(dev.device_id)
            dev.armed = False
            dev.in_signal_loss_alert = False
            dev.last_alert_at = {}
            self._save_state()
            dev_label = self._device_label(dev)
            dev_id = dev.device_id

        msg = (
            f"🔓 <b>Watchdog DISARMED</b> ({html.escape(source)})\n"
            f"Device: <b>{dev_label}</b>"
        )
        await self.telegram.send_message(msg, reply_markup=self.toggle_keyboard(dev_id))
        return self.status_payload(device_id=dev_id)

    async def toggle(
        self,
        source: str,
        device_query: str | None = None,
        device_id: int | None = None,
    ) -> dict[str, Any]:
        dev = await self._resolve_device_for_action(
            device_query=device_query, device_id=device_id, sync=False
        )
        async with self._state_lock:
            debounce = self.cfg.toggle_debounce_seconds
            if debounce > 0.0:
                now_mono = time.monotonic()
                last = self._last_toggle_at.get(dev.device_id)
                if last is not None and (now_mono - last) < debounce:
                    log.info(
                        "Debounced duplicate toggle for device %d (%.2fs < %.2fs)",
                        dev.device_id,
                        now_mono - last,
                        debounce,
                    )
                    payload = self.status_payload(device_id=dev.device_id)
                    payload["debounced"] = True
                    return payload
                self._last_toggle_at[dev.device_id] = now_mono
            currently_armed = dev.armed
            target_id = dev.device_id
        if currently_armed:
            return await self.disarm(source, device_id=target_id)
        return await self.arm(source, device_id=target_id)

    def status_payload(
        self, device_id: int | None = None, device_query: str | None = None
    ) -> dict[str, Any]:
        if device_id is not None:
            target = self.state.devices.get(str(device_id))
            if target is None:
                raise DeviceNotFoundError(f"Traccar device not found: {device_id}")
        elif device_query is not None and device_query.strip():
            target = self._match_device_locked(device_query)
            if target is None:
                raise DeviceNotFoundError(f"Traccar device not found: {device_query}")
        else:
            target = self._resolve_default_device_locked()

        return {
            "ok": True,
            "armed": target.armed if target else False,
            "anchor": self._anchor_dict(target),
            "device_id": target.device_id if target else None,
            "device_name": target.device_name if target else None,
            "device_status": target.device_status if target else None,
            "default_device_id": self.state.default_device_id,
            "devices": {
                k: self._device_status_dict(d)
                for k, d in sorted(self.state.devices.items(), key=lambda item: int(item[0]))
            },
        }

    def device_status_text(self, dev: DeviceState, show_default_badge: bool = False) -> str:
        badge = "🛡️ <b>ARMED</b>" if dev.armed else "🔓 <b>DISARMED</b>"
        is_default = self.state.default_device_id == dev.device_id
        default_tag = " ⭐ default" if (show_default_badge and is_default) else ""
        lines = [
            f"Status: {badge}",
            f"Device: <b>{self._device_label(dev)}</b> ({html.escape(dev.device_status or 'unknown')}){default_tag}",
            f"Last Position: {self._format_pin(dev.last_lat, dev.last_lon)}",
        ]
        if dev.armed:
            lines.append(
                f"Parked Anchor: {self._format_pin(dev.anchor_lat, dev.anchor_lon)}"
            )
            if (
                dev.anchor_lat is not None
                and dev.anchor_lon is not None
                and dev.last_lat is not None
                and dev.last_lon is not None
            ):
                dist = haversine_meters(
                    dev.anchor_lat,
                    dev.anchor_lon,
                    dev.last_lat,
                    dev.last_lon,
                )
                lines.append(f"Drift from Anchor: <b>{dist:.1f} m</b>")
        return "\n".join(lines)

    def _available_devices_summary(self) -> str:
        devices = self._ordered_devices_locked()
        if not devices:
            return "None registered in Traccar yet."
        parts = []
        for dev in devices:
            icon = "🛡️" if dev.armed else "🔓"
            star = " ⭐" if self.state.default_device_id == dev.device_id else ""
            parts.append(f"{icon} <b>{self._device_label(dev)}</b>{star}")
        return ", ".join(parts)

    async def send_status(self, device_query: str | None = None) -> None:
        try:
            await self.sync_from_traccar()
        except Exception as exc:
            log.warning("Status sync failed (%s); showing cached state", exc)

        async with self._state_lock:
            devices = self._ordered_devices_locked()
            if not devices:
                text = "No Traccar devices registered yet. Add a device in Traccar and run /start again."
                markup = None
            elif device_query and device_query.strip().lower() == "all":
                blocks = [
                    self.device_status_text(d, show_default_badge=len(devices) > 1)
                    for d in devices
                ]
                text = "\n\n".join(blocks)
                markup = self.toggle_keyboard()
            elif device_query and device_query.strip():
                dev = self._find_device_locked(device_query)
                if dev is None:
                    text = (
                        f"⚠️ Device <b>{html.escape(device_query.strip())}</b> not found.\n"
                        f"Available devices: {self._available_devices_summary()}"
                    )
                    markup = self.toggle_keyboard()
                else:
                    text = self.device_status_text(dev, show_default_badge=len(devices) > 1)
                    markup = self.toggle_keyboard(dev.device_id)
            else:
                dev = self._resolve_default_device_locked()
                assert dev is not None
                text = self.device_status_text(dev, show_default_badge=len(devices) > 1)
                if len(devices) > 1:
                    others = [d for d in devices if d.device_id != dev.device_id]
                    other_str = ", ".join(
                        f"{'🛡️' if d.armed else '🔓'} <b>{self._device_label(d)}</b>"
                        for d in others
                    )
                    text += (
                        f"\n\nOther devices: {other_str}\n"
                        "Commands: <code>/start &lt;device&gt;</code>, <code>/devices</code>, "
                        "<code>/default &lt;device&gt;</code>"
                    )
                markup = self.toggle_keyboard(dev.device_id)

        await self.telegram.send_message(text, reply_markup=markup)

    async def set_default_device(self, device_query: str | None) -> None:
        try:
            await self.sync_from_traccar()
        except Exception as exc:
            log.warning("Pre-/default sync failed (%s); using cached devices", exc)

        async with self._state_lock:
            if not device_query or not device_query.strip():
                cur = self._resolve_default_device_locked()
                cur_str = self._device_label(cur) if cur else "None"
                text = (
                    f"Current default device: <b>{cur_str}</b>\n"
                    f"Available devices: {self._available_devices_summary()}\n"
                    "Usage: <code>/default &lt;device name&gt;</code>"
                )
                markup = self.toggle_keyboard(cur.device_id if cur else None)
            else:
                dev = self._match_device_locked(device_query)
                if dev is None:
                    text = (
                        f"⚠️ Device <b>{html.escape(device_query.strip())}</b> not found.\n"
                        f"Available devices: {self._available_devices_summary()}"
                    )
                    markup = self.toggle_keyboard()
                else:
                    self.state.default_device_id = dev.device_id
                    self._save_state()
                    text = f"⭐ Default device set to <b>{self._device_label(dev)}</b>"
                    markup = self.toggle_keyboard(dev.device_id)

        await self.telegram.send_message(text, reply_markup=markup)

    async def handle_ws_message(self, payload: dict[str, Any]) -> None:
        devices = payload.get("devices")
        if isinstance(devices, list):
            for dev in devices:
                await self._on_device(dev)

        positions = payload.get("positions")
        if isinstance(positions, list):
            for pos in positions:
                await self._on_position(pos)

    async def _on_device(self, raw_dev: dict[str, Any]) -> None:
        if raw_dev.get("id") is None:
            return
        restored: tuple[int, str, float | None, float | None] | None = None
        async with self._state_lock:
            now = time.time()
            dev = self._upsert_device_locked(raw_dev, now=now, from_ws=True)
            if self.state.default_device_id is None:
                self._resolve_default_device_locked()
            if (
                dev.armed
                and dev.in_signal_loss_alert
                and dev.device_status not in ("offline", "unknown")
                and dev.last_valid is not False
            ):
                dev.in_signal_loss_alert = False
                restored = (dev.device_id, self._device_label(dev), dev.last_lat, dev.last_lon)
            self._save_state()

        if restored is not None:
            dev_id, dev_label, lat, lon = restored
            await self.telegram.send_message(
                f"📡 <b>Signal Restored</b>\nDevice: <b>{dev_label}</b>\n"
                f"Location: {self._format_pin(lat, lon)}",
                reply_markup=self.toggle_keyboard(dev_id),
            )

    async def _on_position(self, pos: dict[str, Any]) -> None:
        raw_id = pos.get("deviceId")
        if raw_id is None:
            return
        dev_id = int(raw_id)
        movement_alert: tuple[int, str, float, float, float] | None = None
        restored: tuple[int, str, float | None, float | None] | None = None

        async with self._state_lock:
            key = str(dev_id)
            dev = self.state.devices.get(key)
            if dev is None:
                dev = DeviceState(device_id=dev_id, device_name=f"Device {dev_id}")
                self.state.devices[key] = dev

            now = time.time()
            info = self._apply_position_locked(dev, pos, now=now, from_sync=False)

            if dev.armed:
                if (
                    info["valid"] is True
                    and dev.anchor_lat is not None
                    and dev.anchor_lon is not None
                    and dev.last_lat is not None
                    and dev.last_lon is not None
                ):
                    dist = haversine_meters(
                        dev.anchor_lat,
                        dev.anchor_lon,
                        dev.last_lat,
                        dev.last_lon,
                    )
                    if dist > self.cfg.movement_threshold_meters and self._can_fire_alert_locked(
                        dev, "movement", now
                    ):
                        movement_alert = (
                            dev_id,
                            self._device_label(dev),
                            dist,
                            dev.last_lat,
                            dev.last_lon,
                        )

                if self.cfg.alert_on_ignition:
                    if info["ignition"] is True:
                        last_ign = dev.last_alert_at.get("ignition")
                        in_cooldown = (
                            last_ign is not None
                            and (now - last_ign) < self.cfg.alert_cooldown_seconds
                        )
                        existing_task = self._ignition_tasks.get(dev_id)
                        if not in_cooldown and (existing_task is None or existing_task.done()):
                            self._ignition_tasks[dev_id] = asyncio.create_task(
                                self._ignition_grace_worker(dev_id)
                            )
                    elif info["ignition"] is False:
                        self._cancel_ignition_timer(dev_id)

                if (
                    dev.in_signal_loss_alert
                    and info["valid"] is True
                    and dev.device_status not in ("offline", "unknown")
                ):
                    dev.in_signal_loss_alert = False
                    restored = (dev_id, self._device_label(dev), dev.last_lat, dev.last_lon)

            self._save_state()

        if movement_alert is not None:
            dev_id, dev_label, dist, lat, lon = movement_alert
            await self._send_alert(
                dev_id,
                dev_label,
                "Movement Detected",
                f"Moved <b>{dist:.1f} m</b> from parked anchor (limit: {self.cfg.movement_threshold_meters:.0f} m).",
                lat,
                lon,
            )

        if restored is not None:
            dev_id, dev_label, lat, lon = restored
            await self.telegram.send_message(
                f"📡 <b>Signal Restored</b>\nDevice: <b>{dev_label}</b>\n"
                f"Location: {self._format_pin(lat, lon)}",
                reply_markup=self.toggle_keyboard(dev_id),
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

            pending_alerts: list[tuple[int, str, str, float | None, float | None]] = []

            async with self._state_lock:
                now = time.time()
                timeout = self.cfg.signal_loss_seconds
                dirty = False

                for dev in self.state.devices.values():
                    if not dev.armed:
                        continue
                    reason: str | None = None
                    armed_at = dev.armed_at or now

                    if dev.device_status in ("offline", "unknown"):
                        since = max(dev.status_lost_at or armed_at, armed_at)
                        elapsed = now - since
                        if elapsed > timeout:
                            reason = (
                                f"Device status is <b>{html.escape(dev.device_status)}</b> "
                                f"for {int(elapsed)}s."
                            )

                    if reason is None:
                        last_pkt = max(dev.last_packet_at or 0.0, armed_at)
                        pkt_elapsed = now - last_pkt
                        if pkt_elapsed > timeout:
                            reason = f"No tracker packet received for {int(pkt_elapsed)}s."

                    if reason is None and dev.last_valid is False:
                        since_valid = max(dev.last_valid_at or 0.0, armed_at)
                        invalid_elapsed = now - since_valid
                        if invalid_elapsed > timeout:
                            reason = f"Invalid GPS fix persisted for {int(invalid_elapsed)}s."

                    if reason is not None:
                        dev.in_signal_loss_alert = True
                        dirty = True
                        if self._can_fire_alert_locked(dev, "signal_loss", now):
                            lat = dev.last_lat or dev.anchor_lat
                            lon = dev.last_lon or dev.anchor_lon
                            pending_alerts.append(
                                (dev.device_id, self._device_label(dev), reason, lat, lon)
                            )

                if dirty:
                    self._save_state()

            for dev_id, dev_label, reason, lat, lon in pending_alerts:
                await self._send_alert(dev_id, dev_label, "GPS / Signal Loss", reason, lat, lon)

    async def execute_gas_command(self, cut: bool, device_id: int | None = None) -> tuple[DeviceState, str]:
        dev = await self._resolve_device_for_action(device_id=device_id, sync=False)
        cmd = "RELAY,1#" if cut else "RELAY,0#"
        await self.traccar.send_command(dev.device_id, cmd)
        return dev, cmd

    @staticmethod
    def _parse_callback_data(data: str) -> tuple[str, int | None]:
        parts = data.split(":", 2)
        if len(parts) == 3 and parts[2].isdigit():
            return f"{parts[0]}:{parts[1]}", int(parts[2])
        if len(parts) >= 2:
            return f"{parts[0]}:{parts[1]}", None
        return data, None

    async def _send_device_not_found(self, query: str | None) -> None:
        async with self._state_lock:
            avail = self._available_devices_summary()
            markup = self.toggle_keyboard()
        await self.telegram.send_message(
            f"⚠️ Device <b>{html.escape((query or '').strip())}</b> not found.\n"
            f"Available devices: {avail}",
            reply_markup=markup,
        )

    async def send_help(self) -> None:
        lines = ["📖 <b>Watchdog Commands</b>", ""]
        for name, arg_spec, desc in BOT_COMMANDS:
            usage = f"/{name} {arg_spec}" if arg_spec else f"/{name}"
            lines.append(f"• <code>{html.escape(usage)}</code> — {html.escape(desc)}")
        await self.telegram.send_message("\n".join(lines))

    async def handle_telegram_update(self, update: dict[str, Any]) -> None:
        expected_chat = str(self.cfg.telegram_chat_id)

        if "message" in update and isinstance(update["message"], dict):
            msg = update["message"]
            chat_id = str(msg.get("chat", {}).get("id", ""))
            if chat_id != expected_chat:
                log.warning("Ignoring Telegram message from unauthorized chat_id=%s", chat_id)
                return
            text = str(msg.get("text", "")).strip()
            parts = text.split(maxsplit=1)
            cmd = parts[0].split("@")[0].lower() if parts else ""
            arg = parts[1].strip() if len(parts) > 1 else None

            if cmd in ("/start", "/status"):
                await self.send_status(arg)
            elif cmd == "/devices":
                await self.send_status("all")
            elif cmd == "/default":
                await self.set_default_device(arg)
            elif cmd == "/arm":
                try:
                    await self.arm("telegram", device_query=arg)
                except DeviceNotFoundError:
                    await self._send_device_not_found(arg)
            elif cmd == "/disarm":
                try:
                    await self.disarm("telegram", device_query=arg)
                except DeviceNotFoundError:
                    await self._send_device_not_found(arg)
            elif cmd == "/help":
                await self.send_help()
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

            action, target_id = self._parse_callback_data(str(cb.get("data", "")))
            message_id = msg.get("message_id")
            if target_id is None:
                async with self._state_lock:
                    default_dev = self._resolve_default_device_locked()
                    target_id = default_dev.device_id if default_dev else None

            if action == "watchdog:arm":
                await self.telegram.answer_callback(cb_id, "Arming watchdog...")
                try:
                    await self.arm("telegram", device_id=target_id)
                except DeviceNotFoundError:
                    await self._send_device_not_found(str(target_id or ""))
            elif action == "watchdog:disarm":
                await self.telegram.answer_callback(cb_id, "Disarming watchdog...")
                try:
                    await self.disarm("telegram", device_id=target_id)
                except DeviceNotFoundError:
                    await self._send_device_not_found(str(target_id or ""))
            elif action == "watchdog:toggle":
                await self.telegram.answer_callback(cb_id, "Toggling watchdog...")
                try:
                    await self.toggle("telegram", device_id=target_id)
                except DeviceNotFoundError:
                    await self._send_device_not_found(str(target_id or ""))
            elif action == "gas:cut_prompt" and target_id is not None:
                await self.telegram.answer_callback(
                    cb_id, "Tap CONFIRM to send RELAY,1#", show_alert=False
                )
                if message_id is not None:
                    await self.telegram.edit_reply_markup(
                        chat_id, int(message_id), self.confirm_cut_keyboard(target_id)
                    )
            elif action == "gas:cut_cancel" and target_id is not None:
                await self.telegram.answer_callback(cb_id, "Cancelled")
                if message_id is not None:
                    await self.telegram.edit_reply_markup(
                        chat_id, int(message_id), self.alert_keyboard(target_id)
                    )
            elif action == "gas:cut_confirm" and target_id is not None:
                try:
                    dev, cmd = await self.execute_gas_command(cut=True, device_id=target_id)
                    await self.telegram.answer_callback(cb_id, f"Sent {cmd}")
                    if message_id is not None:
                        await self.telegram.edit_reply_markup(
                            chat_id, int(message_id), self.alert_keyboard(dev.device_id)
                        )
                    await self.telegram.send_message(
                        f"✂️ <b>Fuel Cut Command Dispatched</b> (<code>{cmd}</code>)\n"
                        f"Device: <b>{self._device_label(dev)}</b>",
                        reply_markup=self.alert_keyboard(dev.device_id),
                    )
                except Exception as exc:
                    log.error("Failed to send RELAY,1#: %s", exc)
                    await self.telegram.answer_callback(cb_id, f"Error: {exc}", show_alert=True)
            elif action == "gas:restore" and target_id is not None:
                try:
                    dev, cmd = await self.execute_gas_command(cut=False, device_id=target_id)
                    await self.telegram.answer_callback(cb_id, f"Sent {cmd}")
                    await self.telegram.send_message(
                        f"✅ <b>Fuel Restore Command Dispatched</b> (<code>{cmd}</code>)\n"
                        f"Device: <b>{self._device_label(dev)}</b>",
                        reply_markup=self.toggle_keyboard(dev.device_id),
                    )
                except Exception as exc:
                    log.error("Failed to send RELAY,0#: %s", exc)
                    await self.telegram.answer_callback(cb_id, f"Error: {exc}", show_alert=True)
            else:
                await self.telegram.answer_callback(cb_id, "No target device selected", show_alert=True)


async def telegram_poll_loop(
    bot: TelegramBot, engine: WatchdogEngine, stop_event: asyncio.Event
) -> None:
    if not bot.enabled:
        await stop_event.wait()
        return

    await bot.set_my_commands(
        [{"command": name, "description": desc} for name, _, desc in BOT_COMMANDS]
    )

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


def _normalize_webhook_target(raw_target: str) -> tuple[str, str | None]:
    parsed = urllib.parse.urlsplit(raw_target)
    path = parsed.path or "/"
    if path == "/watchdog":
        path = "/"
    elif path.startswith("/watchdog/"):
        path = path[len("/watchdog") :]
    if len(path) > 1:
        path = path.rstrip("/")
    qs = urllib.parse.parse_qs(parsed.query)
    device_query = qs.get("device", [None])[0]
    return path, device_query


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
        path, device_query = _normalize_webhook_target(parts[1])

        headers: dict[str, str] = {}
        for line in lines[1:]:
            if ":" in line:
                k, v = line.split(":", 1)
                headers[k.strip().lower()] = v.strip()

        content_len = int(headers.get("content-length", "0") or "0")
        if 0 < content_len <= 65536:
            await asyncio.wait_for(reader.readexactly(content_len), timeout=5.0)

        if method == "GET" and path == "/health":
            try:
                payload = engine.status_payload(device_query=device_query)
                writer.write(_http_json_response(200, "OK", payload))
            except DeviceNotFoundError as exc:
                writer.write(_http_json_response(404, "Not Found", {"ok": False, "error": str(exc)}))
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

        try:
            if path == "/arm":
                res = await engine.arm("webhook", device_query=device_query)
            elif path == "/disarm":
                res = await engine.disarm("webhook", device_query=device_query)
            else:
                res = await engine.toggle("webhook", device_query=device_query)
            writer.write(_http_json_response(200, "OK", res))
        except DeviceNotFoundError as exc:
            writer.write(_http_json_response(404, "Not Found", {"ok": False, "error": str(exc)}))
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
