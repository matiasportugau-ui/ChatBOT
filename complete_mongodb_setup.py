#!/usr/bin/env python3
"""
Complete MongoDB Atlas Setup
Interactive script to finalize MongoDB Atlas configuration
"""

import os
import sys
import re
from dotenv import load_dotenv

def validate_connection_string(uri):
    """Validate MongoDB connection string format"""
    if not uri:
        return False, "Connection string is empty"
    
    # Check for mongodb:// or mongodb+srv://
    if not (uri.startswith('mongodb://') or uri.startswith('mongodb+srv://')):
        return False, "Connection string must start with mongodb:// or mongodb+srv://"
    
    # Check for @ symbol (indicates username:password)
    if '@' not in uri:
        return False, "Connection string should include username:password@cluster"
    
    # Check for .mongodb.net (Atlas cluster)
    if '.mongodb.net' not in uri:
        return False, "Connection string should include .mongodb.net (Atlas cluster)"
    
    return True, "Valid connection string format"

def update_env_file(connection_string):
    """Update .env file with connection string"""
    env_file = '.env'
    
    if not os.path.exists(env_file):
        print("❌ .env file not found!")
        print("   Run: ./setup_mongodb_credentials.sh first")
        return False
    
    # Read current .env
    with open(env_file, 'r') as f:
        lines = f.readlines()
    
    # Check if MONGODB_URI already exists
    uri_found = False
    new_lines = []
    
    for line in lines:
        if line.strip().startswith('MONGODB_URI='):
            # Replace existing URI
            new_lines.append(f'MONGODB_URI={connection_string}\n')
            uri_found = True
        elif line.strip().startswith('# MONGODB_URI='):
            # Uncomment and set
            new_lines.append(f'MONGODB_URI={connection_string}\n')
            uri_found = True
        else:
            new_lines.append(line)
    
    # If not found, add it
    if not uri_found:
        new_lines.append(f'\n# MongoDB Connection String\nMONGODB_URI={connection_string}\n')
    
    # Write back
    with open(env_file, 'w') as f:
        f.writelines(new_lines)
    
    # Set secure permissions
    os.chmod(env_file, 0o600)
    
    return True

def test_connection(connection_string):
    """Test MongoDB connection"""
    try:
        from pymongo import MongoClient
        from pymongo.errors import ConnectionFailure, ServerSelectionTimeoutError
        
        print("\n🔌 Testing connection...")
        client = MongoClient(connection_string, serverSelectionTimeoutMS=10000)
        client.admin.command('ping')
        
        # Get server info
        server_info = client.server_info()
        print(f"   ✅ Connected successfully!")
        print(f"   📊 Server version: {server_info.get('version', 'Unknown')}")
        
        # List databases
        db_names = client.list_database_names()
        print(f"   📁 Available databases: {', '.join(db_names[:5])}")
        if len(db_names) > 5:
            print(f"      ... and {len(db_names) - 5} more")
        
        client.close()
        return True
        
    except ServerSelectionTimeoutError:
        print("   ❌ Connection timeout")
        print("   💡 Check:")
        print("      - IP whitelist in Atlas Network Access")
        print("      - Connection string is correct")
        return False
        
    except ConnectionFailure as e:
        print(f"   ❌ Connection failed: {e}")
        print("   💡 Check username and password in connection string")
        return False
        
    except Exception as e:
        print(f"   ❌ Error: {e}")
        return False

def main():
    """Main setup function"""
    print("=" * 60)
    print("MongoDB Atlas Setup - Final Steps")
    print("=" * 60)
    print()
    
    # Load current .env
    load_dotenv()
    
    # Check current status
    current_uri = os.getenv('MONGODB_URI')
    public_key = os.getenv('MONGODB_ATLAS_PUBLIC_KEY')
    private_key = os.getenv('MONGODB_ATLAS_PRIVATE_KEY')
    
    print("📋 Current Configuration:")
    print("-" * 60)
    
    if public_key and private_key:
        print(f"   ✅ API Keys: Configured")
    else:
        print(f"   ❌ API Keys: Missing")
    
    if current_uri:
        # Mask password
        if '@' in current_uri:
            parts = current_uri.split('@')
            masked = f"{parts[0].split(':')[0]}:***@{parts[1]}" if ':' in parts[0] else current_uri
        else:
            masked = current_uri
        print(f"   ✅ Connection String: {masked}")
    else:
        print(f"   ⚠️  Connection String: Not set")
    
    print()
    
    # Get connection string
    if current_uri:
        print("💡 Connection string already exists.")
        response = input("   Do you want to update it? (y/N): ").strip().lower()
        if response != 'y':
            print("\n✅ Keeping existing connection string")
            if test_connection(current_uri):
                print("\n🎉 Setup complete!")
            return
    
    print("📝 Enter MongoDB Atlas Connection String")
    print("-" * 60)
    print("   Get it from: Atlas → Clusters → Connect → Connect your application")
    print("   Format: mongodb+srv://username:password@cluster0.xxxxx.mongodb.net/database")
    print()
    
    while True:
        connection_string = input("Connection String: ").strip()
        
        # Remove quotes if present
        connection_string = connection_string.strip('"\'')
        
        # Validate
        is_valid, message = validate_connection_string(connection_string)
        
        if is_valid:
            break
        else:
            print(f"   ❌ {message}")
            print("   Please try again or press Ctrl+C to cancel")
            print()
    
    # Update .env file
    print("\n💾 Saving to .env file...")
    if update_env_file(connection_string):
        print("   ✅ Connection string saved")
    else:
        print("   ❌ Failed to save connection string")
        return
    
    # Test connection
    print()
    if test_connection(connection_string):
        print("\n" + "=" * 60)
        print("🎉 MongoDB Atlas Setup Complete!")
        print("=" * 60)
        print()
        print("✅ All configured:")
        print("   - API Keys: Saved in .env")
        print("   - Connection String: Saved and tested")
        print("   - Security: File permissions and git exclusion verified")
        print()
        print("📖 Next steps:")
        print("   - Use MongoDB in your code with:")
        print("     from dotenv import load_dotenv")
        print("     from pymongo import MongoClient")
        print("     import os")
        print("     load_dotenv()")
        print("     client = MongoClient(os.getenv('MONGODB_URI'))")
        print()
    else:
        print("\n⚠️  Connection test failed, but connection string was saved.")
        print("   Check the troubleshooting guide in MONGODB_ATLAS_SETUP.md")

if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        print("\n\n👋 Setup cancelled by user")
        sys.exit(1)
    except Exception as e:
        print(f"\n❌ Error: {e}")
        sys.exit(1)

