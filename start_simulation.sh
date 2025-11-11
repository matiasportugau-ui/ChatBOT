#!/bin/bash
# Quick Start Script for ChatBOT Simulation Environment

set -e

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$PROJECT_DIR"

echo "🚀 ChatBOT Simulation Environment - Quick Start"
echo "=============================================="
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
    pip install -r requirements.txt
    echo "✅ Dependencies installed"
fi

# Check if server is running
echo ""
echo "🔍 Checking if Rasa server is running..."
if curl -s http://localhost:5005/status > /dev/null 2>&1; then
    echo "✅ Server is already running!"
else
    echo "⚠️  Server is not running."
    echo ""
    echo "Choose an option:"
    echo "  1. Start server in background and open chat"
    echo "  2. Just start server (I'll open chat manually)"
    echo "  3. Skip server start (assume it's running elsewhere)"
    read -p "👉 Your choice (1-3): " choice
    
    case $choice in
        1)
            echo ""
            echo "🚀 Starting Rasa server in background..."
            # Find latest model
            LATEST_MODEL=$(ls -t models/*.tar.gz 2>/dev/null | head -1)
            if [ -z "$LATEST_MODEL" ]; then
                echo "⚠️  No model found. Using default model path..."
                rasa run --model models/ --enable-api --cors '*' --port 5005 > rasa_server.log 2>&1 &
            else
                echo "📦 Using model: $LATEST_MODEL"
                rasa run --model "$LATEST_MODEL" --enable-api --cors '*' --port 5005 > rasa_server.log 2>&1 &
            fi
            RASA_PID=$!
            echo "✅ Server started (PID: $RASA_PID)"
            echo "   Logs: $PROJECT_DIR/rasa_server.log"
            sleep 3
            ;;
        2)
            echo ""
            echo "📝 To start the server manually, run:"
            LATEST_MODEL=$(ls -t models/*.tar.gz 2>/dev/null | head -1)
            if [ -n "$LATEST_MODEL" ]; then
                echo "   rasa run --model \"$LATEST_MODEL\" --enable-api --cors '*' --port 5005"
            else
                echo "   rasa run --model models/ --enable-api --cors '*' --port 5005"
            fi
            echo ""
            read -p "Press Enter when server is ready..."
            ;;
        3)
            echo "⏭️  Skipping server start"
            ;;
        *)
            echo "❌ Invalid choice. Exiting."
            exit 1
            ;;
    esac
fi

# Show menu
echo ""
echo "=============================================="
echo "🎮 What would you like to do?"
echo "=============================================="
echo "  1. Interactive Terminal Chat"
echo "  2. Training Interface"
echo "  3. Open Web Chat Interface"
echo "  4. Exit"
echo ""
read -p "👉 Your choice (1-4): " menu_choice

case $menu_choice in
    1)
        echo ""
        echo "💬 Starting interactive chat..."
        python simulate_chat.py
        ;;
    2)
        echo ""
        echo "🎓 Starting training interface..."
        python train_chatbot.py
        ;;
    3)
        echo ""
        echo "🌐 Opening web interface..."
        echo ""
        echo "📝 To open the web interface:"
        echo "   1. Start a web server:"
        echo "      python3 -m http.server 8000"
        echo ""
        echo "   2. Open in browser:"
        echo "      http://localhost:8000/web_chat_interface.html"
        echo ""
        read -p "Press Enter to continue..."
        ;;
    4)
        echo "👋 Goodbye!"
        exit 0
        ;;
    *)
        echo "❌ Invalid choice. Exiting."
        exit 1
        ;;
esac

