import chippy/document.{type Document}
import gleam/list
import gleam/result
import gleam/string
import simplifile

pub type RouteError {
  NotFound
  UnsafePath
  InvalidMetadata
  CannotDiscoverRoutes
}

/// A discovered public URL and its already validated content document.
/// Collections and sitemap generation share this representation.
pub type Route {
  Route(path: String, document: Document)
}

/// Discover valid public `+page.md` routes in deterministic path order.
/// Private directories are pruned; invalid metadata fails the entire result.
pub fn discover_routes() -> Result(List(Route), RouteError) {
  discover_directory("routes", "/")
  |> result.map(fn(routes) {
    list.sort(routes, fn(first, second) {
      string.compare(first.path, second.path)
    })
  })
}

/// Discover indexable direct children in reverse publication order.
pub fn discover_collection(
  directory: String,
  route_path: String,
) -> Result(List(Route), RouteError) {
  use routes <- result.try(discover_children(
    directory,
    route_path,
    [],
    route_at,
  ))
  routes
  |> list.filter(fn(route) { !route.document.noindex })
  |> list.sort(fn(first, second) {
    string.compare(second.document.published, first.document.published)
  })
  |> Ok
}

/// Resolve a public request path to its directory under routes/.
pub fn route_directory(request_path: String) -> Result(String, RouteError) {
  use relative <- result.try(safe_relative_path(request_path))
  case is_private_path(relative) {
    True -> Error(NotFound)
    False ->
      Ok(case relative {
        "" -> "routes"
        _ -> "routes/" <> relative
      })
  }
}

/// Reject traversal before resolving a request path against a filesystem root.
pub fn safe_relative_path(path: String) -> Result(String, RouteError) {
  let trimmed = string.trim(path)
  let relative = case string.starts_with(trimmed, "/") {
    True -> string.drop_start(trimmed, 1)
    False -> trimmed
  }
  let segments = string.split(relative, "/")
  case
    string.contains(relative, "\\")
    || list.any(segments, fn(segment) { segment == ".." })
  {
    True -> Error(UnsafePath)
    False ->
      case string.ends_with(relative, "/") {
        True -> Ok(string.drop_end(relative, 1))
        False -> Ok(relative)
      }
  }
}

/// Identify implementation paths hidden from direct requests.
pub fn is_private_path(relative: String) -> Bool {
  relative
  |> string.split("/")
  |> list.any(fn(segment) {
    string.starts_with(segment, "+") || string.starts_with(segment, "_")
  })
}

fn discover_directory(
  directory: String,
  route_path: String,
) -> Result(List(Route), RouteError) {
  use routes <- result.try(route_at(directory, route_path))
  discover_children(directory, route_path, routes, discover_directory)
}

fn discover_children(
  directory: String,
  route_path: String,
  routes: List(Route),
  discover: fn(String, String) -> Result(List(Route), RouteError),
) -> Result(List(Route), RouteError) {
  use entries <- result.try(
    simplifile.read_directory(directory)
    |> result.map_error(fn(_) { CannotDiscoverRoutes }),
  )
  entries
  |> list.try_fold(routes, fn(found, name) {
    let child_directory = directory <> "/" <> name
    case is_private_segment(name), simplifile.is_directory(child_directory) {
      False, Ok(True) -> {
        let child_path = case string.ends_with(route_path, "/") {
          True -> route_path <> name
          False -> route_path <> "/" <> name
        }
        discover(child_directory, child_path)
        |> result.map(fn(children) { list.append(found, children) })
      }
      _, _ -> Ok(found)
    }
  })
}

fn route_at(directory: String, route_path: String) {
  let filename = directory <> "/+page.md"
  case simplifile.is_file(filename) {
    Ok(True) -> {
      use source <- result.try(
        simplifile.read(filename)
        |> result.map_error(fn(_) { CannotDiscoverRoutes }),
      )
      use document <- result.try(
        document.parse(source) |> result.map_error(fn(_) { InvalidMetadata }),
      )
      Ok([Route(path: route_path, document:)])
    }
    Ok(False) -> Ok([])
    Error(_) -> Error(CannotDiscoverRoutes)
  }
}

fn is_private_segment(segment: String) -> Bool {
  string.starts_with(segment, "+")
  || string.starts_with(segment, "_")
  || string.starts_with(segment, ".")
}
