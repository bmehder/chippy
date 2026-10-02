# Chippy

> A tiny server-rendered Markdown website system written in Gleam.

Chippy is for ordinary, content-led websites. An HTTP request maps to a
directory; Chippy reads its Markdown page at request time, renders it to HTML,
inserts it into an HTML layout, and returns the complete document.

There is no database, content build, client-side router, hydration layer, or
JavaScript framework. Markdown is the normal authoring format, and ordinary
HTML remains available whenever a page needs it.

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

Chippy currently recognizes two required fields:

```markdown
---
title: About
description: Why this page exists.
---
```

The layout receives `{{ title }}`, `{{ description }}`, and `{{ content }}`.
Metadata stays deliberately predefined and small.

## Assets and Tailwind

Site-wide static files live under `assets/` and are served from `/assets/`.
Ordinary files may also live inside a route folder, where their URL follows the
route. Chippy does not transform images or other assets.

Tailwind compiles `styles/site.css` to `assets/site.css`. CSS compilation is
separate from content rendering: changing Markdown never requires a build.

```sh
npm run watch:css
```

## Learn the codebase

- Read [DEVELOPMENT.md](DEVELOPMENT.md) to set up a development environment.
- Run the site and open `/posts/inside-chippy` for a request-by-request tour.

## Check the project

```sh
npm run check
```

Sitemap generation and a favicon fallback are planned next. Collections and
other capabilities will be added only when the demo site genuinely needs them.
