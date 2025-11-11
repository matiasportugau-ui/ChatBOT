#!/bin/bash
# SQLTools Setup Verification Script
# Verifies that SQLTools integration is properly configured

echo "🔍 Verifying SQLTools Integration..."
echo ""

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if .vscode/settings.json exists
echo "1. Checking .vscode/settings.json..."
if [ -f ".vscode/settings.json" ]; then
    if grep -q "sqltools.connections" .vscode/settings.json; then
        echo -e "${GREEN}✓${NC} .vscode/settings.json exists and contains SQLTools configuration"
    else
        echo -e "${RED}✗${NC} .vscode/settings.json exists but missing SQLTools configuration"
    fi
else
    echo -e "${RED}✗${NC} .vscode/settings.json not found"
fi

# Check if workspace file has SQLTools config
echo ""
echo "2. Checking ChatBOTevo.code-workspace..."
if [ -f "ChatBOTevo.code-workspace" ]; then
    if grep -q "sqltools.connections" ChatBOTevo.code-workspace; then
        echo -e "${GREEN}✓${NC} Workspace file contains SQLTools configuration"
    else
        echo -e "${YELLOW}⚠${NC} Workspace file exists but missing SQLTools configuration"
    fi
    
    if grep -q "mtxr.sqltools" ChatBOTevo.code-workspace; then
        echo -e "${GREEN}✓${NC} Workspace file includes SQLTools extension recommendations"
    else
        echo -e "${YELLOW}⚠${NC} Workspace file missing SQLTools extension recommendations"
    fi
else
    echo -e "${YELLOW}⚠${NC} ChatBOTevo.code-workspace not found"
fi

# Check if SQLTOOLS_SETUP.md exists
echo ""
echo "3. Checking documentation..."
if [ -f "SQLTOOLS_SETUP.md" ]; then
    echo -e "${GREEN}✓${NC} SQLTOOLS_SETUP.md exists"
else
    echo -e "${RED}✗${NC} SQLTOOLS_SETUP.md not found"
fi

# Check if example queries exist
echo ""
echo "4. Checking example queries..."
if [ -f "queries/example_queries.sql" ]; then
    echo -e "${GREEN}✓${NC} queries/example_queries.sql exists"
    QUERY_COUNT=$(grep -c "^--" queries/example_queries.sql 2>/dev/null || echo "0")
    echo "   Found $QUERY_COUNT comment sections (indicating query categories)"
else
    echo -e "${RED}✗${NC} queries/example_queries.sql not found"
fi

# Check if PostgreSQL is accessible
echo ""
echo "5. Checking PostgreSQL connection..."
if command -v psql &> /dev/null; then
    if PGPASSWORD=atc_pass psql -h localhost -p 5432 -U atc -d atcdb -c "SELECT 1;" &> /dev/null; then
        echo -e "${GREEN}✓${NC} PostgreSQL is accessible on localhost:5432"
        
        # Check if tables exist
        TABLE_COUNT=$(PGPASSWORD=atc_pass psql -h localhost -p 5432 -U atc -d atcdb -t -c "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = 'public';" 2>/dev/null | tr -d ' ')
        if [ ! -z "$TABLE_COUNT" ] && [ "$TABLE_COUNT" != "0" ]; then
            echo -e "${GREEN}✓${NC} Found $TABLE_COUNT tables in database"
        else
            echo -e "${YELLOW}⚠${NC} No tables found in database (may need to run schema.sql)"
        fi
    else
        echo -e "${YELLOW}⚠${NC} Cannot connect to PostgreSQL (may not be running)"
        echo "   Try: docker-compose up -d postgres"
    fi
else
    echo -e "${YELLOW}⚠${NC} psql command not found (PostgreSQL client not installed)"
    echo "   This is optional - SQLTools can connect without psql"
fi

# Check Docker
echo ""
echo "6. Checking Docker..."
if command -v docker &> /dev/null; then
    if docker ps | grep -q postgres; then
        echo -e "${GREEN}✓${NC} PostgreSQL container is running"
    else
        echo -e "${YELLOW}⚠${NC} PostgreSQL container not running"
        echo "   Try: docker-compose up -d postgres"
    fi
else
    echo -e "${YELLOW}⚠${NC} Docker not found (optional if using local PostgreSQL)"
fi

# Summary
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📋 Summary"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Next steps:"
echo "1. Install SQLTools extension in VS Code/Cursor:"
echo "   - Main: mtxr.sqltools"
echo "   - Driver: mtxr.sqltools-driver-pg"
echo ""
echo "2. Open SQLTools sidebar and connect to:"
echo "   - 'PostgreSQL - ChatBOT (Docker)' or"
echo "   - 'PostgreSQL - ChatBOT (Local)'"
echo ""
echo "3. Open queries/example_queries.sql and test queries"
echo ""
echo "4. See SQLTOOLS_SETUP.md for detailed instructions"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

