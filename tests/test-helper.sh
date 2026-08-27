#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

project_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
test_bin="$project_dir/tests/bin"
test_tmp=$(mktemp -d)
trap 'rm -rf "$test_tmp"' EXIT

export PATH="$test_bin:$PATH"
export TEST_ACTION_LOG="$test_tmp/actions"
touch "$TEST_ACTION_LOG"

fail() {
  printf 'FAIL: %s\n' "$1" >&2
  exit 1
}

assert_contains() {
  local value=$1
  local expected=$2
  [[ $value == *"$expected"* ]] || fail "expected '$value' to contain '$expected'"
}

status=$($project_dir/monitor-handoff status DP-2)
assert_contains "$status" '"class":"active"'

missing=$($project_dir/monitor-handoff status HDMI-A-9)
assert_contains "$missing" '"class":"urgent"'

export TEST_SCENARIO=two-active
>"$TEST_ACTION_LOG"
$project_dir/monitor-handoff toggle DP-2 >/dev/null
expected='eval:hl.monitor({ output = "DP-2", disabled = true })'
actual=$(<"$TEST_ACTION_LOG")
[[ $actual == "$expected" ]] || fail "unexpected disable action: $actual"

export TEST_SCENARIO=target-inactive
>"$TEST_ACTION_LOG"
$project_dir/monitor-handoff toggle DP-2 >/dev/null
actual=$(<"$TEST_ACTION_LOG")
[[ $actual == reload ]] || fail "unexpected reconnect action: $actual"

export TEST_SCENARIO=one-active
>"$TEST_ACTION_LOG"
set +o errexit
$project_dir/monitor-handoff toggle DP-2 >/dev/null 2>&1
exit_code=$?
set -o errexit
[[ $exit_code -eq 4 ]] || fail "expected last-monitor exit 4, got $exit_code"
[[ ! -s $TEST_ACTION_LOG ]] || fail "last active monitor was modified"

printf 'All helper tests passed.\n'
