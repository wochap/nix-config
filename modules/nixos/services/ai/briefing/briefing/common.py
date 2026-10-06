"""Shared helpers for briefing stages: JSONL io, item schema, HTTP and LLM calls."""

import hashlib
import html
import json
import os
import re
import subprocess
import sys
import time
import urllib.parse
import urllib.request
from datetime import datetime, timedelta, timezone

USER_AGENT = "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:149.0) Gecko/20100101 Firefox/149.0"
TRACKING_PARAMS = re.compile(r"^(utm_|fbclid$|gclid$|mc_|ref$|ref_src$|cmpid$|smid$)")

# Fields every item must carry after collection. Adapters may add more.
ITEM_FIELDS = ("id", "source", "section", "feed", "title", "url", "canonical_url", "published", "snippet")


def log(stage, message):
    print(f"[{stage}] {message}", file=sys.stderr, flush=True)


def die(stage, message, code=1):
    log(stage, f"error: {message}")
    sys.exit(code)


# --- io -------------------------------------------------------------------


def read_jsonl(path):
    if not path or not os.path.exists(path):
        return []
    with open(path, encoding="utf-8") as handle:
        return [json.loads(line) for line in handle if line.strip()]


def write_jsonl(path, rows):
    tmp = f"{path}.tmp"
    with open(tmp, "w", encoding="utf-8") as handle:
        for row in rows:
            handle.write(json.dumps(row, ensure_ascii=False) + "\n")
    os.replace(tmp, path)


def read_json(path, default=None):
    if not path or not os.path.exists(path):
        return default
    with open(path, encoding="utf-8") as handle:
        return json.load(handle)


def write_json(path, data):
    tmp = f"{path}.tmp"
    with open(tmp, "w", encoding="utf-8") as handle:
        json.dump(data, handle, ensure_ascii=False, indent=2)
        handle.write("\n")
    os.replace(tmp, path)


# --- time -----------------------------------------------------------------


def now_utc():
    return datetime.now(timezone.utc)


def parse_duration(text):
    """Parse '24h', '7d', '90m' into a timedelta."""
    match = re.fullmatch(r"\s*(\d+)\s*([mhdw])\s*", str(text))
    if not match:
        raise ValueError(f"bad duration: {text!r} (use e.g. 24h, 7d)")
    amount, unit = int(match.group(1)), match.group(2)
    return {"m": timedelta(minutes=amount), "h": timedelta(hours=amount), "d": timedelta(days=amount), "w": timedelta(weeks=amount)}[unit]


def iso(dt):
    return dt.astimezone(timezone.utc).replace(microsecond=0).isoformat().replace("+00:00", "Z")


def parse_iso(text):
    if not text:
        return None
    try:
        return datetime.fromisoformat(str(text).replace("Z", "+00:00"))
    except ValueError:
        return None


# --- items ----------------------------------------------------------------


def canonical_url(url):
    if not url:
        return ""
    parts = urllib.parse.urlsplit(url.strip())
    host = parts.netloc.lower()
    if host.startswith("www."):
        host = host[4:]
    query = urllib.parse.urlencode(
        [(k, v) for k, v in urllib.parse.parse_qsl(parts.query, keep_blank_values=True) if not TRACKING_PARAMS.match(k.lower())]
    )
    path = parts.path.rstrip("/") or "/"
    return urllib.parse.urlunsplit(("https" if parts.scheme in ("http", "https") else parts.scheme, host, path, query, ""))


def title_key(title):
    words = re.findall(r"[a-z0-9]+", (title or "").lower())
    return " ".join(words[:16])


def sha(text):
    return hashlib.sha256(text.encode("utf-8")).hexdigest()[:16]


def strip_html(text):
    text = re.sub(r"(?is)<(script|style).*?</\1>", " ", text or "")
    text = re.sub(r"<[^>]+>", " ", text)
    return re.sub(r"\s+", " ", html.unescape(text)).strip()


