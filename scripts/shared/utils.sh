#!/bin/bash

# Shared utilities script for branching strategy scripts
# Source this script in other scripts to use common functions and checks

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# check if we're in a git repository
check_in_git_repo() {
    if ! git rev-parse --git-dir > /dev/null 2>&1; then
        print_error "Not in a git repository. Please run this script from your project root."
        exit 1
    fi
}

# check if GitHub CLI is installed and authenticated
check_gh_cli() {
    if ! command -v gh > /dev/null 2>&1; then
        print_error "GitHub CLI (gh) is not installed."
        print_error "Please install it first:"
        print_error "  macOS: brew install gh"
        exit 1
    fi
    if ! gh auth status > /dev/null 2>&1; then
        print_error "GitHub CLI is not authenticated."
        print_error "Please run 'gh auth login' first to authenticate."
        exit 1
    fi
}

# check for uncommitted changes
check_uncommitted_changes() {
    if ! test -z "$(git status --porcelain)"; then
        print_warning "You have uncommitted changes. Please commit them before proceeding."
        git status --short
        print_error "Aborted. Please commit your changes first."
        exit 1
    fi
}

# check for unpushed commits
check_unpushed_commits() {
    if ! test -z "$(git status --porcelain --branch)"; then
        AHEAD=$(git status --porcelain --branch | grep -E '^##.*ahead' | sed 's/.*ahead \([0-9]*\).*/\1/')
        if [ -n "$AHEAD" ] && [ "$AHEAD" -gt 0 ]; then
            print_warning "You have $AHEAD unpushed commit(s). Please push them before proceeding."
            git status --short --branch
            print_error "Aborted. Please push your commits first."
            exit 1
        fi
    fi
}

# validate branch format
validate_semantic_release_branch_format() {
    local branch="$1"
    local suffix="$2"

    # Check that both branch and suffix are provided
    if [ -z "$branch" ] || [ -z "$suffix" ]; then
        print_error "validate_semantic_release_branch_format: Both branch name and suffix (dev/alpha/rc) arguments are required."
        exit 1
    fi

    local expected_format="^v[0-9]+\.[0-9]+\.[0-9]+@$suffix$"
    
    if [[ ! "$branch" =~ $expected_format ]]; then
        print_error "Branch '$branch' does not match expected format: $expected_format"
        exit 1
    fi
}

# parse version and return all version components
parse_branch_versioning() {
    local branch="$1"
    
    # Split version into major, minor, patch
    read -r major minor patch release_type <<< "$(echo "$branch" | sed -E 's/^v([0-9]+)\.([0-9]+)\.([0-9]+)@([a-z]+)/\1 \2 \3 \4/')"
    
    local semver="$major.$minor.$patch"

    # Return as space-separated values (can be captured with array assignment)
    echo "$semver $major $minor $patch $release_type"
}

# check if branch exists remotely
branch_exists_remotely() {
    local branch="$1"
    git show-ref --verify --quiet refs/remotes/origin/$branch
}