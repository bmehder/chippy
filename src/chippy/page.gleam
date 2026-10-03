import chippy/site.{type Site, absolute_url}
import gleam/int
import gleam/list
import gleam/option.{type Option, None, Some}
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
  Document(
    title: String,
    description: String,
    published: String,
    noindex: Bool,
    markdown: String,
  )
}

pub type Route {
  Route(path: String, document: Document)
}

pub fn render(request_path: String, site: Site) -> Result(String, PageError) {
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
      use markdown <- result.try(insert_collection(
        document.markdown,
        route_directory,
        request_path,
      ))
      let content = markdown |> mork.parse |> mork.to_html
      render_layout(
        layout,
        document,
        content,
        site,
        Some(absolute_url(site, request_path)),
      )
    }
  }
}

pub fn render_error(
  site: Site,
  title: String,
  description: String,
  heading: String,
  message: String,
) -> Result(String, PageError) {
  use layout <- result.try(read_layout("routes"))
  use layout <- result.try(insert_partials(layout))
  let document =
    Document(title:, description:, published: "", noindex: True, markdown: "")
  let content =
    "<section class=\"error-page\"><p class=\"eyebrow\">Chippy</p><h1>"
    <> escape_html(heading)
    <> "</h1><p>"
    <> escape_html(message)
    <> "</p><a class=\"primary-button\" href=\"/\">Return home</a></section>"
  render_layout(layout, document, content, site, None)
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
  use published <- result.try(frontmatter_value(frontmatter, "published"))
  use _ <- result.try(validate_published(published))
  use noindex <- result.try(frontmatter_flag(frontmatter, "noindex"))
  Ok(Document(title:, description:, published:, noindex:, markdown:))
}

fn validate_published(value: String) -> Result(Nil, PageError) {
  case string.split(value, "-") {
    [year, month, day] ->
      case
        string.length(year) == 4,
        string.length(month) == 2,
        string.length(day) == 2,
        int.parse(year),
        int.parse(month),
        int.parse(day)
      {
        True, True, True, Ok(_), Ok(month), Ok(day)
          if month >= 1 && month <= 12 && day >= 1 && day <= 31
        -> Ok(Nil)
        _, _, _, _, _, _ -> Error(InvalidMetadata)
      }
    _ -> Error(InvalidMetadata)
  }
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
    <> escape_html(route.document.published)
    <> "\">"
    <> escape_html(route.document.published)
    <> "</time><h2><a href=\""
    <> escape_html(route.path)
    <> "\">"
    <> escape_html(route.document.title)
    <> "</a></h2><p>"
    <> escape_html(route.document.description)
    <> "</p></article>"
  })
  |> string.join("\n")
  |> fn(entries) { "<section class=\"collection\">" <> entries <> "</section>" }
}

fn render_layout(
  layout: String,
  document: Document,
  content: String,
  site: Site,
  canonical_url: Option(String),
) -> Result(String, PageError) {
  let metadata = render_metadata(site, document, canonical_url)
  layout
  |> string.replace("{{ language }}", escape_html(site.language))
  |> string.replace("{{ site_name }}", escape_html(site.name))
  |> string.replace("{{ title }}", escape_html(document.title))
  |> string.replace("{{ description }}", escape_html(document.description))
  |> string.replace("{{ metadata }}", metadata)
  |> string.replace("{{ content }}", content)
  |> Ok
}

fn render_metadata(
  site: Site,
  document: Document,
  canonical_url: Option(String),
) -> String {
  let robots = case document.noindex {
    True -> "    <meta name=\"robots\" content=\"noindex\">\n"
    False -> ""
  }
  case canonical_url {
    None -> robots
    Some(canonical_url) -> {
      let canonical_url = escape_html(canonical_url)
      let title = escape_html(document.title)
      let description = escape_html(document.description)
      let site_name = escape_html(site.name)
      robots
      <> "    <link rel=\"canonical\" href=\""
      <> canonical_url
      <> "\">\n"
      <> "    <meta property=\"og:site_name\" content=\""
      <> site_name
      <> "\">\n"
      <> "    <meta property=\"og:type\" content=\"website\">\n"
      <> "    <meta property=\"og:title\" content=\""
      <> title
      <> "\">\n"
      <> "    <meta property=\"og:description\" content=\""
      <> description
      <> "\">\n"
      <> "    <meta property=\"og:url\" content=\""
      <> canonical_url
      <> "\">\n"
      <> "    <meta name=\"twitter:card\" content=\"summary\">\n"
      <> "    <meta name=\"twitter:title\" content=\""
      <> title
      <> "\">\n"
      <> "    <meta name=\"twitter:description\" content=\""
      <> description
      <> "\">"
    }
  }
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
  use root_layout <- result.try(
    simplifile.read("routes/+layout.html")
    |> result.map_error(fn(_) { CannotReadLayout }),
  )
  route_directory
  |> layout_directories
  |> list.drop(1)
  |> list.try_fold(root_layout, fn(rendered, directory) {
    let filename = directory <> "/+layout.html"
    case simplifile.is_file(filename) {
      Ok(False) -> Ok(rendered)
      Ok(True) -> {
        use nested <- result.try(
          simplifile.read(filename)
          |> result.map_error(fn(_) { CannotReadLayout }),
        )
        Ok(string.replace(rendered, "{{ content }}", nested))
      }
      Error(_) -> Error(CannotReadLayout)
    }
  })
}

fn layout_directories(route_directory: String) -> List(String) {
  let #(_, directories) =
    route_directory
    |> string.split("/")
    |> list.fold(#("", []), fn(state, segment) {
      let #(parent, found) = state
      let directory = case parent {
        "" -> segment
        _ -> parent <> "/" <> segment
      }
      #(directory, list.append(found, [directory]))
    })
  directories
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
