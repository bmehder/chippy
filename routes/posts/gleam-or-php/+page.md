---
title: Chippy in Gleam or PHP?
description: An honest comparison of this project in Gleam with an equally well-made PHP version.
published: 2026-10-03
---

<p class="eyebrow">An honest comparison</p>

# Chippy in Gleam or PHP?

<figure class="page-image">
  <img src="/posts/gleam-or-php/gleam-or-php.webp" alt="Two equally careful server-rendering workbenches, one typed and one script-based, producing the same web page" width="1280" height="854" loading="lazy" decoding="async">
</figure>

Chippy is written in Gleam, but its central idea is not language-specific. A
good PHP version could map a URL to a folder, read Markdown, apply layouts, and
return HTML just as faithfully. Comparing the real alternatives means giving
that PHP version the same care: types where PHP offers them, Composer packages,
static analysis, tests, safe path handling, and clear errors.

Under that condition, neither version makes the other look foolish.

## Where PHP would be better

The PHP implementation would probably be shorter. PHP already starts with a
request and ends with a response, so a small file-backed website fits its
native execution model. There would be no BEAM release to package and no
long-running process to supervise.

Deployment would also be more widely available. Nearly every ordinary web host
understands PHP, and many developers could inspect or modify the project
without learning a new language. PHP's web ecosystem offers mature choices for
Markdown, HTTP, caching, and templating. For a small content site that needs to
ship on familiar hosting, those are substantial advantages.

At this scale, PHP would not be meaningfully disqualified by performance. Both
versions spend much of their time reading small files and rendering Markdown.
The quality of caching, I/O, and deployment decisions would matter more than a
language benchmark.

## Where Gleam earns its place

Gleam makes the application's states unusually visible. A missing page,
invalid metadata, unsafe path, and failed file read are explicit values. The
compiler checks that each result is handled and keeps refactors honest across
the routing, rendering, and HTTP boundaries.

That confidence is especially useful once a tiny program grows. Adding
collections, nested layouts, sitemap discovery, and configurable server
addresses changed several modules, but the type system made incomplete changes
hard to hide. Gleam also inherits the BEAM's strong model for long-running,
concurrent services.

The code has a consistency that is pleasant to maintain: immutable data,
exhaustive pattern matching, one formatter, and a deliberately small language.
Those are not requirements for a site like Chippy, but they are real benefits.

## The costs of Gleam

Gleam asks more from deployment. The project needs Gleam and Erlang while it is
built, an Erlang runtime in production, or a container that packages both. Its
library ecosystem and hiring pool are much smaller than PHP's. Debugging may
occasionally cross a boundary into Erlang terminology, as the original port
collision message demonstrated.

Types also do not automatically make the product better. A careless Gleam
version can still have poor HTML, unclear conventions, missing tests, or a
confusing interface. A disciplined PHP version can avoid all of those flaws.
Static analysis with tools such as PHPStan can close part of the assurance gap,
though it remains an additional practice rather than the language's default.

## What I would choose

I would choose PHP when familiar commodity hosting, contributor familiarity,
or the shortest route to production mattered most. For a client site maintained
by a typical web team, that may be the responsible choice.

I would choose Gleam when the project is also an exercise in a clearer domain
model, when compile-time feedback matters to the team, or when the service is
expected to grow on the BEAM. That is why Chippy is in Gleam: not because PHP
cannot do the job, but because this small problem is a good place to explore a
different and rigorous way to do it.

The honest conclusion is that Chippy's value lives in its filesystem model,
not its implementation language. At equal quality, PHP wins on reach and
simplicity of deployment; Gleam wins on built-in guarantees and the shape of
the code. Either can produce the same excellent website.
