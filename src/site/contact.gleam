import chippy/page
import chippy/server
import chippy/site.{type Site}
import gleam/crypto
import gleam/http/request.{type Request}
import gleam/http/response.{type Response}
import mist

/// The deliberately simulated result of the demo contact form.
/// Neither outcome sends or stores the submitted data.
pub type Outcome {
  /// The initial GET displays the form with no feedback.
  NotSubmitted
  Succeeded
  Failed
}

/// Choose a contact outcome using strong random bytes.
/// This randomness is theatre for the demo, not a delivery guarantee.
pub fn random_outcome() -> Outcome {
  case crypto.strong_random_bytes(1) {
    <<byte>> if byte < 128 -> Failed
    _ -> Succeeded
  }
}

/// Render the contact route with accessible feedback for a known outcome.
/// Feedback uses the page renderer's named-insertion extension point.
pub fn render(site: Site, outcome: Outcome) -> Result(String, page.PageError) {
  let feedback = case outcome {
    NotSubmitted -> ""
    Succeeded ->
      "<aside class=\"form-feedback form-feedback-success\" role=\"status\"><strong>Message sent. Probably.</strong><p>This demo did not send an email, but it is pretending everything worked.</p></aside>"
    Failed ->
      "<aside class=\"form-feedback form-feedback-failure\" role=\"alert\"><strong>That one failed on purpose.</strong><p>Nothing was sent. Try again and the imaginary mail server may be kinder.</p></aside>"
  }
  page.render_with(request_path: "/contact", site:, insertions: [
    #("contact-feedback", feedback),
  ])
}

/// Render the initial form with an explicitly empty feedback insertion.
pub fn show(site: Site) -> Response(mist.ResponseData) {
  respond(site, render(site, NotSubmitted))
}

/// Read a contact submission and render the demo feedback.
pub fn handle(
  request: Request(mist.Connection),
  site: Site,
) -> Response(mist.ResponseData) {
  case mist.read_body(request, max_body_limit: 64_000) {
    Ok(_) -> {
      let outcome = random_outcome()
      respond(site, render(site, outcome))
    }
    Error(_) ->
      server.error_response(
        site:,
        status: 400,
        heading: "Invalid submission",
        message: "The contact form submission could not be read.",
      )
  }
}

fn respond(
  site: Site,
  rendered: Result(String, page.PageError),
) -> Response(mist.ResponseData) {
  case rendered {
    Ok(html) -> server.html_response(200, html)
    Error(_) ->
      server.error_response(
        site:,
        status: 500,
        heading: "Rendering failed",
        message: "Chippy could not render the contact response.",
      )
  }
}
