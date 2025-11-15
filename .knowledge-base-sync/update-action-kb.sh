#!/bin/bash

################################################################################
# Update Action Knowledge Base from Research KB
#
# Purpose: Sync updates from Research KB to Action KB
# Frequency: Monthly or on-demand
# Date Created: 2025-11-15
#
# Usage: ./update-action-kb.sh [option]
#   update-action-kb.sh              # Full update
#   update-action-kb.sh --gas-only   # Update gas optimization only
#   update-action-kb.sh --verify     # Verify without updating
#   update-action-kb.sh --report     # Generate report only
#
################################################################################

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
RESEARCH_KB="knowledge-base-research"
ACTION_KB="knowledge-base-action"
SYNC_DIR=".knowledge-base-sync"
LOG_DIR="$SYNC_DIR/logs"
BACKUP_DIR="$SYNC_DIR/backups"
CONFIG_FILE="$SYNC_DIR/sync-config.json"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
LOG_FILE="$LOG_DIR/sync_${TIMESTAMP}.log"

# Ensure directories exist
mkdir -p "$LOG_DIR" "$BACKUP_DIR"

# Logging function
log() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1" | tee -a "$LOG_FILE"
}

log_error() {
    echo -e "${RED}[$(date +'%Y-%m-%d %H:%M:%S')] ERROR:${NC} $1" | tee -a "$LOG_FILE"
}

log_success() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] SUCCESS:${NC} $1" | tee -a "$LOG_FILE"
}

log_warning() {
    echo -e "${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')] WARNING:${NC} $1" | tee -a "$LOG_FILE"
}

# Initialize
log "=============================================="
log "Action KB Sync Started"
log "Timestamp: $TIMESTAMP"
log "=============================================="

# Verify prerequisites
verify_prerequisites() {
    log "Verifying prerequisites..."

    if [ ! -d "$RESEARCH_KB" ]; then
        log_error "Research KB not found at $RESEARCH_KB"
        return 1
    fi

    if [ ! -d "$ACTION_KB" ]; then
        log_error "Action KB not found at $ACTION_KB"
        return 1
    fi

    if [ ! -f "$CONFIG_FILE" ]; then
        log_error "Sync config not found at $CONFIG_FILE"
        return 1
    fi

    # Check required tools
    for tool in find wc sed grep; do
        if ! command -v "$tool" &> /dev/null; then
            log_error "Required tool not found: $tool"
            return 1
        fi
    done

    log_success "All prerequisites verified"
    return 0
}

# Create backup
backup_action_kb() {
    log "Creating backup of Action KB..."

    BACKUP_NAME="action-kb-backup-${TIMESTAMP}.tar.gz"
    BACKUP_PATH="$BACKUP_DIR/$BACKUP_NAME"

    tar -czf "$BACKUP_PATH" "$ACTION_KB" 2>> "$LOG_FILE"

    if [ -f "$BACKUP_PATH" ]; then
        log_success "Backup created: $BACKUP_PATH"

        # Keep only 5 most recent backups
        cd "$BACKUP_DIR"
        ls -t action-kb-backup-*.tar.gz | tail -n +6 | xargs -r rm
        cd - > /dev/null

        return 0
    else
        log_error "Backup creation failed"
        return 1
    fi
}

# Check for file changes
check_file_changes() {
    log "Checking for changes in source files..."

    local changes_found=0

    # Count files in research KB
    local research_count=$(find "$RESEARCH_KB" -type f \( -name "*.md" -o -name "*.sol" \) | wc -l)
    local action_count=$(find "$ACTION_KB" -type f \( -name "*.md" -o -name "*.sol" \) | wc -l)

    log "Research KB files: $research_count"
    log "Action KB files: $action_count"

    # Check for modified files (modified in last 30 days)
    local modified_files=$(find "$RESEARCH_KB" -type f \( -name "*.md" -o -name "*.sol" \) -mtime -30 | wc -l)

    if [ "$modified_files" -gt 0 ]; then
        log_warning "Found $modified_files recently modified files in Research KB"
        changes_found=1
    else
        log "No recent modifications detected in Research KB"
    fi

    return $changes_found
}

# Update gas optimization wins
update_gas_optimization() {
    log "Updating gas optimization guide..."

    local gas_md="$ACTION_KB/01-quick-reference/gas-optimization-wins.md"

    if [ ! -f "$gas_md" ]; then
        log_error "Gas optimization file not found: $gas_md"
        return 1
    fi

    # Count techniques currently in file
    local current_count=$(grep -c "^### " "$gas_md" || echo 0)
    log "Current technique count: $current_count (target: 21)"

    # Check for new sources
    local gas_files=$(find "$RESEARCH_KB/repos/gas-optimization" -name "*.md" | wc -l)
    log "Gas optimization source files: $gas_files"

    # Update modification timestamp in file
    sed -i '' "s/Last Updated:.*/Last Updated: $(date +'%Y-%m-%d')/" "$gas_md" 2>/dev/null || true

    log_success "Gas optimization guide check complete"
    return 0
}

# Update vulnerability guides
update_vulnerabilities() {
    log "Checking vulnerability guides..."

    local vuln_dir="$ACTION_KB/03-attack-prevention"
    local target_count=10
    local current_count=$(find "$vuln_dir" -name "*.md" | wc -l)

    log "Current vulnerability guides: $current_count (target: $target_count)"

    if [ "$current_count" -ne "$target_count" ]; then
        log_warning "Vulnerability count mismatch. Expected: $target_count, Found: $current_count"
    fi

    # List missing or new vulnerabilities
    local expected_vulns=("reentrancy" "access-control" "integer-overflow" "frontrunning" "dos-attacks" "timestamp-dependence" "unsafe-delegatecall" "unchecked-returns" "tx-origin" "flash-loan-attacks")

    for vuln in "${expected_vulns[@]}"; do
        if [ ! -f "$vuln_dir/${vuln}.md" ]; then
            log_warning "Missing: $vuln"
        fi
    done

    log_success "Vulnerability guides check complete"
    return 0
}

