# MongoDB Atlas Quick Start

## ✅ Current Status

Your MongoDB Atlas setup is **almost complete**! Here's what's ready:

- ✅ **Dependencies installed**: pymongo 4.15.3, python-dotenv
- ✅ **API Keys configured**: Public and Private keys saved in `.env`
- ✅ **Security**: `.env` file is protected and excluded from git
- ⏭️ **Connection String**: Need to add `MONGODB_URI` to `.env`

## 🚀 Final Step: Get Connection String

### Step 1: Log into MongoDB Atlas

1. Go to [https://cloud.mongodb.com/](https://cloud.mongodb.com/)
2. Log in to your account

### Step 2: Get Connection String

1. Click on your **cluster** (or create one if you don't have one)
2. Click the **"Connect"** button
3. Select **"Connect your application"**
4. Choose:
   - **Driver**: Python
   - **Version**: 3.12 or later
5. **Copy the connection string** - it looks like:
   ```
   mongodb+srv://<username>:<password>@cluster0.xxxxx.mongodb.net/?retryWrites=true&w=majority
   ```

### Step 3: Update Connection String

Replace `<username>` and `<password>` with your database user credentials:

**Example:**
```
mongodb+srv://bmcadmin:MyPassword123@cluster0.abc123.mongodb.net/bmc_chat?retryWrites=true&w=majority
```

### Step 4: Add to .env File

Add the connection string to your `.env` file:

```bash
# Edit .env file
nano .env
# or
open -e .env  # macOS
```

Add this line (replace with your actual connection string):
```bash
MONGODB_URI=mongodb+srv://username:password@cluster0.xxxxx.mongodb.net/bmc_chat?retryWrites=true&w=majority
```

**Or use this command** (replace with your actual values):
```bash
echo 'MONGODB_URI=mongodb+srv://username:password@cluster0.xxxxx.mongodb.net/bmc_chat?retryWrites=true&w=majority' >> .env
```

### Step 5: Test Connection

Run the verification script:
```bash
python3 verify_mongodb_setup.py
```

Or test the connection directly:
```bash
python3 test_mongodb_atlas.py
```

## 📋 Checklist

Before connecting, make sure you have:

- [ ] **IP Address whitelisted** in Atlas → Network Access
  - Add your current IP or `0.0.0.0/0` for development
- [ ] **Database user created** in Atlas → Database Access
  - Username and password ready
- [ ] **Connection string** copied from Atlas
- [ ] **MONGODB_URI** added to `.env` file
- [ ] **Connection tested** with `verify_mongodb_setup.py`

## 🔍 Troubleshooting

### "IP not whitelisted"
- Go to Atlas → Network Access
- Click "Add IP Address"
- Add your current IP or `0.0.0.0/0` for development

### "Authentication failed"
- Verify username and password in connection string
- URL-encode special characters in password:
  - `@` → `%40`
  - `#` → `%23`
  - `$` → `%24`

### "Connection timeout"
- Check internet connectivity
- Verify IP whitelist includes your IP
- Check firewall settings

## 🎯 What's Next?

Once connected, you can:

1. **Use MongoDB in your code**:
   ```python
   from dotenv import load_dotenv
   from pymongo import MongoClient
   import os
   
   load_dotenv()
   client = MongoClient(os.getenv('MONGODB_URI'))
   db = client.bmc_chat
   ```

2. **Use API Keys for Vector Search**:
   ```python
   import os
   from dotenv import load_dotenv
   
   load_dotenv()
   public_key = os.getenv('MONGODB_ATLAS_PUBLIC_KEY')
   private_key = os.getenv('MONGODB_ATLAS_PRIVATE_KEY')
   # Use with Atlas Data API or Vector Search
   ```

3. **Test your setup**:
   ```bash
   python3 verify_mongodb_setup.py
   ```

## 📚 Documentation

- **[MONGODB_ATLAS_SETUP.md](MONGODB_ATLAS_SETUP.md)** - Complete setup guide
- **[MONGODB_CREDENTIALS.md](MONGODB_CREDENTIALS.md)** - API keys usage guide
- **[test_mongodb_atlas.py](test_mongodb_atlas.py)** - Connection test script
- **[verify_mongodb_setup.py](verify_mongodb_setup.py)** - Full setup verification

---

**Need help?** Check the troubleshooting section in [MONGODB_ATLAS_SETUP.md](MONGODB_ATLAS_SETUP.md)


