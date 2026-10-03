---
title: Contact
description: Try Chippy's deliberately imaginary contact form.
published: 2026-10-03
---

<p class="eyebrow">No inbox attached</p>

# Contact

This form is a demonstration, not a way to reach anyone. Each submission
randomly succeeds or fails. Even a successful result sends no email and stores
nothing.

<!-- contact-feedback -->

<form class="contact-form" action="/contact" method="post">
  <div class="form-field">
    <label for="name">Name</label>
    <input id="name" name="name" type="text" autocomplete="name" required>
  </div>
  <div class="form-field">
    <label for="email">Email</label>
    <input id="email" name="email" type="email" autocomplete="email" required>
  </div>
  <div class="form-field">
    <label for="message">Message</label>
    <textarea id="message" name="message" rows="6" required></textarea>
  </div>
  <button class="primary-button" type="submit">Pretend to send</button>
</form>
