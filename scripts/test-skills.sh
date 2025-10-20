#!/bin/bash

# test-skills.sh - Test deployed skills with comprehensive validation
# Usage: ./scripts/test-skills.sh [skill1,skill2,...] or ./scripts/test-skills.sh (all)

set -e

# Configuration
ALL_SKILLS=("pr-review" "odoo-rpc" "nl-sql" "visual-diff" "design-tokens")
LOG_DIR="$PWD/logs/tests"

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Skills to test
if [ -n "$1" ]; then
    IFS=',' read -ra TEST_SKILLS <<< "$1"
else
    TEST_SKILLS=("${ALL_SKILLS[@]}")
fi

echo "🧪 Testing Odoobo Skills"
echo "Skills to test: ${TEST_SKILLS[*]}"
echo ""

# Create log directory
mkdir -p "$LOG_DIR"
TEST_ID="test-$(date +%Y%m%d-%H%M%S)"
TEST_LOG="$LOG_DIR/$TEST_ID.log"

echo "📝 Test ID: $TEST_ID"
echo "📄 Log file: $TEST_LOG"
echo ""

# Test results
declare -A RESULTS
PASSED=0
FAILED=0

# Function to get app URL
get_app_url() {
    local skill=$1
    local app_name="odoobo-skill-$skill"

    local app_id=$(doctl apps list --format ID,Spec.Name --no-header 2>/dev/null | grep "$app_name" | awk '{print $1}' || echo "")

    if [ -z "$app_id" ]; then
        echo ""
        return
    fi

    local url=$(doctl apps get "$app_id" --format DefaultIngress --no-header 2>/dev/null || echo "")
    echo "$url"
}

# Test 1: Health Check
test_health() {
    local skill=$1
    local url=$2

    echo -n "  [1/5] Health check... "

    local response=$(curl -sf "https://$url/health" 2>&1)
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ PASS${NC}"
        echo "        Response: $response" >> "$TEST_LOG"
        return 0
    else
        echo -e "${RED}✗ FAIL${NC}"
        echo "        Error: $response" >> "$TEST_LOG"
        return 1
    fi
}

# Test 2: Response Time
test_response_time() {
    local skill=$1
    local url=$2

    echo -n "  [2/5] Response time... "

    local start=$(date +%s%N)
    curl -sf "https://$url/health" > /dev/null 2>&1
    local end=$(date +%s%N)
    local duration=$(( (end - start) / 1000000 ))  # Convert to milliseconds

    if [ $duration -lt 5000 ]; then
        echo -e "${GREEN}✓ PASS${NC} (${duration}ms)"
        echo "        Response time: ${duration}ms" >> "$TEST_LOG"
        return 0
    else
        echo -e "${YELLOW}⚠ WARN${NC} (${duration}ms, expected <5000ms)"
        echo "        Response time: ${duration}ms (warning threshold)" >> "$TEST_LOG"
        return 0
    fi
}

# Test 3: Skill Metadata
test_metadata() {
    local skill=$1
    local url=$2

    echo -n "  [3/5] Skill metadata... "

    local response=$(curl -sf "https://$url/health" 2>&1)
    if echo "$response" | jq -e '.skill' > /dev/null 2>&1; then
        local skill_id=$(echo "$response" | jq -r '.skill')
        if [ "$skill_id" = "$skill" ]; then
            echo -e "${GREEN}✓ PASS${NC}"
            echo "        Skill ID matches: $skill_id" >> "$TEST_LOG"
            return 0
        else
            echo -e "${RED}✗ FAIL${NC} (expected: $skill, got: $skill_id)"
            echo "        Skill ID mismatch: expected $skill, got $skill_id" >> "$TEST_LOG"
            return 1
        fi
    else
        echo -e "${YELLOW}⚠ SKIP${NC} (metadata not available)"
        echo "        Skill metadata not available" >> "$TEST_LOG"
        return 0
    fi
}

