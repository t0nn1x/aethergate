#!/bin/bash
# Run this once to authenticate LiteLLM with your GitHub Copilot account.

TOKEN_DIR="$HOME/.config/litellm/github_copilot"
TOKEN_FILE="$TOKEN_DIR/access-token"
CLIENT_ID="Iv1.b507a08c87ecfe98"

mkdir -p "$TOKEN_DIR"

echo "==> Requesting device code from GitHub..."
RESPONSE=$(curl -s --max-time 15 -X POST https://github.com/login/device/code \
  -H "Accept: application/json" \
  -d "client_id=$CLIENT_ID&scope=read:user")

if [ -z "$RESPONSE" ]; then
  echo "ERROR: Could not reach github.com. Check your internet connection."
  exit 1
fi

echo "Raw response: $RESPONSE"

DEVICE_CODE=$(echo "$RESPONSE" | python3.13 -c "import sys,json; d=json.load(sys.stdin); print(d.get('device_code',''))" 2>/dev/null)
USER_CODE=$(echo "$RESPONSE" | python3.13 -c "import sys,json; d=json.load(sys.stdin); print(d.get('user_code',''))" 2>/dev/null)
INTERVAL=$(echo "$RESPONSE" | python3.13 -c "import sys,json; d=json.load(sys.stdin); print(d.get('interval',5))" 2>/dev/null)

if [ -z "$DEVICE_CODE" ]; then
  echo "ERROR: Failed to parse device code from response."
  exit 1
fi

echo ""
echo "================================================"
echo "  1. Open:  https://github.com/login/device"
echo "  2. Enter: $USER_CODE"
echo "  3. Use the GitHub account with your COPILOT subscription"
echo "================================================"
echo ""
echo "You have 60 seconds before polling starts. Authorize now!"
echo ""
sleep 60

echo "==> Polling for access token..."
for i in $(seq 1 30); do
  TOKEN_RESP=$(curl -s --max-time 15 -X POST https://github.com/login/oauth/access_token \
    -H "Accept: application/json" \
    -d "client_id=$CLIENT_ID&device_code=$DEVICE_CODE&grant_type=urn:ietf:params:oauth:grant-type:device_code")

  echo "Poll $i raw: $TOKEN_RESP"

  ACCESS_TOKEN=$(echo "$TOKEN_RESP" | python3.13 -c "import sys,json; d=json.load(sys.stdin); t=d.get('access_token'); print(t if t else '')" 2>/dev/null)

  if [ -n "$ACCESS_TOKEN" ] && [ "$ACCESS_TOKEN" != "None" ] && [ "$ACCESS_TOKEN" != "" ]; then
    echo "$ACCESS_TOKEN" > "$TOKEN_FILE"
    chmod 600 "$TOKEN_FILE"
    echo ""
    echo "SUCCESS! Token saved. Now run: copilot-start"
    cat "$TOKEN_FILE" | head -c 10
    echo "..."
    exit 0
  fi

  ERROR=$(echo "$TOKEN_RESP" | python3.13 -c "import sys,json; d=json.load(sys.stdin); print(d.get('error',''))" 2>/dev/null)

  if [ "$ERROR" = "expired_token" ]; then
    echo "Code expired. Run this script again."
    exit 1
  fi

  sleep "${INTERVAL:-5}"
done

echo "Timed out. Run the script again."
exit 1
