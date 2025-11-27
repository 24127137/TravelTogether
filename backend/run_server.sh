#!/bin/bash

# Script to start the backend for a real Android device on Ubuntu
# Usage: ./run_server.sh

echo "=== Starting Travel Together Backend (Ubuntu) ==="

# 1. Activate virtual environment
# On Linux, the path is usually .venv/bin/activate
if [ -f ".venv/bin/activate" ]; then
    echo "Activating virtual environment..."
    source .venv/bin/activate
else
    echo "WARNING: .venv/bin/activate not found."
    echo "Attempting to run with system python..."
fi

# 2. Display your Local IP Address
# This helps you know what IP to put in your Android App
echo ""
echo "Your Local LAN IP Addresses:"
hostname -I | awk '{print $1}'
echo ""
echo "The Backend will listen on 0.0.0.0:8000"
echo "----------------------------------------"

# 3. Start uvicorn
# --host 0.0.0.0 allows connections from other devices (like your phone)
uvicorn main:app --host 0.0.0.0 --port 8000 --reload