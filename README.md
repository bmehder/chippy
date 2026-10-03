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
├── about/
│   ├── +page.md
│   └── notes.txt
├── posts/
│   ├── +page.md
│   └── inside-chippy/
│       ├── +page.md
│       └── request-flow.txt
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
route. Chippy does not transform images or other assets.

Tailwind compiles `styles/site.css` to `assets/site.css`. CSS compilation is
separate from content rendering: changing Markdown never requires a build.

```sh
npm run watch:css
```

## Built-in routes

- `/sitemap.xml` discovers valid `+page.md` files at request time. It uses the
  public `url` in `site.toml` to produce stable absolute URLs.
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

For production, build the stylesheet, set the public `url` in `site.toml`, and
start Chippy with the platform's `PORT`. Markdown remains request-time content;
there is no content build or generated site directory.

Further capabilities will be added only when the demo site genuinely needs
them.
