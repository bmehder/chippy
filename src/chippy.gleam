import chippy/server
import gleam/erlang/process

pub fn main() -> Nil {
  let assert Ok(_) = server.start(8000)
  process.sleep_forever()
}
