import chippy/page
import chippy/site.{type Site}
import gleam/crypto

pub type Outcome {
  Succeeded
  Failed
}

pub fn random_outcome() -> Outcome {
  case crypto.strong_random_bytes(1) {
    <<byte>> if byte < 128 -> Failed
    _ -> Succeeded
  }
}

pub fn render(site: Site, outcome: Outcome) -> Result(String, page.PageError) {
  let feedback = case outcome {
    Succeeded ->
      "<aside class=\"form-feedback form-feedback-success\" role=\"status\"><strong>Message sent. Probably.</strong><p>This demo did not send an email, but it is pretending everything worked.</p></aside>"
    Failed ->
      "<aside class=\"form-feedback form-feedback-failure\" role=\"alert\"><strong>That one failed on purpose.</strong><p>Nothing was sent. Try again and the imaginary mail server may be kinder.</p></aside>"
  }
  page.render_with("/contact", site, [#("contact-feedback", feedback)])
}
