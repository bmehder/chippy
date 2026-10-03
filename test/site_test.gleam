import chippy/site
import gleeunit/should

pub fn site_configuration_defaults_to_english_test() {
  let source =
    "name = \"Example\"\nurl = \"https://example.com/\"\ndescription = \"An example site.\""
  let assert Ok(configuration) = site.parse(source)
  configuration.language |> should.equal("en")
  configuration.url |> should.equal("https://example.com")
}

pub fn site_configuration_can_override_language_test() {
  let source =
    "name = \"Example\"\nurl = \"https://example.com\"\ndescription = \"An example site.\"\nlanguage = \"nl\""
  let assert Ok(configuration) = site.parse(source)
  configuration.language |> should.equal("nl")
}

pub fn site_configuration_requires_an_absolute_url_test() {
  let source =
    "name = \"Example\"\nurl = \"example.com\"\ndescription = \"An example site.\""
  site.parse(source) |> should.equal(Error(site.InvalidUrl))
}
