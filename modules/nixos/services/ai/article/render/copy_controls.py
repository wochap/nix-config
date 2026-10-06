#!/usr/bin/env python3
"""Safely embed Markdown and its clipboard controls in a rendered page.

The button goes after the page's `a.original` link when there is one,
otherwise at the top of the body.
"""

import html
import sys


html_path, markdown_path = sys.argv[1:]
with open(html_path, encoding="utf-8") as source:
    document = source.read()
with open(markdown_path, encoding="utf-8") as source:
    markdown = source.read()

controls = f"""
<button class="copy-summary" id="copy-summary" type="button" aria-keyshortcuts="y" hidden>Copy Markdown</button>
<span class="copy-status" id="copy-status" role="status" aria-live="polite"></span>
<textarea id="summary-markdown" hidden>{html.escape(markdown)}</textarea>
<script>
(() => {{
  const markdown = document.querySelector('#summary-markdown').value;
  const button = document.querySelector('#copy-summary');
  const status = document.querySelector('#copy-status');
  const original = document.querySelector('a.original');
  let clear;

  if (original) {{
    original.insertAdjacentElement('afterend', button);
  }} else {{
    document.body.prepend(button);
  }}
  button.insertAdjacentElement('afterend', status);
  button.hidden = false;

  async function copyMarkdown() {{
    try {{
      await navigator.clipboard.writeText(markdown);
      status.textContent = 'Copied';
    }} catch {{
      status.textContent = 'Copy failed';
    }}
    clearTimeout(clear);
    clear = setTimeout(() => (status.textContent = ''), 2000);
  }}

  button.addEventListener('click', copyMarkdown);
  document.addEventListener('keydown', event => {{
    if (event.key !== 'y' || event.ctrlKey || event.altKey || event.metaKey || event.repeat) return;
    if (event.target.closest?.('input, textarea, select, [contenteditable]')) return;
    event.preventDefault();
    copyMarkdown();
  }});
}})();
</script>
"""

if "</body>" not in document:
    raise SystemExit("rendered HTML has no closing body tag")
document = document.replace("</body>", controls + "\n</body>", 1)
with open(html_path, "w", encoding="utf-8") as destination:
    destination.write(document)
