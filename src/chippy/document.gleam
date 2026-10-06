import gleam/dict
import gleam/int
import gleam/result
import gleam/string
import mork
import yamleam
import yamleam/node.{YamlBool, YamlMap, YamlString}

pub type Document {
  Document(
    title: String,
    description: String,
    published: String,
    noindex: Bool,
    markdown: String,
  )
}

pub type DocumentError {
  InvalidMetadata
}

pub fn parse(source: String) -> Result(Document, DocumentError) {
  let #(frontmatter, markdown) = mork.split_frontmatter_from_input(source)
  use metadata <- result.try(parse_metadata(frontmatter))
  use title <- result.try(required_string(metadata, "title"))
  use description <- result.try(required_string(metadata, "description"))
  use published <- result.try(required_string(metadata, "published"))
  use _ <- result.try(validate_published(published))
  use noindex <- result.try(metadata_flag(metadata, "noindex"))
  Ok(Document(title:, description:, published:, noindex:, markdown:))
}

fn parse_metadata(frontmatter: String) {
  case yamleam.parse_raw(frontmatter) {
    Ok(YamlMap(entries)) -> Ok(dict.from_list(entries))
    _ -> Error(InvalidMetadata)
  }
}

fn required_string(metadata, key: String) -> Result(String, DocumentError) {
  case dict.get(metadata, key) {
    Ok(YamlString(value)) ->
      case string.is_empty(string.trim(value)) {
        True -> Error(InvalidMetadata)
        False -> Ok(value)
      }
    _ -> Error(InvalidMetadata)
  }
}

fn validate_published(value: String) -> Result(Nil, DocumentError) {
  case string.split(value, "-") {
    [year, month, day] ->
      case
        string.length(year) == 4,
        string.length(month) == 2,
        string.length(day) == 2,
        int.parse(year),
        int.parse(month),
        int.parse(day)
      {
        True, True, True, Ok(year), Ok(month), Ok(day) ->
          case day >= 1 && day <= days_in_month(year, month) {
            True -> Ok(Nil)
            False -> Error(InvalidMetadata)
          }
        _, _, _, _, _, _ -> Error(InvalidMetadata)
      }
    _ -> Error(InvalidMetadata)
  }
}

fn days_in_month(year: Int, month: Int) -> Int {
  case month {
    1 | 3 | 5 | 7 | 8 | 10 | 12 -> 31
    4 | 6 | 9 | 11 -> 30
    2 ->
      case is_leap_year(year) {
        True -> 29
        False -> 28
      }
    _ -> 0
  }
}

fn is_leap_year(year: Int) -> Bool {
  year % 4 == 0 && { year % 100 != 0 || year % 400 == 0 }
}

fn metadata_flag(metadata, key: String) -> Result(Bool, DocumentError) {
  case dict.get(metadata, key) {
    Error(_) -> Ok(False)
    Ok(YamlBool(value)) -> Ok(value)
    Ok(YamlString(value)) ->
      case string.lowercase(value) {
        "true" -> Ok(True)
        "false" -> Ok(False)
        _ -> Error(InvalidMetadata)
      }
    _ -> Error(InvalidMetadata)
  }
}
