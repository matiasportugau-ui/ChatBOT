#!/usr/bin/env python3
"""
Test MongoDB Atlas Connection
Verifies connectivity and configuration for MongoDB Atlas
"""

import os
import sys
from pymongo import MongoClient
from pymongo.errors import ConnectionFailure, ServerSelectionTimeoutError, ConfigurationError

def test_connection():
    """Test MongoDB Atlas connection"""
    
    # Load from environment
    mongodb_uri = os.getenv('MONGODB_URI')
    
    if not mongodb_uri:
        print("❌ Error: MONGODB_URI environment variable not set")
        print("\n💡 Set it with:")
        print("   export MONGODB_URI='mongodb+srv://username:password@cluster0.xxxxx.mongodb.net/bmc_chat'")
        print("\n   Or create a .env file with:")
        print("   MONGODB_URI=mongodb+srv://username:password@cluster0.xxxxx.mongodb.net/bmc_chat")
        return False
    
    print("🔌 Testing MongoDB Atlas connection...")
    print(f"   URI: {mongodb_uri.split('@')[0]}@***")  # Hide password in output
    
    try:
        # Create client with timeout
        client = MongoClient(
            mongodb_uri,
            serverSelectionTimeoutMS=10000,  # 10 second timeout
            connectTimeoutMS=10000
        )
        
        # Test connection
        print("\n📡 Pinging server...")
        result = client.admin.command('ping')
        print("✅ Successfully connected to MongoDB Atlas!")
        
        # Get server info
        server_info = client.server_info()
        print(f"\n📊 Server Information:")
        print(f"   Version: {server_info.get('version', 'Unknown')}")
        print(f"   Platform: {server_info.get('targetMinOS', 'Unknown')}")
        
        # List databases
        print(f"\n📁 Available databases:")
        db_names = client.list_database_names()
        for db_name in db_names[:10]:  # Show first 10
            print(f"   - {db_name}")
        if len(db_names) > 10:
            print(f"   ... and {len(db_names) - 10} more")
        
        # Test database access (extract database name from URI or use default)
        db_name = 'bmc_chat'
        if '/' in mongodb_uri.split('@')[1]:
            # Extract database from URI
            uri_part = mongodb_uri.split('@')[1]
            if '/' in uri_part:
                db_name = uri_part.split('/')[1].split('?')[0] or 'bmc_chat'
        
        print(f"\n📂 Testing database: {db_name}")
        db = client[db_name]
        
        # List collections
        collections = db.list_collection_names()
        if collections:
            print(f"   Collections ({len(collections)}):")
            for coll in collections[:10]:  # Show first 10
                count = db[coll].count_documents({})
                print(f"   - {coll}: {count} documents")
            if len(collections) > 10:
                print(f"   ... and {len(collections) - 10} more")
        else:
            print("   No collections found (database is empty)")
        
        # Test write operation
        print(f"\n✍️  Testing write operation...")
        test_collection = db['_connection_test']
        test_doc = {
            'test': True,
            'timestamp': client.server_info().get('localTime', 'unknown')
        }
        result = test_collection.insert_one(test_doc)
        print(f"   ✅ Write successful (inserted ID: {result.inserted_id})")
        
        # Clean up test document
        test_collection.delete_one({'_id': result.inserted_id})
        print(f"   🧹 Test document cleaned up")
        
        # Connection pool info
        print(f"\n🔗 Connection Pool:")
        print(f"   Max Pool Size: {client.max_pool_size}")
        print(f"   Min Pool Size: {client.min_pool_size if hasattr(client, 'min_pool_size') else 'N/A'}")
        
        print(f"\n✅ All tests passed! MongoDB Atlas is ready to use.")
        return True
        
    except ServerSelectionTimeoutError as e:
        print(f"\n❌ Connection timeout: Could not reach MongoDB Atlas servers")
        print(f"   Error: {e}")
        print("\n💡 Troubleshooting:")
        print("   1. Check your IP address is whitelisted in Atlas Network Access")
        print("   2. Verify your connection string is correct")
        print("   3. Check your internet connection")
        print("   4. Ensure ports 27015-27017 are not blocked by firewall")
        return False
        
    except ConnectionFailure as e:
        print(f"\n❌ Connection failed: {e}")
        print("\n💡 Troubleshooting:")
        print("   1. Verify username and password in connection string")
        print("   2. URL-encode special characters in password")
        print("   3. Check Database Access permissions in Atlas")
        return False
        
    except ConfigurationError as e:
        print(f"\n❌ Configuration error: {e}")
        print("\n💡 Check your connection string format")
        return False
        
    except Exception as e:
        print(f"\n❌ Unexpected error: {e}")
        print(f"   Type: {type(e).__name__}")
        return False
        
    finally:
        try:
            client.close()
        except:
            pass

def main():
    """Main function"""
    print("=" * 60)
    print("MongoDB Atlas Connection Test")
    print("=" * 60)
    print()
    
    success = test_connection()
    
    print()
    print("=" * 60)
    if success:
        print("✅ Connection test completed successfully")
        sys.exit(0)
    else:
        print("❌ Connection test failed")
        print("\n📖 See MONGODB_ATLAS_SETUP.md for detailed setup instructions")
        sys.exit(1)

if __name__ == "__main__":
    main()

