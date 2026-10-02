import chippy/page
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
  |> string.contains("<h1>A website should feel like <em>a website.</em></h1>")
  |> should.be_true
  html |> string.contains("Made with Markdown") |> should.be_true
  html |> string.contains("{{ content }}") |> should.be_false
  html
  |> string.contains(
    "<title>A website should feel like a website — Chippy</title>",
  )
  |> should.be_true
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
