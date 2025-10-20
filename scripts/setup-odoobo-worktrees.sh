#!/bin/bash
# Setup Git Worktrees for Parallel Odoobo-Expert Skill Development
# Based on Anthropic context engineering best practices
#
# Purpose: Create 5 isolated git worktrees for parallel development
# Architecture: Each skill gets independent worktree + Python venv
# Benefits: Zero context switching, parallel testing, no merge conflicts

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
REPO_ROOT="$(git rev-root 2>/dev/null || pwd)"
WORKTREE_BASE="${WORKTREE_BASE:-/tmp/odoobo-worktrees}"
MAIN_BRANCH="${MAIN_BRANCH:-main}"

# 5 Skills from Anthropic Skills architecture
SKILLS=(
  "pr-review"
  "odoo-rpc"
  "nl-sql"
  "visual-diff"
  "design-tokens"
)

# Logging functions
log_info() {
  echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
  echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
  echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
  echo -e "${RED}[ERROR]${NC} $1"
}

# Check prerequisites
check_prerequisites() {
  log_info "Checking prerequisites..."

  # Check if we're in a git repository
  if ! git rev-parse --git-dir > /dev/null 2>&1; then
    log_error "Not in a git repository. Please run from odoboo-workspace root."
    exit 1
  fi

  # Check if main branch exists
  if ! git show-ref --verify --quiet "refs/heads/${MAIN_BRANCH}"; then
    log_error "Main branch '${MAIN_BRANCH}' not found."
    exit 1
  fi

  # Check if Python 3 is available
  if ! command -v python3 &> /dev/null; then
    log_error "Python 3 not found. Please install Python 3.9+."
    exit 1
  fi

  log_success "Prerequisites check passed"
}

# Create worktree base directory
create_worktree_base() {
  log_info "Creating worktree base directory: ${WORKTREE_BASE}"

  if [ -d "${WORKTREE_BASE}" ]; then
    log_warning "Worktree base already exists. Cleaning up..."
    rm -rf "${WORKTREE_BASE}"
  fi

  mkdir -p "${WORKTREE_BASE}"
  log_success "Worktree base created"
}

# Create a single worktree for a skill
create_skill_worktree() {
  local skill=$1
  local branch_name="skill/${skill}"
  local worktree_path="${WORKTREE_BASE}/${skill}"

  log_info "Creating worktree for skill: ${skill}"

  # Check if branch already exists
  if git show-ref --verify --quiet "refs/heads/${branch_name}"; then
    log_warning "Branch ${branch_name} already exists. Deleting worktree if present..."
    git worktree remove "${worktree_path}" --force 2>/dev/null || true
    git branch -D "${branch_name}" 2>/dev/null || true
  fi

  # Create new branch from main
  git branch "${branch_name}" "${MAIN_BRANCH}"

  # Create worktree
  git worktree add "${worktree_path}" "${branch_name}"

  # Copy skill directory to worktree
  if [ -d "${REPO_ROOT}/.claude/skills/${skill}" ]; then
    log_info "Copying skill files to worktree..."
    cp -r "${REPO_ROOT}/.claude/skills/${skill}" "${worktree_path}/.claude/skills/"
  else
    log_warning "Skill directory not found: .claude/skills/${skill}"
  fi

  log_success "Worktree created: ${worktree_path}"
}

# Create Python virtual environment for worktree
create_venv() {
  local skill=$1
  local worktree_path="${WORKTREE_BASE}/${skill}"
  local venv_path="${worktree_path}/.venv"

  log_info "Creating Python venv for ${skill}..."

  cd "${worktree_path}"

  # Create venv
  python3 -m venv "${venv_path}"

  # Activate and install dependencies
  source "${venv_path}/bin/activate"

  # Upgrade pip
  pip install --quiet --upgrade pip

  # Install skill dependencies
  if [ -f ".claude/skills/${skill}/requirements.txt" ]; then
    log_info "Installing dependencies for ${skill}..."
    pip install --quiet -r ".claude/skills/${skill}/requirements.txt"
  fi

  # Install unified dependencies if exists
  if [ -f ".claude/skills/requirements.txt" ]; then
    pip install --quiet -r ".claude/skills/requirements.txt"
  fi

  deactivate

  cd "${REPO_ROOT}"

  log_success "Python venv created for ${skill}"
}

