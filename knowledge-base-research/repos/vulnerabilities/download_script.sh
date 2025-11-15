#!/bin/bash

# Base URL for raw files
BASE_URL="https://raw.githubusercontent.com/kadenzipfel/smart-contract-vulnerabilities/master/vulnerabilities"

# Array of all vulnerability files
FILES=(
    "arbitrary-storage-location.md"
    "assert-violation.md"
    "asserting-contract-from-code-size.md"
    "authorization-txorigin.md"
    "default-visibility.md"
    "delegatecall-untrusted-callee.md"
    "dos-gas-limit.md"
    "dos-revert.md"
    "floating-pragma.md"
    "hash-collision.md"
    "inadherence-to-standards.md"
    "incorrect-constructor.md"
    "incorrect-inheritance-order.md"
    "insufficient-access-control.md"
    "insufficient-gas-griefing.md"
    "lack-of-precision.md"
    "missing-protection-signature-replay.md"
    "msgvalue-loop.md"
    "off-by-one.md"
    "outdated-compiler-version.md"
    "overflow-underflow.md"
    "reentrancy.md"
    "requirement-violation.md"
    "shadowing-state-variables.md"
    "signature-malleability.md"
    "timestamp-dependence.md"
    "transaction-ordering-dependence.md"
    "unbounded-return-data.md"
    "unchecked-return-values.md"
    "unencrypted-private-data-on-chain.md"
    "unexpected-ecrecover-null-address.md"
    "uninitialized-storage-pointer.md"
    "unsafe-low-level-call.md"
    "unsecure-signatures.md"
    "unsupported-opcodes.md"
    "unused-variables.md"
    "use-of-deprecated-functions.md"
    "weak-sources-randomness.md"
)

# Counter for successful downloads
SUCCESS_COUNT=0
FAIL_COUNT=0

echo "Starting download of ${#FILES[@]} vulnerability files..."
echo "=========================================="

# Download each file
for file in "${FILES[@]}"; do
    echo "Downloading: $file"
    if curl -s -f -o "$file" "$BASE_URL/$file"; then
        SUCCESS_COUNT=$((SUCCESS_COUNT + 1))
        echo "✓ Success: $file"
    else
        FAIL_COUNT=$((FAIL_COUNT + 1))
        echo "✗ Failed: $file"
    fi
done

echo "=========================================="
echo "Download Summary:"
echo "Total files: ${#FILES[@]}"
echo "Successfully downloaded: $SUCCESS_COUNT"
echo "Failed: $FAIL_COUNT"
echo "=========================================="
