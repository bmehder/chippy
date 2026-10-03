import chippy/document.{type Document, Document}
import chippy/markdown
import chippy/site.{type Site, absolute_url}
import chippy/template
import gleam/list
import gleam/option.{None, Some}
import gleam/result
import gleam/string
import simplifile

pub type PageError {
  NotFound
  UnsafePath
  InvalidMetadata
  CannotDiscoverRoutes
  CannotReadLayout
  CannotReadPartials
  MissingContentSlot
}

pub type Route {
  Route(path: String, document: Document)
}

pub fn render(request_path: String, site: Site) -> Result(String, PageError) {
  render_with(request_path, site, [])
}

pub fn render_with(
  request_path: String,
  site: Site,
  insertions: List(#(String, String)),
) -> Result(String, PageError) {
  use route_directory <- result.try(route_directory(request_path))
  use source <- result.try(
    simplifile.read(route_directory <> "/+page.md")
    |> result.map_error(fn(_) { NotFound }),
  )
  use document <- result.try(parse_document(source))
  use layout <- result.try(load_template(route_directory))
  use markdown <- result.try(insert_collection(
    document.markdown,
    route_directory,
    request_path,
  ))
  let markdown = insertions |> list.fold(markdown, insert_named)
  let content = markdown.render(markdown)
  Ok(template.render(
    layout,
    document,
    content,
    site,
    Some(absolute_url(site, request_path)),
  ))
}

pub fn render_error(
  site: Site,
  title: String,
  description: String,
  heading: String,
  message: String,
) -> Result(String, PageError) {
  use layout <- result.try(load_template("routes"))
  let document =
    Document(title:, description:, published: "", noindex: True, markdown: "")
  let content =
    "<section class=\"error-page\"><p class=\"eyebrow\">Chippy</p><h1>"
    <> template.escape_html(heading)
    <> "</h1><p>"
    <> template.escape_html(message)
    <> "</p><a class=\"primary-button\" href=\"/\">Return home</a></section>"
  Ok(template.render(layout, document, content, site, None))
}

pub fn discover_routes() -> Result(List(Route), PageError) {
  discover_directory("routes", "/")
  |> result.map(fn(routes) {
    list.sort(routes, fn(first, second) {
      string.compare(first.path, second.path)
    })
  })
}

pub fn asset_path(request_path: String) -> Result(String, PageError) {
  use relative <- result.try(safe_relative_path(request_path))
  case relative {
    "" -> Error(NotFound)
    _ -> {
      let path = case string.starts_with(relative, "assets/") {
        True -> relative
        False -> "routes/" <> relative
      }
      case is_private_path(relative) {
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

fn insert_named(markdown: String, insertion: #(String, String)) -> String {
  let #(name, value) = insertion
  string.replace(markdown, "<!-- " <> name <> " -->", value)
}

fn insert_collection(
  markdown: String,
  directory: String,
  route_path: String,
) -> Result(String, PageError) {
  case string.contains(markdown, "{{ collection }}") {
    False -> Ok(markdown)
    True -> {
      use entries <- result.try(discover_collection(directory, route_path))
      Ok(string.replace(markdown, "{{ collection }}", collection_html(entries)))
    }
  }
}

fn discover_collection(
  directory: String,
  route_path: String,
) -> Result(List(Route), PageError) {
  use entries <- result.try(
    simplifile.read_directory(directory)
    |> result.map_error(fn(_) { CannotDiscoverRoutes }),
  )
  use routes <- result.try(
    list.try_fold(entries, [], fn(found, name) {
      let child_directory = directory <> "/" <> name
      case is_private_segment(name), simplifile.is_directory(child_directory) {
        False, Ok(True) -> {
          let child_path = case string.ends_with(route_path, "/") {
            True -> route_path <> name
            False -> route_path <> "/" <> name
          }
          route_at(child_directory, child_path)
          |> result.map(fn(routes) { list.append(found, routes) })
        }
        _, _ -> Ok(found)
      }
    }),
  )
  routes
  |> list.filter(fn(route) { !route.document.noindex })
  |> list.sort(fn(first, second) {
    string.compare(second.document.published, first.document.published)
  })
  |> Ok
}

fn collection_html(routes: List(Route)) -> String {
  routes
  |> list.map(fn(route) {
    "<article class=\"collection-entry\"><time datetime=\""
    <> template.escape_html(route.document.published)
    <> "\">"
    <> template.escape_html(route.document.published)
    <> "</time><h2><a href=\""
    <> template.escape_html(route.path)
    <> "\">"
    <> template.escape_html(route.document.title)
    <> "</a></h2><p>"
    <> template.escape_html(route.document.description)
    <> "</p></article>"
  })
  |> string.join("\n")
  |> fn(entries) { "<section class=\"collection\">" <> entries <> "</section>" }
}

fn route_directory(request_path: String) -> Result(String, PageError) {
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

fn safe_relative_path(path: String) -> Result(String, PageError) {
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

fn is_private_path(relative: String) -> Bool {
  relative
  |> string.split("/")
  |> list.any(fn(segment) {
    string.starts_with(segment, "+") || string.starts_with(segment, "_")
  })
}

fn discover_directory(
  directory: String,
  route_path: String,
) -> Result(List(Route), PageError) {
  use routes <- result.try(route_at(directory, route_path))
  use entries <- result.try(
    simplifile.read_directory(directory)
    |> result.map_error(fn(_) { CannotDiscoverRoutes }),
  )
  entries
  |> list.try_fold(routes, fn(found, name) {
    let child_directory = directory <> "/" <> name
    case is_private_segment(name), simplifile.is_directory(child_directory) {
      False, Ok(True) -> {
        let child_path = case route_path {
          "/" -> "/" <> name
          _ -> route_path <> "/" <> name
        }
        discover_directory(child_directory, child_path)
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
      use document <- result.try(parse_document(source))
      Ok([Route(path: route_path, document:)])
    }
    Ok(False) -> Ok([])
    Error(_) -> Error(CannotDiscoverRoutes)
  }
}

fn parse_document(source: String) -> Result(Document, PageError) {
  document.parse(source) |> result.map_error(fn(_) { InvalidMetadata })
}

fn load_template(route_directory: String) -> Result(String, PageError) {
  template.load(route_directory)
  |> result.map_error(fn(error) {
    case error {
      template.CannotReadLayout -> CannotReadLayout
      template.CannotReadPartials -> CannotReadPartials
      template.MissingContentSlot -> MissingContentSlot
    }
  })
}

fn is_private_segment(segment: String) -> Bool {
  string.starts_with(segment, "+")
  || string.starts_with(segment, "_")
  || string.starts_with(segment, ".")
}
