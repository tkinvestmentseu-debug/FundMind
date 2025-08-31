# FundMind — pakiet startowy

Ten pakiet zawiera:
- `landing/` — gotowy landing (PL/EN) + newsletter (lokalny lub Flask).
- `android_app/` — aplikacja Android (Jetpack Compose) gotowa do uruchomienia w Android Studio.
- `docs/` — Planer PDF (druk), szablony.
- `ai/` — szkic integracji AI (prompt + mock).
- `backend/` — prosty serwer newslettera (Flask).

## Szybki start (Android Studio)
1. Otwórz Android Studio → **Open** → wskaż folder `android_app`.
2. Poczekaj na synchronizację Gradle (Studio doinstaluje brakujące elementy).
3. Uruchom na emulatorze/urządzeniu (Run ▶).
4. Jeśli pojawi się błąd Gradle Wrapper:
   - Android Studio zaproponuje utworzenie wrappera automatycznie, zaakceptuj.
   - Lub z menu: *File → Sync Project with Gradle Files*.

## Budowanie APK
- **Build → Build Bundle(s) / APK(s) → Build APK(s)**.

## Landing
- Otwórz `landing/index.html` (PL) lub `landing/index-en.html` (EN).
- Aby włączyć realny newsletter:
  - uruchom `backend/newsletter_server.py` (`pip install flask`),
  - w `landing/script.js` podmień endpoint na `http://localhost:5000/subscribe`.

## AI Asystent
- W folderze `ai/` znajdziesz `prompt_spec.md` i `local_mock.py`.
- Podłączenie produkcyjne: dodaj endpoint do backendu i wywołuj go z aplikacji.

## Licencja
MIT — do użytku komercyjnego.
