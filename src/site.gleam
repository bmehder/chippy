import chippy/site.{type Site}
import gleam/http
import gleam/http/request.{type Request}
import gleam/http/response.{type Response}
import gleam/option.{type Option, None, Some}
import mist
import site/contact

/// Register custom site requests here. None delegates to Chippy.
pub fn handle(
  request: Request(mist.Connection),
  site: Site,
) -> Option(Response(mist.ResponseData)) {
  case request.method, request.path {
    http.Post, "/contact" -> Some(contact.handle(request, site))
    _, _ -> None
  }
}
