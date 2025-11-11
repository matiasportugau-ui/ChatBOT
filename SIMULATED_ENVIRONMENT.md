# 🎮 Simulated Chat & Training Environment

This document describes the simulated environment for chatting with and training the ChatBOT.

## 📋 Overview

The simulated environment provides three ways to interact with and train your chatbot:

1. **Interactive Terminal Chat** (`simulate_chat.py`) - Command-line chat interface
2. **Training Interface** (`train_chatbot.py`) - Add examples and retrain the model
3. **Web Chat Interface** (`web_chat_interface.html`) - Browser-based chat UI

## 🚀 Quick Start

### Prerequisites

1. **Activate virtual environment:**
   ```bash
   source .venv/bin/activate
   ```

2. **Start Rasa server:**
   ```bash
   rasa run --model models/ --enable-api --cors '*' --port 5005
   ```

   Or if you have a specific model:
   ```bash
   rasa run --model models/20251109-214427-visible-reservoir.tar.gz --enable-api --cors '*' --port 5005
   ```

### Option 1: Interactive Terminal Chat

Run the interactive chat simulator:

```bash
python simulate_chat.py
```

**Features:**
- Real-time chat with the chatbot
- Intent and entity analysis
- Conversation tracker inspection
- Conversation history saving

**Commands:**
- Type your message to chat
- `/parse <text>` - Analyze intent/entities
- `/tracker` - View conversation state
- `/save` - Save conversation history
- `/exit` - Exit the simulator

**Example:**
```bash
$ python simulate_chat.py

🚀 CHATBOT SIMULATION ENVIRONMENT
============================================================
📡 Connecting to: http://localhost:5005
👤 User ID: sim_user_20251109_123456
============================================================
✅ Server is running!

👤 You: hola
🤖 CHATBOT:
============================================================
📊 Intent: saludo
   Confidence: 95.23%

💬 Hola, ¿cómo puedo ayudarte?
============================================================
```

### Option 2: Training Interface

Add new training examples and retrain the model:

```bash
python train_chatbot.py
```

**Features:**
- Add examples to existing intents
- Create new intents
- View training examples
- Train new models

**Interactive Menu:**
```
📋 Available intents:
   1. saludo (5 examples)
   2. despedida (4 examples)
   3. cotizar_producto (5 examples)

💡 Options:
   1. Add new example to existing intent
   2. Create new intent with example
   3. View examples for an intent
   4. Train model
   5. Exit
```

**Example - Adding an entity:**
```
👉 Enter example text: quiero cotizar [remera roja](producto) talle [M](sku)
✅ Added example to intent 'cotizar_producto'
```

**Training a model:**
```
👉 Choose an option (1-5): 4
⚠️  This will train a new model. Continue? (y/n): y

🚀 Training model...
============================================================
...
✅ Training completed successfully!
```

### Option 3: Web Chat Interface

Open the web interface in your browser:

```bash
# Option A: Use Python's built-in server
python -m http.server 8000

# Option B: Use any web server
# Just open web_chat_interface.html in your browser
```

Then navigate to: `http://localhost:8000/web_chat_interface.html`

**Features:**
- Beautiful, modern UI
- Real-time chat
- Intent confidence display
- Server status indicator
- Responsive design

## 📚 Detailed Usage

### Simulate Chat Script

**Command-line options:**
```bash
python simulate_chat.py --url http://localhost:5005 --sender custom_user_id
```

