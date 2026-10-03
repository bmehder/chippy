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

## Current scope

- Directory-based routes
- Markdown content with predefined metadata
- HTML layouts and partials
- Global and route-local static files
- Request-time rendering

Its [colocated text file](/about/notes.txt) is served directly from the same
route folder.
