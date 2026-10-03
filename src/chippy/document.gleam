import gleam/int
import gleam/list
import gleam/option.{None, Some}
import gleam/result
import gleam/string
import mork

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
  use title <- result.try(frontmatter_value(frontmatter, "title"))
  use description <- result.try(frontmatter_value(frontmatter, "description"))
  use published <- result.try(frontmatter_value(frontmatter, "published"))
  use _ <- result.try(validate_published(published))
  use noindex <- result.try(frontmatter_flag(frontmatter, "noindex"))
  Ok(Document(title:, description:, published:, noindex:, markdown:))
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
        True, True, True, Ok(_), Ok(month), Ok(day)
          if month >= 1 && month <= 12 && day >= 1 && day <= 31
        -> Ok(Nil)
        _, _, _, _, _, _ -> Error(InvalidMetadata)
      }
    _ -> Error(InvalidMetadata)
  }
}

fn frontmatter_value(
  frontmatter: String,
  key: String,
) -> Result(String, DocumentError) {
  frontmatter
  |> string.split("\n")
  |> list.find_map(fn(line) {
    case string.split_once(line, on: ":") {
      Ok(#(found_key, value)) ->
        case
          string.trim(found_key) == key && !string.is_empty(string.trim(value))
        {
          True -> Ok(string.trim(value))
          False -> Error(Nil)
        }
      Error(Nil) -> Error(Nil)
    }
  })
  |> result.map_error(fn(_) { InvalidMetadata })
}

fn frontmatter_flag(
  frontmatter: String,
  key: String,
) -> Result(Bool, DocumentError) {
  case optional_frontmatter_value(frontmatter, key) {
    None -> Ok(False)
    Some(value) ->
      case string.lowercase(value) {
        "true" -> Ok(True)
        "false" -> Ok(False)
        _ -> Error(InvalidMetadata)
      }
  }
}

fn optional_frontmatter_value(frontmatter: String, key: String) {
  case
    frontmatter
    |> string.split("\n")
    |> list.find_map(fn(line) {
      case string.split_once(line, on: ":") {
        Ok(#(found_key, value)) ->
          case string.trim(found_key) == key {
            True -> Ok(string.trim(value))
            False -> Error(Nil)
          }
        Error(Nil) -> Error(Nil)
      }
    })
  {
    Ok(value) -> Some(value)
    Error(Nil) -> None
  }
}
