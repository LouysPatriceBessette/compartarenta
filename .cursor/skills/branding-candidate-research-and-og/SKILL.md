---
name: branding-candidate-research-and-og
description: >-
  Research a proposed Compartarenta rebrand name and, only when explicitly
  requested, create a matching editable SVG plus 1200x630 French OG image. Use
  when the user proposes a branding option, asks to test another app name,
  requests the same branding methodology, or explicitly requests a visual
  candidate.
---

# Branding candidate research with optional OG image

Use this workflow for each proposed replacement name.

## Inputs and fixed reference

- Candidate name exactly as written by the user.
- Reference image:
  `/home/bvii/repos/online/compartarenta.incoherences.org/site/src/assets/img/og-image-fr.png`
- Output directory:
  `dev-ideas/branding/<candidate-slug>/`

If the candidate spelling and requested directory disagree, ask which spelling
is intentional before creating files. Do not silently correct the name.

## 1. Inspect before creating

1. Determine whether the user explicitly requested an OG image or SVG in the
   current message. A request to “try,” “test,” or research a name does not
   authorize visual generation.
2. Only when a visual was explicitly requested, read the reference PNG and
   inspect previous candidate folders so the new palette and monogram are
   visibly distinct.
3. Obtain the current local timestamp as `YYYY-MM-DD-HH-MM`.
4. Create the candidate output directory only when the user's request
   explicitly authorizes writing under `dev-ideas/`.

## 2. Research the name live

Use current web results; do not rely on prior candidate research.

Search at minimum:

1. Exact quoted name.
2. Spacing, accent, plural, and likely spelling variants.
3. Phonetically close names.
4. Google Play and Apple App Store.
5. The candidate plus `app`, `software`, `company`, `startup`, `trademark`,
   `roommate`, `colocation`, `shared expenses`, and `vehicle sharing`.
6. Root domains and notable country domains when results expose them.

For relevant store listings, fetch the live page and record:

- package/bundle identifier;
- public download bucket on Google Play;
- rating and rating count when exposed;
- last update date;
- developer and country;
- price, ads, subscriptions, or in-app purchases;
- declared languages;
- functional positioning.

Apple does not publish download counts. Say so rather than estimating.
Keep store download buckets separate from company marketing claims such as
“registered users.”

Classify every collision:

- **Direct:** same name and overlapping app function.
- **Adjacent:** same or near name in housing, payments, agreements, sharing, or
  another nearby market.
- **Distant:** same name in an unrelated market.

Give an evidence-based risk verdict. This is brand screening, not trademark
clearance; never claim that a name is legally available.

## 3. Create the visual candidate only on explicit request

Skip this entire section unless the user explicitly asks for an OG image, SVG,
logo, monogram, or visual candidate in the current message. Do not infer visual
authorization from previous candidate runs or from “use the same method.”

Preserve the reference image's:

- 1200×630 dimensions;
- overall left-logo/right-copy composition;
- French tagline exactly:
  `Utilitaire local-first de colocation et de partage de véhicule`;
- text exactly: `Code public sur GitHub`.

Change only:

- candidate name;
- URL to `<candidate-slug>.incoherences.org`;
- logo/monogram;
- palette and decorative colors.

### SVG requirements

- Keep all colors in named CSS classes near the top of the SVG.
- Include comments identifying the palette controls.
- Create a recognizable monogram from useful candidate initials.
- Use one continuous SVG `<path>` for the monogram: exactly one initial `M`
  command and no disconnected subpaths.
- Slightly deform letters to join naturally, with rounded caps and joins.
- Keep the path easy to edit by hand.
- Use a candidate-specific palette that differs from previous options.
- Write valid UTF-8 and validate by rendering it.

Keep a candidate-local `_build_og.py` so the SVG and PNG can be regenerated.
It must derive its output directory from `Path(__file__).resolve().parent`, so
moving the candidate folder does not break it.

Use CairoSVG for deterministic SVG-to-PNG rendering. Reuse an existing local
branding render environment if available; otherwise create a local virtual
environment under the authorized branding workspace and install `cairosvg`.

### Eye-guided SVG micro-adjustments (preferred)

For fine visual placement (homemade glyphs, apostrophes, kerning gaps, icon
offsets, rotation, stroke weight), **do not** spend turns guessing from PNG
descriptions or pixel heuristics alone.

When the user is willing to steer:

1. Ship a reasonable first mark (or a homemade substitute when a font glyph is
   broken — e.g. Allura’s `'` had zero advance and floated badly).
2. Regenerate the PNG quickly.
3. Apply the user’s **eye deltas in chat** as absolute or relative nudges:
   `+Npx` / `−Npx`, clockwise/counterclockwise degrees, “a bit thinner”, etc.
4. Keep the `_build_og.py` (or SVG) constants as the source of truth so each
   nudge is cumulative and reproducible.

**Why:** Guided deltas are much faster and more accurate than autonomous
re-guessing of sub-pixel typography. Prefer asking for / waiting on eye
guidance once the mark exists, instead of over-tuning alone.

Demonstrated (2026-07-18, Bojairũ FR OG): homemade SVG apostrophe for
`l'amitié`, then iterative `translate` / `rotate` / path slim / `amitié` gap
until the user confirmed.

## 4. Required files

Always create the research note:

```text
dev-ideas/branding/<candidate-slug>/
└── YYYY-MM-DD-HH-MM-qui-est-<candidate-slug>.md
```

Only when the user explicitly requested a visual, also create:

```text
dev-ideas/branding/<candidate-slug>/
├── YYYY-MM-DD-HH-MM-og-image-fr.png
├── YYYY-MM-DD-HH-MM-og-image-fr.svg
└── _build_og.py
```

The research note must contain:

1. the quoted user request;
2. the standard personal-note separator and `# Réponse IA`;
3. exact and near-name collisions with links;
4. live store data where available;
5. direct/adjacent/distant classification;
6. a concise risk verdict;
7. the generated file list;
8. a palette and monogram summary only when a visual was requested and created.

## 5. Verify before delivery

When no visual was requested, confirm the research note exists and do not
create, render, or mention an OG image, SVG, palette, monogram, or build script.

When a visual was explicitly requested:

1. Render the PNG at exactly 1200×630.
2. Read the rendered PNG and visually inspect:
   - candidate spelling;
   - unchanged French copy;
   - candidate URL;
   - monogram legibility and continuity;
   - text overflow and contrast;
   - palette distinction from earlier candidates.
3. Confirm all required files exist.
4. If the folder is moved, regenerate once to prove `_build_og.py` still works.

When a visual was requested, do not report completion until the rendered PNG
has been inspected.

## Delivery format

Always lead with the collision-risk verdict and the strongest supporting
evidence, then list the research-note path.

Only when a visual was explicitly requested: show the PNG, list its output
paths, and summarize the palette/monogram.
