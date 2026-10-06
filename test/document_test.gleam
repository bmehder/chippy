import chippy/document
import gleam/string
import gleeunit/should
import simplifile

pub fn parses_the_shared_portable_document_test() {
  let assert Ok(source) = simplifile.read("routes/portable/+page.md")
  let assert Ok(document.Document(
    title:,
    description:,
    published:,
    markdown:,
    ..,
  )) = document.parse(source)

  title |> should.equal("A portable page")
  description
  |> should.equal(
    "The same document can supply content to three independent projects.",
  )
  published |> should.equal("2026-10-06")
  markdown
  |> string.contains("Markdown works. We build around that.")
  |> should.be_true
}

pub fn normalizes_plain_and_quoted_core_strings_test() {
  let plain =
    "---\ntitle: Page\ndescription: Summary\npublished: 2024-02-29\n---\n"
  let quoted =
    "---\ntitle: \"Page\"\ndescription: 'Summary'\npublished: \"2024-02-29\"\n---\n"
  let assert Ok(document.Document(
    title: plain_title,
    description: plain_description,
    published: plain_published,
    ..,
  )) = document.parse(plain)
  let assert Ok(document.Document(
    title: quoted_title,
    description: quoted_description,
    published: quoted_published,
    ..,
  )) = document.parse(quoted)

  quoted_title |> should.equal(plain_title)
  quoted_description |> should.equal(plain_description)
  quoted_published |> should.equal(plain_published)
}

pub fn ignores_nested_recognized_names_in_additional_metadata_test() {
  let source =
    "---\ncustom:\n  title: Nested title\n  description: Nested description\n  published: 2026-02-31\n  noindex: invalid\ntitle: Top-level title\ndescription: Top-level description\npublished: 2026-10-06\n---\n"
  let assert Ok(document.Document(
    title:,
    description:,
    published:,
    noindex:,
    ..,
  )) = document.parse(source)

  title |> should.equal("Top-level title")
  description |> should.equal("Top-level description")
  published |> should.equal("2026-10-06")
  noindex |> should.be_false
}

pub fn parses_optional_noindex_metadata_test() {
  let source =
    "---\ntitle: Private\ndescription: Hidden from search\npublished: 2026-10-03\nnoindex: true\n---\n\nSecret"
  let assert Ok(document.Document(noindex:, ..)) = document.parse(source)
  noindex |> should.be_true
}

pub fn rejects_invalid_noindex_metadata_test() {
  let source =
    "---\ntitle: Invalid\ndescription: Invalid flag\npublished: 2026-10-03\nnoindex: sometimes\n---\n"
  document.parse(source) |> should.equal(Error(document.InvalidMetadata))
}

pub fn requires_published_metadata_test() {
  let source = "---\ntitle: Missing date\ndescription: No date\n---\n"
  document.parse(source) |> should.equal(Error(document.InvalidMetadata))
}

pub fn rejects_invalid_published_metadata_test() {
  let source =
    "---\ntitle: Bad date\ndescription: Bad date\npublished: October 3\n---\n"
  document.parse(source) |> should.equal(Error(document.InvalidMetadata))
}

pub fn validates_calendar_date_semantics_test() {
  let leap_day =
    "---\ntitle: Leap day\ndescription: Valid date\npublished: 2024-02-29\n---\n"
  let non_leap_day =
    "---\ntitle: Not a leap day\ndescription: Invalid date\npublished: 2026-02-29\n---\n"
  let short_april =
    "---\ntitle: Long April\ndescription: Invalid date\npublished: 2026-04-31\n---\n"

  let assert Ok(_) = document.parse(leap_day)
  document.parse(non_leap_day)
  |> should.equal(Error(document.InvalidMetadata))
  document.parse(short_april)
  |> should.equal(Error(document.InvalidMetadata))
}
