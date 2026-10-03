---
title: About
description: Chippy is a server-side rendered dynamic website with Markdown files instead of a database.
published: 2026-10-03
---

# About Chippy

Chippy is a server-side rendered dynamic content website system written in
Gleam. It uses Markdown files in place of database records.

Each URL maps to a directory. When a request arrives, Chippy reads the current
Markdown file, renders it, applies an HTML layout, and returns a complete HTML
document.

<figure class="page-image">
  <img src="/about/about.webp" alt="Folders, Markdown, a server, and an image assembled as website building blocks" width="1280" height="854" loading="lazy" decoding="async">
</figure>

## Everything Chippy does

### Content and routing

- Maps directories to URLs, with one `+page.md` file per page
- Renders Markdown on every request instead of generating a static site
- Requires a title, description, and publication date in page frontmatter
- Supports an optional `noindex` flag
- Allows trusted raw HTML inside Markdown
- Builds collection indexes from immediate child routes, newest first

### Composition and presentation

- Composes layouts from the root down through nested route folders
- Inserts reusable root-level HTML partials
- Serves site-wide files from `assets/`
- Serves ordinary files colocated inside route folders
- Compiles the included dark theme from Tailwind source CSS
- Ships this repository as a working demo site

### Metadata and discovery

- Produces canonical, Open Graph, and Twitter metadata
- Defaults the document language to English and allows it to be configured
- Generates `/sitemap.xml` from current indexable routes at request time
- Serves a site favicon or a built-in SVG fallback

### HTTP and operations

- Returns complete server-rendered HTML through Mist on the BEAM
- Handles the demo contact form on the server with simulated feedback
- Sends useful content types and `X-Content-Type-Options: nosniff` for assets
- Rejects unsafe paths and keeps implementation files private
- Renders styled, noindexed `404` and `500` pages with correct status codes
- Validates `HOST` and `PORT` before starting, with local-friendly defaults
- Includes tests, automated checks, a production container, and Fly.io setup

## What it deliberately does not do

Chippy has no database, browser-side application runtime, content build,
general template language, administration screen, tag system, pagination, RSS
feed, or built-in image pipeline. The illustrations on this demo were optimized
to WebP before being added and are served as ordinary colocated files. The
contact form deliberately sends and stores nothing.

Its [colocated text file](/about/notes.txt) is served directly from the same
route folder. The illustration above is served from that folder too.
