#!/bin/bash
# Setup MongoDB Atlas Credentials
# This script creates a secure .env file with MongoDB credentials

set -e

ENV_FILE=".env"
EXAMPLE_FILE=".env.example"

echo "🔐 MongoDB Atlas Credentials Setup"
echo "===================================="
echo ""

# Check if .env already exists
if [ -f "$ENV_FILE" ]; then
    echo "⚠️  .env file already exists!"
    read -p "Do you want to overwrite it? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "❌ Aborted. Existing .env file preserved."
        exit 1
    fi
    echo "📝 Backing up existing .env to .env.backup"
    cp "$ENV_FILE" "${ENV_FILE}.backup"
fi

# Create .env file
cat > "$ENV_FILE" << 'EOF'
# MongoDB Atlas Configuration
# This file contains sensitive credentials and is excluded from version control

# MongoDB Atlas API Keys (for Vector Search and Data API)
MONGODB_ATLAS_PUBLIC_KEY=mvkwbyac
MONGODB_ATLAS_PRIVATE_KEY=8d26b5d5-50a3-4439-9b91-d22d16ffe455

# MongoDB Connection String
# Format: mongodb+srv://<username>:<password>@<cluster>.mongodb.net/<database>?retryWrites=true&w=majority
# Replace with your actual connection string from Atlas
# MONGODB_URI=mongodb+srv://username:password@cluster0.xxxxx.mongodb.net/bmc_chat?retryWrites=true&w=majority

# Rasa Server Configuration
RASA_URL=http://localhost:5005

# Chat Simulation Configuration
SIMULATE_DEFAULT_PHONE=+59891234567
PY_CHAT_SERVICE_URL=http://localhost:8000
EOF

# Set secure permissions (read/write for owner only)
chmod 600 "$ENV_FILE"

echo "✅ Created .env file with MongoDB Atlas credentials"
echo ""
echo "📋 Credentials saved:"
echo "   - Public Key: mvkwbyac"
echo "   - Private Key: 8d26b5d5-50a3-4439-9b91-d22d16ffe455"
echo ""
echo "🔒 File permissions set to 600 (owner read/write only)"
echo ""
echo "⚠️  IMPORTANT:"
echo "   - .env file is excluded from git (.gitignore)"
echo "   - Never commit this file to version control"
echo "   - Keep these credentials secure"
echo ""
echo "📝 Next steps:"
echo "   1. Add your MONGODB_URI connection string to .env"
echo "   2. Test connection: python test_mongodb_atlas.py"
echo "   3. See MONGODB_CREDENTIALS.md for usage instructions"
echo ""

