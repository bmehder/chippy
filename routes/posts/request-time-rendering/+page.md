---
title: Why Chippy renders on request
description: The practical benefits and costs of reading Markdown when a page is requested.
published: 2026-10-02
---

<p class="eyebrow">A deliberate tradeoff</p>

# Why Chippy renders on request

<figure class="page-image">
  <img src="/posts/request-time-rendering/request-time-rendering.webp" alt="A server assembling fresh web pages from Markdown as requests arrive" width="1280" height="854" loading="lazy" decoding="async">
</figure>

Chippy does not turn Markdown into a folder of HTML during a build. It reads the
requested file and renders the page when the request arrives. That makes it a
dynamic website even though its content is stored in ordinary files.

This is not automatically better than static generation. It is a compact model
with a specific set of advantages and costs.

## There is one source of truth

With a static generator, source Markdown and generated HTML exist at different
stages. A content edit has to pass through a build before a visitor can see it.
Chippy removes that intermediate artifact:

```text
request → route folder → Markdown → layouts → response
```

Save a file locally and refresh the browser. Collections and the sitemap see
the same current files, so there is no separate content index to rebuild or
invalidate.

On a deployed container, changing a repository file still requires a new
deployment unless the content directory is mounted or synchronized. Request-
time rendering removes the content *build*; it does not invent remote editing.

## Dynamic behavior stays possible

A server is already present for every page view. Chippy can choose status
codes, inspect configuration, enforce safe paths, and discover current child
routes at that moment. Future features that genuinely depend on a request do
not require changing the project from a static artifact into an application.

The browser still receives complete HTML. Request-time rendering does not mean
a client-side JavaScript application, hydration, or a loading screen.

## The server does more work

Static HTML can be placed on a CDN and served with almost no computation.
Chippy instead reads files and renders Markdown for each request. It also needs
a running Erlang process, which is more operational machinery than a bucket of
finished HTML.

For a small content site, the work is modest and the implementation stays easy
to understand. At higher traffic, sensible caching would become the next
feature rather than pretending repeated parsing is free. Chippy does not
currently include that cache.

## Files replace records, not every database use case

Markdown is a good record format when content is edited by developers, reviewed
in Git, and deployed with the application. It is less suitable for concurrent
editing, fine-grained permissions, large queries, user-generated content, or an
editorial team expecting an administration interface.

Chippy makes the file-backed case pleasant. It does not try to make a directory
behave like a general database.

## Why it fits this project

The repository is both the framework and its demo site. Reading files on demand
makes the behavior literal: the page explaining a feature is rendered by that
feature, and a newly added article immediately joins the collection and
sitemap. There is very little distance between the mental model and the code.

That directness is the reason for request-time rendering. A static build would
be faster at the edge; a database-backed CMS would support more editorial
workflows. Chippy chooses the middle: a small dynamic server with Markdown
files instead of database rows.
