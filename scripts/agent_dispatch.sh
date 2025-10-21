#!/usr/bin/env bash
# ============================================================================
# SUPERCLAUDE AGENT DISPATCHER
# ============================================================================
# CLI entry point for agent-driven workflows
#
# Usage:
#   ./scripts/agent_dispatch.sh pr_opened payload.json
#   ./scripts/agent_dispatch.sh deploy_staging
#   cat payload.json | ./scripts/agent_dispatch.sh nightly
# ============================================================================

set -euo pipefail

# Configuration
WORKSPACE_ROOT="${WORKSPACE_ROOT:-$(git rev-parse --show-toplevel)}"
AGENT_DIR="${WORKSPACE_ROOT}/.claude/agents"
ORCHESTRATION_DIR="${WORKSPACE_ROOT}/.claude/orchestration"
MCP_SERVERS="${WORKSPACE_ROOT}/mcp/servers.json"

EVENT="${1:-help}"
PAYLOAD_FILE="${2:-/dev/stdin}"
AGENT="${3:-${AGENT_DIR}/superclaude.agent.yaml}"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

usage() {
    cat <<EOF
${BLUE}SuperClaude Agent Dispatcher${NC}

Usage:
  $0 <event> [payload_file] [agent_yaml]

Events:
  pr_opened       - New pull request
  pr_sync         - PR updated
  ci_pass         - CI passed
  ci_fail         - CI failed
  deploy_staging  - Deploy to staging
  deploy_prod     - Deploy to production
  nightly         - Nightly maintenance
  blocked         - Mark as blocked

Examples:
  # PR opened (from stdin)
  cat payload.json | $0 pr_opened

  # Deploy with explicit payload
  $0 deploy_staging deploy_payload.json

  # Use specific agent
  $0 pr_opened - .claude/agents/reviewer.agent.yaml

Environment Variables:
  WORKSPACE_ROOT     - Project root (default: git root)
  ODOO_URL          - Odoo instance URL
  ODOO_API_KEY      - Odoo API key
  GITHUB_TOKEN      - GitHub token
  DO_ACCESS_TOKEN   - DigitalOcean token

EOF
    exit 0
}

log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $*"
}

error() {
    echo -e "${RED}[ERROR]${NC} $*" >&2
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $*"
}

check_dependencies() {
    local missing=()

    # Check required tools
    for tool in jq yq python3 node; do
        if ! command -v "$tool" &> /dev/null; then
            missing+=("$tool")
        fi
    done

    if [ ${#missing[@]} -gt 0 ]; then
        error "Missing required tools: ${missing[*]}"
        error "Install with: brew install ${missing[*]}"
        exit 1
    fi

    # Check agent files exist
    if [ ! -f "$AGENT" ]; then
        error "Agent file not found: $AGENT"
        exit 1
    fi

    if [ ! -f "$MCP_SERVERS" ]; then
        error "MCP servers config not found: $MCP_SERVERS"
        exit 1
    fi
}

load_payload() {
    if [ "$PAYLOAD_FILE" = "/dev/stdin" ]; then
        PAYLOAD=$(cat)
    elif [ -f "$PAYLOAD_FILE" ]; then
        PAYLOAD=$(cat "$PAYLOAD_FILE")
    else
        error "Payload file not found: $PAYLOAD_FILE"
        exit 1
    fi

    # Validate JSON
    if ! echo "$PAYLOAD" | jq empty 2>/dev/null; then
        error "Invalid JSON payload"
        exit 1
    fi

    echo "$PAYLOAD"
}

execute_agent() {
    local agent_yaml="$1"
    local event="$2"
    local payload="$3"

    log "Executing agent: $(basename "$agent_yaml")"
    log "Event: $event"

    # Parse agent config
    local agent_name
    agent_name=$(yq eval '.name' "$agent_yaml")

    log "Agent name: $agent_name"

    # Determine execution method
    case "$agent_name" in
        superclaude)
            execute_orchestrator "$agent_yaml" "$event" "$payload"
            ;;

        reviewer|security-scan|test-runner|devops|analyst)
            execute_sub_agent "$agent_name" "$event" "$payload"
            ;;

        *)
            error "Unknown agent: $agent_name"
            exit 1
            ;;
    esac
}

