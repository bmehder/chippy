import chippy/page
import gleam/bytes_tree
import gleam/http
import gleam/http/request.{type Request}
import gleam/http/response.{type Response}
import gleam/option.{None}
import gleam/string
import mist

pub fn start(port: Int) {
  fn(request: Request(mist.Connection)) -> Response(mist.ResponseData) {
    handle(request)
  }
  |> mist.new
  |> mist.port(port)
  |> mist.start
}

pub fn handle(
  request: Request(mist.Connection),
) -> Response(mist.ResponseData) {
  case request.method {
    http.Get -> get(request.path)
    _ ->
      text_response(405, "Method not allowed")
      |> response.set_header("allow", "GET")
  }
}

fn get(path: String) -> Response(mist.ResponseData) {
  case page.render(path) {
    Ok(html) -> html_response(200, html)
    Error(page.NotFound) -> asset_or_not_found(path)
    Error(page.UnsafePath) -> text_response(400, "Bad request")
    Error(_) -> text_response(500, "Could not render this page")
  }
}

fn asset_or_not_found(path: String) -> Response(mist.ResponseData) {
  case page.asset_path(path) {
    Ok(path) ->
      case mist.send_file(path, offset: 0, limit: None) {
        Ok(body) ->
          response.new(200)
          |> response.set_header("content-type", content_type(path))
          |> response.set_header("x-content-type-options", "nosniff")
          |> response.set_body(body)
        Error(_) -> text_response(404, "Not found")
      }
    Error(_) -> text_response(404, "Not found")
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
