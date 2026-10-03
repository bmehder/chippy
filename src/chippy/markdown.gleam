import mork

pub fn render(source: String) -> String {
  mork.configure()
  |> mork.heading_ids(True)
  |> mork.tables(True)
  |> mork.parse_with_options(source)
  |> mork.to_html
}
