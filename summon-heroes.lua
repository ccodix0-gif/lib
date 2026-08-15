-- NewReality - Summon Heroes [🚨]
-- Lobby placeId 117381420723145 | Waves placeId 80877167393789 | gameId 9802644580
-- Disk: settings/configs only. No script copy / farm.json on PC (Luarmor-ready).
-- Event currency HUD = Essence (Infinite Tower / Gear). Legacy Seashells/Event removed from UI.
-- Reminder: re-upload src/lib/interface.luau as interface.lua for the lib to update
-- (version 2026.08.15.01: opts.open=false so the shell stays hidden until tabs exist).

_G.NewRealityShowcase = false

local genv = (getgenv and getgenv()) or _G

-- Silence noisy game client boot prints (+ our own debug prints stay off)
do
    local mute = {
        "INITIALIZE SUMMON HEROES CLIENT",
        "Waiting for all systems to start up",
        "Waiting for local player data to load",
        "Player data took",
        "All systems took",
        "Game not fully loaded yet",
        "Game fully loaded!",
        "Roblox IsLoaded State",
        -- Roblox TextChatService noise (not from this script)
        "TACommands",
        "TextChatService",
    }
    local function shouldMute(...)
        local n = select("#", ...)
        for i = 1, n do
            local s = tostring(select(i, ...))
            for _, needle in ipairs(mute) do
                if s:find(needle, 1, true) then return true end
            end
        end
        return false
    end
    local oldPrint = print
    print = function(...)
        if shouldMute(...) then return end
        return oldPrint(...)
    end
    -- Also cover LogService mirror if executor routes through warn
    pcall(function()
        local oldWarn = warn
        warn = function(...)
            if shouldMute(...) then return end
            return oldWarn(...)
        end
    end)
end

-- Prevent stacking a million copies (same-session re-exec / stacked queue_on_teleport)
local function wipeShGuis()
    local function wipeIn(parent)
        if not parent then return end
        for _, c in ipairs(parent:GetChildren()) do
            if c:IsA("ScreenGui") then
                local n = c.Name
                local ours = n == "SH_ESP" or n == "SH_HUD" or n == "NewReality" or n == "NewRealityWindow"
                    or c:GetAttribute("SH_UI") == true
                if ours then
                    pcall(function() c:Destroy() end)
                end
            end
        end
    end
    pcall(function()
        local list = genv.SH_Screens
        if type(list) == "table" then
            for _, s in ipairs(list) do
                pcall(function() if s then s:Destroy() end end)
            end
        end
        genv.SH_Screens = {}
    end)
    pcall(function() wipeIn(game:GetService("CoreGui")) end)
    pcall(function() if gethui then wipeIn(gethui()) end end)
    pcall(function()
        local lp = game:GetService("Players").LocalPlayer
        if lp then wipeIn(lp:FindFirstChild("PlayerGui")) end
    end)
    pcall(function()
        local units = workspace:FindFirstChild("Units")
        if units then
            for _, m in ipairs(units:GetDescendants()) do
                if m:IsA("Highlight") and (m.Name == "SH_HL" or m.Name == "SH_ChestHL") then
                    m:Destroy()
                end
            end
        end
    end)
end

local BOOT_TOKEN = nil
do
    local fromTp = genv.SH_FromTeleport == true
    genv.SH_FromTeleport = nil

    -- Already running / mid-boot on this place (stacked queue copies).
    -- genv flags survive teleport; the ScreenGui does not. Skip only if a live window exists.
    if fromTp and genv.SH_BootPlace == game.PlaceId then
        local live = false
        pcall(function()
            for _, s in ipairs(genv.SH_Screens or {}) do
                if s and s.Parent then live = true end
            end
        end)
        if live and (genv.SH_Alive == true or genv.SH_Booting == true) then
            return
        end
        genv.SH_Alive = false
        genv.SH_Booting = false
    end

    local token = tostring(os.clock()) .. "_" .. tostring(math.random(1, 1e9))
    genv.SH_BootClaim = token
    genv.SH_Booting = true
    genv.SH_LoadLock = os.clock()
    genv.SH_BootPlace = game.PlaceId
    task.wait(0.08)
    if genv.SH_BootClaim ~= token then
        return
    end

    -- Manual re-exec / hop: tear down leftovers so UIs never stack.
    if genv.SH_Unload then
        pcall(genv.SH_Unload)
    end
    wipeShGuis()

    -- Queue was consumed by this hop — must re-arm at end of boot.
    genv.SH_TeleportArmed = nil
    genv.SH_ArmedUrl = nil

    BOOT_TOKEN = token
    genv.SH_Session = token
    genv.SH_BootAt = os.clock()
    genv.SH_Alive = false
end

if type(BOOT_TOKEN) ~= "string" then
    return
end

local function stillThisBoot()
    return genv.SH_BootClaim == BOOT_TOKEN
end

-- The library has a file name of its own so this cannot accidentally download one of the
-- scripts that load it. That mistake is silent: the wrong file is a healthy size, it
-- compiles and it runs, and if it happens to be a loader it fetches itself in a loop until
-- something gives out. Size tells them apart at a glance, the library being about twenty
-- times the larger. The old name is tried last so an existing upload keeps working.
local LIB_BASE = "https://raw.githubusercontent.com/ccodix0-gif/lib/refs/heads/main/"
local LIB_NAMES = { "interface.lua", "interface.luau", "nw.lua" }

