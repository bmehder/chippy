import envoy
import gleam/int
import gleam/list
import gleam/result
import gleam/string

pub const default_port = 8000

pub const default_host = "127.0.0.1"

pub type Config {
  Config(host: String, port: Int)
}

pub type ConfigError {
  InvalidPort(String)
  InvalidHost(String)
}

pub fn load() -> Result(Config, ConfigError) {
  from_values(
    host: envoy.get("HOST") |> result.unwrap(default_host),
    port: envoy.get("PORT") |> result.unwrap(int.to_string(default_port)),
  )
}

pub fn from_values(host host_value: String, port port_value: String) {
  use host <- result.try(parse_host(host_value))
  use port <- result.try(parse_port(port_value))
  Ok(Config(host:, port:))
}

pub fn parse_port(value: String) -> Result(Int, ConfigError) {
  case int.parse(value) {
    Ok(port) if port > 0 && port <= 65_535 -> Ok(port)
    _ -> Error(InvalidPort(value))
  }
}

@external(erlang, "chippy_ffi", "port_is_available")
pub fn port_is_available(host: String, port: Int) -> Bool

fn parse_host(value: String) -> Result(String, ConfigError) {
  let value = string.trim(value)
  case value {
    "localhost" -> Ok(value)
    _ ->
      case string.split(value, ".") {
        [_, _, _, _] as segments ->
          case
            list.all(segments, fn(segment) {
              case int.parse(segment) {
                Ok(number) -> number >= 0 && number <= 255
                Error(_) -> False
              }
            })
          {
            True -> Ok(value)
            False -> Error(InvalidHost(value))
          }
        _ -> Error(InvalidHost(value))
      }
  }
}
