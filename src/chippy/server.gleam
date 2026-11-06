import chippy/asset
import chippy/contact
import chippy/page
import chippy/route
import chippy/site as site_config
import chippy/sitemap
import gleam/bytes_tree
import gleam/http
import gleam/http/request.{type Request}
import gleam/http/response.{type Response}
import gleam/option.{None}
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
  use site <- result.try(
    site_config.load("site.toml")
    |> result.map_error(InvalidSiteConfiguration),
  )
  fn(request: Request(mist.Connection)) -> Response(mist.ResponseData) {
    handle(request, site)
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
/// GET tries Markdown pages before static files. POST is limited to the demo
/// contact route, and all other methods receive `405`.
pub fn handle(
  request: Request(mist.Connection),
  site: site_config.Site,
) -> Response(mist.ResponseData) {
  case request.method {
    http.Get -> get(request, site)
    http.Post -> post(request, site)
    _ ->
      text_response(405, "Method not allowed")
      |> response.set_header("allow", "GET, POST")
  }
}

fn post(
  request: Request(mist.Connection),
  site: site_config.Site,
) -> Response(mist.ResponseData) {
  case request.path {
    "/contact" ->
      case mist.read_body(request, max_body_limit: 64_000) {
        Ok(_) -> {
          let outcome = contact.random_outcome()
          case contact.render(site, outcome) {
            Ok(html) -> html_response(200, html)
            Error(_) ->
              error_response(
                site:,
                status: 500,
                heading: "Rendering failed",
                message: "Chippy could not render the contact response.",
              )
          }
        }
        Error(_) ->
          error_response(
            site:,
            status: 400,
            heading: "Invalid submission",
            message: "The contact form submission could not be read.",
          )
      }
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

fn error_response(
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

fn html_response(status: Int, body: String) -> Response(mist.ResponseData) {
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
