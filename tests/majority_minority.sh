#!/bin/sh
# The core mechanic: a juror who votes with the eventual majority gets
# their own stake back PLUS a proportional share of what the minority
# lost; a juror who votes the other way gets nothing back. Two jurors
# vote plaintiff (majority), one votes defendant (minority, slashed).
set -e
DB="tests/data/majority_minority.json"
rm -f "$DB"
C="$LARZCOURT --board=$DB"

$C fund alice 100
$C fund bob 100
$C fund carol 100
$C create-case "Refund dispute" "did the item ship?" --period=5
id="$($C list | awk 'NR==3{print $2}')"
$C join "$id" alice 20
$C join "$id" bob 30
$C join "$id" carol 10
$C vote "$id" alice plaintiff
$C vote "$id" bob plaintiff
$C vote "$id" carol defendant
sleep 6
$C resolve "$id"
$C balance alice
$C balance bob
$C balance carol
