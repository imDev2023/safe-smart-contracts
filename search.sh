#!/bin/bash

# Safe Smart Contract Knowledge Base - Search Tool
# Searchable interface for 238+ files across the knowledge base
# Usage: ./search.sh [keyword] [options]

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Get script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
KB_DIR="$SCRIPT_DIR"

# Default values
KEYWORD=""
SECTION=""
TYPE=""
FORMAT=""
COUNT_ONLY=false
SHOW_FILES_ONLY=false
CASE_INSENSITIVE=true

# Help function
show_help() {
    cat << 'EOF'
Safe Smart Contract Knowledge Base - Search Tool

USAGE:
    ./search.sh [KEYWORD] [OPTIONS]

EXAMPLES:
    # Search by keyword
    ./search.sh "reentrancy"
    ./search.sh "ERC20" --case-sensitive

    # Search by section
    ./search.sh "gas" --section quick-ref
    ./search.sh "loop" --section attack-prevention

    # Search by type
    ./search.sh "factory" --type pattern
    ./search.sh "custom" --type error
    ./search.sh --type vulnerability

    # Search in specific format
    ./search.sh "Solidity" --format solidity
    ./search.sh "modifier" --format markdown

    # Get statistics
    ./search.sh --count
    ./search.sh "ERC" --count

    # Show matching files only
    ./search.sh "storage" --files-only

    # List all templates
    ./search.sh --templates

    # List vulnerabilities
    ./search.sh --vulnerabilities

    # List patterns
    ./search.sh --patterns

OPTIONS:
    --section [name]            Search in specific section
                               Options: quick-ref, templates, attack-prevention,
                                       code-snippets, workflows, research, all

    --type [type]              Filter by content type
                              Options: vulnerability, pattern, template, snippet,
                                      error, modifier, event, code

    --format [format]          Search in specific file format
                              Options: markdown, solidity, json, all

    --case-sensitive           Case sensitive search (default: insensitive)
    --count                    Show count of matches only
    --files-only              Show only matching filenames
    --context [N]             Show N lines of context (default: 2)

    --templates               List all contract templates
    --vulnerabilities         List all vulnerabilities
    --patterns                List all design patterns
    --snippets               List all code snippets
    --quick-ref              List all quick references

    --stats                  Show knowledge base statistics
    --help                   Show this help message

EOF
}

# Color function for output
print_match() {
    local file="$1"
    local line_num="$2"
    local line_text="$3"

    # Highlight keyword in the line
    local highlight_line="$line_text"
    if [[ "$CASE_INSENSITIVE" == true ]]; then
        highlight_line=$(echo "$line_text" | sed -E "s/([^[:space:]]*)($KEYWORD)([^[:space:]]*)/\1${GREEN}\2${NC}\3/gi")
    else
        highlight_line=$(echo "$line_text" | sed "s/${KEYWORD}/${GREEN}${KEYWORD}${NC}/g")
    fi

    # Get relative path
    local rel_path="${file#$KB_DIR/}"

    echo -e "${CYAN}${rel_path}${NC}:${YELLOW}${line_num}${NC}: ${highlight_line}"
}

# Search function
search_kb() {
    local keyword="$1"
    local matches=0
    local files_searched=0

    # Build grep options
    local grep_opts="-rn"
    if [[ "$CASE_INSENSITIVE" == true ]]; then
        grep_opts="${grep_opts}i"
    fi

    # Determine file pattern based on format
    local file_pattern=""
    case "$FORMAT" in
        solidity)
            file_pattern="--include=*.sol"
            ;;
        markdown)
            file_pattern="--include=*.md"
            ;;
        json)
            file_pattern="--include=*.json"
            ;;
        *)
            file_pattern=""
            ;;
    esac

    # Determine search path based on section
    local search_path=""
    case "$SECTION" in
        quick-ref)
            search_path="$KB_DIR/knowledge-base-action/01-quick-reference/"
            ;;
        templates)
            search_path="$KB_DIR/knowledge-base-action/02-contract-templates/"
            ;;
        attack-prevention|vulnerabilities)
            search_path="$KB_DIR/knowledge-base-action/03-attack-prevention/"
            ;;
        code-snippets|snippets)
            search_path="$KB_DIR/knowledge-base-action/04-code-snippets/"
            ;;
        workflows)
            search_path="$KB_DIR/knowledge-base-action/05-workflows/"
            ;;
        action)
            search_path="$KB_DIR/knowledge-base-action/"
            ;;
        research)
            search_path="$KB_DIR/knowledge-base-research/"
            ;;
        *)
            search_path="$KB_DIR"
            ;;
    esac

    if [[ ! -d "$search_path" ]]; then
        echo -e "${RED}Error: Invalid section${NC}"
        return 1
    fi

    # Perform search
    local grep_output
    if [[ "$SHOW_FILES_ONLY" == true ]]; then
        grep_output=$(grep $grep_opts $file_pattern -l "$keyword" "$search_path" 2>/dev/null || true)
        echo "$grep_output" | while read -r file; do
            if [[ -n "$file" ]]; then
                echo "${file#$KB_DIR/}"
                ((matches++))
            fi
        done
    elif [[ "$COUNT_ONLY" == true ]]; then
        matches=$(grep $grep_opts $file_pattern "$keyword" "$search_path" 2>/dev/null | wc -l)
        echo -e "${CYAN}Matches found: ${GREEN}${matches}${NC}"
    else
        grep_output=$(grep $grep_opts $file_pattern "$keyword" "$search_path" 2>/dev/null || true)
        if [[ -z "$grep_output" ]]; then
            echo -e "${RED}No matches found for '${YELLOW}${keyword}${RED}'${NC}"
            return 1
        fi
        echo "$grep_output"
        matches=$(echo "$grep_output" | wc -l)
    fi

    return 0
}

