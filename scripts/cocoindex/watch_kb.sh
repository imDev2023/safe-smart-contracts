#!/bin/bash
################################################################################
# Knowledge Base Watch & Auto-Rebuild
#
# Monitors knowledge base directories for changes and automatically
# rebuilds the knowledge graph when new content is added.
#
# Usage:
#   ./watch_kb.sh              # Watch and auto-rebuild
#   ./watch_kb.sh --once       # Check once and exit
################################################################################

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

ACTION_KB="$PROJECT_ROOT/knowledge-base-action"
RESEARCH_KB="$PROJECT_ROOT/knowledge-base-research"
CHECKSUM_FILE="$PROJECT_ROOT/.cocoindex/kb_checksums.txt"

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${BLUE}================================================================================${NC}"
echo -e "${BLUE}👀 Knowledge Base Monitor${NC}"
echo -e "${BLUE}================================================================================${NC}"
echo ""

# Function to calculate KB checksum
calculate_checksum() {
    find "$ACTION_KB" "$RESEARCH_KB" -type f \( -name "*.sol" -o -name "*.md" \) -exec md5sum {} \; 2>/dev/null | sort | md5sum | cut -d' ' -f1
}

# Function to count files
count_files() {
    find "$ACTION_KB" "$RESEARCH_KB" -type f \( -name "*.sol" -o -name "*.md" \) 2>/dev/null | wc -l
}

# Check if running in --once mode
ONCE_MODE=false
if [ "$1" == "--once" ]; then
    ONCE_MODE=true
fi

# Initial checksum
mkdir -p "$(dirname "$CHECKSUM_FILE")"
CURRENT_CHECKSUM=$(calculate_checksum)
CURRENT_COUNT=$(count_files)

if [ ! -f "$CHECKSUM_FILE" ]; then
    echo -e "${YELLOW}⚠️  No previous checksum found. Creating baseline...${NC}"
    echo "$CURRENT_CHECKSUM" > "$CHECKSUM_FILE"
    echo "$CURRENT_COUNT" >> "$CHECKSUM_FILE"

    echo -e "${GREEN}✅ Baseline created${NC}"
    echo "   Files: $CURRENT_COUNT"
    echo "   Checksum: $CURRENT_CHECKSUM"
    echo ""

    if [ "$ONCE_MODE" = true ]; then
        exit 0
    fi
fi

# Read stored checksum
STORED_CHECKSUM=$(head -n1 "$CHECKSUM_FILE" 2>/dev/null || echo "")
STORED_COUNT=$(tail -n1 "$CHECKSUM_FILE" 2>/dev/null || echo "0")

# Check for changes
if [ "$CURRENT_CHECKSUM" != "$STORED_CHECKSUM" ]; then
    echo -e "${YELLOW}🔍 Changes detected in knowledge bases!${NC}"
    echo ""
    echo "   Previous: $STORED_COUNT files (checksum: ${STORED_CHECKSUM:0:8}...)"
    echo "   Current:  $CURRENT_COUNT files (checksum: ${CURRENT_CHECKSUM:0:8}...)"
    echo ""

    if [ "$CURRENT_COUNT" -gt "$STORED_COUNT" ]; then
        NEW_FILES=$((CURRENT_COUNT - STORED_COUNT))
        echo -e "${GREEN}   📝 $NEW_FILES new file(s) added${NC}"
    elif [ "$CURRENT_COUNT" -lt "$STORED_COUNT" ]; then
        REMOVED_FILES=$((STORED_COUNT - CURRENT_COUNT))
        echo -e "${YELLOW}   🗑️  $REMOVED_FILES file(s) removed${NC}"
    else
        echo -e "${BLUE}   ✏️  File(s) modified${NC}"
    fi
    echo ""

    echo -e "${BLUE}🔄 Triggering automatic rebuild...${NC}"
    echo ""

    # Run rebuild
    "$SCRIPT_DIR/rebuild_graph.sh"

    if [ $? -eq 0 ]; then
        # Update checksum
        echo "$CURRENT_CHECKSUM" > "$CHECKSUM_FILE"
        echo "$CURRENT_COUNT" >> "$CHECKSUM_FILE"

        echo ""
        echo -e "${GREEN}================================================================================${NC}"
        echo -e "${GREEN}✅ Auto-rebuild complete!${NC}"
        echo -e "${GREEN}================================================================================${NC}"
        echo ""
        echo "   Knowledge graph is now up to date with your latest changes."
        echo ""
    else
        echo ""
        echo -e "${YELLOW}⚠️  Rebuild encountered errors. Check logs above.${NC}"
        echo ""
    fi
else
    echo -e "${GREEN}✅ No changes detected${NC}"
    echo "   Files: $CURRENT_COUNT"
    echo "   Knowledge graph is up to date"
    echo ""
fi

# Watch mode
if [ "$ONCE_MODE" = false ]; then
    echo -e "${BLUE}👀 Watching for changes... (Press Ctrl+C to stop)${NC}"
    echo ""

    while true; do
        sleep 30  # Check every 30 seconds

        NEW_CHECKSUM=$(calculate_checksum)
        if [ "$NEW_CHECKSUM" != "$CURRENT_CHECKSUM" ]; then
            echo ""
            echo -e "${YELLOW}🔍 Change detected! Rebuilding...${NC}"
            echo ""

            # Re-run this script in once mode
            "$0" --once

            CURRENT_CHECKSUM=$NEW_CHECKSUM
        fi
    done
fi
