-- Fast login script for lol.ddial.com:2300
-- Sequence requested:
-- 1. Connect to lol.ddial.com:2300 (telnet)
-- 2. Press 'f' for fast login when prompt appears
-- 3. At the continue prompt press 'C'
-- 4. At the password/login selection prompt send a Right Arrow key to highlight r0dent
-- 5. When asked for guest name send "snowman" (or Unicode snowman) + CR
-- 6. After the word 'battle' appears send 't'
--
-- Adjust regex patterns below if the BBS uses different wording.

log("Starting lol.ddial.com fast login script...")

local url = connect("telnet://lol.ddial.com:2300")
log("Connected (requested): " .. url)

-- Helper: wait for pattern with logging
local function wait(pattern, timeout)
    log("Waiting for pattern: " .. pattern)
    local r = wait_for(pattern, timeout or 15000)
    if not r then
        log("ERROR: Timeout waiting for '" .. pattern .. "'")
        return false
    end
    return true
end

-- 1. Login prompt: the BBS shows just "login" (case-insensitive). When seen, press 'f'.
-- Use (?i) for case-insensitive regex.
if wait("(?i)login", 30000) then
    send("f")
    log("Detected 'login' and sent 'f' for fast login")
end

-- Make matching case-insensitive and more flexible
if wait("(?i)(continue|press c to continue|hit c)", 30000) then
    send("C")
    log("Sent 'C' to continue")
end

if wait("(?i)(password|login)", 40000) then
    send_key("right")
    log("Sent Right Arrow to highlight r0dent (assuming list navigation)")
end

-- After moving selection, look for any mention of 'guest' (case-insensitive)
if wait("(?i)guest", 30000) then
    local guest = "snowman"  -- Change to "☃" for Unicode snowman if desired
    send(guest .. "\r")
    log("Sent guest name: " .. guest)
    -- Allow the server to settle before next actions
    sleep(1000)
end

-- Detect battle phase; also accept exact 'TankBattle'
if wait("(?i)(battle|tankbattle)", 60000) then
    send("t")
    log("Sent 't' after battle/TankBattle appeared")
end

-- After sending 't', look for 'any' (case-insensitive) and send 'X'
-- Accept either 'world any' or just 'any'
if wait("(?i)(world any|any)", 30000) then
    send("X")
    log("Detected 'any' and sent 'X'")
end

-- Then detect 'msg' and send '/1' + Enter
if wait("(?i)msg", 30000) then
    -- Send command and explicitly press Enter via key mapping
    send("/1")
    send_key("enter")
    log("Detected 'msg' and sent '/1' + Enter (explicit)")
    
    -- While waiting for confirmation, keep nudging Enter until 'vacant snowman' appears
    local attempts = 0
    while (not on_screen("(?i)(vacant\\s+snowman|snowman\\s+vacant|vacant.*snowman|snowman.*vacant)")) and attempts < 10 do
        sleep(400)
        send_key("enter")
        attempts = attempts + 1
    end
    
    if on_screen("(?i)(vacant\\s+snowman|snowman\\s+vacant|vacant.*snowman|snowman.*vacant)") then
        log("'vacant snowman' detected; proceeding")
    else
        log("WARN: 'vacant snowman' not detected after retries; proceeding anyway")
    end
end

-- =========================
-- Configuration section (must come before test movement)
-- =========================
local TEST_MOVE_DELAY_MS     = 0        -- delay after test movement 'a' keys (set to 0)
local TOTAL_ACTIONS          = 0        -- total primary action picks (0 = run forever)
local NODELAY                = 0        -- 1 = no delay between keys, 0 = use MIN/MAX delays
local MIN_DELAY_MS           = 10       -- minimum delay between actions (ignored if NODELAY=1)
local MAX_DELAY_MS           = 100      -- maximum delay between actions (ignored if NODELAY=1)
local FIRE_REPEAT_CHANCE     = 0.30     -- chance that a fire action repeats multiple times
local MAX_FIRE_REPEAT        = 3        -- maximum consecutive fire presses
local EXTRA_MOVE_CHANCE      = 0.25     -- chance to follow a turn with a movement
local TURN_WEIGHT            = 3        -- relative weight for choosing a turn (a/d)
local FIRE_WEIGHT            = 2        -- relative weight for choosing fire (s)
local MOVE_WEIGHT            = 4        -- relative weight for choosing movement (arrow)

-- Then press 'a', move right 10 times, press 'a' twice, move left 10 times
send("a")
log("Sent 'a'")
sleep(TEST_MOVE_DELAY_MS)
for i = 1, 10 do
    send_key("right")
    sleep(TEST_MOVE_DELAY_MS)
end
log("Moved right 10 times")
send("a")
sleep(TEST_MOVE_DELAY_MS)
send("a")
log("Sent 'a' twice")
sleep(TEST_MOVE_DELAY_MS)
for i = 1, 10 do
    send_key("left")
    sleep(TEST_MOVE_DELAY_MS)
end
log("Moved left 10 times")

-- =========================
-- Random combat/movement phase
-- =========================
-- Sends random combinations of:
--   a = turn left
--   d = turn right
--   s = fire (may repeat consecutively)
--   arrow keys = movement
-- (Configuration already defined above)

math.randomseed(os.time())

local move_keys = {"up", "down", "left", "right"}

local function rand_delay()
    if NODELAY == 1 then
        return  -- no delay
    end
    local span = MAX_DELAY_MS - MIN_DELAY_MS
    local d = MIN_DELAY_MS + math.random(0, span)
    sleep(d)
end

local function do_fire_sequence()
    local repeats = 1
    if math.random() < FIRE_REPEAT_CHANCE then
        repeats = math.random(2, MAX_FIRE_REPEAT)
    end
    for i = 1, repeats do
        send("s")
        rand_delay()
    end
end

local function do_turn()
    if math.random(0,1) == 0 then
        send("a") -- turn left
        log("Action: turn left")
    else
        send("d") -- turn right
        log("Action: turn right")
    end
    rand_delay()
    -- Fire after turning
    send("s")
    log("Fire after turn")
    rand_delay()
    if math.random() < EXTRA_MOVE_CHANCE then
        local k = move_keys[math.random(1,#move_keys)]
        send_key(k)
        log("Follow-up move: " .. k)
        rand_delay()
    end
end

local function do_move()
    local k = move_keys[math.random(1,#move_keys)]
    local repeats = math.random(1, 10)
    log("Action: move " .. k .. " (" .. repeats .. "x)")
    for i = 1, repeats do
        send_key(k)
        rand_delay()
    end
end

-- Weighted random choice
local function pick_action()
    local total = TURN_WEIGHT + FIRE_WEIGHT + MOVE_WEIGHT
    local r = math.random() * total
    if r < TURN_WEIGHT then return "turn" end
    r = r - TURN_WEIGHT
    if r < FIRE_WEIGHT then return "fire" end
    return "move"
end

if TOTAL_ACTIONS == 0 then
    log("Starting random combat/movement phase (infinite loop)...")
    while true do
        local act = pick_action()
        if act == "turn" then
            do_turn()
        elseif act == "fire" then
            log("Action: fire")
            do_fire_sequence()
        else
            do_move()
        end
    end
else
    log("Starting random combat/movement phase (" .. TOTAL_ACTIONS .. " actions)...")
    for i = 1, TOTAL_ACTIONS do
        local act = pick_action()
        if act == "turn" then
            do_turn()
        elseif act == "fire" then
            log("Action: fire")
            do_fire_sequence()
        else
            do_move()
        end
    end
    log("Random combat/movement phase complete.")
end

log("lol_fast_login.lua finished.")
