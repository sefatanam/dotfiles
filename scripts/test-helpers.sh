#!/usr/bin/env bash
# Minimal assertion helpers for dotfiles tests. Intentionally dependency-free:
# this repo has no test framework and adding one would be a new prerequisite on
# every machine the dotfiles bootstrap.

TESTS_RUN=0
TESTS_FAILED=0

assert_eq() {
    local expected="$1" actual="$2" msg="$3"
    TESTS_RUN=$((TESTS_RUN + 1))
    if [[ "$expected" == "$actual" ]]; then
        printf '  ok   %s\n' "$msg"
    else
        TESTS_FAILED=$((TESTS_FAILED + 1))
        printf '  FAIL %s\n         expected: %s\n         actual:   %s\n' \
            "$msg" "$expected" "$actual"
    fi
}

# assert_exit <expected-code> <message> <command...>
assert_exit() {
    local expected="$1" msg="$2"
    shift 2
    TESTS_RUN=$((TESTS_RUN + 1))
    local actual=0
    "$@" >/dev/null 2>&1 || actual=$?
    if [[ "$expected" == "$actual" ]]; then
        printf '  ok   %s\n' "$msg"
    else
        TESTS_FAILED=$((TESTS_FAILED + 1))
        printf '  FAIL %s (expected exit %s, got %s)\n' "$msg" "$expected" "$actual"
    fi
}

finish() {
    printf '\n%d assertions, %d failed\n' "$TESTS_RUN" "$TESTS_FAILED"
    [[ $TESTS_FAILED -eq 0 ]]
}
