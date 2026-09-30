#!/bin/sh
# A narrated walkthrough of all three ways a case can resolve: a clean
# majority (two jurors vote together, slash the one who didn't), a
# non-voter treated exactly like a wrong vote (no special exemption for
# just staying silent), and a tie (no majority to reward, no minority
# to slash, so everyone just gets their own stake back). Every case
# uses a short --period so the demo finishes in seconds, followed by a
# real sleep past the deadline before resolving. Run from the repo
# root: sh examples/demo.sh
set -e
DB="/tmp/larzcourt-demo-$$.json"
rm -f "$DB"
LARZCOURT="larzscript bin/larzcourt.lz --board=$DB"

echo "--- fund three jurors (demo-only faucet) ---"
$LARZCOURT fund alice 100
$LARZCOURT fund bob 100
$LARZCOURT fund carol 100

echo
echo "--- case 1: alice and bob vote plaintiff, carol votes defendant alone ---"
$LARZCOURT create-case "Refund dispute" "did the item ship?" --period=5
id1="$($LARZCOURT list | grep 'Refund dispute' | awk '{print $2}')"
$LARZCOURT join "$id1" alice 20
$LARZCOURT join "$id1" bob 30
$LARZCOURT join "$id1" carol 10
$LARZCOURT vote "$id1" alice plaintiff
$LARZCOURT vote "$id1" bob plaintiff
$LARZCOURT vote "$id1" carol defendant
sleep 6
echo "--- carol's whole \$10 stake is redistributed to alice and bob, proportional to their own stakes ---"
$LARZCOURT resolve "$id1"
$LARZCOURT balance alice
$LARZCOURT balance bob
$LARZCOURT balance carol

echo
echo "--- case 2: alice votes, bob never shows up to vote at all ---"
$LARZCOURT create-case "Late delivery dispute" "was it late?" --period=5
id2="$($LARZCOURT list | grep 'Late delivery' | awk '{print $2}')"
$LARZCOURT join "$id2" alice 10
$LARZCOURT join "$id2" bob 10
$LARZCOURT vote "$id2" alice plaintiff
echo "--- bob never votes - treated exactly like voting the losing side, not exempt for staying silent ---"
sleep 6
$LARZCOURT resolve "$id2"
$LARZCOURT balance alice
$LARZCOURT balance bob

echo
echo "--- case 3: alice and carol split evenly - no majority, no slashing ---"
$LARZCOURT create-case "Ambiguous contract dispute" "who's right?" --period=5
id3="$($LARZCOURT list | grep 'Ambiguous contract' | awk '{print $2}')"
$LARZCOURT join "$id3" alice 15
$LARZCOURT join "$id3" carol 15
$LARZCOURT vote "$id3" alice plaintiff
$LARZCOURT vote "$id3" carol defendant
sleep 6
echo "--- a tie just refunds everyone their own stake, dollar for dollar ---"
$LARZCOURT resolve "$id3"
$LARZCOURT balance alice
$LARZCOURT balance carol

rm -f "$DB"
