#!/bin/bash
# Build the installable Koha plugin archive (.kpz) for ISBD4MARCPunctuation.
#
# Usage: ./scripts/build_kpz.sh            -> ../isbd4marcpunctuation.kpz
#        ./scripts/build_kpz.sh /tmp/out   -> /tmp/out/isbd4marcpunctuation.kpz
#
# A .kpz is a plain zip of the Koha/ tree. Koha unpacks it into the plugins
# directory, so every path inside the zip must start with Koha/. The archive is
# verified afterwards: a missing configure.tt would only show up as a broken
# Configure screen on the test server, which is exactly what this script exists
# to prevent.

set -eu

cd "$(dirname "$0")/.." || exit 1

OUTDIR="${1:-..}"
NAME='isbd4marcpunctuation'
ARCHIVE="$OUTDIR/$NAME.kpz"

PLUGIN_PM='Koha/Plugin/HKS3/ISBD4MARCPunctuation.pm'
TEMPLATE='Koha/Plugin/HKS3/ISBD4MARCPunctuation/configure.tt'

# Files that must end up in the archive, whether or not Koha needs them to run.
REQUIRED=(
    "$PLUGIN_PM"
    "$TEMPLATE"
)

for f in "${REQUIRED[@]}"; do
    if [ ! -s "$f" ]; then
        echo "ERROR: missing or empty: $f" >&2
        rm -f "$ARCHIVE"   # never leave a previous build looking current
        exit 1
    fi
done

# The filter itself is loaded from the plugins directory too, so it must be in
# the archive - Koha has no way to resolve it otherwise.
FILTER_PM='Koha/Filter/MARC/ISBD4MARCPunctuation.pm'
RULESETS=(Koha/Filter/MARC/ISBD4MARCPunctuation/RuleSet/*.pm)
for f in "$FILTER_PM" "${RULESETS[@]}"; do
    if [ ! -s "$f" ]; then
        echo "ERROR: missing or empty: $f" >&2
        rm -f "$ARCHIVE"
        exit 1
    fi
done

mkdir -p "$OUTDIR"
rm -f "$ARCHIVE"

# Pack only the code: no editor backups, no .git, no test files. The .sh files
# under Koha/ are a stray developer copy of run_tests.sh - they are not part of
# the plugin and must not land in Koha's plugins directory.
zip -q -r "$ARCHIVE" Koha/ \
    -x '*/.*' '*.bak' '*.orig' '*~' '*.swp' '*.sh'

if [ ! -s "$ARCHIVE" ]; then
    echo "ERROR: zip produced no archive" >&2
    exit 1
fi

# Verify the archive CONTENTS, not just that the file exists.
listed=$(unzip -Z1 "$ARCHIVE")

status=0
for f in "${REQUIRED[@]}" "$FILTER_PM" "${RULESETS[@]}"; do
    if ! printf '%s\n' "$listed" | grep -Fxq "$f"; then
        echo "ERROR: $f is NOT in $ARCHIVE" >&2
        status=1
    fi
done

# Koha expects top-level Koha/ entries; a nested prefix means it will not load.
if printf '%s\n' "$listed" | grep -vq '^Koha/'; then
    echo "ERROR: archive contains paths outside Koha/:" >&2
    printf '%s\n' "$listed" | grep -v '^Koha/' | head -5 >&2
    status=1
fi

if [ "$status" -ne 0 ]; then
    rm -f "$ARCHIVE"
    exit 1
fi

echo "Built $ARCHIVE"
echo "Contents:"
printf '%s\n' "$listed" | sed 's/^/    /'
