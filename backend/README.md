# Newsletter backend (placeholder)

This folder shows two options:

1) **Quick local CSV** using Python (Flask):
   - `pip install flask`
   - `python newsletter_server.py`
   - The landing page can POST to `http://localhost:5000/subscribe`.

2) **Static fallback**:
   - The landing stores signups in browser `localStorage` if the backend is offline.

Connect Mailchimp/ConvertKit by replacing fetch URL in `landing/script.js`.