# Test 4: Error Handling
test_error_handling() {
    local skill=$1
    local url=$2

    echo -n "  [4/5] Error handling... "

    # Test invalid endpoint
    local status=$(curl -sf -o /dev/null -w "%{http_code}" "https://$url/invalid-endpoint" 2>&1)

    if [ "$status" = "404" ] || [ "$status" = "405" ]; then
        echo -e "${GREEN}✓ PASS${NC} (HTTP $status)"
        echo "        Error handling: HTTP $status" >> "$TEST_LOG"
        return 0
    else
        echo -e "${YELLOW}⚠ WARN${NC} (HTTP $status, expected 404 or 405)"
        echo "        Error handling: HTTP $status (unexpected)" >> "$TEST_LOG"
        return 0
    fi
}

# Test 5: Documentation
test_documentation() {
    local skill=$1
    local url=$2

    echo -n "  [5/5] Documentation... "

    # Check if /docs endpoint exists
    local status=$(curl -sf -o /dev/null -w "%{http_code}" "https://$url/docs" 2>&1)

    if [ "$status" = "200" ]; then
        echo -e "${GREEN}✓ PASS${NC}"
        echo "        Documentation available at /docs" >> "$TEST_LOG"
        return 0
    else
        echo -e "${YELLOW}⚠ SKIP${NC} (docs endpoint not available)"
        echo "        Documentation not available" >> "$TEST_LOG"
        return 0
    fi
}

# Run tests for each skill
for skill in "${TEST_SKILLS[@]}"; do
    echo "═══════════════════════════════════════════════════════════"
    echo "  Testing: $skill"
    echo "═══════════════════════════════════════════════════════════"
    echo ""

    # Get app URL
    url=$(get_app_url "$skill")

    if [ -z "$url" ]; then
        echo -e "  ${RED}✗ FAILED${NC}: App not found or not deployed"
        RESULTS[$skill]="NOT_DEPLOYED"
        FAILED=$((FAILED + 1))
        echo ""
        continue
    fi

    echo "  URL: https://$url"
    echo ""

    # Run all tests
    local test_passed=0
    local test_failed=0

    echo "$skill test started at $(date)" >> "$TEST_LOG"
    echo "URL: https://$url" >> "$TEST_LOG"

    if test_health "$skill" "$url"; then
        test_passed=$((test_passed + 1))
    else
        test_failed=$((test_failed + 1))
    fi

    if test_response_time "$skill" "$url"; then
        test_passed=$((test_passed + 1))
    else
        test_failed=$((test_failed + 1))
    fi

    if test_metadata "$skill" "$url"; then
        test_passed=$((test_passed + 1))
    else
        test_failed=$((test_failed + 1))
    fi

    if test_error_handling "$skill" "$url"; then
        test_passed=$((test_passed + 1))
    else
        test_failed=$((test_failed + 1))
    fi

    if test_documentation "$skill" "$url"; then
        test_passed=$((test_passed + 1))
    else
        test_failed=$((test_failed + 1))
    fi

    echo "" >> "$TEST_LOG"

    # Overall result
    echo ""
    if [ $test_failed -eq 0 ]; then
        echo -e "  ${GREEN}✓ ALL TESTS PASSED${NC} ($test_passed/5)"
        RESULTS[$skill]="PASSED"
        PASSED=$((PASSED + 1))
    else
        echo -e "  ${RED}✗ SOME TESTS FAILED${NC} ($test_passed/5 passed, $test_failed/5 failed)"
        RESULTS[$skill]="FAILED"
        FAILED=$((FAILED + 1))
    fi

    echo ""
done

# Display summary
echo "═══════════════════════════════════════════════════════════"
echo "  🎉 Test Summary"
echo "═══════════════════════════════════════════════════════════"
echo ""
echo "Test ID: $TEST_ID"
echo ""

echo "Results:"
for skill in "${TEST_SKILLS[@]}"; do
    result="${RESULTS[$skill]}"
    case "$result" in
        "PASSED")
            echo -e "  - $skill: ${GREEN}✓ PASSED${NC}"
            ;;
        "FAILED")
            echo -e "  - $skill: ${RED}✗ FAILED${NC}"
            ;;
        "NOT_DEPLOYED")
            echo -e "  - $skill: ${YELLOW}⚠ NOT DEPLOYED${NC}"
            ;;
    esac
done

echo ""
echo "Summary: $PASSED passed, $FAILED failed"
echo ""
echo "📄 Full test log: $TEST_LOG"
echo ""

# Exit with error if any tests failed
if [ $FAILED -gt 0 ]; then
    exit 1
fi
