import chippy/document
import gleeunit/should

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
