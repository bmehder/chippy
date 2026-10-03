import envoy
import gleam/int

pub const default_port = 8000

pub type ConfigError {
  InvalidPort(String)
}

pub fn load_port() -> Result(Int, ConfigError) {
  case envoy.get("PORT") {
    Ok(value) -> parse_port(value)
    Error(_) -> Ok(default_port)
  }
}

pub fn parse_port(value: String) -> Result(Int, ConfigError) {
  case int.parse(value) {
    Ok(port) if port > 0 && port <= 65_535 -> Ok(port)
    _ -> Error(InvalidPort(value))
  }
}

@external(erlang, "chippy_ffi", "port_is_available")
pub fn port_is_available(port: Int) -> Bool
