---
title: Inside Chippy
description: Follow a request from a URL through a Markdown file and layout to a complete HTML response.
---

<p class="eyebrow">A guided code tour</p>

# Inside Chippy

This guide follows one request through the complete project: from `GET
/posts/inside-chippy`, through a directory and Markdown document, to HTML served
by Mist. Keep the source open beside this page and follow the files in order.

Chippy is deliberately small. Filesystem and HTTP work stay near the edges;
the middle is a direct transformation that can be tested without opening a
network port.

## 1. Start with the repository shape

```text
routes/                 Pages and route-colocated static files
assets/                 Site-wide static files
styles/                 Tailwind source CSS
src/chippy/             Application modules
test/                   Tests
```

Two filenames carry special meaning:

```text
routes/<path>/+page.md       Markdown for the route
routes/<path>/+layout.html   Optional layout for the route
```

The `+` prefix reserves a file for Chippy itself. Files beginning with `+` or
directories beginning with `_` cannot be requested as static files.

## 2. Turn the request path into a directory

Open `src/chippy/page.gleam`. `safe_relative_path` removes the leading slash and
rejects parent-directory or backslash traversal. `route_directory` then places
the safe path beneath `routes/`.

Conceptually:

```text
/posts/inside-chippy
          ↓
routes/posts/inside-chippy
          ↓
routes/posts/inside-chippy/+page.md
```

The route structure is the routing configuration. There is no separate table
that can drift away from the content tree.

## 3. Read and model the document

`page.render` reads `+page.md` on every request. Mörk separates the frontmatter
from the body. Chippy currently recognizes two required metadata fields:
`title` and `description`.

The parser returns a `Result`. A missing page becomes `NotFound`; malformed or
missing metadata becomes `InvalidMetadata`. These errors are values passed to
the HTTP boundary rather than exceptions hidden in the rendering code.

## 4. Render Markdown

Mörk converts the body to HTML. Raw HTML is intentionally allowed because route
files are trusted site source, not untrusted visitor input. That is why this
guide can use ordinary Markdown while the homepage uses richer HTML sections.

## 5. Apply a layout and partials

Chippy looks for a `+layout.html` in the route directory and otherwise uses the
root layout. It replaces three small insertion points:

```text
{{ title }}
{{ description }}
{{ content }}
```

Files under `routes/_partials/` are available through markers such as `{{
partial:header }}`. This is intentionally not a general template language. The
layout remains an HTML file with a few obvious holes.

## 6. Reach the HTTP boundary

Open `src/chippy/server.gleam`. Mist passes each request to `handle`. A `GET`
first attempts to render a page. If there is no page at that path, the server
checks for a static file instead.

The domain errors become HTTP responses at this boundary:

- missing page or asset → `404`
- unsafe path → `400`
- unsupported method → `405`
- rendering failure → `500`

Successful HTML gets an explicit UTF-8 content type. Static responses receive
a content type based on their extension and `X-Content-Type-Options: nosniff`.

## 7. Follow an asset

Global files live under `assets/` and keep that URL prefix. This compiled
stylesheet is therefore available as `/assets/site.css`.

An ordinary file placed beside a page is colocated with its route. For example,
the source file beside this guide is available as
[request-flow.txt](/posts/inside-chippy/request-flow.txt).

There is no image optimizer or generalized asset build. Tailwind compiles one
CSS file; everything else is served as an ordinary file.

## 8. Read the tests beside the code

Open `test/chippy_test.gleam`. The tests render pages and resolve assets without
starting the server. They cover the home page, directory routing, both asset
locations, private implementation files, traversal rejection, partials, and
metadata insertion.

Run the complete project check with:

```sh
npm run check
```

## 9. Start at `main` last

`src/chippy.gleam` starts the server on port 8000 and then lets the BEAM process
sleep. It is short because routing, rendering, and response decisions live in
the modules you have already read.

## Exercises

1. Edit this paragraph and refresh the page.
2. Add `routes/contact/+page.md` with the required metadata.
3. Add a CSS or text file beside it and request that file directly.
4. Add a partial under `routes/_partials/` and place its marker in the layout.
5. Remove a required metadata field and inspect the `500` response.

If you can trace those changes from URL to filesystem to HTML, you understand
the current Chippy architecture.
