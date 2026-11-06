import chippy/route.{type RouteError, NotFound}
import gleam/list
import gleam/result
import gleam/string
import simplifile

/// Resolve a public asset URL to an existing file Mist may safely serve.
///
/// Global assets, generated reference files, and route-colocated files have
/// distinct roots. Traversal attempts and Chippy implementation files fail.
pub fn resolve(request_path: String) -> Result(String, RouteError) {
  use relative <- result.try(route.safe_relative_path(request_path))
  case relative {
    "" -> Error(NotFound)
    _ -> {
      let path = case relative {
        "reference" -> "reference/index.html"
        _ ->
          case string.starts_with(relative, "reference/") {
            True -> relative
            False ->
              case string.starts_with(relative, "assets/") {
                True -> relative
                False -> "routes/" <> relative
              }
          }
      }
      case route.is_private_path(relative) {
        True -> Error(NotFound)
        False ->
          case simplifile.is_file(path) {
            Ok(True) -> Ok(path)
            _ -> Error(NotFound)
          }
      }
    }
  }
}

/// Return the content type for a static file based on its extension.
pub fn content_type(path: String) -> String {
  case file_extension(path) {
    "html" -> "text/html; charset=utf-8"
    "css" -> "text/css; charset=utf-8"
    "js" -> "text/javascript; charset=utf-8"
    "json" -> "application/json; charset=utf-8"
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

fn file_extension(path: String) -> String {
  let filename = path |> string.split("/") |> list.last |> result.unwrap("")
  case string.split(filename, ".") {
    ["", _] -> ""
    [_, extension, ..rest] ->
      [extension, ..rest]
      |> list.last
      |> result.unwrap("")
      |> string.lowercase
    _ -> ""
  }
}
