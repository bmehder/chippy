import chippy/page
import gleam/list
import gleam/string
import gleeunit/should
import test_support

pub fn renders_the_home_page_test() {
  let assert Ok(html) = page.render("/", test_support.demo_site())
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
  html |> string.contains("{{ metadata }}") |> should.be_false
  html |> string.contains("<html lang=\"en\">") |> should.be_true
  html
  |> string.contains(
    "<link rel=\"canonical\" href=\"https://chippy.example/\">",
  )
  |> should.be_true
  html
  |> string.contains("<meta property=\"og:site_name\" content=\"Chippy\">")
  |> should.be_true
  html
  |> string.contains("<title>Server-side rendered Markdown — Chippy</title>")
  |> should.be_true
  html |> string.contains("class=\"mobile-menu\"") |> should.be_true
  html
  |> string.contains("aria-label=\"Mobile navigation\"")
  |> should.be_true
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
  paths |> list.contains("/contact") |> should.be_true
  paths |> list.contains("/posts/gleam-or-php") |> should.be_true
  paths |> list.contains("/posts/inside-chippy") |> should.be_true
  paths |> list.contains("/posts/request-time-rendering") |> should.be_true
  paths |> list.contains("/portable") |> should.be_true
}

pub fn renders_the_shared_portable_page_test() {
  let assert Ok(html) = page.render("/portable", test_support.demo_site())
  html
  |> string.contains("<title>A portable page — Chippy</title>")
  |> should.be_true
  html
  |> string.contains("Markdown works. We build around that.")
  |> should.be_true
  html
  |> string.contains("This nested title is additional metadata.")
  |> should.be_false
}

pub fn renders_errors_with_the_site_layout_test() {
  let assert Ok(html) =
    page.render_error(
      test_support.demo_site(),
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

pub fn serves_colocated_assets_test() {
  page.asset_path("/about/notes.txt")
  |> should.equal(Ok("routes/about/notes.txt"))
  page.asset_path("/posts/gleam-or-php/gleam-or-php.webp")
  |> should.equal(Ok("routes/posts/gleam-or-php/gleam-or-php.webp"))
}

pub fn serves_global_assets_test() {
  page.asset_path("/assets/site.css")
  |> should.equal(Ok("assets/site.css"))
  page.asset_path("/assets/favicon.svg")
  |> should.equal(Ok("assets/favicon.svg"))
}

pub fn serves_generated_reference_files_test() {
  page.asset_path("/reference/")
  |> should.equal(Ok("reference/index.html"))
  page.asset_path("/reference/chippy/page.html")
  |> should.equal(Ok("reference/chippy/page.html"))
  page.asset_path("/reference/docs_config.js")
  |> should.equal(Ok("reference/docs_config.js"))
}

pub fn maps_directories_to_routes_test() {
  let assert Ok(html) = page.render("/about", test_support.demo_site())
  html
  |> string.contains("<h1 id=\"About-Chippy\">About Chippy</h1>")
  |> should.be_true
  html |> string.contains("<title>About — Chippy</title>") |> should.be_true
}

pub fn renders_a_collection_from_child_routes_test() {
  let assert Ok(html) = page.render("/posts", test_support.demo_site())
  html |> string.contains("class=\"collection\"") |> should.be_true
  html
  |> string.contains("href=\"/posts/gleam-or-php\"")
  |> should.be_true
  html
  |> string.contains("href=\"/posts/inside-chippy\"")
  |> should.be_true
  html
  |> string.contains("href=\"/posts/request-time-rendering\"")
  |> should.be_true
  html
  |> string.contains("<time datetime=\"2026-10-03\">")
  |> should.be_true
  html |> string.contains("{{ collection }}") |> should.be_false
}

pub fn composes_nested_route_layouts_test() {
  let assert Ok(index) = page.render("/posts", test_support.demo_site())
  let assert Ok(article) =
    page.render("/posts/inside-chippy", test_support.demo_site())
  let assert Ok(comparison) =
    page.render("/posts/gleam-or-php", test_support.demo_site())
  let assert Ok(about) = page.render("/about", test_support.demo_site())
  index |> string.contains("class=\"posts-layout\"") |> should.be_true
  index |> string.contains("{{ content }}") |> should.be_false
  article |> string.contains("class=\"posts-layout\"") |> should.be_true
  article |> string.contains("<!doctype html>") |> should.be_true
  comparison |> string.contains("class=\"posts-layout\"") |> should.be_true
  about |> string.contains("class=\"posts-layout\"") |> should.be_false
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
