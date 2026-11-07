import chippy/asset
import chippy/page
import chippy/route
import chippy/site as site_config
import chippy/sitemap
import gleam/bytes_tree
import gleam/http
import gleam/http/request.{type Request}
import gleam/http/response.{type Response}
import gleam/option.{type Option, None, Some}
import gleam/result
import mist

/// A failure to load site identity or start the Mist listener.
pub type StartError {
  InvalidSiteConfiguration(site_config.SiteError)
  ServerStartFailed(String, Int)
}

/// Load `site.toml` and start Mist at an already validated address.
/// Callers normally use `chippy.main`, which performs listener preflight.
pub fn start(host: String, port: Int) -> Result(Nil, StartError) {
  start_with(host:, port:, handler: fn(_, _) { None })
}

/// Start with a site handler. Returning None delegates to Chippy's routes.
pub fn start_with(
  host host: String,
  port port: Int,
  handler handler: fn(Request(mist.Connection), site_config.Site) ->
    Option(Response(mist.ResponseData)),
) -> Result(Nil, StartError) {
  use site <- result.try(
    site_config.load("site.toml")
    |> result.map_error(InvalidSiteConfiguration),
  )
  fn(request: Request(mist.Connection)) -> Response(mist.ResponseData) {
    case handler(request, site) {
      Some(response) -> response
      None -> handle(request, site)
    }
  }
  |> mist.new
  |> mist.bind(host)
  |> mist.port(port)
  |> mist.start
  |> result.map(fn(_) { Nil })
  |> result.map_error(fn(_) { ServerStartFailed(host, port) })
}

/// Convert one Mist request into a Chippy response.
///
/// GET tries Markdown pages before static files. Other methods receive 405.
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
    path ->
      case page.render(path, site) {
        Ok(html) -> html_response(200, html)
        Error(page.NotFound) -> serve_asset(path, site)
        Error(page.UnsafePath) ->
          error_response(
            site:,
            status: 400,
            heading: "Bad request",
            message: "The requested path is not valid.",
          )
        Error(_) ->
          error_response(
            site:,
            status: 500,
            heading: "Rendering failed",
            message: "Chippy could not render this page.",
          )
      }
  }
}

fn serve_asset(
  path: String,
  site: site_config.Site,
) -> Response(mist.ResponseData) {
  case asset.resolve(path) {
    Ok(path) -> file_response(path, site)
    Error(_) ->
      error_response(
        site:,
        status: 404,
        heading: "Page not found",
        message: "There is no page at this address.",
      )
  }
}

fn sitemap_response(site: site_config.Site) -> Response(mist.ResponseData) {
  case route.discover_routes() {
    Ok(routes) ->
      string_response(
        status: 200,
        content_type: "application/xml; charset=utf-8",
        body: sitemap.render(site.url, routes),
      )
    Error(_) ->
      error_response(
        site:,
        status: 500,
        heading: "Sitemap unavailable",
        message: "Chippy could not discover the site's routes.",
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
      |> response.set_header("content-type", asset.content_type(path))
      |> response.set_header("x-content-type-options", "nosniff")
      |> response.set_body(body)
    Error(_) ->
      error_response(
        site:,
        status: 404,
        heading: "File not found",
        message: "The requested file is unavailable.",
      )
  }
}

/// Render a site-styled error response with a plain-text fallback.
pub fn error_response(
  site site: site_config.Site,
  status status: Int,
  heading heading: String,
  message message: String,
) -> Response(mist.ResponseData) {
  case page.render_error(site:, heading:, message:) {
    Ok(html) -> html_response(status, html)
    Error(_) -> text_response(status, message)
  }
}

/// Build an HTML response for rendered site content.
pub fn html_response(status: Int, body: String) -> Response(mist.ResponseData) {
  string_response(status:, content_type: "text/html; charset=utf-8", body:)
}

fn text_response(status: Int, body: String) -> Response(mist.ResponseData) {
  string_response(status:, content_type: "text/plain; charset=utf-8", body:)
}

fn string_response(
  status status: Int,
  content_type content_type: String,
  body body: String,
) -> Response(mist.ResponseData) {
  let body = body |> bytes_tree.from_string |> mist.Bytes
  response.new(status)
  |> response.set_header("content-type", content_type)
  |> response.set_body(body)
}