local function loadLibrary()
    local notes = {}
    for _, name in ipairs(LIB_NAMES) do
        local text
        local got = pcall(function() text = game:HttpGet(LIB_BASE .. name) end)
        if not got or type(text) ~= "string" then
            notes[#notes + 1] = name .. ": no download"
        elseif #text < 300000 then
            notes[#notes + 1] = name .. ": " .. #text .. " bytes, too small for the library"
        elseif not string.find(text, "Interface.version", 1, true) then
            notes[#notes + 1] = name .. ": not the library"
        else
            local chunk, compileErr = loadstring(text)
            if not chunk then return nil, name .. " does not compile: " .. tostring(compileErr) end
            local ran, result = pcall(chunk)
            if not ran then return nil, name .. " threw while loading: " .. tostring(result) end
            if type(result) ~= "table" or type(result.new) ~= "function" then
                return nil, name .. " loaded but has no UI.new"
            end
            return result
        end
    end
    return nil, "no library found, tried " .. table.concat(notes, "; ")
end

-- Autoexec / queue_on_teleport run on the loading screen. The UI library captures
-- Players.LocalPlayer at chunk load; UI.new there paints an empty NewReality that
-- never gets tabs (Plugin dies on the next yield). Wait before both.
local Players = game:GetService("Players")
local function waitPlaceReady(sec)
    local t0 = os.clock()
    while os.clock() - t0 < (sec or 30) do
        if not stillThisBoot() then return false end
        local loaded = false
        pcall(function() loaded = game:IsLoaded() end)
        local lp = Players.LocalPlayer
        if loaded and lp and lp:FindFirstChild("PlayerGui") then
            task.wait(0.5)
            return stillThisBoot()
        end
        task.wait(0.12)
    end
    return Players.LocalPlayer ~= nil
end
if not waitPlaceReady(30) then
    if not stillThisBoot() then return end
end
if not stillThisBoot() then
    return
end
if not Players.LocalPlayer then
    genv.SH_Booting = false
    genv.SH_LoadLock = nil
    genv.SH_Alive = false
    warn("[SH] LocalPlayer missing")
    return
end

local UI, loadErr = loadLibrary()
if not stillThisBoot() then
    return
end
if not UI then
    genv.SH_LoadLock = nil
    genv.SH_Booting = false
    genv.SH_Alive = false
    warn("[SH] " .. tostring(loadErr))
    return
end

-- ============================================================ SERVICES
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local CollectionService = game:GetService("CollectionService")
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local TweenService = game:GetService("TweenService")

local LP = Players.LocalPlayer
if not LP then
    genv.SH_Booting = false
    genv.SH_LoadLock = nil
    warn("[SH] LocalPlayer missing")
    return
end
local Camera = Workspace.CurrentCamera
pcall(function()
    Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
        if Workspace.CurrentCamera then Camera = Workspace.CurrentCamera end
    end)
end)

local PLACE_LOBBY = 117381420723145
local PLACE_WAVES = 80877167393789
-- From Map.IsPVPMap place table (game dump)
local PLACE_PVP = {
    [76034736091213] = true,
    [128314954869462] = true,
    [96840997305685] = true,
    [80728320154598] = true,
}
-- Settings/configs live under NewReality (UI lib). Loader URL may be cached on disk; never script source.
local ESP_FONT
do
    local ok, font = pcall(Font.new, "rbxasset://fonts/families/Arial.json", Enum.FontWeight.Heavy, Enum.FontStyle.Normal)
    if ok then ESP_FONT = font end
end

-- Kill leftover GUIs / highlights from a previous stacked run
pcall(wipeShGuis)
if not stillThisBoot() then
    return
end

-- Window is created immediately before tabs. UI.new on this thread *before* the
-- helper IIFEs used to flash an empty NewReality (chrome, no sidebar) because
-- the next yield killed Plugin and win:tab never ran.
local win
local F = {}
local wm, kb
local espGui, hudGui
-- Never WaitForChild on this thread — a yield before win:tab strips Plugin and leaves an empty window.
local function parentShGui(gui)
    local pg = LP and LP:FindFirstChild("PlayerGui")
    if pg then
        gui.Parent = pg
        return
    end
    pcall(function() gui.Parent = (gethui and gethui()) or game:GetService("CoreGui") end)
end
local function ensureEspHud()
    if not (espGui and espGui.Parent) then
        local g = Instance.new("ScreenGui")
        g.Name = "SH_ESP"
        g.ResetOnSpawn = false
        g.IgnoreGuiInset = true
        pcall(function() g:SetAttribute("SH_UI", true) end)
        pcall(function() g.DisplayOrder = 20 end)
        parentShGui(g)
        espGui = g
    end
    if not (hudGui and hudGui.Parent) then
        local g = Instance.new("ScreenGui")
        g.Name = "SH_HUD"
        g.ResetOnSpawn = false
        g.IgnoreGuiInset = true
        g.Enabled = true
        pcall(function() g:SetAttribute("SH_UI", true) end)
        pcall(function() g.DisplayOrder = 1e9 end)
        pcall(function() g.ZIndexBehavior = Enum.ZIndexBehavior.Sibling end)
        parentShGui(g)
        hudGui = g
    end
end

local function createWindow()
    if win then return true end
    if not stillThisBoot() then return false end
    pcall(wipeShGuis)
    local okNew, result = pcall(function()
        return UI.new({
            icon = "logo",
            toggleKey = Enum.KeyCode.RightShift,
            entrance = false,
            open = false,
        })
    end)
    if not okNew or type(result) ~= "table" or type(result.tab) ~= "function" then
        warn("[SH] UI.new failed: " .. tostring(result))
        return false
    end
    win = result
    if type(win.flags) == "table" and win.flags ~= F then
        for k, v in pairs(win.flags) do
            if F[k] == nil then F[k] = v end
        end
    end
    win.flags = F
    pcall(function()
        if win._open then
            win:toggle(false)
        end
        if win.window then
            win.window.Visible = false
            win._open = false
        end
    end)
    pcall(function()
        if win.screen then
            win.screen:SetAttribute("SH_UI", true)
            genv.SH_Screens = genv.SH_Screens or {}
            table.insert(genv.SH_Screens, win.screen)
        end
    end)
    pcall(ensureEspHud)
    return true
end

-- ============================================================ PERSIST / TELEPORT RELOAD
-- URL only on disk (Luarmor-safe). Never write script source.
local SESSION = BOOT_TOKEN
local teleportArmed = false
local LOADER_DIR = "NewReality/SummonHeroes"
local LOADER_PATH = LOADER_DIR .. "/loader-url.txt"
local HUD_LAYOUT_PATH = LOADER_DIR .. "/hud-layout.json"

local function ensureLoaderDir()
    if type(makefolder) ~= "function" then return end
    pcall(function()
        if isfolder and not isfolder("NewReality") then makefolder("NewReality") end
        if isfolder and not isfolder(LOADER_DIR) then makefolder(LOADER_DIR) end
    end)
end

local function readHudLayoutFile()
    if type(isfile) ~= "function" or type(readfile) ~= "function" then return nil end
    local ok, raw = pcall(function()
        if not isfile(HUD_LAYOUT_PATH) then return nil end
        return readfile(HUD_LAYOUT_PATH)
    end)
    if not ok or type(raw) ~= "string" or raw == "" then return nil end
    local ok2, data = pcall(function()
        return HttpService:JSONDecode(raw)
    end)
    if ok2 and type(data) == "table" then return data end
    return nil
end

local function writeHudLayoutFile(data)
    if type(writefile) ~= "function" then return false, "no writefile" end
    if type(data) ~= "table" then return false, "no data" end
    ensureLoaderDir()
    local ok, enc = pcall(function()
        return HttpService:JSONEncode(data)
    end)
    if not ok or type(enc) ~= "string" then return false, "json encode failed" end
    local okW, err = pcall(writefile, HUD_LAYOUT_PATH, enc)
    if not okW then return false, tostring(err) end
    return true, nil
end

-- Pack UDim2 as {scaleX, offX, scaleY, offY, visible}
local function packOverlayPos(frame, rest)
    local p = rest or (frame and frame.Position)
    if not p then return nil end
    local vis = 1
    if frame then vis = frame.Visible and 1 or 0 end
    return { p.X.Scale, p.X.Offset, p.Y.Scale, p.Y.Offset, vis }
end

local function unpackOverlayPos(t)
    if type(t) ~= "table" then return nil end
    -- New format: {sx,ox,sy,oy,v} or file format {x,y,v} (legacy absolute)
    if t.x ~= nil and t.y ~= nil and t[1] == nil then
        return UDim2.new(0, tonumber(t.x) or 0, 0, tonumber(t.y) or 0), t.v
    end
    if t[1] == nil or t[2] == nil or t[3] == nil or t[4] == nil then return nil end
    return UDim2.new(tonumber(t[1]) or 0, tonumber(t[2]) or 0, tonumber(t[3]) or 0, tonumber(t[4]) or 0), t[5]
end

-- Manual Save only: write exact Position (as dragged) into flags + lib config + backup file.
genv.SH_SaveHudLayout = function()
    local w = win
    if not w or type(w._overlays) ~= "table" then
        return false, "UI not ready"
    end
    if type(w._overlayRest) ~= "table" then w._overlayRest = {} end
    if type(w._overlayPos) ~= "table" then w._overlayPos = {} end

    local layout = {}
    local count = 0
    for key, frame in pairs(w._overlays) do
        if frame and frame.Parent then
            -- Prefer live Position after drag (rest may lag if lib didn't update).
            local packed = packOverlayPos(frame, frame.Position)
            if packed then
                layout[key] = packed
                w._overlayRest[key] = UDim2.new(packed[1], packed[2], packed[3], packed[4])
                w._overlayPos[key] = packed
                count += 1
            end
        end
    end
    if count == 0 then return false, "no overlays" end

    F.hudLayout = layout
    w.flags.hudLayout = layout
    pcall(function() w:markDirty() end)

    local cfgName = nil
    pcall(function()
        cfgName = (w.getAutoSave and w:getAutoSave()) or (w.getAutoLoad and w:getAutoLoad()) or "default"
    end)
    cfgName = (type(cfgName) == "string" and cfgName ~= "" and cfgName) or "default"

    local cfgOk = false
    pcall(function()
        cfgOk = w:saveConfig(cfgName, true) == true
    end)

    local fileOk = select(1, writeHudLayoutFile(layout))

    if cfgOk or fileOk then
        return true, nil
    end
    return false, "saveConfig+file both failed"
end

genv.SH_ApplyHudLayout = function()
    local w = win
    if not w or type(w._overlays) ~= "table" then return 0 end
    if type(w._overlayRest) ~= "table" then w._overlayRest = {} end
    if type(w._overlayPos) ~= "table" then w._overlayPos = {} end

    -- Prefer flag (inside normal config), then backup file, then lib _overlayPos.
    local data = F.hudLayout or (w.flags and w.flags.hudLayout)
    if type(data) ~= "table" or not next(data) then
        data = readHudLayoutFile()
    end
    if type(data) ~= "table" or not next(data) then
        data = w._overlayPos
    end
    if type(data) ~= "table" then return 0 end

    local n = 0
    for key, t in pairs(data) do
        local frame = w._overlays[key]
        local at, vis = unpackOverlayPos(t)
        if frame and frame.Parent and at then
            frame.Position = at
            w._overlayRest[key] = at
            w._overlayPos[key] = packOverlayPos(frame, at)
            n += 1
        end
    end
    return n
end

local function readLoaderUrlDisk()
    if type(isfile) ~= "function" or type(readfile) ~= "function" then return nil end
    local ok, text = pcall(function()
        if not isfile(LOADER_PATH) then return nil end
        return readfile(LOADER_PATH)
    end)
    if not ok or type(text) ~= "string" then return nil end
    text = text:gsub("^%s+", ""):gsub("%s+$", "")
    if #text > 8 then return text end
    return nil
end

local function writeLoaderUrlDisk(url)
    if type(url) ~= "string" or #url < 9 then return false end
    if type(writefile) ~= "function" then return false end
    ensureLoaderDir()
    local ok = pcall(writefile, LOADER_PATH, url)
    return ok == true
end

-- Boot: restore URL from disk if genv/config empty
do
    local disk = readLoaderUrlDisk()
    if disk then
        if type(genv.SH_ScriptUrl) ~= "string" or #genv.SH_ScriptUrl < 9 then
            genv.SH_ScriptUrl = disk
        end
        if type(F.scriptUrl) ~= "string" or #F.scriptUrl < 9 then
            F.scriptUrl = disk
        end
    end
end

local function resolveScriptUrl()
    local u = F.scriptUrl or genv.SH_ScriptUrl or genv.SH_HttpUrl or readLoaderUrlDisk()
    if type(u) == "string" and #u > 8 then return u end
    return nil
end

local function saveScriptUrl(url)
    if type(url) ~= "string" or #url < 9 then return false end
    F.scriptUrl = url
    genv.SH_ScriptUrl = url
    writeLoaderUrlDisk(url)
    return true
end

local function armTeleportReload(force)
    -- Most executors APPEND queue_on_teleport. Never enqueue the same URL twice.
    local url = resolveScriptUrl()
    if not url then return false end
    if (teleportArmed or genv.SH_TeleportArmed == true) and genv.SH_ArmedUrl == url then
        teleportArmed = true
        return true
    end
    local q
    pcall(function()
        q = queue_on_teleport
            or (syn and syn.queue_on_teleport)
            or (fluxus and fluxus.queue_on_teleport)
            or queueteleport
            or (getgenv and (getgenv().queue_on_teleport or getgenv().queueteleport))
            or (crypt and crypt.queue_on_teleport)
    end)
    if type(q) ~= "function" then return false end

    saveScriptUrl(url)

    -- Minimal stub: main script owns wipe/lock. Early-out if already alive here.
    local body = string.format([[
repeat task.wait() until game:IsLoaded()
local Players = game:GetService("Players")
repeat task.wait() until Players.LocalPlayer
task.wait(1.25)
local g = (getgenv and getgenv()) or _G
if g.SH_BootPlace == game.PlaceId and (g.SH_Alive == true or g.SH_Booting == true) then
    return
end
g.SH_FromTeleport = true
local url = %q
pcall(function()
    if type(readfile) == "function" and type(isfile) == "function"
        and isfile("NewReality/SummonHeroes/loader-url.txt") then
        local t = readfile("NewReality/SummonHeroes/loader-url.txt")
        if type(t) == "string" then
            t = t:gsub("^%%s+", ""):gsub("%%s+$", "")
            if #t > 8 then url = t end
        end
    end
end)
g.SH_ScriptUrl = url
pcall(function()
    if writefile then
        if makefolder then
            if not (isfolder and isfolder("NewReality")) then makefolder("NewReality") end
            if not (isfolder and isfolder("NewReality/SummonHeroes")) then makefolder("NewReality/SummonHeroes") end
        end
        writefile("NewReality/SummonHeroes/loader-url.txt", url)
    end
end)
local function http(u)
    local src
    local ok = pcall(function() src = game:HttpGet(u) end)
    if ok and type(src) == "string" and #src > 200 then return src end
    pcall(function()
        local req = (syn and syn.request) or request or http_request or (http and http.request)
        if type(req) == "function" then
            local r = req({ Url = u, Method = "GET" })
            if r and type(r.Body) == "string" and #r.Body > 200 then src = r.Body end
        end
    end)
    return src
end
local src
for _ = 1, 6 do
    src = http(url)
    if src then break end
    task.wait(1)
end
if not src then
    warn("[SH] teleport reload: HttpGet failed for " .. tostring(url))
    g.SH_FromTeleport = nil
    return
end
local chunk, err = loadstring(src)
if not chunk then
    warn("[SH] teleport reload compile", err)
    g.SH_FromTeleport = nil
    return
end
local ok2, err2 = pcall(chunk)
if not ok2 then
    warn("[SH] teleport reload fail", err2)
    g.SH_FromTeleport = nil
    g.SH_Booting = false
    g.SH_LoadLock = nil
end
]], url)
    local okq = pcall(q, body)
    if okq then
        teleportArmed = true
        genv.SH_TeleportArmed = true
        genv.SH_ArmedUrl = url
    end
    return okq == true
end

-- Do NOT re-arm on every teleport state — that stacks queue copies.

-- Farm stats: memory only (genv across teleport). No farm.json on disk.
local lastFarmSaveAt = 0
local farm = genv.SH_Farm
if type(farm) ~= "table" then
    farm = {
        coinsEarned = 0, gemsEarned = 0, essenceEarned = 0, essenceDustEarned = 0,
        pvpTokensEarned = 0,
        runs = 0, chestsOpened = 0,
        chestCoins = 0, chestGems = 0,
        startedAt = os.time(),
        lastCoins = nil, lastGems = nil, lastEssence = nil, lastEssenceDust = nil, lastPvpTokens = nil,
        pendingChestCoins = 0, pendingChestGems = 0,
    }
else
    farm.coinsEarned = farm.coinsEarned or 0
    farm.gemsEarned = farm.gemsEarned or 0
    farm.essenceEarned = farm.essenceEarned or farm.eventEarned or 0
    farm.essenceDustEarned = farm.essenceDustEarned or 0
    farm.pvpTokensEarned = farm.pvpTokensEarned or 0
    farm.pendingChestCoins = farm.pendingChestCoins or 0
    farm.pendingChestGems = farm.pendingChestGems or 0
    farm.chestCoins = farm.chestCoins or 0
    farm.chestGems = farm.chestGems or 0
    farm.startedAt = tonumber(farm.startedAt) or os.time()
    -- Drop legacy Seashells/Event session fields
    farm.eventEarned, farm.chestEvent, farm.pendingChestEvent, farm.lastEvent = nil, nil, nil, nil
end
genv.SH_Farm = farm

local function flushFarmDisk()
    genv.SH_Farm = farm
    lastFarmSaveAt = tick()
end

-- After tabs exist. queue_on_teleport / writefile can yield and used to blank the window.
task.defer(function()
    if stillThisBoot() then
        pcall(armTeleportReload)
    end
end)

-- Unload hook so a re-exec kills the previous instance instead of stacking
genv.SH_Unload = function()
    genv.SH_Alive = false
    -- Do not clear BootClaim / Booting / BootPlace / Session — a newer boot owns those.
    pcall(flushFarmDisk)
    pcall(function()
        if win and win.unload then
            win:unload()
        elseif win and win.screen then
            win.screen:Destroy()
        end
    end)
    pcall(function() if espGui then espGui:Destroy() end end)
    pcall(function() if hudGui then hudGui:Destroy() end end)
    -- Not wipeShGuis — that would destroy a newer boot's window.
    pcall(function() RunService:UnbindFromRenderStep("SH_Camera") end)
end

-- Luau limit: 200 locals per function. Keep setup thin; body runs in nested scopes.
local function __SH_BOOT__()
if not stillThisBoot() then return end

-- ============================================================ HELPERS
local remoteCache = {}
local function rem(name)
    local cached = remoteCache[name]
    if cached and cached.Parent then return cached end
    remoteCache[name] = nil
    local folder = ReplicatedStorage:FindFirstChild("Remotes")
    if not folder then return nil end
    local node = folder:FindFirstChild(name)
    if node then remoteCache[name] = node end
    return node
end
local function fire(name, ...)
    local n = rem(name)
    if not n then
        -- Remotes may not exist yet right after teleport/join
        local folder = ReplicatedStorage:FindFirstChild("Remotes") or ReplicatedStorage:WaitForChild("Remotes", 2)
        n = folder and folder:FindFirstChild(name)
        if n then remoteCache[name] = n end
    end
    if n and n:IsA("RemoteEvent") then
        local a = { ... }
        return pcall(function() n:FireServer(table.unpack(a)) end)
    end
    return false
end
local function invoke(name, ...)
    local n = rem(name)
    if not n then
        local folder = ReplicatedStorage:FindFirstChild("Remotes") or ReplicatedStorage:WaitForChild("Remotes", 2)
        n = folder and folder:FindFirstChild(name)
        if n then remoteCache[name] = n end
    end
    if n and n:IsA("RemoteFunction") then
        local a = { ... }
        local ok2, a1, a2, a3 = pcall(function() return n:InvokeServer(table.unpack(a)) end)
        if ok2 then return true, a1, a2, a3 end
    end
    return false
end

local function isLobby()
    if game.PlaceId == PLACE_LOBBY then return true end
    if game.PlaceId == PLACE_WAVES then return false end
    if PLACE_PVP[game.PlaceId] then return false end
    if ReplicatedStorage:FindFirstChild("WaveInfo") then return false end
    local v = ReplicatedStorage:GetAttribute("IsLobby")
    if v ~= nil then return v == true end
    -- Unknown place with no WaveInfo → treat as lobby-ish
    return true
end

local function isPvpWorld()
    if PLACE_PVP[game.PlaceId] then return true end
    if LP:GetAttribute("InPVPMatch") == true then return true end
    if Workspace:FindFirstChild("PVPMap") ~= nil then return true end
    local gm = ReplicatedStorage:GetAttribute("Gamemode")
    if gm == "PVP" or gm == "Tournaments" then return true end
    -- Arena maps often still expose Systems.PVP while in-place
    local systems = ReplicatedStorage:FindFirstChild("Systems")
    if systems and systems:FindFirstChild("PVP") and game.PlaceId ~= PLACE_LOBBY and game.PlaceId ~= PLACE_WAVES then
        -- Only treat unknown non-lobby/waves places with PVP module as arena when map present
        if Workspace:FindFirstChild("Map") and not ReplicatedStorage:FindFirstChild("WaveInfo") then
            return true
        end
    end
    return false
end

local function char() return LP.Character end
local function hrp() local c = char() return c and c:FindFirstChild("HumanoidRootPart") end
local function hum() local c = char() return c and c:FindFirstChildOfClass("Humanoid") end
local function rootOf(model)
    if not model then return nil end
    return model:FindFirstChild("HumanoidRootPart") or model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart")
end
local function humOf(model) return model and model:FindFirstChildOfClass("Humanoid") end
local function w2v(pos)
    local v, on = Camera:WorldToViewportPoint(pos)
    return Vector2.new(v.X, v.Y), on, v.Z
end
local function distTo(pos)
    local r = hrp()
    if not r then return math.huge end
    return (r.Position - pos).Magnitude
end

local RISK_MED = { Color3.fromRGB(255, 196, 92), Color3.fromRGB(255, 142, 52) }
local RISK_HIGH = { Color3.fromRGB(255, 120, 120), Color3.fromRGB(232, 46, 46) }
local function mark(row, level)
    if not row then return end
    local lbl
    for _, d in ipairs(row:GetDescendants()) do
        if d:IsA("TextLabel") then lbl = d break end
    end
    if not lbl then return end
    local set = level == "high" and RISK_HIGH or RISK_MED
    lbl.TextColor3 = set[1]
    local old = lbl:FindFirstChildOfClass("UIGradient")
    if old then old:Destroy() end
    local g = Instance.new("UIGradient")
    g.Color = ColorSequence.new(set[1], set[2])
    g.Parent = lbl
end
local function tog(card, label, key, default, risk)
    local g, s = win:flag(key, default)
    local row = card:toggle(label, g, s)
    if risk then mark(row, risk) end
    return g
end
local function togBind(card, label, key, default, defKey, risk)
    local g, s = win:flag(key, default)
    local row = card:toggle(label, g, s)
    if risk then mark(row, risk) end
    -- Library stores key names as strings ("F"), not EnumItem
    local defName = defKey
    if typeof(defKey) == "EnumItem" then defName = defKey.Name end
    local bg, bs = win:flag(key .. "Keys", defName and { tostring(defName) } or {})
    card:keybind(label .. " Key", bg, bs, {
        multi = true, listName = label,
        active = function() return win.flags[key] end,
        callback = function()
            win.flags[key] = not win.flags[key]
            win:refreshAll()
            win:notify({ title = label, text = win.flags[key] and "On" or "Off", icon = "bolt" })
        end,
    })
    return g
end
local function colorFlag(card, label, key, r, g, b, alpha)
    win:flag(key, alpha and { r, g, b, 1 } or { r, g, b })
    card:colorpicker(label, function() return win.flags[key] end, function(c) win.flags[key] = c end, alpha and { alpha = true } or nil)
end
local function colOf(key, r, g, b)
    local t = win.flags[key] or { r, g, b }
    return Color3.fromRGB(t[1] or r, t[2] or g, t[3] or b)
end
local function alphaOf(key)
    local t = win.flags[key]
    return (t and tonumber(t[4])) or 1
end
local function slider(card, label, key, min, max, default, dec)
    local g, s = win:flag(key, default)
    card:slider(label, min, max, g, s, dec or 0)
end
local function loop(getEnabled, fn, interval)
    local acc = 0
    RunService.Heartbeat:Connect(function(dt)
        if genv.SH_Session ~= SESSION or not genv.SH_Alive then return end
        if not getEnabled() then return end
        local iv = interval
        if type(interval) == "function" then
            iv = interval()
        end
        if iv then
            acc = acc + dt
            if acc < iv then return end
            acc = 0
        end
        pcall(fn)
    end)
end
local function notify(title, text, icon)
    win:notify({ title = title, text = text, icon = icon or "bell" })
end

-- ============================================================ PROFILE / CURRENCY
local function getProfile()
    local pg = LP:FindFirstChild("PlayerGui")
    return pg and pg:FindFirstChild("Profile")
end
local function getCurrency(name)
    local p = getProfile()
    if not p then return nil end
    local cur = p:FindFirstChild("Currencies")
    local v = cur and cur:FindFirstChild(name)
    return v and v.Value or nil
end

local currencyHooks = setmetatable({}, { __mode = "k" })

local function applyCurrencyDelta(kind, newVal)
    newVal = tonumber(newVal)
    if newVal == nil then return end
    if kind == "Coins" then
        if farm.lastCoins == nil then
            farm.lastCoins = newVal
            return
        end
        local d = newVal - farm.lastCoins
        if d > 0 and d < 5e7 then
            -- Skip amount already counted from OpenChest (awarded later at GameOver)
            local pending = tonumber(farm.pendingChestCoins) or 0
            local skip = math.min(d, pending)
            farm.pendingChestCoins = math.max(0, pending - skip)
            local extra = d - skip
            if extra > 0 then
                farm.coinsEarned = (farm.coinsEarned or 0) + extra
            end
        end
        farm.lastCoins = newVal
    elseif kind == "Gems" then
        if farm.lastGems == nil then
            farm.lastGems = newVal
            return
        end
        local d = newVal - farm.lastGems
        if d > 0 and d < 5e6 then
            local pending = tonumber(farm.pendingChestGems) or 0
            local skip = math.min(d, pending)
            farm.pendingChestGems = math.max(0, pending - skip)
            local extra = d - skip
            if extra > 0 then
                farm.gemsEarned = (farm.gemsEarned or 0) + extra
            end
        end
        farm.lastGems = newVal
    elseif kind == "Essence" then
        if farm.lastEssence == nil then
            farm.lastEssence = newVal
            return
        end
        local d = newVal - farm.lastEssence
        if d > 0 and d < 5e6 then
            farm.essenceEarned = (farm.essenceEarned or 0) + d
        end
        farm.lastEssence = newVal
    elseif kind == "PVPTokens" then
        if farm.lastPvpTokens == nil then
            farm.lastPvpTokens = newVal
            return
        end
        local d = newVal - farm.lastPvpTokens
        if d > 0 and d < 5e6 then
            farm.pvpTokensEarned = (farm.pvpTokensEarned or 0) + d
        end
        farm.lastPvpTokens = newVal
    end
    -- Legacy "Event"/Seashells deliberately ignored (old event currency)
    genv.SH_Farm = farm
end

local function rebaselineCurrency()
    local coins = getCurrency("Coins")
    local gems = getCurrency("Gems")
    local essence = getCurrency("Essence")
    local pvpTok = getCurrency("PVPTokens")
    if coins ~= nil then applyCurrencyDelta("Coins", coins) end
    if gems ~= nil then applyCurrencyDelta("Gems", gems) end
    if essence ~= nil then applyCurrencyDelta("Essence", essence) end
    if pvpTok ~= nil then applyCurrencyDelta("PVPTokens", pvpTok) end
    if coins ~= nil then farm.lastCoins = coins end
    if gems ~= nil then farm.lastGems = gems end
    if essence ~= nil then farm.lastEssence = essence end
    if pvpTok ~= nil then farm.lastPvpTokens = pvpTok end
end

local function isCurrencyValue(v)
    return v and (v:IsA("NumberValue") or v:IsA("IntValue"))
end

local function hookCurrencyValues()
    local p = getProfile()
    local cur = p and p:FindFirstChild("Currencies")
    if not cur then return end
    for _, name in ipairs({ "Coins", "Gems", "Essence", "PVPTokens" }) do
        local v = cur:FindFirstChild(name)
        if isCurrencyValue(v) and not currencyHooks[v] then
            currencyHooks[v] = true
            applyCurrencyDelta(name, v.Value)
            v:GetPropertyChangedSignal("Value"):Connect(function()
                if genv.SH_Session ~= SESSION or not genv.SH_Alive then return end
                applyCurrencyDelta(name, v.Value)
                if tick() - lastFarmSaveAt >= 1 then flushFarmDisk() end
            end)
        end
    end
end

local function updateFarmStats()
    hookCurrencyValues()
    local coins = getCurrency("Coins")
    local gems = getCurrency("Gems")
    local essence = getCurrency("Essence")
    local pvpTok = getCurrency("PVPTokens")
    if coins ~= nil then applyCurrencyDelta("Coins", coins) end
    if gems ~= nil then applyCurrencyDelta("Gems", gems) end
    if essence ~= nil then applyCurrencyDelta("Essence", essence) end
    if pvpTok ~= nil then applyCurrencyDelta("PVPTokens", pvpTok) end
    if tick() - lastFarmSaveAt >= 5 then
        flushFarmDisk()
    end
end

local function noteChestsOpened(n)
    n = tonumber(n) or 0
    if n <= 0 then return end
    farm.chestsOpened = (farm.chestsOpened or 0) + n
    genv.SH_Farm = farm
    flushFarmDisk()
end

-- Server awards chest currency only at GameOver; OpenChest fires immediately with reward type
local function noteChestReward(rewardType, coinAmount)
    rewardType = tostring(rewardType or "")
    coinAmount = tonumber(coinAmount) or 0
    if rewardType == "Gems" then
        farm.chestGems = (farm.chestGems or 0) + 50
        farm.gemsEarned = (farm.gemsEarned or 0) + 50
        farm.pendingChestGems = (farm.pendingChestGems or 0) + 50
    elseif rewardType == "Coins" then
        local amt = coinAmount > 0 and coinAmount or 0
        if amt > 0 then
            farm.chestCoins = (farm.chestCoins or 0) + amt
            farm.coinsEarned = (farm.coinsEarned or 0) + amt
            farm.pendingChestCoins = (farm.pendingChestCoins or 0) + amt
        end
    elseif rewardType == "Essence" then
        local amt = coinAmount > 0 and coinAmount or 0
        if amt > 0 then
            farm.essenceEarned = (farm.essenceEarned or 0) + amt
        end
    end
    -- Legacy chest "Event"/Seashells ignored
    genv.SH_Farm = farm
    flushFarmDisk()
end

local function hookOpenChestRewards()
    local hooked = setmetatable({}, { __mode = "k" })
    local function bind(ev)
        if not ev or not ev:IsA("RemoteEvent") or hooked[ev] then return end
        hooked[ev] = true
        ev.OnClientEvent:Connect(function(_part, rewardType, _item, coinAmount)
            if genv.SH_Session ~= SESSION or not genv.SH_Alive then return end
            pcall(noteChestReward, rewardType, coinAmount)
        end)
    end
    local folder = ReplicatedStorage:FindFirstChild("Remotes")
    if folder then bind(folder:FindFirstChild("OpenChest")) end
    task.spawn(function()
        local remotes = ReplicatedStorage:WaitForChild("Remotes", 30)
        if remotes then
            bind(remotes:FindFirstChild("OpenChest") or remotes:WaitForChild("OpenChest", 10))
            remotes.ChildAdded:Connect(function(ch)
                if ch.Name == "OpenChest" then bind(ch) end
            end)
        end
    end)
end
hookOpenChestRewards()

-- ============================================================ WAVE DATA (maps/stages)
local MAP_KEYS = {
    "RookieIsland", "VolcanoFortress", "FrozenGlacier", "CalamityCanyon",
    "SakuraVillage", "EvercrestAcademy", "LeviathansEye", "SunsetCity",
    "AetherwellCitadel", "GildedTemple", "MeteorCrystal", "MemorysEnd",
}
-- WaveData keys with apostrophe use Leviathan's Eye etc — resolve dynamically
local function getWaveData()
    local ok2, mod = pcall(function()
        return require(ReplicatedStorage.WorldModules.WaveData)
    end)
    return ok2 and mod or nil
end
local function mapList()
    local wd = getWaveData()
    local out = {}
    if wd then
        for k, v in pairs(wd) do
            if type(v) == "table" and v.Title and not v.Hidden then
                table.insert(out, k)
            end
        end
        table.sort(out, function(a, b)
            local wa, wb = wd[a], wd[b]
            return (wa.Order or 99) < (wb.Order or 99)
        end)
    else
        out = MAP_KEYS
    end
    return out
end
local function stageCount(mapKey)
    local wd = getWaveData()
    if wd and wd[mapKey] and wd[mapKey].Stages then return #wd[mapKey].Stages end
    return 4
end
local function stageLabels(mapKey)
    local n = stageCount(mapKey)
    local t = {}
    for i = 1, n do t[i] = "Stage " .. i end
    return t
end

local function isStoryMap(data)
    if type(data) ~= "table" then return false end
    if data.Hidden or data.ChallengeWave or data.IsDungeon or data.IsNightmareDungeon then return false end
    if not data.Stages or #data.Stages == 0 then return false end
    return true
end

local function canPlayStage(mapKey, stageIdx)
    stageIdx = math.floor(tonumber(stageIdx) or 1)
    local okQ, Queue = pcall(function()
        return require(ReplicatedStorage.Systems.Queue)
    end)
    if okQ and Queue and type(Queue.CanPlayStage) == "function" then
        local ok2, res = pcall(function()
            return Queue:CanPlayStage(LP, mapKey, stageIdx)
        end)
        if ok2 then return res == true end
    end
    -- Fallback: Profile.Maps.<map> attributes (stage N unlocked if prev cleared)
    local p = getProfile()
    local maps = p and p:FindFirstChild("Maps")
    local wd = getWaveData()
    local data = wd and wd[mapKey]
    if not data or not isStoryMap(data) then return false end
    if (data.Order or 99) == 1 and stageIdx == 1 then return true end
    local prevMap, prevStage = mapKey, stageIdx - 1
    if prevStage == 0 then
        prevMap, prevStage = nil, nil
        for k, v in pairs(wd) do
            if isStoryMap(v) and v.Order == (data.Order or 99) - 1 then
                prevMap, prevStage = k, #v.Stages
                break
            end
        end
        if not prevMap then return false end
    end
    local folder = maps and maps:FindFirstChild(prevMap)
    local cleared = folder and folder:GetAttribute(prevStage)
    return type(cleared) == "number" and cleared > 0
end

-- Furthest unlocked story stage (don't restart from RookieIsland 1 if progress exists)
local function getAdaptiveStoryTarget()
    local wd = getWaveData()
    local maps = mapList()
    if #maps == 0 then maps = MAP_KEYS end
    local targetMap, targetStage = maps[1] or "RookieIsland", 1
    if not wd then return targetMap, targetStage end

    for _, mapKey in ipairs(maps) do
        local data = wd[mapKey]
        if isStoryMap(data) then
            local highest
            for i = 1, #data.Stages do
                if canPlayStage(mapKey, i) then highest = i end
            end
            if not highest then
                break
            end
            local mapsFolder = getProfile()
            mapsFolder = mapsFolder and mapsFolder:FindFirstChild("Maps")
            local mapFolder = mapsFolder and mapsFolder:FindFirstChild(mapKey)
            local lastCleared = mapFolder and mapFolder:GetAttribute(#data.Stages)
            if type(lastCleared) == "number" and lastCleared > 0 then
                -- Map fully cleared — keep as fallback, prefer next map when unlocked
                targetMap, targetStage = mapKey, #data.Stages
            else
                targetMap, targetStage = mapKey, highest
                break
            end
        end
    end
    return targetMap, targetStage
end

local function resolveStoryQueue()
    if F.storyAdaptive ~= false then
        return getAdaptiveStoryTarget()
    end
    return F.storyMap or "RookieIsland", tonumber(F.storyStage) or 1
end

-- ============================================================ UNITS
local function unitsFolder()
    return Workspace:FindFirstChild("Units")
end
local function myTeam()
    local t = LP:GetAttribute("TeamNum")
    return tonumber(t) or 1
end
local function isOwnUnit(model)
    return model and model:GetAttribute("OwnerName") == LP.Name
end
-- Story enemies always spawn as Team 2; player units Team 1 (OwnerName set)
local function isEnemyUnit(model)
    if not model or not model:IsA("Model") then return false end
    if isOwnUnit(model) then return false end
    local team = tonumber(model:GetAttribute("Team"))
    local owner = model:GetAttribute("OwnerName")
    local hasOwner = type(owner) == "string" and owner ~= ""
    if hasOwner then
        -- Other players' units: enemy only on different team (PvP)
        return team ~= nil and team ~= myTeam()
    end
    -- Mobs / bosses: Team 2, or any non-my team, or no Team but real unit body
    if team == 2 then return true end
    if team ~= nil and team ~= myTeam() then return true end
    if team == nil and (model:FindFirstChild("HumanoidRootPart") or model:FindFirstChild("Collider") or model:FindFirstChildOfClass("Humanoid")) then
        return true
    end
    return false
end
local function unitHp(model)
    local h = humOf(model)
    if h and (h.MaxHealth or 0) > 0 then
        return h.Health, h.MaxHealth
    end
    local hp = model:GetAttribute("Health") or model:GetAttribute("HP")
    local maxHp = model:GetAttribute("MaxHealth") or model:GetAttribute("MaxHP")
    if typeof(hp) == "number" then
        return hp, (typeof(maxHp) == "number" and maxHp) or hp
    end
    local hv = model:FindFirstChild("Health")
    local mv = model:FindFirstChild("MaxHealth")
    if hv and hv:IsA("NumberValue") then
        return hv.Value, (mv and mv:IsA("NumberValue") and mv.Value) or hv.Value
    end
    return nil, nil
end
local function specialReady(model)
    local t = model:GetAttribute("SpecialReadyTime")
    if type(t) ~= "number" then return false, 0 end
    local now = Workspace:GetServerTimeNow()
    local left = math.max(0, t - now)
    return left <= 0, left
end
local function isBossUnit(model)
    if not model or not model:IsA("Model") then return false end
    if not isEnemyUnit(model) then return false end
    -- Game truth only — name heuristics matched map props ("BossSpawn", rooms, etc.)
    if model:GetAttribute("IsBoss") == true then return true end
    if model:GetAttribute("IsElite") == true then return true end
    local n = model.Name
    if type(n) == "string" and n:sub(1, 5) == "Boss_" then return true end
    return false
end

-- Real units are small; map chunks under Units (or welded junk) have hundreds of parts.
-- Cache: GetDescendants every RenderStepped on every unit = PvP melt.
local unitValidCache = setmetatable({}, { __mode = "k" })
local function isValidUnitModel(model)
    if not model or not model:IsA("Model") then return false end
    local cached = unitValidCache[model]
    if cached ~= nil then return cached end
    local folder = unitsFolder()
    if not folder or model.Parent ~= folder then
        unitValidCache[model] = false
        return false
    end
    if not (model:FindFirstChild("Collider")
        or model:FindFirstChildOfClass("Humanoid")
        or model.PrimaryPart
        or model:FindFirstChild("HumanoidRootPart")) then
        unitValidCache[model] = false
        return false
    end
    local parts = 0
    for _, d in ipairs(model:GetDescendants()) do
        if d:IsA("BasePart") then
            parts = parts + 1
            if parts > 100 then
                unitValidCache[model] = false
                return false
            end
        end
    end
    unitValidCache[model] = true
    return true
end

-- ============================================================ CHESTS
local openedChests = {} -- [BasePart] = true
local chestBusy = false

local function chestPrompt(part)
    if not part then return nil end
    return part:FindFirstChildWhichIsA("ProximityPrompt", true)
        or (part.Parent and part.Parent:FindFirstChildWhichIsA("ProximityPrompt", true))
end

local function isOpenableChest(part)
    if not part or not part.Parent then return false end
    if openedChests[part] then return false end
    local prompt = chestPrompt(part)
    if not prompt or not prompt.Enabled then return false end
    -- Spawn pads left in BonusChests without a live prompt are not openable
    if not CollectionService:HasTag(part, "BonusChestPart") then return false end
    return true
end

local function chestParts()
    local out, seen = {}, {}
    for _, v in ipairs(CollectionService:GetTagged("BonusChestPart")) do
        if v:IsA("BasePart") and v:IsDescendantOf(Workspace) and not seen[v] then
            seen[v] = true
            table.insert(out, v)
        end
    end
    return out
end

local function openableChests()
    local out = {}
    for _, part in ipairs(chestParts()) do
        if isOpenableChest(part) then table.insert(out, part) end
    end
    return out
end

-- Declared here rather than beside the chest loop that reads it, because the backup
-- vote in onGameOver calls it too and that sits above the loop. A local declared
-- lower down is not in scope up there: the call read a global instead, found nil and
-- threw, so the backup Retry never fired when no chests spawned.
local function chestsRemaining()
    return #openableChests()
end


local function chestVisual(part)
    if not part then return nil end
    -- Client clones ReplicatedModels.BonusChests.Chest into Workspace at the pad.
    -- Never grab random AnimationController models (units/props lit up Endless ESP).
    local best, bestD = nil, 5
    for _, m in ipairs(Workspace:GetChildren()) do
        if m:IsA("Model") and (m.Name == "Chest" or m.Name == "BonusChest") then
            local pp = m.PrimaryPart or m:FindFirstChildWhichIsA("BasePart")
            if pp then
                local d = (pp.Position - part.Position).Magnitude
                if d < bestD then
                    bestD, best = d, m
                end
            end
        end
    end
    return best -- nil = highlight only the tagged pad, not nearby junk
end

local function firePrompt(prompt)
    if not prompt then return false end
    -- Recruit/shop prompts are HoldDuration=1; fire without zeroing often does nothing.
    pcall(function() prompt.HoldDuration = 0 end)
    pcall(function() prompt.MaxActivationDistance = math.max(prompt.MaxActivationDistance or 0, 80) end)
    if fireproximityprompt then
        pcall(fireproximityprompt, prompt)
        pcall(fireproximityprompt, prompt, 0)
        return true
    end
    pcall(function()
        prompt:InputHoldBegin()
        task.wait(0.05)
        prompt:InputHoldEnd()
    end)
    return true
end

local function openChestAt(part)
    if not part or openedChests[part] then return false end
    local prompt = chestPrompt(part)
    if not prompt or not prompt.Enabled then
        openedChests[part] = true
        return false
    end
    pcall(function() prompt.HoldDuration = 0 end)
    pcall(function() prompt.MaxActivationDistance = 200 end)
    for _ = 1, 3 do
        firePrompt(prompt)
        task.wait(0.12)
        if not prompt.Parent or not prompt.Enabled then
            openedChests[part] = true
            return true
        end
    end
    task.wait(0.2)
    if not prompt.Parent or not prompt.Enabled then
        openedChests[part] = true
        return true
    end
    return false
end

local function tpTo(pos)
    local r = hrp()
    if not r then return end
    local c = char()
    if c and c.PrimaryPart then
        pcall(function() c:PivotTo(CFrame.new(pos + Vector3.new(0, 4, 0))) end)
    else
        r.CFrame = CFrame.new(pos + Vector3.new(0, 4, 0))
    end
end

-- ============================================================ QUEUE / AFK / VOTE / READY
-- Server rejects RequestEnterQueue if farther than 20 studs from pad.Door.
-- modes: nil/"Waves"/"Story" | "Tower" | table of allowed Gamemode strings
local function findQueuePad(modes)
    local allow
    if type(modes) == "string" then
        allow = { [modes] = true }
    elseif type(modes) == "table" then
        allow = {}
        for _, m in ipairs(modes) do allow[m] = true end
    else
        allow = { Waves = true, Story = true, [""] = true }
    end
    local function modeOk(gm)
        if gm == nil then return allow.Waves or allow.Story or allow[""] end
        return allow[gm] == true
    end
    local empty, mine, any
    for _, v in ipairs(CollectionService:GetTagged("LobbyQueue")) do
        if v:IsDescendantOf(Workspace) and not v:GetAttribute("Locked") then
            if modeOk(v:GetAttribute("Gamemode")) and v:FindFirstChild("Door") then
                local owner = v:GetAttribute("OwnerName")
                if owner == nil then
                    empty = empty or v
                elseif owner == LP.Name then
                    mine = mine or v
                else
                    any = any or v
                end
            end
        end
    end
    if mine or empty then return mine or empty end
    -- Tower pads may not always carry LobbyQueue tag in every build — scan Functionality
    if allow.Tower then
        local func = Workspace:FindFirstChild("LobbyMap") and Workspace.LobbyMap:FindFirstChild("Functionality")
        if func then
            for _, m in ipairs(func:GetChildren()) do
                if m:IsA("Model") and m:GetAttribute("Gamemode") == "Tower" and not m:GetAttribute("Locked") and m:FindFirstChild("Door") then
                    local owner = m:GetAttribute("OwnerName")
                    if owner == nil or owner == LP.Name then return m end
                    any = any or m
                end
            end
        end
    end
    if any then return any end
    return nil
end

local function queueDoor(pad)
    if not pad then return nil end
    local door = pad:FindFirstChild("Door")
    if door and door:IsA("BasePart") then return door end
    return nil
end

local function tpNearQueue(pad)
    local door = queueDoor(pad)
    if not door then return false end
    -- EnterQueue requires Magnitude(HRP, Door) <= 20
    local stand = door.Position + door.CFrame.LookVector * -6 + Vector3.new(0, 2, 0)
    tpTo(stand)
    return true
end

local function setStoryQueue(mapKey, stageIdx)
    stageIdx = math.max(1, math.floor(tonumber(stageIdx) or 1))
    local pad = findQueuePad()
    if not pad then return false, "no empty Waves queue pad" end

    -- Already owner: just configure + launch
    if pad:GetAttribute("OwnerName") == LP.Name then
        fire("SetQueue", pad, mapKey, stageIdx)
        task.wait(0.4)
        if F.autoQueueLaunch ~= false then
            fire("LaunchQueue", pad)
        end
        return true
    end

    -- Drop previous queue membership so we can claim an empty pad
    fire("LeaveQueue")
    task.wait(0.25)

    if not tpNearQueue(pad) then
        return false, "queue has no Door"
    end
    task.wait(0.5)

    local okEnter, isOwner, errMsg = invoke("RequestEnterQueue", pad)
    if not okEnter then
        -- one more attempt closer
        tpNearQueue(pad)
        task.wait(0.35)
        okEnter, isOwner, errMsg = invoke("RequestEnterQueue", pad)
    end
    if not okEnter then
        return false, tostring(errMsg or "enter failed (need to be near pad)")
    end
    task.wait(0.45)

    if pad:GetAttribute("OwnerName") ~= LP.Name then
        return false, "not queue owner (pad taken?)"
    end

    fire("SetQueue", pad, mapKey, stageIdx)
    task.wait(0.45)
    if F.autoQueueLaunch ~= false then
        fire("LaunchQueue", pad)
    end
    return true
end

local function getEndlessEntries()
    local p = getProfile()
    local q = p and p:FindFirstChild("Quests")
    local v = q and q:FindFirstChild("EndlessModeEntries")
    if v then return tonumber(v.Value) or 0 end
    local ok, n = pcall(function()
        return require(ReplicatedStorage.Systems.Challenges):GetChallengeWaveEntries(LP, "NightmareCircus", tonumber(F.endlessStage) or 1)
    end)
    return ok and tonumber(n) or 0
end

local function queueTower()
    if not isLobby() then return false, "not lobby" end
    local pad = findQueuePad("Tower")
    if not pad then return false, "no Tower pad (InfTowerPad)" end
    if pad:GetAttribute("OwnerName") == LP.Name then
        fire("SetQueue", pad, "Tower", tonumber(F.towerDifficulty) or 1)
        task.wait(0.35)
        if F.autoQueueLaunch ~= false then fire("LaunchQueue", pad) end
        return true
    end
    fire("LeaveQueue")
    task.wait(0.2)
    if not tpNearQueue(pad) then return false, "no Door" end
    task.wait(0.4)
    local okEnter, _, errMsg = invoke("RequestEnterQueue", pad)
    if not okEnter then
        tpNearQueue(pad)
        task.wait(0.3)
        okEnter, _, errMsg = invoke("RequestEnterQueue", pad)
    end
    if not okEnter then return false, tostring(errMsg or "enter failed") end
    task.wait(0.35)
    fire("SetQueue", pad, "Tower", tonumber(F.towerDifficulty) or 1)
    task.wait(0.35)
    if F.autoQueueLaunch ~= false then fire("LaunchQueue", pad) end
    -- Also poke official StartRound (lobby → match)
    pcall(function() require(ReplicatedStorage.Systems.TowerWaves):StartRound(LP) end)
    fire("Tower_StartRound")
    return true
end

local function queueEndlessCircus()
    if not isLobby() then return false, "not lobby" end
    local entries = getEndlessEntries()
    if entries <= 0 and F.endlessRespectEntries ~= false then
        return false, "no Endless entries left"
    end
    local stage = math.max(1, math.floor(tonumber(F.endlessStage) or 1))
    -- Open ring / menu if present, then fire Challenges_StartRound
    local ring = Workspace:FindFirstChild("LobbyMap") and Workspace.LobbyMap:FindFirstChild("EndlessModeRing")
    local touch = ring and (ring:FindFirstChild("Touch") or ring:FindFirstChildWhichIsA("BasePart"))
    if touch then tpTo(touch.Position) task.wait(0.35) end
    pcall(function()
        require(ReplicatedStorage.Systems.Challenges):StartRound(LP, "NightmareCircus", stage)
    end)
    fire("Challenges_StartRound", "NightmareCircus", stage)
    -- UI fallback: Start button on EndlessWaveMenu
    pcall(function()
        if not getconnections then return end
        local pg = LP:FindFirstChild("PlayerGui")
        local menu = pg and pg:FindFirstChild("EndlessWaveMenu")
        if not menu or not menu.Enabled then return end
        for _, d in ipairs(menu:GetDescendants()) do
            if d:IsA("GuiButton") and d.Name == "StartButton" then
                for _, conn in ipairs(getconnections(d.MouseButton1Click)) do
                    pcall(function() if conn.Fire then conn:Fire() elseif conn.Function then conn.Function() end end)
                end
            end
        end
    end)
    return true
end

-- ============================================================ ENDLESS TOWER BOT (Infinite Tower rooms)
-- Do not require() on the boot thread — ModuleScript yield kills win:tab (empty NewReality).
local UNIT_DATA
local function loadUnitData()
    if type(UNIT_DATA) == "table" then return UNIT_DATA end
    pcall(function()
        local wm = ReplicatedStorage:FindFirstChild("WorldModules")
        local folder = wm and wm:FindFirstChild("ItemData")
        local mod = folder and folder:FindFirstChild("Units")
        if mod then UNIT_DATA = require(mod) end
    end)
    return UNIT_DATA
end

local ROOM_ALIASES = {
    Elite = "Elite", Chest = "Chest", Healing = "Healing", Heal = "Healing",
    Mystery = "Mystery", ["?"] = "Mystery", Recruit = "Recruit", Combat = "Combat",
    Boss = "Elite", Merchant = "Merchant", Skip = "Skip",
}

local DOOR_ORDER_KEYS = { "Elite", "Chest", "Healing", "Mystery", "Recruit", "Combat", "Merchant" }
local DOOR_ORDER_LABEL = {
    Elite = "Elite / Boss",
    Chest = "Chest",
    Healing = "Healing",
    Mystery = "Mystery (2x XP)",
    Recruit = "Recruit",
    Combat = "Combat",
    Merchant = "Merchant shop",
}
local DOOR_LABEL_TO_KEY = {}
for k, v in pairs(DOOR_ORDER_LABEL) do DOOR_LABEL_TO_KEY[v] = k end
local DOOR_ORDER_OPTIONS = {}
for _, k in ipairs(DOOR_ORDER_KEYS) do DOOR_ORDER_OPTIONS[#DOOR_ORDER_OPTIONS + 1] = DOOR_ORDER_LABEL[k] end

local function normalizeRoomType(text, xpText)
    text = tostring(text or "")
    if ROOM_ALIASES[text] then return ROOM_ALIASES[text] end
    if text == "" and xpText and tostring(xpText):find("2x", 1, true) then return "Mystery" end
    local lower = text:lower()
    if lower:find("elite") or lower:find("boss") then return "Elite" end
    if lower:find("chest") then return "Chest" end
    if lower:find("heal") then return "Healing" end
    if lower:find("recruit") or lower:find("unit") then return "Recruit" end
    if lower:find("merchant") or lower:find("shop") then return "Merchant" end
    if lower:find("combat") or lower:find("battle") then return "Combat" end
    if lower:find("skip") then return "Skip" end
    if text == "?" then return "Mystery" end
    return text ~= "" and text or "Combat"
end

local function doorOrderValid(o, n)
    if type(o) ~= "table" or #o ~= n then return false end
    local seen = {}
    for _, k in ipairs(o) do
        if type(k) ~= "string" or not DOOR_ORDER_LABEL[k] or seen[k] then return false end
        seen[k] = true
    end
    return true
end

local function getDoorOrder()
    local o = F.towerDoorOrder
    if doorOrderValid(o, 7) then return o end
    if doorOrderValid(o, 6) then
        local new = table.clone(o)
        local at = #new + 1
        for i, k in ipairs(new) do
            if k == "Chest" then
                at = i + 1
                break
            end
        end
        table.insert(new, at, "Merchant")
        F.towerDoorOrder = new
        return new
    end
    local order = { "Elite", "Chest", "Merchant", "Healing", "Mystery", "Recruit", "Combat" }
    F.towerDoorOrder = order
    return order
end

local function setDoorOrderSlot(slot, key)
    if not DOOR_ORDER_LABEL[key] then return end
    local order = table.clone(getDoorOrder())
    local cur = order[slot]
    if cur == key then return end
    for i, k in ipairs(order) do
        if k == key then
            order[i] = cur
            break
        end
    end
    order[slot] = key
    F.towerDoorOrder = order
    win:markDirty()
end

local function roomPriority(roomType)
    if roomType == "Merchant" and F.towerEnterMerchant == false then return 999 end
    -- Skip door: jumps floor to ~your usual tower level −10. Toggle = always take it.
    if roomType == "Skip" then
        if F.towerPreferSkip ~= false then return -1 end
        return 80
    end
    local order = getDoorOrder()
    for i, k in ipairs(order) do
        if k == roomType then return i end
    end
    return 50
end

-- Prefer lit ExitDoors (Ring beams). Later themes sometimes have no beams — then Screen+Touch is enough.
local function isSelectableTowerDoor(model, relaxLit)
    if not (model and model:IsA("Model") and model.Name == "ExitDoor" and model.Parent) then
        return false
    end
    local touch = model:FindFirstChild("Touch")
    local screen = model:FindFirstChild("Screen")
    if not (touch and touch:IsA("BasePart") and screen) then return false end
    local ring = model:FindFirstChild("Ring")
    if ring and ring:IsA("BasePart") and ring.Transparency >= 0.95 and not relaxLit then
        return false
    end
    if ring and not relaxLit then
        local lit = false
        for _, d in ipairs(ring:GetDescendants()) do
            if (d:IsA("Beam") or d:IsA("ParticleEmitter")) and d.Enabled then
                lit = true
                break
            end
        end
        if not lit then return false end
    end
    local gui = screen:FindFirstChildWhichIsA("SurfaceGui") or screen:FindFirstChild("SurfaceGui")
    local nameLabel = gui and (gui:FindFirstChild("RoomName") or gui:FindFirstChild("RoomName", true))
    return nameLabel and nameLabel:IsA("TextLabel")
end

-- Never Workspace:GetDescendants — by floor ~200 the map has every past room and that hitch freezes the bot.
local function findTowerDoors(relaxLit)
    local doors = {}
    local map = Workspace:FindFirstChild("Map")
    if not map then return doors end
    local info = ReplicatedStorage:FindFirstChild("TowerWaveInfo")
    local floor = info and info:GetAttribute("CurrentRoomNum")
    local rooms = {}
    if floor ~= nil then
        local named = map:FindFirstChild(tostring(floor))
        if named then rooms[#rooms + 1] = named end
    end
    if #rooms == 0 then
        for _, ch in ipairs(map:GetChildren()) do
            rooms[#rooms + 1] = ch
        end
    end
    local function consider(d)
        if not isSelectableTowerDoor(d, relaxLit) then return end
        local screen = d.Screen
        local gui = screen:FindFirstChildWhichIsA("SurfaceGui") or screen:FindFirstChild("SurfaceGui")
        local nameLabel = gui:FindFirstChild("RoomName") or gui:FindFirstChild("RoomName", true)
        local xpLabel = gui:FindFirstChild("RoomXP") or gui:FindFirstChild("RoomXP", true)
        local rt = normalizeRoomType(nameLabel.Text, xpLabel and xpLabel.Text)
        doors[#doors + 1] = { model = d, touch = d.Touch, roomType = rt, label = nameLabel.Text }
    end
    for _, room in ipairs(rooms) do
        if room.Name == "ExitDoor" then
            consider(room)
        else
            for _, ch in ipairs(room:GetChildren()) do
                if ch.Name == "ExitDoor" then consider(ch) end
            end
        end
    end
    return doors
end

local function pickBestDoor(doors)
    if F.towerPreferSkip ~= false then
        for _, door in ipairs(doors) do
            if door.roomType == "Skip" then return door end
        end
    end
    local best, bestScore
    for _, door in ipairs(doors) do
        if door.roomType == "Merchant" and F.towerEnterMerchant == false then continue end
        if door.roomType == "Skip" and F.towerPreferSkip == false then continue end
        local score = roomPriority(door.roomType)
        if not best or score < bestScore then
            best, bestScore = door, score
        end
    end
    return best
end

local function unitRangedScore(unitId)
    local data = UNIT_DATA and UNIT_DATA[unitId]
    if not data then return 0 end
    return tonumber(data.AttackRange) or 0
end

local function unitRarityScore(unitId)
    local data = UNIT_DATA and UNIT_DATA[unitId]
    if data and tonumber(data.Rarity) then return tonumber(data.Rarity) end
    return 0
end

local function pickRecruitPrompt()
    if type(UNIT_DATA) ~= "table" then loadUnitData() end
    local mode = tostring(F.towerRecruitMode or "Rarity")
    local best, bestScore, bestPrompt
    local function consider(prompt)
        if not (prompt and prompt:IsA("ProximityPrompt") and prompt.Enabled) then return end
        local action = tostring(prompt.ActionText or "")
        if action ~= "Recruit" then return end
        local unitId = prompt.ObjectText
        local id = unitId
        if UNIT_DATA then
            for k, v in pairs(UNIT_DATA) do
                if v.DisplayName == unitId or k == unitId then id = k break end
            end
        end
        local score
        if mode == "Ranged" then
            score = unitRangedScore(id) * 10 + unitRarityScore(id)
        else
            score = unitRarityScore(id) * 100 + unitRangedScore(id)
        end
        if not best or score > bestScore then
            best, bestScore, bestPrompt = id, score, prompt
        end
    end
    local folder = unitsFolder()
    if folder then
        for _, m in ipairs(folder:GetChildren()) do
            for _, d in ipairs(m:GetDescendants()) do
                if d:IsA("ProximityPrompt") then consider(d) end
            end
        end
    end
    if bestPrompt then return bestPrompt end
    local map = Workspace:FindFirstChild("Map")
    local info = ReplicatedStorage:FindFirstChild("TowerWaveInfo")
    local floor = info and info:GetAttribute("CurrentRoomNum")
    local room = map and floor ~= nil and map:FindFirstChild(tostring(floor))
    if room then
        for _, d in ipairs(room:GetDescendants()) do
            if d:IsA("ProximityPrompt") then consider(d) end
        end
    end
    return bestPrompt
end

local function shopGuiFromPrompt(prompt)
    local inst = prompt
    for _ = 1, 14 do
        if not inst then break end
        local gui = inst:FindFirstChild("Gui", true)
        if gui and (gui:FindFirstChild("Primary") or gui:FindFirstChild("RarityLabel")) then
            return gui
        end
        inst = inst.Parent
    end
    return nil
end

local function shopOptionScore(desc, rarity)
    desc = tostring(desc or ""):lower()
    if desc == "" then return nil end
    local isHeal = desc:find("heal", 1, true) ~= nil and desc:find("unit", 1, true) ~= nil
        or desc:find("heal ", 1, true) ~= nil
        or desc:find("of each unit", 1, true) ~= nil
    local isRevive = desc:find("revive", 1, true) ~= nil or desc:find("respawn", 1, true) ~= nil
    if isHeal and F.towerSkipShopHeal ~= false then return nil end
    if isRevive and F.towerSkipShopRevive ~= false then return nil end
    local combat = 0
    local cfg
    pcall(function() cfg = require(ReplicatedStorage.WorldModules.TowerConfig) end)
    local opt
    if cfg and cfg.ShopOptions then
        for _, v in pairs(cfg.ShopOptions) do
            if type(v) == "table" and tostring(v.Desc or ""):lower() == desc then
                opt = v
                break
            end
        end
    end
    rarity = tonumber(rarity) or (opt and tonumber(opt.Rarity)) or 1
    local sc = opt and opt.StatChange
    if sc then
        combat = (sc.Attack or 0) * 100
            + (sc.AtkSpd or 0) * 80
            + (sc.CritRate or 0) * 90
            + (sc.CritDmg or 0) * 70
            + (sc.BossAttack or 0) * 90
            + (sc.EliteAttack or 0) * 90
            + (sc.Speed or 0) * 40
            + (sc.Health or 0) * 25
            + (sc.Evasion or 0) * 20
    else
        if desc:find("atk spd", 1, true) then combat = combat + 80
        elseif desc:find("atk to elite", 1, true) or desc:find("bosses", 1, true) then combat = combat + 90
        elseif desc:find("atk", 1, true) then combat = combat + 100
        end
        if desc:find("crit", 1, true) then combat = combat + 80 end
        if desc:find("spd boost", 1, true) then combat = combat + 40 end
        if desc:find("hp boost", 1, true) then combat = combat + 25 end
    end
    local prefer = tostring(F.towerShopPrefer or "Combat")
    if prefer == "Rarity" then
        return rarity * 10000 + combat
    end
    return combat * 100 + rarity * 10
end

local function pickMerchantBuy()
    local coins = tonumber(getCurrency("Coins")) or 0
    local keep = tonumber(F.towerShopMinCoins) or 0
    local map = Workspace:FindFirstChild("Map")
    local info = ReplicatedStorage:FindFirstChild("TowerWaveInfo")
    local floor = info and info:GetAttribute("CurrentRoomNum")
    local room = map and floor ~= nil and map:FindFirstChild(tostring(floor))
    if not room then return nil end
    local bestPrompt, bestPart, bestScore
    for _, d in ipairs(room:GetDescendants()) do
        if not (d:IsA("ProximityPrompt") and d.Enabled and d.ActionText == "Buy") then continue end
        local gui = shopGuiFromPrompt(d)
        local desc = gui and gui:FindFirstChild("Primary") and gui.Primary.Text
        local rarityTxt = gui and gui:FindFirstChild("RarityLabel") and gui.RarityLabel.Text
        local rarity
        do
            local t = tostring(rarityTxt or ""):lower()
            if t:find("secret", 1, true) or t:find("mythic", 1, true) then rarity = 6
            elseif t:find("legendary", 1, true) then rarity = 5
            elseif t:find("epic", 1, true) then rarity = 4
            elseif t:find("rare", 1, true) then rarity = 3
            elseif t:find("uncommon", 1, true) then rarity = 2
            elseif t:find("common", 1, true) then rarity = 1
            end
        end
        local price = 0
        local priceGui = gui and gui:FindFirstChild("Price")
        local priceLabel = priceGui and (priceGui:FindFirstChild("Label") or priceGui:FindFirstChildWhichIsA("TextLabel", true))
        if priceLabel and priceLabel:IsA("TextLabel") then
            price = tonumber((tostring(priceLabel.Text):gsub(",", ""):gsub("%s", ""))) or 0
        end
        if price <= 0 then
            local prices = { [1] = 100, [3] = 250, [4] = 500, [5] = 1000, [6] = 5000 }
            price = prices[rarity or 0] or 0
        end
        if price > 0 and coins - price < keep then continue end
        local score = shopOptionScore(desc, rarity)
        if not score then continue end
        if not bestPrompt or score > bestScore then
            local part = d.Parent
            if part and part:IsA("Attachment") then part = part.Parent end
            if part and part:IsA("BasePart") then
                bestPrompt, bestPart, bestScore = d, part, score
            end
        end
    end
    return bestPrompt, bestPart
end

local function safeTp(pos)
    if typeof(pos) ~= "Vector3" then return false end
    if pos.X ~= pos.X or pos.Y ~= pos.Y or pos.Z ~= pos.Z then return false end
    if math.abs(pos.X) > 50000 or math.abs(pos.Z) > 50000 then return false end
    if pos.Y < -200 or pos.Y > 2000 then return false end
    tpTo(pos)
    return true
end

-- Retry every tick while the phase is open. One-shot TP missed thin doors / HoldDuration=1 prompts.
local towerBot = {
    lastDoorTp = 0,
    lastRecruitFire = 0,
    lastShopFire = 0,
}

local function towerBotTick()
    if not F.towerBot then
        towerBot.lastDoorTp, towerBot.lastRecruitFire, towerBot.lastShopFire = 0, 0, 0
        return
    end
    if isLobby() or isPvpWorld() then return end
    local info = ReplicatedStorage:FindFirstChild("TowerWaveInfo")
    if not info then return end

    local choosing = info:GetAttribute("RoomChoice") == true
    local recruitLeft = tonumber(info:GetAttribute("RecruitTimer")) or 0
    local shopLeft = tonumber(info:GetAttribute("PurchaseTimer")) or 0

    local function standOn(part)
        if not (part and part:IsA("BasePart") and part.Parent) then return false end
        if not safeTp(part.Position) then return false end
        local r = hrp()
        if r and firetouchinterest then
            pcall(firetouchinterest, part, r, 1)
            pcall(firetouchinterest, r, part, 1)
            task.defer(function()
                pcall(firetouchinterest, part, r, 0)
                pcall(firetouchinterest, r, part, 0)
            end)
        end
        return true
    end

    if choosing then
        local best = pickBestDoor(findTowerDoors(false))
        if not (best and best.touch and best.touch.Parent) then
            best = pickBestDoor(findTowerDoors(true))
        end
        if not (best and best.touch and best.touch.Parent) then return end
        if tick() - towerBot.lastDoorTp < 0.2 then return end
        towerBot.lastDoorTp = tick()
        standOn(best.touch)
        return
    end

    if recruitLeft > 0 then
        local prompt = pickRecruitPrompt()
        if not prompt then return end
        local part = prompt.Parent
        if part and part:IsA("Attachment") then part = part.Parent end
        if not (part and part:IsA("BasePart")) then return end
        if tick() - towerBot.lastRecruitFire < 0.25 then return end
        towerBot.lastRecruitFire = tick()
        standOn(part)
        firePrompt(prompt)
        return
    end

    if shopLeft > 0 and F.towerEnterMerchant ~= false then
        local prompt, part = pickMerchantBuy()
        if not (prompt and part) then return end
        if tick() - towerBot.lastShopFire < 0.25 then return end
        towerBot.lastShopFire = tick()
        standOn(part)
        firePrompt(prompt)
    end
end

local function doReady()
    if isLobby() then return end
    if LP:GetAttribute("Ready") == true then return end
    pcall(function() require(ReplicatedStorage.Systems.Waves):Ready(LP) end)
    pcall(function() require(ReplicatedStorage.Systems.EndlessWaves):Ready(LP) end)
    pcall(function() require(ReplicatedStorage.Systems.AFKWaves):Ready(LP) end)
    fire("Waves_Ready")
    fire("EndlessWaves_Ready")
    fire("AFKWaves_Ready")
    -- Tower has no in-match Ready remote; StartRound is lobby-only. Keep UI ready clicks.
    pcall(function()
        if not getconnections then return end
        local pg = LP:FindFirstChild("PlayerGui")
        if not pg then return end
        for _, d in ipairs(pg:GetDescendants()) do
            if d:IsA("GuiButton") and d.Visible and d.Name:lower():find("ready") then
                for _, conn in ipairs(getconnections(d.MouseButton1Click)) do
                    pcall(function() if conn.Fire then conn:Fire() elseif conn.Function then conn.Function() end end)
                end
            end
        end
    end)
end

-- Declared early: used by isRoundEndOpen + vote loops
local pendingVote = nil
local lastVictory = nil
local gameOverAt = 0
local chestFarmPhase = "idle" -- idle | collecting | need_loot_then_retry | waiting_vote
local lastChestFarmVoteAt = 0
local votedThisEnd = false
local sawChestsThisMatch = false
local chestsLootedThisMatch = 0

local function isGuiTrulyVisible(inst)
    local n = inst
    while n and n ~= LP do
        if n:IsA("LayerCollector") and not n.Enabled then return false end
        if n:IsA("GuiObject") and (not n.Visible or n.AbsoluteSize.X <= 0) then return false end
        n = n.Parent
    end
    return true
end

local function doVote(kind)
    if not kind or kind == "None" then return false end
    local okRemote = fire("Vote", kind)
    pcall(function()
        require(ReplicatedStorage.Systems.Voting):Vote(LP, kind)
    end)
    -- Fallback: click RoundEnd buttons (Retry Stage / Lobby / Next)
    pcall(function()
        local pg = LP:FindFirstChild("PlayerGui")
        if not pg then return end
        local want = ({
            Retry = { "RestartButton", "RetryButton" },
            Next = { "NextStageButton", "NextButton" },
            Lobby = { "LobbyButton", "BackButton" },
        })[kind]
        if not want then return end
        for _, gui in ipairs(pg:GetChildren()) do
            if not gui:IsA("ScreenGui") then continue end
            for _, name in ipairs(want) do
                local btn = gui:FindFirstChild(name, true)
                if not (btn and btn:IsA("GuiButton")) then continue end
                if not btn.Visible or btn.AbsoluteSize.X <= 0 then continue end
                if getconnections then
                    for _, conn in ipairs(getconnections(btn.MouseButton1Click)) do
                        pcall(function()
                            if conn.Fire then conn:Fire()
                            elseif conn.Function then conn.Function()
                            end
                        end)
                    end
                end
                pcall(function()
                    if firesignal then firesignal(btn.MouseButton1Click) end
                end)
                pcall(function() btn:Activate() end)
                pcall(function()
                    local vim = game:GetService("VirtualInputManager")
                    local abs = btn.AbsolutePosition
                    local sz = btn.AbsoluteSize
                    local x, y = abs.X + sz.X * 0.5, abs.Y + sz.Y * 0.5
                    vim:SendMouseButtonEvent(x, y, 0, true, game, 1)
                    task.wait()
                    vim:SendMouseButtonEvent(x, y, 0, false, game, 1)
                end)
                return
            end
        end
    end)
    return okRemote == true or ReplicatedStorage:GetAttribute("RoundEndType") == kind
end

local function isRoundEndGuiVisible()
    local pg = LP:FindFirstChild("PlayerGui")
    if not pg then return false end
    for _, gui in ipairs(pg:GetChildren()) do
        if gui:IsA("ScreenGui") and gui.Enabled then
            local n = gui.Name:lower()
            if n:find("roundend") or n:find("afkend") or n:find("endlessend") or n:find("towerend") then
                return true
            end
            local restart = gui:FindFirstChild("RestartButton", true)
            local nextBtn = gui:FindFirstChild("NextStageButton", true)
            local lobby = gui:FindFirstChild("LobbyButton", true)
            if (restart and isGuiTrulyVisible(restart))
                or (nextBtn and isGuiTrulyVisible(nextBtn))
                or (lobby and isGuiTrulyVisible(lobby)) then
                return true
            end
        end
    end
    return false
end

local function isRoundEndOpen()
    -- GUI / active countdown only. RoundEndType alone can linger after a vote and
    -- permanently block Ready (Endless Retry teleports slowly / can stall).
    if isRoundEndGuiVisible() then return true end
    local timer = ReplicatedStorage:GetAttribute("RoundEndTimer")
    return type(timer) == "number" and timer > 0
end

local function endlessRetryAvailable()
    -- In-game Endless end screen only shows Restart when entries remain.
    local pg = LP:FindFirstChild("PlayerGui")
    if pg then
        for _, gui in ipairs(pg:GetChildren()) do
            if gui:IsA("ScreenGui") and gui.Enabled then
                local n = gui.Name:lower()
                local endlessUi = n:find("endless") or n:find("roundend")
                local restart = gui:FindFirstChild("RestartButton", true)
                if endlessUi and restart and isGuiTrulyVisible(restart) then
                    return true
                end
            end
        end
    end
    return getEndlessEntries() > 0
end

local function clearVoteState(reason)
    pendingVote = nil
    votedThisEnd = false
    gameOverAt = 0
end

local function forceVote(kind)
    if not kind or kind == "None" then return false end
    pcall(function()
        updateFarmStats()
        flushFarmDisk()
    end)
    pendingVote = kind
    doVote(kind)
    return ReplicatedStorage:GetAttribute("RoundEndType") == kind
end

local function clickScreenSkip()
    -- Mouse/touch click — NOT Space (Space makes the character jump)
    pcall(function()
        local vim = game:GetService("VirtualInputManager")
        local vp = (Camera and Camera.ViewportSize) or Vector2.new(960, 540)
        local x, y = vp.X * 0.5, vp.Y * 0.55
        vim:SendMouseButtonEvent(x, y, 0, true, game, 1)
        task.wait()
        vim:SendMouseButtonEvent(x, y, 0, false, game, 1)
    end)
    pcall(function()
        if not getconnections then return end
        local fake = {
            KeyCode = Enum.KeyCode.Unknown,
            UserInputType = Enum.UserInputType.MouseButton1,
            UserInputState = Enum.UserInputState.Begin,
        }
        for _, conn in ipairs(getconnections(UserInputService.InputBegan)) do
            pcall(function()
                if conn.Fire then conn:Fire(fake, false)
                elseif conn.Function then conn.Function(fake, false)
                end
            end)
        end
        if UserInputService.TouchTap then
            for _, conn in ipairs(getconnections(UserInputService.TouchTap)) do
                pcall(function()
                    if conn.Fire then conn:Fire({ Vector2.new(0.5, 0.5) }, false)
                    elseif conn.Function then conn.Function({ Vector2.new(0.5, 0.5) }, false)
                    end
                end)
            end
        end
    end)
end

local function isCutsceneActive()
    local ok = false
    pcall(function()
        local Cutscenes = require(ReplicatedStorage.Systems.Cutscenes)
        if Cutscenes.IsInCutscene and Cutscenes:IsInCutscene() then ok = true end
    end)
    if ok then return true end
    local pg = LP:FindFirstChild("PlayerGui")
    if not pg then return false end
    for _, g in ipairs(pg:GetChildren()) do
        if g:IsA("ScreenGui") and g.Enabled then
            local n = g.Name:lower()
            if n:find("cutscene") then return true end
        end
    end
    return false
end

local function isTauntDialogOpen()
    local open = false
    pcall(function()
        local Gui = require(ReplicatedStorage.Systems.Gui)
        local t = Gui:Get("Taunt")
        if t and t.IsOpen and t:IsOpen() then open = true end
    end)
    if open then return true end
    local pg = LP:FindFirstChild("PlayerGui")
    if not pg then return false end
    for _, g in ipairs(pg:GetChildren()) do
        if g:IsA("ScreenGui") and g.Enabled then
            local n = g.Name:lower()
            if n == "taunt" or n:find("taunt") then return true end
        end
    end
    return false
end

local function skipCutscenes()
    local cut = isCutsceneActive()
    local dialog = isTauntDialogOpen()
    if not cut and not dialog then return end
    if cut then
        fire("Cutscene_Skipped")
    end
    clickScreenSkip()
end

-- Gear machine: skip LobbyMap gauge anim (GearSummonNew no-ops if gauge missing).
local gearSummonHooked = false
local function hookFastGearSummon()
    if gearSummonHooked then return true end
    local Gui
    local ok = pcall(function()
        Gui = require(ReplicatedStorage.Systems.Gui)
    end)
    if not ok or type(Gui) ~= "table" or type(Gui.Get) ~= "function" then return false end
    local seq = Gui:Get("GearSummonSequence")
    if type(seq) ~= "table" or type(seq.Open) ~= "function" then return false end
    gearSummonHooked = true
    local oldOpen = seq.Open
    seq.Open = function(self, items, rarity)
        if F.fastGearSummon == false then
            return oldOpen(self, items, rarity)
        end
        local gauge, gParent, gName
        pcall(function()
            local lobby = Workspace:FindFirstChild("LobbyMap")
            gauge = lobby and lobby:FindFirstChild("GearSummonGauge")
            if gauge then
                gParent = gauge.Parent
                gName = gauge.Name
                gauge.Parent = nil
            end
        end)
        local okOpen, a, b, c, d = pcall(oldOpen, self, items, rarity)
        pcall(function()
            if gauge and gParent then
                gauge.Name = gName or "GearSummonGauge"
                gauge.Parent = gParent
            end
        end)
        if F.fastGearRewards == true then
            task.defer(function()
                pcall(function()
                    local rew = Gui:Get("RewardsObtained")
                    if not (rew and rew.IsOpen and rew:IsOpen()) then return end
                    task.wait(0.12)
                    if rew.IsOpen and rew:IsOpen() and rew.Close then
                        rew:Close()
                    end
                end)
            end)
        end
        if not okOpen then
            warn("[SH] fast gear Open", a)
            return
        end
        return a, b, c, d
    end
    return true
end
-- Defer: require(Gui) yields. Immediate call here used to blank the window.
task.defer(function()
    for _ = 1, 20 do
        if hookFastGearSummon() then break end
        task.wait(0.5)
    end
end)

local function chestDisplayName(part)
    if not part then return "Chest" end
    local prompt = chestPrompt(part)
    if prompt then
        local ot = prompt.ObjectText
        if type(ot) == "string" and ot ~= "" then return ot end
        local at = prompt.ActionText
        if type(at) == "string" and at ~= "" and at:lower() ~= "open" then return at end
    end
    local vis = chestVisual(part)
    if typeof(vis) == "Instance" then
        local n = vis.Name
        if type(n) == "string" and n ~= "" and n ~= "Chest" and n ~= "Model" then
            return n
        end
    end
    local n = part.Name
    if type(n) == "string" and n ~= "" and n ~= "Part" and n ~= "Handle" then
        return n
    end
    local parent = part.Parent
    if parent and parent.Name ~= "BonusChests" and parent.Name ~= "Workspace" then
        return parent.Name
    end
    return "Bonus Chest"
end

-- ============================================================ ESP DRAWING
local drawings = {} -- key -> {box, name, tracer, hl}
local function destroyDraw(d)
    if not d then return end
    for _, x in pairs(d) do
        if typeof(x) == "Instance" then x:Destroy()
        elseif type(x) == "userdata" and x.Remove then pcall(function() x:Remove() end)
        elseif type(x) == "table" and x.Destroy then pcall(function() x:Destroy() end)
        end
    end
end
local function makeLabel()
    if not (espGui and espGui.Parent) then pcall(ensureEspHud) end
    if not espGui then return nil end
    local f = Instance.new("Frame")
    f.BackgroundTransparency = 1
    f.AutomaticSize = Enum.AutomaticSize.XY
    f.Size = UDim2.fromOffset(0, 0)
    f.AnchorPoint = Vector2.new(0.5, 1)
    f.Parent = espGui
    local t = Instance.new("TextLabel")
    t.BackgroundTransparency = 1
    t.AutomaticSize = Enum.AutomaticSize.XY
    t.Size = UDim2.fromOffset(0, 0)
    t.Font = Enum.Font.GothamBold
    t.TextSize = 14
    t.TextStrokeTransparency = 0.3
    t.TextStrokeColor3 = Color3.new(0, 0, 0)
    t.TextColor3 = Color3.new(1, 1, 1)
    t.TextXAlignment = Enum.TextXAlignment.Center
    t.TextYAlignment = Enum.TextYAlignment.Bottom
    t.Text = ""
    t.Parent = f
    return { frame = f, text = t }
end
local function ensureHl(model, fill, outline)
    -- Keep Highlight OFF the unit model (parenting into Units can break selection / anims)
    if not model then return nil end
    local folder = espGui:FindFirstChild("SH_Highlights")
    if not folder then
        folder = Instance.new("Folder")
        folder.Name = "SH_Highlights"
        folder.Parent = espGui
    end
    local key = tostring(model)
    local hl = folder:FindFirstChild(key)
    if not hl then
        -- Roblox struggles with dozens of Highlights — hard cap
        local n = 0
        for _, ch in ipairs(folder:GetChildren()) do
            if ch:IsA("Highlight") and ch.Enabled then n = n + 1 end
        end
        if n >= 14 then return nil end
        hl = Instance.new("Highlight")
        hl.Name = key
        hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        hl.Parent = folder
    end
    hl.Adornee = model
    hl.FillColor = fill
    hl.OutlineColor = outline
    hl.FillTransparency = 0.55
    hl.OutlineTransparency = 0
    hl.Enabled = true
    return hl
end

local function disableHl(model)
    if not model then return end
    local folder = espGui:FindFirstChild("SH_Highlights")
    if not folder then return end
    local hl = folder:FindFirstChild(tostring(model))
    if hl then hl.Enabled = false; hl.Adornee = nil end
end
local function clearEsp()
    for k, d in pairs(drawings) do
        destroyDraw(d)
        drawings[k] = nil
    end
    local folder = espGui:FindFirstChild("SH_Highlights")
    if folder then folder:ClearAllChildren() end
    local bbHost = espGui:FindFirstChild("SH_UnitBB")
    if bbHost then bbHost:ClearAllChildren() end
    local units = unitsFolder()
    if units then
        for _, m in ipairs(units:GetChildren()) do
            local hl = m:FindFirstChild("SH_HL")
            if hl then hl:Destroy() end -- legacy cleanup
            local old = m:FindFirstChild("SH_ESP_BB", true)
            if old then old:Destroy() end
        end
    end
    for _, p in ipairs(chestParts()) do
        local hl = p:FindFirstChild("SH_ChestHL") or (p.Parent and p.Parent:FindFirstChild("SH_ChestHL"))
        if hl then hl:Destroy() end
    end
end

local function updateUnitEsp()
    local seen = {}
    local folder = unitsFolder()
    if not folder then return end
    local pvp = isPvpWorld()
    -- PvP: ESP off unless explicitly enabled — billboards/chams drop FPS to 0–1 in arenas
    if pvp and F.pvpEsp ~= true then
        if next(drawings) then
            for k, d in pairs(drawings) do
                if d and d.model then disableHl(d.model) end
                if d and d.bb then pcall(function() d.bb:Destroy() end) end
                drawings[k] = nil
            end
            local hlFolder = espGui:FindFirstChild("SH_Highlights")
            if hlFolder then hlFolder:ClearAllChildren() end
            local bbHost = espGui:FindFirstChild("SH_UnitBB")
            if bbHost then bbHost:ClearAllChildren() end
        end
        return
    end
    local showEnemy = F.enemyEsp ~= false -- default ON
    local showOwn = F.ownEsp == true
    if not showEnemy and not showOwn then
        for k, d in pairs(drawings) do
            if d and d.model then disableHl(d.model) end
            if d and d.bb then pcall(function() d.bb:Destroy() end) end
            drawings[k] = nil
        end
        local hlFolder = espGui:FindFirstChild("SH_Highlights")
        if hlFolder then
            for _, hl in ipairs(hlFolder:GetChildren()) do
                if hl:IsA("Highlight") then hl.Enabled = false; hl.Adornee = nil end
            end
        end
        return
    end
    -- Host billboards under espGui (Adornee) — parenting into Units gets wiped by the game
    local host = espGui:FindFirstChild("SH_UnitBB")
    if not host then
        host = Instance.new("Folder")
        host.Name = "SH_UnitBB"
        host.Parent = espGui
    end
    for _, m in ipairs(folder:GetChildren()) do
        if not m:IsA("Model") then continue end
        if not isValidUnitModel(m) then
            disableHl(m)
            continue
        end
        local own = isOwnUnit(m)
        local enemy = isEnemyUnit(m)
        local show = (own and showOwn) or (enemy and showEnemy)
        local key = tostring(m)
        -- Prefer Collider (PrimaryPart) — that's what the game orients; fall back to HRP
        local root = m.PrimaryPart or rootOf(m)
        if not show or not root then
            if drawings[key] then
                if drawings[key].bb then pcall(function() drawings[key].bb:Destroy() end) end
                drawings[key] = nil
            end
            disableHl(m)
            continue
        end
        -- PvP: skip far units (billboards + work) — keep closest fights readable
        if pvp and enemy then
            local d = distTo(root.Position)
            if d > 220 then
                if drawings[key] then
                    if drawings[key].bb then pcall(function() drawings[key].bb:Destroy() end) end
                    drawings[key] = nil
                end
                disableHl(m)
                continue
            end
        end
        seen[key] = true
        local d = drawings[key]
        if not d or not d.bb or not d.bb.Parent then
            if pvp then
                local bbCount = 0
                for _ in pairs(drawings) do bbCount = bbCount + 1 end
                if bbCount >= 24 then continue end
            end
            local bb = Instance.new("BillboardGui")
            bb.Name = "SH_ESP_" .. key:gsub("%W", ""):sub(1, 40)
            bb.AlwaysOnTop = true
            bb.Size = UDim2.fromOffset(260, 60)
            bb.StudsOffset = Vector3.new(0, 4, 0)
            bb.MaxDistance = pvp and 220 or 2000
            bb.LightInfluence = 0
            bb.ResetOnSpawn = false
            bb.Adornee = root
            bb.Parent = host
            local t = Instance.new("TextLabel")
            t.Name = "Text"
            t.BackgroundTransparency = 1
            t.Size = UDim2.fromScale(1, 1)
            t.Font = Enum.Font.GothamBold
            t.TextSize = 15
            t.TextStrokeTransparency = 0.15
            t.TextStrokeColor3 = Color3.new(0, 0, 0)
            t.TextColor3 = Color3.new(1, 1, 1)
            t.TextWrapped = true
            t.Parent = bb
            d = { bb = bb, text = t, model = m }
            drawings[key] = d
        else
            d.bb.Adornee = root
            d.model = m
        end
        local col = own and colOf("ownEspColor", 80, 220, 120) or colOf("enemyEspColor", 255, 90, 90)
        if enemy and isBossUnit(m) then col = colOf("bossEspColor", 255, 200, 60) end
        local hp, maxHp = unitHp(m)
        local parts = {}
        if (enemy and F.enemyEspName ~= false) or (own and F.ownEspName ~= false) then
            table.insert(parts, m.Name)
        end
        if enemy and F.enemyEspHp ~= false then
            table.insert(parts, hp and string.format("%.0f/%.0f", hp, maxHp or hp) or "HP ?")
        end
        if own and F.ownEspHp ~= false then
            table.insert(parts, hp and string.format("HP %.0f/%.0f", hp, maxHp or hp) or "HP ?")
        end
        if own and F.ownEspSpecial ~= false then
            local ready, left = specialReady(m)
            table.insert(parts, ready and "SP READY" or string.format("SP %.1fs", left))
        end
        if (enemy and F.enemyEspDist ~= false) or (own and F.ownEspDist) then
            table.insert(parts, string.format("%.0fm", distTo(root.Position)))
        end
        d.bb.Enabled = true
        d.text.Text = #parts > 0 and table.concat(parts, " | ") or m.Name
        d.text.TextColor3 = col
        d.text.TextTransparency = 0
        -- Chams: OFF in PvP by default (Highlights melt FPS with many player units)
        local wantChams = (own and F.ownEspChams) or (enemy and F.enemyEspChams ~= false)
        if pvp and F.pvpEspChams ~= true then
            wantChams = false
        end
        if wantChams then
            ensureHl(m, col, col)
        else
            disableHl(m)
        end
    end
    for k, d in pairs(drawings) do
        if not seen[k] then
            if d and d.model then disableHl(d.model) end
            if d and d.bb then pcall(function() d.bb:Destroy() end) end
            drawings[k] = nil
        end
    end
end

local chestDraw = {}
local function updateChestEsp()
    if isPvpWorld() or not F.chestEsp then
        if next(chestDraw) then
            for k, d in pairs(chestDraw) do
                destroyDraw(d)
                chestDraw[k] = nil
            end
        end
        return
    end
    local seen = {}
    for _, part in ipairs(openableChests()) do
        local key = tostring(part:GetFullName())
        seen[key] = true
        local d = chestDraw[key]
        if not d then d = makeLabel(); chestDraw[key] = d end
        if not d then continue end
        local col = colOf("chestEspColor", 255, 210, 90)
        local vis = chestVisual(part)
        local anchor = part
        if typeof(vis) == "Instance" then
            if vis:IsA("Model") then
                anchor = vis.PrimaryPart or vis:FindFirstChildWhichIsA("BasePart") or part
            elseif vis:IsA("BasePart") then
                anchor = vis
            end
        end
        local pos = anchor.Position
        local sp, on, z = w2v(pos + Vector3.new(0, 2, 0))
        if on and z > 0 then
            d.frame.Visible = true
            d.frame.Position = UDim2.fromOffset(sp.X, sp.Y)
            d.text.Text = (F.chestEspName ~= false) and chestDisplayName(part) or "Chest"
            d.text.TextColor3 = col
            if F.chestEspChams then
                -- Only highlight the real Chest model (or the tagged pad) — never random nearby props
                local host = (typeof(vis) == "Instance" and vis:IsA("Model")) and vis or part
                if host:IsA("BasePart") or (host:IsA("Model") and (host.Name == "Chest" or host.Name == "BonusChest")) then
                    local hl = host:FindFirstChild("SH_ChestHL")
                    if not hl then
                        hl = Instance.new("Highlight")
                        hl.Name = "SH_ChestHL"
                        hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                        hl.FillTransparency = 0.45
                        hl.OutlineTransparency = 0
                        hl.Parent = host
                    end
                    hl.Adornee = host
                    hl.FillColor = col
                    hl.OutlineColor = col
                    hl.Enabled = true
                end
            else
                local host = (typeof(vis) == "Instance" and vis:IsA("Model")) and vis or part
                local hl = host and host:FindFirstChild("SH_ChestHL")
                if hl then hl.Enabled = false end
            end
        else
            d.frame.Visible = false
        end
    end
    for k, d in pairs(chestDraw) do
        if not seen[k] then destroyDraw(d); chestDraw[k] = nil end
    end
end

local lastEspAt = 0
local pvpEspCleared = false
RunService.Heartbeat:Connect(function()
    if genv.SH_Session ~= SESSION or not genv.SH_Alive then return end
    local pvp = isPvpWorld()
    if pvp and F.pvpEsp ~= true then
        if not pvpEspCleared then
            pvpEspCleared = true
            pcall(clearEsp)
        end
        return
    end
    pvpEspCleared = false
    local now = tick()
    local iv = pvp and 0.5 or 0.2
    if now - lastEspAt < iv then return end
    lastEspAt = now
    pcall(updateUnitEsp)
    if not pvp then
        pcall(updateChestEsp)
    end
end)

-- ============================================================ VISUALS WORLD
local fbWas, fogWas = false, false
local fbOrig, fogOrig = {}, {}
loop(function() return F.fullbright end, function()
    if not fbWas then
        fbOrig = {
            b = Lighting.Brightness, a = Lighting.Ambient, oa = Lighting.OutdoorAmbient,
            gs = Lighting.GlobalShadows, ct = Lighting.ClockTime,
        }
        fbWas = true
    end
    Lighting.Brightness = F.fbBrightness or 3
    Lighting.ClockTime = 12
    Lighting.GlobalShadows = false
    Lighting.Ambient = Color3.fromRGB(160, 160, 160)
    Lighting.OutdoorAmbient = Color3.fromRGB(160, 160, 160)
end, 0.35)
loop(function() return F.noFog end, function()
    if not fogWas then fogOrig = { e = Lighting.FogEnd, s = Lighting.FogStart }; fogWas = true end
    Lighting.FogEnd = 1e9
    Lighting.FogStart = 1e9
end, 0.35)
RunService.Heartbeat:Connect(function()
    if not F.fullbright and fbWas then
        pcall(function()
            Lighting.Brightness = fbOrig.b; Lighting.Ambient = fbOrig.a
            Lighting.OutdoorAmbient = fbOrig.oa; Lighting.GlobalShadows = fbOrig.gs
            Lighting.ClockTime = fbOrig.ct
        end)
        fbWas = false
    end
    if not F.noFog and fogWas then
        pcall(function() Lighting.FogEnd = fogOrig.e; Lighting.FogStart = fogOrig.s end)
        fogWas = false
    end
end)

RunService:BindToRenderStep("SH_Camera", Enum.RenderPriority.Camera.Value + 2, function()
    if genv.SH_Session ~= SESSION or not genv.SH_Alive then return end
    if F.fovUnlock then Camera.FieldOfView = F.fovAmt or 90 end
    if F.noShake then
        local h = hum()
        if h then h.CameraOffset = Vector3.zero end
    end
end)
-- CameraShake setting: write rarely (every frame Profile walk = PvP lag)
do
    local lastShakeWrite = 0
    loop(function() return F.noShake == true end, function()
        if tick() - lastShakeWrite < 2 then return end
        lastShakeWrite = tick()
        pcall(function()
            local p = getProfile()
            local s = p and p:FindFirstChild("Settings")
            local cs = s and s:FindFirstChild("CameraShake")
            if cs and cs:IsA("BoolValue") and cs.Value ~= false then cs.Value = false end
        end)
    end, 2)
end

-- Damage numbers enhance — NEVER Workspace:GetDescendants (melts PvP arenas)
local function enhanceDamageBillboards()
    if not F.dmgEnhance or isPvpWorld() then return end
    local scale = F.dmgScale or 1.8
    local hosts = {
        Workspace:FindFirstChild("Effects"),
        Workspace:FindFirstChild("Debris"),
        Workspace:FindFirstChild("DamageNumbers"),
    }
    for _, host in ipairs(hosts) do
        if not host then continue end
        for _, gui in ipairs(host:GetDescendants()) do
            if gui:IsA("BillboardGui") then
                local tl = gui:FindFirstChildWhichIsA("TextLabel", true)
                if tl and tl.Text and tonumber((tl.Text:gsub(",", ""):match("[%d%.]+"))) then
                    local us = gui:FindFirstChildOfClass("UIScale")
                    if not us then us = Instance.new("UIScale"); us.Parent = gui end
                    if us.Scale < scale then us.Scale = scale end
                    if F.dmgBold then tl.TextStrokeTransparency = 0.2; tl.TextSize = math.max(tl.TextSize, 22) end
                end
            end
        end
    end
end
do
    local rd = rem("RenderDamage")
    if rd and rd:IsA("RemoteEvent") then
        rd.OnClientEvent:Connect(function()
            if not F.dmgEnhance or isPvpWorld() then return end
            task.defer(enhanceDamageBillboards)
        end)
    end
end
loop(function() return F.dmgEnhance == true and not isPvpWorld() end, enhanceDamageBillboards, 0.75)

-- ============================================================ HUD (Session + Match via win:hud)
-- Kill legacy ScreenGui labels — they fought win:hud and caused the "Lobby" stub / jerk.
pcall(function()
    if hudGui then
        for _, ch in ipairs(hudGui:GetChildren()) do
            if ch:IsA("TextLabel") then ch:Destroy() end
        end
        hudGui.Enabled = false
    end
end)

local sessionHud, matchHud, indexHud

local function fmtNum(n)
    n = math.floor(tonumber(n) or 0)
    if n >= 1e6 then return string.format("%.2fM", n / 1e6) end
    if n >= 1e3 then return string.format("%.1fK", n / 1e3) end
    return tostring(n)
end

local function fmtRate(n)
    n = tonumber(n) or 0
    if n >= 1e6 then return string.format("%.2fM/h", n / 1e6) end
    if n >= 1e3 then return string.format("%.1fK/h", n / 1e3) end
    return string.format("%.0f/h", n)
end

local function getMatchWaveInfo()
    return ReplicatedStorage:FindFirstChild("TowerWaveInfo")
        or ReplicatedStorage:FindFirstChild("EndlessWaveInfo")
        or ReplicatedStorage:FindFirstChild("WaveInfo")
end

local function applyHudVisibility(instant)
    if sessionHud then
        pcall(function() sessionHud:setVisible(F.farmHud ~= false, instant == true) end)
    end
    if matchHud then
        pcall(function() matchHud:setVisible(F.waveHud ~= false, instant == true) end)
    end
    if indexHud then
        pcall(function() indexHud:setVisible(F.indexHud ~= false, instant == true) end)
    end
end

-- Farm stats only — never call setVisible here (that re-triggered fade every tick).
loop(function() return true end, function()
    pcall(updateFarmStats)
end, function()
    return isPvpWorld() and 2.5 or 1
end)

-- ============================================================ AUTOMATION LOOPS
local lastVoteAt = 0
local lastReadyAt = 0
local lastQueueAt = 0
local lastQueueFailNotify = 0
local lastAfkStart = 0
local lastSkipAt = 0

local function pickVote()
    if F.towerBot or F.autoQueueTower then
        return "Retry" -- win or loss: Replay Tower
    end
    if F.chestRetryFarm then return "Retry" end
    if F.fullAfkStory or F.autoQueueStory then
        if lastVictory == true then return "Next" end
        return "Retry"
    end
    if F.afkWavesFarm then
        return F.afkVoteMode or "Lobby"
    end
    if F.autoQueueEndless then
        local mode = F.endlessVoteMode or "Retry"
        if mode == "None" then return nil end
        -- 0 entries → Restart hidden; Retry votes do nothing and bot freezes on RoundEnd
        if mode == "Retry" and not endlessRetryAvailable() then
            return "Lobby"
        end
        return mode
    end
    if F.autoVoteRetry or F.autoVoteNext or F.autoVoteLobby then
        return F.voteMode or (F.autoVoteRetry and "Retry") or (F.autoVoteNext and "Next") or "Lobby"
    end
    return nil
end

local function beginEndVote(mode, delaySec)
    if not mode or mode == "None" then return end
    pendingVote = mode
    votedThisEnd = false
    if delaySec == nil then
        if F.soloFastMatch then
            delaySec = 0.45
        else
            delaySec = tonumber(F.voteDelayAfterEnd) or 2
        end
    else
        delaySec = tonumber(delaySec) or 2
    end
    if F.soloFastMatch then
        delaySec = math.min(delaySec, 0.45)
    end
    task.spawn(function()
        task.wait(math.max(0.15, delaySec))
        for _ = 1, 60 do
            if isLobby() then return end
            if pendingVote ~= mode then return end
            -- Prefer voting once RoundEnd is up; after enough time force anyway
            local waited = tick() - gameOverAt
            if isRoundEndOpen() or waited >= delaySec + 1.5 then
                forceVote(mode)
                if ReplicatedStorage:GetAttribute("RoundEndType") == mode then
                    votedThisEnd = true
                    return
                end
            end
            task.wait(0.25)
        end
    end)
end

local function onGameOver(victory)
    if typeof(victory) == "boolean" then
        lastVictory = victory
    elseif victory == nil and lastVictory == nil then
        -- keep
    end
    -- Don't double-count the same end screen
    if gameOverAt > 0 and tick() - gameOverAt < 4 then
        if not pendingVote then
            pendingVote = pickVote()
            if F.chestRetryFarm then
                chestFarmPhase = "need_loot_then_retry"
            elseif pendingVote then
                beginEndVote(pendingVote, F.voteDelayAfterEnd or 2)
            end
        end
        return
    end
    gameOverAt = tick()
    votedThisEnd = false
    farm.runs = (farm.runs or 0) + 1
    genv.SH_Farm = farm
    flushFarmDisk()
    if F.chestRetryFarm then
        chestFarmPhase = "need_loot_then_retry"
        pendingVote = "Retry"
        -- Instant Retry once loot finishes (chest loop). Backup if no chests spawn.
        task.delay(4, function()
            if not F.chestRetryFarm or isLobby() or gameOverAt <= 0 then return end
            if chestsRemaining() > 0 then return end
            pendingVote = "Retry"
            forceVote("Retry")
        end)
        return
    end
    local mode = pickVote()
    if mode then beginEndVote(mode, F.voteDelayAfterEnd or 2) end
end

do
    local hooked = {}
    local function hook(name, parseVictory)
        if hooked[name] then return end
        local r = rem(name)
        if not (r and r:IsA("RemoteEvent")) then return end
        hooked[name] = true
        r.OnClientEvent:Connect(function(...)
            local args = { ... }
            local victory = parseVictory and args[1] or nil
            task.defer(function() pcall(onGameOver, victory) end)
        end)
    end
    local function hookAll()
        hook("Waves_GameOver", true)
        hook("EndlessWaves_GameOver", false)
        hook("AFKWaves_ShowRewards", false)
        hook("Tower_GameOver", false)
    end
    hookAll()
    task.spawn(function()
        ReplicatedStorage:WaitForChild("Remotes", 30)
        for _ = 1, 20 do
            hookAll()
            if hooked["Waves_GameOver"] then break end
            task.wait(0.5)
        end
    end)
    -- Fallback: RoundEnd GUI appeared but GameOver remote was missed
    task.spawn(function()
        while genv.SH_Alive and genv.SH_Session == SESSION do
            task.wait(0.75)
            if isLobby() then continue end
            if gameOverAt > 0 and tick() - gameOverAt < 60 then continue end
            if isRoundEndGuiVisible() then
                pcall(onGameOver, nil)
            end
        end
    end)
    -- New match: reset vote state (WaveInfo + Endless + Tower)
    task.spawn(function()
        local bound = {}
        local function onMatchReset()
            clearVoteState("match-reset")
            lastVictory = nil
            sawChestsThisMatch = false
            chestsLootedThisMatch = 0
            chestFarmPhase = F.chestRetryFarm and "collecting" or "idle"
            rebaselineCurrency()
        end
        local function bind(wi)
            if not wi or bound[wi] then return end
            bound[wi] = true
            wi:GetAttributeChangedSignal("Wave"):Connect(function()
                local w = wi:GetAttribute("Wave")
                if w == 1 and wi:GetAttribute("Intermission") == true then
                    onMatchReset()
                end
            end)
            wi:GetAttributeChangedSignal("Intermission"):Connect(function()
                if wi:GetAttribute("Intermission") == true and not isRoundEndGuiVisible() then
                    clearVoteState("intermission")
                end
            end)
        end
        for _, name in ipairs({ "WaveInfo", "EndlessWaveInfo", "TowerWaveInfo" }) do
            bind(ReplicatedStorage:FindFirstChild(name))
        end
        ReplicatedStorage.ChildAdded:Connect(function(ch)
            if ch.Name == "WaveInfo" or ch.Name == "EndlessWaveInfo" or ch.Name == "TowerWaveInfo" then
                bind(ch)
                task.defer(onMatchReset)
            end
        end)
    end)
    pcall(function()
        local ts = game:GetService("TeleportService")
        if ts.LocalPlayerTeleported then
            ts.LocalPlayerTeleported:Connect(function()
                rebaselineCurrency()
                pendingVote = nil
                gameOverAt = 0
                votedThisEnd = false
            end)
        end
    end)
end

-- Skip cutscenes + dialogue — pause while RoundEnd is up (don't steal clicks)
loop(function() return F.skipCutscene ~= false end, function()
    if isPvpWorld() then return end
    if isRoundEndOpen() or isRoundEndGuiVisible() then return end
    if not isCutsceneActive() and not isTauntDialogOpen() then return end
    if tick() - lastSkipAt < 0.45 then return end
    lastSkipAt = tick()
    skipCutscenes()
end, 0.25)

loop(function() return F.autoReady or F.fullAfkStory or F.autoQueueStory or F.afkWavesFarm or F.chestRetryFarm or F.towerBot or F.autoQueueEndless or F.autoQueueTower end, function()
    if isLobby() or isPvpWorld() then return end
    if isRoundEndOpen() then return end
    if LP:GetAttribute("Ready") == true then return end
    local wi = ReplicatedStorage:FindFirstChild("TowerWaveInfo")
        or ReplicatedStorage:FindFirstChild("EndlessWaveInfo")
        or ReplicatedStorage:FindFirstChild("WaveInfo")
    if wi then
        local inter = wi:GetAttribute("Intermission")
        local timer = wi:GetAttribute("IntermissionTimer")
        local needReady = inter == true or (type(timer) == "number" and timer > 0)
        -- Endless / Tower: Ready only during intermission. Story WaveInfo same.
        if not needReady then return end
    end
    if tick() - lastReadyAt < (F.readyInterval or 1.0) then return end
    lastReadyAt = tick()
    doReady()
end, 0.35)

loop(function() return F.autoVoteRetry or F.autoVoteNext or F.autoVoteLobby or F.fullAfkStory or F.autoQueueStory or F.afkWavesFarm or F.chestRetryFarm or F.towerBot or F.autoQueueTower or F.autoQueueEndless end, function()
    if isLobby() or isPvpWorld() then
        clearVoteState("lobby")
        return
    end
    if not pendingVote and (F.autoQueueStory or F.fullAfkStory or F.towerBot or F.autoQueueTower or F.autoQueueEndless) and isRoundEndOpen() then
        pendingVote = pickVote() or "Retry"
        if gameOverAt <= 0 then gameOverAt = tick() end
    end
    -- Endless: if we planned Retry but entries ran out mid-screen, switch to Lobby
    if pendingVote == "Retry" and F.autoQueueEndless and isRoundEndOpen() and not endlessRetryAvailable() then
        pendingVote = "Lobby"
    end
    if not pendingVote then return end
    if not F.chestRetryFarm then
        if gameOverAt <= 0 and not isRoundEndOpen() then return end
        local delaySec = tonumber(F.voteDelayAfterEnd) or 1
        if gameOverAt > 0 and tick() - gameOverAt < delaySec and not isRoundEndGuiVisible() then return end
    end
    if tick() - lastVoteAt < (F.chestRetryFarm and 0.35 or (F.voteInterval or 0.8)) then return end
    lastVoteAt = tick()
    local mode = pendingVote
    forceVote(mode)
    if ReplicatedStorage:GetAttribute("RoundEndType") == mode then
        votedThisEnd = true
    end
end, 0.35)

loop(function() return F.autoQueueStory or F.fullAfkStory end, function()
    if not isLobby() then return end
    if tick() - lastQueueAt < (F.queueInterval or 5) then return end
    lastQueueAt = tick()
    local mapKey, stage = resolveStoryQueue()
    local ok2, err = setStoryQueue(mapKey, stage)
    if ok2 then
        notify("Queue", mapKey .. " · Stage " .. tostring(stage), "map-pin")
    elseif tick() - (lastQueueFailNotify or 0) > 8 then
        lastQueueFailNotify = tick()
        notify("Queue", tostring(err or "failed"), "alert-triangle")
    end
end, 1)

loop(function() return F.afkWavesFarm end, function()
    if isLobby() then
        if tick() - lastAfkStart < (F.afkStartInterval or 6) then return end
        lastAfkStart = tick()
        fire("AFKWaves_StartRound")
    else
        doReady()
        if pendingVote then
            local mode = pendingVote
            if mode ~= "None" then doVote(mode) end
        end
    end
end, 1.2)

local lastTowerQueueAt, lastEndlessQueueAt = 0, 0
loop(function() return F.autoQueueTower end, function()
    if not isLobby() then return end
    if tick() - lastTowerQueueAt < (F.towerQueueInterval or 6) then return end
    lastTowerQueueAt = tick()
    local ok2, err = queueTower()
    if ok2 then
        notify("Tower", "Queued Infinite Tower", "mountain")
    elseif tick() - (lastQueueFailNotify or 0) > 10 then
        lastQueueFailNotify = tick()
        notify("Tower", tostring(err or "failed"), "alert-triangle")
    end
end, 1.2)

loop(function() return F.autoQueueEndless end, function()
    if not isLobby() then return end
    if tick() - lastEndlessQueueAt < (F.endlessQueueInterval or 8) then return end
    lastEndlessQueueAt = tick()
    local ok2, err = queueEndlessCircus()
    if ok2 then
        notify("Endless", "Started NightmareCircus", "bolt")
    elseif tick() - (lastQueueFailNotify or 0) > 10 then
        lastQueueFailNotify = tick()
        notify("Endless", tostring(err or "failed"), "alert-triangle")
    end
end, 1.5)

-- Endless stall watchdog: stuck RoundEnd / ghost vote state / missed Ready
loop(function() return F.autoQueueEndless == true end, function()
    if isPvpWorld() then return end
    if isLobby() then
        -- After Lobby vote, keep trying to re-enter (entries permitting)
        return
    end
    local wi = ReplicatedStorage:FindFirstChild("EndlessWaveInfo")
    if wi and wi:GetAttribute("Intermission") == true and not isRoundEndGuiVisible() then
        if pendingVote or gameOverAt > 0 then
            clearVoteState("endless-intermission")
        end
        if LP:GetAttribute("Ready") ~= true then
            doReady()
        end
        return
    end
    if not isRoundEndGuiVisible() then return end
    if gameOverAt <= 0 then gameOverAt = tick() end
    local want = pickVote()
    if not want or want == "None" then return end
    -- Stuck >12s on end screen → force correct vote (Lobby if no entries)
    if tick() - gameOverAt >= 12 then
        pendingVote = want
        forceVote(want)
    elseif not pendingVote then
        pendingVote = want
        beginEndVote(want, 0.5)
    end
end, 1.2)

loop(function() return F.towerBot == true end, towerBotTick, function()
    local info = ReplicatedStorage:FindFirstChild("TowerWaveInfo")
    if info and (info:GetAttribute("RoomChoice") == true
        or (tonumber(info:GetAttribute("RecruitTimer")) or 0) > 0
        or (tonumber(info:GetAttribute("PurchaseTimer")) or 0) > 0) then
        return 0.15
    end
    return 0.5
end)

-- Keep teleport queue armed once (identical URL — never re-queue / never stack)
-- (periodic re-arm removed: executors append queue_on_teleport)

-- ============================================================ PVP SHOP AUTO-BUY (RotatingShops PvPShop)
-- Never yield inside Heartbeat loop — that stacked overlapping buy passes and lagged the game.
local PVP_SHOP_ID = "PvPShop"
local PVP_FOOD = {
    Cupcake = true, Boba = true, Avocado = true, RiceCake = true, Fries = true, Burger = true,
}
local PVP_MAX_BUYS_PER_PASS = 3
local PVP_BUY_GAP = 0.55
local lastPvpBuyAt = 0
local lastPvpNotifyAt = 0
local lastPvpSeed = nil
local pvpBuyBusy = false
local pvpShopCached = nil

local function getRotatingShops()
    if pvpShopCached ~= nil then return pvpShopCached end
    -- FindFirstChild only — never WaitForChild/yield (yield during UI build → Plugin error).
    local systems = ReplicatedStorage:FindFirstChild("Systems")
    local mod = systems and systems:FindFirstChild("RotatingShops")
    if not mod then return nil end
    local ok, result = pcall(require, mod)
    if ok and result then pvpShopCached = result end
    return ok and result or nil
end

local function pvpItemWanted(itemName)
    if itemName == "TraitReroll" then return F.pvpBuyTraitReroll == true end
    if itemName == "SummonTicket" then return F.pvpBuySummonTicket == true end
    if itemName == "LegendaryFusionCrystal" then return F.pvpBuyLegendaryCrystal == true end
    if itemName == "EpicFusionCrystal" then return F.pvpBuyEpicCrystal == true end
    if itemName == "RareFusionCrystal" then return F.pvpBuyRareCrystal == true end
    if F.pvpBuyFood == true and PVP_FOOD[itemName] then return true end
    return false
end

local function buyPvpShopSlot(shop, slot)
    -- Client API: RotatingShops:BuyItem(player, shopId, slot) → FireServer(shopId, slot)
    local ok = pcall(function()
        shop:BuyItem(LP, PVP_SHOP_ID, slot)
    end)
    if not ok then
        fire("BuyItem", PVP_SHOP_ID, slot)
    end
end

local function autoBuyPvpShopPass(force)
    if not force and F.pvpShopAutoBuy ~= true then return end
    local shop = getRotatingShops()
    if not shop then return end

    local seed = nil
    pcall(function() seed = shop:GetShopSeed(PVP_SHOP_ID) end)
    local items
    pcall(function() items = shop:GetCurrentShopItems(PVP_SHOP_ID) end)
    if type(items) ~= "table" then return end

    local bal = getCurrency("PVPTokens") or 0
    local bought = 0

    for slot, item in ipairs(items) do
        if bought >= PVP_MAX_BUYS_PER_PASS then break end
        if type(item) ~= "table" or not pvpItemWanted(item.ItemName) then continue end

        local has, left = false, 0
        pcall(function()
            has, left = shop:HasStock(LP, PVP_SHOP_ID, slot)
        end)
        left = math.floor(tonumber(left) or 0)
        if not has or left <= 0 then continue end

        local price = tonumber(item.PVPTokensPrice) or 0
        if bal < price then continue end

        local remDaily = nil
        pcall(function()
            remDaily = select(1, shop:GetDailyItemLimit(LP, item.ItemName))
        end)
        if type(remDaily) == "number" and remDaily < 1 then continue end

        local times = 1
        if F.pvpBuyAllStock == true then
            times = left
            if type(remDaily) == "number" then times = math.min(times, remDaily) end
            times = math.min(times, PVP_MAX_BUYS_PER_PASS - bought, math.floor(bal / math.max(price, 1)))
            times = math.max(1, times)
        end

        for _ = 1, times do
            if bal < price then break end
            buyPvpShopSlot(shop, slot)
            bal = bal - price
            bought = bought + 1
            if bought >= PVP_MAX_BUYS_PER_PASS then break end
            task.wait(PVP_BUY_GAP)
        end
    end

    if bought > 0 and tick() - lastPvpNotifyAt > 4 then
        lastPvpNotifyAt = tick()
        notify("PvP Shop", "Bought x" .. tostring(bought), "ticket")
    end
    if seed ~= nil then lastPvpSeed = seed end
end

local function autoBuyPvpShopTick()
    if F.pvpShopAutoBuy ~= true then return end
    if pvpBuyBusy then return end
    if tick() - lastPvpBuyAt < 4 then return end
    lastPvpBuyAt = tick()
    pvpBuyBusy = true
    task.spawn(function()
        local ok, err = pcall(autoBuyPvpShopPass)
        pvpBuyBusy = false
        if not ok then warn("[SH] PvP buy: " .. tostring(err)) end
    end)
end

-- Idle poll ~5s; buy work runs off Heartbeat so passes never overlap.
loop(function() return F.pvpShopAutoBuy == true end, autoBuyPvpShopTick, 5)

-- Sync in-game AutoGearSell settings
local lastGearSellSync = 0
loop(function() return F.syncAutoGearSell == true end, function()
    if tick() - lastGearSellSync < 2 then return end
    lastGearSellSync = tick()
    fire("SetConfig", "AutoGearSell_Rarity2", F.autoGearSellR2 == true)
    fire("SetConfig", "AutoGearSell_Rarity3", F.autoGearSellR3 == true)
    fire("SetConfig", "AutoGearSell_Rarity4", F.autoGearSellR4 == true)
end, 2)

-- ============================================================ QUICK GEAR RECYCLE (RecycleGear RF, max 18 / call)
local GEAR_ITEM_DATA = nil
local GEAR_RANK_ORD = { D = 1, C = 2, B = 3, A = 4, S = 5, X = 6 }
-- Index S/A names — never junk-recycle unless user disables keep
local GEAR_KEEP_NAMED = {
    PactboundToken = true,
    HeartOfTheColossus = true,
    RendsBlade = true,
    HertzsWildcard = true,
    TheSleeplessEye = true,
    DeadeyeFang = true,
    FoxfireCharm = true,
}
local gearRecycleBusy = false

local function getGearItemData(name)
    if not GEAR_ITEM_DATA then
        pcall(function()
            GEAR_ITEM_DATA = require(ReplicatedStorage.WorldModules.ItemData.Gear)
        end)
        if type(GEAR_ITEM_DATA) ~= "table" then GEAR_ITEM_DATA = {} end
    end
    return GEAR_ITEM_DATA[name]
end

local function getGearInventoryFolder()
    local p = getProfile()
    local inv = p and p:FindFirstChild("Inventory")
    return inv and inv:FindFirstChild("Gear")
end

local function gearShouldRecycle(inst)
    if not inst or inst:GetAttribute("Locked") then return false end
    local data = getGearItemData(inst.Name)
    local rarity = data and tonumber(data.Rarity) or 1
    local maxR = tonumber(F.recycleMaxRarity) or 4 -- default Epic
    if rarity > maxR then return false end
    if F.recycleKeepNamed ~= false and GEAR_KEEP_NAMED[inst.Name] then return false end
    local rank = tostring(inst:GetAttribute("Rank") or "D")
    local keepRank = tostring(F.recycleKeepMinRank or "A")
    if keepRank ~= "Z" and keepRank ~= "None" then
        if (GEAR_RANK_ORD[rank] or 0) >= (GEAR_RANK_ORD[keepRank] or 4) then return false end
    end
    local lv = tonumber(inst:GetAttribute("Level")) or 1
    if F.recycleKeepLeveled ~= false and lv > 1 then return false end
    return true
end

local function recycleGearInvoke(batch)
    if type(batch) ~= "table" or #batch == 0 then return false, 0 end
    local r1, r2
    local called = pcall(function()
        local Gear = require(ReplicatedStorage.Systems.Gear)
        if Gear and Gear.RecycleGear then
            r1, r2 = Gear:RecycleGear(LP, batch)
        end
    end)
    if called then
        if r1 == true then return true, tonumber(r2) or 0 end
        if type(r1) == "number" then return true, r1 end
        if r1 == false then return false, 0 end
    end
    local ok2, dust = invoke("RecycleGear", batch)
    if ok2 then return true, tonumber(dust) or 0 end
    return false, 0
end

local function countRecycleCandidates()
    local folder = getGearInventoryFolder()
    if not folder then return 0 end
    local n = 0
    for _, g in ipairs(folder:GetChildren()) do
        if gearShouldRecycle(g) then n += 1 end
    end
    return n
end

local function quickRecycleGear()
    if gearRecycleBusy then
        notify("Recycle", "Already running…", "trash")
        return
    end
    gearRecycleBusy = true
    task.spawn(function()
        local folder = getGearInventoryFolder()
        if not folder then
            notify("Recycle", "No gear inventory", "alert-triangle")
            gearRecycleBusy = false
            return
        end
        local list = {}
        for _, g in ipairs(folder:GetChildren()) do
            if gearShouldRecycle(g) then
                list[#list + 1] = g
            end
        end
        if #list == 0 then
            notify("Recycle", "Nothing to recycle (filters)", "trash")
            gearRecycleBusy = false
            return
        end
        local recycled, dustTotal = 0, 0
        for i = 1, #list, 18 do
            local batch = {}
            for j = i, math.min(i + 17, #list) do
                local g = list[j]
                if g and g.Parent == folder then
                    batch[#batch + 1] = g
                end
            end
            if #batch > 0 then
                local ok, dust = recycleGearInvoke(batch)
                if ok then
                    recycled += #batch
                    dustTotal += tonumber(dust) or 0
                else
                    notify("Recycle", "Batch failed at " .. tostring(recycled), "alert-triangle")
                    break
                end
                task.wait(0.25)
            end
        end
        notify("Recycle", string.format("Recycled %d · +%d Dust", recycled, math.floor(dustTotal)), "trash")
        gearRecycleBusy = false
    end)
end

-- Optional auto junk recycle in lobby
local lastAutoRecycleAt = 0
loop(function() return F.autoRecycleGear == true end, function()
    if not isLobby() then return end
    if gearRecycleBusy then return end
    if tick() - lastAutoRecycleAt < (tonumber(F.autoRecycleInterval) or 20) then return end
    if countRecycleCandidates() < (tonumber(F.autoRecycleMinCount) or 6) then return end
    lastAutoRecycleAt = tick()
    quickRecycleGear()
end, 3)

-- ============================================================ STAT REROLL BOT (own register pool — keeps __SH_BOOT__ under 200 locals)
local STATR = (function()
local STAT_LETTER_ORD = { D = 1, C = 2, B = 3, A = 4, S = 5, X = 6 }
local STAT_REROLL_KEYS = { "Attack", "Health", "Speed", "Cooldown" }
local STAT_REROLL_LABEL = { Attack = "ATK", Health = "HP", Speed = "SPD", Cooldown = "CD" }
local statRerollBusy = false
local statRerollStop = false

local function letterMeets(letter, target)
    return (STAT_LETTER_ORD[tostring(letter)] or 0) >= (STAT_LETTER_ORD[tostring(target)] or 6)
end

local function getUnitUpgradesMod()
    local ok, mod = pcall(function()
        return require(ReplicatedStorage.Systems.UnitUpgrades)
    end)
    return ok and mod or nil
end

local function listRerollUnits()
    local p = getProfile()
    if not p then return {} end
    local out, seen = {}, {}
    local function add(folder)
        if not folder then return end
        for _, u in ipairs(folder:GetChildren()) do
            if not seen[u] then
                seen[u] = true
                out[#out + 1] = u
            end
        end
    end
    add(p:FindFirstChild("Equipped"))
    local inv = p:FindFirstChild("Inventory")
    add(inv and inv:FindFirstChild("Units"))
    table.sort(out, function(a, b)
        local la = tonumber(a:GetAttribute("Level")) or 0
        local lb = tonumber(b:GetAttribute("Level")) or 0
        if la ~= lb then return la > lb end
        return a.Name < b.Name
    end)
    return out
end

local function unitRerollLabel(u, idx)
    if not u then return "?" end
    local data = UNIT_DATA and UNIT_DATA[u.Name]
    local dn = data and data.DisplayName or u.Name
    local lv = tonumber(u:GetAttribute("Level")) or 1
    local eq = u.Parent and u.Parent.Name == "Equipped" and "★" or ""
    local n = idx or 0
    if n <= 0 then
        for i, x in ipairs(listRerollUnits()) do
            if x == u then n = i break end
        end
    end
    return string.format("#%d %s%s Lv.%d", n, eq, dn, lv)
end

local function findUnitByRerollLabel(label)
    local units = listRerollUnits()
    for i, u in ipairs(units) do
        if unitRerollLabel(u, i) == label then return u end
    end
    -- fallback: match without # if list shifted
    for i, u in ipairs(units) do
        if label and label:find(unitRerollLabel(u, i), 1, true) then return u end
    end
    return nil
end

local function readUnitLetters(unit)
    local t = {}
    for _, k in ipairs(STAT_REROLL_KEYS) do
        t[k] = unit:GetAttribute(k) or "D"
    end
    return t
end

local function formatUnitLetters(unit)
    local parts = {}
    for _, k in ipairs(STAT_REROLL_KEYS) do
        parts[#parts + 1] = STAT_REROLL_LABEL[k] .. "=" .. tostring(unit:GetAttribute(k) or "?")
    end
    return table.concat(parts, " ")
end

local function buildLockedFromUnit(unit, target)
    local locked = {}
    for _, k in ipairs(STAT_REROLL_KEYS) do
        if letterMeets(unit:GetAttribute(k), target) then
            locked[#locked + 1] = k
        end
    end
    return locked
end

local function tableHas(t, v)
    for _, x in ipairs(t) do
        if x == v then return true end
    end
    return false
end

-- Skip RerollSequence cinematic when enabled (manual Reroll! also benefits)
local statRerollSeqHooked = false
local function fireRerollClosed(seq)
    pcall(function()
        local ev = seq:GetClosedSignal()
        if getconnections and ev then
            for _, c in ipairs(getconnections(ev)) do
                if c.Function then pcall(c.Function) end
            end
        end
    end)
end
local function restoreRerollStatsUi(Gui)
    pcall(function()
        if Gui and Gui.SetFullscreenLock then
            Gui:SetFullscreenLock("RerollStats", false)
        end
    end)
    pcall(function()
        local pg = LP:FindFirstChild("PlayerGui")
        if not pg then return end
        for _, g in ipairs(pg:GetDescendants()) do
            if g:IsA("ScreenGui") and (g.Name == "RerollStats" or g.Name:find("RerollStats")) then
                g.Enabled = true
            end
        end
    end)
end
local function hookStatRerollSkip()
    if statRerollSeqHooked then return true end
    local ok, Gui = pcall(function() return require(ReplicatedStorage.Systems.Gui) end)
    if not ok or type(Gui) ~= "table" or type(Gui.Get) ~= "function" then return false end
    local seq = Gui:Get("RerollSequence")
    if type(seq) ~= "table" or type(seq.Open) ~= "function" then return false end
    statRerollSeqHooked = true
    local oldOpen = seq.Open
    seq.Open = function(self, unit, newStats, locked)
        if F.statRerollSkip == false then
            return oldOpen(self, unit, newStats, locked)
        end
        -- Instant accept — RerollStats registers GetClosedSignal:Once AFTER Open returns
        local UU = getUnitUpgradesMod()
        if UU and UU.RerollAction then
            pcall(function() UU:RerollAction(LP, "UseNew") end)
        else
            invoke("RerollAction", "UseNew")
        end
        task.defer(function()
            fireRerollClosed(seq)
            pcall(function()
                if seq.Close then seq:Close() end
            end)
            restoreRerollStatsUi(Gui)
        end)
        return
    end
    return true
end
task.defer(function()
    for _ = 1, 15 do
        if hookStatRerollSkip() then break end
        task.wait(0.5)
    end
end)

local function applyStatReroll(unit, locked)
    local UU = getUnitUpgradesMod()
    local newStats
    if UU and UU.BuyStatReroll then
        local ok, res = pcall(function()
            return UU:BuyStatReroll(LP, unit, locked)
        end)
        if ok then newStats = res end
    end
    if type(newStats) ~= "table" then
        local ok2, res2 = invoke("BuyStatReroll", unit, locked)
        if ok2 then newStats = res2 end
    end
    if type(newStats) ~= "table" then return nil end
    -- Skip sequence: accept immediately
    if UU and UU.RerollAction then
        pcall(function() UU:RerollAction(LP, "UseNew") end)
    else
        invoke("RerollAction", "UseNew")
    end
    return newStats
end

local function runStatRerollBot()
    if statRerollBusy then
        notify("Stat Reroll", "Already running — Stop first", "alert-triangle")
        return
    end
    local label = F.statRerollUnitLabel
    local unit = findUnitByRerollLabel(label)
    if not unit then
        -- fallback: first equipped
        local p = getProfile()
        local eq = p and p:FindFirstChild("Equipped")
        unit = eq and eq:GetChildren()[1]
    end
    if not unit then
        notify("Stat Reroll", "No unit selected", "alert-triangle")
        return
    end
    local target = F.statRerollTarget or "X"
    local maxRolls = math.max(1, math.floor(tonumber(F.statRerollMax) or 400))
    local delaySec = math.max(0.05, tonumber(F.statRerollDelay) or 0.12)
    local only = {
        Attack = F.statRerollAtk ~= false,
        Health = F.statRerollHp ~= false,
        Speed = F.statRerollSpd ~= false,
        Cooldown = F.statRerollCd ~= false,
    }

    statRerollBusy = true
    statRerollStop = false
    pcall(hookStatRerollSkip)

    task.spawn(function()
        local UU = getUnitUpgradesMod()
        local locked = {}
        -- Pre-lock stats already at target OR user doesn't want to roll them
        for _, k in ipairs(STAT_REROLL_KEYS) do
            if not only[k] or letterMeets(unit:GetAttribute(k), target) then
                if not tableHas(locked, k) then locked[#locked + 1] = k end
            end
        end

        local function needCount()
            local n = 0
            for _, k in ipairs(STAT_REROLL_KEYS) do
                if only[k] then n += 1 end
            end
            return n
        end
        local function lockedWanted()
            local n = 0
            for _, k in ipairs(locked) do
                if only[k] then n += 1 end
            end
            return n
        end

        if lockedWanted() >= needCount() then
            notify("Stat Reroll", "Already done: " .. formatUnitLetters(unit), "check")
            statRerollBusy = false
            return
        end

        notify("Stat Reroll", "Start " .. unitRerollLabel(unit) .. " → " .. target, "sparkles-2")
        local rolls = 0
        while rolls < maxRolls and not statRerollStop do
            if lockedWanted() >= needCount() then break end
            if #locked >= #STAT_REROLL_KEYS then break end

            local can, why = true, nil
            if UU and UU.CanReroll then
                local okc, a, b = pcall(function()
                    return UU:CanReroll(LP, unit, locked)
                end)
                if okc then
                    can, why = a, b
                end
            end
            if not can then
                notify("Stat Reroll", tostring(why or "Can't reroll"), "alert-triangle")
                break
            end

            local newStats = applyStatReroll(unit, locked)
            rolls += 1
            if not newStats then
                notify("Stat Reroll", "BuyStatReroll failed", "alert-triangle")
                break
            end

            task.wait(delaySec)
            -- Prefer pending roll letters (server applied via UseNew)
            local letters = readUnitLetters(unit)
            if type(newStats) == "table" then
                for _, k in ipairs(STAT_REROLL_KEYS) do
                    local v = newStats[k]
                    if type(v) == "string" then
                        letters[k] = v
                    end
                end
            end

            local newly = {}
            for _, k in ipairs(STAT_REROLL_KEYS) do
                if only[k] and not tableHas(locked, k) and letterMeets(letters[k], target) then
                    locked[#locked + 1] = k
                    newly[#newly + 1] = STAT_REROLL_LABEL[k] .. "=" .. tostring(letters[k])
                end
            end
            if #newly > 0 then
                notify("Stat Reroll", "Locked " .. table.concat(newly, " · ") .. " | " .. formatUnitLetters(unit), "check")
            elseif rolls % 25 == 0 then
                notify("Stat Reroll", string.format("#%d %s", rolls, formatUnitLetters(unit)), "sparkles-2")
            end
        end

        local msg = statRerollStop and "Stopped" or "Done"
        notify("Stat Reroll", string.format("%s · %d rolls · %s", msg, rolls, formatUnitLetters(unit)), "check")
        statRerollBusy = false
        statRerollStop = false
    end)
end

return {
    listRerollUnits = listRerollUnits,
    unitRerollLabel = unitRerollLabel,
    findUnitByRerollLabel = findUnitByRerollLabel,
    formatUnitLetters = formatUnitLetters,
    hookStatRerollSkip = hookStatRerollSkip,
    runStatRerollBot = runStatRerollBot,
    stop = function()
        statRerollStop = true
    end,
}
end)()

-- ============================================================ CLAIMS (own register pool)
local CLAIM = (function()
local function invokeQuick(name, ...)
    local n = rem(name)
    if not n then
        local folder = ReplicatedStorage:FindFirstChild("Remotes") or ReplicatedStorage:WaitForChild("Remotes", 1)
        n = folder and folder:FindFirstChild(name)
        if n then remoteCache[name] = n end
    end
    if not (n and n:IsA("RemoteFunction")) then return false end
    local args = { ... }
    local done, okRet, a1 = false, false, nil
    task.spawn(function()
        local ok2, r1 = pcall(function() return n:InvokeServer(table.unpack(args)) end)
        okRet, a1, done = ok2, r1, true
    end)
    local t0 = tick()
    while not done and tick() - t0 < 4 do task.wait() end
    return done and okRet, a1
end

local function claimQuestsAll()
    local n = 0
    local p = getProfile()
    local q = p and p:FindFirstChild("Quests")
    if not q then return 0 end
    -- Only active quest folders (not Completed / seeds)
    for _, folderName in ipairs({ "Daily", "Achievement", "Hourly", "Weekly" }) do
        local folder = q:FindFirstChild(folderName)
        if not folder then continue end
        for _, child in ipairs(folder:GetChildren()) do
            local id = child.Name
            local progress = child:GetAttribute("Progress")
            local maxP = nil
            pcall(function()
                local data = require(ReplicatedStorage.Systems.Quests):GetQuestData(id)
                maxP = data and (data.MaxProgress or 1)
            end)
            if typeof(progress) == "number" and typeof(maxP) == "number" and progress < maxP then
                continue
            end
            local okMod = pcall(function()
                require(ReplicatedStorage.Systems.Quests):ClaimQuest(LP, id)
            end)
            if not okMod then invokeQuick("ClaimQuest", id) end
            n += 1
            task.wait(0.05)
        end
    end
    -- Battlepass daily quests
    pcall(function()
        local bpDaily = p:FindFirstChild("Battlepass") and p.Battlepass:FindFirstChild("Daily")
        if not bpDaily then return end
        for _, child in ipairs(bpDaily:GetChildren()) do
            local id = tonumber(child.Name) or child.Name
            local okMod = pcall(function()
                require(ReplicatedStorage.Systems.BattlepassQuests):ClaimQuest(LP, id)
            end)
            if not okMod then invokeQuick("BattlepassClaimQuest", id) end
            n += 1
            task.wait(0.05)
        end
    end)
    return n
end

-- Built-in active codes (GetCodeCache is admin-only). Skip already-claimed via Profile.PromoCodes.
local KNOWN_CODES = {
    "TIDESWEEKTWO", "TIDESEASON", "SUMMERHYPE", "SECRETWEEK", "PACTBREAKER",
    "DIVINEORSERAPH", "RUNELAUNCH", "RUNEHYPE", "HURRYUP", "DIVINE",
    "ULTIMATE", "SUNSET", "MOARSHARD", "DUNGEONZ", "DELAYHEROES",
    "500GEMS", "OOF", "LEGEND",
}

local function claimedCodeSet()
    local set = {}
    local p = getProfile()
    local folder = p and p:FindFirstChild("PromoCodes")
    if folder then
        for _, c in ipairs(folder:GetChildren()) do
            set[string.lower(c.Name)] = true
        end
    end
    return set
end

-- NEVER yield here — used during UI build (InvokeServer breaks CoreGui SetAttribute)
local function listActiveCodes()
    local claimed = claimedCodeSet()
    local active = {}
    for _, code in ipairs(KNOWN_CODES) do
        if not claimed[string.lower(code)] then
            table.insert(active, code)
        end
    end
    table.sort(active)
    return active
end

local function codesStatusText()
    local ok, text = pcall(function()
        local active = listActiveCodes()
        if #active == 0 then return "All known codes claimed (or none left)." end
        local show = {}
        for i = 1, math.min(8, #active) do show[i] = active[i] end
        local extra = #active > 8 and (" +" .. tostring(#active - 8) .. " more") or ""
        return "Unclaimed: " .. table.concat(show, ", ") .. extra
    end)
    return (ok and text) or "Codes ready — Claim All Active"
end

local function claimCodes()
    local active = listActiveCodes()
    local raw = F.codeList or ""
    for code in string.gmatch(raw, "[^,%s\n]+") do
        local up = string.upper(code)
        local found = false
        for _, a in ipairs(active) do
            if a == up then found = true break end
        end
        if not found then table.insert(active, up) end
    end
    local okN = 0
    local claimed = claimedCodeSet()
    for _, code in ipairs(active) do
        local low = string.lower(code)
        if claimed[low] then continue end
        local okFire = false
        pcall(function()
            require(ReplicatedStorage.Systems.PromoCodes):ClaimCode(LP, low)
            okFire = true
        end)
        if not okFire then fire("ClaimCode", low) end
        okN = okN + 1
        -- Server locks ~2s per player; 0.225 spam drops most claims
        task.wait(tonumber(F.codeClaimDelay) or 2.05)
        claimed = claimedCodeSet()
    end
    return okN, active
end

local function claimBattlepass()
    local ok = pcall(function()
        require(ReplicatedStorage.Systems.Battlepass):ClaimAll(LP)
    end)
    if not ok then invokeQuick("BattlepassClaimAll") end
end

local function claimRewards()
    pcall(function()
        require(ReplicatedStorage.Systems.LeaderboardRewards):ClaimRewards()
    end)
    invokeQuick("ClaimRewards")
    invokeQuick("GetPlayerRewards")
    invokeQuick("ClaimLeaderboardReward")
    invokeQuick("ClaimRobloxPrize")
end

local function claimUnitRewards()
    local n = 0
    pcall(function()
        local UnitDex = require(ReplicatedStorage.Systems.UnitDex)
        local rewards = UnitDex:GetAvailableRewards(LP)
        if type(rewards) ~= "table" then return end
        for name in pairs(rewards) do
            UnitDex:ClaimReward(LP, name)
            n += 1
            task.wait(0.05)
        end
    end)
    -- Fallback: only unclaimed entries already in profile UnitDex
    if n == 0 then
        pcall(function()
            local p = getProfile()
            local dex = p and p:FindFirstChild("UnitDex")
            if not dex then return end
            for _, child in ipairs(dex:GetChildren()) do
                if child:GetAttribute("Claimed") then continue end
                invokeQuick("ClaimUnitReward", child.Name)
                n += 1
                task.wait(0.05)
            end
        end)
    end
    return n
end

local function claimWeeklyRunes()
    invokeQuick("GrantWeeklyRuneRewards")
end

local claimAllBusy = false
local function claimAll()
    if claimAllBusy then
        notify("Claim All", "Already running…", "clock")
        return
    end
    claimAllBusy = true
    task.spawn(function()
        local okRun, err = pcall(function()
            notify("Claim All", "Quests…", "sparkles-2")
            local qn = claimQuestsAll()
            notify("Claim All", "Battlepass…", "sparkles-2")
            claimBattlepass()
            notify("Claim All", "Rewards…", "sparkles-2")
            claimRewards()
            notify("Claim All", "Unit Dex…", "sparkles-2")
            local un = claimUnitRewards()
            notify("Claim All", "Weekly runes…", "sparkles-2")
            claimWeeklyRunes()
            notify("Claim All", "Codes…", "ticket")
            local cn = claimCodes()
            notify(
                "Claim All",
                string.format("Done · quests %d · dex %d · codes %d", qn or 0, un or 0, cn or 0),
                "sparkles-2"
            )
        end)
        claimAllBusy = false
        if not okRun then
            notify("Claim All", "Error: " .. tostring(err), "alert-triangle")
        end
    end)
end

loop(function() return F.autoClaimAll == true and not claimAllBusy end, claimAll, function() return F.claimInterval or 90 end)

-- Offline training
local function offlineStart()
    local p = getProfile()
    if not p then notify("Offline", "No profile", "alert-triangle"); return end
    local units = {}
    local inv = p:FindFirstChild("Inventory") and p.Inventory:FindFirstChild("Units")
    local eq = p:FindFirstChild("Equipped")
    local pool = {}
    if eq then for _, u in ipairs(eq:GetChildren()) do table.insert(pool, u) end end
    if inv then for _, u in ipairs(inv:GetChildren()) do table.insert(pool, u) end end
    for _, u in ipairs(pool) do
        if not u:GetAttribute("Busy") then table.insert(units, u) end
        if #units >= 3 then break end
    end
    if #units < 3 then
        notify("Offline", "Need 3 free units", "alert-triangle")
        return
    end
    local ok2, a1, a2 = invoke("StartMission", { Party1 = { units[1], units[2], units[3] } })
    notify("Offline", ok2 and "Started" or tostring(a1 or a2 or "fail"), "clock")
end
local function offlineEnd()
    local ok2, a1 = invoke("EndMission")
    notify("Offline", ok2 and "Claimed" or tostring(a1 or "fail"), "clock")
end

return {
    claimAll = claimAll,
    claimQuestsAll = claimQuestsAll,
    claimBattlepass = claimBattlepass,
    claimRewards = claimRewards,
    claimUnitRewards = claimUnitRewards,
    claimWeeklyRunes = claimWeeklyRunes,
    claimCodes = claimCodes,
    codesStatusText = codesStatusText,
    offlineStart = offlineStart,
    offlineEnd = offlineEnd,
}
end)()

-- ============================================================ LOADOUT + PVP HOP (own register pool)
local LOAD = (function()
local function getUnitsModule()
    local ok, mod = pcall(function() return require(ReplicatedStorage.Systems.Units) end)
    return ok and mod or nil
end
local function getInventoryModule()
    local ok, mod = pcall(function() return require(ReplicatedStorage.Systems.Inventory) end)
    return ok and mod or nil
end

local function ownedUnitPower(unitInst)
    local Units = getUnitsModule()
    if Units and Units.GetUnitPower then
        local ok, pow = pcall(function() return Units:GetUnitPower(unitInst) end)
        if ok and type(pow) == "number" then return pow end
    end
    -- Fallback: rarity × level × stars (if Units API unavailable)
    local data = UNIT_DATA and UNIT_DATA[unitInst.Name]
    local r = data and tonumber(data.Rarity) or 1
    local lv = tonumber(unitInst:GetAttribute("Level")) or 1
    local stars = tonumber(unitInst:GetAttribute("StarCount")) or r
    return r * 1000 + lv * 10 + stars * 50
end

local function equipStrongestUnits()
    if isPvpWorld() and LP:GetAttribute("InPVPMatch") == true then
        notify("Loadout", "Can't change loadout mid PvP match", "alert-triangle")
        return
    end
    local p = getProfile()
    if not p then
        notify("Loadout", "No profile", "alert-triangle")
        return
    end
    local playerLv = 999
    pcall(function() playerLv = p.Level.Value end)
    local Inv = getInventoryModule()
    local equipped = p:FindFirstChild("Equipped")
    local invUnits = p:FindFirstChild("Inventory") and p.Inventory:FindFirstChild("Units")
    if not equipped or not invUnits then
        notify("Loadout", "No inventory", "alert-triangle")
        return
    end

    local function setEquipped(unit, on)
        if not unit then return false end
        local ok = false
        if Inv and Inv.SetUnitEquipped then
            ok = pcall(function() Inv:SetUnitEquipped(LP, unit, on) end)
        end
        if not ok then
            ok = fire("SetUnitEquipped", unit, on) == true
        end
        return ok
    end

    -- Same pool as in-game Equip Best (inventory + equipped)
    local pool = {}
    for _, u in ipairs(invUnits:GetChildren()) do
        if not u:GetAttribute("Busy") then
            local lv = tonumber(u:GetAttribute("Level")) or 1
            if lv <= playerLv then pool[#pool + 1] = u end
        end
    end
    for _, u in ipairs(equipped:GetChildren()) do
        if not u:GetAttribute("Busy") then
            pool[#pool + 1] = u
        end
    end

    local scored = {}
    for _, u in ipairs(pool) do
        scored[#scored + 1] = { u = u, pow = ownedUnitPower(u) }
    end
    table.sort(scored, function(a, b) return a.pow > b.pow end)

    local maxEq = 3
    pcall(function()
        if Inv and Inv.GetMaxEquippedUnits then
            maxEq = math.clamp(tonumber(Inv:GetMaxEquippedUnits()) or 3, 1, 3)
        end
    end)

    -- Want-set like EquipBestClicked (don't unequip-all first — Parent only updates after server)
    local want = {}
    local names = {}
    for i = 1, math.min(maxEq, #scored) do
        local e = scored[i]
        want[e.u] = true
        local data = UNIT_DATA and UNIT_DATA[e.u.Name]
        local dn = data and data.DisplayName or e.u.Name
        names[#names + 1] = string.format("%s (%.0f)", dn, e.pow)
    end
    if #names == 0 then
        notify("Loadout", "No eligible units", "alert-triangle")
        return
    end

    for _, u in ipairs(equipped:GetChildren()) do
        if not want[u] then
            setEquipped(u, false)
            task.wait(0.05)
        end
    end
    local deadline = tick() + 2
    while tick() < deadline do
        local blocking = 0
        for _, u in ipairs(equipped:GetChildren()) do
            if not want[u] then blocking += 1 end
        end
        if blocking == 0 then break end
        task.wait(0.05)
    end

    for u in pairs(want) do
        if u.Parent == invUnits then
            setEquipped(u, true)
            task.wait(0.08)
        end
    end

    deadline = tick() + 2
    while tick() < deadline do
        local n = 0
        for _, u in ipairs(equipped:GetChildren()) do
            if want[u] then n += 1 end
        end
        if n >= #names then break end
        for u in pairs(want) do
            if u.Parent == invUnits then setEquipped(u, true) end
        end
        task.wait(0.1)
    end

    local got = {}
    for _, u in ipairs(equipped:GetChildren()) do
        if want[u] then
            local data = UNIT_DATA and UNIT_DATA[u.Name]
            got[#got + 1] = (data and data.DisplayName) or u.Name
        end
    end
    notify("Loadout", #got > 0 and ("Equipped: " .. table.concat(got, " · ")) or ("Tried: " .. table.concat(names, " · ")), #got > 0 and "check" or "alert-triangle")
end

-- ============================================================ PVP: hop to weakest public servers
local PVP_PLACE_LIVE = 128314954869462
local function resolvePvpPlaceId()
    local id
    pcall(function()
        id = require(ReplicatedStorage.Systems.Queue):GetTeleportPlaceId("PVP")
    end)
    id = tonumber(id)
    if id and id > 0 then return id end
    if PLACE_PVP[game.PlaceId] then return game.PlaceId end
    return PVP_PLACE_LIVE
end

local function findTeleportQueue(placeName)
    local best, bestDist = nil, math.huge
    local root = hrp()
    local pos = root and root.Position
    pcall(function()
        for _, part in ipairs(CollectionService:GetTagged("TeleportQueue")) do
            if part:IsDescendantOf(Workspace) and part:GetAttribute("PlaceName") == placeName then
                if not pos then
                    best = part
                    return
                end
                local d = (part.Position - pos).Magnitude
                if d < bestDist then
                    best, bestDist = part, d
                end
            end
        end
    end)
    return best
end

local function standOnTeleportQueue(placeName)
    local pad = findTeleportQueue(placeName)
    if not pad then return false, "No " .. tostring(placeName) .. " TeleportQueue in this place" end
    local root = hrp()
    if not root then return false, "No character" end
    local h = hum()
    if h then pcall(function() h.Sit = false end) end
    local cf = pad.CFrame + Vector3.new(0, pad.Size.Y * 0.5 + 3, 0)
    root.CFrame = cf
    pcall(function()
        root.AssemblyLinearVelocity = Vector3.zero
        root.AssemblyAngularVelocity = Vector3.zero
    end)
    return true, pad
end

local function httpGetJson(url)
    local body
    local ok = pcall(function() body = game:HttpGet(url) end)
    if (not ok or type(body) ~= "string") and request then
        local r = request({ Url = url, Method = "GET" })
        body = r and r.Body
    end
    if type(body) ~= "string" or #body < 2 then return nil end
    local okj, data = pcall(function() return HttpService:JSONDecode(body) end)
    return okj and data or nil
end

local function fetchPublicServers(placeId, cursor)
    local url = string.format(
        "https://games.roblox.com/v1/games/%d/servers/Public?sortOrder=Asc&excludeFullGames=true&limit=100%s",
        placeId,
        cursor and ("&cursor=" .. HttpService:UrlEncode(tostring(cursor))) or ""
    )
    return httpGetJson(url)
end

local function pickWeakestPvpServer(placeId, maxPlaying)
    maxPlaying = tonumber(maxPlaying) or 6
    local best, bestN = nil, math.huge
    local cursor = nil
    for _ = 1, 5 do
        local data = fetchPublicServers(placeId, cursor)
        if type(data) ~= "table" or type(data.data) ~= "table" then break end
        for _, s in ipairs(data.data) do
            local playing = tonumber(s.playing) or 99
            local maxP = tonumber(s.maxPlayers) or 8
            local job = s.id
            if type(job) == "string" and job ~= game.JobId and playing < bestN and playing < maxP and playing <= maxPlaying then
                best, bestN = job, playing
            end
        end
        cursor = data.nextPageCursor
        if not cursor or bestN <= 1 then break end
    end
    return best, bestN
end

local function tryClientTeleport(placeId, jobId)
    local ts = game:GetService("TeleportService")
    local ok = pcall(function()
        if jobId then
            ts:TeleportToPlaceInstance(placeId, jobId, LP)
        else
            ts:Teleport(placeId, LP)
        end
    end)
    if ok then return true end
    return pcall(function()
        if jobId then
            local opt = Instance.new("TeleportOptions")
            opt.ServerInstanceId = jobId
            ts:TeleportAsync(placeId, { LP }, opt)
        else
            ts:TeleportAsync(placeId, { LP })
        end
    end)
end

local function hopWeakPvpServer()
    task.spawn(function()
        pcall(armTeleportReload)
        local placeId = resolvePvpPlaceId()
        local maxPlaying = tonumber(F.pvpWeakMaxPlayers) or 4

        -- Client TeleportService is blocked ("no valid teleport token"). Enter PvP via game pad.
        if not PLACE_PVP[game.PlaceId] then
            local okPad, why = standOnTeleportQueue("PVP")
            if not okPad then
                notify("PvP", tostring(why), "alert-triangle")
                return
            end
            notify("PvP", "On PVP pad — holding 6s for server countdown", "map-pin")
            for _ = 1, 6 do
                task.wait(1)
                if PLACE_PVP[game.PlaceId] then return end
                standOnTeleportQueue("PVP")
            end
            return
        end

        notify("PvP Hop", "Scanning servers (≤" .. tostring(maxPlaying) .. " players)…", "user")
        local job, n = pickWeakestPvpServer(placeId, maxPlaying)
        if not job then
            job, n = pickWeakestPvpServer(placeId, math.max(maxPlaying, 8))
        end
        if not job then
            notify("PvP Hop", "No weaker public server found", "alert-triangle")
            return
        end
        notify("PvP Hop", string.format("Trying %d-player server…", n), "check")
        if not tryClientTeleport(placeId, job) then
            notify("PvP Hop", "Blocked: no valid teleport token (Roblox requires server teleport)", "alert-triangle")
        end
    end)
end

local function teleportToPvpLobby()
    task.spawn(function()
        pcall(armTeleportReload)
        if PLACE_PVP[game.PlaceId] then
            notify("PvP", "Already in a PvP place", "map-pin")
            return
        end
        local okPad, why = standOnTeleportQueue("PVP")
        if not okPad then
            local placeId = resolvePvpPlaceId()
            notify("PvP", "No pad (" .. tostring(why) .. ") — trying client Teleport…", "alert-triangle")
            if not tryClientTeleport(placeId, nil) then
                notify("PvP", "Teleport blocked (no token). Use the PVP pad in lobby.", "alert-triangle")
            end
            return
        end
        notify("PvP", "On PVP pad — holding 6s for server countdown", "map-pin")
        for _ = 1, 6 do
            task.wait(1)
            if PLACE_PVP[game.PlaceId] then return end
            standOnTeleportQueue("PVP")
        end
    end)
end

return {
    equipStrongestUnits = equipStrongestUnits,
    hopWeakPvpServer = hopWeakPvpServer,
    teleportToPvpLobby = teleportToPvpLobby,
}
end)()

-- ============================================================ MOVEMENT / FREECAM / CHESTS (own register pool)
local MOVE = (function()
local flyBV, flyBG
local function stopFly()
    if flyBV then flyBV:Destroy(); flyBV = nil end
    if flyBG then flyBG:Destroy(); flyBG = nil end
    local h = hum()
    if h then pcall(function() h.PlatformStand = false end) end
end
local function startFly()
    local root = hrp()
    if not root then return end
    stopFly()
    local h = hum()
    if h then pcall(function() h.PlatformStand = true end) end
    flyBV = Instance.new("BodyVelocity")
    flyBV.MaxForce = Vector3.new(9e9, 9e9, 9e9)
    flyBV.Velocity = Vector3.zero
    flyBV.Parent = root
    flyBG = Instance.new("BodyGyro")
    flyBG.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
    flyBG.P = 9000
    flyBG.D = 600
    flyBG.CFrame = root.CFrame
    flyBG.Parent = root
end

RunService.RenderStepped:Connect(function()
    if genv.SH_Session ~= SESSION or not genv.SH_Alive then return end
    if F.flyOn then
        if not flyBV then startFly() end
        local root = hrp()
        if flyBV and flyBG and root then
            local dir = Vector3.zero
            local cf = Camera.CFrame
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then dir += cf.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then dir -= cf.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then dir -= cf.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then dir += cf.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then dir += Vector3.new(0, 1, 0) end
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) or UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then
                dir -= Vector3.new(0, 1, 0)
            end
            if dir.Magnitude > 0 then dir = dir.Unit end
            local vel = dir * (tonumber(F.flySpeed) or 60)
            flyBV.Velocity = vel
            pcall(function()
                root.AssemblyLinearVelocity = vel
            end)
            local look = cf.LookVector
            flyBG.CFrame = CFrame.lookAt(root.Position, root.Position + Vector3.new(look.X, 0, look.Z))
        end
    elseif flyBV then
        stopFly()
    end
end)
LP.CharacterAdded:Connect(function()
    flyBV, flyBG = nil, nil
    if F.flyOn then
        task.defer(function()
            task.wait(0.3)
            if F.flyOn then startFly() end
        end)
    end
end)

local walkWas = false
loop(function() return F.walkSpeedOn == true end, function()
    local h = hum()
    if h then
        h.WalkSpeed = tonumber(F.walkSpeed) or 28
        walkWas = true
    end
end, 0.1)
RunService.Heartbeat:Connect(function()
    if genv.SH_Session ~= SESSION or not genv.SH_Alive then return end
    if not F.walkSpeedOn and walkWas then
        local h = hum()
        if h then h.WalkSpeed = 16 end
        walkWas = false
    end
end)

-- Freecam (camera only; locks mouse + disables player controls)
local freecam = {
    active = false, pos = Vector3.zero, yaw = 0, pitch = 0,
    controls = nil, controlsDisabled = false,
}
local function getPlayerControls()
    if freecam.controls then return freecam.controls end
    local ok, mod = pcall(function()
        local ps = LP:WaitForChild("PlayerScripts", 5)
        local pm = ps and ps:WaitForChild("PlayerModule", 5)
        return pm and require(pm)
    end)
    if ok and mod then freecam.controls = mod:GetControls() end
    return freecam.controls
end
local function freecamEnter()
    if freecam.active then return end
    freecam.active = true
    freecam.pos = Camera.CFrame.Position
    local rx, ry = Camera.CFrame:ToOrientation()
    freecam.pitch, freecam.yaw = rx, ry
    Camera.CameraType = Enum.CameraType.Scriptable
    Camera.CameraSubject = nil
    UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
    UserInputService.MouseIconEnabled = false
    pcall(function() UserInputService.MouseDeltaSensitivity = 1 end)
    local c = getPlayerControls()
    if c and not freecam.controlsDisabled then
        pcall(function() c:Disable() end)
        freecam.controlsDisabled = true
    end
end
local function freecamExit()
    if not freecam.active then return end
    freecam.active = false
    pcall(function()
        Camera.CameraType = Enum.CameraType.Custom
        local h = hum()
        if h then Camera.CameraSubject = h end
        UserInputService.MouseBehavior = Enum.MouseBehavior.Default
        UserInputService.MouseIconEnabled = true
    end)
    local c = getPlayerControls()
    if c and freecam.controlsDisabled then
        pcall(function() c:Enable() end)
        freecam.controlsDisabled = false
    end
end
RunService.RenderStepped:Connect(function(dt)
    if genv.SH_Session ~= SESSION or not genv.SH_Alive then return end
    if F.freecamOn then
        if not freecam.active then freecamEnter() end
        Camera.CameraType = Enum.CameraType.Scriptable
        if UserInputService.MouseBehavior ~= Enum.MouseBehavior.LockCenter then
            UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
        end
        local sens = (F.freecamSensitivity or 0.45) * 0.01
        local delta = UserInputService:GetMouseDelta()
        if delta.Magnitude > 0 then
            freecam.yaw = freecam.yaw - delta.X * sens
            freecam.pitch = math.clamp(freecam.pitch - delta.Y * sens, -math.rad(89), math.rad(89))
        end
        local cf = CFrame.new(freecam.pos) * CFrame.fromEulerAnglesYXZ(freecam.pitch, freecam.yaw, 0)
        local dir = Vector3.zero
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then dir += cf.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then dir -= cf.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then dir -= cf.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then dir += cf.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.E) or UserInputService:IsKeyDown(Enum.KeyCode.Space) then
            dir += Vector3.new(0, 1, 0)
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.Q) or UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
            dir -= Vector3.new(0, 1, 0)
        end
        local speed = tonumber(F.freecamSpeed) or 80
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then speed *= 3 end
        if dir.Magnitude > 0 then freecam.pos = freecam.pos + dir.Unit * speed * dt end
        Camera.CFrame = CFrame.new(freecam.pos) * CFrame.fromEulerAnglesYXZ(freecam.pitch, freecam.yaw, 0)
    elseif freecam.active then
        freecamExit()
    end
end)
LP.CharacterAdded:Connect(function() freecam.controls = nil end)
win:flag("freecamSensitivity", 0.45)

-- Anti AFK
local vu
pcall(function() vu = game:GetService("VirtualUser") end)
if vu then
    LP.Idled:Connect(function()
        if F.antiAfk ~= false then
            vu:CaptureController()
            vu:ClickButton2(Vector2.new())
        end
    end)
end
loop(function() return F.antiAfk ~= false end, function()
    pcall(function()
        local vim = game:GetService("VirtualInputManager")
        if vim then vim:SendKeyEvent(true, Enum.KeyCode.LeftShift, false, game); task.wait(); vim:SendKeyEvent(false, Enum.KeyCode.LeftShift, false, game) end
    end)
end, 60)

-- Chest TP / Auto collect
local function tpChestsAndOpen(fromAuto)
    if chestBusy then return 0 end
    chestBusy = true
    local opened = 0
    local okRun = pcall(function()
        local list = openableChests()
        table.sort(list, function(a, b) return distTo(a.Position) < distTo(b.Position) end)
        local maxN = tonumber(F.chestTpMax) or 0
        if maxN <= 0 then
            maxN = tonumber(ReplicatedStorage:GetAttribute("NumBonusChests")) or #list
            if maxN < 1 then maxN = #list end
        end
        local delay = F.chestTpDelay or 0.45
        for _, part in ipairs(list) do
            if fromAuto and not (F.autoChest or F.chestRetryFarm) then break end
            if opened >= maxN then break end
            local range = tonumber(F.chestTpRange) or 0
            if range > 0 and distTo(part.Position) > range then continue end
            if not isOpenableChest(part) then continue end
            tpTo(part.Position)
            task.wait(0.15)
            if openChestAt(part) then
                opened += 1
            end
            task.wait(delay)
        end
    end)
    chestBusy = false
    if not okRun then return 0 end
    if opened > 0 then noteChestsOpened(opened) end
    -- Instant Retry the moment the pass finishes and nothing openable remains
    if fromAuto and F.chestRetryFarm and opened > 0 and #openableChests() == 0 then
        sawChestsThisMatch = true
        pendingVote = "Retry"
        lastChestFarmVoteAt = tick()
        forceVote("Retry")
    end
    return opened
end

-- Collect all chests → INSTANT Retry (old mid-match Vote abuse — no GameOver wait)
loop(function() return F.chestRetryFarm == true and not isLobby() and not isPvpWorld() end, function()
    if chestBusy then return end
    local left = chestsRemaining()
    if left > 0 then
        sawChestsThisMatch = true
        chestFarmPhase = "collecting"
        local n = tpChestsAndOpen(true)
        if n > 0 then
            chestsLootedThisMatch += n
            notify("Chest Farm", "Opened +" .. n, "archive")
        end
        -- After this pass: if none left → Retry on next tick immediately
        return
    end
    -- Nothing left to open → Retry the second chests are gone
    local num = tonumber(ReplicatedStorage:GetAttribute("NumBonusChests")) or 0
    local readyToRetry = sawChestsThisMatch or chestsLootedThisMatch > 0
        or (gameOverAt > 0 and (num > 0 or tick() - gameOverAt >= 3))
    if not readyToRetry then return end
    if ReplicatedStorage:GetAttribute("RoundEndType") == "Retry" then
        votedThisEnd = true
        return
    end
    if tick() - lastChestFarmVoteAt < 0.2 then return end
    lastChestFarmVoteAt = tick()
    chestFarmPhase = "waiting_vote"
    pendingVote = "Retry"
    forceVote("Retry")
end, 0.2)

loop(function() return F.autoChest == true and not F.chestRetryFarm and not isLobby() and not isPvpWorld() end, function()
    if chestBusy then return end
    if #openableChests() == 0 then return end
    local n = tpChestsAndOpen(true)
    if n > 0 then notify("Chests", "Opened " .. n, "archive") end
end, function() return F.chestAutoInterval or 2 end)

-- Clear opened cache when server clears chests / new room
pcall(function()
    local folder = ReplicatedStorage:FindFirstChild("Remotes")
    local clear = folder and folder:FindFirstChild("ClearClientChests")
    if clear and clear:IsA("RemoteEvent") then
        clear.OnClientEvent:Connect(function()
            openedChests = {}
        end)
    end
end)
CollectionService:GetInstanceAddedSignal("BonusChestPart"):Connect(function(part)
    openedChests[part] = nil
end)

-- SpawnItem (needs Admin — will silently fail without perms)
local function trySpawnItem(name)
    fire("SpawnItem", name)
    notify("SpawnItem", name .. " (needs Admin)", "alert-triangle")
end

return {
    tpChestsAndOpen = tpChestsAndOpen,
    trySpawnItem = trySpawnItem,
}
end)()

-- ============================================================ SOLO FAST (auto special + sweep — own register pool)
local FAST = (function()
local function setAutoOnModel(model, on)
    if not model then return end
    pcall(function() model:SetAttribute("AutoSpecial", on == true) end)
    fire("SetUnitAutoMode", model, on == true)
    pcall(function()
        require(ReplicatedStorage.Systems.Profile):SetUnitAutoMode(LP, model, on == true)
    end)
end

local function forceAutoSpecialTick()
    if F.forceAutoSpecial == false then return end
    -- Lobby: persist on equipped data
    if isLobby() then
        local p = getProfile()
        local eq = p and p:FindFirstChild("Equipped")
        if eq then
            for _, u in ipairs(eq:GetChildren()) do
                if u:GetAttribute("AutoSpecial") ~= true then
                    pcall(function() u:SetAttribute("AutoSpecial", true) end)
                end
            end
        end
        return
    end
    local folder = unitsFolder()
    if not folder then return end
    for _, m in ipairs(folder:GetChildren()) do
        if isOwnUnit(m) and m:GetAttribute("Summon") ~= true then
            if m:GetAttribute("AutoSpecial") ~= true then
                setAutoOnModel(m, true)
            end
        end
    end
end

local function spamSpecialTick()
    if F.spamSpecial ~= true then return end
    if isLobby() or isPvpWorld() then return end
    local folder = unitsFolder()
    if not folder then return end
    local Units
    pcall(function() Units = require(ReplicatedStorage.Systems.Units) end)
    for _, m in ipairs(folder:GetChildren()) do
        if not isOwnUnit(m) then continue end
        if m:GetAttribute("Summon") == true then continue end
        local ready = specialReady(m)
        if not ready then continue end
        if Units and Units.RequestSpecialAttack then
            pcall(function() Units:RequestSpecialAttack(LP, m) end)
        else
            invoke("RequestSpecialAttack", m)
        end
    end
end

local function sweepsLeft()
    local p = getProfile()
    local s = p and p:FindFirstChild("Sweeps")
    return s and tonumber(s.Value) or 0
end

local function doSweep(count)
    count = math.max(1, math.floor(tonumber(count) or 1))
    local left = sweepsLeft()
    if left < 1 then
        notify("Sweep", "No sweeps left today", "alert-triangle")
        return false
    end
    count = math.min(count, left)
    local mapKey, stage = resolveStoryQueue()
    stage = math.floor(tonumber(stage) or 1)
    local okCall, xpOrErr, rewards = pcall(function()
        local Sweeps = require(ReplicatedStorage.Systems.Sweeps)
        return Sweeps:SweepWave(LP, mapKey, stage, count)
    end)
    if not okCall or xpOrErr == nil then
        local ok2, a1, a2 = invoke("SweepWave", mapKey, stage, count)
        okCall, xpOrErr, rewards = ok2, a1, a2
    end
    if okCall and type(xpOrErr) == "number" then
        local coins = type(rewards) == "table" and rewards.Coins or "?"
        local gems = type(rewards) == "table" and rewards.Gems or "?"
        notify("Sweep", string.format("%s S%d ×%d · XP %s · coins %s · gems %s · left %d",
            tostring(mapKey), stage, count, tostring(xpOrErr), tostring(coins), tostring(gems), sweepsLeft()), "bolt")
        return true
    end
    notify("Sweep", "Failed (need cleared stage Lv≥8, sweeps left)", "alert-triangle")
    return false
end

loop(function() return F.forceAutoSpecial ~= false end, forceAutoSpecialTick, 1.2)
loop(function() return F.spamSpecial == true and not isLobby() end, spamSpecialTick, 0.35)
loop(function() return F.soloFastMatch == true and (F.autoReady or F.fullAfkStory or F.autoQueueStory) end, function()
    -- Snappier ready in solo fast mode
    doReady()
end, 0.45)

return {
    forceAutoSpecialTick = forceAutoSpecialTick,
    doSweep = doSweep,
    sweepsLeft = sweepsLeft,
}
end)()

-- ============================================================ INDEX (own register pool — __SH_BOOT__ was at 200 locals)
local IDX = (function()
local RARITY_NAMES = { "Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic", "Secret" }
local RARITY_MULT = { 1, 1, 1, 1.15, 1.35, 1.5, 1.6 }
local function rarityName(r)
    return RARITY_NAMES[tonumber(r) or 0] or ("R" .. tostring(r))
end
local function curveHP(level)
    level = math.clamp(math.floor(tonumber(level) or 1), 1, 200)
    return math.floor(100 * (1.05 ^ (level - 1)))
end
local function curveATK(level)
    return curveHP(level) / 10
end
local LETTER_MULT = { D = 0.9, C = 0.95, B = 1, A = 1.05, S = 1.1, X = 1.2 }
local STAR_MULT = { 0.8, 0.9, 1, 1.1, 1.2, 1.3, 1.4, 1.5, 1.6, 1.7 }

local function unitPowerDetailed(data, level, stars, letter)
    local r = tonumber(data.Rarity) or 1
    local rm = RARITY_MULT[r] or 1
    local sm = STAR_MULT[math.clamp(math.floor(tonumber(stars) or 5), 1, 10)] or 1.2
    local lm = LETTER_MULT[letter or "B"] or 1
    local hp = curveHP(level) * sm * (tonumber(data.Health) or 1) * lm * rm
    local atk = curveATK(level) * sm * lm * rm
    return math.floor(hp + 0.5), math.floor(atk + 0.5), sm, lm, rm
end

local function unitPowerAt(data, level)
    local hp, atk = unitPowerDetailed(data, level, 5, "B")
    return hp, atk
end

-- Official in-game power (Units:GetUnitPower) at a fair roll — NOT AttackCooldown kit hacks.
-- power = ATK*10*(Speed/10)*(1+CR*CDMG)*(1+(1-CD)*0.5) + HP*2*(1+Evade)
-- Bare unit (no trait/rune/gear/shiny): CR=0, CDMG=1, Evade=0, letter CD = 2-letterMult.
-- Curves.MAX_LEVEL = 200
local function computeGamePower(data, level, stars, letter)
    if type(data) ~= "table" then return 0 end
    level = math.clamp(math.floor(tonumber(level) or 200), 1, 200)
    stars = math.clamp(math.floor(tonumber(stars) or 5), 1, 10)
    letter = letter or "B"
    local r = tonumber(data.Rarity) or 1
    local rm = RARITY_MULT[r] or 1
    local sm = STAR_MULT[stars] or 1.2
    local lm = LETTER_MULT[letter] or 1
    local hp = curveHP(level) * sm * (tonumber(data.Health) or 1) * lm * rm
    local atk = curveATK(level) * sm * lm * rm
    local spd = (tonumber(data.Speed) or 10) * lm
    local cd = (2 - lm) -- Curves.Cooldown(letter)
    local cr, cdmg, evade = 0, 1, 0
    local power = atk * 10 * (spd / 10) * (1 + cr * cdmg) * (1 + (1 - cd) * 0.5) + hp * 2 * (1 + evade)
    return power, hp, atk, spd, cd
end

-- Clear-speed score: GetUnitPower ignores kit CD/range; raw ATK/AC also lies —
-- some units ship AttackCooldown 0.1 (Tank Commander) = animation quirk, not DPS.
-- Floor AC at 1s, soft-cap long ranges, keep HP light (tanks ≠ practical clear).
local function computeCombatScore(data, level, stars, letter)
    local pow, hp, atk, spd = computeGamePower(data, level, stars, letter)
    if not pow or pow <= 0 then return 0, 0, 0, 0 end
    local acRaw = tonumber(data.AttackCooldown) or 2
    local ac = math.clamp(math.max(acRaw, 1), 1, 6)
    local sc = math.clamp(tonumber(data.SpecialCooldown) or 10, 5, 28)
    local ar = math.clamp(tonumber(data.AttackRange) or 5, 1, 40)
    local sr = math.clamp(tonumber(data.SpecialRange) or 8, 1, 80)
    local flee = math.clamp(tonumber(data.FleeRange) or 0, 0, 30)
    local r = tonumber(data.Rarity) or 1

    local auto = atk / ac
    local srSoft = 1 + math.min(sr, 28) / 55 + math.max(0, sr - 28) / 220
    local special = (atk * srSoft) / sc
    local arSoft = 1 + math.min(ar, 20) / 50
    local move = 1 + math.max(0, ((spd or 10) - 10) / 24) * 0.22
    local kite = (flee >= 10) and 1.05 or 1

    local offense = (auto * 1.2 + special * 1.6) * arSoft * move * kite
    local sustain = hp * 0.1
    local rarityBoost = 1 + math.max(-0.08, (r - 4) * 0.055)
    return (offense + sustain) * rarityBoost, pow, offense, sustain
end

local function dumpUnitDataFields(data)
    local skip = { Icon = true }
    local keys = {}
    for k, v in pairs(data) do
        if not skip[k] and type(v) ~= "function" and type(v) ~= "table" then
            keys[#keys + 1] = k
        end
    end
    table.sort(keys)
    local parts = {}
    for _, k in ipairs(keys) do
        local v = data[k]
        if type(v) == "boolean" then
            parts[#parts + 1] = k .. "=" .. (v and "true" or "false")
        elseif type(v) == "number" then
            parts[#parts + 1] = string.format("%s=%s", k, tostring(v))
        else
            parts[#parts + 1] = k .. "=" .. tostring(v)
        end
    end
    return table.concat(parts, " · ")
end

local function formatUnitDetail(e, rank, total)
    if not e or not e.data then return "No unit." end
    local d = e.data
    local lim = e.lim and " · Limited (event/craft)" or ""
    local craft = e.craft and " · Secret forge" or ""
    local own = e.owned and " · OWNED" or " · locked"
    local nick = d.Nickname and (" · nick " .. tostring(d.Nickname)) or ""
    local flee = d.FleeRange and (" · Flee " .. tostring(d.FleeRange)) or ""
    local stars = e.stars or 5
    local score = e.score or select(1, computeCombatScore(d, 200, stars, "B"))
    local pow1 = select(1, computeGamePower(d, 1, stars, "B"))
    local pow50, hp50, atk50, spd50 = computeGamePower(d, 50, stars, "B")
    local pow100, hp100, atk100 = computeGamePower(d, 100, stars, "B")
    local pow200, hp200, atk200, spd200 = computeGamePower(d, 200, stars, "B")
    local powMax, hpMax, atkMax = computeGamePower(d, 200, 10, "X")
    local _, _, smStar, lmB, rm = unitPowerDetailed(d, 1, stars, "B")
    local tier
    if score >= 2.2e6 then tier = "S+ kit"
    elseif score >= 1.6e6 then tier = "S strong"
    elseif score >= 1.1e6 then tier = "A solid"
    elseif score >= 0.7e6 then tier = "B mid"
    else tier = "C weak" end
    return string.format(
        "#%d/%d %s%s%s%s%s\n%s · Type %s · %s\n—— INDEX SCORE (kit-aware) ——\nCombat %.0f  ← rank uses this\n= auto DPS (ATK/AC) + special (ATK×reach/SC) + HP sustain\nAC %.2g · SC %.2g · AR %s · SR %s · Spd %s%s\nATK: %s\nSP: %s\n—— GAME POWER (GetUnitPower, bare — ignores kit CD/range) ——\n★%d/B: Lv1 %.0f · Lv50 %.0f · Lv100 %.0f · Lv200 %.0f\nMax ★10/X Lv200: %.0f\n@Lv200 ★%d/B: %dHP · %dATK · Spd %.1f\n—— Multipliers ——\nRarity×%.2f · ★%d×%.2f · letter B×%.2f\n—— All ItemData fields ——\n%s",
        rank, total, e.n, lim, craft, own, nick,
        rarityName(e.r), e.t, tier,
        score,
        e.cd, e.scd, tostring(e.ar), tostring(e.sr), tostring(e.spd), flee,
        e.ad ~= "" and e.ad or "(none)", e.sd ~= "" and e.sd or "(none)",
        stars, pow1, pow50, pow100, pow200, powMax,
        stars, math.floor(hp200 + 0.5), math.floor(atk200 + 0.5), spd200,
        rm, stars, smStar, lmB,
        dumpUnitDataFields(d)
    )
end

-- Gear tiers from dump (passives + base stats). Stat % × rank(D–X 1–2) × lvl(1–5 → 1–2.3).
local INDEX_GEAR = {
    { id = "PactboundToken", n = "Pactbound Token", r = 7, arch = "Universal", tier = "S",
        stats = "ATK 6% · HP 6% · EVADE 4% · CR 4% · CDMG 6%",
        pas = "Binding Oath — redirect 30% dmg to higher-HP ally else reflect 5% (L5)" },
    { id = "HeartOfTheColossus", n = "Heart of the Colossus", r = 6, arch = "Ward", tier = "S",
        stats = "HP 12%", pas = "Unbreakable — same-enemy hits reduce dmg taken up to 15% (L5)" },
    { id = "RendsBlade", n = "Rending Blade", r = 6, arch = "Talon", tier = "S",
        stats = "ATK 12%", pas = "Worldsplitter — +20% vs higher-%HP foes (L5)" },
    { id = "HertzsWildcard", n = "Hertz's Wildcard", r = 5, arch = "Fang", tier = "S",
        stats = "ATK 10%", pas = "Wild Draw — 30% chance to cast special twice (L5)" },
    { id = "TheSleeplessEye", n = "The Sleepless Eye", r = 6, arch = "Fang", tier = "A",
        stats = "CR 4.8% · CDMG 7.2%", pas = "Vigil — crits mark enemy +7.5% dmg taken 8s (L5)" },
    { id = "DeadeyeFang", n = "Deadeye Fang", r = 5, arch = "Fang", tier = "A",
        stats = "CR 4% · CDMG 6%", pas = "Deadeye — first hit always crit; stacks up to +10% CR (L5)" },
    { id = "FoxfireCharm", n = "Foxfire Charm", r = 5, arch = "Ward", tier = "A",
        stats = "HP 2.5% · EVADE 7.5%", pas = "Foxfire Veil — after evade, next attack +30% dmg (L5)" },
    { id = "Scorchknot", n = "Scorchknot", r = 4, arch = "Talon", tier = "C",
        stats = "ATK 6%", pas = "No passive — solid mid ATK filler" },
    { id = "GildedCharm", n = "Gilded Charm", r = 4, arch = "Ward", tier = "C",
        stats = "HP 6%", pas = "No passive — mid HP filler" },
    { id = "SnipersScope", n = "Sniper's Scope", r = 4, arch = "Fang", tier = "C",
        stats = "CR 2.4% · CDMG 3.6%", pas = "No passive — mid crit filler" },
    { id = "TwinstarCharm", n = "Twinstar Charm", r = 4, arch = "Ward", tier = "C",
        stats = "HP 1.5% · EVADE 4.5%", pas = "No passive — mid evade filler" },
    { id = "JadeIdol", n = "Jade Idol", r = 3, arch = "Talon", tier = "C",
        stats = "ATK 4%", pas = "No passive — early ATK" },
    { id = "IronCharm", n = "Iron Charm", r = 3, arch = "Ward", tier = "D",
        stats = "HP 4%", pas = "Weak — sell / fodder" },
    { id = "QuickPendant", n = "Quick Pendant", r = 3, arch = "Ward", tier = "D",
        stats = "HP 1% · EVADE 3%", pas = "Weak — sell / fodder" },
    { id = "SwiftBand", n = "Swift Band", r = 3, arch = "Fang", tier = "D",
        stats = "CR 1.6% · CDMG 2.4%", pas = "Weak — sell / fodder" },
    { id = "TinBand", n = "Tin Band", r = 2, arch = "Talon", tier = "D",
        stats = "ATK 2%", pas = "Bad — recycle" },
    { id = "WhiteFeather", n = "White Feather", r = 2, arch = "Fang", tier = "D",
        stats = "CR 0.8% · CDMG 1.2%", pas = "Bad — recycle" },
    { id = "StonePendant", n = "Stone Pendant", r = 2, arch = "Ward", tier = "D",
        stats = "HP 0.5% · EVADE 1.5%", pas = "Bad — recycle" },
    { id = "WovenCharm", n = "Woven Charm", r = 2, arch = "Ward", tier = "D",
        stats = "HP 2%", pas = "Bad — recycle" },
}

-- Rune tiers = combat role priority, NOT "best at everything".
-- S = raw clear speed (DPS). A = strong secondary (sustain / tank / AoE). Heal ≠ kill faster.
local INDEX_RUNES = {
    { id = "Chrono", n = "Chrono Rune", tier = "S",
        desc = "Unit's attacks are sped up (higher attack rate).",
        up = "ATK SPD ×1.3 → ×1.7",
        note = "S DPS: more hits/sec = more damage + more specials. Carry BiS" },
    { id = "Burn", n = "Burn Rune", tier = "S",
        desc = "Hits apply abyss burn DoT — enemy takes damage over time each tick.",
        up = "Burn 3s/0.1 → 10s/0.25 (tick every 0.5s)",
        note = "S DoT: free extra damage on every hit. Great on multi-hit / AoE" },
    { id = "Boom", n = "Boom Rune", tier = "A",
        desc = "Projectiles create larger explosions.",
        up = "AoE radius ×1.4 → ×1.8", note = "A AoE: bigger splash, not single-target DPS" },
    { id = "Vampiric", n = "Vampiric Rune", tier = "A",
        desc = "% of damage dealt returns as healing (lifesteal).",
        up = "Lifesteal 10% → 20%",
        note = "A sustain: keeps unit alive — does NOT raise DPS like Chrono/Burn" },
    { id = "Giant", n = "Giant Rune", tier = "A",
        desc = "Makes units larger & have more HP.",
        up = "Scale ×1.2→×1.6 · HP +10%→+50%", note = "A tank HP" },
    { id = "Angelic", n = "Angelic Rune", tier = "B",
        desc = "Occasionally put up a shield when hit.",
        up = "Invuln 0.5→2s · CD 20→12s", note = "B tank proc — slower than Giant" },
    { id = "Shadow", n = "Shadow Rune", tier = "B",
        desc = "Units are less likely to be targeted.",
        up = "Avoid target 40% → 80%", note = "B peel for glass cannons" },
    { id = "Focus", n = "Focus Rune", tier = "B",
        desc = "Units target summoned units less often.",
        up = "Skip summons 20% → 100%", note = "B vs summon waves" },
    { id = "Warp", n = "Warp Rune", tier = "B",
        desc = "Units warp directly to their enemies.",
        up = "Warp CD 15s → 7s", note = "B melee gap-close" },
    { id = "Golden", n = "Golden Rune", tier = "C",
        desc = "Enemies drop more gold on defeat.",
        up = "Coins +10% → +35%", note = "C farm only — skip for combat/PvP" },
}

-- Traits from Systems.Units.Traits. Roll via Trait Reroll. HP/DMG/SPD % add to base; CD % shrinks cooldown (power + specials).
local INDEX_TRAITS = {
    { id = "Ultimate", n = "Ultimate", tier = "S", r = 6, drop = 0.1,
        stats = "DMG +100%",
        desc = "Corrupted power, stolen from Summonia itself.",
        icon = "rbxassetid://115415178130784",
        note = "BiS power — double ATK. Chase this" },
    { id = "Divine", n = "Divine", tier = "S", r = 6, drop = 0.5,
        stats = "DMG +50% · CD −20% · SPD +10%",
        desc = "Divine power, summoned from a higher realm.",
        icon = "rbxassetid://112607321178950",
        note = "Near-BiS: huge ATK + faster specials + speed" },
    { id = "Rampage", n = "Rampage", tier = "A", r = 5, drop = 1,
        stats = "DMG +30% · SPD +10%",
        desc = "This unit hits hard and hits fast.",
        icon = "rbxassetid://131403230191039",
        note = "Best Legendary DPS trait" },
    { id = "Overclocked", n = "Overclocked", tier = "A", r = 5, drop = 1,
        stats = "CD −22% · SPD +20%",
        desc = "Time moves faster for this unit.",
        icon = "rbxassetid://121809027431883",
        note = "Special spam + move speed (no raw ATK)" },
    { id = "Berserker", n = "Berserker", tier = "A", r = 4, drop = 7.5,
        stats = "DMG +20% · HP −8%",
        desc = "Reduced HP but greater strength.",
        icon = "rbxassetid://136260306816624",
        note = "Strong cheap DPS if unit can survive" },
    { id = "Titan", n = "Titan", tier = "B", r = 5, drop = 1,
        stats = "HP +22% · CD −5%",
        desc = "This unit has a major health boost.",
        icon = "rbxassetid://132184412031438",
        note = "Tank / HP power — not carry DPS" },
    { id = "Godspeed", n = "Godspeed", tier = "B", r = 4, drop = 7.5,
        stats = "CD −15%",
        desc = "This unit can use their special even faster.",
        icon = "rbxassetid://120272112393181",
        note = "Special CD only" },
    { id = "Brutal", n = "Brutal", tier = "B", r = 3, drop = nil,
        stats = "DMG +12%",
        desc = "This unit deals more damage.",
        icon = "rbxassetid://107110349616966",
        note = "Solid early DPS until better" },
    { id = "Sprinter", n = "Sprinter", tier = "B", r = 4, drop = 7.5,
        stats = "SPD +16%",
        desc = "Rolling around at the speed of sound!",
        icon = "rbxassetid://115718372739298",
        note = "Move speed — mild power bump" },
    { id = "Vanguard", n = "Vanguard", tier = "C", r = 4, drop = 7.5,
        stats = "HP +16%",
        desc = "This unit is armored for combat.",
        icon = "rbxassetid://107626360044866",
        note = "HP only — filler" },
    { id = "Nimble", n = "Nimble", tier = "C", r = 3, drop = nil,
        stats = "CD −8%",
        desc = "This unit can use their special more often.",
        icon = "rbxassetid://77722839091971",
        note = "Small special CD" },
    { id = "Sturdy", n = "Sturdy", tier = "C", r = 3, drop = nil,
        stats = "HP +12%",
        desc = "This unit has more health.",
        icon = "rbxassetid://107626360044866",
        note = "Small HP" },
    { id = "Swift", n = "Swift", tier = "C", r = 3, drop = nil,
        stats = "SPD +10%",
        desc = "This unit can run faster!",
        icon = "rbxassetid://89322369616608",
        note = "Small move speed" },
}

local function buildUnitIndex()
    local src = UNIT_DATA
    if type(src) ~= "table" then return {} end
    local list = {}
    if type(src) ~= "table" then return list end
    -- Same set as in-game UnitDex: every Unlockable unit (Limited / SecretForged included).
    for id, data in pairs(src) do
        if type(data) ~= "table" or data.Unlockable ~= true or type(data.DisplayName) ~= "string" then
            continue
        end
        local lim = data.Limited == true
        local craft = data.SecretForged == true
        -- Fair compare: ★5/B. Secret forge always rolls ★7 — use that for craft secrets.
        local stars = craft and 7 or 5
        local score, pow = computeCombatScore(data, 200, stars, "B")
        list[#list + 1] = {
            id = id,
            n = data.DisplayName,
            icon = (type(data.Icon) == "string" and data.Icon ~= "" and data.Icon) or "user",
            t = data.Type or "?",
            r = tonumber(data.Rarity) or 1,
            hp = tonumber(data.Health) or 1,
            spd = tonumber(data.Speed) or 10,
            cd = tonumber(data.AttackCooldown) or 1,
            ar = tonumber(data.AttackRange) or 1,
            scd = tonumber(data.SpecialCooldown) or 1,
            sr = tonumber(data.SpecialRange) or 1,
            ad = data.AttackDesc or "",
            sd = data.SpecialDesc or "",
            lim = lim,
            craft = craft,
            stars = stars,
            data = data,
            s = score,
            score = score,
            pow = pow,
        }
    end
    -- Weak → strong by kit-aware combat score (not raw GetUnitPower / not rarity-only).
    table.sort(list, function(a, b)
        if a.score == b.score then
            if a.r ~= b.r then return a.r < b.r end
            return a.n < b.n
        end
        return a.score < b.score
    end)
    return list
end

local function formatGearDetail(g)
    if not g then return "No gear." end
    local verdict = ({ S = "KEEP / BiS", A = "Strong — keep", C = "Filler until better", D = "Sell / recycle" })[g.tier] or "?"
    return string.format(
        "[%s] %s · %s · %s\n%s\n%s\nUpgrade: rank D→X (×1–2) · level 1→5 (×1–2.3). Max ≈ base×4.6\nVerdict: %s",
        g.tier, g.n, rarityName(g.r), g.arch, g.stats, g.pas, verdict
    )
end

local function formatRuneDetail(r)
    if not r then return "No rune." end
    local verdict = ({ S = "Priority upgrade", A = "Great pick", B = "Situational", C = "Farm only / skip combat" })[r.tier] or "?"
    return string.format(
        "[%s] %s\n%s\nUpgrades T1→T5: %s\n%s\nUpgrade cost: 2 same-tier copies + 1000 Gems (max T5)\nVerdict: %s",
        r.tier, r.n, r.desc, r.up, r.note or "", verdict
    )
end

local function formatTraitDetail(t)
    if not t then return "No trait." end
    local verdict = ({ S = "Keep / chase", A = "Strong keep", B = "OK until better", C = "Reroll" })[t.tier] or "?"
    local drop = t.drop and string.format("%.1f%%", t.drop) or "~common pool"
    return string.format(
        "[%s] %s · %s\n%s\n%s\nDrop: %s\nVerdict: %s\nReroll with Trait Rerolls (shop / PvP).",
        t.tier, t.n, rarityName(t.r), t.stats or "", t.desc or "", drop, verdict
    )
end

local function isUnitCollected(unitId)
    -- Profile folder only — never require() here (yield mid-UI build kills the window).
    if type(unitId) ~= "string" or unitId == "" then return false end
    local p = getProfile()
    local dex = p and p:FindFirstChild("UnitDex")
    local v = dex and dex:FindFirstChild(unitId)
    if not v then return false end
    local n = tonumber(v.Value)
    return n == nil or n > 0
end

-- Only units unlocked in your UnitDex (summoned/crafted at least once).
local function buildOwnedUnitIndex()
    local out = {}
    for _, e in ipairs(buildUnitIndex()) do
        if isUnitCollected(e.id) then
            out[#out + 1] = e
        end
    end
    for i, e in ipairs(out) do
        e._rank = i
    end
    return out
end

local function formatUnitRankList(list, strongFirst, limit)
    if not list or #list == 0 then
        return "(units data not loaded)"
    end
    local lines = {}
    local n = #list
    limit = math.clamp(math.floor(tonumber(limit) or 25), 5, n)
    local function line(rank, e)
        local tags = ""
        if e.owned then tags = tags .. " ·OWN" end
        if e.craft then tags = tags .. " ·Craft" end
        if e.lim then tags = tags .. " ·Lim" end
        local acShow = math.max(tonumber(e.cd) or 1, 1)
        return string.format(
            "#%d  %s · %s · %s%s · SCR %.0f · AC%.2g/SR%s",
            rank, e.n, rarityName(e.r), tostring(e.t), tags, e.score or e.pow or 0,
            acShow, tostring(e.sr or "?")
        )
    end
    if strongFirst then
        for rank = 1, limit do
            lines[#lines + 1] = line(rank, list[n - rank + 1])
        end
    else
        for i = 1, limit do
            lines[#lines + 1] = line(i, list[i])
        end
    end
    if n > limit then
        lines[#lines + 1] = string.format("… +%d more (pick in dropdown)", n - limit)
    end
    return table.concat(lines, "\n")
end

-- Annotate owned flags (UnitDex) without filtering — Index shows EVERYONE.
local function annotateOwned(list)
    for _, e in ipairs(list) do
        e.owned = isUnitCollected(e.id)
    end
    return list
end

local function itemIcon(_folder, _id, fallback)
    -- Never require() while the window is building (yield → empty sidebar).
    return fallback or "diamond"
end

return {
    rarityName = rarityName,
    buildUnitIndex = buildUnitIndex,
    buildOwnedUnitIndex = buildOwnedUnitIndex,
    annotateOwned = annotateOwned,
    isUnitCollected = isUnitCollected,
    formatUnitRankList = formatUnitRankList,
    formatOwnedRankList = formatUnitRankList, -- alias
    formatUnitDetail = formatUnitDetail,
    formatGearDetail = formatGearDetail,
    formatRuneDetail = formatRuneDetail,
    formatTraitDetail = formatTraitDetail,
    itemIcon = itemIcon,
    GEAR = INDEX_GEAR,
    RUNES = INDEX_RUNES,
    TRAITS = INDEX_TRAITS,
}
end)()

-- ============================================================ UI
-- Separate proto so tab builders don't compete with helper locals for registers.
local function __SH_UI__()
if not stillThisBoot() then return end
if not createWindow() then
    error("UI.new failed")
end
-- One failed tab must not abort the rest (re-exec used to leave a half-empty window).
local function tabOk(name, fn)
    local ok, err = pcall(fn)
    if not ok then
        warn("[SH] UI " .. name .. ": " .. tostring(err))
        pcall(function()
            win:notify({
                title = "UI " .. name,
                text = tostring(err):sub(1, 140),
                icon = "alert-triangle",
                duration = 8,
            })
        end)
    end
    return ok
end
-- Icons must exist in the library's ICON_DATA. Missing names = blank icon.
tabOk("Visuals", function()
local tVis = win:tab({ name = "Visuals", icon = "eye", group = "Main", subtitle = "ESP and world" })
do
    local s = tVis:sub("ESP")
    local ec = s:card({ title = "Enemy Unit ESP", icon = "bone", column = "left" })
    tog(ec, "Enabled", "enemyEsp", true)
    tog(ec, "Names", "enemyEspName", true)
    tog(ec, "HP", "enemyEspHp", true)
    tog(ec, "Distance", "enemyEspDist", true)
    tog(ec, "Chams", "enemyEspChams", true)
    tog(ec, "ESP in PvP arenas", "pvpEsp", false, "high")
    tog(ec, "PvP Chams (very laggy)", "pvpEspChams", false, "high")
    ec:label("PvP arenas: ESP fully off unless enabled. Damage enhance also disabled there.")
    colorFlag(ec, "Color", "enemyEspColor", 255, 90, 90, true)
    colorFlag(ec, "Boss Color", "bossEspColor", 255, 200, 60, true)

    local oc = s:card({ title = "Own Unit ESP", icon = "heart", column = "right" })
    tog(oc, "Enabled", "ownEsp", false)
    tog(oc, "HP", "ownEspHp", true)
    tog(oc, "Special CD", "ownEspSpecial", true)
    tog(oc, "Auto Mode", "ownEspAuto", false)
    tog(oc, "Distance", "ownEspDist", false)
    tog(oc, "Chams", "ownEspChams", false)
    colorFlag(oc, "Color", "ownEspColor", 80, 220, 120, true)

    local s2 = tVis:sub("World")
    local cc = s2:card({ title = "Chest ESP", icon = "archive", column = "left" })
    tog(cc, "Enabled", "chestEsp", false)
    tog(cc, "Show Name", "chestEspName", true)
    tog(cc, "Chams", "chestEspChams", true)
    colorFlag(cc, "Color", "chestEspColor", 255, 210, 90, true)
    cc:label("Shows chest / pad name. Distance removed.")

    local wc = s2:card({ title = "World / Camera", icon = "world", column = "right" })
    tog(wc, "Fullbright", "fullbright", false)
    slider(wc, "Brightness", "fbBrightness", 1, 10, 3, 1)
    tog(wc, "No Fog", "noFog", false)
    tog(wc, "No Camera Shake", "noShake", true)
    tog(wc, "FOV Unlock", "fovUnlock", false)
    slider(wc, "FOV", "fovAmt", 60, 120, 90, 0)
    tog(wc, "Damage Numbers Enhance", "dmgEnhance", true)
    slider(wc, "Dmg Scale", "dmgScale", 1, 4, 1.8, 1)
    tog(wc, "Dmg Bold", "dmgBold", true)
end
end)

tabOk("Farm", function()
local tFarm = win:tab({ name = "Farm", icon = "bolt", group = "Main", subtitle = "Ready, vote, AFK, queue" })
    local s = tFarm:sub("Match")
    local rc = s:card({ title = "Auto Ready", icon = "player-play", column = "left" })
    tog(rc, "Enabled", "autoReady", true)
    slider(rc, "Interval", "readyInterval", 0.3, 5, 1.0, 1)
    rc:label("Ready during intermission (Waves / Endless / AFK).")

    local sc = s:card({ title = "Skip Cutscenes", icon = "bolt", column = "right" })
    tog(sc, "Enabled", "skipCutscene", true)
    sc:label("Clicks to skip cutscenes + dialogue. Does not press Space (no jump).")

    local sk = s:card({ title = "Tower Skip doors", icon = "gauge", column = "right" })
    tog(sk, "Take Skip doors", "towerPreferSkip", true)
    sk:label("Infinite Tower: if a Skip door appears, the bot enters it (floor jump). Off = ignore that door.")

    local sf = s:card({ title = "Solo Fast", icon = "bolt", column = "left" })
    tog(sf, "Solo Fast Match", "soloFastMatch", true)
    tog(sf, "Force Auto Special", "forceAutoSpecial", true)
    tog(sf, "Spam Special (when ready)", "spamSpecial", false, "medium")
    sf:label("Can't speed server waves. This: auto special + faster Ready/Vote. Sweep skips cleared stages.")
    slider(sf, "Sweep count", "sweepCount", 1, 10, 1, 0)
    sf:button("Sweep story target now", function()
        task.spawn(function()
            FAST.doSweep(F.sweepCount or 1)
        end)
    end)
    sf:button("Show sweeps left", function()
        notify("Sweep", "Left today: " .. tostring(FAST.sweepsLeft()), "list")
    end)

    local sVote = tFarm:sub("Vote")
    local vc = sVote:card({ title = "Auto Vote", icon = "check", column = "left" })
    tog(vc, "Vote Retry", "autoVoteRetry", false)
    tog(vc, "Vote Next", "autoVoteNext", false)
    tog(vc, "Vote Lobby", "autoVoteLobby", false)
    local mg, ms = win:flag("voteMode", "Retry")
    vc:dropdown("Vote Mode (priority)", { "Retry", "Next", "Lobby" }, mg, ms)
    slider(vc, "Vote Interval", "voteInterval", 0.5, 6, 1.2, 1)
    slider(vc, "Delay after end", "voteDelayAfterEnd", 0.5, 12, 2, 1)
    vc:label("Votes via Vote remote only (won't hide Retry/Next buttons).")

    local s2 = tFarm:sub("Loops")
    local qc = s2:card({ title = "Auto Queue Story", icon = "map-pin", column = "left" })
    tog(qc, "Enabled", "autoQueueStory", false, "medium")
    tog(qc, "Auto Launch", "autoQueueLaunch", true)
    tog(qc, "Use Current Progress", "storyAdaptive", true)
    qc:label("Lobby queue + RoundEnd: loss→Retry Stage, win→Next. Then re-queue adaptive.")
    -- MAP_KEYS only — mapList() requires WaveData and yields mid-tab (empty window).
    local maps = MAP_KEYS
    local mapg, maps_ = win:flag("storyMap", maps[1] or "RookieIsland")
    qc:dropdown("Manual Map", maps, mapg, maps_, { search = true })
    local stg, sts = win:flag("storyStage", 1)
    qc:slider("Manual Stage", 1, 6, stg, sts, 0)
    slider(qc, "Queue Interval", "queueInterval", 3, 20, 5, 0)
    qc:button("Queue Adaptive Now", function()
        local mk, st = getAdaptiveStoryTarget()
        local ok2, err = setStoryQueue(mk, st)
        notify("Queue", ok2 and (mk .. " #" .. st) or tostring(err), ok2 and "check" or "alert-triangle")
    end)
    qc:button("Queue Manual Now", function()
        local ok2, err = setStoryQueue(F.storyMap or "RookieIsland", F.storyStage or 1)
        notify("Queue", ok2 and "OK" or tostring(err), ok2 and "check" or "alert-triangle")
    end)

    local ac = s2:card({ title = "AFK Waves Farm", icon = "clock", column = "right" })
    tog(ac, "Enabled", "afkWavesFarm", false, "medium")
    local ag, as_ = win:flag("afkVoteMode", "Lobby")
    ac:dropdown("After rewards vote", { "Lobby", "Retry", "None" }, ag, as_)
    ac:label("No stage levels in AFK Waves — just start + vote.")

    local tw = s2:card({ title = "Infinite Tower", icon = "gauge", column = "left" })
    tog(tw, "Take Skip doors", "towerPreferSkip", true)
    tog(tw, "Auto Queue Tower", "autoQueueTower", false, "medium")
    slider(tw, "Queue interval", "towerQueueInterval", 4, 20, 6, 0)
    slider(tw, "Difficulty index", "towerDifficulty", 1, 4, 1, 0)
    togBind(tw, "Tower Bot", "towerBot", false, "T", "medium")
    tw:label("Skip door = floor jump. On = bot always enters it. Merchant shops still follow Tower Bot settings.")
    tw:button("Queue Tower Now", function()
        local ok2, err = queueTower()
        notify("Tower", ok2 and "OK" or tostring(err), ok2 and "check" or "alert-triangle")
    end)

    local en = s2:card({ title = "Endless Circus", icon = "bolt", column = "right" })
    tog(en, "Auto Queue Endless", "autoQueueEndless", false, "medium")
    tog(en, "Respect entry limit", "endlessRespectEntries", true)
    slider(en, "Stage index", "endlessStage", 1, 6, 1, 0)
    slider(en, "Queue interval", "endlessQueueInterval", 5, 30, 8, 0)
    local eg, es = win:flag("endlessVoteMode", "Retry")
    en:dropdown("After end vote", { "Retry", "Lobby", "None" }, eg, es)
    en:label("Retry only if entries left — else auto Lobby (avoids freeze).")
    en:button("Start Endless Now", function()
        local ok2, err = queueEndlessCircus()
        notify("Endless", ok2 and ("OK · entries " .. getEndlessEntries()) or tostring(err), ok2 and "check" or "alert-triangle")
    end)

    local pri = tFarm:sub("Tower Bot")
    local pc = pri:card({ title = "Door priority", icon = "list", column = "left" })
    tog(pc, "Take Skip doors", "towerPreferSkip", true)
    pc:label("If a Skip door is up, take it first. Then Elite/Chest/… from the list.")
    win:flag("towerDoorOrder", { "Elite", "Chest", "Merchant", "Healing", "Mystery", "Recruit", "Combat" })
    getDoorOrder() -- migrate old slider / 6-slot configs
    local slotNames = { "1st pick", "2nd pick", "3rd pick", "4th pick", "5th pick", "6th pick", "7th pick" }
    for slot = 1, 7 do
        pc:dropdown(slotNames[slot], DOOR_ORDER_OPTIONS, function()
            local o = getDoorOrder()
            return DOOR_ORDER_LABEL[o[slot]] or DOOR_ORDER_OPTIONS[slot]
        end, function(label)
            local key = DOOR_LABEL_TO_KEY[label]
            if key then setDoorOrderSlot(slot, key) end
            win:refreshAll()
        end)
    end
    pc:button("Reset default order", function()
        F.towerDoorOrder = { "Elite", "Chest", "Merchant", "Healing", "Mystery", "Recruit", "Combat" }
        win:markDirty()
        win:refreshAll()
        notify("Tower Bot", "Priority reset", "list")
    end)
    local rc = pri:card({ title = "Recruit pick", icon = "user", column = "right" })
    local rg, rs = win:flag("towerRecruitMode", "Rarity")
    rc:dropdown("Prefer", { "Rarity", "Ranged" }, rg, rs)
    rc:label("Rarity = highest rarity. Ranged = highest AttackRange.")

    local mc = pri:card({ title = "Merchant shop", icon = "sparkles-2", column = "right" })
    tog(mc, "Enter Merchant doors", "towerEnterMerchant", true)
    tog(mc, "Skip unit heal", "towerSkipShopHeal", true)
    tog(mc, "Skip revive / respawn", "towerSkipShopRevive", true)
    local sg, ss = win:flag("towerShopPrefer", "Combat")
    mc:dropdown("Buy prefer", { "Combat", "Rarity" }, sg, ss)
    slider(mc, "Keep at least coins", "towerShopMinCoins", 0, 20000, 0, 0)
    mc:label("Buys ATK / Crit / Boss / SPD. Never Heal or Revive unless you turn those skips off. HP% boost is a stat, not heal.")

    local sRoll = tFarm:sub("Stat Reroll")
    local rollCard = sRoll:card({ title = "Auto lock to letter", icon = "sparkles-2", column = "left" })
    do
        local labels = {}
        local units = STATR.listRerollUnits()
        for i, u in ipairs(units) do
            labels[#labels + 1] = STATR.unitRerollLabel(u, i)
        end
        if #labels == 0 then labels[1] = "(no units)" end
        local ug, us = win:flag("statRerollUnitLabel", labels[1])
        rollCard:dropdown("Unit", labels, ug, function(v)
            us(v)
            F.statRerollUnitLabel = v
            win:markDirty()
        end)
        rollCard:label("Re-exec script to refresh unit dropdown after inventory changes.")
    end
    local tg, ts = win:flag("statRerollTarget", "X")
    rollCard:dropdown("Lock when ≥", { "X", "S", "A", "B" }, tg, function(v)
        ts(v)
        F.statRerollTarget = v
        win:markDirty()
    end)
    tog(rollCard, "Skip roll animation", "statRerollSkip", true)
    tog(rollCard, "Roll ATK", "statRerollAtk", true)
    tog(rollCard, "Roll HP", "statRerollHp", true)
    tog(rollCard, "Roll SPD", "statRerollSpd", true)
    tog(rollCard, "Roll CD", "statRerollCd", true)
    slider(rollCard, "Max rolls", "statRerollMax", 50, 2000, 400, 0)
    slider(rollCard, "Delay (s)", "statRerollDelay", 0.05, 0.5, 0.12, 2)
    rollCard:label("Rerolls → UseNew (no cinematic) → locks each hit. Cost 100+300×locks.")
    rollCard:button("Start auto reroll", function()
        pcall(STATR.hookStatRerollSkip)
        STATR.runStatRerollBot()
    end)
    rollCard:button("Stop", function()
        STATR.stop()
        notify("Stat Reroll", "Stopping…", "alert-triangle")
    end)
    rollCard:button("Show current letters", function()
        local u = STATR.findUnitByRerollLabel(F.statRerollUnitLabel)
        if not u then
            notify("Stat Reroll", "Pick a unit", "alert-triangle")
            return
        end
        notify("Stat Reroll", STATR.unitRerollLabel(u) .. " · " .. STATR.formatUnitLetters(u), "list")
    end)

    local fc = s2:card({ title = "Full AFK Story Clear", icon = "puzzle", column = "left" })
    tog(fc, "Enabled", "fullAfkStory", false, "medium")
    fc:label("Ready + skip cutscenes + vote (win→Next, loss→Retry) + adaptive re-queue.")

    local fh = s2:card({ title = "Farm Stats", icon = "gauge", column = "right" })
    do
        local g, s = win:flag("farmHud", true)
        fh:toggle("Show Session HUD", g, function(v)
            s(v)
            applyHudVisibility(true)
        end)
    end
    do
        local g, s = win:flag("waveHud", true)
        fh:toggle("Show Match HUD", g, function(v)
            s(v)
            applyHudVisibility(true)
        end)
    end
    do
        local g, s = win:flag("indexHud", true)
        fh:toggle("Show Index HUD", g, function(v)
            s(v)
            applyHudVisibility(true)
        end)
    end
    fh:label("Also controllable from Settings → Panels.")
    fh:button("Equip strongest 3", function()
        task.spawn(LOAD.equipStrongestUnits)
    end)
    fh:button("Reset Farm Stats", function()
        farm.coinsEarned, farm.gemsEarned, farm.essenceEarned = 0, 0, 0
        farm.pvpTokensEarned = 0
        farm.runs, farm.chestsOpened = 0, 0
        farm.chestCoins, farm.chestGems = 0, 0
        farm.pendingChestCoins, farm.pendingChestGems = 0, 0
        farm.startedAt = os.time()
        farm.lastCoins, farm.lastGems = getCurrency("Coins"), getCurrency("Gems")
        farm.lastEssence = getCurrency("Essence")
        farm.lastPvpTokens = getCurrency("PVPTokens")
        genv.SH_Farm = farm
        flushFarmDisk()
        notify("Farm", "Stats reset", "adjustments")
    end)
end)

tabOk("Gear", function()
local tGear = win:tab({ name = "Gear", icon = "diamond", group = "Main", subtitle = "Gear sell + PvP shop" })
    local s = tGear:sub("Gear")
    local gFast = s:card({ title = "Gear Machine", icon = "zap", column = "right" })
    tog(gFast, "Fast open (skip gauge anim)", "fastGearSummon", true)
    tog(gFast, "Auto-close rewards popup", "fastGearRewards", false)
    gFast:label("Skips LobbyMap stick/gauge cinematic. Rewards still grant normally.")
    gFast:button("Re-hook now", function()
        gearSummonHooked = false
        notify("Gear", hookFastGearSummon() and "Hooked" or "Gui not ready", "zap")
    end)

    local g2 = s:card({ title = "Auto Gear Sell", icon = "trash", column = "left" })
    tog(g2, "Sync to game settings", "syncAutoGearSell", false)
    -- RarityNames: 1=Common 2=Uncommon 3=Rare 4=Epic — AutoGearSell uses 2/3/4
    tog(g2, "Sell Uncommon", "autoGearSellR2", false)
    tog(g2, "Sell Rare", "autoGearSellR3", false)
    tog(g2, "Sell Epic", "autoGearSellR4", false)
    g2:label("Same as in-game Auto Gear Sell rarity toggles (on summon).")
    g2:button("Apply once", function()
        fire("SetConfig", "AutoGearSell_Rarity2", F.autoGearSellR2 == true)
        fire("SetConfig", "AutoGearSell_Rarity3", F.autoGearSellR3 == true)
        fire("SetConfig", "AutoGearSell_Rarity4", F.autoGearSellR4 == true)
        notify("Gear", "AutoGearSell synced", "check")
    end)

    local gRec = s:card({ title = "Quick Recycle", icon = "trash", column = "left" })
    win:flag("recycleMaxRarity", 4)
    local rg, rs = win:flag("recycleMaxRarityLabel", "Epic (4)")
    gRec:dropdown("Max rarity to junk", {
        "Common (1)", "Uncommon (2)", "Rare (3)", "Epic (4)", "Legendary (5)",
    }, rg, function(v)
        rs(v)
        local n = tonumber(tostring(v):match("%((%d+)%)")) or 4
        F.recycleMaxRarity = n
        win:flag("recycleMaxRarity", n)
        win:markDirty()
    end)
    win:flag("recycleKeepMinRank", "A")
    local kg, ks = win:flag("recycleKeepMinRankLabel", "A+")
    gRec:dropdown("Keep rank ≥", { "B+", "A+", "S+", "X only", "None" }, kg, function(v)
        ks(v)
        local map = { ["B+"] = "B", ["A+"] = "A", ["S+"] = "S", ["X only"] = "X", None = "Z" }
        F.recycleKeepMinRank = map[v] or "A"
        win:markDirty()
    end)
    tog(gRec, "Keep leveled (Lv>1)", "recycleKeepLeveled", true)
    tog(gRec, "Keep Index S/A names", "recycleKeepNamed", true)
    tog(gRec, "Auto recycle in lobby", "autoRecycleGear", false)
    slider(gRec, "Auto min count", "autoRecycleMinCount", 1, 18, 6, 0)
    slider(gRec, "Auto interval (s)", "autoRecycleInterval", 10, 120, 20, 0)
    gRec:label("One click — skips BiS names, high ranks, leveled. Batches of 18.")
    gRec:button("Recycle junk now", function()
        notify("Recycle", "Candidates: " .. tostring(countRecycleCandidates()), "trash")
        quickRecycleGear()
    end)
    gRec:button("Count only", function()
        notify("Recycle", "Would recycle: " .. tostring(countRecycleCandidates()), "list")
    end)

    local sPvp = tGear:sub("PvP Shop")
    local pc = sPvp:card({ title = "Auto Buy", icon = "ticket", column = "left" })
    tog(pc, "Enabled", "pvpShopAutoBuy", false, "medium")
    tog(pc, "Buy all stock of match", "pvpBuyAllStock", true)
    pc:label("Buys when items appear / refresh (every ~10 min). Needs PVP Tokens.")
    tog(pc, "Trait Reroll", "pvpBuyTraitReroll", true)
    tog(pc, "Summon Ticket", "pvpBuySummonTicket", true)
    tog(pc, "Legendary Fusion Crystal", "pvpBuyLegendaryCrystal", true)
    tog(pc, "Epic Fusion Crystal", "pvpBuyEpicCrystal", false)
    tog(pc, "Rare Fusion Crystal", "pvpBuyRareCrystal", false)
    tog(pc, "Food (Cupcake / Boba / …)", "pvpBuyFood", false)
    pc:button("Buy now", function()
        task.spawn(function()
            if pvpBuyBusy then
                notify("PvP Shop", "Already buying…", "ticket")
                return
            end
            lastPvpBuyAt = 0
            pvpBuyBusy = true
            pcall(autoBuyPvpShopPass, true)
            pvpBuyBusy = false
            lastPvpBuyAt = tick()
            local v = getCurrency("PVPTokens")
            notify("PvP Shop", "Pass done · tokens " .. (v ~= nil and tostring(v) or "-"), "ticket")
        end)
    end)
    -- Static text only — never call getRotatingShops/require while building UI (yield → Plugin error).
    pc:label("Max 3 buys / pass · poll 5s. Buy all stock spreads across passes.")
end)

tabOk("Claims", function()
local tClaim = win:tab({ name = "Claims", icon = "trophy", group = "Main", subtitle = "Quests, BP, codes" })
    local s = tClaim:sub("Claims")
    local c = s:card({ title = "One-click", icon = "sparkles-2", column = "left" })
    c:button("Claim All", CLAIM.claimAll)
    c:button("Claim Quests", function()
        task.spawn(function()
            notify("Quests", tostring(CLAIM.claimQuestsAll()), "sparkles-2")
        end)
    end)
    c:button("Battlepass Claim", CLAIM.claimBattlepass)
    c:button("Claim Rewards", CLAIM.claimRewards)
    c:button("Claim Unit Dex", CLAIM.claimUnitRewards)
    c:button("Weekly Rune Rewards", CLAIM.claimWeeklyRunes)
    tog(c, "Auto Claim All (loop)", "autoClaimAll", false)
    slider(c, "Claim Interval (s)", "claimInterval", 30, 300, 90, 0)

    local c2 = s:card({ title = "Codes / Offline", icon = "ticket", column = "right" })
    c2:label(CLAIM.codesStatusText())
    c2:button("Refresh Code List", function()
        notify("Codes", CLAIM.codesStatusText(), "ticket")
    end)
    c2:button("Claim All Active Codes", function()
        task.spawn(function()
            local n, list = CLAIM.claimCodes()
            notify("Codes", "Sent " .. tostring(n) .. " / " .. tostring(list and #list or 0), "ticket")
            notify("Codes", CLAIM.codesStatusText(), "ticket")
        end)
    end)
    win:flag("codeList", "")
    c2:input("Extra codes (optional)", "CODE1,CODE2", function() return F.codeList or "" end, function(v) F.codeList = v; win:markDirty() end)
    c2:label("Claims unclaimed known codes (~2s each — server lock). Extra field optional.")
    c2:button("Offline Training Start", CLAIM.offlineStart)
    c2:button("Offline Training End", CLAIM.offlineEnd)
end)

tabOk("Index", function()
local tIdx = win:tab({ name = "Index", icon = "book", group = "Main", subtitle = "All units, gear, runes" })
    local rarityName = IDX.rarityName
    local buildUnitIndex = IDX.buildUnitIndex
    local annotateOwned = IDX.annotateOwned
    local formatUnitRankList = IDX.formatUnitRankList
    local formatUnitDetail = IDX.formatUnitDetail
    local formatGearDetail = IDX.formatGearDetail
    local formatRuneDetail = IDX.formatRuneDetail
    local formatTraitDetail = IDX.formatTraitDetail
    local INDEX_GEAR = IDX.GEAR
    local INDEX_RUNES = IDX.RUNES
    local INDEX_TRAITS = IDX.TRAITS

    local unitNames, unitByLabel = {}, {}
    local setRankList, setCount, setUnitInfo, us
    local unitList

    local function rebuildUnitPickLists(list)
        for k in pairs(unitNames) do unitNames[k] = nil end
        for k in pairs(unitByLabel) do unitByLabel[k] = nil end
        for i, e in ipairs(list) do
            local tags = ""
            if e.owned then tags = tags .. " ·OWN" end
            if e.craft then tags = tags .. " ·Craft" end
            if e.lim then tags = tags .. " ·Lim" end
            local label = string.format(
                "%02d. %s · SCR %.0f · AC%.2g/SR%s (%s)%s",
                i, e.n, e.score or 0, e.cd or 0, tostring(e.sr or "?"), rarityName(e.r), tags
            )
            unitNames[i] = label
            unitByLabel[label] = e
            e._rank = i
        end
        if #unitNames == 0 then
            unitNames[1] = "(units data not loaded)"
        end
    end
    do
        local okAll, allOrErr = pcall(function()
            return annotateOwned(buildUnitIndex())
        end)
        unitList = (okAll and allOrErr) or {}
    end
    rebuildUnitPickLists(unitList)
    task.defer(function()
        if genv.SH_Session ~= SESSION then return end
        pcall(function()
            loadUnitData()
            unitList = annotateOwned(buildUnitIndex()) or {}
            rebuildUnitPickLists(unitList)
            if setRankList then setRankList(formatUnitRankList(unitList, true, 20)) end
            if setCount then setCount(string.format("%d units · clear score @ Lv200", #unitList)) end
            local pick = unitNames[#unitNames] or unitNames[1]
            if us then us(pick) end
            local e = unitByLabel[pick]
            if setUnitInfo then
                setUnitInfo(formatUnitDetail(e, e and e._rank or 0, #unitList))
            end
        end)
    end)

    local sU = tIdx:sub("Units")
    local rankCard = sU:card({ title = "Clear top · kit score", icon = "list", column = "left" })
    rankCard:label("SCR = clear speed (ATK/AC≥1s + special + soft range). HP light. AC<1s floored (data quirks).")
    do
        local _, set = rankCard:label(formatUnitRankList(unitList, true, 20))
        setRankList = set
    end
    rankCard:button("Refresh owned tags", function()
        pcall(loadUnitData)
        unitList = annotateOwned(buildUnitIndex())
        rebuildUnitPickLists(unitList)
        if setRankList then setRankList(formatUnitRankList(unitList, true, 20)) end
        if setCount then setCount(string.format("%d units · clear score @ Lv200", #unitList)) end
        local pick = unitNames[#unitNames] or unitNames[1]
        if us then us(pick) end
        local e = unitByLabel[pick]
        if setUnitInfo then
            setUnitInfo(formatUnitDetail(e, e and e._rank or 0, #unitList))
        end
        win:refreshAll()
        notify("Index", #unitList .. " units (all unlockable)", "book")
    end)

    local uc = sU:card({ title = "Unit detail", icon = "user", column = "left" })
    do
        local _, set = uc:label(string.format("%d units · clear score @ Lv200", #unitList))
        setCount = set
    end
    local ug
    ug, us = win:flag("indexUnitPick", unitNames[#unitNames] or unitNames[1])
    do
        local e0 = unitByLabel[ug()]
        local _, set = uc:label(formatUnitDetail(e0, e0 and e0._rank or 0, #unitList))
        setUnitInfo = set
    end
    uc:dropdown("Unit", unitNames, ug, function(v)
        us(v)
        local e = unitByLabel[v]
        if setUnitInfo then
            setUnitInfo(formatUnitDetail(e, e and e._rank or 0, #unitList))
        end
        win:markDirty()
    end, { search = true })

    local tip = sU:card({ title = "How power works", icon = "gauge", column = "right" })
    tip:label("Rank = clear-speed score @ Lv200 (★5/B, Secret forge ★7).")
    tip:label("Subs above: Units · Gear · Runes · Traits. HUD mirrors S/A lists.")
    tip:label("ATK/max(AC,1s) + special. HP barely counts. AC<1s floored.")

    local load = sU:card({ title = "Loadout", icon = "check", column = "right" })
    load:button("Equip strongest 3", function()
        task.spawn(LOAD.equipStrongestUnits)
    end)
    load:label("Live GetUnitPower on owned inventory (real rolls).")

    local hudCard = sU:card({ title = "Index HUD", icon = "layout-dashboard", column = "right" })
    do
        local g, s = win:flag("indexHud", true)
        hudCard:toggle("Show Index HUD", g, function(v)
            s(v)
            applyHudVisibility(true)
        end)
    end
    slider(hudCard, "Top units on HUD", "indexHudTopN", 4, 10, 6, 0)
    hudCard:label("Units only on HUD. Gear/Runes/Traits → Index tabs. Restart after top-N.")

    local sG = tIdx:sub("Gear")
    local gearNames, gearByLabel = {}, {}
    for i, g in ipairs(INDEX_GEAR) do
        local label = string.format("[%s] %s", g.tier, g.n)
        gearNames[i] = label
        gearByLabel[label] = g
    end
    local glist = sG:card({ title = "Gear BiS / keep (S–A)", icon = "diamond", column = "left" })
    for _, g in ipairs(INDEX_GEAR) do
        if g.tier == "S" or g.tier == "A" then
            glist:label(string.format("[%s] %s · %s · %s", g.tier, g.n, g.arch or "?", g.stats or ""))
            if g.pas and g.pas ~= "" and not string.find(g.pas, "No passive", 1, true) then
                glist:label("  → " .. g.pas)
            end
        end
    end
    local gc = sG:card({ title = "Gear detail", icon = "list", column = "right" })
    local gg, gs = win:flag("indexGearPick", gearNames[1])
    local _, setGearInfo = gc:label(formatGearDetail(gearByLabel[gg()]))
    gc:dropdown("Gear", gearNames, gg, function(v)
        gs(v)
        if setGearInfo then setGearInfo(formatGearDetail(gearByLabel[v])) end
        win:markDirty()
    end, { search = true })
    gc:label("S = BiS · A = keep · C/D in dropdown. Passives at L3/L5.")

    local sR = tIdx:sub("Runes")
    local runeNames, runeByLabel = {}, {}
    for i, r in ipairs(INDEX_RUNES) do
        local label = string.format("[%s] %s", r.tier, r.n)
        runeNames[i] = label
        runeByLabel[label] = r
    end
    local rlist = sR:card({ title = "Rune priority", icon = "sparkles-2", column = "left" })
    for _, r in ipairs(INDEX_RUNES) do
        local short = (r.n or ""):gsub(" Rune$", "")
        rlist:label(string.format("[%s] %s · %s", r.tier, short, r.note or r.up or ""))
    end
    rlist:label("Upgrade: 2 same tier + 1000 Gems → next T (max T5).")
    local rc = sR:card({ title = "Rune detail", icon = "list", column = "right" })
    local rg, rs = win:flag("indexRunePick", runeNames[1])
    local _, setRuneInfo = rc:label(formatRuneDetail(runeByLabel[rg()]))
    rc:dropdown("Rune", runeNames, rg, function(v)
        rs(v)
        if setRuneInfo then setRuneInfo(formatRuneDetail(runeByLabel[v])) end
        win:markDirty()
    end)

    local sT = tIdx:sub("Traits")
    local traitNames, traitByLabel = {}, {}
    for i, t in ipairs(INDEX_TRAITS) do
        local label = string.format("[%s] %s", t.tier, t.n)
        traitNames[i] = label
        traitByLabel[label] = t
    end
    local tlist = sT:card({ title = "Trait priority", icon = "sparkles-2", column = "left" })
    for _, t in ipairs(INDEX_TRAITS) do
        tlist:label(string.format("[%s] %s · %s · %s", t.tier, t.n, t.stats or "", t.note or ""))
    end
    tlist:label("Reroll = Trait Rerolls. Drop % from Traits module (commons share leftover pool).")
    local tc = sT:card({ title = "Trait detail", icon = "list", column = "right" })
    local tg, ts = win:flag("indexTraitPick", traitNames[1])
    local _, setTraitInfo = tc:label(formatTraitDetail(traitByLabel[tg()]))
    tc:dropdown("Trait", traitNames, tg, function(v)
        ts(v)
        if setTraitInfo then setTraitInfo(formatTraitDetail(traitByLabel[v])) end
        win:markDirty()
    end)
    tc:label("S = chase · A = keep · B = mid · C = reroll. Affects live GetUnitPower.")
end)

tabOk("World", function()
local tWorld = win:tab({ name = "World", icon = "map-pin", group = "Player", subtitle = "Chests, spawn, PvP hop" })
    local s = tWorld:sub("Chests")
    local c = s:card({ title = "Auto Chests", icon = "archive", column = "left" })
    tog(c, "Auto Collect Chests", "autoChest", false)
    tog(c, "Chest → Retry Loop", "chestRetryFarm", false, "medium")
    c:label("Loot all chests → Instant Retry (mid-match OK).")
    slider(c, "Auto Interval", "chestAutoInterval", 1, 8, 1.2, 1)
    slider(c, "Max Chests (0=all)", "chestTpMax", 0, 30, 0, 0)
    slider(c, "Delay", "chestTpDelay", 0.15, 2, 0.45, 2)
    slider(c, "Max Range (0=inf)", "chestTpRange", 0, 2000, 0, 0)
    c:label("Opens only unopened chests. 0 max = use NumBonusChests / all left.")
    local bg, bs = win:flag("chestTpKeys", { "C" })
    c:keybind("TP Chests Bind", bg, bs, {
        multi = true, listName = "TP Chests",
        callback = function()
            task.spawn(function()
                local n = MOVE.tpChestsAndOpen(false)
                notify("Chests", "Opened " .. tostring(n), "archive")
            end)
        end,
    })
    c:button("TP + Open Now", function()
        task.spawn(function()
            local n = MOVE.tpChestsAndOpen(false)
            notify("Chests", "Opened " .. tostring(n), "archive")
        end)
    end)

    local sPvp = tWorld:sub("PvP")
    local pc = sPvp:card({ title = "Weak PvP servers", icon = "user", column = "left" })
    slider(pc, "Max players (prefer)", "pvpWeakMaxPlayers", 1, 12, 4, 0)
    pc:label("Scans Roblox public servers for this PvP place, joins the emptiest ≤ max.")
    pc:button("Hop to weakest PvP server", LOAD.hopWeakPvpServer)
    pc:button("Teleport to PvP place", LOAD.teleportToPvpLobby)
    pc:label("Uses lobby PVP TeleportQueue (server TP). Client Teleport is token-blocked by Roblox.")

    local pl = sPvp:card({ title = "Loadout", icon = "user", column = "right" })
    pl:button("Equip strongest 3 units", function()
        task.spawn(LOAD.equipStrongestUnits)
    end)
    pl:label("Same flow as in-game Equip Best via SetUnitEquipped.")

    local sp = s:card({ title = "SpawnItem", icon = "alert-triangle", column = "right" })
    win:flag("spawnItemName", "Coin")
    sp:input("Item Name", "Coin", function() return F.spawnItemName or "Coin" end, function(v) F.spawnItemName = v; win:markDirty() end)
    sp:button("Spawn (needs Admin)", function() MOVE.trySpawnItem(F.spawnItemName or "Coin") end)
    sp:label("Without Admin perms this does nothing.")
end)

tabOk("Movement", function()
local tMov = win:tab({ name = "Movement", icon = "user", group = "Player", subtitle = "Speed, fly, freecam" })
    local s = tMov:sub("Move")
    local c = s:card({ title = "Movement", icon = "gauge", column = "left" })
    togBind(c, "WalkSpeed", "walkSpeedOn", false, "V")
    slider(c, "Speed", "walkSpeed", 16, 120, 28, 0)
    togBind(c, "Fly", "flyOn", false, "F")
    slider(c, "Fly Speed", "flySpeed", 20, 200, 60, 0)
    togBind(c, "Freecam", "freecamOn", false, "G")
    slider(c, "Freecam Speed", "freecamSpeed", 20, 250, 80, 0)
    tog(c, "Anti-AFK", "antiAfk", true)
end)

tabOk("Settings", function()
local _, settingsPage = win:settingsTab({
    subtitle = "Window, panels, theme, type, configs",
})
do
    local reloadCard = settingsPage:card({
        title = "Teleport Reload",
        icon = "bolt",
        subtitle = "Auto-exec on lobby ↔ waves ↔ PvP",
        column = "left",
    })
    win:flag("scriptUrl", genv.SH_ScriptUrl or readLoaderUrlDisk() or "")
    reloadCard:input("Loader URL", "https://... (Luarmor / raw)", function()
        return F.scriptUrl or ""
    end, function(v)
        F.scriptUrl = v
        if type(v) == "string" and #v > 8 then
            saveScriptUrl(v)
        end
        win:markDirty()
    end)
    reloadCard:label("URL → NewReality/SummonHeroes/loader-url.txt. Arms once (no stack).")
    reloadCard:label("Teleport only — cold join needs Autoexec / manual run. Set URL → Arm once.")
    reloadCard:button("Arm Teleport Reload", function()
        if F.scriptUrl and #F.scriptUrl > 8 then
            saveScriptUrl(F.scriptUrl)
        end
        -- Allow re-queue only when URL changed (clears armed marker first)
        local url = resolveScriptUrl()
        if url and genv.SH_ArmedUrl ~= url then
            teleportArmed = false
            genv.SH_TeleportArmed = nil
            genv.SH_ArmedUrl = nil
        end
        local ok2 = armTeleportReload(true)
        local why = "Set Loader URL first"
        if not ok2 then
            if not resolveScriptUrl() then
                why = "No Loader URL"
            else
                why = "No queue_on_teleport on this executor"
            end
        end
        notify("Teleport", ok2 and ("Armed · " .. tostring(resolveScriptUrl())) or why, ok2 and "check" or "alert-triangle")
    end)

    local layoutCard = settingsPage:card({
        title = "HUD layout",
        icon = "layout-dashboard",
        subtitle = "Manual save only",
        column = "right",
    })
    layoutCard:label("1) Drag HUDs  2) Press this Save  3) Re-exec. Saves into config + hud-layout.json")
    layoutCard:button("Save HUD positions", function()
        local fn = genv.SH_SaveHudLayout
        if type(fn) ~= "function" then
            notify("Layout", "Save fn missing", "alert-triangle")
            return
        end
        local ok, err = fn()
        if ok then
            local n = 0
            if type(F.hudLayout) == "table" then
                for _ in pairs(F.hudLayout) do n += 1 end
            end
            notify("Layout", "Saved " .. tostring(n) .. " panels", "check")
        else
            notify("Layout", "Fail: " .. tostring(err or "?"), "alert-triangle")
        end
    end)
end
end)

-- ============================================================ FINALIZE
-- 1) loadConfig once → flags + _overlayPos
-- 2) spawn overlays (they pick saved spots from _overlayPos)
-- 3) re-apply saved spots exactly after layout (no second loadConfig / no clamp rewrite)
-- Never saveConfig on boot — that used to overwrite good positions with mid-layout junk.
local function trimAutoName(s)
    if type(s) ~= "string" then return nil end
    s = s:gsub("^%s+", ""):gsub("%s+$", "")
    if s == "" then return nil end
    return s
end

local autoName = trimAutoName(win:getAutoLoad()) or "default"
tabOk("HUD", function()
pcall(function()
    win:loadConfig(autoName)
end)
-- Keep lib overlay positions from config; also F.hudLayout from flags.
-- Do NOT wipe _overlayPos — that killed restores.
if F.farmHud == nil then F.farmHud = true end
if F.waveHud == nil then F.waveHud = true end
if F.indexHud == nil then F.indexHud = true end
if F.indexHudTopN == nil then F.indexHudTopN = 6 end
pcall(function() win._dirty = false end)

wm = win:watermark({ show = { logo = true, brand = true, fps = true, time = true } })
kb = win:keybindList({ showInactive = true, width = 168, title = "Binds" })

-- Session + Match HUDs (Settings → Panels + Farm Stats toggles)
sessionHud = win:hud({
    title = "Session",
    icon = "gauge",
    width = 248,
    position = UDim2.new(1, -264, 0, 80),
    id = "session",
    interval = 0.35,
    visible = F.farmHud ~= false,
})
sessionHud:section("Wallet")
sessionHud:row({ icon = "coin-pound", label = "Coins", value = function()
    local v = getCurrency("Coins")
    return v ~= nil and fmtNum(v) or "-"
end })
sessionHud:row({ icon = "diamond", label = "Gems", value = function()
    local v = getCurrency("Gems")
    return v ~= nil and fmtNum(v) or "-"
end })
sessionHud:row({ icon = "sparkles-2", label = "Essence", value = function()
    local v = getCurrency("Essence")
    return v ~= nil and fmtNum(v) or "-"
end })
sessionHud:row({ icon = "ticket", label = "PvP Coins", value = function()
    local v = getCurrency("PVPTokens")
    return v ~= nil and fmtNum(v) or "-"
end })
sessionHud:section("Session +")
sessionHud:row({ icon = "coin-pound", label = "Coins +", value = function()
    local elapsed = math.max(1, os.time() - (farm.startedAt or os.time()))
    local n = farm.coinsEarned or 0
    return fmtNum(n) .. " · " .. fmtRate(n / (elapsed / 3600))
end })
sessionHud:row({ icon = "diamond", label = "Gems +", value = function()
    local elapsed = math.max(1, os.time() - (farm.startedAt or os.time()))
    local n = farm.gemsEarned or 0
    return fmtNum(n) .. " · " .. fmtRate(n / (elapsed / 3600))
end })
sessionHud:row({ icon = "sparkles-2", label = "Essence +", value = function()
    local elapsed = math.max(1, os.time() - (farm.startedAt or os.time()))
    local n = farm.essenceEarned or 0
    return fmtNum(n) .. " · " .. fmtRate(n / (elapsed / 3600))
end })
sessionHud:row({ icon = "ticket", label = "PvP Coins +", value = function()
    local elapsed = math.max(1, os.time() - (farm.startedAt or os.time()))
    local n = farm.pvpTokensEarned or 0
    return fmtNum(n) .. " · " .. fmtRate(n / (elapsed / 3600))
end })
sessionHud:section("Farm")
sessionHud:row({ icon = "bolt", label = "Runs", value = function() return farm.runs or 0 end })
sessionHud:row({ icon = "archive", label = "Chests", value = function() return farm.chestsOpened or 0 end })
sessionHud:row({ icon = "ticket", label = "Endless entries", value = function() return getEndlessEntries() end })
sessionHud:row({
    label = "Tower bot",
    icon = "bolt",
    dot = function() return F.towerBot == true end,
    value = function() return F.towerBot and "On" or "Off" end,
})

matchHud = win:hud({
    title = "Match",
    icon = "bone",
    width = 220,
    position = UDim2.new(0, 16, 0, 80),
    id = "match",
    interval = 0.35,
    visible = F.waveHud ~= false,
})
matchHud:section("Place")
matchHud:row({ icon = "map-pin", label = "Area", value = function()
    if isLobby() then return "Lobby" end
    if isPvpWorld() then return "PvP"
    end
    if F.afkWavesFarm then return "AFK Waves" end
    return "In match"
end })
matchHud:row({ icon = "ticket", label = "PvP Coins", value = function()
    local v = getCurrency("PVPTokens")
    return v ~= nil and fmtNum(v) or "-"
end })
matchHud:section("Wave")
matchHud:row({ icon = "list", label = "Wave", value = function()
    local wi = getMatchWaveInfo()
    if not wi then return isLobby() and "-" or "?" end
    local wave = wi:GetAttribute("Wave") or wi:GetAttribute("CurrentRoom") or wi:GetAttribute("CurrentRoomNum") or "?"
    local total = wi:GetAttribute("TotalWaves") or wi:GetAttribute("TotalRooms") or "?"
    return string.format("%s / %s", tostring(wave), tostring(total))
end })
matchHud:row({ icon = "bone", label = "Enemies", value = function()
    local wi = getMatchWaveInfo()
    if not wi then return "-" end
    local left = wi:GetAttribute("EnemiesLeft")
    return left ~= nil and tostring(left) or "-"
end })
matchHud:row({ icon = "gauge", label = "Enemy Lv", value = function()
    local wi = getMatchWaveInfo()
    if not wi then return "-" end
    -- Tower uses CurrentLevel; story waves may use EnemyLevel
    local lv = wi:GetAttribute("CurrentLevel")
        or wi:GetAttribute("EnemyLevel")
        or wi:GetAttribute("StartLevel")
    return lv ~= nil and tostring(lv) or "-"
end })
matchHud:section("Rewards")
matchHud:row({ icon = "sparkles-2", label = "Essence (run)", value = function()
    local wi = getMatchWaveInfo()
    if not wi then return "-" end
    local e = wi:GetAttribute("CurrentEssence")
    return e ~= nil and fmtNum(e) or "-"
end })
matchHud:row({ icon = "coin-pound", label = "Coin reward", value = function()
    local wi = getMatchWaveInfo()
    if not wi then return "-" end
    local c = wi:GetAttribute("CoinBag")
    return c ~= nil and fmtNum(c) or "-"
end })
matchHud:row({ icon = "diamond", label = "Gem reward", value = function()
    local wi = getMatchWaveInfo()
    if not wi then return "-" end
    local g = wi:GetAttribute("GemReward")
    return g ~= nil and fmtNum(g) or "-"
end })
matchHud:row({
    label = "Tower bot",
    icon = "bolt",
    dot = function() return F.towerBot == true end,
    value = function() return F.towerBot and "On" or "Off" end,
})

-- Index HUD: top units only (gear/runes/traits live in Index tab — fewer GuiObjects = less lag)
do
    local unitList = {}
    if type(UNIT_DATA) == "table" then
        pcall(function()
            unitList = IDX.annotateOwned(IDX.buildUnitIndex()) or {}
        end)
    end
    local rarityName = IDX.rarityName
    local topN = math.clamp(math.floor(tonumber(F.indexHudTopN) or 6), 4, 10)

    local function rarityShort(r)
        local n = rarityName(r)
        if n == "Legendary" then return "Leg"
        elseif n == "Mythic" then return "Myth"
        elseif n == "Secret" then return "Sec"
        elseif n == "Uncommon" then return "Unc"
        elseif n == "Common" then return "Com"
        elseif n == "Epic" then return "Epc"
        elseif n == "Rare" then return "Rare"
        end
        return n
    end

    indexHud = win:hud({
        title = "Index",
        icon = "book",
        width = 420,
        valueWidth = 72,
        spacing = 2,
        padding = 8,
        position = UDim2.new(1, -436, 0, 72),
        id = "index",
        interval = 30, -- static rows; rare tick is enough
        visible = F.indexHud ~= false,
    })

    indexHud:section(string.format("Clear top (%d)", #unitList))
    local n = #unitList
    if n == 0 then
        indexHud:row({ icon = "user", label = "Units data missing", value = "—", height = 17 })
    else
        for rank = 1, math.min(topN, n) do
            local e = unitList[n - rank + 1]
            if e then
                local tags = ""
                if e.owned then tags = tags .. " ·OWN" end
                if e.craft then tags = tags .. " ·C" end
                if e.lim then tags = tags .. " ·L" end
                local acShow = math.max(tonumber(e.cd) or 1, 1)
                indexHud:row({
                    icon = e.icon or "user",
                    label = string.format("#%d %s · %s · AC%.2g%s", rank, e.n, rarityShort(e.r), acShow, tags),
                    value = fmtNum(e.score or e.pow or 0),
                    height = 17,
                })
            end
        end
    end

    -- Game icons (rbxassetid) like before; untinted in defer below
    local itemIcon = IDX.itemIcon
    local function clip(s, max)
        s = tostring(s or "")
        if #s <= max then return s end
        return string.sub(s, 1, max - 1) .. "…"
    end

    indexHud:section("Gear S/A")
    for _, g in ipairs(IDX.GEAR or {}) do
        if g.tier == "S" or g.tier == "A" then
            indexHud:row({
                icon = itemIcon("Gear", g.id, "diamond"),
                label = string.format("[%s] %s", g.tier, g.n),
                value = clip(g.arch or g.stats or "", 18),
                height = 16,
            })
        end
    end

    indexHud:section("Runes S/A")
    for _, r in ipairs(IDX.RUNES or {}) do
        if r.tier == "S" or r.tier == "A" then
            local short = (r.n or ""):gsub(" Rune$", "")
            indexHud:row({
                icon = itemIcon("Runes", r.id, "sparkles-2"),
                label = string.format("[%s] %s", r.tier, short),
                value = clip(r.note or r.up or "", 18),
                height = 16,
            })
        end
    end

    indexHud:section("Traits S/A")
    for _, t in ipairs(IDX.TRAITS or {}) do
        if t.tier == "S" or t.tier == "A" then
            indexHud:row({
                icon = t.icon or "sparkles-2",
                label = string.format("[%s] %s", t.tier, t.n),
                value = clip(t.stats or "", 18),
                height = 16,
            })
        end
    end

    task.defer(function()
        pcall(function()
            local root = indexHud and indexHud.frame
            if not root then return end
            for _, d in ipairs(root:GetDescendants()) do
                if d:IsA("ImageLabel") and type(d.Image) == "string" and string.sub(d.Image, 1, 11) == "rbxassetid:" then
                    d.ImageColor3 = Color3.new(1, 1, 1)
                end
            end
        end)
    end)
end

-- Restore HUD positions from hud-layout.json (manual Save only — no drag hooks / no autosave).
pcall(function()
    genv.SH_ApplyHudLayout()
end)

win:setAutoLoad(autoName)
win:setAutoSave(autoName)
win:refreshAll()
pcall(function() win._dirty = false end)

task.defer(function()
    task.wait(0.35)
    if genv.SH_Session ~= SESSION then return end
    pcall(function() genv.SH_ApplyHudLayout() end)
    pcall(function() win._dirty = false end)
end)

task.spawn(function()
    for _ = 1, 40 do
        if getProfile() then break end
        task.wait(0.25)
    end
    farm.lastCoins = getCurrency("Coins")
    farm.lastGems = getCurrency("Gems")
    farm.lastEssence = getCurrency("Essence")
    farm.lastPvpTokens = getCurrency("PVPTokens")
    pcall(loadUnitData)
    if not farm.startedAt then farm.startedAt = os.time() end
    genv.SH_Farm = farm
    flushFarmDisk()
    hookCurrencyValues()
    armTeleportReload()
end)

local reloadOk = resolveScriptUrl() ~= nil
win:notify({
    title = "Summon Heroes [🚨]",
    text = reloadOk and ("Loaded · config " .. autoName .. " · teleport armed") or ("Loaded · config " .. autoName .. " · set Loader URL"),
    icon = "logo",
    duration = 5,
})
end)
end -- __SH_UI__
if stillThisBoot() then
    local okUi, errUi = pcall(__SH_UI__)
    if not okUi then
        pcall(function()
            warn("[SH] UI build failed: " .. tostring(errUi))
        end)
        pcall(function()
            if win and win.notify then
                win:notify({
                    title = "UI build failed",
                    text = tostring(errUi):sub(1, 180),
                    icon = "alert-triangle",
                    duration = 12,
                })
            end
        end)
        pcall(function()
            if not stillThisBoot() then return end
            local t = win:tab({ name = "Recover", icon = "alert-triangle", group = "Main", subtitle = "UI error" })
            local c = t:sub("Error"):card({ title = "UI build failed", icon = "alert-triangle", column = "left" })
            c:label(tostring(errUi):sub(1, 240))
            c:label("Re-execute the script. Farm still runs.")
        end)
    end
end

if stillThisBoot() then
    genv.SH_Alive = true
    genv.SH_BootPlace = game.PlaceId
    genv.SH_BootAt = os.clock()
    genv.SH_Booting = false
    genv.SH_LoadLock = nil
end
end -- __SH_BOOT__
do
    local okBoot, errBoot = pcall(__SH_BOOT__)
    if stillThisBoot() then
        genv.SH_Booting = false
        genv.SH_LoadLock = nil
        if not okBoot then
            warn("[SH] boot failed: " .. tostring(errBoot))
            pcall(function()
                if win and win.notify then
                    win:notify({
                        title = "Boot failed",
                        text = tostring(errBoot):sub(1, 180),
                        icon = "alert-triangle",
                        duration = 12,
                    })
                end
            end)
        end
        genv.SH_Alive = true
        genv.SH_BootPlace = game.PlaceId
        pcall(function()
            if win and win.window and not win._open then
                win:toggle(true)
            end
        end)
    elseif not stillThisBoot() then
        pcall(function()
            if win and win.unload then
                win:unload()
            elseif win and win.screen then
                win.screen:Destroy()
            end
        end)
    end
end
