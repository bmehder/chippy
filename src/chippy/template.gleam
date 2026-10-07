import chippy/document.{type Document}
import chippy/site.{type Site}
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/result
import gleam/string
import simplifile

/// A failure while loading or composing route layouts and root partials.
pub type TemplateError {
  CannotReadLayout
  CannotReadPartials
  MissingContentSlot
}

/// Compose the root layout with every nested layout above a route directory.
/// Root partials follow composition; one `{{ content }}` slot must remain.
pub fn load(route_directory: String) -> Result(String, TemplateError) {
  use root_layout <- result.try(
    simplifile.read("routes/+layout.html")
    |> result.map_error(fn(_) { CannotReadLayout }),
  )
  use layout <- result.try(
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
    }),
  )
  use layout <- result.try(insert_partials(layout))
  case string.contains(layout, "{{ content }}") {
    True -> Ok(layout)
    False -> Error(MissingContentSlot)
  }
}

/// Fill predefined layout slots with escaped metadata and rendered page HTML.
///
/// `content` is trusted renderer output and is not escaped. Canonical and
/// social metadata is omitted when `canonical_url` is absent, as on errors.
pub fn render(
  layout: String,
  document: Document,
  content: String,
  site: Site,
  canonical_url: Option(String),
) -> String {
  let metadata = render_metadata(site, document, canonical_url)
  layout
  |> string.replace("{{ language }}", escape_html(site.language))
  |> string.replace("{{ site_name }}", escape_html(site.name))
  |> string.replace("{{ title }}", escape_html(document.title))
  |> string.replace("{{ description }}", escape_html(document.description))
  |> string.replace("{{ metadata }}", metadata)
  |> string.replace("{{ content }}", content)
}

/// Escape text for HTML content and quoted attribute values.
pub fn escape_html(value: String) -> String {
  value
  |> string.replace("&", "&amp;")
  |> string.replace("<", "&lt;")
  |> string.replace(">", "&gt;")
  |> string.replace("\"", "&quot;")
  |> string.replace("'", "&#39;")
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

fn insert_partials(layout: String) -> Result(String, TemplateError) {
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
