import gleam/list
import gleam/option.{None, Some}
import gleam/result
import gleam/string
import mork
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

pub type Document {
  Document(title: String, description: String, noindex: Bool, markdown: String)
}

pub type Route {
  Route(path: String, document: Document)
}

pub fn render(request_path: String) -> Result(String, PageError) {
  use route_directory <- result.try(route_directory(request_path))
  use markdown <- result.try(
    simplifile.read(route_directory <> "/+page.md")
    |> result.map_error(fn(_) { NotFound }),
  )
  use document <- result.try(parse_document(markdown))
  use layout <- result.try(read_layout(route_directory))
  use layout <- result.try(insert_partials(layout))

  case string.contains(layout, "{{ content }}") {
    False -> Error(MissingContentSlot)
    True -> {
      let content = document.markdown |> mork.parse |> mork.to_html
      render_layout(layout, document, content)
    }
  }
}

pub fn render_error(
  title: String,
  description: String,
  heading: String,
  message: String,
) -> Result(String, PageError) {
  use layout <- result.try(read_layout("routes"))
  use layout <- result.try(insert_partials(layout))
  let document = Document(title:, description:, noindex: True, markdown: "")
  let content =
    "<section class=\"error-page\"><p class=\"eyebrow\">Chippy</p><h1>"
    <> escape_html(heading)
    <> "</h1><p>"
    <> escape_html(message)
    <> "</p><a class=\"primary-button\" href=\"/\">Return home</a></section>"
  render_layout(layout, document, content)
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

pub fn parse_document(source: String) -> Result(Document, PageError) {
  let #(frontmatter, markdown) = mork.split_frontmatter_from_input(source)
  use title <- result.try(frontmatter_value(frontmatter, "title"))
  use description <- result.try(frontmatter_value(frontmatter, "description"))
  use noindex <- result.try(frontmatter_flag(frontmatter, "noindex"))
  Ok(Document(title:, description:, noindex:, markdown:))
}

fn render_layout(
  layout: String,
  document: Document,
  content: String,
) -> Result(String, PageError) {
  let robots = case document.noindex {
    True -> "<meta name=\"robots\" content=\"noindex\">"
    False -> ""
  }
  layout
  |> string.replace("{{ title }}", escape_html(document.title))
  |> string.replace("{{ description }}", escape_html(document.description))
  |> string.replace("{{ robots }}", robots)
  |> string.replace("{{ content }}", content)
  |> Ok
}

fn frontmatter_value(
  frontmatter: String,
  key: String,
) -> Result(String, PageError) {
  frontmatter
  |> string.split("\n")
  |> list.find_map(fn(line) {
    case string.split_once(line, on: ":") {
      Ok(#(found_key, value)) ->
        case
          string.trim(found_key) == key && !string.is_empty(string.trim(value))
        {
          True -> Ok(string.trim(value))
          False -> Error(Nil)
        }
      Error(Nil) -> Error(Nil)
    }
  })
  |> result.map_error(fn(_) { InvalidMetadata })
}

fn frontmatter_flag(
  frontmatter: String,
  key: String,
) -> Result(Bool, PageError) {
  case optional_frontmatter_value(frontmatter, key) {
    None -> Ok(False)
    Some(value) ->
      case string.lowercase(value) {
        "true" -> Ok(True)
        "false" -> Ok(False)
        _ -> Error(InvalidMetadata)
      }
  }
}

fn optional_frontmatter_value(frontmatter: String, key: String) {
  case
    frontmatter
    |> string.split("\n")
    |> list.find_map(fn(line) {
      case string.split_once(line, on: ":") {
        Ok(#(found_key, value)) ->
          case string.trim(found_key) == key {
            True -> Ok(string.trim(value))
            False -> Error(Nil)
          }
        Error(Nil) -> Error(Nil)
      }
    })
  {
    Ok(value) -> Some(value)
    Error(Nil) -> None
  }
}

fn escape_html(value: String) -> String {
  value
  |> string.replace("&", "&amp;")
  |> string.replace("<", "&lt;")
  |> string.replace(">", "&gt;")
  |> string.replace("\"", "&quot;")
  |> string.replace("'", "&#39;")
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

fn read_layout(route_directory: String) -> Result(String, PageError) {
  let local_layout = route_directory <> "/+layout.html"
  case simplifile.is_file(local_layout) {
    Ok(True) ->
      simplifile.read(local_layout)
      |> result.map_error(fn(_) { CannotReadLayout })
    _ ->
      simplifile.read("routes/+layout.html")
      |> result.map_error(fn(_) { CannotReadLayout })
  }
}

fn insert_partials(layout: String) -> Result(String, PageError) {
  use filenames <- result.try(
    simplifile.read_directory("routes/_partials")
    |> result.map_error(fn(_) { CannotReadPartials }),
  )

  filenames
  |> list.filter(fn(filename) { string.ends_with(filename, ".html") })
  |> list.try_fold(layout, fn(rendered, filename) {
    use partial <- result.try(
      simplifile.read("routes/_partials/" <> filename)
      |> result.map_error(fn(_) { CannotReadPartials }),
    )
    let name = string.drop_end(filename, 5)
    Ok(string.replace(rendered, "{{ partial:" <> name <> " }}", partial))
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

fn is_private_segment(segment: String) -> Bool {
  string.starts_with(segment, "+")
  || string.starts_with(segment, "_")
  || string.starts_with(segment, ".")
}
