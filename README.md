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

Port 8000 is the default. Set `PORT` when another process already uses it or
when a hosting platform supplies a port:

```sh
PORT=4000 gleam run
```

Invalid and unavailable ports produce a short error with the next command to
try.

Chippy binds to `127.0.0.1` by default for local development. A deployed
service normally needs to accept traffic from outside its container:

```sh
HOST=0.0.0.0 PORT=4000 gleam run
```

`HOST` accepts `localhost` or an IPv4 address. Invalid and unavailable
addresses fail before Mist starts.

Edit `routes/+page.md`, save it, and refresh the browser to see the change. The
repository is Chippy's demo site as well as its implementation.

## Site configuration

`site.toml` defines the small amount of metadata shared by the whole site:

```toml
name = "Chippy"
url = "http://localhost:8000"
description = "A server-side rendered dynamic website with Markdown files instead of a database."
```

`name`, `url`, and `description` are required. `language` is optional and
defaults to `"en"`; set it only when the site uses another language. Change
`url` to the public production origin before deploying. Chippy loads and
validates this file when the server starts.

## Routes

The root page currently demonstrates the route convention:

```text
routes/
├── +page.md
├── +layout.html
├── home.webp
├── about/
│   ├── +page.md
│   ├── about.webp
│   └── notes.txt
├── contact/
│   └── +page.md
├── portable/
│   └── +page.md
├── posts/
│   ├── +page.md
│   ├── +layout.html
│   ├── posts.webp
│   ├── gleam-or-php/
│   │   ├── +page.md
│   │   └── gleam-or-php.webp
│   ├── inside-chippy/
│   │   ├── +page.md
│   │   ├── inside-chippy.webp
│   │   └── request-flow.txt
│   └── request-time-rendering/
│       ├── +page.md
│       └── request-time-rendering.webp
└── _partials/
    ├── footer.html
    └── header.html
```

- `+page.md` contains frontmatter followed by the route's Markdown.
- `+layout.html` is ordinary HTML with a `{{ content }}` insertion point.
  The root file owns the complete document; nested files are HTML fragments.
- `{{ partial:name }}` inserts `routes/_partials/name.html`.
- The included header has desktop navigation and an accessible, no-JavaScript
  mobile menu built with native HTML.
- Ordinary files inside a route folder are served at the corresponding URL.
  For example, `routes/about/notes.txt` is available at `/about/notes.txt`.
- Files beginning with `+` or `_` are implementation files and are never
  served as static assets.

The included `routes/about/+page.md` maps naturally to `/about`. Layouts compose
from the root down to the requested route, so the posts layout wraps both
`/posts` and every article beneath it. A directory without its own layout
simply inherits the layouts above it. Root partials remain available
throughout.

## Contact demo

`/contact` contains a plain HTML form inside its Markdown page. Its POST handler
reads a size-limited body and randomly renders either success or failure
feedback. This is intentionally theatre: it decodes nothing, stores nothing,
and never sends an email. The small feature demonstrates that Chippy is a
dynamic server rather than a static-site build.

## Metadata

Chippy recognizes three required fields and one optional flag:

```markdown
---
title: About
description: Why this page exists.
published: 2026-10-03
noindex: false
---
```

The root layout receives `{{ language }}`, `{{ site_name }}`, `{{ title }}`,
`{{ description }}`, `{{ metadata }}`, and `{{ content }}`. Chippy fills the
metadata slot with canonical, Open Graph, and Twitter tags, plus a robots
directive when `noindex: true`. Noindexed pages are also omitted from the
sitemap. Metadata stays deliberately predefined and small.

`published` must use `YYYY-MM-DD`. It gives collection indexes a predictable
display value and makes newest-first ordering a simple string comparison.

Chippy supports version 1.0.0 of [The Markdown Works content
contract](https://github.com/bmehder/themarkdownworks/blob/main/docs/markdown-contract.md).
Its three required fields are read from a real YAML mapping, so plain and quoted
strings have the same meaning. Additional scalar, list, and mapping metadata is
allowed and ignored unless Chippy recognizes the field. The unchanged shared
example is available at `/portable`.

Markdown supports CommonMark plus footnotes, stable heading IDs, and tables.
Raw HTML is allowed because route files are trusted site source rather than
visitor input.

## Collections

A page becomes a collection index when its Markdown contains `{{ collection }}`.
Chippy replaces that marker with the indexable pages found in its immediate
child route folders. Each entry links to the child page and displays its title,
description, and publication date.

The included `/posts` page demonstrates the complete convention. Collection
discovery happens on every request, just like normal page rendering, so adding
a child route requires no content build. Chippy deliberately has no tags,
pagination, categories, or feed format.

## Assets and Tailwind

Site-wide static files live under `assets/` and are served from `/assets/`.
Ordinary files may also live inside a route folder, where their URL follows the
route. The demo illustrations are pre-optimized WebP files colocated with their
pages. Chippy serves them unchanged; it does not transform images or other
assets at runtime.

Tailwind compiles `styles/site.css` to `assets/site.css`. CSS compilation is
separate from content rendering: changing Markdown never requires a build.

```sh
npm run watch:css
```

## Interactive islands

Chippy does not require a browser-side framework, and this demo currently has
no JavaScript island. When a page needs a small interactive area, place its
JavaScript beside the route or in `assets/` and load it from the layout or page.

Lustre is the author's preferred way to build those islands, and the Docklands
demo uses it. It is a choice, not a Chippy dependency: plain JavaScript or
another suitably small library works too, and authors do not need to learn
Lustre to build with Chippy. The [shared islands
guide](https://themarkdownworks.vercel.app/docs/islands/) explains the options
with a plain JavaScript example.

## Infrastructure route

- `/sitemap.xml` discovers valid `+page.md` files at request time. It uses the
  public `url` in `site.toml` to produce stable absolute URLs.

The root layout links directly to `/assets/favicon.svg`. Replace that ordinary
asset when a site needs its own icon; there is no special favicon route or
fallback behavior.

Missing pages and unexpected rendering failures use the site's root layout and
partials, return the correct `404` or `500` status, and are marked `noindex`.

## Learn the codebase

- Read [DEVELOPMENT.md](DEVELOPMENT.md) to set up a development environment.
- Read [DEPLOYMENT.md](DEPLOYMENT.md) for the container and Fly.io deployment.
- Run the site and open `/posts/inside-chippy` for a request-by-request tour.
- Open `/about` for the complete feature inventory and intentional omissions.
- Submit `/contact` to see both simulated form outcomes.

## Dependencies

The included packages each have a narrow job:

- Simplifile reads route, layout, partial, asset, and configuration files and
  checks filesystem entries. Chippy keeps its own traversal so private route
  directories can be pruned while they are walked.
- Mörk separates frontmatter from the body and renders Markdown with the useful
  authoring extensions listed above; Yamleam interprets the YAML mapping.
- Mist serves HTTP responses and files and size-limits the contact request body.
- Tom parses `site.toml`; Envoy reads host and port settings; Gleam Crypto
  supplies the contact demo's random outcome.

Using a dependency fully means using the parts that fit Chippy's small contract,
not wrapping every API it exposes.

## Check the project

```sh
npm run check
```

For production, build the stylesheet, set the public `url` in `site.toml`, and
start Chippy with `HOST=0.0.0.0` and the platform's `PORT`. Markdown remains
request-time content; there is no content build or generated site directory.

Further capabilities will be added only when the demo site genuinely needs
them.
