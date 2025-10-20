#!/bin/bash

# monitor-deployments.sh - Monitor skill deployments in real-time
# Usage: ./scripts/monitor-deployments.sh [interval_seconds]

set -e

# Configuration
INTERVAL="${1:-10}"  # Default: check every 10 seconds
STATUS_FILE="$PWD/WORKTREE_STATUS.json"

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo "📊 Monitoring Odoobo Skill Deployments"
echo "Refresh interval: ${INTERVAL}s (Ctrl+C to stop)"
echo ""

# Verify doctl is installed
if ! command -v doctl &> /dev/null; then
    echo "❌ Error: doctl not found"
    echo "   Install: brew install doctl"
    exit 1
fi

# Function to get app status
get_app_status() {
    local skill=$1
    local app_name="odoobo-skill-$skill"

    # Get app ID
    local app_id=$(doctl apps list --format ID,Spec.Name --no-header 2>/dev/null | grep "$app_name" | awk '{print $1}' || echo "")

    if [ -z "$app_id" ]; then
        echo "NOT_FOUND"
        return
    fi

    # Get deployment phase
    local phase=$(doctl apps get "$app_id" --format ActiveDeployment.Phase --no-header 2>/dev/null || echo "UNKNOWN")

    # Get app URL
    local url=$(doctl apps get "$app_id" --format DefaultIngress --no-header 2>/dev/null || echo "")

    echo "${phase}|${url}|${app_id}"
}

# Function to display status
display_status() {
    clear
    echo "═══════════════════════════════════════════════════════════"
    echo "  📊 Odoobo Skill Deployment Status"
    echo "═══════════════════════════════════════════════════════════"
    echo ""
    echo "Updated: $(date '+%Y-%m-%d %H:%M:%S')"
    echo ""

    local all_skills=("pr-review" "odoo-rpc" "nl-sql" "visual-diff" "design-tokens")

    printf "%-15s %-15s %-10s %-50s\n" "SKILL" "STATUS" "HEALTH" "URL"
    echo "───────────────────────────────────────────────────────────────────────────────────"

    for skill in "${all_skills[@]}"; do
        local status_info=$(get_app_status "$skill")
        IFS='|' read -r phase url app_id <<< "$status_info"

        # Determine status color
        local status_color=$NC
        case "$phase" in
            "ACTIVE")
                status_color=$GREEN
                ;;
            "ERROR"|"CANCELED")
                status_color=$RED
                ;;
            "PENDING"|"BUILDING"|"DEPLOYING")
                status_color=$YELLOW
                ;;
            "NOT_FOUND")
                status_color=$NC
                ;;
        esac

        # Check health if app is active
        local health="N/A"
        if [ "$phase" = "ACTIVE" ] && [ -n "$url" ]; then
            if curl -sf "https://$url/health" > /dev/null 2>&1; then
                health="${GREEN}✓${NC}"
            else
                health="${RED}✗${NC}"
            fi
        fi

        # Format URL
        local formatted_url="N/A"
        if [ -n "$url" ] && [ "$url" != "" ]; then
            formatted_url="https://$url"
        fi

        printf "%-15s ${status_color}%-15s${NC} %-10s %-50s\n" \
            "$skill" "$phase" "$health" "$formatted_url"
    done

    echo ""
    echo "───────────────────────────────────────────────────────────────────────────────────"
    echo ""

    # Summary counts
    local active_count=$(doctl apps list --format Spec.Name,ActiveDeployment.Phase --no-header 2>/dev/null | grep "odoobo-skill-" | grep -c "ACTIVE" || echo "0")
    local total_count=$(doctl apps list --format Spec.Name --no-header 2>/dev/null | grep -c "odoobo-skill-" || echo "0")

    echo "Summary:"
    echo "  ${GREEN}●${NC} Active: $active_count"
    echo "  ${BLUE}●${NC} Total Apps: $total_count"
    echo ""

    # Recent deployments
    echo "Recent Deployments:"
    doctl apps list --format Spec.Name,ActiveDeployment.Phase,ActiveDeployment.UpdatedAt --no-header 2>/dev/null | \
        grep "odoobo-skill-" | head -5 | \
        awk '{printf "  - %-30s %-15s %s\n", $1, $2, $3}'

    echo ""
    echo "Press Ctrl+C to stop monitoring"
    echo "Next refresh in ${INTERVAL}s..."
}

# Function to check all health endpoints
check_all_health() {
    echo "═══════════════════════════════════════════════════════════"
    echo "  🏥 Health Check Report"
    echo "═══════════════════════════════════════════════════════════"
    echo ""

    local all_skills=("pr-review" "odoo-rpc" "nl-sql" "visual-diff" "design-tokens")
    local healthy=0
    local unhealthy=0

    for skill in "${all_skills[@]}"; do
        local status_info=$(get_app_status "$skill")
        IFS='|' read -r phase url app_id <<< "$status_info"

        if [ "$phase" = "ACTIVE" ] && [ -n "$url" ]; then
            echo -n "  Checking $skill... "

            local response=$(curl -sf "https://$url/health" 2>&1)
            if [ $? -eq 0 ]; then
                echo -e "${GREEN}✓ HEALTHY${NC}"
                echo "    Response: $response"
                healthy=$((healthy + 1))
            else
                echo -e "${RED}✗ UNHEALTHY${NC}"
                echo "    Error: $response"
                unhealthy=$((unhealthy + 1))
            fi
            echo ""
        fi
    done

    echo "───────────────────────────────────────────────────────────"
    echo "Healthy: $healthy | Unhealthy: $unhealthy"
    echo ""
}

# Handle Ctrl+C
trap 'echo ""; echo "Monitoring stopped."; exit 0' INT

# Main monitoring loop
while true; do
    display_status
    sleep "$INTERVAL"
done
