#!/usr/bin/env python3
"""Extract an article and its metadata from HTML using Trafilatura's API."""

import json
import sys
from urllib.parse import urljoin

import trafilatura


def value(document, name):
    if isinstance(document, dict):
        return document.get(name)
    return getattr(document, name, None)


def main():
    if len(sys.argv) != 3:
        raise SystemExit("usage: extract.py URL HTML_FILE")
    url, filename = sys.argv[1:]
    with open(filename, "r", encoding="utf-8", errors="replace") as source:
        html = source.read()

    document = trafilatura.bare_extraction(
        html,
        url=url,
        output_format="markdown",
        with_metadata=True,
        include_comments=False,
        include_links=True,
        include_images=False,
        include_tables=True,
        favor_precision=True,
    )
    if document is None:
        raise RuntimeError("Trafilatura did not find article content")

    body = value(document, "text") or value(document, "raw_text") or ""
    body = body.strip()
    if len(body) < 300:
        raise RuntimeError(f"extracted article is too short ({len(body)} characters)")

    lowered = body.lower()
    warning_phrases = (
        "enable javascript to continue",
        "javascript is required",
        "please log in to continue",
        "sign in to continue",
        "accept cookies to continue",
    )
    if len(body) < 1200 and any(phrase in lowered for phrase in warning_phrases):
        raise RuntimeError("page appears to contain only a login, cookie, or JavaScript notice")

    canonical = value(document, "url") or url
    canonical = urljoin(url, canonical)
    image = value(document, "image") or ""
    if image:
        image = urljoin(canonical, image)
        if not image.startswith(("http://", "https://")):
            image = ""

    json.dump(
        {
            "title": value(document, "title") or "Untitled article",
            "author": value(document, "author") or "",
            "date": value(document, "date") or "",
            "canonical_url": canonical,
            "image_url": image,
            "body": body,
        },
        sys.stdout,
        ensure_ascii=False,
    )


if __name__ == "__main__":
    try:
        main()
    except Exception as error:
        print(str(error), file=sys.stderr)
        raise SystemExit(1)
