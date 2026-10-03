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

The server reads `HOST` and `PORT` from the environment. They default to
`127.0.0.1` and `8000`. To use another port:

```sh
PORT=4000 gleam run
```

Use `HOST=0.0.0.0` when a container or hosting platform needs to reach the
listener. Host and port values are validated before Mist starts.

When changing classes or `styles/site.css`, run this in a second terminal:

```sh
npm run watch:css
```

Tailwind is the only built-in asset build. Images and other files are served
unchanged. Optimize production images before adding them; the demo uses WebP
files colocated with their pages.

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
  → chippy/document.gleam and chippy/markdown.gleam
  → chippy/template.gleam
  → Mist response
```

- `src/chippy/page.gleam` orchestrates page rendering and owns safe path
  resolution, collections, route discovery, and static-file resolution.
- `src/chippy/document.gleam` owns the page document type, frontmatter parsing,
  and metadata validation.
- `src/chippy/markdown.gleam` owns the Mörk configuration and enables heading
  IDs, tables, task lists, and automatic links in addition to CommonMark and
  footnotes.
- `src/chippy/template.gleam` composes nested layouts and partials, escapes
  inserted values, and renders document metadata.
- `src/chippy/contact.gleam` contains the demo form's simulated outcome and
  supplies its feedback through the page renderer's named-insertion API.
- `src/chippy/server.gleam` owns HTTP methods, statuses, headers, content types,
  the sitemap route, site configuration loading, and Mist response bodies.
- `src/chippy/server_config.gleam` validates the optional `HOST` and `PORT`
  environment values and checks that the selected address is available before
  Mist starts.
- `src/chippy/site.gleam` parses and validates `site.toml`, supplies the default
  language, and builds absolute URLs.
- `src/chippy/sitemap.gleam` turns discovered indexable routes into XML.
- `src/chippy.gleam` starts the listener and contains no domain logic.

Keep filesystem and HTTP failures explicit. Prefer extending the current
linear flow over adding generalized framework abstractions.

## Route fixtures

The project website is also the primary fixture:

- `/` demonstrates mixed Markdown and HTML.
- `/about` demonstrates directory routing and a colocated file.
- `/contact` demonstrates a server-rendered POST response without external
  delivery or persistence.
- `/posts/inside-chippy` documents the implementation using the implementation.
- `/posts/gleam-or-php` records the language tradeoffs without treating PHP as
  an inferior implementation.
- `/posts/request-time-rendering` explains the central rendering decision.
- `/posts` demonstrates a request-time collection and, with its children, a
  composed route layout.
- `/sitemap.xml` demonstrates filesystem-derived infrastructure output.
- `/assets/favicon.svg` demonstrates a site-wide static asset.

The shared header demonstrates responsive navigation with native `details` and
`summary` elements. It needs no browser-side JavaScript.

Focused tests are split by module under `test/`. `test/chippy_test.gleam` is
only their Gleeunit entry point. The tests should not require a live socket.

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

## Package boundaries

Simplifile is Chippy's read-only filesystem boundary. It reads content and
templates and identifies files and directories; route discovery remains in
Chippy so private directory pruning stays explicit. Mörk owns Markdown parsing,
Mist owns HTTP and file responses, Tom owns TOML parsing, Envoy owns environment
access, and Gleam Crypto supplies randomness for the contact demonstration.
Prefer extending those focused boundaries over adding overlapping helpers.