**Parameters:**
- `--url`: Rasa server URL (default: http://localhost:5005)
- `--sender`: Custom sender ID (default: auto-generated)

**Conversation History:**
Conversations are saved as JSON files with timestamps:
- `conversation_20251109_123456.json`

**Format:**
```json
[
  {
    "timestamp": "2025-11-09T12:34:56",
    "user_message": "hola",
    "intent": "saludo",
    "entities": [],
    "bot_responses": [
      {"text": "Hola, ¿cómo puedo ayudarte?"}
    ]
  }
]
```

### Training Script

**Command-line options:**
```bash
# Interactive mode (default)
python train_chatbot.py

# Direct training
python train_chatbot.py --train

# Custom project directory
python train_chatbot.py --project-dir /path/to/project
```

**Adding Examples with Entities:**
When adding examples, you can include entities using the format:
```
[entity_text](entity_name)
```

Examples:
- `quiero cotizar [remera](producto)` - product entity
- `necesito [5](cantidad) [zapatillas](producto)` - quantity and product
- `cotizame [SKU-123](sku)` - SKU entity

**Training Process:**
1. The script validates all training files
2. Trains a new model with timestamp
3. Saves model to `models/` directory
4. Model name format: `model_YYYYMMDD-HHMMSS.tar.gz`

### Web Interface

**Configuration:**
Edit `web_chat_interface.html` and change the `RASA_URL` constant:
```javascript
const RASA_URL = 'http://localhost:5005';
```

**Features:**
- Auto-reconnects if server goes down
- Shows server status in header
- Displays intent confidence for each message
- Saves conversation history in browser memory

## 🔧 Integration Examples

### Use in Python Scripts

```python
from simulate_chat import ChatSimulator

simulator = ChatSimulator(rasa_url="http://localhost:5005")
responses = simulator.send_message("hola")
print(responses)
```

### Use Training Programmatically

```python
from train_chatbot import ChatbotTrainer

trainer = ChatbotTrainer(project_dir=".")
trainer.add_example("saludo", "buenas tardes")
trainer.add_example("cotizar_producto", "quiero cotizar [remera](producto)", 
                    [{"text": "remera", "entity": "producto"}])
trainer.train_model()
```

## 🐛 Troubleshooting

### Server Not Running

**Error:** `❌ ERROR: Rasa server is not running!`

**Solution:**
```bash
# Start the server
source .venv/bin/activate
rasa run --model models/ --enable-api --cors '*' --port 5005
```

### Port Already in Use

**Error:** `Address already in use`

**Solution:**
```bash
# Use a different port
rasa run --model models/ --enable-api --cors '*' --port 5006

# Update scripts to use new port
python simulate_chat.py --url http://localhost:5006
```

### Model Not Found

**Error:** `Model file not found`

**Solution:**
```bash
# List available models
ls -lh models/

# Train a new model
python train_chatbot.py
# Choose option 4 to train
```

### CORS Errors (Web Interface)

**Error:** `CORS policy blocked`

**Solution:**
Make sure Rasa server is started with `--cors '*'`:
```bash
rasa run --model models/ --enable-api --cors '*' --port 5005
```

## 📊 Training Best Practices

1. **Add diverse examples:**
   - Different phrasings
   - Various entity combinations
   - Edge cases

2. **Entity annotation:**
   - Always annotate entities in examples
   - Use consistent entity names
   - Include examples without entities too

3. **Regular retraining:**
   - Retrain after adding 5-10 new examples
   - Test the model after training
   - Keep old models as backups

4. **Validation:**
   - Test with the chat simulator
   - Check intent confidence scores
   - Verify entity extraction

## 🎯 Example Workflow

1. **Start server:**
   ```bash
   rasa run --model models/ --enable-api --cors '*' --port 5005
   ```

2. **Test current model:**
   ```bash
   python simulate_chat.py
   ```

3. **Identify gaps:**
   - Note incorrect intent predictions
   - Missing entity extractions
   - Unhandled user inputs

4. **Add training examples:**
   ```bash
   python train_chatbot.py
   ```

5. **Retrain:**
   - Choose option 4 in training interface
   - Wait for training to complete

6. **Test new model:**
   ```bash
   # Restart server with new model
   rasa run --model models/model_20251109-123456.tar.gz --enable-api --cors '*' --port 5005
   python simulate_chat.py
   ```

## 📝 Files Created

- `simulate_chat.py` - Interactive chat simulator
- `train_chatbot.py` - Training interface
- `web_chat_interface.html` - Web-based chat UI
- `SIMULATED_ENVIRONMENT.md` - This documentation
- `conversation_*.json` - Saved conversation histories

## 🔗 Related Documentation

- `USAR_CHATBOT.md` - Basic chatbot usage
- `README.md` - Project overview
- Rasa Documentation: https://rasa.com/docs/

---

**Happy Chatting and Training! 🚀**

