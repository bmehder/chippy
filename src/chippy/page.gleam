import gleam/list
import gleam/result
import gleam/string
import mork
import simplifile

pub type PageError {
  NotFound
  UnsafePath
  InvalidMetadata
  CannotReadLayout
  CannotReadPartials
  MissingContentSlot
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
      layout
      |> string.replace("{{ title }}", escape_html(document.title))
      |> string.replace("{{ description }}", escape_html(document.description))
      |> string.replace("{{ content }}", content)
      |> Ok
    }
  }
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

type Document {
  Document(title: String, description: String, markdown: String)
}

fn parse_document(source: String) -> Result(Document, PageError) {
  let #(frontmatter, markdown) = mork.split_frontmatter_from_input(source)
  use title <- result.try(frontmatter_value(frontmatter, "title"))
  use description <- result.try(frontmatter_value(frontmatter, "description"))
  Ok(Document(title:, description:, markdown:))
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

fn escape_html(value: String) -> String {
  value
  |> string.replace("&", "&amp;")
  |> string.replace("<", "&lt;")
  |> string.replace(">", "&gt;")
  |> string.replace("\"", "&quot;")
  |> string.replace("'", "&#39;")
}

fn route_directory(request_path: String) -> Result(String, PageError) {
  safe_relative_path(request_path)
  |> result.map(fn(relative) {
    case relative {
      "" -> "routes"
      _ -> "routes/" <> relative
    }
  })
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
