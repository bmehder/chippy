import chippy/document
import chippy/page
import chippy/sitemap
import gleam/string
import gleeunit/should

pub fn sitemap_omits_noindex_routes_test() {
  let public =
    page.Route(
      path: "/about",
      document: document.Document(
        title: "About",
        description: "About",
        published: "2026-10-03",
        noindex: False,
        markdown: "",
      ),
    )
  let private =
    page.Route(
      path: "/private",
      document: document.Document(
        title: "Private",
        description: "Private",
        published: "2026-10-03",
        noindex: True,
        markdown: "",
      ),
    )
  let xml = sitemap.render("https://example.com/", [private, public])
  xml |> string.contains("https://example.com/about") |> should.be_true
  xml |> string.contains("private") |> should.be_false
}
