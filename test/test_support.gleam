import chippy/site

pub fn demo_site() -> site.Site {
  site.Site(
    name: "Chippy",
    url: "https://chippy.example",
    description: "A Markdown website.",
    language: "en",
  )
}
