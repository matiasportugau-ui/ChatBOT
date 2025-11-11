#!/bin/bash
# Run simulation WITHOUT Docker - uses local Rasa installation

set -e

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$PROJECT_DIR"

echo "🚀 ChatBOT Simulation (No Docker Required)"
echo "============================================"
echo ""

# Check if virtual environment exists
if [ ! -d ".venv" ]; then
    echo "⚠️  Virtual environment not found. Creating one..."
    python3 -m venv .venv
    echo "✅ Virtual environment created"
fi

# Activate virtual environment
echo "📦 Activating virtual environment..."
source .venv/bin/activate

# Check if Rasa is installed
if ! command -v rasa &> /dev/null; then
    echo "⚠️  Rasa not found. Installing dependencies..."
    pip install -q -r requirements.txt
    echo "✅ Dependencies installed"
fi

# Find latest model
LATEST_MODEL=$(ls -t models/*.tar.gz 2>/dev/null | head -1)

if [ -z "$LATEST_MODEL" ]; then
    echo "❌ No model found. Please train a model first:"
    echo "   python train_chatbot.py"
    exit 1
fi

echo "📦 Using model: $LATEST_MODEL"
echo ""

# Check if server is already running
if curl -s http://localhost:5005/status > /dev/null 2>&1; then
    echo "✅ Server is already running!"
    echo ""
    echo "Starting chat simulation..."
    python simulate_chat.py
else
    echo "🚀 Starting Rasa server..."
    echo "   (This will take 10-20 seconds to load the model)"
    echo ""
    echo "   Server will run in the background."
    echo "   To stop it later, run: pkill -f 'rasa run'"
    echo ""
    
    # Start server in background
    rasa run --model "$LATEST_MODEL" --enable-api --cors '*' --port 5005 > rasa_server.log 2>&1 &
    SERVER_PID=$!
    echo "   Server starting (PID: $SERVER_PID)"
    echo ""
    
    # Wait for server to be ready
    echo "⏳ Waiting for server to be ready..."
    for i in {1..30}; do
        if curl -s http://localhost:5005/status > /dev/null 2>&1; then
            echo "✅ Server is ready!"
            echo ""
            break
        fi
        sleep 1
        echo -n "."
    done
    echo ""
    
    # Check if server is ready
    if curl -s http://localhost:5005/status > /dev/null 2>&1; then
        echo ""
        echo "💬 Starting chat simulation..."
        echo ""
        python simulate_chat.py
    else
        echo ""
        echo "❌ Server failed to start. Check logs:"
        echo "   tail -20 rasa_server.log"
        echo ""
        echo "You can also start the server manually:"
        echo "   rasa run --model \"$LATEST_MODEL\" --enable-api --cors '*' --port 5005"
        exit 1
    fi
fi

