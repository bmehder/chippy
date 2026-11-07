# Reading Chippy's source

Read these in order for a first pass. In `server.gleam`, start with `handle` and follow a GET request for `/` into `page.render`. Then come back for the other request paths.

Before reading the default request handler, glance at [src/site.gleam](src/site.gleam). Startup passes this site's handler to `server.start_with`. Every request reaches it first. It handles contact submissions and returns `None` for requests that Chippy should handle.

| Order | File | What to look for |
| --- | --- | --- |
| 1 | [chippy.gleam](src/chippy.gleam) | The entry point loads listener settings, probes the port, starts the server, and reports startup failures. |
| 2 | [server_config.gleam](src/chippy/server_config.gleam) | Reads and validates `HOST` and `PORT`, supplies defaults, and declares the port probe. |
| 3 | [chippy_ffi.erl](src/chippy_ffi.erl) | Implements the probe by opening and closing a temporary TCP socket. |
| 4 | [server.gleam](src/chippy/server.gleam) | Starts Mist, offers requests to the site handler, and serves pages, assets, and the sitemap. |
| 5 | [site.gleam](src/chippy/site.gleam) | Reads site-wide settings from `site.toml` and builds absolute URLs. |
| 6 | [page.gleam](src/chippy/page.gleam) | Loads a route's Markdown, inserts collection or form content, and renders the full page. Also renders error pages. |
| 7 | [route.gleam](src/chippy/route.gleam) | Validates request paths, maps them to directories, and discovers routes for collections and the sitemap. |
| 8 | [document.gleam](src/chippy/document.gleam) | Parses Markdown frontmatter and validates page metadata, including publication dates. |
| 9 | [markdown.gleam](src/chippy/markdown.gleam) | Configures Mörk and turns Markdown into HTML. |
| 10 | [template.gleam](src/chippy/template.gleam) | Composes nested layouts and partials, then fills the HTML and metadata slots. |
| 11 | [asset.gleam](src/chippy/asset.gleam) | Finds public static files and determines their HTTP content type. |
| 12 | [sitemap.gleam](src/chippy/sitemap.gleam) | Turns discovered routes into sitemap XML and omits noindex pages. |
| 13 | [site.gleam](src/site.gleam) | Registers site-specific requests and delegates ordinary requests to Chippy. |
| 14 | [contact.gleam](src/site/contact.gleam) | Handles the demo submission and renders feedback. Its form markup is in routes/_partials/contact-form.html. |

For a small first edit, try the homepage copy in [routes/+page.md](routes/+page.md), the site-wide HTML in [routes/+layout.html](routes/+layout.html), or a response message in [server.gleam](src/chippy/server.gleam). Run `gleam test` after changing Gleam code. See [DEVELOPMENT.md](DEVELOPMENT.md) for the local workflow.
