
// Simple newsletter: posts to backend or stores locally.
const form = document.getElementById('newsletter-form');
const msg = document.getElementById('newsletter-msg');

form?.addEventListener('submit', async (e) => {
  e.preventDefault();
  const email = document.getElementById('email').value.trim();
  if(!email){ return }
  try{
    const res = await fetch('../backend/subscribe_local.json', {
      method:'POST',
      headers:{'Content-Type':'application/json'},
      body: JSON.stringify({ email, ts: new Date().toISOString() })
    });
    if(res.ok){
      msg.textContent = "Dziękujemy! Sprawdź skrzynkę.";
    } else {
      // fallback to localStorage
      const list = JSON.parse(localStorage.getItem('fundmind_newsletter')||'[]');
      list.push({email, ts: new Date().toISOString()});
      localStorage.setItem('fundmind_newsletter', JSON.stringify(list));
      msg.textContent = "Zapis lokalny — podłącz backend kiedy będziesz gotowy.";
    }
  }catch(err){
    const list = JSON.parse(localStorage.getItem('fundmind_newsletter')||'[]');
    list.push({email, ts: new Date().toISOString()});
    localStorage.setItem('fundmind_newsletter', JSON.stringify(list));
    msg.textContent = "Zapis lokalny — podłącz backend kiedy będziesz gotowy.";
  }
  form.reset();
});
