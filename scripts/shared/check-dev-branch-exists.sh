#!/bin/bash

# Shared script to check if a newer @dev branch exists than the current alpha release
# Returns 0 (success) if a newer dev branch exists, 1 if it doesn't

set -e

# Source shared utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/utils.sh"

# Check if we're in a git repository
check_in_git_repo

# Get current branch
CURRENT_BRANCH=$(git branch --show-current)

# Verify it's an @alpha branch
validate_semantic_release_branch_format "$CURRENT_BRANCH" "alpha"

# Parse version and get next versions
read -r CURRENT_VERSION MAJOR MINOR PATCH RELEASE <<< "$(parse_branch_versioning "$CURRENT_BRANCH")"

# Calculate what the next dev branch should be (increment minor, reset patch)
NEXT_DEV_BRANCH="v${MAJOR}.${MINOR + 1}.0@dev"

print_status "Current alpha version: $CURRENT_VERSION"
print_status "Checking if $NEXT_DEV_BRANCH exists..."

# Check if the next dev branch exists remotely
if branch_exists_remotely "$NEXT_DEV_BRANCH"; then
    print_success "Found existing dev branch: $NEXT_DEV_BRANCH"
    exit 0  # Success - dev branch exists
else
    print_status "No existing dev branch found for $NEXT_DEV_BRANCH"
    exit 1  # Failure - dev branch doesn't exist
fi
