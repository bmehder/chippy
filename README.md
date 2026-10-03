# Chippy

> A server-side rendered dynamic website with Markdown files instead of a database.

An HTTP request maps to a directory. Chippy reads the current Markdown file,
renders it to HTML, inserts it into an HTML layout, and returns the complete
document. Editing content does not require a database or a content build.

## Run it

```sh
npm install
npm run build:css
gleam run
```

Then open <http://localhost:8000>.

Edit `routes/+page.md`, save it, and refresh the browser to see the change. The
repository is Chippy's demo site as well as its implementation.

## Routes

The root page currently demonstrates the route convention:

```text
routes/
├── +page.md
├── +layout.html
├── about/
│   ├── +page.md
│   └── notes.txt
├── posts/inside-chippy/
│   ├── +page.md
│   └── request-flow.txt
└── _partials/
    ├── footer.html
    └── header.html
```

- `+page.md` contains frontmatter followed by the route's Markdown.
- `+layout.html` is ordinary HTML with a `{{ content }}` insertion point.
- `{{ partial:name }}` inserts `routes/_partials/name.html`.
- Ordinary files inside a route folder are served at the corresponding URL.
  For example, `routes/about/notes.txt` is available at `/about/notes.txt`.
- Files beginning with `+` or `_` are implementation files and are never
  served as static assets.

The included `routes/about/+page.md` maps naturally to `/about`. Nested routes
currently fall back to the root layout and root partials.

## Metadata

Chippy recognizes two required fields and one optional flag:

```markdown
---
title: About
description: Why this page exists.
noindex: false
---
```

The layout receives `{{ title }}`, `{{ description }}`, `{{ robots }}`, and
`{{ content }}`. Set `noindex: true` to add a robots directive and omit the page
from the sitemap. Metadata stays deliberately predefined and small.

## Assets and Tailwind

Site-wide static files live under `assets/` and are served from `/assets/`.
Ordinary files may also live inside a route folder, where their URL follows the
route. Chippy does not transform images or other assets.

Tailwind compiles `styles/site.css` to `assets/site.css`. CSS compilation is
separate from content rendering: changing Markdown never requires a build.

```sh
npm run watch:css
```

## Built-in routes

- `/sitemap.xml` discovers valid `+page.md` files at request time. It uses the
  request host and forwarded protocol/host headers to produce absolute URLs.
- `/favicon.svg` serves `assets/favicon.svg` when the site provides one. If it
  does not, Chippy returns its built-in SVG favicon.

Missing pages and unexpected rendering failures use the site's root layout and
partials, return the correct `404` or `500` status, and are marked `noindex`.

## Learn the codebase

- Read [DEVELOPMENT.md](DEVELOPMENT.md) to set up a development environment.
- Run the site and open `/posts/inside-chippy` for a request-by-request tour.

## Check the project

```sh
npm run check
```

Collections and other capabilities will be added only when the demo site
genuinely needs them.
