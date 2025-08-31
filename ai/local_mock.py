# Local mock of AI endpoint (for dev)
# Usage: python local_mock.py
from flask import Flask, request, jsonify
app = Flask(__name__)

@app.post("/ai/coach")
def coach():
    data = request.get_json(force=True)
    income = data.get("income", 0)
    result = {
        "envelopes": {"needs": round(income*0.5,2), "wants": round(income*0.3,2), "savings": round(income*0.2,2)},
        "plan7d": ["Przejrzyj subskrypcje", "Zapłać najdroższy dług", "Ustal tygodniowy limit wydatków"],
        "quick_win": "Negocjuj rachunek za Internet/telefon"
    }
    return jsonify(result)

if __name__ == "__main__":
    app.run(port=5050, debug=True)
