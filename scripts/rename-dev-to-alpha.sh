#!/bin/bash

# Script to rename the current @dev branch to @alpha
# This handles step 2 of the branching strategy

set -e  # Exit on any error

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

# Check if we're in a git repository
if ! git rev-parse --git-dir > /dev/null 2>&1; then
    print_error "Not in a git repository. Please run this script from your project root."
    exit 1
fi

# Check if we have uncommitted changes
if ! test -z "$(git status --porcelain)"; then
    print_warning "You have uncommitted changes. Please commit them before proceeding."
    git status --short
    print_error "Aborted. Please commit your changes first."
    exit 1
fi

# Check if we have unpushed commits
if ! test -z "$(git status --porcelain --branch)"; then
    AHEAD=$(git status --porcelain --branch | grep -E '^##.*ahead' | sed 's/.*ahead \([0-9]*\).*/\1/')
    if [ -n "$AHEAD" ] && [ "$AHEAD" -gt 0 ]; then
        print_warning "You have $AHEAD unpushed commit(s). Please push them before proceeding."
        git status --short --branch
        print_error "Aborted. Please push your commits first."
        exit 1
    fi
fi

# Get current branch
CURRENT_BRANCH=$(git branch --show-current)
print_status "Current branch: $CURRENT_BRANCH"

# Verify it's a @dev branch
if [[ ! "$CURRENT_BRANCH" =~ ^v[0-9]+\.[0-9]+\.[0-9]+@dev$ ]]; then
    print_error "Current branch '$CURRENT_BRANCH' is not a valid @dev branch"
    print_error "Expected format: v<major>.<minor>.<patch>@dev"
    exit 1
fi

# Extract version from branch name
VERSION=$(echo "$CURRENT_BRANCH" | sed 's/v\([0-9]*\.[0-9]*\.[0-9]*\)@dev/\1/')
ALPHA_BRANCH="v${VERSION}@alpha"

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
if git show-ref --verify --quiet refs/remotes/origin/$ALPHA_BRANCH; then
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

# Switch back to the old dev branch to delete it
git checkout "$CURRENT_BRANCH"

print_status "Deleting old dev branch..."

# Delete the old dev branch locally and remotely
git branch -D "$CURRENT_BRANCH"
git push origin --delete "$CURRENT_BRANCH"

print_success "Deleted old dev branch: $CURRENT_BRANCH"

# Switch to the alpha branch
git checkout "$ALPHA_BRANCH"

print_success "✅ Branch rename completed successfully!"
echo
print_status "Summary:"
echo "  Previous dev branch: $CURRENT_BRANCH"
echo "  New alpha branch: $ALPHA_BRANCH"
echo
print_status "You are now on: $ALPHA_BRANCH"