# Create helper scripts
create_helper_scripts() {
  log_info "Creating helper scripts..."

  # List worktrees script
  cat > "${REPO_ROOT}/scripts/list-worktrees.sh" << 'EOF'
#!/bin/bash
# List all odoobo-expert worktrees
git worktree list | grep -E "skill/(pr-review|odoo-rpc|nl-sql|visual-diff|design-tokens)"
EOF
  chmod +x "${REPO_ROOT}/scripts/list-worktrees.sh"

  # Switch worktree script
  cat > "${REPO_ROOT}/scripts/switch-worktree.sh" << 'EOF'
#!/bin/bash
# Switch to a skill worktree
if [ $# -eq 0 ]; then
  echo "Usage: $0 <skill-name>"
  echo "Skills: pr-review, odoo-rpc, nl-sql, visual-diff, design-tokens"
  exit 1
fi

SKILL=$1
WORKTREE_BASE="${WORKTREE_BASE:-/tmp/odoobo-worktrees}"
WORKTREE_PATH="${WORKTREE_BASE}/${SKILL}"

if [ ! -d "${WORKTREE_PATH}" ]; then
  echo "Error: Worktree not found: ${WORKTREE_PATH}"
  exit 1
fi

cd "${WORKTREE_PATH}"
source .venv/bin/activate
echo "Switched to ${SKILL} worktree"
echo "Path: ${WORKTREE_PATH}"
exec $SHELL
EOF
  chmod +x "${REPO_ROOT}/scripts/switch-worktree.sh"

  # Test skill script
  cat > "${REPO_ROOT}/scripts/test-skill.sh" << 'EOF'
#!/bin/bash
# Test a skill in its worktree
if [ $# -eq 0 ]; then
  echo "Usage: $0 <skill-name>"
  exit 1
fi

SKILL=$1
WORKTREE_BASE="${WORKTREE_BASE:-/tmp/odoobo-worktrees}"
WORKTREE_PATH="${WORKTREE_BASE}/${SKILL}"

if [ ! -d "${WORKTREE_PATH}" ]; then
  echo "Error: Worktree not found: ${WORKTREE_PATH}"
  exit 1
fi

cd "${WORKTREE_PATH}"
source .venv/bin/activate

if [ -f ".claude/skills/${SKILL}/tests/test_${SKILL//-/_}.py" ]; then
  echo "Running tests for ${SKILL}..."
  pytest ".claude/skills/${SKILL}/tests/" -v
else
  echo "No tests found for ${SKILL}"
fi
EOF
  chmod +x "${REPO_ROOT}/scripts/test-skill.sh"

  log_success "Helper scripts created"
}

# Create worktree status file
create_status_file() {
  log_info "Creating worktree status file..."

  cat > "${REPO_ROOT}/WORKTREE_STATUS.json" << EOF
{
  "created_at": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "worktree_base": "${WORKTREE_BASE}",
  "skills": {
    "pr-review": {
      "path": "${WORKTREE_BASE}/pr-review",
      "branch": "skill/pr-review",
      "status": "ready"
    },
    "odoo-rpc": {
      "path": "${WORKTREE_BASE}/odoo-rpc",
      "branch": "skill/odoo-rpc",
      "status": "ready"
    },
    "nl-sql": {
      "path": "${WORKTREE_BASE}/nl-sql",
      "branch": "skill/nl-sql",
      "status": "ready"
    },
    "visual-diff": {
      "path": "${WORKTREE_BASE}/visual-diff",
      "branch": "skill/visual-diff",
      "status": "ready"
    },
    "design-tokens": {
      "path": "${WORKTREE_BASE}/design-tokens",
      "branch": "skill/design-tokens",
      "status": "ready"
    }
  },
  "helper_scripts": {
    "list": "scripts/list-worktrees.sh",
    "switch": "scripts/switch-worktree.sh <skill-name>",
    "test": "scripts/test-skill.sh <skill-name>"
  }
}
EOF

  log_success "Status file created: WORKTREE_STATUS.json"
}

# Print summary
print_summary() {
  echo ""
  echo -e "${GREEN}========================================${NC}"
  echo -e "${GREEN}  Git Worktrees Setup Complete!${NC}"
  echo -e "${GREEN}========================================${NC}"
  echo ""
  echo -e "${BLUE}5 worktrees created:${NC}"
  for skill in "${SKILLS[@]}"; do
    echo -e "  • ${YELLOW}${skill}${NC}: ${WORKTREE_BASE}/${skill}"
  done
  echo ""
  echo -e "${BLUE}Helper scripts:${NC}"
  echo -e "  • ${YELLOW}list-worktrees.sh${NC}: List all worktrees"
  echo -e "  • ${YELLOW}switch-worktree.sh${NC}: Switch to a skill worktree"
  echo -e "  • ${YELLOW}test-skill.sh${NC}: Run tests for a skill"
  echo ""
  echo -e "${BLUE}Next steps:${NC}"
  echo -e "  1. Switch to a worktree: ${YELLOW}./scripts/switch-worktree.sh pr-review${NC}"
  echo -e "  2. Make changes in the skill directory"
  echo -e "  3. Test: ${YELLOW}./scripts/test-skill.sh pr-review${NC}"
  echo -e "  4. Commit changes in the worktree"
  echo -e "  5. Repeat for other skills in parallel"
  echo ""
  echo -e "${GREEN}Status file: WORKTREE_STATUS.json${NC}"
  echo ""
}

# Main execution
main() {
  log_info "Starting odoobo-expert worktree setup..."

  check_prerequisites
  create_worktree_base

  # Create worktrees for all skills
  for skill in "${SKILLS[@]}"; do
    create_skill_worktree "${skill}"
    create_venv "${skill}"
  done

  create_helper_scripts
  create_status_file
  print_summary

  log_success "Setup complete! Ready for parallel development."
}

# Run main function
main "$@"