# List templates
list_templates() {
    echo -e "${CYAN}=== Contract Templates ===${NC}\n"

    local templates=(
        "secure-erc20.sol:ERC20 token with security features"
        "secure-erc721.sol:NFT collection with enumerable"
        "access-control-template.sol:Role-based access control"
        "upgradeable-template.sol:UUPS upgradeable pattern"
        "staking-template.sol:Token staking with rewards"
        "pausable-template.sol:Emergency stop circuit breaker"
        "multisig-template.sol:Multi-signature wallet"
    )

    for template in "${templates[@]}"; do
        file="${template%:*}"
        desc="${template#*:}"
        if [[ -f "$KB_DIR/knowledge-base-action/02-contract-templates/$file" ]]; then
            echo -e "${GREEN}✓${NC} ${YELLOW}$file${NC}"
            echo -e "  $desc"
            echo ""
        fi
    done
}

# List vulnerabilities
list_vulnerabilities() {
    echo -e "${CYAN}=== Smart Contract Vulnerabilities ===${NC}\n"

    local vulns=(
        "reentrancy.md:Classic and advanced reentrancy attacks"
        "access-control.md:Missing and weak access control"
        "integer-overflow.md:Integer overflow/underflow"
        "frontrunning.md:Mempool manipulation and sandwich attacks"
        "dos-attacks.md:Denial of service attacks"
        "timestamp-dependence.md:Block timestamp and weak randomness"
        "unsafe-delegatecall.md:Unsafe delegatecall and storage collisions"
        "unchecked-returns.md:Unchecked return values"
        "tx-origin.md:tx.origin authentication bypass"
        "flash-loan-attacks.md:Flash loan oracle manipulation"
    )

    for vuln in "${vulns[@]}"; do
        file="${vuln%:*}"
        desc="${vuln#*:}"
        if [[ -f "$KB_DIR/knowledge-base-action/03-attack-prevention/$file" ]]; then
            echo -e "${GREEN}✓${NC} ${YELLOW}$file${NC}"
            echo -e "  $desc"
            echo ""
        fi
    done
}

# List patterns
list_patterns() {
    echo -e "${CYAN}=== Design Patterns ===${NC}\n"
    echo "See: knowledge-base-action/01-quick-reference/pattern-catalog.md"
    echo ""

    local patterns=(
        "Factory:Create multiple contract instances"
        "Proxy:Upgradeable contracts"
        "Vault:Token deposit/withdrawal"
        "Staking:Token locking with rewards"
        "AMM:Automated market maker"
        "Time Lock:Delayed critical operations"
        "Governor:Governance voting"
        "Oracle:External data integration"
        "Flash Loan:Uncollateralized lending"
        "Beacon:Multiple proxies, one implementation"
    )

    for pattern in "${patterns[@]}"; do
        name="${pattern%:*}"
        desc="${pattern#*:}"
        echo -e "${GREEN}✓${NC} ${YELLOW}${name}${NC}"
        echo -e "  ${desc}"
        echo ""
    done
}

# List quick references
list_quick_ref() {
    echo -e "${CYAN}=== Quick References ===${NC}\n"

    local refs=(
        "vulnerability-matrix.md:20 vulnerabilities reference table"
        "pattern-catalog.md:10 essential design patterns"
        "gas-optimization-wins.md:21 gas optimization techniques"
        "oz-quick-ref.md:OpenZeppelin contracts quick reference"
        "security-checklist.md:360+ pre-deployment checks"
    )

    for ref in "${refs[@]}"; do
        file="${ref%:*}"
        desc="${ref#*:}"
        if [[ -f "$KB_DIR/knowledge-base-action/01-quick-reference/$file" ]]; then
            echo -e "${GREEN}✓${NC} ${YELLOW}$file${NC}"
            echo -e "  $desc"
            echo ""
        fi
    done
}

