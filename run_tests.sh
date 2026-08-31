#!/bin/bash
# Run all tests for the ISBD4MARCPunctuation filter.
# Usage: ./run_tests.sh [test_file.t ...]
# If no arguments given, runs all t/*.t files.

cd "$(dirname "$0")" || exit 1

if [ $# -eq 0 ]; then
    TESTS=( t/*.t )
else
    TESTS=( "$@" )
fi

for t in "${TESTS[@]}"; do
    echo "=== $t ==="
    PERL5LIB=t/lib:. perl "$t"
    echo
done

echo "---"
echo "All ${#TESTS[@]} test(s) completed."
