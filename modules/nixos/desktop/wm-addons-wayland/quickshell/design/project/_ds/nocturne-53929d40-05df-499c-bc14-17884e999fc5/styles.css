/* Nocturne — design-system tokens and component classes. This file is the source of truth for the system's look; retune it here and see readme.md. */
@import url('https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap');

:root {
  --color-bg: #161826;
  --color-surface: #232532;
  --color-text: #e9e9ed;
  --color-accent: #9184d9; /* review round 7 (Barron): the accent moves to
     the product's blurple — OKLCH hue 289.2, the hue of the app's own Pro
     accent (#9a8fe0, --om-accent-pro) — at the same lightness the steel
     accent held (L 0.660, so the documented ratios survive) and chroma
     in the product blurple's own range (its token sits at C 0.118; the
     accent takes 0.125, from the old steel's 0.030):
     the accent now reads as an accent rather than another neutral. */
  --color-accent-2: #a7a1db; /* the machine-derived stand-in follows: same
     hue, same L 0.734, chroma at the same 2:3 proportion it held */
  --color-divider: color-mix(in srgb, #e9e9ed 16%, transparent);

  /* Tonal ramps — generated in OKLCH on one shared lightness scale, so the
     same step of any role matches the others in visual value. */
  --color-neutral-100: #f3f5fe;
  --color-neutral-200: #e4e7f5;
  --color-neutral-300: #cfd3e5;
  --color-neutral-400: #b2b6ca;
  --color-neutral-500: #9397ab;
  --color-neutral-600: #75798c;
  --color-neutral-700: #595d6c;
  --color-neutral-800: #3f424d;
  --color-neutral-900: #292b31;

  --color-accent-100: #f5f4ff;
  --color-accent-200: #e7e5fe;
  --color-accent-300: #d2cefd;
  --color-accent-400: #b5abfc;
  --color-accent-500: #968ae0;
  --color-accent-600: #796cbf;
  --color-accent-700: #5d5294;
  --color-accent-800: #423a6a;
  --color-accent-900: #2b2741;

  --color-accent-2-100: #f5f4ff;
  --color-accent-2-200: #e7e5fe;
  --color-accent-2-300: #d2cefd;
  --color-accent-2-400: #b5afe8;
  --color-accent-2-500: #9690c9;
  --color-accent-2-600: #7972a9;
  --color-accent-2-700: #5c5783;
  --color-accent-2-800: #423e5d;
  --color-accent-2-900: #2b293a;

  /* Deck section-divider ground — review round 3: saturation as presence.
     Dividers take a saturated deep indigo (hue 277, the neutral ramp's own
     family; C 0.094 — written when the accent held C 0.030, before the
     round-7 blurple raised it past the ground's) with a lighter bloom and
     a ghost tint of the same hue, while the slide grounds stay
     desaturated. Deck-scale fills only — not interface colors. */
  --color-section: #262a60;
  --color-section-glow: #353b80;
  --color-section-ghost: #4c5397;

  --font-heading: "Inter", system-ui, sans-serif;
  --font-heading-weight: 500;
  --font-body: "Inter", system-ui, sans-serif;

  --space-1: 2.8px;
  --space-2: 5.6px;
  --space-3: 8.4px;
  --space-4: 11.2px;
  --space-6: 16.8px;
  --space-8: 22.4px;

  --radius-sm: 4px;
  --radius-md: 8px;
  --radius-lg: 14px;

  /* Elevation — derived from the ground: soft ink-tinted shadows on a
     light theme, a hairline edge + ambient darkness on a dark one. */
  --shadow-sm: 0 0 0 1px #3f424d;
  --shadow-md: 0 0 0 1px #595d6c, 0 6px 18px rgba(0,0,0,0.55);
  --shadow-lg: 0 0 0 1px #9397ab, 0 16px 40px rgba(0,0,0,0.65);
}

body {
  background: var(--color-bg);
  color: var(--color-text);
  font-family: var(--font-body);
}
h1, h2, h3, h4 { font-family: var(--font-heading); font-weight: var(--font-heading-weight); }

.lighten{mix-blend-mode:lighten;background-color:transparent}

/* ══════════════════════════════════════════════════════════════════════════
   Components — built with the tokens above. Plain CSS
   on plain HTML: no JavaScript, no build step. Each class is documented in
   readme.md and demonstrated in foundations/ and components/.
   ══════════════════════════════════════════════════════════════════════ */

*, *::before, *::after { box-sizing: border-box; }
body { margin: 0; font-size: 15px; line-height: 1.55; font-weight: 400; }
h1, h2, h3, h4, h5, h6 {
  font-family: var(--font-heading); font-weight: var(--font-heading-weight);
  line-height: 1.12; letter-spacing: -0.015em; margin: 0 0 var(--space-2);
}
h1 { font-size: 42px; }
h2 { font-size: 32px; }
h3 { font-size: 25px; }
h4 { font-size: 20px; }
h5 { font-size: 16px; }
h6 { font-size: 13px; }
h6 { letter-spacing: 0.08em; text-transform: uppercase; }
p { margin: 0 0 var(--space-3); }
a { color: var(--color-accent); text-underline-offset: 3px; }
img { display: block; max-width: 100%; }
figure { margin: 0; }
figcaption {
  font-size: 11px; margin-top: var(--space-1);
  color: color-mix(in srgb, var(--color-text) 55%, transparent);
}
.text-muted { color: color-mix(in srgb, var(--color-text) 55%, transparent); }
:focus { outline: none; }
:focus-visible { outline: 2px solid var(--color-accent); outline-offset: 2px; }
::selection { background: color-mix(in srgb, var(--color-accent) 30%, transparent); }

/* — rules — */
/* Rules fade to transparent at both ends instead of stopping cleanly — a
   Nocturne signature. The ramp is 48px an end (one deck baseline unit),
   painted from the same divider token. Freestanding rules fade; box
   outlines, in-control separators, and short accent marks stay solid. */
.hr {
  height: 1px; border: 0; margin: var(--space-4) 0;
  background: linear-gradient(to right,
    transparent, var(--color-divider) 48px,
    var(--color-divider) calc(100% - 48px), transparent);
}

/* — buttons — */
.btn {
  display: inline-flex; align-items: center; justify-content: center; gap: 6px;
  cursor: pointer; text-decoration: none;
  font-family: var(--font-heading); font-weight: var(--font-heading-weight);
  font-size: 14px; line-height: 1.2; color: var(--color-text); /* matches the .input's 14px —
     the pair sits side by side in sign-up rows */
  background: transparent; border: 1px solid transparent;
  padding: var(--space-2) calc(var(--space-3) * 1.2);
  border-radius: var(--radius-md);
}
.btn svg { display: block; }
.btn:disabled { opacity: 0.45; cursor: not-allowed; }
.btn-primary { color: var(--color-accent); border-color: var(--color-accent); }
.btn-primary:hover { background: color-mix(in srgb, var(--color-accent) 12%, transparent); }
.btn-primary:active { background: color-mix(in srgb, var(--color-accent) 22%, transparent); }
.btn-secondary { border-color: var(--color-divider); }
.btn-secondary:hover { background: color-mix(in srgb, var(--color-text) 7%, transparent); }
.btn-secondary:active { background: color-mix(in srgb, var(--color-text) 14%, transparent); }
.btn-ghost { color: var(--color-accent); padding-inline: var(--space-1); }
.btn-ghost:hover { background: color-mix(in srgb, var(--color-accent) 10%, transparent); }
.btn-ghost:active { background: color-mix(in srgb, var(--color-accent) 18%, transparent); }
.btn-icon { width: 36px; height: 36px; padding: 0; }
.btn-block { width: 100%; margin-top: var(--space-2); }

/* — forms — */
.field > label {
  display: block; font-size: 12px; margin-bottom: 5px;
  color: color-mix(in srgb, var(--color-text) 70%, transparent);
}
.input {
  width: 100%; min-height: 36px; padding: 6px 10px; font: inherit;
  font-size: 14px; color: var(--color-text); caret-color: var(--color-accent);
  background: var(--color-surface);
  border: 1px solid var(--color-divider); border-radius: var(--radius-md);
}
.input:hover { border-color: color-mix(in srgb, var(--color-text) 45%, transparent); }
.input:focus-visible { border-color: var(--color-accent); outline-offset: 0; }
textarea.input { min-height: 90px; resize: vertical; }
.radio { display: inline-flex; align-items: center; gap: 8px; cursor: pointer; font-size: 14px; }
.radio input, .seg-opt input {
  position: absolute; opacity: 0; width: 0; height: 0; pointer-events: none;
}
.radio .dot {
  width: 16px; height: 16px; flex: none; border-radius: 50%;
  border: 1.5px solid var(--color-divider);
}
.radio:hover .dot { border-color: var(--color-accent); }
.radio input:checked + .dot {
  border-color: var(--color-accent); background: var(--color-accent);
  box-shadow: inset 0 0 0 4px var(--color-bg);
}
.radio input:focus-visible + .dot { outline: 2px solid var(--color-accent); outline-offset: 2px; }
.seg {
  display: inline-flex; overflow: hidden;
  border: 1px solid var(--color-divider); border-radius: var(--radius-md);
}
.seg-opt {
  display: inline-flex; align-items: center; gap: 6px;
  padding: 7px 12px; font-size: 13px; cursor: pointer;
}
.seg-opt + .seg-opt { border-left: 1px solid var(--color-divider); }
.seg-opt:has(input:checked) { color: var(--color-accent); box-shadow: inset 0 0 0 1px var(--color-accent); }
.seg-opt:not(:has(input:checked)):hover { background: color-mix(in srgb, var(--color-text) 7%, transparent); }
.seg-opt:has(input:focus-visible) { outline: 2px solid var(--color-accent); outline-offset: -2px; }

/* — cards — */
.card {
  display: flex; flex-direction: column; gap: var(--space-2);
  padding: var(--space-3); border-radius: var(--radius-md); background: var(--color-surface);
}
.card-kicker { font-size: 10px; letter-spacing: 0.1em; text-transform: uppercase; color: var(--color-accent); }
.card-title {
  font-family: var(--font-heading); font-weight: var(--font-heading-weight);
  font-size: 17px; line-height: 1.2;
}
.card-body { margin: 0; font-size: 13px; opacity: 0.8; flex: 1; }
.card-meta {
  display: flex; align-items: center; gap: 6px; font-size: 11px;
  color: color-mix(in srgb, var(--color-text) 50%, transparent);
}
.elev-sm { box-shadow: var(--shadow-sm); }
.elev-md { box-shadow: var(--shadow-md); }
.elev-lg { box-shadow: var(--shadow-lg); }

/* — tags — */
.tag {
  display: inline-flex; align-items: center; font-size: 11px;
  letter-spacing: 0.02em; padding: 3px 10px;
  border-radius: calc(var(--radius-md) * 0.75);
}
.tag-accent { background: var(--color-accent-800); color: var(--color-accent-100); }
.tag-accent-2 { background: var(--color-accent-2-800); color: var(--color-accent-2-100); }
.tag-neutral { background: var(--color-neutral-800); color: var(--color-neutral-100); }
.tag-outline { border: 1px solid var(--color-accent); color: var(--color-accent); }

/* — navigation — */
.nav {
  display: flex; align-items: center; gap: var(--space-4);
  padding: var(--space-3) var(--space-4);
  border-bottom: none;
}
.nav-brand {
  font-family: var(--font-heading); font-weight: var(--font-heading-weight);
  font-size: 18px; margin-right: auto;
}
.nav a { color: inherit; text-decoration: none; font-size: 14px; }
.nav a:hover, .nav a[aria-current='page'] { color: var(--color-accent); }

/* — tables — */
.table { width: 100%; border-collapse: collapse; font-size: 14px; }
.table th {
  text-align: left; font-size: 11px; letter-spacing: 0.08em; text-transform: uppercase;
  color: color-mix(in srgb, var(--color-text) 60%, transparent);
  padding: var(--space-2); border-bottom: 1px solid transparent; /* keeps layout; the row paints the fading rule */
}
.table td {
  padding: var(--space-2);
  border-bottom: 1px solid transparent;
}
/* Row rules as row-level strips so the end-fade spans the row, not each cell. */
.table thead tr {
  background: linear-gradient(to right,
    transparent, var(--color-divider) 48px,
    var(--color-divider) calc(100% - 48px), transparent) no-repeat bottom / 100% 1px;
}
.table tbody tr {
  background: linear-gradient(to right,
    transparent, color-mix(in srgb, var(--color-text) 8%, transparent) 48px,
    color-mix(in srgb, var(--color-text) 8%, transparent) calc(100% - 48px), transparent) no-repeat bottom / 100% 1px;
}
.table tbody tr:hover {
  /* the hover tint layers over the row rule, which keeps painting */
  background:
    linear-gradient(color-mix(in srgb, var(--color-text) 4%, transparent),
                    color-mix(in srgb, var(--color-text) 4%, transparent)) no-repeat 0 0 / 100% 100%,
    linear-gradient(to right,
      transparent, color-mix(in srgb, var(--color-text) 8%, transparent) 48px,
      color-mix(in srgb, var(--color-text) 8%, transparent) calc(100% - 48px), transparent) no-repeat bottom / 100% 1px;
}

/* — dialog — */
.dialog-backdrop {
  position: fixed; inset: 0; display: grid; place-items: center;
  padding: var(--space-4);
  background: color-mix(in srgb, var(--color-neutral-900) 50%, transparent);
}
.dialog {
  width: min(440px, 100%); display: flex; flex-direction: column; gap: var(--space-3);
  padding: var(--space-4); border-radius: var(--radius-lg);
  background: var(--color-surface); box-shadow: var(--shadow-lg);
}
.dialog-title {
  font-family: var(--font-heading); font-weight: var(--font-heading-weight);
  font-size: 20px;
}
.dialog-body { font-size: 14px; opacity: 0.85; }
.dialog-actions { display: flex; justify-content: flex-end; gap: var(--space-2); margin-top: var(--space-2); }

