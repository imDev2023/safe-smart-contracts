#!/bin/bash

################################################################################
# Quarterly Knowledge Base Review & Gap Analysis
#
# Purpose: Comprehensive quarterly review of knowledge base
# Frequency: Every 3 months (Feb, May, Aug, Nov)
# Date Created: 2025-11-15
#
# Usage: ./quarterly-review.sh [option]
#   quarterly-review.sh            # Full quarterly review
#   quarterly-review.sh --gaps     # Gap analysis only
#   quarterly-review.sh --quality  # Quality check only
#   quarterly-review.sh --outdated # Find outdated content
#
################################################################################

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
NC='\033[0m' # No Color

# Configuration
RESEARCH_KB="knowledge-base-research"
ACTION_KB="knowledge-base-action"
SYNC_DIR=".knowledge-base-sync"
LOG_DIR="$SYNC_DIR/logs"
REPORT_DIR="$SYNC_DIR/reports"
CONFIG_FILE="$SYNC_DIR/sync-config.json"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
QUARTER=$(date +%q)
YEAR=$(date +%Y)
LOG_FILE="$LOG_DIR/quarterly-review_Q${QUARTER}_${YEAR}_${TIMESTAMP}.log"
REPORT_FILE="$REPORT_DIR/quarterly-review_Q${QUARTER}_${YEAR}_${TIMESTAMP}.md"

# Ensure directories exist
mkdir -p "$LOG_DIR" "$REPORT_DIR"

# Logging function
log() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1" | tee -a "$LOG_FILE"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1" | tee -a "$LOG_FILE"
}

log_success() {
    echo -e "${GREEN}[✓]${NC} $1" | tee -a "$LOG_FILE"
}

log_warning() {
    echo -e "${YELLOW}[!]${NC} $1" | tee -a "$LOG_FILE"
}

log_section() {
    echo -e "\n${MAGENTA}=== $1 ===${NC}\n" | tee -a "$LOG_FILE"
}

# Initialize report
init_report() {
    cat > "$REPORT_FILE" << EOF
# Quarterly Knowledge Base Review
## Q${QUARTER} ${YEAR}

**Date:** $(date '+%Y-%m-%d %H:%M:%S')
**Reviewers:** Automated System
**Status:** In Progress

---

## Executive Summary

This document contains the comprehensive quarterly review of the Safe Smart Contract Knowledge Base, including gap analysis, quality metrics, and recommendations.

---

EOF
}

# Check content freshness
check_freshness() {
    log_section "Content Freshness Analysis"

    local old_files=0
    local old_days=180  # Files older than 6 months

    while IFS= read -r file; do
        if [ -f "$file" ]; then
            local mod_days=$(( ($(date +%s) - $(stat -f%m "$file" 2>/dev/null || stat -c%Y "$file")) ) / 86400 ))
            if [ "$mod_days" -gt "$old_days" ]; then
                log_warning "Outdated (${mod_days} days): $file"
                ((old_files++))
            fi
        fi
    done < <(find "$ACTION_KB" -name "*.md" -o -name "*.sol")

    if [ "$old_files" -gt 0 ]; then
        log_warning "Found $old_files files not updated in 6+ months"
    else
        log_success "All content is current (updated within 6 months)"
    fi

    cat >> "$REPORT_FILE" << EOF
### Content Freshness

- Files older than 6 months: $old_files
- Last sync: $([ -f "$SYNC_DIR/sync-config.json" ] && grep '"last_updated"' "$SYNC_DIR/sync-config.json" | head -1)
- Recommendation: Review outdated files for accuracy

EOF
}

