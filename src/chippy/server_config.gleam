import envoy
import gleam/int
import gleam/list
import gleam/result
import gleam/string

/// The local development port used when `PORT` is absent.
pub const default_port = 8000

/// The loopback listener used when `HOST` is absent.
/// Deployments generally override this with `0.0.0.0`.
pub const default_host = "127.0.0.1"

/// A validated IPv4-or-localhost listener address.
pub type Config {
  Config(host: String, port: Int)
}

/// Invalid operator input read from `HOST` or `PORT`.
pub type ConfigError {
  InvalidPort(String)
  InvalidHost(String)
}

/// Read listener configuration with local-safe defaults.
pub fn load() -> Result(Config, ConfigError) {
  from_values(
    host: envoy.get("HOST") |> result.unwrap(default_host),
    port: envoy.get("PORT") |> result.unwrap(int.to_string(default_port)),
  )
}

/// Validate explicit host and port strings without reading the environment.
/// This pure entry point keeps configuration behavior straightforward to test.
pub fn from_values(host host_value: String, port port_value: String) {
  use host <- result.try(parse_host(host_value))
  use port <- result.try(parse_port(port_value))
  Ok(Config(host:, port:))
}

/// Parse a TCP port in the inclusive range 1 through 65535.
pub fn parse_port(value: String) -> Result(Int, ConfigError) {
  case int.parse(value) {
    Ok(port) if port > 0 && port <= 65_535 -> Ok(port)
    _ -> Error(InvalidPort(value))
  }
}

/// Check whether the requested address can be bound before Mist starts.
/// Availability can still change between this Erlang preflight and real bind.
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
