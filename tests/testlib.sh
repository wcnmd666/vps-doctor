#!/usr/bin/env bash

TESTS=0
FAILURES=0

assert_eq() {
  local expected="$1" actual="$2" message="${3:-values should be equal}"
  ((TESTS+=1))
  if [[ "$expected" != "$actual" ]]; then
    printf 'not ok - %s\n  expected: %q\n  actual:   %q\n' "$message" "$expected" "$actual"
    ((FAILURES+=1))
  else
    printf 'ok - %s\n' "$message"
  fi
}

assert_contains() {
  local haystack="$1" needle="$2" message="${3:-text should contain value}"
  ((TESTS+=1))
  if [[ "$haystack" != *"$needle"* ]]; then
    printf 'not ok - %s\n  missing: %q\n' "$message" "$needle"
    ((FAILURES+=1))
  else
    printf 'ok - %s\n' "$message"
  fi
}

assert_not_contains() {
  local haystack="$1" needle="$2" message="${3:-text should not contain value}"
  ((TESTS+=1))
  if [[ "$haystack" == *"$needle"* ]]; then
    printf 'not ok - %s\n  unexpected: %q\n' "$message" "$needle"
    ((FAILURES+=1))
  else
    printf 'ok - %s\n' "$message"
  fi
}

finish_tests() {
  printf '\n%d assertions, %d failures\n' "$TESTS" "$FAILURES"
  ((FAILURES == 0))
}
