# MongoDB Atlas Connection Guide

This guide explains how to connect your ChatBOT application to MongoDB Atlas instead of a local MongoDB instance.

> 📖 **For API Keys Management**: See [MONGODB_CREDENTIALS.md](MONGODB_CREDENTIALS.md) for secure credential storage and usage.

## Prerequisites

Before connecting to an Atlas cluster, ensure your application can reach your MongoDB Atlas environment by allowing your applications to make outbound connections to ports **27015 to 27017** for both **TCP and UDP** traffic on Atlas hosts.

## Setup Steps

### 1. Configure IP Access List (Network Access)

1. Log in to [MongoDB Atlas](https://cloud.mongodb.com/)
2. Navigate to your project
3. Go to **Network Access** in the left sidebar
4. Click **Add IP Address**
5. Choose one of the following options:
   - **Add Current IP Address**: For development from your current location
   - **Allow Access from Anywhere**: Add `0.0.0.0/0` (⚠️ Less secure, use only for development)
   - **Add Specific IP**: For production deployments, add your server's IP address

**Recommended for Development:**
- Add your current IP address
- Add `0.0.0.0/0` if you need to connect from multiple locations (development only)

**Recommended for Production:**
- Add only specific IP addresses of your application servers
- Use VPC peering for AWS/GCP/Azure deployments

### 2. Create Database User (Database Access)

1. In MongoDB Atlas, go to **Database Access** in the left sidebar
2. Click **Add New Database User**
3. Configure the user:
   - **Authentication Method**: Password
   - **Username**: Choose a username (e.g., `bmc_chatbot_user`)
   - **Password**: 
     - Click **Autogenerate Secure Password** (recommended)
     - **⚠️ IMPORTANT**: Copy and save this password immediately
   - **Database User Privileges**: 
     - Select **Read and write to any database** (for development)
     - Or create custom roles for production (more secure)
4. Click **Add User**

### 3. Get Connection String

1. In MongoDB Atlas, go to **Clusters** in the left sidebar
2. Click **Connect** on your cluster
3. Select **Connect your application**
4. Choose your driver:
   - **Driver**: Python
   - **Version**: 3.12 or later (for pymongo)
5. Copy the connection string. It will look like:
   ```
   mongodb+srv://<username>:<password>@cluster0.xxxxx.mongodb.net/?retryWrites=true&w=majority
   ```

### 4. Configure Your Application

#### Option A: Environment Variable (Recommended)

1. **Quick Setup**: Run the setup script to create `.env` file with your credentials:
   ```bash
   ./setup_mongodb_credentials.sh
   ```

2. **Manual Setup**: Create a `.env` file in your project root (if it doesn't exist):
   ```bash
   # .env
   MONGODB_URI=mongodb+srv://bmc_chatbot_user:YOUR_PASSWORD@cluster0.xxxxx.mongodb.net/bmc_chat?retryWrites=true&w=majority
   MONGODB_ATLAS_PUBLIC_KEY=your_public_key
   MONGODB_ATLAS_PRIVATE_KEY=your_private_key
   ```
   
   > 💡 **Note**: Your API keys are already saved in `.env` if you ran `setup_mongodb_credentials.sh`

3. Replace `<username>` and `<password>` in the connection string with your actual credentials:
   ```bash
   MONGODB_URI=mongodb+srv://bmc_chatbot_user:MySecurePassword123@cluster0.xxxxx.mongodb.net/bmc_chat?retryWrites=true&w=majority
   ```

4. The connection string format:
   ```
   mongodb+srv://[username]:[password]@[cluster]/[database]?[options]
   ```
   - `[username]`: Your database user username
   - `[password]`: Your database user password (URL-encode special characters)
   - `[cluster]`: Your cluster address (e.g., `cluster0.xxxxx.mongodb.net`)
   - `[database]`: Database name (e.g., `bmc_chat`)
   - `[options]`: Connection options (optional)

#### Option B: Direct Configuration

Update your code to use the Atlas connection string:

```python
import os
from pymongo import MongoClient

# Atlas connection string
MONGODB_URI = os.getenv(
    'MONGODB_URI', 
    'mongodb+srv://username:password@cluster0.xxxxx.mongodb.net/bmc_chat?retryWrites=true&w=majority'
)

client = MongoClient(MONGODB_URI)
db = client.bmc_chat
```

### 5. Test Connection

Test your connection with a simple script:

```python
#!/usr/bin/env python3
"""Test MongoDB Atlas connection"""
import os
from pymongo import MongoClient
from pymongo.errors import ConnectionFailure, ServerSelectionTimeoutError

# Load from environment or use default
MONGODB_URI = os.getenv(
    'MONGODB_URI',
    'mongodb+srv://username:password@cluster0.xxxxx.mongodb.net/bmc_chat'
)

try:
    print("🔌 Connecting to MongoDB Atlas...")
    client = MongoClient(MONGODB_URI, serverSelectionTimeoutMS=5000)
    
    # Test connection
    client.admin.command('ping')
    print("✅ Successfully connected to MongoDB Atlas!")
    
    # List databases
    print("\n📊 Available databases:")
    for db_name in client.list_database_names():
        print(f"   - {db_name}")
    
    # Test database access
    db = client.get_database('bmc_chat')
    print(f"\n📁 Using database: bmc_chat")
    print(f"   Collections: {db.list_collection_names()}")
    
except ServerSelectionTimeoutError:
    print("❌ Error: Could not connect to MongoDB Atlas")
    print("   Check your IP whitelist and connection string")
except ConnectionFailure as e:
    print(f"❌ Connection failed: {e}")
except Exception as e:
    print(f"❌ Error: {e}")
finally:
    client.close()
```

Run the test:
```bash
python test_mongodb_atlas.py
```

## Connection Methods

### Connect via Driver (Python/pymongo)

This is the method used in this project. The connection string is used directly with `pymongo.MongoClient`:

```python
from pymongo import MongoClient

client = MongoClient(MONGODB_URI)
db = client.bmc_chat
```

### Connect via Compass

1. Download [MongoDB Compass](https://www.mongodb.com/try/download/compass)
2. In Atlas, click **Connect** → **Compass**
3. Copy the connection string
4. Open Compass and paste the connection string
5. Replace `<password>` with your actual password

### Connect via mongo Shell

1. Install MongoDB Shell: `brew install mongosh` (macOS) or download from [MongoDB website](https://www.mongodb.com/try/download/shell)
2. In Atlas, click **Connect** → **MongoDB Shell**
3. Copy the connection command
4. Run it in your terminal

### Connect via Command Line Tools

Use `mongosh` or `mongo` CLI tools with the connection string:

```bash
mongosh "mongodb+srv://username:password@cluster0.xxxxx.mongodb.net/bmc_chat"
```

## Troubleshooting Connection Issues

### Common Issues

#### 1. "IP not whitelisted" Error

**Problem**: Your IP address is not in the Atlas IP access list.

**Solution**:
- Go to **Network Access** in Atlas
- Add your current IP address
- Wait 1-2 minutes for changes to propagate

#### 2. "Authentication failed" Error

**Problem**: Incorrect username or password.

**Solution**:
- Verify username and password in the connection string
- URL-encode special characters in password (e.g., `@` becomes `%40`)
- Check Database Access to ensure user exists and has correct permissions

#### 3. "Connection timeout" Error

**Problem**: Network connectivity issues or firewall blocking ports.

**Solution**:
- Ensure ports 27015-27017 are open for TCP/UDP
- Check firewall settings
- Verify you're using the correct connection string format (`mongodb+srv://`)

#### 4. "Server selection timeout" Error

**Problem**: Cannot reach Atlas servers.

**Solution**:
- Check internet connectivity
- Verify IP whitelist includes your current IP
- Try using `mongodb://` instead of `mongodb+srv://` (requires specifying port)

### Connection String Format Issues

**Special Characters in Password**:
If your password contains special characters, URL-encode them:
- `@` → `%40`
- `#` → `%23`
- `$` → `%24`
- `%` → `%25`
- `&` → `%26`
- `/` → `%2F`
- `:` → `%3A`
- `?` → `%3F`
- `=` → `%3D`

**Example**:
```
Password: P@ssw0rd#123
Encoded:  P%40ssw0rd%23123
```

### Testing Connection from Command Line

```bash
# Test with mongosh
mongosh "mongodb+srv://username:password@cluster0.xxxxx.mongodb.net/bmc_chat" --eval "db.adminCommand('ping')"

# Test with Python
python3 -c "from pymongo import MongoClient; c = MongoClient('mongodb+srv://username:password@cluster0.xxxxx.mongodb.net/bmc_chat', serverSelectionTimeoutMS=5000); c.admin.command('ping'); print('✅ Connected')"
```

## Connection Limits and Cluster Tier

Different Atlas cluster tiers have different connection limits:

- **M0 (Free)**: 500 connections
- **M2**: 1,500 connections
- **M5**: 1,500 connections
- **M10+**: 1,500+ connections (varies by tier)

Monitor your connections in Atlas → **Metrics** → **Connection Pool**.

## Best Practices

### 1. Use Connection Pooling

```python
from pymongo import MongoClient

client = MongoClient(
    MONGODB_URI,
    maxPoolSize=50,  # Maximum connections in pool
    minPoolSize=10,  # Minimum connections in pool
    maxIdleTimeMS=45000,  # Close idle connections after 45s
    serverSelectionTimeoutMS=5000  # Timeout for server selection
)
```

### 2. Environment Variables

Never hardcode credentials. Always use environment variables:

```python
import os
from pymongo import MongoClient

MONGODB_URI = os.getenv('MONGODB_URI')
if not MONGODB_URI:
    raise ValueError("MONGODB_URI environment variable is required")

client = MongoClient(MONGODB_URI)
```

### 3. Error Handling

Always handle connection errors gracefully:

```python
from pymongo import MongoClient
from pymongo.errors import ConnectionFailure, ServerSelectionTimeoutError

try:
    client = MongoClient(MONGODB_URI, serverSelectionTimeoutMS=5000)
    client.admin.command('ping')
    # Use database...
except (ConnectionFailure, ServerSelectionTimeoutError) as e:
    print(f"❌ MongoDB connection failed: {e}")
    # Fallback logic or retry
```

### 4. Connection String Security

- Store connection strings in environment variables or secret management systems
- Never commit connection strings to version control
- Use `.gitignore` to exclude `.env` files
- Rotate passwords regularly
- Use different users for different environments (dev/staging/prod)

### 5. For AWS Lambda

If deploying to AWS Lambda, see: [Best Practices Connecting from AWS Lambda](https://www.mongodb.com/docs/atlas/connect-to-cluster/#best-practices-connecting-from-aws-lambda)

Key points:
- Use connection pooling (reuse connections across invocations)
- Set appropriate timeouts
- Use VPC peering for better security
- Consider using MongoDB Atlas Data API for serverless

## Updating Your Project

### Update simulate_chat.py

The `simulate_chat.py` file already supports MongoDB Atlas connection strings via the `MONGODB_URI` environment variable. Simply set it to your Atlas connection string:

```bash
export MONGODB_URI="mongodb+srv://username:password@cluster0.xxxxx.mongodb.net/bmc_chat?retryWrites=true&w=majority"
```

Or create a `.env` file:

```bash
# .env
MONGODB_URI=mongodb+srv://username:password@cluster0.xxxxx.mongodb.net/bmc_chat?retryWrites=true&w=majority
```

Then load it in your code:

```python
from dotenv import load_dotenv
load_dotenv()  # Loads .env file

MONGODB_URI = os.getenv('MONGODB_URI')
```

### Install python-dotenv (if not already installed)

```bash
pip install python-dotenv
```

## Additional Resources

- [MongoDB Atlas Documentation](https://www.mongodb.com/docs/atlas/)
- [Troubleshoot Connection Issues](https://www.mongodb.com/docs/atlas/troubleshoot-connection/)
- [Connection Limits and Cluster Tier](https://www.mongodb.com/docs/atlas/reference/connection-limits/)
- [Data Explorer for managing Atlas data](https://www.mongodb.com/docs/atlas/data-explorer/)
- [Test Failover](https://www.mongodb.com/docs/atlas/test-failover/)
- [Connections in MongoDB Atlas Clusters](https://www.mongodb.com/docs/atlas/connection-pooling/)

## Quick Reference

### Connection String Template

```
mongodb+srv://[username]:[password]@[cluster]/[database]?retryWrites=true&w=majority
```

### Environment Variable

```bash
MONGODB_URI=mongodb+srv://username:password@cluster0.xxxxx.mongodb.net/bmc_chat?retryWrites=true&w=majority
```

### Python Connection Code

```python
from pymongo import MongoClient
import os

MONGODB_URI = os.getenv('MONGODB_URI')
client = MongoClient(MONGODB_URI)
db = client.bmc_chat
```

---

**Need Help?**
- Check MongoDB Atlas logs: Atlas → **Metrics** → **Logs**
- Review connection metrics: Atlas → **Metrics** → **Connection Pool**
- MongoDB Community Forums: https://www.mongodb.com/community/forums/

