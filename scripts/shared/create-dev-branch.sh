#!/bin/bash

# Script to create a new @dev branch from the current @alpha branch
# This handles step 3 of the branching strategy

set -e  # Exit on any error

# Source shared utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/utils.sh"

# Check if we're in a git repository
check_in_git_repo

# Check if GitHub CLI is installed and authenticated
check_gh_cli

# Get current branch
CURRENT_BRANCH=$(git branch --show-current)

# Verify it's an @alpha branch
validate_semantic_release_branch_format "$CURRENT_BRANCH" "alpha"

# Parse version and get next versions
read -r CURRENT_VERSION MAJOR MINOR PATCH RELEASE <<< "$(parse_branch_versioning "$CURRENT_BRANCH")"

# Calculate what the next dev branch should be (increment minor, reset patch)
NEXT_DEV_BRANCH="v${MAJOR}.$((MINOR + 1)).0@dev"

print_status "Current alpha version: $CURRENT_VERSION"
print_status "Will create new dev branch: $NEXT_DEV_BRANCH"

# Check if the dev branch already exists
if branch_exists_remotely "$NEXT_DEV_BRANCH"; then
    print_warning "Dev branch $NEXT_DEV_BRANCH already exists."
    print_error "Aborted."
    exit 1
fi

# Confirm the action
echo
read -p "Are you sure you want to create $NEXT_DEV_BRANCH from $CURRENT_BRANCH? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    print_error "Aborted."
    exit 1
fi

print_status "Creating new dev branch from current alpha branch..."

# Create the new dev branch
git branch "$NEXT_DEV_BRANCH"

# Push the new dev branch
git push -u origin "$NEXT_DEV_BRANCH"

print_success "Created dev branch: $NEXT_DEV_BRANCH"

print_status "Setting new dev branch as default..."

# Set the new dev branch as the repository default
gh repo edit --default-branch "$NEXT_DEV_BRANCH"

print_success "Set $NEXT_DEV_BRANCH as default branch"

echo
read -p "Do you want to check out the new dev branch ($NEXT_DEV_BRANCH) now? (Y/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Nn]$ ]]; then
    print_status "Staying on current branch: $CURRENT_BRANCH"
else
    git checkout "$NEXT_DEV_BRANCH"
    echo -e "${GREEN}  Checked out on branch: $NEXT_DEV_BRANCH${NC}"
fi