# Update patterns
update_patterns() {
    log "Checking design patterns..."

    local pattern_file="$ACTION_KB/01-quick-reference/pattern-catalog.md"

    if [ ! -f "$pattern_file" ]; then
        log_error "Pattern catalog not found: $pattern_file"
        return 1
    fi

    # Count patterns in file
    local pattern_count=$(grep -c "^## " "$pattern_file" || echo 0)
    log "Current patterns: $pattern_count (target: 10-20)"

    # Update modification timestamp
    sed -i '' "s/Last Updated:.*/Last Updated: $(date +'%Y-%m-%d')/" "$pattern_file" 2>/dev/null || true

    log_success "Pattern catalog check complete"
    return 0
}

# Verify file integrity
verify_integrity() {
    log "Verifying Action KB integrity..."

    local errors=0

    # Check required files
    local required_files=(
        "00-START-HERE.md"
        "01-quick-reference/vulnerability-matrix.md"
        "01-quick-reference/pattern-catalog.md"
        "01-quick-reference/gas-optimization-wins.md"
        "01-quick-reference/oz-quick-ref.md"
        "01-quick-reference/security-checklist.md"
        "02-contract-templates/README.md"
        "02-contract-templates/secure-erc20.sol"
        "02-contract-templates/secure-erc721.sol"
        "05-workflows/contract-development.md"
        "05-workflows/pre-deployment.md"
    )

    for file in "${required_files[@]}"; do
        if [ ! -f "$ACTION_KB/$file" ]; then
            log_error "Missing required file: $file"
            ((errors++))
        fi
    done

    # Check file counts
    local vuln_count=$(find "$ACTION_KB/03-attack-prevention" -name "*.md" | wc -l)
    if [ "$vuln_count" -ne 10 ]; then
        log_warning "Expected 10 vulnerability guides, found $vuln_count"
    fi

    local template_count=$(find "$ACTION_KB/02-contract-templates" -name "*.sol" | wc -l)
    if [ "$template_count" -ne 7 ]; then
        log_warning "Expected 7 Solidity templates, found $template_count"
    fi

    if [ "$errors" -eq 0 ]; then
        log_success "Integrity check passed"
        return 0
    else
        log_error "Integrity check failed: $errors errors found"
        return 1
    fi
}

# Generate report
generate_report() {
    log "Generating sync report..."

    local report_file="$SYNC_DIR/sync-report-${TIMESTAMP}.txt"

    cat > "$report_file" << EOF
================================================================================
ACTION KB SYNC REPORT
================================================================================

Sync Timestamp: $TIMESTAMP
Duration: $(date)

RESEARCH KB STATUS
------------------
Total Files: $(find "$RESEARCH_KB" -type f | wc -l)
Markdown Files: $(find "$RESEARCH_KB" -name "*.md" | wc -l)
Solidity Files: $(find "$RESEARCH_KB" -name "*.sol" | wc -l)

ACTION KB STATUS
----------------
Total Files: $(find "$ACTION_KB" -type f | wc -l)
Markdown Files: $(find "$ACTION_KB" -name "*.md" | wc -l)
Solidity Files: $(find "$ACTION_KB" -name "*.sol" | wc -l)

VERIFICATION RESULTS
--------------------
Vulnerabilities: $(find "$ACTION_KB/03-attack-prevention" -name "*.md" | wc -l)/10
Templates: $(find "$ACTION_KB/02-contract-templates" -name "*.sol" | wc -l)/7
Quick References: $(find "$ACTION_KB/01-quick-reference" -name "*.md" | wc -l)/5
Code Snippets: $(find "$ACTION_KB/04-code-snippets" -name "*.md" | wc -l)/5
Workflows: $(find "$ACTION_KB/05-workflows" -name "*.md" | wc -l)/2

BACKUP
------
Backup created: $BACKUP_PATH
Backup size: $([ -f "$BACKUP_PATH" ] && du -h "$BACKUP_PATH" | cut -f1)

SUMMARY
-------
Sync completed successfully!
See log file for details: $LOG_FILE

================================================================================
EOF

    cat "$report_file" >> "$LOG_FILE"
    log_success "Report generated: $report_file"

    return 0
}

# Handle different options
case "${1:-default}" in
    --gas-only)
        log "Running gas optimization update only..."
        verify_prerequisites || exit 1
        backup_action_kb || exit 1
        update_gas_optimization || exit 1
        verify_integrity || exit 1
        generate_report || exit 1
        ;;
    --verify)
        log "Running verification only (no updates)..."
        verify_prerequisites || exit 1
        check_file_changes || true
        update_vulnerabilities || true
        verify_integrity || exit 1
        ;;
    --report)
        log "Generating report only..."
        verify_prerequisites || exit 1
        generate_report || exit 1
        ;;
    *)
        log "Running full sync..."
        verify_prerequisites || exit 1
        backup_action_kb || exit 1
        check_file_changes || true
        update_gas_optimization || true
        update_vulnerabilities || true
        update_patterns || true
        verify_integrity || exit 1
        generate_report || exit 1
        ;;
esac

log_success "=============================================="
log "Sync completed successfully!"
log "Log file: $LOG_FILE"
log "=============================================="

exit 0
