import gleam/option.{type Option, None, Some}
import gleam/result
import gleam/string
import simplifile
import tom

pub const default_language = "en"

pub type Site {
  Site(name: String, url: String, description: String, language: String)
}

pub type SiteError {
  CannotReadSite
  InvalidToml
  MissingOrInvalidField(String)
  InvalidUrl
}

pub fn load(path: String) -> Result(Site, SiteError) {
  use source <- result.try(
    simplifile.read(path)
    |> result.map_error(fn(_) { CannotReadSite }),
  )
  parse(source)
}

pub fn parse(source: String) -> Result(Site, SiteError) {
  use document <- result.try(
    tom.parse(source)
    |> result.map_error(fn(_) { InvalidToml }),
  )
  use name <- result.try(required_string(document, "name"))
  use url <- result.try(required_string(document, "url"))
  use description <- result.try(required_string(document, "description"))
  use language <- result.try(optional_string(document, "language"))
  let language = case language {
    Some(value) -> value
    None -> default_language
  }
  case
    string.starts_with(url, "https://") || string.starts_with(url, "http://")
  {
    True ->
      Ok(Site(name:, url: trim_trailing_slash(url), description:, language:))
    False -> Error(InvalidUrl)
  }
}

pub fn absolute_url(site: Site, path: String) -> String {
  site.url
  <> case string.starts_with(path, "/") {
    True -> path
    False -> "/" <> path
  }
}

fn required_string(document, key: String) -> Result(String, SiteError) {
  case tom.get_string(document, [key]) {
    Ok(value) -> non_empty(value, key)
    Error(_) -> Error(MissingOrInvalidField(key))
  }
}

fn optional_string(document, key: String) -> Result(Option(String), SiteError) {
  case tom.get_string(document, [key]) {
    Ok(value) -> non_empty(value, key) |> result.map(Some)
    Error(tom.NotFound(_)) -> Ok(None)
    Error(_) -> Error(MissingOrInvalidField(key))
  }
}

fn non_empty(value: String, key: String) -> Result(String, SiteError) {
  let value = string.trim(value)
  case string.is_empty(value) {
    True -> Error(MissingOrInvalidField(key))
    False -> Ok(value)
  }
}

fn trim_trailing_slash(value: String) -> String {
  case string.ends_with(value, "/") {
    True -> string.drop_end(value, 1)
    False -> value
  }
}
