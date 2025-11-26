# MCP BBS Demo Script

This script demonstrates how to use curl to interact with Icy Term's MCP server to automate BBS interactions.

## Quick Start

**Terminal 1 - Start Icy Term with MCP server:**
```bash
./target/release/icy_term --mcp-port 3000
```

**Terminal 2 - Run the demo script:**
```bash
./mcp_bbs_demo.sh 3000
```

## What the script does:

1. **Connects** to `lol.ddial.com:2300` (a Telnet BBS)
2. **Captures** the initial screen in ANSI format
3. **Gets** the initial terminal state
4. **For each F-key (F1-F12):**
   - Sends the key
   - Waits 1 second
   - Captures the screen
   - Gets the terminal state
5. **Disconnects** from the BBS

## Output

All captures and state data are saved to `mcp_captures/` directory:
- `capture_00_initial.ans` - Initial screen
- `capture_01.ans` through `capture_12.ans` - Screens after each F-key
- `state_00_initial.json` - Initial state
- `state_01.json` through `state_12.json` - State after each F-key

## Using the script

```bash
# Use default port 3000
./mcp_bbs_demo.sh

# Use custom port
./mcp_bbs_demo.sh 5000
```

## Manual curl examples

If you want to test individual commands:

```bash
# Connect to a BBS
curl -X POST http://127.0.0.1:3000 \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","method":"tools/call","params":{"name":"connect","arguments":{"url":"telnet://lol.ddial.com:2300"}},"id":1}'

# Send F1 key
curl -X POST http://127.0.0.1:3000 \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","method":"tools/call","params":{"name":"send_key","arguments":{"key":"f1"}},"id":1}'

# Capture screen in ANSI format
curl -X POST http://127.0.0.1:3000 \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","method":"tools/call","params":{"name":"capture_screen","arguments":{"format":"ansi"}},"id":1}'

# Get terminal state
curl -X POST http://127.0.0.1:3000 \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","method":"tools/call","params":{"name":"get_state","arguments":{}},"id":1}'

# Disconnect
curl -X POST http://127.0.0.1:3000 \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","method":"tools/call","params":{"name":"disconnect","arguments":{}},"id":1}'
```

## Prerequisites

- `curl` - for making HTTP requests
- `jq` - for parsing JSON responses (optional, but recommended)
- Icy Term running with `--mcp-port` flag

Install `jq` on Linux:
```bash
sudo apt-get install jq
```

Or on macOS:
```bash
brew install jq
```
