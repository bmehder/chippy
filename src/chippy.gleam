import chippy/server
import chippy/server_config
import gleam/erlang/process
import gleam/int
import gleam/io

@external(erlang, "erlang", "halt")
fn halt(code: Int) -> Nil

pub fn main() -> Nil {
  case server_config.load_port() {
    Error(server_config.InvalidPort(value)) ->
      stop("Invalid PORT '" <> value <> "'. Use a number from 1 to 65535.")
    Ok(port) ->
      case server_config.port_is_available(port) {
        False -> port_in_use(port)
        True ->
          case server.start(port) {
            Ok(_) -> process.sleep_forever()
            Error(server.InvalidSiteConfiguration(_)) ->
              stop(
                "Could not start Chippy because site.toml is missing or invalid.",
              )
            Error(server.ServerStartFailed(port)) -> port_in_use(port)
          }
      }
  }
}

fn port_in_use(port: Int) -> Nil {
  stop(
    "Could not listen on port "
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
