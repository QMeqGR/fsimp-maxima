#!/bin/sh
# Run the fsimp rtest files, each in a fresh Maxima process, and report
# pass counts and timings. The rtest files start with kill(all), so they
# cannot share a session with a driver script.
#
# Usage: tests/run_rtests.sh [rtest_file ...]
# With no arguments, runs every rtest_fsimp*.mac in the repository root.
# Extra Maxima statements can be passed in FS_RTEST_SETUP, for example
#   FS_RTEST_SETUP='fs_check:false$' tests/run_rtests.sh
# The setup runs before the rtest file, so it must survive kill(all):
# option variables do, user variables do not.

repo=$(cd "$(dirname "$0")/.." && pwd)
cd "$repo" || exit 1
[ $# -eq 0 ] && set -- rtest_fsimp*.mac

status=0
for f in "$@"; do
  start=$(date +%s)
  out=$(maxima --very-quiet -r "
file_search_maxima : append([\"$repo/###.mac\", \"$repo/docs/###.mac\"], file_search_maxima)\$
file_search_lisp : append([\"$repo/###.lisp\", \"$repo/docs/###.lisp\"], file_search_lisp)\$
${FS_RTEST_SETUP}
batch(\"$repo/$f\", 'test)\$
quit()\$" 2>&1)
  end=$(date +%s)
  summary=$(printf '%s\n' "$out" | grep -E 'tests passed|problems? failed|No unexpected errors' | tr '\n' ' ')
  printf '%s: %s(%ss)\n' "$f" "$summary" "$((end - start))"
  printf '%s\n' "$out" | grep -q 'failed' && status=1
done
rm -f "$repo"/rtest_fsimp*.ERR
exit $status
