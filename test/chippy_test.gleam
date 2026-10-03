import chippy/favicon
import chippy/page
import chippy/sitemap
import gleam/list
import gleam/string
import gleeunit
import gleeunit/should

pub fn main() -> Nil {
  gleeunit.main()
}

pub fn renders_the_home_page_test() {
  let assert Ok(html) = page.render("/")

  html |> string.contains("<!doctype html>") |> should.be_true
  html
  |> string.contains(
    "<h1>Server-side rendered content. <em>Markdown instead of a database.</em></h1>",
  )
  |> should.be_true
  html
  |> string.contains("Server-rendered Markdown in Gleam")
  |> should.be_true
  html |> string.contains("{{ content }}") |> should.be_false
  html |> string.contains("{{ robots }}") |> should.be_false
  html
  |> string.contains("<title>Server-side rendered Markdown — Chippy</title>")
  |> should.be_true
}

pub fn parses_optional_noindex_metadata_test() {
  let source =
    "---\ntitle: Private\ndescription: Hidden from search\nnoindex: true\n---\n\nSecret"
  let assert Ok(page.Document(noindex:, ..)) = page.parse_document(source)

  noindex |> should.be_true
}

pub fn rejects_invalid_noindex_metadata_test() {
  let source =
    "---\ntitle: Invalid\ndescription: Invalid flag\nnoindex: sometimes\n---\n"

  page.parse_document(source)
  |> should.equal(Error(page.InvalidMetadata))
}

pub fn discovers_directory_routes_test() {
  let assert Ok(routes) = page.discover_routes()
  let paths =
    list.map(routes, fn(route) {
      let page.Route(path:, ..) = route
      path
    })

  paths |> list.contains("/") |> should.be_true
  paths |> list.contains("/about") |> should.be_true
  paths |> list.contains("/posts/inside-chippy") |> should.be_true
}

pub fn sitemap_omits_noindex_routes_test() {
  let public =
    page.Route(
      path: "/about",
      document: page.Document(
        title: "About",
        description: "About",
        noindex: False,
        markdown: "",
      ),
    )
  let private =
    page.Route(
      path: "/private",
      document: page.Document(
        title: "Private",
        description: "Private",
        noindex: True,
        markdown: "",
      ),
    )
  let xml = sitemap.render("https://example.com/", [private, public])

  xml |> string.contains("https://example.com/about") |> should.be_true
  xml |> string.contains("private") |> should.be_false
}

pub fn renders_errors_with_the_site_layout_test() {
  let assert Ok(html) =
    page.render_error(
      "Page not found",
      "There is no page at this address.",
      "Page not found",
      "There is no page at this address.",
    )

  html
  |> string.contains("<meta name=\"robots\" content=\"noindex\">")
  |> should.be_true
  html |> string.contains("class=\"error-page\"") |> should.be_true
}

pub fn provides_a_fallback_favicon_test() {
  favicon.svg |> string.contains("<svg") |> should.be_true
  favicon.svg |> string.contains("#a8dc7c") |> should.be_true
}

pub fn serves_colocated_assets_test() {
  page.asset_path("/about/notes.txt")
  |> should.equal(Ok("routes/about/notes.txt"))
}

pub fn serves_global_assets_test() {
  page.asset_path("/assets/site.css")
  |> should.equal(Ok("assets/site.css"))
}

pub fn maps_directories_to_routes_test() {
  let assert Ok(html) = page.render("/about")

  html |> string.contains("<h1>About Chippy</h1>") |> should.be_true
  html |> string.contains("<title>About — Chippy</title>") |> should.be_true
}

pub fn keeps_chippy_files_private_test() {
  page.asset_path("/+page.md") |> should.equal(Error(page.NotFound))
  page.asset_path("/_partials/header.html")
  |> should.equal(Error(page.NotFound))
}

pub fn rejects_parent_directory_segments_test() {
  page.asset_path("/../gleam.toml")
  |> should.equal(Error(page.UnsafePath))
}
