---
title: Server-side rendered Markdown
description: Chippy is a server-side rendered dynamic website with Markdown files instead of a database.
published: 2026-10-03
---

<section class="hero">
  <p class="eyebrow">Chippy</p>
  <h1>Server-side rendered content. <em>Markdown instead of a database.</em></h1>
  <p class="hero-copy">Chippy is a dynamic website system. URLs map to folders, content lives in Markdown files, and every request returns complete HTML.</p>
  <div class="hero-actions">
    <a class="primary-button" href="/posts/inside-chippy">See how Chippy works</a>
    <a class="text-link" href="https://github.com/bmehder/chippy">View the source →</a>
  </div>
  <div class="request-flow" aria-label="Request flow">
    <span>GET /about</span><b>→</b><span>+page.md</span><b>→</b><span>HTML</span>
  </div>
</section>

<section class="principles">
  <p class="eyebrow">The model</p>
  <h2>A direct path from request to response.</h2>
  <div class="principle-grid">
    <article><span>01</span><h3>Content is stored in files</h3><p>Markdown files take the place of database records and stay easy to edit, move, and version.</p></article>
    <article><span>02</span><h3>Pages render on request</h3><p>Change a file, save it, and refresh. Chippy reads the current content every time.</p></article>
    <article><span>03</span><h3>The response is HTML</h3><p>Layouts and partials wrap rendered Markdown in a complete server response.</p></article>
  </div>
</section>

## The route is the folder

```text
routes/
├── +page.md                 → /
├── about/+page.md           → /about
└── posts/
    ├── +page.md             → /posts
    └── inside-chippy/
        ├── +page.md         → /posts/inside-chippy
        └── request-flow.txt → /posts/inside-chippy/request-flow.txt
```

Files beginning with `+` describe Chippy. Ordinary files are served normally,
which makes route-local CSS, JavaScript, images, and downloads unsurprising.

<aside class="callout"><strong>The project is the demo.</strong> This page is loaded from <code>routes/+page.md</code>, rendered by the same code documented in the repository, and styled by Tailwind-generated CSS served from <code>assets/</code>.</aside>
