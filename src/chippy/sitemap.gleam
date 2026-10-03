import chippy/document.{Document}
import chippy/page.{type Route, Route}
import gleam/list
import gleam/string

pub fn render(base_url: String, routes: List(Route)) -> String {
  let base_url = trim_trailing_slash(base_url)
  let urls =
    routes
    |> list.filter_map(fn(route) {
      let Route(path:, document:) = route
      let Document(noindex:, ..) = document
      case noindex {
        True -> Error(Nil)
        False ->
          Ok("  <url><loc>" <> escape_xml(base_url <> path) <> "</loc></url>")
      }
    })
    |> string.join("\n")

  "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<urlset xmlns=\"http://www.sitemaps.org/schemas/sitemap/0.9\">\n"
  <> urls
  <> "\n</urlset>\n"
}

fn trim_trailing_slash(value: String) -> String {
  case string.ends_with(value, "/") {
    True -> string.drop_end(value, 1)
    False -> value
  }
}

fn escape_xml(value: String) -> String {
  value
  |> string.replace("&", "&amp;")
  |> string.replace("<", "&lt;")
  |> string.replace(">", "&gt;")
  |> string.replace("\"", "&quot;")
  |> string.replace("'", "&apos;")
}
