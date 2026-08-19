#!/usr/bin/env python3
"""Render a public web page in an isolated browser and save its final DOM."""

import os
import sys
import time

from playwright.sync_api import Error as PlaywrightError
from playwright.sync_api import TimeoutError as PlaywrightTimeoutError
from playwright.sync_api import sync_playwright


RENDER_TIMEOUT_SECONDS = 20
MINIMUM_WAIT_SECONDS = 2
QUIET_PERIOD_MILLISECONDS = 1000


def browser_executable():
    executable = os.environ.get("ARTICLE_SUMMARY_BROWSER") or os.environ.get(
        "ARTICLE_SUMMARY_BROWSER_DEFAULT"
    )
    if not executable:
        raise RuntimeError(
            "no browser configured; set ARTICLE_SUMMARY_BROWSER to an absolute Chrome executable path"
        )
    if not os.path.isabs(executable):
        raise RuntimeError("ARTICLE_SUMMARY_BROWSER must be an absolute path")
    if not os.path.isfile(executable) or not os.access(executable, os.X_OK):
        raise RuntimeError(f"browser is missing or not executable: {executable}")
    return executable


def render(url, destination):
    executable = browser_executable()
    started = time.monotonic()
    deadline = started + RENDER_TIMEOUT_SECONDS

    with sync_playwright() as playwright:
        browser = playwright.chromium.launch(headless=True, executable_path=executable)
        try:
            context = browser.new_context(service_workers="block")
            context.route(
                "**/*",
                lambda route: route.abort()
                if route.request.resource_type in {"font", "image", "media"}
                else route.continue_(),
            )
            page = context.new_page()
            try:
                page.goto(
                    url,
                    wait_until="domcontentloaded",
                    timeout=max(1, int((deadline - time.monotonic()) * 1000)),
                )
            except PlaywrightTimeoutError:
                # A committed page may still contain a usable DOM even when a
                # resource prevents DOMContentLoaded from firing.
                if page.url == "about:blank":
                    raise RuntimeError("browser navigation timed out before loading the page")

            page.evaluate(
                """
                () => {
                  window.__newsboatSummaryLastMutation = performance.now();
                  new MutationObserver(() => {
                    window.__newsboatSummaryLastMutation = performance.now();
                  }).observe(document.documentElement, {
                    attributes: true,
                    characterData: true,
                    childList: true,
                    subtree: true,
                  });
                }
                """
            )
            settling_started = time.monotonic()

            while time.monotonic() < deadline:
                elapsed = time.monotonic() - settling_started
                quiet_for = page.evaluate(
                    "performance.now() - window.__newsboatSummaryLastMutation"
                )
                if (
                    elapsed >= MINIMUM_WAIT_SECONDS
                    and quiet_for >= QUIET_PERIOD_MILLISECONDS
                ):
                    break
                page.wait_for_timeout(200)

            html = page.content()
            final_url = page.url
            context.close()
        finally:
            browser.close()

    with open(destination, "w", encoding="utf-8") as output:
        output.write(html)
    return final_url


def main():
    if len(sys.argv) != 3:
        raise SystemExit("usage: fetch_rendered.py URL HTML_FILE")
    print(render(sys.argv[1], sys.argv[2]), end="")


if __name__ == "__main__":
    try:
        main()
    except (OSError, PlaywrightError, RuntimeError) as error:
        print(str(error), file=sys.stderr)
        raise SystemExit(1)
