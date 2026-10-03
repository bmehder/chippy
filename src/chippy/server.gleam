import chippy/favicon
import chippy/page
import chippy/site as site_config
import chippy/sitemap
import gleam/bytes_tree
import gleam/http
import gleam/http/request.{type Request}
import gleam/http/response.{type Response}
import gleam/option.{None}
import gleam/result
import gleam/string
import mist

pub type StartError {
  InvalidSiteConfiguration(site_config.SiteError)
  ServerStartFailed
}

pub fn start(port: Int) -> Result(Nil, StartError) {
  use site <- result.try(
    site_config.load("site.toml")
    |> result.map_error(InvalidSiteConfiguration),
  )
  fn(request: Request(mist.Connection)) -> Response(mist.ResponseData) {
    handle(request, site)
  }
  |> mist.new
  |> mist.port(port)
  |> mist.start
  |> result.map(fn(_) { Nil })
  |> result.map_error(fn(_) { ServerStartFailed })
}

pub fn handle(
  request: Request(mist.Connection),
  site: site_config.Site,
) -> Response(mist.ResponseData) {
  case request.method {
    http.Get -> get(request, site)
    _ ->
      text_response(405, "Method not allowed")
      |> response.set_header("allow", "GET")
  }
}

fn get(
  request: Request(mist.Connection),
  site: site_config.Site,
) -> Response(mist.ResponseData) {
  case request.path {
    "/sitemap.xml" -> sitemap_response(site)
    "/favicon.svg" -> favicon_response(site)
    path ->
      case page.render(path, site) {
        Ok(html) -> html_response(200, html)
        Error(page.NotFound) -> asset_or_not_found(path, site)
        Error(page.UnsafePath) ->
          error_response(
            site,
            400,
            "Bad request",
            "The requested path is not valid.",
          )
        Error(_) ->
          error_response(
            site,
            500,
            "Rendering failed",
            "Chippy could not render this page.",
          )
      }
  }
}

fn asset_or_not_found(
  path: String,
  site: site_config.Site,
) -> Response(mist.ResponseData) {
  case page.asset_path(path) {
    Ok(path) -> file_response(path, site)
    Error(_) ->
      error_response(
        site,
        404,
        "Page not found",
        "There is no page at this address.",
      )
  }
}

fn favicon_response(site: site_config.Site) -> Response(mist.ResponseData) {
  case page.asset_path("/assets/favicon.svg") {
    Ok(path) -> file_response(path, site)
    Error(_) ->
      response.new(200)
      |> response.set_header("content-type", "image/svg+xml")
      |> response.set_header("cache-control", "public, max-age=3600")
      |> response.set_header("x-content-type-options", "nosniff")
      |> response.set_body(mist.Bytes(bytes_tree.from_string(favicon.svg)))
  }
}

fn sitemap_response(site: site_config.Site) -> Response(mist.ResponseData) {
  case page.discover_routes() {
    Ok(routes) ->
      response.new(200)
      |> response.set_header("content-type", "application/xml; charset=utf-8")
      |> response.set_body(
        mist.Bytes(bytes_tree.from_string(sitemap.render(site.url, routes))),
      )
    Error(_) ->
      error_response(
        site,
        500,
        "Sitemap unavailable",
        "Chippy could not discover the site's routes.",
      )
  }
}

fn file_response(
  path: String,
  site: site_config.Site,
) -> Response(mist.ResponseData) {
  case mist.send_file(path, offset: 0, limit: None) {
    Ok(body) ->
      response.new(200)
      |> response.set_header("content-type", content_type(path))
      |> response.set_header("x-content-type-options", "nosniff")
      |> response.set_body(body)
    Error(_) ->
      error_response(
        site,
        404,
        "File not found",
        "The requested file is unavailable.",
      )
  }
}

fn error_response(
  site: site_config.Site,
  status: Int,
  heading: String,
  message: String,
) -> Response(mist.ResponseData) {
  case page.render_error(site, heading, message, heading, message) {
    Ok(html) -> html_response(status, html)
    Error(_) -> text_response(status, message)
  }
}

fn html_response(status: Int, body: String) -> Response(mist.ResponseData) {
  response.new(status)
  |> response.set_header("content-type", "text/html; charset=utf-8")
  |> response.set_body(mist.Bytes(bytes_tree.from_string(body)))
}

fn text_response(status: Int, body: String) -> Response(mist.ResponseData) {
  response.new(status)
  |> response.set_header("content-type", "text/plain; charset=utf-8")
  |> response.set_body(mist.Bytes(bytes_tree.from_string(body)))
}

fn content_type(path: String) -> String {
  case path |> string.split(".") |> list_last {
    "css" -> "text/css; charset=utf-8"
    "js" -> "text/javascript; charset=utf-8"
    "svg" -> "image/svg+xml"
    "png" -> "image/png"
    "jpg" | "jpeg" -> "image/jpeg"
    "gif" -> "image/gif"
    "webp" -> "image/webp"
    "ico" -> "image/x-icon"
    "woff" -> "font/woff"
    "woff2" -> "font/woff2"
    "txt" -> "text/plain; charset=utf-8"
    _ -> "application/octet-stream"
  }
}

fn list_last(items: List(String)) -> String {
  case items {
    [] -> ""
    [item] -> string.lowercase(item)
    [_, ..rest] -> list_last(rest)
  }
}
