#!/bin/sh
# Validate a commit subject against Cadence conventions.
# Usage: validate-subject.sh "<subject>"
# Exit 0 = valid (a case warning still exits 0); 1 = invalid.
export LC_ALL=C
subject="$1"
status=0
types='feat|fix|docs|style|refactor|perf|test|build|ci|chore|revert'

if printf '%s' "$subject" | grep -Eq "^(${types})(\([a-z0-9-]+\))?!?: .+"; then
  desc=$(printf '%s' "$subject" | sed -E "s/^(${types})(\([a-z0-9-]+\))?!?: //")
  case "$desc" in
    [A-Z]*) echo "⚠ description starts uppercase — fine for a proper noun (GitHub, SwiftData, App Store…), otherwise lowercase it" ;;
  esac
else
  echo "✗ subject must be: <type>(<scope>)?!?: <description>"
  echo "  allowed types: ${types}"
  echo "  got: '${subject}'"
  status=1
fi

if [ "${#subject}" -gt 72 ]; then
  echo "✗ subject is ${#subject} chars (max 72): '${subject}'"
  status=1
fi

exit "$status"
