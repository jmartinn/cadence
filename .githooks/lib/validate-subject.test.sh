#!/bin/sh
# Self-test for validate-subject.sh. Exit 0 = every case behaved as expected.
here=$(dirname "$0")
v="$here/validate-subject.sh"
fail=0

expect_pass() {
  if sh "$v" "$1" >/dev/null 2>&1; then :; else
    echo "FAIL (expected pass): $1"; fail=1
  fi
}
expect_block() {
  if sh "$v" "$1" >/dev/null 2>&1; then
    echo "FAIL (expected block): $1"; fail=1
  fi
}
expect_warn() {
  out=$(sh "$v" "$1" 2>&1); rc=$?
  if [ "$rc" -ne 0 ]; then echo "FAIL (expected pass-with-warn): $1"; fail=1; fi
  case "$out" in
    *⚠*) : ;;
    *) echo "FAIL (expected a warning): $1"; fail=1 ;;
  esac
}
expect_no_warn() {
  out=$(sh "$v" "$1" 2>&1); rc=$?
  if [ "$rc" -ne 0 ]; then echo "FAIL (expected pass): $1"; fail=1; fi
  case "$out" in
    *⚠*) echo "FAIL (expected NO warning): $1"; fail=1 ;;
  esac
}

expect_pass  "feat: add forecaster"
expect_pass  "fix(home): clamp badge offset"
expect_pass  "refactor(domain)!: rename plan type"
expect_block "Feature: capitalized type"
expect_block "feat add forecaster"
expect_block "feat: "
expect_block "$(printf 'feat: %073d' 0)"
expect_warn    "feat: GitHub sign-in"
expect_no_warn "fix: lowercase description stays quiet"

if [ "$fail" -eq 0 ]; then echo "all validate-subject cases passed"; fi
exit "$fail"
