#!/bin/bash

# ============================================================================
# QUICK AUTHENTICATION VERIFICATION
# ============================================================================
# Run this after fixing authentication to verify everything works
# ============================================================================

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "🔍 AUTHENTICATION VERIFICATION"
echo "==============================="
echo ""

PASS=0
FAIL=0

# Test 1: Git
echo -n "Git configuration... "
if git config --global user.name &> /dev/null && git config --global user.email &> /dev/null; then
    echo -e "${GREEN}✅${NC}"
    ((PASS++))
else
    echo -e "${RED}❌${NC}"
    ((FAIL++))
fi

# Test 2: SSH
echo -n "GitHub SSH... "
if timeout 5 ssh -T git@github.com 2>&1 | grep -q "successfully authenticated"; then
    echo -e "${GREEN}✅${NC}"
    ((PASS++))
else
    echo -e "${RED}❌${NC}"
    ((FAIL++))
fi

# Test 3: GitHub CLI
echo -n "GitHub CLI... "
if command -v gh &> /dev/null && gh auth status &> /dev/null; then
    echo -e "${GREEN}✅${NC}"
    ((PASS++))
else
    echo -e "${YELLOW}⚠${NC}  (not installed or not authenticated)"
    ((FAIL++))
fi

# Test 4: Supabase CLI
echo -n "Supabase CLI... "
if command -v supabase &> /dev/null && [ -f "$HOME/.supabase/access-token" ]; then
    echo -e "${GREEN}✅${NC}"
    ((PASS++))
else
    echo -e "${YELLOW}⚠${NC}  (not installed or not authenticated)"
    ((FAIL++))
fi

# Test 5: DigitalOcean CLI
echo -n "DigitalOcean CLI... "
if command -v doctl &> /dev/null && doctl account get &> /dev/null; then
    echo -e "${GREEN}✅${NC}"
    ((PASS++))
else
    echo -e "${YELLOW}⚠${NC}  (not installed or not authenticated)"
    ((FAIL++))
fi

# Test 6: Vercel CLI
echo -n "Vercel CLI... "
if command -v vercel &> /dev/null && [ -f "$HOME/.vercel/auth.json" ]; then
    echo -e "${GREEN}✅${NC}"
    ((PASS++))
else
    echo -e "${YELLOW}⚠${NC}  (not installed or not authenticated)"
    ((FAIL++))
fi

echo ""
echo "═══════════════════════════════"
echo -e "Passed: ${GREEN}$PASS/6${NC}"
echo -e "Failed: ${RED}$FAIL/6${NC}"
echo ""

if [ $FAIL -eq 0 ]; then
    echo -e "${GREEN}🎉 All authentications verified!${NC}"
    exit 0
else
    echo -e "${YELLOW}⚠️  Some authentications need attention.${NC}"
    echo ""
    echo "Run: ./scripts/fix-all-auth.sh"
    exit 1
fi
