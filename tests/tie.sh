#!/bin/sh
# An even split has no majority to reward and no minority to slash -
# every juror gets their own stake back in full, nothing more, nothing
# less.
set -e
DB="tests/data/tie.json"
rm -f "$DB"
C="$LARZCOURT --board=$DB"

$C fund alice 100
$C fund bob 100
$C create-case "Ambiguous contract dispute" "who's right?" --period=5
id="$($C list | awk 'NR==3{print $2}')"
$C join "$id" alice 15
$C join "$id" bob 15
$C vote "$id" alice plaintiff
$C vote "$id" bob defendant
sleep 6
$C resolve "$id"
$C balance alice
$C balance bob
