---
title: Inside Chippy
description: Follow a request from a URL through a Markdown file and layout to a complete HTML response.
published: 2026-10-01
---

<p class="eyebrow">A guided code tour</p>

# Inside Chippy

<figure class="page-image">
  <img src="/posts/inside-chippy/inside-chippy.webp" alt="A request passing through Markdown and nested layout layers to become a complete page" width="1280" height="854" loading="lazy" decoding="async">
</figure>

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
site.toml               Site-wide identity and public URL
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

## 2. Load the site configuration

Open `src/chippy/site.gleam`. At startup, Chippy reads `site.toml` into a typed
site value. A site requires a name, public URL, and description. Its language
defaults to English, so most sites do not need to specify it.

The public URL is intentionally configuration rather than request data. It
gives canonical links and the sitemap one stable origin in development,
production, and behind a proxy. An invalid configuration prevents the server
from starting instead of quietly publishing incorrect metadata.

## 3. Turn the request path into a directory

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

## 4. Read and model the document

`page.render` reads `+page.md` on every request. Mörk separates the frontmatter
from the body. Chippy recognizes three required metadata fields: `title`,
`description`, and an ISO `published` date. It also recognizes the optional
boolean `noindex` flag.

The parser returns a `Result`. A missing page becomes `NotFound`; malformed or
missing metadata becomes `InvalidMetadata`. These errors are values passed to
the HTTP boundary rather than exceptions hidden in the rendering code.

`noindex: true` has two effects: the layout receives a robots meta tag and the
route is omitted from `/sitemap.xml`.

## 5. Build a collection when requested

A route becomes a collection index when its Markdown contains the collection
insertion marker. Before Markdown rendering, Chippy reads the route's immediate
child directories and finds those containing a valid `+page.md`.

Noindexed children are omitted. The remaining entries are ordered by their
`published` dates, newest first, and rendered with a link, title, description,
and date. `/posts` uses this behavior to list this article. It is a direct
filesystem convention rather than a general query or taxonomy system.

## 6. Render Markdown

Mörk converts the body to HTML. Raw HTML is intentionally allowed because route
files are trusted site source, not untrusted visitor input. That is why this
guide can use ordinary Markdown while the homepage uses richer HTML sections.

## 7. Apply a layout and partials

Chippy collects `+layout.html` files from the root down to the requested route.
The root layout owns the doctype, document head, header, and footer. Nested
layouts are ordinary HTML fragments that wrap the next `{{ content }}` slot.

For this page, composition follows the filesystem:

```text
routes/+layout.html
  → routes/posts/+layout.html
    → routes/posts/inside-chippy/+page.md
```

A directory without a layout inherits the layouts above it. Every layout must
leave a `{{ content }}` insertion point for the next layout or page. After
composition, Chippy replaces the predefined document insertion points:

```text
{{ language }}
{{ site_name }}
{{ title }}
{{ description }}
{{ metadata }}
{{ content }}
```

The metadata slot contains canonical, Open Graph, and Twitter tags, plus a
robots directive for noindexed pages. Page and site values are escaped before
they enter the layout.

Files under `routes/_partials/` are available through markers such as `{{
partial:header }}`. This is intentionally not a general template language. The
layout remains an HTML file with a few obvious holes.

## 8. Reach the HTTP boundary

Open `src/chippy/server.gleam`. Mist passes each request to `handle`. A `GET`
first attempts to render a page. If there is no page at that path, the server
checks for a static file instead.

The domain errors become HTTP responses at this boundary:

- missing page or asset → layout-rendered `404`
- unsafe path → `400`
- `POST /contact` → a randomly selected simulated result page
- unsupported method or POST route → `405`
- rendering failure → layout-rendered `500`

The contact handler reads a size-limited request body, but it neither decodes
nor stores the fields and never contacts an email service. Its only purpose is
to demonstrate a server-rendered form response.

Successful HTML gets an explicit UTF-8 content type. Static responses receive
a content type based on their extension and `X-Content-Type-Options: nosniff`.

## 9. Follow an asset

Global files live under `assets/` and keep that URL prefix. This compiled
stylesheet is therefore available as `/assets/site.css`.

An ordinary file placed beside a page is colocated with its route. For example,
the source file beside this guide is available as
[request-flow.txt](/posts/inside-chippy/request-flow.txt).

There is no image optimizer or generalized asset build. The illustration on
this article was optimized before it entered the repository, then colocated
beside `+page.md`. Tailwind compiles one CSS file; everything else is served as
an ordinary file.

## 10. Discover the sitemap

Open `src/chippy/page.gleam` again and find `discover_routes`. It walks the
`routes/` tree, ignores private directories, reads each `+page.md`, and returns
the same typed documents used by normal rendering.

`src/chippy/sitemap.gleam` removes `noindex` routes and encodes the remaining
paths as XML. The server uses the public URL from `site.toml`, so the sitemap
and canonical metadata always agree.

Open `/sitemap.xml` while the site is running. Add a valid route directory,
refresh, and the new URL appears immediately.

## 11. Serve the favicon

The root layout points browsers directly to `/assets/favicon.svg`. It is an
ordinary global asset handled by the same path and content-type rules as other
static files. Replace that file when a site needs a different icon. Chippy does
not resize or transform it.

## 12. Render failures as pages

`page.render_error` uses the root layout and partials with an error-specific
content block. The server preserves the meaningful HTTP status while returning
a complete HTML page. Error documents always receive `noindex`, preventing a
404 or rendering failure from appearing in search results.

## 13. Read the tests beside the code

Open `test/chippy_test.gleam`. The tests render pages and resolve assets without
starting the server. They cover the home page, directory routing, both asset
locations, private implementation files, traversal rejection, partials, and
metadata insertion. They also cover site configuration and its English
default, collection rendering, publication-date validation, route discovery,
sitemap filtering, `noindex` validation, global favicon serving, and
layout-rendered errors.

Run the complete project check with:

```sh
npm run check
```

## 14. Start at `main` last

`src/chippy.gleam` asks `server_config.gleam` for optional `HOST` and `PORT`
environment values, defaulting to `127.0.0.1:8000`. A deployment can bind to
`0.0.0.0` so traffic can reach the server from outside its container. The
configuration rejects invalid values and checks address availability before
Mist starts, which keeps a collision from becoming an Erlang supervisor dump.
After a successful start, the main process simply sleeps while Mist handles
requests.

This entry point stays short because routing, rendering, and response decisions
live in the modules you have already read.

## Exercises

1. Edit this paragraph and refresh the page.
2. Change the site name in `site.toml` and inspect the page title and metadata.
3. Add another child route beneath `routes/posts/` and refresh the collection.
4. Add `routes/contact/+page.md` with the required metadata.
5. Submit `/contact` until you see both of its deliberately simulated outcomes.
6. Add a CSS or text file beside a route and request that file directly.
7. Add a partial under `routes/_partials/` and place its marker in the layout.
8. Set `noindex: true` and compare the collection with `/sitemap.xml`.
9. Replace `assets/favicon.svg` and refresh the browser tab.
10. Remove a required metadata field and inspect the `500` response.

If you can trace those changes from URL to filesystem to HTML, you understand
the current Chippy architecture.
