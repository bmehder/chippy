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
  → site.toml
  → chippy/page.gleam
  → routes/<path>/+page.md
  → Mörk
  → +layout.html and _partials/*.html
  → Mist response
```

- `src/chippy/page.gleam` owns safe path resolution, metadata, Markdown,
  layouts, partials, route discovery, errors, and static-file resolution.
- `src/chippy/server.gleam` owns HTTP methods, statuses, headers, content types,
  built-in routes, site configuration loading, and Mist response bodies.
- `src/chippy/site.gleam` parses and validates `site.toml`, supplies the default
  language, and builds absolute URLs.
- `src/chippy/sitemap.gleam` turns discovered indexable routes into XML.
- `src/chippy/favicon.gleam` contains the fallback used when a site does not
  provide `assets/favicon.svg`.
- `src/chippy.gleam` starts the listener and contains no domain logic.

Keep filesystem and HTTP failures explicit. Prefer extending the current
linear flow over adding generalized framework abstractions.

## Route fixtures

The project website is also the primary fixture:

- `/` demonstrates mixed Markdown and HTML.
- `/about` demonstrates directory routing and a colocated file.
- `/posts/inside-chippy` documents the implementation using the implementation.
- `/posts` demonstrates a request-time collection of immediate child routes.
- `/sitemap.xml` demonstrates filesystem-derived infrastructure output.
- `/favicon.svg` demonstrates the built-in asset fallback.

Focused tests live in `test/chippy_test.gleam`. They should not require a live
socket.

## Current content contract

Every `+page.md` requires non-empty `title`, `description`, and `published`
strings. `published` uses `YYYY-MM-DD`. The optional `noindex` field accepts
only `true` or `false`; an omitted value means `false`. Invalid metadata fails
rendering explicitly and also prevents Chippy from publishing an incomplete
sitemap or collection.

The collection marker discovers only immediate child route folders, excludes
noindexed pages, and orders the remainder by `published` newest-first. Keep it
small and filesystem-shaped; do not turn it into a generalized query system.

Every site requires `name`, `url`, and `description` strings in `site.toml`.
The optional `language` string defaults to `en`. The configured URL is the
canonical public origin used in page metadata and the sitemap.

Keep this contract, README.md, and the Inside Chippy article synchronized when
adding metadata or built-in routes.
