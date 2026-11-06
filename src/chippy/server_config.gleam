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

/// Read `HOST` and `PORT` from the environment.
/// Missing values use local development defaults. Invalid values return errors.
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

/// The result of a temporary TCP bind before Mist starts.
pub type PortProbe {
  Available
  /// The OS returned `eaddrinuse`, so the requested address is occupied.
  AddressInUse
  /// The bind failed for another reason. Carries the OS error name.
  BindFailed(String)
}

/// Try to bind a temporary listener and close it immediately on success.
/// This check does not reserve the address for Mist's later bind.
@external(erlang, "chippy_ffi", "probe_port")
pub fn probe_port(host: String, port: Int) -> PortProbe

/// Accept localhost or a dotted IPv4 address after trimming whitespace.
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
