#!/bin/bash

# MCP BBS Demo Script
# This script demonstrates using curl to control icy_term via the MCP server
# Usage: ./mcp_bbs_demo.sh [port] (default: 3000)
# Usage: ./mcp_bbs_demo.sh --one [port] (default: 3000) - Run single sequence

MODE="${1:-normal}"
if [ "$MODE" = "--one" ]; then
    MCP_PORT="${2:-3000}"
    ONE_SEQUENCE=true
else
    MCP_PORT="${1:-3000}"
    ONE_SEQUENCE=false
fi

MCP_URL="http://127.0.0.1:${MCP_PORT}"
OUTPUT_DIR="mcp_captures"

# Create output directory for captures
mkdir -p "$OUTPUT_DIR"

# Helper function to make MCP calls
mcp_call() {
    local method=$1
    local params=$2
    local request_id=$((RANDOM))
    
    echo "[MCP] Calling: $method"
    
    local response=$(curl -s -X POST "$MCP_URL" \
        -H "Content-Type: application/json" \
        -d "{
            \"jsonrpc\": \"2.0\",
            \"method\": \"$method\",
            \"params\": $params,
            \"id\": $request_id
        }")
    
    echo "$response"
}

# Helper function to send text
send_text() {
    local text=$1
    mcp_call "tools/call" "{\"name\": \"send_text\", \"arguments\": {\"text\": \"$text\"}}"
}

# Helper function to send key
send_key() {
    local key=$1
    mcp_call "tools/call" "{\"name\": \"send_key\", \"arguments\": {\"key\": \"$key\"}}"
}

# Helper function to capture screen
capture_screen() {
    local format=$1
    local filename=$2
    echo "[CAPTURE] Saving screen to $filename"
    
    local response=$(mcp_call "tools/call" "{\"name\": \"capture_screen\", \"arguments\": {\"format\": \"$format\"}}")
    
    # Extract base64 data and save to file
    echo "$response" | jq -r '.result.content[0].text // .result.text' > "$filename"
}

# Helper function to get state
get_state() {
    echo "[STATE] Fetching terminal state..."
    mcp_call "tools/call" "{\"name\": \"get_state\", \"arguments\": {}}"
}

# Helper function to disconnect
disconnect() {
    echo "[DISCONNECT] Disconnecting from BBS..."
    mcp_call "tools/call" "{\"name\": \"disconnect\", \"arguments\": {}}"
}

# Main execution
echo "=========================================="
echo "MCP BBS Demo Script"
echo "MCP Server: $MCP_URL"
echo "=========================================="
echo ""

if [ "$ONE_SEQUENCE" = true ]; then
    # Single sequence mode: Connect, F key, C key, Right arrow, type MCP (enter), disconnect
    echo "[1/7] Connecting to lol.ddial.com:2300..."
    mcp_call "tools/call" "{\"name\": \"connect\", \"arguments\": {\"url\": \"telnet://lol.ddial.com:2300\"}}"
    sleep 2

    echo ""
    echo "[2/7] Capturing initial screen (ANSI)..."
    capture_screen "ansi" "$OUTPUT_DIR/capture_00_initial.ans"
    sleep 1

    echo ""
    echo "[3/7] Sending F key..."
    send_key "f1"
    sleep 1

    echo ""
    echo "[4/7] Sending C key..."
    send_text "c"
    sleep 1

    echo ""
    echo "[5/7] Sending Right arrow..."
    send_key "right"
    sleep 1

    echo ""
    echo "[6/7] Typing 'MCP' and pressing Enter..."
    send_text "MCP\n"
    sleep 2

    echo ""
    echo "[7/7] Capturing final screen (ANSI)..."
    capture_screen "ansi" "$OUTPUT_DIR/capture_01_final.ans"
    sleep 1

    echo ""
    echo "[8/7] Getting final terminal state..."
    get_state | jq '.' > "$OUTPUT_DIR/state_final.json"
    sleep 1

    echo ""
    echo "[9/7] Disconnecting..."
    disconnect
    sleep 1

    echo ""
    echo "=========================================="
    echo "Single sequence complete!"
    echo "Captures saved to: $OUTPUT_DIR/"
    echo "=========================================="
else
    # Original full demo with F1-F12
    # Step 1: Connect to BBS
    echo "[1/8] Connecting to lol.ddial.com:2300..."
    mcp_call "tools/call" "{\"name\": \"connect\", \"arguments\": {\"url\": \"telnet://lol.ddial.com:2300\"}}"
    sleep 2

    # Step 2: Capture screen (ANSI format)
    echo ""
    echo "[2/8] Capturing initial screen (ANSI)..."
    capture_screen "ansi" "$OUTPUT_DIR/capture_00_initial.ans"
    sleep 1

    # Step 3: Get state
    echo ""
    echo "[3/8] Getting terminal state..."
    get_state | jq '.' > "$OUTPUT_DIR/state_00_initial.json"
    sleep 1

    # Step 4-10: Send F1-F12 keys with captures in between
    for i in {1..12}; do
        echo ""
        echo "[$((i+3))/25] Sending F$i key..."
        send_key "f$i"
        sleep 1
        
        echo "Capturing screen after F$i (ANSI)..."
        capture_screen "ansi" "$OUTPUT_DIR/capture_$(printf "%02d" $((i))).ans"
        sleep 1
        
        echo "Getting state after F$i..."
        get_state | jq '.' > "$OUTPUT_DIR/state_$(printf "%02d" $((i))).json"
        sleep 1
    done

    # Final: Disconnect
    echo ""
    echo "[26/26] Disconnecting..."
    disconnect
    sleep 1

    echo ""
    echo "=========================================="
    echo "Demo complete! All captures saved to: $OUTPUT_DIR/"
    echo "ANSI captures: $OUTPUT_DIR/capture_*.ans"
    echo "State files: $OUTPUT_DIR/state_*.json"
    echo "=========================================="
fi
