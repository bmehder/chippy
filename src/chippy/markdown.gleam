import mork

/// Render trusted site-authored Markdown to HTML.
///
/// Heading IDs and tables are enabled. Raw HTML remains available because
/// route files are trusted repository content rather than visitor input.
pub fn render(source: String) -> String {
  mork.configure()
  |> mork.heading_ids(True)
  |> mork.tables(True)
  |> mork.parse_with_options(source)
  |> mork.to_html
}
