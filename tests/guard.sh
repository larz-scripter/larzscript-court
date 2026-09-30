#!/bin/sh
# Same class of bug found and fixed in every sibling project: a too-
# short/empty id prefix must never silently match the first case
# iterated over. Also covers a couple of other real error paths - an
# unknown juror voting, and resolving before the deadline.
set -e
DB="tests/data/guard.json"
rm -f "$DB"
C="$LARZCOURT --board=$DB"

$C fund alice 100
$C create-case "Case one" "first" --period=5
$C create-case "Case two" "second" --period=5
id="$($C list | awk 'NR==3{print $2}')"
echo "--- a 3-char prefix is rejected outright, even if it happens to match ---"
$C show "${id}" > /dev/null
$C show "abc" || true
echo "--- an unjoined juror can't vote ---"
$C vote "$id" mallory plaintiff || true
echo "--- resolving before the deadline is refused ---"
$C join "$id" alice 10
$C vote "$id" alice plaintiff
$C resolve "$id" || true