# Gap analysis
gap_analysis() {
    log_section "Gap Analysis"

    local gaps=()

    # Check for required sections
    local required_sections=(
        "Solidity 0.8.20 specific patterns"
        "Post-merge Ethereum updates"
        "ERC-4337 Account Abstraction"
        "zkSync/Arbitrum specific patterns"
        "Modern DeFi attack vectors"
    )

    for section in "${required_sections[@]}"; do
        if ! grep -r "$section" "$ACTION_KB" > /dev/null 2>&1; then
            gaps+=("Missing: $section")
            log_warning "Gap found: $section"
        fi
    done

    # Check vulnerability coverage
    log "Verifying vulnerability coverage..."
    local required_vulns=(
        "reentrancy"
        "access-control"
        "integer-overflow"
        "frontrunning"
        "dos-attacks"
        "timestamp-dependence"
        "unsafe-delegatecall"
        "unchecked-returns"
        "tx-origin"
        "flash-loan-attacks"
    )

    for vuln in "${required_vulns[@]}"; do
        if [ ! -f "$ACTION_KB/03-attack-prevention/${vuln}.md" ]; then
            gaps+=("Missing vulnerability guide: $vuln")
            log_error "Gap: Missing $vuln"
        fi
    done

    # Check pattern completeness
    log "Checking pattern coverage..."
    local pattern_file="$ACTION_KB/01-quick-reference/pattern-catalog.md"
    if [ -f "$pattern_file" ]; then
        local pattern_count=$(grep -c "^## " "$pattern_file" || echo 0)
        if [ "$pattern_count" -lt 10 ]; then
            gaps+=("Insufficient patterns: $pattern_count (need 10+)")
            log_warning "Pattern count: $pattern_count/10"
        fi
    fi

    cat >> "$REPORT_FILE" << EOF
### Identified Gaps

Found ${#gaps[@]} gap(s):

EOF

    for gap in "${gaps[@]}"; do
        echo "- ❌ $gap" >> "$REPORT_FILE"
        log_warning "Gap: $gap"
    done

    echo "" >> "$REPORT_FILE"
}

# Quality metrics
quality_check() {
    log_section "Quality Metrics"

    local issues=0

    # Check file sizes
    log "Checking documentation completeness..."
    while IFS= read -r file; do
        if [ -f "$file" ]; then
            local size=$(wc -c < "$file")
            if [ "$size" -lt 1000 ]; then
                log_warning "File too small ($(($size/1000)) KB): $file"
                ((issues++))
            fi
        fi
    done < <(find "$ACTION_KB" -name "*.md" | grep -v README)

    # Check for code examples
    log "Verifying code examples..."
    local files_with_examples=$(grep -r "^\\`\\`\\`" "$ACTION_KB" | cut -d: -f1 | sort -u | wc -l)
    local total_md_files=$(find "$ACTION_KB" -name "*.md" | wc -l)

    log "Files with code examples: $files_with_examples/$total_md_files"

    # Check documentation
    log "Verifying NatSpec in templates..."
    local templates_missing_natspec=0
    while IFS= read -r file; do
        if [ -f "$file" ]; then
            if ! grep -q "///" "$file"; then
                ((templates_missing_natspec++))
            fi
        fi
    done < <(find "$ACTION_KB/02-contract-templates" -name "*.sol")

    log "Templates missing NatSpec: $templates_missing_natspec"

    cat >> "$REPORT_FILE" << EOF
### Quality Metrics

- Documentation files with issues: $issues
- Files with code examples: $files_with_examples/$total_md_files
- Templates missing NatSpec: $templates_missing_natspec
- Overall Quality Score: $(( (files_with_examples * 100) / total_md_files ))%

### Quality Recommendations

1. Ensure all documentation files are at least 1000 bytes
2. Include practical code examples in all guides
3. Add NatSpec to all Solidity templates
4. Verify all links are current and functional

EOF
}

# Coverage verification
coverage_verification() {
    log_section "Coverage Verification"

    # Count files
    local research_files=$(find "$RESEARCH_KB" -type f \( -name "*.md" -o -name "*.sol" \) | wc -l)
    local action_files=$(find "$ACTION_KB" -type f \( -name "*.md" -o -name "*.sol" \) | wc -l)

    log "Research KB: $research_files files"
    log "Action KB: $action_files files"

    # Category breakdown
    log_success "Vulnerability guides: $(find "$ACTION_KB/03-attack-prevention" -name "*.md" | wc -l)/10"
    log_success "Contract templates: $(find "$ACTION_KB/02-contract-templates" -name "*.sol" | wc -l)/7"
    log_success "Code snippet files: $(find "$ACTION_KB/04-code-snippets" -name "*.md" | wc -l)/5"
    log_success "Quick reference guides: $(find "$ACTION_KB/01-quick-reference" -name "*.md" | wc -l)/5"
    log_success "Workflow documents: $(find "$ACTION_KB/05-workflows" -name "*.md" | wc -l)/2"

    cat >> "$REPORT_FILE" << EOF
### Coverage Metrics

| Category | Count | Target | Status |
|----------|-------|--------|--------|
| Vulnerabilities | $(find "$ACTION_KB/03-attack-prevention" -name "*.md" | wc -l) | 10 | $([ $(find "$ACTION_KB/03-attack-prevention" -name "*.md" | wc -l) -eq 10 ] && echo "✓" || echo "✗") |
| Templates | $(find "$ACTION_KB/02-contract-templates" -name "*.sol" | wc -l) | 7 | $([ $(find "$ACTION_KB/02-contract-templates" -name "*.sol" | wc -l) -eq 7 ] && echo "✓" || echo "✗") |
| Code Snippets | $(find "$ACTION_KB/04-code-snippets" -name "*.md" | wc -l) | 5 | $([ $(find "$ACTION_KB/04-code-snippets" -name "*.md" | wc -l) -eq 5 ] && echo "✓" || echo "✗") |
| Quick References | $(find "$ACTION_KB/01-quick-reference" -name "*.md" | wc -l) | 5 | $([ $(find "$ACTION_KB/01-quick-reference" -name "*.md" | wc -l) -eq 5 ] && echo "✓" || echo "✗") |
| Workflows | $(find "$ACTION_KB/05-workflows" -name "*.md" | wc -l) | 2 | $([ $(find "$ACTION_KB/05-workflows" -name "*.md" | wc -l) -eq 2 ] && echo "✓" || echo "✗") |

EOF
}

# Recommendations
generate_recommendations() {
    log_section "Recommendations"

    cat >> "$REPORT_FILE" << EOF
## Recommendations for Next Quarter

### High Priority
1. ✓ Verify all file counts match targets
2. ✓ Update outdated content
3. ✓ Fix identified gaps
4. ✓ Improve code examples

### Medium Priority
1. Add more real-world exploit examples
2. Create video walkthroughs for complex patterns
3. Add more Foundry test examples
4. Create integration guides for specific use cases

### Low Priority
1. Enhance visual diagrams
2. Add more gas cost comparisons
3. Create best practices case studies
4. Add community feedback section

---

## Action Items

| Item | Priority | Owner | Due Date |
|------|----------|-------|----------|
| Fix identified gaps | High | Team | End of month |
| Update outdated content | High | Team | End of month |
| Improve quality metrics | Medium | Team | End of quarter |
| Add new patterns | Medium | Team | End of quarter |

---

## Sign-Off

**Reviewed By:** Automated System
**Review Date:** $(date '+%Y-%m-%d')
**Next Review:** Q$((QUARTER + 1)) (if QUARTER < 4, else Q1 next year)

---

*This report was automatically generated. For detailed logs, see: $LOG_FILE*

EOF

    log_success "Report generated: $REPORT_FILE"
}

# Main execution
main() {
    log "======================================================"
    log "Quarterly Knowledge Base Review - Q${QUARTER} ${YEAR}"
    log "======================================================"

    init_report

    case "${1:-default}" in
        --gaps)
            log "Running gap analysis only..."
            gap_analysis
            ;;
        --quality)
            log "Running quality check only..."
            quality_check
            ;;
        --outdated)
            log "Finding outdated content..."
            check_freshness
            ;;
        *)
            log "Running full quarterly review..."
            check_freshness
            gap_analysis
            quality_check
            coverage_verification
            generate_recommendations
            ;;
    esac

    log_success "======================================================"
    log "Quarterly review complete!"
    log "Report: $REPORT_FILE"
    log "Log: $LOG_FILE"
    log "======================================================"
}

# Run main
main "$@"

exit 0
