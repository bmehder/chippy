import chippy/server_config
import gleeunit/should

pub fn accepts_a_valid_server_port_test() {
  server_config.parse_port("4000") |> should.equal(Ok(4000))
}

pub fn accepts_local_and_public_server_hosts_test() {
  server_config.from_values(host: "127.0.0.1", port: "8000")
  |> should.equal(Ok(server_config.Config(host: "127.0.0.1", port: 8000)))
  server_config.from_values(host: "0.0.0.0", port: "4000")
  |> should.equal(Ok(server_config.Config(host: "0.0.0.0", port: 4000)))
}

pub fn rejects_an_invalid_server_host_test() {
  server_config.from_values(host: "example.com", port: "8000")
  |> should.equal(Error(server_config.InvalidHost("example.com")))
  server_config.from_values(host: "999.0.0.1", port: "8000")
  |> should.equal(Error(server_config.InvalidHost("999.0.0.1")))
}

pub fn rejects_an_invalid_server_port_test() {
  server_config.parse_port("0")
  |> should.equal(Error(server_config.InvalidPort("0")))
  server_config.parse_port("not-a-port")
  |> should.equal(Error(server_config.InvalidPort("not-a-port")))
}
