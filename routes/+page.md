---
title: A website should feel like a website
description: Chippy is a tiny server-rendered Markdown website system written in Gleam.
---

<section class="hero">
  <p class="eyebrow">Markdown → HTML, on request</p>
  <h1>A website should feel like <em>a website.</em></h1>
  <p class="hero-copy">Chippy maps URLs to folders, renders Markdown on the server, and sends complete HTML to the browser. No database. No content build. No application pretending to be a document.</p>
  <div class="hero-actions">
    <a class="primary-button" href="/posts/inside-chippy">See how Chippy works</a>
    <a class="text-link" href="https://github.com/bmehder/chippy">View the source →</a>
  </div>
  <div class="request-flow" aria-label="Request flow">
    <span>GET /about</span><b>→</b><span>+page.md</span><b>→</b><span>HTML</span>
  </div>
</section>

<section class="principles">
  <p class="eyebrow">Caveman simple, if it earns it</p>
  <h2>Ordinary website technology, with a small amount of structure.</h2>
  <div class="principle-grid">
    <article><span>01</span><h3>Files are the content store</h3><p>Routes, Markdown, layouts, partials, and assets remain visible on disk.</p></article>
    <article><span>02</span><h3>Rendering happens at request time</h3><p>Change a Markdown file, save it, and refresh. There is no content compilation step.</p></article>
    <article><span>03</span><h3>HTML stays welcome</h3><p>Use Markdown for prose and ordinary HTML when the page needs more control.</p></article>
  </div>
</section>

## The route is the folder

```text
routes/
├── +page.md                 → /
├── about/+page.md           → /about
└── posts/inside-chippy/
    ├── +page.md             → /posts/inside-chippy
    └── request-flow.txt     → /posts/inside-chippy/request-flow.txt
```

Files beginning with `+` describe Chippy. Ordinary files are served normally,
which makes route-local CSS, JavaScript, images, and downloads unsurprising.

<aside class="callout"><strong>The project is the demo.</strong> This page is loaded from <code>routes/+page.md</code>, rendered by the same code documented in the repository, and styled by Tailwind-generated CSS served from <code>assets/</code>.</aside>
