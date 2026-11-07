import chippy/server
import chippy/server_config
import gleam/erlang/process
import gleam/int
import gleam/io
import site

@external(erlang, "erlang", "halt")
fn halt(code: Int) -> Nil

/// Start Chippy from the configured `HOST` and `PORT` values.
///
/// Startup validates the listener address and `site.toml` before entering the
/// long-running process. Failures become short operator-facing messages.
pub fn main() -> Nil {
  case server_config.load() {
    Error(server_config.InvalidPort(value)) ->
      fail_startup(
        "Invalid PORT '" <> value <> "'. Use a number from 1 to 65535.",
      )
    Error(server_config.InvalidHost(value)) ->
      fail_startup(
        "Invalid HOST '"
        <> value
        <> "'. Use localhost or an IPv4 address such as 127.0.0.1 or 0.0.0.0.",
      )
    Ok(config) ->
      case server_config.probe_port(config.host, config.port) {
        server_config.AddressInUse -> address_in_use(config.host, config.port)
        server_config.BindFailed(reason) ->
          fail_startup(
            "Could not listen on "
            <> config.host
            <> ":"
            <> int.to_string(config.port)
            <> " ("
            <> reason
            <> ").",
          )
        server_config.Available ->
          case
            server.start_with(
              host: config.host,
              port: config.port,
              handler: site.handle,
            )
          {
            Ok(_) -> process.sleep_forever()
            Error(server.InvalidSiteConfiguration(_)) ->
              fail_startup(
                "Could not start Chippy because site.toml is missing or invalid.",
              )
            Error(server.ServerStartFailed(host, port)) ->
              fail_startup(
                "Could not start Chippy on "
                <> host
                <> ":"
                <> int.to_string(port)
                <> ".",
              )
          }
      }
  }
}

fn address_in_use(host: String, port: Int) -> Nil {
  fail_startup(
    "Could not listen on "
    <> host
    <> ":"
    <> int.to_string(port)
    <> ". Another process may already be using it. Try PORT="
    <> int.to_string(port + 1)
    <> " gleam run.",
  )
}

fn fail_startup(message: String) -> Nil {
  io.println_error("Chippy: " <> message)
  halt(1)
}
