import chippy/server
import chippy/server_config
import gleam/erlang/process
import gleam/int
import gleam/io

@external(erlang, "erlang", "halt")
fn halt(code: Int) -> Nil

/// Start Chippy from the configured `HOST` and `PORT` values.
///
/// Startup validates the listener address and `site.toml` before entering the
/// long-running process. Failures become short operator-facing messages.
pub fn main() -> Nil {
  case server_config.load() {
    Error(server_config.InvalidPort(value)) ->
      stop("Invalid PORT '" <> value <> "'. Use a number from 1 to 65535.")
    Error(server_config.InvalidHost(value)) ->
      stop(
        "Invalid HOST '"
        <> value
        <> "'. Use localhost or an IPv4 address such as 127.0.0.1 or 0.0.0.0.",
      )
    Ok(config) ->
      case server_config.port_is_available(config.host, config.port) {
        False -> address_in_use(config.host, config.port)
        True ->
          case server.start(config.host, config.port) {
            Ok(_) -> process.sleep_forever()
            Error(server.InvalidSiteConfiguration(_)) ->
              stop(
                "Could not start Chippy because site.toml is missing or invalid.",
              )
            Error(server.ServerStartFailed(host, port)) ->
              address_in_use(host, port)
          }
      }
  }
}

fn address_in_use(host: String, port: Int) -> Nil {
  stop(
    "Could not listen on "
    <> host
    <> ":"
    <> int.to_string(port)
    <> ". Another process may already be using it. Try PORT="
    <> int.to_string(port + 1)
    <> " gleam run.",
  )
}

fn stop(message: String) -> Nil {
  io.println_error("Chippy: " <> message)
  halt(1)
}
