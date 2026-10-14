"""Clients for the local AI services: embeddings, scorers, SearXNG and Firecrawl.

Endpoints come from the environment (the `briefing` wrapper sets them):
  BRIEFING_EMBED_URL, BRIEFING_EMBED_MODEL      OpenAI-style /embeddings (Ollama)
  BRIEFING_RERANK_URL, BRIEFING_RERANK_MODEL    Cohere/Jina-style /rerank (llama-server)
  BRIEFING_JEV_URL, JEV_API_KEY                 TypeSafe Jev /systemone (calibrated 0-3)
  BRIEFING_SEARXNG_URL                          SearXNG JSON API
  BRIEFING_FIRECRAWL_URL                        Firecrawl /v1
  BRIEFING_SCORER                               jev or rerank (the LLM is the fallback)
"""

import json
import math
import os
import re
import sqlite3
import time
import urllib.error
import urllib.parse
import urllib.request
from concurrent.futures import ThreadPoolExecutor
from datetime import timedelta

import numpy as np

from briefing.common import USER_AGENT, iso, log, now_utc, sha

RETRY_STATUSES = {429, 502, 503, 504}
EMBED_BATCH = 32
EMBED_CHARS = 2000
CACHE_DAYS = 60
# Qwen3-Embedding wants an instruction on the query side only; documents go in raw.
TOPIC_INSTRUCT = "Instruct: Given a news topic description, retrieve news items about that topic\nQuery: "


class ServiceError(RuntimeError):
    pass


def env(name, default=""):
    return os.environ.get(name, default).rstrip("/") if name.endswith("_URL") else os.environ.get(name, default)


def post_json(url, body, *, headers=None, timeout=60, retries=2, method="POST"):
    data = json.dumps(body).encode() if body is not None else None
    request = urllib.request.Request(
        url,
        data=data,
        method=method,
        headers={"User-Agent": USER_AGENT, "Content-Type": "application/json", **(headers or {})},
    )
    last_error = None
    for attempt in range(retries + 1):
        try:
            with urllib.request.urlopen(request, timeout=timeout) as response:
                return json.loads(response.read())
        except urllib.error.HTTPError as error:
            detail = error.read()[:300].decode(errors="replace")
            last_error = f"HTTP {error.code}: {detail}"
            if error.code not in RETRY_STATUSES:
                break
        except Exception as error:  # noqa: BLE001 - network errors are varied
            last_error = str(error)
        if attempt < retries:
            time.sleep(2 * (attempt + 1) ** 2)
    raise ServiceError(f"{method} {url.split('?')[0]} failed: {last_error}")


def get_json(url, params, **kwargs):
    return post_json(f"{url}?{urllib.parse.urlencode(params)}", None, method="GET", **kwargs)


# --- embeddings -------------------------------------------------------------


class Embedder:
    """Normalized embeddings with a SQLite cache, so reruns and later stages reuse vectors."""

    def __init__(self, cache_path=None, *, url=None, model=None):
        self.url = url or env("BRIEFING_EMBED_URL")
        self.model = model or env("BRIEFING_EMBED_MODEL")
        if not self.url:
            raise ServiceError("BRIEFING_EMBED_URL is not set")
        cache_path = cache_path or os.path.join(env("BRIEFING_STATE_DIR", os.path.expanduser("~/.local/state/briefing")), "embeddings.db")
        os.makedirs(os.path.dirname(cache_path), exist_ok=True)
        self.db = sqlite3.connect(cache_path)
        self.db.execute("CREATE TABLE IF NOT EXISTS vectors (key TEXT PRIMARY KEY, vector BLOB, used_at TEXT)")
        # Unused vectors age out; anything still referenced gets its used_at refreshed.
        self.db.execute("DELETE FROM vectors WHERE used_at < ?", (iso(now_utc() - timedelta(days=CACHE_DAYS)),))
        self.db.commit()

    def _key(self, text):
        return sha(f"{self.model}\0{text}")

    def embed(self, texts):
        """Return a (len(texts), dim) float32 matrix of unit vectors."""
        texts = [(t or " ")[:EMBED_CHARS] for t in texts]
        if not texts:
            return np.zeros((0, 0), dtype=np.float32)
        keys = [self._key(t) for t in texts]
        cached = {}
        for start in range(0, len(keys), 500):
            chunk = keys[start : start + 500]
            rows = self.db.execute(f"SELECT key, vector FROM vectors WHERE key IN ({','.join('?' * len(chunk))})", chunk)
            cached.update({key: np.frombuffer(blob, dtype=np.float32) for key, blob in rows})
        missing = list(dict.fromkeys(text for text, key in zip(texts, keys) if key not in cached))
        batches = [missing[i : i + EMBED_BATCH] for i in range(0, len(missing), EMBED_BATCH)]
        with ThreadPoolExecutor(max_workers=2) as pool:
            for batch, vectors in zip(batches, pool.map(self._request, batches)):
                for text, vector in zip(batch, vectors):
                    cached[self._key(text)] = vector
        stamp = iso(now_utc())
        self.db.executemany(
            "INSERT OR REPLACE INTO vectors VALUES (?, ?, ?)", [(key, cached[key].tobytes(), stamp) for key in set(keys)]
        )
        self.db.commit()
        return np.stack([cached[key] for key in keys])

    def _request(self, texts):
        body = {"input": texts}
        if self.model:
            body["model"] = self.model
        # The first call may load the model into VRAM.
        data = post_json(f"{self.url}/embeddings", body, timeout=300)
        items = sorted(data.get("data") or [], key=lambda item: int(item.get("index", 0)))
        if len(items) != len(texts):
            raise ServiceError(f"embeddings: sent {len(texts)} texts, got {len(items)} vectors")
        matrix = np.asarray([item["embedding"] for item in items], dtype=np.float32)
        norms = np.linalg.norm(matrix, axis=1, keepdims=True)
        return list(matrix / np.where(norms == 0, 1, norms))


