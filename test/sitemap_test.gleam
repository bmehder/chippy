import chippy/document
import chippy/route
import chippy/sitemap
import gleam/string
import gleeunit/should

pub fn sitemap_omits_noindex_routes_test() {
  let public =
    route.Route(
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
    route.Route(
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
