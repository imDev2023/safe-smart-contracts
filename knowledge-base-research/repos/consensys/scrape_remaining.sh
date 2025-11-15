#!/bin/bash

BASE_DIR="/Volumes/Farhan/Work Folder/Dev/Safe-Smart-Contracts/knowledge-base-research/repos/consensys"

# Documentation files - save simple content
cat > "$BASE_DIR/02-development-recommendations/05-documentation/general.md" << 'EOF'
# General

> **Tip**: For comprehensive insights into secure development practices, consider visiting the [Development Recommendations](https://scsfg.io/developers/) section of the Smart Contract Security Field Guide. This resource provides in-depth articles to guide you in developing robust and secure smart contracts.

When launching a contract that will have substantial funds or is required to be mission critical, it is important to include proper documentation.
EOF

cat > "$BASE_DIR/02-development-recommendations/05-documentation/specification.md" << 'EOF'
# Specification

> **Tip**: For comprehensive insights into secure development practices, consider visiting the [Development Recommendations](https://scsfg.io/developers/) section of the Smart Contract Security Field Guide. This resource provides in-depth articles to guide you in developing robust and secure smart contracts.

- Specs, diagrams, state machines, models, and other documentation that helps auditors, reviewers, and the community understand what the system is intended to do.
- Many bugs can be found just from the specifications, and they are the least costly to fix.
- Rollout plans that include details listed [here](https://consensysdiligence.github.io/smart-contract-best-practices/development-recommendations/precautions/deployment/), and target dates.
EOF

cat > "$BASE_DIR/02-development-recommendations/05-documentation/status.md" << 'EOF'
# Status

> **Tip**: For comprehensive insights into secure development practices, consider visiting the [Development Recommendations](https://scsfg.io/developers/) section of the Smart Contract Security Field Guide. This resource provides in-depth articles to guide you in developing robust and secure smart contracts.

- Where current code is deployed
- Compiler version, flags used, and steps for verifying the deployed bytecode matches the source code
- Compiler versions and flags that will be used for the different phases of rollout.
- Current status of deployed code (including outstanding issues, performance stats, etc.)
EOF

cat > "$BASE_DIR/02-development-recommendations/05-documentation/procedures.md" << 'EOF'
# Procedures

> **Tip**: For comprehensive insights into secure development practices, consider visiting the [Development Recommendations](https://scsfg.io/developers/) section of the Smart Contract Security Field Guide. This resource provides in-depth articles to guide you in developing robust and secure smart contracts.

- Action plan in case a bug is discovered (e.g., emergency options, public notification process, etc.)
- Wind down process if something goes wrong (e.g., funders will get percentage of your balance before attack, from remaining funds)
- Responsible disclosure policy (e.g., where to report bugs found, the rules of any bug bounty program)
- Recourse in case of failure (e.g., insurance, penalty fund, no recourse)
EOF

cat > "$BASE_DIR/02-development-recommendations/05-documentation/known-issues.md" << 'EOF'
# Known Issues

> **Tip**: For comprehensive insights into secure development practices, consider visiting the [Development Recommendations](https://scsfg.io/developers/) section of the Smart Contract Security Field Guide. This resource provides in-depth articles to guide you in developing robust and secure smart contracts.

- Key risks with contract
- e.g., You can lose all your money, hacker can vote for certain outcomes
- All known bugs/limitations
- Potential attacks and mitigants
- Potential conflicts of interest (e.g., will be using yourself, like Slock.it did with the DAO)
EOF

cat > "$BASE_DIR/02-development-recommendations/05-documentation/history.md" << 'EOF'
# History

> **Tip**: For comprehensive insights into secure development practices, consider visiting the [Development Recommendations](https://scsfg.io/developers/) section of the Smart Contract Security Field Guide. This resource provides in-depth articles to guide you in developing robust and secure smart contracts.

- Testing (including usage stats, discovered bugs, length of testing)
- People who have reviewed code (and their key feedback)
EOF

cat > "$BASE_DIR/02-development-recommendations/05-documentation/contact.md" << 'EOF'
# Contact

> **Tip**: For comprehensive insights into secure development practices, consider visiting the [Development Recommendations](https://scsfg.io/developers/) section of the Smart Contract Security Field Guide. This resource provides in-depth articles to guide you in developing robust and secure smart contracts.

- Who to contact with issues
- Names of programmers and/or other important parties
- Chat room where questions can be asked
EOF

echo "Documentation files created successfully"