def item_text(title, snippet=""):
    """The text embedded for an item or a story source; dedup, clustering and corroboration compare these."""
    return f"{title}\n{(snippet or '')[:200]}".strip()


def try_embedder(stage):
    try:
        return Embedder()
    except (ServiceError, sqlite3.Error) as error:
        log(stage, f"embeddings unavailable: {error}")
        return None


# --- scorers ----------------------------------------------------------------

JEV_INSTRUCTIONS = (
    "How much does this news item deserve airtime in a private audio news briefing for this listener?\n\n"
    "Listener interests:\n{interests}"
)
JEV_CRITERIA = [
    "Off-topic for this listener, promotional, a tutorial or a listicle",
    "Related to the interests, but minor, incremental, opinion or a rehash",
    "Relevant and newsworthy for this listener",
    "A major, concrete new development squarely in the interests",
]


def jev_scores(texts, interests, *, concurrency=16):
    """Calibrated 0-3 usefulness from Jev, mapped to 0-1."""
    url, key = env("BRIEFING_JEV_URL"), os.environ.get("JEV_API_KEY", "")
    if not url or not key:
        raise ServiceError("jev: BRIEFING_JEV_URL or JEV_API_KEY is not set")
    instructions = JEV_INSTRUCTIONS.format(interests=interests.strip())

    def one(text):
        body = {
            "state": text,
            "model": "jev-latest",
            "questions": {"relevance": {"type": "score", "instructions": instructions, "criteria": JEV_CRITERIA}},
        }
        data = post_json(f"{url}/systemone", body, headers={"Authorization": f"Bearer {key}"}, timeout=120)
        value = float(data["answers"]["relevance"]["score"])
        if not 0 <= value <= 3:
            raise ServiceError(f"jev: score {value} outside 0-3")
        return value / 3

    with ThreadPoolExecutor(max_workers=concurrency) as pool:
        return list(pool.map(one, texts))


def rerank_scores(texts, query, *, batch=32):
    """Relevance from the local reranker; logits are squashed to 0-1."""
    url, model = env("BRIEFING_RERANK_URL"), env("BRIEFING_RERANK_MODEL")
    if not url:
        raise ServiceError("rerank: BRIEFING_RERANK_URL is not set")
    values = []
    for start in range(0, len(texts), batch):
        documents = texts[start : start + batch]
        body = {"query": query, "documents": documents}
        if model:
            body["model"] = model
        # The lazy proxy starts llama-server on the first request.
        data = post_json(f"{url}/rerank", body, timeout=300)
        results = {int(r["index"]): float(r["relevance_score"]) for r in data.get("results") or data.get("data") or []}
        if set(results) != set(range(len(documents))):
            raise ServiceError(f"rerank: {len(results)} results for {len(documents)} documents")
        values += [results[i] for i in range(len(documents))]
    if any(v < 0 or v > 1 for v in values):
        values = [1 / (1 + math.exp(-v)) for v in values]
    return values


def scorer_name():
    return env("BRIEFING_SCORER", "rerank")


# --- search and fetch -------------------------------------------------------


def searxng_search(query, *, time_range="week", limit=8):
    url = env("BRIEFING_SEARXNG_URL")
    if not url:
        raise ServiceError("BRIEFING_SEARXNG_URL is not set")
    params = {"q": query, "format": "json", "categories": "news", "time_range": time_range}
    data = get_json(f"{url}/search", params, timeout=60)
    return [r for r in data.get("results") or [] if r.get("url")][:limit]


MD_IMAGE = re.compile(r"!\[[^\]]*\]\([^)]*\)")
MD_LINK = re.compile(r"\[([^\]]*)\]\([^)]*\)")


def firecrawl_scrape(url, *, timeout=60):
    """Main-content markdown of a page, with images and link targets stripped."""
    base = env("BRIEFING_FIRECRAWL_URL")
    if not base:
        raise ServiceError("BRIEFING_FIRECRAWL_URL is not set")
    body = {"url": url, "formats": ["markdown"], "onlyMainContent": True, "timeout": timeout * 1000}
    data = post_json(f"{base}/scrape", body, timeout=timeout + 30, retries=1)
    page = data.get("data") or {}
    metadata = page.get("metadata") or {}
    if not data.get("success"):
        raise ServiceError(str(data.get("error") or "success: false"))
    status = metadata.get("statusCode")
    if isinstance(status, int) and status >= 400:
        raise ServiceError(f"page answered HTTP {status}")
    text = MD_LINK.sub(r"\1", MD_IMAGE.sub("", page.get("markdown") or ""))
    # Markdown hard breaks ("\" at line end) and escaped spaces read as noise in a prompt.
    text = re.sub(r"\\(?=\s)", "", text)
    text = re.sub(r"\n{3,}", "\n\n", text).strip()
    return {"body": text, "url": metadata.get("sourceURL") or metadata.get("url") or url, "title": metadata.get("title") or ""}
