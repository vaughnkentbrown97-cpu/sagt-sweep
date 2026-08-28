#!/bin/sh
# Wakes the sweeper, without waiting for GitHub to feel like it.
#
# The same job the Actions workflow in this repo does, and it exists because
# that workflow cannot be relied on to run. Measured over 26 hours on
# 2026-08-27/28: three scheduled runs against a */15 schedule, gaps of 2.2, 4.6
# and 2 hours between them, 34% of the window with nothing sweeping at all. The
# sweeper's session expires after an hour and is renewed inside a tick, so a
# long enough gap does not merely pause the sweep - it lets the credential die
# and stays dead until something calls again.
#
# A machine that is simply always on has no schedule to be throttled.

: "${TICK_URL:?TICK_URL is required}"
: "${CRON_KEY:?CRON_KEY is required}"
GAP="${GAP_SECONDS:-25}"

fails=0

while :; do
  code=$(curl -s -o /tmp/tick.json -w '%{http_code}' \
    --max-time 70 \
    -H "x-cron-key: $CRON_KEY" \
    "$TICK_URL" || echo 000)

  if [ "$code" = "200" ]; then
    fails=0
    # The tick's own account of what it did, so `fly logs` answers "is it
    # sweeping" without anyone having to query the database.
    sed -n 's/.*"did":"\([^"]*\)".*"pages":\([0-9]*\).*/\1 pages=\2/p' /tmp/tick.json 2>/dev/null \
      | head -1 | while read -r line; do echo "$(date -u +%H:%M:%S) $line"; done
  else
    fails=$((fails + 1))
    echo "$(date -u +%H:%M:%S) tick -> HTTP $code (${fails} consecutive)"
    # A single blip is the network, not an outage - the Actions version
    # measured one transport failure in fifteen runs. Sustained failure is
    # worth dying for, because Fly restarts the machine and a restart is a
    # clean process with a fresh DNS view.
    if [ "$fails" -ge 20 ]; then
      echo "$(date -u +%H:%M:%S) twenty consecutive failures - exiting so the machine restarts"
      exit 1
    fi
  fi

  sleep "$GAP"
done
