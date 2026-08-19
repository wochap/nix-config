#!/usr/bin/env python3
"""Safely embed summary Markdown and its clipboard controls in rendered HTML."""

import html
import sys


html_path, markdown_path = sys.argv[1:]
with open(html_path, encoding="utf-8") as source:
    document = source.read()
with open(markdown_path, encoding="utf-8") as source:
    markdown = source.read()

controls = f"""
<button class="copy-summary" id="copy-summary" type="button" hidden>Copy Markdown</button>
<span class="copy-status" id="copy-status" role="status" aria-live="polite"></span>
<textarea class="summary-markdown" id="summary-markdown" readonly tabindex="-1" aria-hidden="true">{html.escape(markdown)}</textarea>
<script>
(() => {{
  const markdown = document.querySelector('#summary-markdown');
  const button = document.querySelector('#copy-summary');
  const status = document.querySelector('#copy-status');
  const original = document.querySelector('a.original');

  if (original) {{
    original.insertAdjacentElement('afterend', button);
    button.insertAdjacentElement('afterend', status);
    button.hidden = false;
  }}

  async function copyMarkdown() {{
    let method = 'Clipboard API';
    try {{
      await navigator.clipboard.writeText(markdown.value);
    }} catch {{
      method = 'textarea fallback';
      markdown.focus();
      markdown.select();
      if (!document.execCommand('copy')) {{
        status.textContent = 'Copy failed';
        return;
      }}
    }}
    status.textContent = `Copied using ${{method}}`;
    button.focus();
  }}

  button.addEventListener('click', copyMarkdown);
  document.addEventListener('keydown', event => {{
    const target = event.target;
    const editing = target instanceof HTMLInputElement
      || target instanceof HTMLTextAreaElement
      || target instanceof HTMLSelectElement
      || target.isContentEditable;
    if (event.key === 'y' && !event.ctrlKey && !event.altKey
        && !event.metaKey && !event.shiftKey && !editing) {{
      event.preventDefault();
      copyMarkdown();
    }}
  }});
}})();
</script>
"""

if "</body>" not in document:
    raise SystemExit("rendered HTML has no closing body tag")
document = document.replace("</body>", controls + "\n</body>", 1)
with open(html_path, "w", encoding="utf-8") as destination:
    destination.write(document)