# Show statistics
show_stats() {
    echo -e "${CYAN}=== Knowledge Base Statistics ===${NC}\n"

    local total_files=$(find "$KB_DIR" -type f \( -name "*.md" -o -name "*.sol" -o -name "*.json" -o -name "*.sh" \) ! -path "*/.git/*" ! -path "*/.claude/*" | wc -l)
    local markdown_files=$(find "$KB_DIR" -type f -name "*.md" ! -path "*/.git/*" ! -path "*/.claude/*" | wc -l)
    local solidity_files=$(find "$KB_DIR" -type f -name "*.sol" ! -path "*/.git/*" ! -path "*/.claude/*" | wc -l)

    local action_files=$(find "$KB_DIR/knowledge-base-action" -type f -name "*.md" -o -name "*.sol" 2>/dev/null | wc -l)
    local research_files=$(find "$KB_DIR/knowledge-base-research" -type f -name "*.md" 2>/dev/null | wc -l)

    local total_lines=$(find "$KB_DIR" -type f \( -name "*.md" -o -name "*.sol" \) ! -path "*/.git/*" ! -path "*/.claude/*" -exec wc -l {} + 2>/dev/null | tail -1 | awk '{print $1}')

    echo -e "${GREEN}Total Files:${NC} $total_files"
    echo -e "${GREEN}Markdown Files:${NC} $markdown_files"
    echo -e "${GREEN}Solidity Files:${NC} $solidity_files"
    echo -e "${GREEN}Total Lines:${NC} $total_lines"
    echo ""
    echo -e "${GREEN}Action KB Files:${NC} $action_files (production-ready)"
    echo -e "${GREEN}Research KB Files:${NC} $research_files (deep research)"
    echo ""

    echo -e "${CYAN}=== Component Breakdown ===${NC}\n"

    local qr_files=$(find "$KB_DIR/knowledge-base-action/01-quick-reference" -type f 2>/dev/null | wc -l)
    local tpl_files=$(find "$KB_DIR/knowledge-base-action/02-contract-templates" -type f 2>/dev/null | wc -l)
    local atk_files=$(find "$KB_DIR/knowledge-base-action/03-attack-prevention" -type f 2>/dev/null | wc -l)
    local snip_files=$(find "$KB_DIR/knowledge-base-action/04-code-snippets" -type f 2>/dev/null | wc -l)
    local flow_files=$(find "$KB_DIR/knowledge-base-action/05-workflows" -type f 2>/dev/null | wc -l)

    echo -e "Quick References: ${GREEN}${qr_files}${NC} files"
    echo -e "Templates: ${GREEN}${tpl_files}${NC} files"
    echo -e "Attack Prevention: ${GREEN}${atk_files}${NC} files"
    echo -e "Code Snippets: ${GREEN}${snip_files}${NC} files"
    echo -e "Workflows: ${GREEN}${flow_files}${NC} files"
}

# Main program
main() {
    if [[ $# -eq 0 ]]; then
        show_help
        exit 0
    fi

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -h|--help)
                show_help
                exit 0
                ;;
            --section)
                SECTION="$2"
                shift 2
                ;;
            --type)
                TYPE="$2"
                shift 2
                ;;
            --format)
                FORMAT="$2"
                shift 2
                ;;
            --case-sensitive)
                CASE_INSENSITIVE=false
                shift
                ;;
            --count)
                COUNT_ONLY=true
                shift
                ;;
            --files-only)
                SHOW_FILES_ONLY=true
                shift
                ;;
            --context)
                CONTEXT="$2"
                shift 2
                ;;
            --templates)
                list_templates
                exit 0
                ;;
            --vulnerabilities)
                list_vulnerabilities
                exit 0
                ;;
            --patterns)
                list_patterns
                exit 0
                ;;
            --quick-ref)
                list_quick_ref
                exit 0
                ;;
            --snippets)
                SECTION="code-snippets"
                KEYWORD="."
                shift
                ;;
            --stats)
                show_stats
                exit 0
                ;;
            -*)
                echo -e "${RED}Unknown option: $1${NC}"
                show_help
                exit 1
                ;;
            *)
                KEYWORD="$1"
                shift
                ;;
        esac
    done

    if [[ -z "$KEYWORD" ]]; then
        show_help
        exit 0
    fi

    # Perform search
    search_kb "$KEYWORD"
}

# Run main function
main "$@"
