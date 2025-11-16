#!/bin/bash
################################################################################
# Knowledge Graph Auto-Rebuild Script
#
# Automatically rebuilds the knowledge graph when knowledge bases are updated.
# Run this after adding new repos, files, or content to either KB.
#
# Usage:
#   ./rebuild_graph.sh           # Full rebuild
#   ./rebuild_graph.sh --quick   # Skip metadata extraction if DB exists
################################################################################

set -e  # Exit on error

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

echo "================================================================================"
echo "🔄 Knowledge Graph Auto-Rebuild"
echo "================================================================================"
echo ""

# Parse arguments
QUICK_MODE=false
if [ "$1" == "--quick" ]; then
    QUICK_MODE=true
    echo "⚡ Quick mode: Skipping metadata extraction"
fi

# Step 1: Check for changes in knowledge bases
echo "Step 1: Checking for changes in knowledge bases..."
echo ""

ACTION_KB="$PROJECT_ROOT/knowledge-base-action"
RESEARCH_KB="$PROJECT_ROOT/knowledge-base-research"
METADATA_FILE="$PROJECT_ROOT/.cocoindex/complete-metadata.json"
DB_FILE="$PROJECT_ROOT/.cocoindex/knowledge_graph.db"

# Count files
ACTION_FILES=$(find "$ACTION_KB" -type f \( -name "*.sol" -o -name "*.md" \) 2>/dev/null | wc -l)
RESEARCH_FILES=$(find "$RESEARCH_KB" -type f \( -name "*.sol" -o -name "*.md" \) 2>/dev/null | wc -l)
TOTAL_FILES=$((ACTION_FILES + RESEARCH_FILES))

echo "📊 Knowledge Base Status:"
echo "   Action KB:   $ACTION_FILES files"
echo "   Research KB: $RESEARCH_FILES files"
echo "   Total:       $TOTAL_FILES files"
echo ""

# Step 2: Extract metadata (if needed)
if [ "$QUICK_MODE" = false ] || [ ! -f "$METADATA_FILE" ]; then
    echo "Step 2: Extracting metadata from knowledge bases..."
    echo ""

    cd "$PROJECT_ROOT"

    if [ -f "scripts/cocoindex/extract_complete_metadata.py" ]; then
        python3 scripts/cocoindex/extract_complete_metadata.py
        echo "✅ Metadata extracted successfully"
    else
        echo "⚠️  Metadata extraction script not found, skipping..."
    fi
    echo ""
else
    echo "Step 2: Skipping metadata extraction (quick mode)"
    echo ""
fi

# Step 3: Backup existing database (if it exists)
if [ -f "$DB_FILE" ]; then
    BACKUP_FILE="${DB_FILE}.backup.$(date +%Y%m%d_%H%M%S)"
    echo "Step 3: Backing up existing database..."
    cp "$DB_FILE" "$BACKUP_FILE"
    echo "✅ Backup saved: $BACKUP_FILE"
    echo ""
else
    echo "Step 3: No existing database to backup"
    echo ""
fi

# Step 4: Rebuild knowledge graph
echo "Step 4: Building knowledge graph from metadata..."
echo ""

cd "$PROJECT_ROOT"
python3 scripts/cocoindex/knowledge_graph.py

if [ $? -eq 0 ]; then
    echo "✅ Knowledge graph built successfully"
else
    echo "❌ Error building knowledge graph"

    # Restore backup if build failed
    if [ -f "$BACKUP_FILE" ]; then
        echo "🔄 Restoring backup..."
        cp "$BACKUP_FILE" "$DB_FILE"
        echo "✅ Backup restored"
    fi
    exit 1
fi
echo ""

# Step 5: Enhance with relationships
echo "Step 5: Adding relationships to knowledge graph..."
echo ""

python3 scripts/cocoindex/enhance_knowledge_graph.py

if [ $? -eq 0 ]; then
    echo "✅ Relationships added successfully"
else
    echo "❌ Error adding relationships"
    exit 1
fi
echo ""

# Step 6: Get final statistics
echo "Step 6: Generating statistics..."
echo ""

python3 scripts/cocoindex/query_kb.py stats > /tmp/kg_stats.json
STATS=$(cat /tmp/kg_stats.json)

# Extract key metrics
TOTAL_NODES=$(echo "$STATS" | grep -o '"total_nodes": [0-9]*' | grep -o '[0-9]*')
TOTAL_EDGES=$(echo "$STATS" | grep -o '"total_edges": [0-9]*' | grep -o '[0-9]*')

echo "================================================================================"
echo "✅ Knowledge Graph Rebuild Complete!"
echo "================================================================================"
echo ""
echo "📊 Final Statistics:"
echo "   Total Nodes:        $TOTAL_NODES"
echo "   Total Edges:        $TOTAL_EDGES"
echo "   KB Files Indexed:   $TOTAL_FILES"
echo ""
echo "🎯 Next Steps:"
echo "   • View graph: ./start-web.sh"
echo "   • Query KB:   python3 scripts/cocoindex/query_kb.py"
echo "   • Explore:    http://localhost:5000/graph"
echo ""

# Clean up old backups (keep last 5)
echo "🧹 Cleaning up old backups..."
ls -t "$PROJECT_ROOT/.cocoindex/"knowledge_graph.db.backup.* 2>/dev/null | tail -n +6 | xargs rm -f 2>/dev/null || true
echo ""

echo "✅ All done!"
echo ""
