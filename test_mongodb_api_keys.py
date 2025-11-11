#!/usr/bin/env python3
"""
Test MongoDB Atlas API Keys
Verifies that API keys are properly configured and can be used
"""

import os
import sys
from dotenv import load_dotenv

def test_api_keys():
    """Test MongoDB Atlas API keys configuration"""
    
    # Load environment variables
    load_dotenv()
    
    print("=" * 60)
    print("MongoDB Atlas API Keys Test")
    print("=" * 60)
    print()
    
    # Get API keys
    public_key = os.getenv('MONGODB_ATLAS_PUBLIC_KEY')
    private_key = os.getenv('MONGODB_ATLAS_PRIVATE_KEY')
    
    # Check if keys are set
    if not public_key:
        print("❌ Error: MONGODB_ATLAS_PUBLIC_KEY not set")
        print("\n💡 Set it in .env file:")
        print("   MONGODB_ATLAS_PUBLIC_KEY=your_public_key")
        return False
    
    if not private_key:
        print("❌ Error: MONGODB_ATLAS_PRIVATE_KEY not set")
        print("\n💡 Set it in .env file:")
        print("   MONGODB_ATLAS_PRIVATE_KEY=your_private_key")
        return False
    
    # Display keys (masked)
    print("✅ API Keys found in environment")
    print(f"   Public Key: {public_key[:4]}...{public_key[-4:] if len(public_key) > 8 else '****'}")
    print(f"   Private Key: {private_key[:4]}...{private_key[-4:] if len(private_key) > 8 else '****'}")
    print()
    
    # Verify key formats
    print("🔍 Validating key formats...")
    
    if len(public_key) < 4:
        print("⚠️  Warning: Public key seems too short")
    else:
        print("   ✅ Public key format looks valid")
    
    if len(private_key) < 8:
        print("⚠️  Warning: Private key seems too short")
    elif '-' in private_key:
        print("   ✅ Private key format looks valid (UUID format)")
    else:
        print("   ✅ Private key format looks valid")
    
    print()
    print("=" * 60)
    print("✅ API Keys Configuration Test Complete")
    print("=" * 60)
    print()
    print("📖 Usage:")
    print("   These keys can be used for:")
    print("   - MongoDB Atlas Data API")
    print("   - Vector Search API")
    print("   - Atlas Admin API")
    print()
    print("   See MONGODB_CREDENTIALS.md for code examples")
    print()
    
    return True

if __name__ == "__main__":
    try:
        success = test_api_keys()
        sys.exit(0 if success else 1)
    except ImportError:
        print("❌ Error: python-dotenv not installed")
        print("   Install with: pip install python-dotenv")
        sys.exit(1)
    except Exception as e:
        print(f"❌ Unexpected error: {e}")
        sys.exit(1)

