#!/bin/bash
# Start Training API Server for BMC Chat Interface

cd "$(dirname "$0")"

# Activate virtual environment
source .venv/bin/activate

# Check if Flask is installed
python -c "import flask" 2>/dev/null || {
    echo "Installing Flask and flask-cors..."
    pip install flask flask-cors
}

# Start training API server
echo "Starting Training API server on http://localhost:5006"
echo "Press CTRL+C to stop"
python training_api.py

