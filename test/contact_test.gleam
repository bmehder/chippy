import chippy/contact
import chippy/page
import gleam/string
import gleeunit/should
import test_support

pub fn renders_the_contact_form_without_feedback_test() {
  let assert Ok(html) = page.render("/contact", test_support.demo_site())
  html |> string.contains("action=\"/contact\"") |> should.be_true
  html |> string.contains("method=\"post\"") |> should.be_true
  html |> string.contains("form-feedback") |> should.be_false
}

pub fn renders_both_simulated_contact_outcomes_test() {
  let assert Ok(success) =
    contact.render(test_support.demo_site(), contact.Succeeded)
  let assert Ok(failure) =
    contact.render(test_support.demo_site(), contact.Failed)
  success |> string.contains("form-feedback-success") |> should.be_true
  success |> string.contains("did not send an email") |> should.be_true
  failure |> string.contains("form-feedback-failure") |> should.be_true
  failure |> string.contains("Nothing was sent") |> should.be_true
}
