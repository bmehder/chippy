# Developing Chippy

This guide is for people changing Chippy itself. For the product overview and
site-authoring conventions, start with [README.md](README.md). For a guided code
tour, run the site and open `/posts/inside-chippy`.

## Requirements

- Gleam 1.18 or newer
- Erlang/OTP 29 or newer
- Node.js and npm for Tailwind CSS

## First setup

```sh
gleam deps download
npm install
npm run build:css
gleam run
```

Open <http://localhost:8000>. Markdown and HTML are read on each request, so
content changes only need a browser refresh.

When changing classes or `styles/site.css`, run this in a second terminal:

```sh
npm run watch:css
```

Tailwind is the only asset build. Images and other files are served unchanged.

## Complete verification

```sh
npm run check
```

This rebuilds the stylesheet, checks Gleam formatting, and runs the test suite.
Run it before committing.

GitHub Actions runs the same check and verifies an Erlang shipment on every
push to `main` and every pull request.

## Architecture

The request path is intentionally short:

```text
Mist request
  → chippy/server.gleam
  → chippy/page.gleam
  → routes/<path>/+page.md
  → Mörk
  → +layout.html and _partials/*.html
  → Mist response
```

- `src/chippy/page.gleam` owns safe path resolution, metadata, Markdown,
  layouts, partials, and static-file resolution.
- `src/chippy/server.gleam` owns HTTP methods, statuses, headers, content types,
  and Mist response bodies.
- `src/chippy.gleam` starts the listener and contains no domain logic.

Keep filesystem and HTTP failures explicit. Prefer extending the current
linear flow over adding generalized framework abstractions.

## Route fixtures

The project website is also the primary fixture:

- `/` demonstrates mixed Markdown and HTML.
- `/about` demonstrates directory routing and a colocated file.
- `/posts/inside-chippy` documents the implementation using the implementation.

Focused tests live in `test/chippy_test.gleam`. They should not require a live
socket.

## Near-term work

- Generate a sitemap from valid route directories.
- Provide a favicon fallback while allowing a site-owned favicon to override it.
- Grow the predefined metadata only when an actual page needs another field.

These are product capabilities, not reasons to introduce a plugin or schema
system.
