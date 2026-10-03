# Deploying Chippy

Chippy's demo site runs on Fly.io as a small Erlang container. The deployment
uses the same request-time rendering as local development; it does not generate
a static site.

## Container

The multi-stage `Dockerfile` exports an Erlang shipment, then copies only the
runtime, site configuration, routes, and public assets into the final image.
The server runs as an unprivileged user and listens on `0.0.0.0:8000`.

Build verification is part of the normal project check:

```sh
npm run check
gleam export erlang-shipment
```

## Fly.io

`fly.toml` deploys to London on a 256 MB shared Machine. It can stop while idle
and starts automatically on the next request.

Deploy the current checkout with:

```sh
fly deploy
```

Inspect it with:

```sh
fly status
fly logs
```

The public URL in `site.toml` must match the deployed origin because Chippy uses
it for canonical metadata and the sitemap. A custom domain only requires
changing that value and configuring the corresponding Fly certificate and DNS.
