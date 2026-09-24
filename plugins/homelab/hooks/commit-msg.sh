#!/usr/bin/env bash
# Enforces Conventional Commits and bans tooling trailers. See CLAUDE.md.
set -uo pipefail

cmd="$(jq -r '.tool_input.command // ""')"
[ -z "$cmd" ] && exit 0

# Only look at git commit invocations.
printf '%s' "$cmd" | grep -Eq '\bgit\b[^|;&]*\bcommit\b' || exit 0

# The message comes from -m, or from stdin through a heredoc (-F - / --file=-).
# A commit reading it from a real file, or an amend with no new message, is
# out of scope: there is nothing in the command to inspect.
if printf '%s' "$cmd" | grep -Eq '[[:space:]](-F|--file)[=[:space:]]+-([[:space:]]|$)'; then
  # The body of the heredoc opened on the git commit line itself, from the line
  # after <<[-]['"]TAG['"] up to the line TAG. Another heredoc earlier in the
  # command (a script editing a file, say) is not the message.
  msg="$(printf '%s' "$cmd" | perl -0777 -ne '
    print $2 if /\bgit\b[^\n;&|]*\bcommit\b[^\n]*?<<-?\s*["\x27]?(\w+)["\x27]?[^\n]*\n(.*?)\n\s*\1\s*(?:\n|$)/s')"
elif printf '%s' "$cmd" | grep -Eq '[[:space:]]-([a-zA-Z]*m|-message)[=[:space:]]'; then
  # Every -m value, whichever quoting was used, grouped short flags included
  # (-qam "subject").
  msg="$(printf '%s' "$cmd" | perl -ne '
    while (/(?:\s-[a-zA-Z]*m|\s--message)[= ]\s*("([^"\\]*(\\.[^"\\]*)*)"|'"'"'([^'"'"']*)'"'"'|(\S+))/g) {
      print defined($2) ? $2 : defined($4) ? $4 : $5; print "\n";
    }')"
else
  exit 0
fi
[ -z "$msg" ] && exit 0

subject="$(printf '%s' "$msg" | head -1)"

if printf '%s' "$msg" | grep -qiE 'co-authored-by:|generated with|🤖'; then
  echo "BLOCKED: no tooling trailers in commit messages. Drop the Co-Authored-By / generated-by line." >&2
  exit 2
fi

if ! printf '%s' "$subject" | grep -qE '^(feat|fix|docs|refactor|chore|ci)(\([a-z0-9._/-]+\))?!?: .+'; then
  echo "BLOCKED: '$subject' is not a Conventional Commit. Expected <type>(<scope>): <subject> with type in feat|fix|docs|refactor|chore|ci." >&2
  exit 2
fi

if [ "${#subject}" -gt 72 ]; then
  echo "BLOCKED: subject is ${#subject} characters, limit is 72. Move the detail to the body." >&2
  exit 2
fi

if printf '%s' "$subject" | grep -qE '\.$'; then
  echo "BLOCKED: subject must not end with a period." >&2
  exit 2
fi

# First word after the colon, lowercase and imperative.
if printf '%s' "$subject" | grep -qE ': [A-Z]'; then
  echo "BLOCKED: subject starts with a capital. Use lowercase imperative: 'add x', not 'Add x'." >&2
  exit 2
fi

exit 0
