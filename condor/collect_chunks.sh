#!/bin/bash
# Move finished chunk files from condor_out/ into the layout the merge,
# combine and plot steps expect -- the same layout the REANA run produced, so
# the two can be compared file by file.
#
# Safe to run repeatedly while jobs are still finishing: it only moves what is
# there, and reports what is still missing.

set -euo pipefail

cd "$(dirname "$0")/.."

moved=0
for src in condor_out/chunk__*.root; do
    [ -e "$src" ] || continue
    base=$(basename "$src" .root)
    rest=${base#chunk__}
    dataset=${rest%__*}
    chunk_id=${rest##*__}

    if [ ! -s "$src" ]; then
        echo "SKIP  empty: $src" >&2
        continue
    fi

    mkdir -p "results/chunks/$dataset"
    mv "$src" "results/chunks/$dataset/$chunk_id.root"
    moved=$((moved + 1))
done

echo "moved $moved file(s)"

total=0
missing=0
: > condor/retry.txt
while IFS=, read -r dataset chunk_id; do
    dataset=$(echo "$dataset" | tr -d ' ')
    chunk_id=$(echo "$chunk_id" | tr -d ' ')
    [ -n "$dataset" ] || continue
    total=$((total + 1))
    if [ ! -s "results/chunks/$dataset/$chunk_id.root" ]; then
        echo "MISSING results/chunks/$dataset/$chunk_id.root"
        echo "$dataset, $chunk_id" >> condor/retry.txt
        missing=$((missing + 1))
    fi
done < condor/chunks.txt

echo "$((total - missing))/$total chunks present"

# Written every time, so it is always current: resubmit exactly what is left
# with condor_submit condor/analyze_chunks.sub -append 'chunklist = condor/retry.txt'
if [ "$missing" -gt 0 ]; then
    echo "wrote condor/retry.txt with $missing chunk(s) to resubmit"
else
    rm -f condor/retry.txt
fi
