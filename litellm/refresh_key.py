#!/usr/bin/env python3
"""
Refresh the GitHub Copilot API key and save it to ~/.config/litellm/github_copilot/api-key.json.
Run before starting the LiteLLM proxy to avoid startup auth timeouts.
"""
import httpx
import os
import json
import datetime
import time
import sys

ACCESS_TOKEN_FILE = os.path.expanduser("~/.config/litellm/github_copilot/access-token")
API_KEY_FILE = os.path.expanduser("~/.config/litellm/github_copilot/api-key.json")
COPILOT_TOKEN_URL = "https://api.github.com/copilot_internal/v2/token"

try:
    token = open(ACCESS_TOKEN_FILE).read().strip()
    if not token:
        print("ERROR: access-token file is empty.")
        sys.exit(1)
except FileNotFoundError:
    print(f"ERROR: No access token at {ACCESS_TOKEN_FILE}")
    print("Run: bash ~/User/aethergate/litellm/auth.sh")
    sys.exit(1)

headers = {
    "authorization": f"token {token}",
    "editor-version": "vscode/1.85.1",
    "editor-plugin-version": "copilot/1.155.0",
    "user-agent": "GithubCopilot/1.155.0",
    "accept": "application/json",
}

# Check if cached key is still valid (with 5-minute buffer)
try:
    cached = json.load(open(API_KEY_FILE))
    remaining = cached.get("expires_at", 0) - time.time()
    if remaining > 300:
        exp = datetime.datetime.fromtimestamp(cached["expires_at"])
        print(f"Copilot API key still valid until {exp.strftime('%H:%M:%S')} ({int(remaining)}s remaining). Skipping refresh.")
        sys.exit(0)
    else:
        print("Cached key expires soon or already expired. Refreshing...")
except (FileNotFoundError, json.JSONDecodeError, KeyError):
    print("No valid cached key found. Fetching new one...")

try:
    r = httpx.get(COPILOT_TOKEN_URL, headers=headers, timeout=15)
    r.raise_for_status()
    data = r.json()
    os.makedirs(os.path.dirname(API_KEY_FILE), exist_ok=True)
    json.dump(data, open(API_KEY_FILE, "w"))
    expires = datetime.datetime.fromtimestamp(data.get("expires_at", 0))
    print(f"Copilot API key refreshed. Valid until {expires.strftime('%H:%M:%S')}")
except httpx.HTTPStatusError as e:
    print(f"ERROR: HTTP {e.response.status_code}: {e.response.text[:200]}")
    sys.exit(1)
except Exception as e:
    print(f"ERROR fetching new key: {e}")
    print("Using expired/missing key - proxy may fail.")
    sys.exit(1)
