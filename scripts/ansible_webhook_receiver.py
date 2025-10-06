from flask import Flask, request

app = Flask(__name__)

@app.route("/", methods=["POST"])
def webhook():
    # Read raw request data and log it
    raw_data = request.data.decode('utf-8')
    app.logger.info(f"Received alert: {raw_data}")
    return "OK", 200

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5001)