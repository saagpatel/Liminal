#!/bin/sh
set -eu

repo_root=$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)
readme="$repo_root/docs/playtest/README.md"
decision="$repo_root/docs/playtest/decision.md"
sessions="$repo_root/docs/playtest/session-observations.csv"

checkpoint=$(sed -n 's/^- Source checkpoint: `\([0-9a-f]\{40\}\)`.*/\1/p' "$readme")
executable_sha=$(sed -n 's/^- Unsigned device Release executable SHA-256: `\([0-9a-f]\{64\}\)`.*/\1/p' "$readme")

test -n "$checkpoint"
test -n "$executable_sha"
grep -q -- "- Build commit: \`$checkpoint\`" "$decision"
grep -q -- "- Release executable SHA-256: \`$executable_sha\`" "$decision"

awk -F, -v checkpoint="$checkpoint" -v executable_sha="$executable_sha" '
  NR == 1 { next }
  $2 != checkpoint { print "stale build checkpoint on row " NR > "/dev/stderr"; failed = 1 }
  $3 != executable_sha { print "stale executable hash on row " NR > "/dev/stderr"; failed = 1 }
  END {
    if (NR != 9) {
      print "expected header plus 8 cohort rows" > "/dev/stderr"
      failed = 1
    }
    exit failed
  }
' "$sessions"

printf '%s\n' "PASS: Playtest packet pins one executable candidate across README, decision, and 8 cohort rows"
