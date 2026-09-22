#!/usr/bin/env bash
# SessionStart: puts the open items of the org project board into the session,
# so no work starts without knowing what is tracked. Never blocks a session.
set -uo pipefail

command -v gh >/dev/null 2>&1 || { echo "homelab: gh not found, project board not loaded."; exit 0; }

board="$(gh project item-list 1 --owner 0xc0-homelab --limit 200 --format json --jq '
  [.items[] | select(.status != "Done")]
  | if length == 0 then "No open items."
    else (group_by(.status // "No status")[]
          | "\(.[0].status // "No status"):",
            (.[] | "  - [\(.phase // "no phase")] \(.repository // "draft" | sub("https://github.com/0xc0-homelab/"; ""))#\(.content.number // "-") \(.title)"))
    end' 2>/dev/null)" || { echo "homelab: could not read the project board (gh auth?)."; exit 0; }

cat <<EOF
## 0xc0-homelab project board — open items

No work starts without an issue on this board. Before editing anything, find
the issue for the task or open one, and move it to In Progress. The PR links it
with "Closes #N" or "Refs owner/repo#N"; a PR without one fails the issue check.

$board
EOF
exit 0
