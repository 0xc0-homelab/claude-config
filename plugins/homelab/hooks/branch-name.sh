#!/usr/bin/env bash
# Enforces branch names <type>/<slug>, with the commit types. See CLAUDE.md.
set -uo pipefail

cmd="$(jq -r '.tool_input.command // ""')"
[ -z "$cmd" ] && exit 0

# Every branch the command creates: git checkout -b|-B, git switch -c|-C|--create,
# with or without -C <dir> before the subcommand.
names="$(printf '%s' "$cmd" | perl -ne '
  while (/\bgit\b(?:\s+-C\s+\S+)?\s+(?:checkout\s+(?:\S+\s+)*?-[bB]|switch\s+(?:\S+\s+)*?(?:-[cC]|--create|--force-create))\s+([^\s;&|]+)/g) {
    print "$1\n";
  }')"
[ -z "$names" ] && exit 0

while IFS= read -r name; do
  [ -z "$name" ] && continue
  if ! printf '%s' "$name" | grep -qE '^(feat|fix|docs|refactor|chore|ci)/[a-z0-9][a-z0-9.-]*$'; then
    echo "BLOCKED: branch '$name' does not follow <type>/<slug>: type in feat|fix|docs|refactor|chore|ci, slug in lowercase letters, digits, '.' and '-'." >&2
    exit 2
  fi
done <<<"$names"

exit 0
