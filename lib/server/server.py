from flask import Flask, request, jsonify
import os
from openai import OpenAI

app = Flask(__name__)

# Initialize OpenAI client for Gemma 2 9B
client = OpenAI(
    base_url="http://localhost:11434/v1",
    api_key="ollama"
)

# Root URL for GET requests
@app.route('/', methods=['GET'])
def home():
    return """
    <h1>WordWiz AI Generator</h1>
    <p>Available endpoints:</p>
    <ul>
        <li><b>POST /generate_clue</b>: Generate a clue for a word and category. Example: <code>{"word": "apple", "category": "Level 1"}</code></li>
        <li><b>POST /generate_hint</b>: Generate a hint for a word. Example: <code>{"word": "apple"}</code></li>
    </ul>
    <p>Use tools like curl or Postman to test.</p>
    """

# Endpoint to generate a clue
@app.route('/generate_clue', methods=['POST'])
def generate_clue():
    try:
        data = request.get_json()
        word = data.get('word', '').strip()
        category = data.get('category', '').strip()

        if not word or not category:
            return jsonify({"error": "Word and category are required"}), 400

        prompt = f"""
        You are an English teacher for beginners. Create a simple, clear clue for the English word '{word}' in the category '{category}'. 
        The clue should be short, use basic vocabulary, and avoid using the word itself. 
        For example, for 'apple' in 'Level 1', a clue could be 'This is a fruit. It’s red.'
        """

        response = client.chat.completions.create(
            model="gemma2:9b",
            messages=[
                {"role": "system", "content": "You are a helpful assistant."},
                {"role": "user", "content": prompt}
            ],
            max_tokens=50,
            temperature=0.7
        )

        clue = response.choices[0].message.content.strip()
        return jsonify({"word": word, "category": category, "clue": clue}), 200

    except Exception as e:
        return jsonify({"error": str(e)}), 500

# Endpoint to generate a hint
@app.route('/generate_hint', methods=['POST'])
def generate_hint():
    try:
        data = request.get_json()
        word = data.get('word', '').strip()

        if not word:
            return jsonify({"error": "No word provided"}), 400

        prompt = f"""
        You are an English teacher for beginners. Provide a simple hint for the English word '{word}' to help a beginner guess it.
        The hint should be very short and reveal minimal information, like the first letter or a key trait.
        For example, for 'dog', a hint could be 'First letter: D' or 'It barks.'
        """

        response = client.chat.completions.create(
            model="gemma2:9b",
            messages=[
                {"role": "system", "content": "You are a helpful assistant."},
                {"role": "user", "content": prompt}
            ],
            max_tokens=30,
            temperature=0.7
        )

        hint = response.choices[0].message.content.strip()
        return jsonify({"word": word, "hint": hint}), 200

    except Exception as e:
        return jsonify({"error": str(e)}), 500

# Handle favicon requests
@app.route('/favicon.ico')
def favicon():
    return '', 204

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=3000, debug=True)