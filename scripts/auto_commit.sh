#!/bin/bash
set -e

# ==============================================================================
# Bachat Repository - Automated Activity & Heatmap Contribution Generator
# Author: Abrar Ahmad <abrar.ahmad@iust.ac.in>
# ==============================================================================

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_DIR"

AUTHOR_NAME="Abrar Ahmad"
AUTHOR_EMAIL="abrar.ahmad@iust.ac.in"
TARGET_FILE="docs/ACTIVITY.md"

export GIT_AUTHOR_NAME="$AUTHOR_NAME"
export GIT_AUTHOR_EMAIL="$AUTHOR_EMAIL"
export GIT_COMMITTER_NAME="$AUTHOR_NAME"
export GIT_COMMITTER_EMAIL="$AUTHOR_EMAIL"

# Determine commit count: use argument if provided, otherwise random number between 2 and 19
if [ -n "$1" ]; then
    COMMIT_COUNT="$1"
else
    # RANDOM % 18 generates 0..17; adding 2 yields range [2..19]
    COMMIT_COUNT=$(( (RANDOM % 18) + 2 ))
fi

echo "==> Running automated commits generator..."
echo "==> Target commits today: $COMMIT_COUNT"

# Ensure target log file exists
mkdir -p "$(dirname "$TARGET_FILE")"
if [ ! -f "$TARGET_FILE" ]; then
    cat << 'EOF' > "$TARGET_FILE"
# Automated Repository Activity Log

This log records routine maintenance checks and automated synchronization entries.

| Timestamp (UTC) | Run ID | Checkpoint | Status |
|---|---|---|---|
EOF
fi

# Rotating commit message templates
MESSAGES=(
    "chore(activity): record maintenance heartbeat entry"
    "chore(telemetry): update repository activity timestamp"
    "docs(activity): synchronize daily contribution log"
    "chore(health): record periodic workspace integrity check"
    "chore(metrics): update automated activity snapshot"
    "docs(changelog): record routine maintenance heartbeat"
    "chore(sync): update repository sync checkpoint"
)

# Pull latest changes to avoid conflicts
git pull --rebase origin main || true

for ((i = 1; i <= COMMIT_COUNT; i++)); do
    TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    HASH=$(openssl rand -hex 4 2>/dev/null || date +%s%N | cut -c 1-8)
    MSG_INDEX=$(( RANDOM % ${#MESSAGES[@]} ))
    COMMIT_MSG="${MESSAGES[$MSG_INDEX]}"

    echo "| $TIMESTAMP | \`$HASH\` | Step $i of $COMMIT_COUNT | Verified |" >> "$TARGET_FILE"
    git add "$TARGET_FILE"
    git commit -m "$COMMIT_MSG [$i/$COMMIT_COUNT]" --author="$AUTHOR_NAME <$AUTHOR_EMAIL>"
    echo "  -> Committed ($i/$COMMIT_COUNT): $COMMIT_MSG [$i/$COMMIT_COUNT]"
    sleep 1
done

echo "==> Pushing $COMMIT_COUNT commits to origin main..."
git push origin main
echo "==> Successfully completed and pushed $COMMIT_COUNT commits!"
