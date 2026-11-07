import chippy/document.{type Document, Document}
import chippy/markdown
import chippy/route.{type Route}
import chippy/site.{type Site, absolute_url}
import chippy/template
import gleam/list
import gleam/option.{None, Some}
import gleam/result
import gleam/string
import simplifile

/// A filesystem, path-safety, metadata, or template rendering failure.
/// The HTTP boundary translates these values into response status codes.
pub type PageError {
  NotFound
  UnsafePath
  InvalidMetadata
  CannotDiscoverRoutes
  CannotReadLayout
  CannotReadPartials
  MissingContentSlot
}

/// Render a request path as a complete HTML document.
///
/// Paths map to `routes/<path>/+page.md`; layouts compose from the route root
/// downward, and content is read afresh on every request.
pub fn render(request_path: String, site: Site) -> Result(String, PageError) {
  render_with(request_path:, site:, insertions: [])
}

/// Render a page after applying named HTML insertions to its Markdown source.
///
/// An insertion named `notice` replaces `<!-- notice -->`. This narrow trusted
/// extension point supports dynamic server responses without a template DSL.
pub fn render_with(
  request_path request_path: String,
  site site: Site,
  insertions insertions: List(#(String, String)),
) -> Result(String, PageError) {
  use route_directory <- result.try(
    route.route_directory(request_path) |> result.map_error(from_route_error),
  )
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
  use markdown <- result.try(
    template.insert_partials(markdown)
    |> result.map_error(fn(_) { CannotReadPartials }),
  )
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

/// Render a noindexed error document through the site's root presentation.
/// The heading and message also supply the page title and description.
/// The caller remains responsible for choosing the HTTP status code.
pub fn render_error(
  site site: Site,
  heading heading: String,
  message message: String,
) -> Result(String, PageError) {
  use layout <- result.try(load_template("routes"))
  let document =
    Document(
      title: heading,
      description: message,
      published: "",
      noindex: True,
      markdown: "",
    )
  let content =
    "<section class=\"error-page\"><p class=\"eyebrow\">Chippy</p><h1>"
    <> template.escape_html(heading)
    <> "</h1><p>"
    <> template.escape_html(message)
    <> "</p><a class=\"primary-button\" href=\"/\">Return home</a></section>"
  Ok(template.render(layout, document, content, site, None))
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
      use entries <- result.try(
        route.discover_collection(directory, route_path)
        |> result.map_error(from_route_error),
      )
      Ok(string.replace(markdown, "{{ collection }}", collection_html(entries)))
    }
  }
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

fn from_route_error(error: route.RouteError) -> PageError {
  case error {
    route.NotFound -> NotFound
    route.UnsafePath -> UnsafePath
    route.InvalidMetadata -> InvalidMetadata
    route.CannotDiscoverRoutes -> CannotDiscoverRoutes
  }
}
