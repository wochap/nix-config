"use strict";

const http = require("node:http");
const { chromium } = require("patchright");

const HOST = process.env.HOST || "127.0.1.1";
const PORT = Number.parseInt(process.env.PORT || "20902", 10);
const UPSTREAM_URL = process.env.UPSTREAM_URL || "http://127.0.1.1:20912";
const PROFILE_DIR = process.env.PROFILE_DIR || "/var/lib/firecrawl/browser-profile";
const CHROME_EXECUTABLE = process.env.CHROME_EXECUTABLE || undefined;
const MAX_CONCURRENT_PAGES = Math.max(1, Number.parseInt(process.env.MAX_CONCURRENT_PAGES || "4", 10) || 4);

const FALLBACK_STATUS_CODES = new Set([403, 429, 503]);

class Semaphore {
  constructor(permits) {
    this.permits = permits;
    this.queue = [];
  }

  async acquire() {
    if (this.permits > 0) {
      this.permits -= 1;
      return;
    }
    await new Promise((resolve) => this.queue.push(resolve));
  }

  release() {
    const next = this.queue.shift();
    if (next) {
      next();
    } else {
      this.permits += 1;
    }
  }
}

const pageSemaphore = new Semaphore(MAX_CONCURRENT_PAGES);
let contextPromise = null;

async function getContext() {
  if (!contextPromise) {
    contextPromise = chromium
      .launchPersistentContext(PROFILE_DIR, {
        channel: "chrome",
        ...(CHROME_EXECUTABLE ? { executablePath: CHROME_EXECUTABLE } : {}),
        headless: true,
        viewport: { width: 1280, height: 800 },
        ignoreHTTPSErrors: true,
        args: [
          "--no-sandbox",
          "--disable-setuid-sandbox",
          "--disable-dev-shm-usage",
          "--disable-gpu",
        ],
      })
      .then((ctx) => {
        ctx.on("close", () => {
          contextPromise = null;
        });
        return ctx;
      })
      .catch((err) => {
        contextPromise = null;
        throw err;
      });
  }
  return contextPromise;
}

function isValidHttpUrl(urlString) {
  try {
    const parsed = new URL(urlString);
    return parsed.protocol === "http:" || parsed.protocol === "https:";
  } catch {
    return false;
  }
}

function shouldFallback(upstreamStatus, payload) {
  if (upstreamStatus >= 500 || !payload || typeof payload !== "object") {
    return true;
  }
  const code = payload.pageStatusCode;
  if (!code || FALLBACK_STATUS_CODES.has(code)) {
    return true;
  }
  if (payload.pageError && code !== 404 && code !== 410) {
    return true;
  }
  return false;
}

async function scrapeWithUpstream(body) {
  const timeoutMs = (Number(body.timeout) || 15000) + (Number(body.wait_after_load) || 0) + 10000;
  const response = await fetch(`${UPSTREAM_URL}/scrape`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(body),
    signal: AbortSignal.timeout(timeoutMs),
  });
  const payload = await response.json();
  return { status: response.status, payload };
}

async function scrapeWithProfile({ url, wait_after_load = 0, timeout = 15000, headers }) {
  await pageSemaphore.acquire();
  try {
    const context = await getContext();
    const page = await context.newPage();
    try {
      if (headers && typeof headers === "object" && Object.keys(headers).length > 0) {
        await page.setExtraHTTPHeaders(headers);
      }

      const response = await page.goto(url, { waitUntil: "load", timeout });
      if (wait_after_load > 0) {
        await page.waitForTimeout(wait_after_load);
      }

      let content = await page.content();
      let contentType;
      if (response) {
        const allHeaders = await response.allHeaders();
        const ctEntry = Object.entries(allHeaders).find(([k]) => k.toLowerCase() === "content-type");
        contentType = ctEntry ? ctEntry[1] : undefined;
        if (
          contentType &&
          (contentType.toLowerCase().includes("application/json") ||
            contentType.toLowerCase().includes("text/plain"))
        ) {
          content = (await response.body()).toString("utf8");
        }
      }

      return {
        content,
        pageStatusCode: response ? response.status() : 200,
        ...(contentType ? { contentType } : {}),
      };
    } finally {
      await page.close().catch(() => {});
    }
  } finally {
    pageSemaphore.release();
  }
}

function readJsonBody(req) {
  return new Promise((resolve, reject) => {
    const chunks = [];
    req.on("data", (chunk) => chunks.push(chunk));
    req.on("end", () => {
      try {
        resolve(JSON.parse(Buffer.concat(chunks).toString("utf8") || "{}"));
      } catch (err) {
        reject(err);
      }
    });
    req.on("error", reject);
  });
}

function sendJson(res, statusCode, body) {
  const data = JSON.stringify(body);
  res.writeHead(statusCode, {
    "Content-Type": "application/json",
    "Content-Length": Buffer.byteLength(data),
  });
  res.end(data);
}

const server = http.createServer(async (req, res) => {
  if (req.method === "GET" && req.url === "/health") {
    try {
      const upstream = await fetch(`${UPSTREAM_URL}/health`, {
        signal: AbortSignal.timeout(5000),
      });
      const upstreamBody = await upstream.json().catch(() => ({}));
      return sendJson(res, upstream.ok ? 200 : 503, {
        status: upstream.ok ? "healthy" : "unhealthy",
        upstream: upstreamBody,
        fallbackProfile: PROFILE_DIR,
      });
    } catch (err) {
      return sendJson(res, 503, {
        status: "unhealthy",
        error: err instanceof Error ? err.message : String(err),
      });
    }
  }

  if (req.method === "POST" && req.url === "/scrape") {
    let body;
    try {
      body = await readJsonBody(req);
    } catch {
      return sendJson(res, 400, { error: "Invalid JSON body" });
    }

    if (!body.url) {
      return sendJson(res, 400, { error: "URL is required" });
    }
    if (!isValidHttpUrl(body.url)) {
      return sendJson(res, 400, { error: "Invalid URL" });
    }

    try {
      const { status, payload } = await scrapeWithUpstream(body);
      if (!shouldFallback(status, payload)) {
        return sendJson(res, status, payload);
      }
      console.warn(
        `Upstream playwright returned status=${status} pageStatusCode=${payload?.pageStatusCode}; falling back to persistent profile for ${body.url}`
      );
    } catch (err) {
      console.warn(
        `Upstream playwright failed (${err instanceof Error ? err.message : String(err)}); falling back to persistent profile for ${body.url}`
      );
    }

    try {
      const fallbackResult = await scrapeWithProfile(body);
      return sendJson(res, 200, fallbackResult);
    } catch (err) {
      console.error(`Fallback profile scrape failed for ${body.url}:`, err);
      return sendJson(res, 200, {
        content: "",
        pageStatusCode: 500,
        pageError: err instanceof Error ? err.message : String(err),
      });
    }
  }

  return sendJson(res, 404, { error: "Not found" });
});

async function shutdown() {
  server.close();
  if (contextPromise) {
    try {
      const ctx = await contextPromise;
      await ctx.close();
    } catch {
      // ignore close errors during shutdown
    }
  }
  process.exit(0);
}

process.on("SIGTERM", shutdown);
process.on("SIGINT", shutdown);

server.listen(PORT, HOST, () => {
  console.log(
    `Firecrawl playwright fallback proxy listening on http://${HOST}:${PORT} (upstream=${UPSTREAM_URL}, profile=${PROFILE_DIR})`
  );
});
