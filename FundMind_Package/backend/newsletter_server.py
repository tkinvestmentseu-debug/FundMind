from flask import Flask, request, jsonify
from pathlib import Path
import csv, datetime

app = Flask(__name__)
DATA = Path(__file__).parent / "newsletter.csv"

@app.post("/subscribe")
def subscribe():
    body = request.get_json(force=True)
    email = (body.get("email") or "").strip().lower()
    if not email or "@" not in email:
        return jsonify({"ok": False, "error":"invalid_email"}), 400
    is_new = not DATA.exists()
    with DATA.open("a", newline="") as f:
        w = csv.writer(f)
        if is_new: w.writerow(["email","timestamp"])
        w.writerow([email, datetime.datetime.utcnow().isoformat()+"Z"])
    return jsonify({"ok": True})

if __name__ == "__main__":
    app.run(debug=True)