def make_item(source, *, title, url="", section="", feed="", published=None, snippet="", **extra):
    """Normalize an item to the common schema. `published` may be datetime or ISO text."""
    if isinstance(published, datetime):
        published = iso(published)
    canon = canonical_url(url)
    item = {
        "id": sha(canon or title_key(title) or title),
        "source": source,
        "section": section or "",
        "feed": feed or "",
        "title": strip_html(title)[:300],
        "url": url or "",
        "canonical_url": canon,
        "published": published or "",
        "snippet": strip_html(snippet)[:1200],
    }
    item.update(extra)
    return item


def validate_item(item):
    missing = [field for field in ("title",) if not item.get(field)]
    if missing:
        raise ValueError(f"item missing {missing}: {json.dumps(item)[:200]}")


# --- http -----------------------------------------------------------------


def http_get(url, *, params=None, headers=None, timeout=30, retries=2):
    if params:
        url = f"{url}{'&' if '?' in url else '?'}{urllib.parse.urlencode(params)}"
    request = urllib.request.Request(url, headers={"User-Agent": USER_AGENT, **(headers or {})})
    last_error = None
    for attempt in range(retries + 1):
        try:
            with urllib.request.urlopen(request, timeout=timeout) as response:
                return response.read()
        except Exception as error:  # noqa: BLE001 - network errors are varied
            last_error = error
            if attempt < retries:
                throttled = getattr(error, "code", None) == 429
                time.sleep((5 if throttled else 1) * (attempt + 1) ** 2)
    raise RuntimeError(f"GET {url.split('?')[0]} failed: {last_error}")


def http_json(url, **kwargs):
    return json.loads(http_get(url, **kwargs))


# --- llm ------------------------------------------------------------------


def llm(messages, *, model=None, temperature=0.4, max_tokens=None, retries=2, stage="llm"):
    """Chat completion through `omniroute-chat` (OpenAI-compatible, key handling included)."""
    request = {"messages": messages, "temperature": temperature}
    if max_tokens:
        request["max_tokens"] = max_tokens
    command = [
        "omniroute-chat",
        "--model",
        model or os.environ.get("BRIEFING_MODEL", "desktop-free"),
        "--reasoning-effort",
        os.environ.get("OMNIROUTE_REASONING_EFFORT", "none"),
    ]
    last_error = ""
    for attempt in range(retries + 1):
        result = subprocess.run(command, input=json.dumps(request), capture_output=True, text=True, check=False)
        # Reasoning fallbacks (local qwen3.5) may prepend a <think> block.
        text = re.sub(r"(?s)<think>.*?</think>", "", result.stdout).strip()
        if result.returncode == 0 and text:
            return text
        last_error = result.stderr.strip() or f"exit {result.returncode}"
        log(stage, f"llm attempt {attempt + 1} failed: {last_error}")
        time.sleep(3 + attempt * 5)
    raise RuntimeError(f"llm failed: {last_error}")


def llm_json(messages, **kwargs):
    """Like `llm`, but parses the first JSON value in the reply (tolerates code fences / prose)."""
    stage = kwargs.get("stage", "llm")
    for attempt in range(2):
        text = llm(messages, **kwargs)
        try:
            return extract_json(text)
        except ValueError as error:
            log(stage, f"bad JSON from llm (attempt {attempt + 1}): {error}")
            messages = [*messages, {"role": "assistant", "content": text}, {"role": "user", "content": "That was not valid JSON. Reply with only the JSON value, no prose."}]
    raise RuntimeError("llm returned invalid JSON twice")


def extract_json(text):
    text = re.sub(r"(?s)<think>.*?</think>", "", text).strip()
    fenced = re.search(r"```(?:json)?\s*(.*?)```", text, re.S)
    if fenced:
        text = fenced.group(1).strip()
    starts = [i for i in (text.find("["), text.find("{")) if i >= 0]
    if not starts:
        raise ValueError("no JSON found")
    decoder = json.JSONDecoder()
    value, _ = decoder.raw_decode(text[min(starts):])
    return value


def read_text(path):
    with open(path, encoding="utf-8") as handle:
        return handle.read()
