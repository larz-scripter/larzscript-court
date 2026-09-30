#!/bin/sh
# A juror who never votes at all is treated exactly like a minority
# voter - same real Kleros-style non-participation penalty - not
# refunded, not exempt, stake redistributed to whoever did vote with
# the eventual majority.
set -e
DB="tests/data/non_voter.json"
rm -f "$DB"
C="$LARZCOURT --board=$DB"

$C fund alice 100
$C fund bob 100
$C create-case "Late delivery dispute" "was it late?" --period=5
id="$($C list | awk 'NR==3{print $2}')"
$C join "$id" alice 10
$C join "$id" bob 10
$C vote "$id" alice plaintiff
echo "--- bob never votes ---"
sleep 6
$C resolve "$id"
$C balance alice
$C balance bob
