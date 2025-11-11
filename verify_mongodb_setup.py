#!/usr/bin/env python3
"""
Comprehensive MongoDB Atlas Setup Verification
Checks all components needed for MongoDB Atlas integration
"""

import os
import sys
from dotenv import load_dotenv

def check_dependencies():
    """Check if required packages are installed"""
    print("📦 Checking Dependencies...")
    print("-" * 60)
    
    missing = []
    
    # Check pymongo
    try:
        import pymongo
        print(f"   ✅ pymongo {pymongo.__version__}")
    except ImportError:
        print("   ❌ pymongo not installed")
        missing.append("pymongo")
    
    # Check python-dotenv
    try:
        import dotenv
        print(f"   ✅ python-dotenv installed")
    except ImportError:
        print("   ❌ python-dotenv not installed")
        missing.append("python-dotenv")
    
    if missing:
        print(f"\n   💡 Install missing packages:")
        print(f"      pip install {' '.join(missing)}")
        return False
    
    print()
    return True

def check_env_file():
    """Check if .env file exists and is readable"""
    print("📁 Checking .env File...")
    print("-" * 60)
    
    if not os.path.exists('.env'):
        print("   ❌ .env file not found")
        print("   💡 Run: ./setup_mongodb_credentials.sh")
        return False
    
    # Check permissions
    stat_info = os.stat('.env')
    mode = stat_info.st_mode & 0o777
    
    if mode > 0o600:
        print(f"   ⚠️  .env file permissions are {oct(mode)} (should be 600)")
        print("   💡 Run: chmod 600 .env")
    else:
        print(f"   ✅ .env file exists with secure permissions ({oct(mode)})")
    
    print()
    return True

def check_credentials():
    """Check if credentials are loaded"""
    print("🔑 Checking Credentials...")
    print("-" * 60)
    
    load_dotenv()
    
    public_key = os.getenv('MONGODB_ATLAS_PUBLIC_KEY')
    private_key = os.getenv('MONGODB_ATLAS_PRIVATE_KEY')
    mongodb_uri = os.getenv('MONGODB_URI')
    
    all_good = True
    
    if public_key:
        masked = f"{public_key[:4]}...{public_key[-4:] if len(public_key) > 8 else '****'}"
        print(f"   ✅ MONGODB_ATLAS_PUBLIC_KEY: {masked}")
    else:
        print("   ❌ MONGODB_ATLAS_PUBLIC_KEY not set")
        all_good = False
    
    if private_key:
        masked = f"{private_key[:4]}...{private_key[-4:] if len(private_key) > 8 else '****'}"
        print(f"   ✅ MONGODB_ATLAS_PRIVATE_KEY: {masked}")
    else:
        print("   ❌ MONGODB_ATLAS_PRIVATE_KEY not set")
        all_good = False
    
    if mongodb_uri:
        # Mask password in URI
        if '@' in mongodb_uri:
            parts = mongodb_uri.split('@')
            masked_uri = f"{parts[0].split(':')[0]}:***@{parts[1]}" if ':' in parts[0] else mongodb_uri
        else:
            masked_uri = mongodb_uri
        print(f"   ✅ MONGODB_URI: {masked_uri}")
    else:
        print("   ⚠️  MONGODB_URI not set (connection string needed)")
        print("   💡 Get connection string from Atlas → Connect → Connect your application")
        print("   💡 Add to .env: MONGODB_URI=mongodb+srv://username:password@cluster...")
    
    print()
    return all_good

def check_git_ignore():
    """Check if .env is in .gitignore"""
    print("🔒 Checking Git Security...")
    print("-" * 60)
    
    if not os.path.exists('.gitignore'):
        print("   ⚠️  .gitignore file not found")
        return False
    
    with open('.gitignore', 'r') as f:
        content = f.read()
    
    if '.env' in content:
        print("   ✅ .env is in .gitignore")
    else:
        print("   ⚠️  .env is NOT in .gitignore")
        print("   💡 Add '.env' to .gitignore to prevent accidental commits")
    
    # Check if .env is tracked
    try:
        import subprocess
        result = subprocess.run(
            ['git', 'check-ignore', '.env'],
            capture_output=True,
            text=True,
            timeout=2
        )
        if result.returncode == 0:
            print("   ✅ .env is properly ignored by git")
        else:
            print("   ⚠️  .env might be tracked by git")
            print("   💡 Check: git ls-files .env")
    except:
        pass  # Git not available or not a git repo
    
    print()
    return True

def test_connection():
    """Test MongoDB connection if URI is available"""
    print("🔌 Testing Connection...")
    print("-" * 60)
    
    load_dotenv()
    mongodb_uri = os.getenv('MONGODB_URI')
    
    if not mongodb_uri:
        print("   ⏭️  Skipping connection test (MONGODB_URI not set)")
        print()
        return None
    
    try:
        from pymongo import MongoClient
        from pymongo.errors import ConnectionFailure, ServerSelectionTimeoutError
        
        print(f"   🔗 Attempting connection...")
        client = MongoClient(mongodb_uri, serverSelectionTimeoutMS=5000)
        client.admin.command('ping')
        print("   ✅ Successfully connected to MongoDB Atlas!")
        
        # Get server info
        server_info = client.server_info()
        print(f"   📊 Server version: {server_info.get('version', 'Unknown')}")
        
        client.close()
        print()
        return True
        
    except ServerSelectionTimeoutError:
        print("   ❌ Connection timeout")
        print("   💡 Check:")
        print("      - IP whitelist in Atlas Network Access")
        print("      - Connection string is correct")
        print("      - Internet connectivity")
        print()
        return False
        
    except ConnectionFailure as e:
        print(f"   ❌ Connection failed: {e}")
        print("   💡 Check username and password in connection string")
        print()
        return False
        
    except Exception as e:
        print(f"   ❌ Error: {e}")
        print()
        return False

def main():
    """Run all checks"""
    print("=" * 60)
    print("MongoDB Atlas Setup Verification")
    print("=" * 60)
    print()
    
    results = {
        'dependencies': check_dependencies(),
        'env_file': check_env_file(),
        'credentials': check_credentials(),
        'git_security': check_git_ignore(),
    }
    
    # Only test connection if we have credentials
    if results['credentials']:
        results['connection'] = test_connection()
    
    # Summary
    print("=" * 60)
    print("Summary")
    print("=" * 60)
    
    all_checks = ['dependencies', 'env_file', 'credentials', 'git_security']
    passed = sum(1 for check in all_checks if results.get(check))
    
    print(f"✅ Passed: {passed}/{len(all_checks)} checks")
    
    if results.get('connection') is True:
        print("✅ Connection test: PASSED")
    elif results.get('connection') is False:
        print("❌ Connection test: FAILED")
    else:
        print("⏭️  Connection test: SKIPPED (no MONGODB_URI)")
    
    print()
    
    if passed == len(all_checks) and results.get('connection') is not False:
        print("🎉 Setup looks good!")
        if results.get('connection') is None:
            print("\n📝 Next step: Add MONGODB_URI to .env file")
            print("   Get it from: Atlas → Clusters → Connect → Connect your application")
    else:
        print("⚠️  Some checks failed. Review the output above.")
    
    print()

if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        print("\n\n👋 Interrupted by user")
        sys.exit(1)
    except Exception as e:
        print(f"\n❌ Unexpected error: {e}")
        sys.exit(1)


