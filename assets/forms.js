// Sends the site's forms (contact, beta application) to the form service and shows the result in the page.
// Without JavaScript the form still posts normally and the service shows its own thank-you page.
document.querySelectorAll('form.js-form').forEach(function (form) {
  form.addEventListener('submit', async function (e) {
    e.preventDefault();
    var status = form.querySelector('.form-status');
    var button = form.querySelector('button[type="submit"]');
    status.className = 'form-status';
    if (!form.checkValidity()) { form.reportValidity(); return; }
    button.disabled = true;
    status.textContent = 'Sending…';
    try {
      var r = await fetch(form.action, { method: 'POST', body: new FormData(form), headers: { Accept: 'application/json' } });
      if (!r.ok) throw new Error(String(r.status));
      form.hidden = true;
      var done = document.getElementById(form.dataset.done);
      if (done) { done.hidden = false; done.focus(); }
    } catch (err) {
      status.className = 'form-status error';
      status.textContent = "That didn't send. Please try again in a moment, or email contact@encoreaudio.co.uk.";
      button.disabled = false;
    }
  });
});
