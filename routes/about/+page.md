---
title: About
description: Why Chippy exists and what it deliberately leaves out.
---

# About Chippy

Chippy is for content-led websites that do not need to become applications.
It keeps the useful old idea—request a page and receive HTML—while using Gleam
to model the path from disk to response explicitly.

## Deliberately absent

- No database or ORM
- No SPA, hydration, or client-side router
- No content build step
- No asset pipeline beyond ordinary Tailwind CSS compilation
- No image optimization

Its [colocated text file](/about/notes.txt) is served directly from the same
route folder.
