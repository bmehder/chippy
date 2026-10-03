import chippy/markdown
import gleam/string
import gleeunit/should

pub fn enables_useful_extended_markdown_test() {
  let html =
    markdown.render(
      "# Useful heading\n\n| Feature | State |\n| --- | --- |\n| Tables | On |",
    )

  html |> string.contains("id=\"Useful-heading\"") |> should.be_true
  html |> string.contains("<table>") |> should.be_true
}
