#!/bin/sh
# Runs each tests/*.sh scenario and diffs its real output against
# tests/<name>.expected. Same discipline as sibling flagship projects -
# real captured output, no fabrication.
#
# Normalizes uuid.v4() case ids (full + 8-char short form) before
# comparing, same as every sibling project.
#
# Env override: LARZCOURT="larzscript /path/to/bin/larzcourt.lz" to test
# another copy (used by CI).
set -e
cd "$(dirname "$0")/.."
LARZCOURT="${LARZCOURT:-larzscript bin/larzcourt.lz}"
export LARZCOURT
mkdir -p tests/data

normalize() {
  sed -E 's/[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}/UUID/g; s/\b[0-9a-f]{8}\b/xxxxxxxx/g'
}

pass=0; fail=0
for t in tests/*.sh; do
  case "$t" in *run_tests.sh) continue ;; esac
  exp="${t%.sh}.expected"
  got="$(sh "$t" 2>&1 | normalize || true)"
  if [ "$got" = "$(cat "$exp")" ]; then
    pass=$((pass+1))
  else
    fail=$((fail+1))
    echo "FAIL: $t"
    echo "$got" > /tmp/larzcourt_test_got.$$
    diff /tmp/larzcourt_test_got.$$ "$exp" || true
    rm -f /tmp/larzcourt_test_got.$$
  fi
done

echo "passed=$pass failed=$fail"
[ "$fail" -eq 0 ]
