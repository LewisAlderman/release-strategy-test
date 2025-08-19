#!/bin/bash

# Script to rename the current @dev branch to @alpha
# This handles step 2 of the branching strategy

set -e  # Exit on any error

# Source shared utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/scripts" && pwd)"
source "$SCRIPT_DIR/shared/utils.sh"

# Check if we're in a git repository
check_in_git_repo

# Check if GitHub CLI is installed and authenticated
check_gh_cli

# Check if we have uncommitted or unpushed changes
check_uncommitted_changes
check_unpushed_commits

# Get current branch
CURRENT_BRANCH=$(git branch --show-current)
print_status "Current branch: $CURRENT_BRANCH"

# Verify it's a @dev branch
validate_semantic_release_branch_format "$CURRENT_BRANCH" "dev"

# Extract version from branch name
read -r CURRENT_VERSION MAJOR MINOR PATCH RELEASE <<< "$(parse_branch_versioning "$CURRENT_BRANCH")"
ALPHA_BRANCH="v${CURRENT_VERSION}@alpha"

print_status "Will rename: $CURRENT_BRANCH → $ALPHA_BRANCH"

# Confirm the action
echo
read -p "Are you sure you want to rename $CURRENT_BRANCH to $ALPHA_BRANCH? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    print_error "Aborted."
    exit 1
fi

# Check if alpha branch already exists
if branch_exists_remotely "$ALPHA_BRANCH"; then
    print_warning "Branch $ALPHA_BRANCH already exists remotely."
    print_error "Aborted."
    exit 1
fi

print_status "Creating alpha branch from current dev branch..."

# Create the new alpha branch
git checkout -b "$ALPHA_BRANCH"

# Push the new alpha branch
git push origin "$ALPHA_BRANCH"

print_success "Created alpha branch: $ALPHA_BRANCH"

print_status "Updating default branch to alpha branch..."

# Update the default branch to the alpha branch before deleting dev
gh repo edit --default-branch "$ALPHA_BRANCH"

print_status "Deleting old dev branch..."

# Delete the old dev branch remotely first
git push origin --delete "$CURRENT_BRANCH"

# Delete the old dev branch locally (we're already on alpha branch)
git branch -D "$CURRENT_BRANCH"

print_success "Deleted old dev branch: $CURRENT_BRANCH"

print_success "✅ Branch rename completed successfully!"
echo
print_status "Summary:"
echo "  $CURRENT_BRANCH → $ALPHA_BRANCH"
echo -e "${GREEN}  Checked out on branch: $ALPHA_BRANCH${NC}"

# Check if we need to create a new dev branch
print_status "Checking if new dev branch is needed..."

# Source the shared script to check if dev branch exists
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/scripts" && pwd)"
if source "$SCRIPT_DIR/shared/check-dev-branch-exists.sh"; then
    print_status "Newer dev branch already exists, skipping creation."
else
    print_status "No newer dev branch found, creating one now..."
    
    # Call the create-dev-branch script
    if "$SCRIPT_DIR/create-dev-branch.sh"; then
        print_success "✅ New dev branch created and set as default!"
        print_status "You can now switch to the new dev branch to continue development."
    else
        print_warning "Failed to create new dev branch. You may need to create it manually."
    fi
fi
