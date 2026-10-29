import time
from flask import Flask, request

app = Flask(__name__)

@app.route("/health")
def health():
    return "OK", 200

@app.route("/aplicar-descuento", methods=["POST"])
def aplicar_descuento():
    # Simula cálculo pesado de validación de cupones que bloquea el hilo de Gunicorn
    time.sleep(1.2)
    return {"status": "Descuento aplicado", "descuento": 15}, 200

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)