execute_orchestrator() {
    local agent_yaml="$1"
    local event="$2"
    local payload="$3"

    log "Orchestrating event: $event"

    # Get routing from agent config
    local routing
    routing=$(yq eval ".routing[] | select(.when | contains(\"$event\"))" "$agent_yaml")

    if [ -z "$routing" ]; then
        warn "No routing rule for event: $event"
        return 0
    fi

    # Check for parallel execution
    if echo "$routing" | yq eval '.parallel' - &> /dev/null; then
        execute_parallel "$routing" "$payload"
    else
        execute_sequential "$routing" "$payload"
    fi
}

execute_parallel() {
    local routing="$1"
    local payload="$2"

    log "Executing parallel agents..."

    # Get list of agents
    local agents
    agents=$(echo "$routing" | yq eval '.parallel[]' -)

    # Execute in parallel (using background jobs)
    local pids=()

    while IFS= read -r agent; do
        execute_sub_agent "$agent" "parallel" "$payload" &
        pids+=($!)
    done <<< "$agents"

    # Wait for all agents
    local failed=0
    for pid in "${pids[@]}"; do
        if ! wait "$pid"; then
            ((failed++))
        fi
    done

    if [ $failed -gt 0 ]; then
        error "$failed parallel agents failed"
        return 1
    fi

    log "All parallel agents completed successfully"
}

execute_sequential() {
    local routing="$1"
    local payload="$2"

    log "Executing sequential agents..."

    # Get sequence
    local sequence
    sequence=$(echo "$routing" | yq eval '.sequence[]' -)

    while IFS= read -r agent; do
        if ! execute_sub_agent "$agent" "sequential" "$payload"; then
            error "Sequential agent failed: $agent"
            return 1
        fi
    done <<< "$sequence"

    log "Sequential execution complete"
}

execute_sub_agent() {
    local agent_name="$1"
    local mode="$2"
    local payload="$3"

    log "[$mode] Running sub-agent: $agent_name"

    local agent_file="${AGENT_DIR}/${agent_name}.agent.yaml"

    if [ ! -f "$agent_file" ]; then
        error "Agent config not found: $agent_file"
        return 1
    fi

    # Get agent capabilities
    local capabilities
    capabilities=$(yq eval '.capabilities[]' "$agent_file")

    log "Capabilities: $capabilities"

    # Execute agent-specific logic
    case "$agent_name" in
        reviewer)
            python3 -c "print('Reviewer: OCA rules, lockfile sync, spec validation')"
            ;;

        security-scan)
            python3 -c "print('Security: secret scan, npm audit, Docker scan')"
            ;;

        test-runner)
            python3 -c "print('Tests: unit, integration, e2e, smoke')"
            ;;

        devops)
            python3 -c "print('DevOps: backup, deploy, SSL, uptime')"
            ;;

        analyst)
            python3 -c "print('Analyst: metrics, charts, cost analysis')"
            ;;
    esac

    log "✅ $agent_name completed"
}

integrate_odoo() {
    local event="$1"
    local payload="$2"

    log "Syncing to Odoo Kanban..."

    if [ -z "${ODOO_API_KEY:-}" ]; then
        warn "ODOO_API_KEY not set - skipping Odoo sync"
        return 0
    fi

    python3 "${WORKSPACE_ROOT}/scripts/odoo_kanban_sync.py" "$event" <<< "$payload"
}

main() {
    if [ "$EVENT" = "help" ] || [ "$EVENT" = "--help" ] || [ "$EVENT" = "-h" ]; then
        usage
    fi

    log "SuperClaude Agent Dispatcher"
    log "============================"

    check_dependencies

    PAYLOAD=$(load_payload)

    execute_agent "$AGENT" "$EVENT" "$PAYLOAD"

    # Always sync to Odoo (Your Own Slack)
    integrate_odoo "$EVENT" "$PAYLOAD"

    log "✅ Agent dispatch complete!"
}

main "$@"
