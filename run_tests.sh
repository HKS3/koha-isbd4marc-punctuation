#!/bin/bash
# Run all tests for the ISBD4MARCPunctuation filter.
# Usage: ./run_tests.sh [test_file.t ...]
# If no arguments given, runs all t/*.t files.

cd "$(dirname "$0")" || exit 1

# The doc-coverage gate (t/99) needs the reference-doc text, which is NOT
# committed (copyright). If it is missing, fetch+preprocess it once. The path
# respects ISBD_REF_DOC (same default as the gate: ../isbdmarc2016.txt).
if [ ! -s "${ISBD_REF_DOC:-../isbdmarc2016.txt}" ]; then
    echo "Reference doc missing - fetching + preprocessing..."
    perl scripts/fetch_reference_doc.pl \
        || { echo "Could not obtain reference doc; run scripts/fetch_reference_doc.pl manually." >&2; exit 1; }
fi

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
