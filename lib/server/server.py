from flask import Flask, request, jsonify
import os
import json
import re
from openai import OpenAI

app = Flask(__name__)

# Initialize OpenAI client for Gemma 2 9B with increased timeout
client = OpenAI(
    base_url="http://localhost:11434/v1",
    api_key="ollama",
    timeout=60  # Increase timeout to 60 seconds
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
        <li><b>POST /validate_word</b>: Validate a word in a word chain game. Example: <code>{"word": "tiger", "prev_word": "cat", "used_words": ["cat"]}</code></li>
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

        if not hasattr(response, 'choices') or not response.choices:
            raise ValueError("Invalid response from Ollama: No choices found")

        clue = response.choices[0].message.content.strip()
        return jsonify({"word": word, "category": category, "clue": clue}), 200

    except Exception as e:
        return jsonify({"error": f"Failed to generate clue: {str(e)}"}), 500

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

        if not hasattr(response, 'choices') or not response.choices:
            raise ValueError("Invalid response from Ollama: No choices found")

        hint = response.choices[0].message.content.strip()
        return jsonify({"word": word, "hint": hint}), 200

    except Exception as e:
        return jsonify({"error": f"Failed to generate hint: {str(e)}"}), 500

# Endpoint to validate a word in word chain game
@app.route('/validate_word', methods=['POST'])
def validate_word():
    try:
        data = request.get_json()
        word = data.get('word', '').strip().lower()
        prev_word = data.get('prev_word', '').strip().lower()
        used_words = data.get('used_words', [])

        if not word or not prev_word:
            return jsonify({"error": "Word and prev_word are required"}), 400

        # Manual check for used words to ensure correctness
        if word in used_words:
            return jsonify({"is_valid": False, "message": "Word already used"}), 200

        prompt = f"""
        You are an English language expert. Validate if the word '{word}' is a valid English word and suitable for a word chain game. 
        The word must:
        - Be a valid English word (not a proper noun, slang, or abbreviation).
        - Start with the last letter of the previous word '{prev_word}'.
        - Not be in the list of used words: {used_words}.
        Return ONLY a JSON object with:
        - "is_valid": true/false
        - "message": Explanation if invalid (empty string if valid)
        Example:
        {{"is_valid": true, "message": ""}}
        or
        {{"is_valid": false, "message": "Not a valid English word"}}
        Do NOT include any additional text, markdown, or comments outside the JSON.
        If the word is already in the used words list, return:
        {{"is_valid": false, "message": "Word already used"}}
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

        if not hasattr(response, 'choices') or not response.choices:
            raise ValueError("Invalid response from Ollama: No choices found")

        content = response.choices[0].message.content.strip()

        # Try to parse the content as JSON
        try:
            result = json.loads(content)
            if not isinstance(result, dict) or 'is_valid' not in result:
                raise ValueError("Invalid JSON format from model: Missing is_valid field")
        except json.JSONDecodeError:
            # Extract JSON from markdown or text if possible
            json_match = re.search(r'\{.*?\}', content, re.DOTALL)
            if json_match:
                try:
                    result = json.loads(json_match.group(0))
                except json.JSONDecodeError:
                    # Fallback: Analyze content for validity
                    is_valid = "valid English word" in content.lower() and word not in used_words
                    message = content if not is_valid else "Word already used" if word in used_words else ""
                    result = {"is_valid": is_valid, "message": message}
            else:
                # If no JSON found, fallback to manual validation
                is_valid = False
                message = "Failed to parse model response"
                result = {"is_valid": is_valid, "message": message}
        except ValueError as ve:
            result = {"is_valid": false, "message": f"Model response format invalid: {str(ve)}"}

        return jsonify(result), 200

    except Exception as e:
        return jsonify({"error": f"Failed to validate word: {str(e)}"}), 500

# Handle favicon requests
@app.route('/favicon.ico')
def favicon():
    return '', 204

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=3000, debug=True)