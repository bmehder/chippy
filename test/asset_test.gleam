import chippy/asset
import chippy/route
import gleeunit/should

pub fn serves_colocated_assets_test() {
  asset.resolve("/about/notes.txt")
  |> should.equal(Ok("routes/about/notes.txt"))
  asset.resolve("/posts/gleam-or-php/gleam-or-php.webp")
  |> should.equal(Ok("routes/posts/gleam-or-php/gleam-or-php.webp"))
}

pub fn serves_global_assets_test() {
  asset.resolve("/assets/site.css")
  |> should.equal(Ok("assets/site.css"))
  asset.resolve("/assets/favicon.svg")
  |> should.equal(Ok("assets/favicon.svg"))
}

pub fn serves_generated_reference_files_test() {
  asset.resolve("/reference/")
  |> should.equal(Ok("reference/index.html"))
  asset.resolve("/reference/chippy/page.html")
  |> should.equal(Ok("reference/chippy/page.html"))
  asset.resolve("/reference/docs_config.js")
  |> should.equal(Ok("reference/docs_config.js"))
}

pub fn keeps_chippy_files_private_test() {
  asset.resolve("/+page.md") |> should.equal(Error(route.NotFound))
  asset.resolve("/_partials/header.html")
  |> should.equal(Error(route.NotFound))
}

pub fn rejects_parent_directory_segments_test() {
  asset.resolve("/../gleam.toml")
  |> should.equal(Error(route.UnsafePath))
}
