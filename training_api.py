#!/usr/bin/env python3
"""
Simple API server to bridge web interface with training functionality
Run this alongside the Rasa server to enable training from the web interface
"""

from flask import Flask, request, jsonify
from flask_cors import CORS
import json
import sys
from pathlib import Path
from train_chatbot import ChatbotTrainer

app = Flask(__name__)
CORS(app)  # Enable CORS for web interface

# Initialize trainer
PROJECT_DIR = Path(__file__).parent
trainer = ChatbotTrainer(project_dir=str(PROJECT_DIR))

@app.route('/api/intents', methods=['GET'])
def get_intents():
    """Get list of all available intents"""
    try:
        data = trainer.load_nlu_data()
        intents = []
        for item in data.get('nlu', []):
            if 'intent' in item:
                intent_name = item['intent']
                examples = item.get('examples', '')
                # Count examples properly - each line starting with '- ' is an example
                example_count = len([line for line in examples.split('\n') 
                                   if line.strip().startswith('-')])
                intents.append({
                    'name': intent_name,
                    'examples_count': example_count
                })
        return jsonify({'intents': intents})
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/intents/<intent_name>/examples', methods=['GET'])
def get_examples(intent_name):
    """Get examples for a specific intent"""
    try:
        data = trainer.load_nlu_data()
        for item in data.get('nlu', []):
            if item.get('intent') == intent_name:
                examples = item.get('examples', '')
                # Parse examples - handle both '- ' and '-' formats
                example_list = []
                for line in examples.split('\n'):
                    line = line.strip()
                    if line.startswith('- '):
                        example_list.append(line[2:].strip())
                    elif line.startswith('-'):
                        example_list.append(line[1:].strip())
                return jsonify({'examples': example_list})
        return jsonify({'examples': []})
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/examples', methods=['POST'])
def add_example():
    """Add a new training example"""
    try:
        data = request.json
        intent = data.get('intent')
        example = data.get('example')
        
        if not intent or not example:
            return jsonify({'error': 'Intent and example are required'}), 400
        
        # Parse entities from example if present
        entities = []
        if '[' in example and '](' in example:
            import re
            matches = re.findall(r'\[([^\]]+)\]\(([^\)]+)\)', example)
            for text, entity_name in matches:
                entities.append({'text': text, 'entity': entity_name})
        
        trainer.add_example(intent, example, entities if entities else None)
        return jsonify({'success': True, 'message': f'Example added to {intent}'})
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/train', methods=['POST'])
def train_model():
    """Train the Rasa model"""
    try:
        result = trainer.train_model()
        if result:
            return jsonify({'success': True, 'message': 'Model trained successfully'})
        else:
            return jsonify({'error': 'Training failed'}), 500
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/health', methods=['GET'])
def health():
    """Health check endpoint"""
    return jsonify({'status': 'ok'})

if __name__ == '__main__':
    print("Starting Training API server on http://localhost:5006")
    print("Make sure Rasa server is running on http://localhost:5005")
    app.run(host='0.0.0.0', port=5006, debug=False)

