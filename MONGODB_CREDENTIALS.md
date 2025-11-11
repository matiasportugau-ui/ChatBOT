# MongoDB Atlas Credentials Guide

This document explains how to securely manage MongoDB Atlas API keys and connection strings.

## 🔐 Security Best Practices

✅ **DO:**
- Store credentials in `.env` file (excluded from git)
- Use environment variables in your code
- Rotate keys regularly
- Use different keys for dev/staging/production
- Keep `.env` file permissions restricted (chmod 600)

❌ **DON'T:**
- Commit `.env` files to version control
- Hardcode credentials in source code
- Share credentials in chat/email
- Use production keys in development

## 📁 File Structure

```
ChatBOT-full/
├── .env                    # Your actual credentials (NOT in git)
├── .env.example            # Template file (safe to commit)
└── MONGODB_CREDENTIALS.md  # This guide
```

## 🔑 MongoDB Atlas API Keys

### What are they used for?

MongoDB Atlas API keys are used for:
- **Vector Search API**: Semantic search in MongoDB Atlas
- **Data API**: Serverless access to MongoDB without drivers
- **Atlas Admin API**: Programmatic cluster management

### Current Credentials

Your API keys are stored in `.env`:
- **Public Key**: `MONGODB_ATLAS_PUBLIC_KEY`
- **Private Key**: `MONGODB_ATLAS_PRIVATE_KEY`

⚠️ **Keep these keys secure!** Anyone with both keys can access your Atlas cluster.

### Using API Keys in Code

```python
import os
from dotenv import load_dotenv

# Load environment variables from .env
load_dotenv()

# Get API keys
public_key = os.getenv('MONGODB_ATLAS_PUBLIC_KEY')
private_key = os.getenv('MONGODB_ATLAS_PRIVATE_KEY')

# Use for Atlas Data API requests
import requests

url = "https://data.mongodb-api.com/app/your-app-id/endpoint/data/v1/action/findOne"
headers = {
    "Content-Type": "application/json",
    "api-key": public_key
}
auth = (public_key, private_key)

response = requests.post(url, headers=headers, auth=auth, json={
    "dataSource": "your-cluster",
    "database": "bmc_chat",
    "collection": "conversations",
    "filter": {}
})
```

### Using API Keys for Vector Search

```python
import os
import requests
from dotenv import load_dotenv

load_dotenv()

public_key = os.getenv('MONGODB_ATLAS_PUBLIC_KEY')
private_key = os.getenv('MONGODB_ATLAS_PRIVATE_KEY')

# Vector search endpoint
url = "https://cloud.mongodb.com/api/atlas/v1.0/groups/{GROUP_ID}/clusters/{CLUSTER_NAME}/fts/v1/search"
headers = {
    "Content-Type": "application/json"
}
auth = (public_key, private_key)

response = requests.post(url, headers=headers, auth=auth, json={
    "collectionName": "knowledge_base",
    "databaseName": "bmc_chat",
    "indexName": "vector_index",
    "searchDefinition": {
        "vector": embedding_vector,
        "path": "embedding",
        "numCandidates": 100
    }
})
```

## 🔌 MongoDB Connection String

### What is it used for?

The connection string is used for:
- **Direct database connections** via pymongo/MongoDB drivers
- **Standard CRUD operations**
- **Real-time data access**

### Current Configuration

Your connection string should be stored in `.env` as `MONGODB_URI`:

```
MONGODB_URI=mongodb+srv://username:password@cluster0.xxxxx.mongodb.net/bmc_chat?retryWrites=true&w=majority
```

### Using Connection String in Code

```python
import os
from pymongo import MongoClient
from dotenv import load_dotenv

load_dotenv()

# Get connection string
mongodb_uri = os.getenv('MONGODB_URI')

# Connect to MongoDB
client = MongoClient(mongodb_uri)
db = client.bmc_chat
collection = db.conversations

# Use database
result = collection.find_one({"user_id": "123"})
```

## 🚀 Quick Start

### 1. Load Credentials

```python
from dotenv import load_dotenv
import os

load_dotenv()  # Loads .env file

# Access credentials
mongodb_uri = os.getenv('MONGODB_URI')
public_key = os.getenv('MONGODB_ATLAS_PUBLIC_KEY')
private_key = os.getenv('MONGODB_ATLAS_PRIVATE_KEY')
```

### 2. Verify Credentials are Loaded

```python
if not mongodb_uri:
    raise ValueError("MONGODB_URI not set in .env file")
if not public_key or not private_key:
    raise ValueError("MongoDB Atlas API keys not set in .env file")
```

## 🔄 Rotating Credentials

### When to Rotate

- Every 90 days (recommended)
- If keys are compromised
- When team members leave
- Before production deployment

### How to Rotate

1. **Create new API key in Atlas:**
   - Go to Atlas → Access Manager → API Keys
   - Click "Create API Key"
   - Save the new keys securely

2. **Update .env file:**
   ```bash
   MONGODB_ATLAS_PUBLIC_KEY=new_public_key
   MONGODB_ATLAS_PRIVATE_KEY=new_private_key
   ```

3. **Test new keys:**
   ```bash
   python test_mongodb_atlas.py
   ```

4. **Delete old keys in Atlas** (after verifying new keys work)

## 🛡️ File Permissions

On Unix/macOS, restrict `.env` file permissions:

```bash
chmod 600 .env
```

This ensures only you can read/write the file.

## 📋 Checklist

- [ ] `.env` file created with credentials
- [ ] `.env` is in `.gitignore` (verified)
- [ ] `.env.example` template created (without real credentials)
- [ ] File permissions set to 600 (Unix/macOS)
- [ ] Credentials tested and working
- [ ] Team members know not to commit `.env`
- [ ] Backup of credentials stored securely (password manager)

## 🔍 Verifying Security

### Check if .env is in gitignore:

```bash
git check-ignore .env
# Should output: .env
```

### Check if .env is tracked by git:

```bash
git ls-files .env
# Should output nothing (file not tracked)
```

### Verify file permissions:

```bash
ls -la .env
# Should show: -rw------- (600 permissions)
```

## 🆘 Troubleshooting

### "Credentials not found"

**Problem**: Environment variables are not loading.

**Solution**:
1. Verify `.env` file exists in project root
2. Check file has correct format (KEY=value, no spaces around =)
3. Ensure `python-dotenv` is installed: `pip install python-dotenv`
4. Call `load_dotenv()` before accessing environment variables

### "Authentication failed"

**Problem**: API keys or connection string are incorrect.

**Solution**:
1. Verify keys in Atlas dashboard
2. Check for typos in `.env` file
3. Ensure no extra spaces or quotes around values
4. Test connection with `test_mongodb_atlas.py`

### "Permission denied" when reading .env

**Problem**: File permissions are too restrictive.

**Solution**:
```bash
chmod 600 .env  # Read/write for owner only
```

## 📚 Additional Resources

- [MongoDB Atlas API Documentation](https://www.mongodb.com/docs/atlas/api/)
- [Atlas Data API](https://www.mongodb.com/docs/atlas/api/data-api/)
- [Vector Search API](https://www.mongodb.com/docs/atlas/atlas-vector-search/vector-search-overview/)
- [MONGODB_ATLAS_SETUP.md](MONGODB_ATLAS_SETUP.md) - Full setup guide

---

**⚠️ Security Reminder**: Never commit `.env` files or share credentials. Always use environment variables or secure secret management systems in production.

