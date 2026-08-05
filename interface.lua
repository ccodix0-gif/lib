-- NewReality interface
-- Sidebar based UI kit for the NW scripts: grouped sidebar tabs with icons, top
-- sub-tabs, titled cards in two columns, toggles with gear popovers, sliders,
-- searchable dropdowns, multi keybinds, colour pickers, live theming, saved
-- configs, translations and detached overlays (watermark, keybind panel, HUD).
-- The icon pack is embedded as base64, so the library is self contained.
--
-- The full guide with every option lives in docs/interface-lib.md, this header
-- is only the short reference.
--
-- LOADING
--   local UI = loadstring(game:HttpGet("<url>/interface.lua"))()
--   local win = UI.new({ toggleKey = Enum.KeyCode.RightShift })
--
-- LAYOUT: window -> tab -> sub -> card -> controls
--   local tab  = win:tab({ name = "Main", icon = "eye", group = "Visuals", subtitle = "Players" })
--   local sub  = tab:sub("Features")                         -- top sub-tab (call once per name)
--   local card = sub:card({ title = "Combat", icon = "bolt", column = "left" })  -- column "left"/"right"
--
-- FLAGS (persisted values). win:flag(key, default) returns get, set:
--   local get, set = win:flag("aimbot", false)
--   card:toggle("Aimbot", get, set)
--   -- get/set is two values; when passed as the LAST args it unpacks directly:
--   card:slider("FOV", 0, 500, win:flag("fov", 100))
--   -- After changing a flag yourself, call win:markDirty() so auto save persists it.
--
-- CONTROLS (all are methods on a card):
--   card:toggle(text, get, set [, buildSettings])  -- buildSettings(sc) adds a gear popover; fill sc like a card
--   card:slider(text, min, max, get, set [, decimals, format])
--   card:dropdown(text, options, get, set [, { search = true, multi = true }])  -- options: table or function
--   card:keybind(text, get, set [, { multi = true, list = false }])  -- right click / x icon clears it
--   card:colorpicker(text, getRgb, setRgb [, { alpha = false }])     -- value is { r, g, b, a }, a in 0..1
--   card:button(text, onClick)
--   card:input(text, placeholder, get, set)
--   card:segmented(text, options, get, set)         -- inline pills, no popover
--   card:list(options, get, set)                    -- inline searchable list
--   card:stepper(text, min, max, step, get, set)
--   card:status(text, get [, { lit = fn }])         -- read only row: a dot and the value
--   card:theme([{ preset = false, keys = {..}, reset = false, search = false }])  -- palette editor
--   card:section(text)                              -- small caption between groups of controls
--   card:label(text)                                -- wraps to multiple lines
--   card:divider()
--
-- GEAR POPOVERS: put long option lists behind a control's gear instead of the card:
--   card:toggle("Chams", g, s, function(sc)
--       sc:dropdown("Type", { "Fill", "Outline" }, win:flag("chamsType", "Fill"))
--       sc:colorpicker("Colour", getRgb, setRgb)
--   end)
--
-- THEME: win:getColor(key) -> { r, g, b, a }; win:setColor(key, { r, g, b, a }); win:resetTheme()
--   keys: accent, background, sidebar, card, cardTop, control, controlHover,
--   track, text, subtext, stroke
--
-- TRANSLATIONS (optional, nothing to do if a script only ships one language):
--   every string the kit draws goes through the phrase table, so more than one
--   language costs no changes to the layout code.
--   UI.addLocale("ru", { ["Auto Farm"] = "Автофарм", None = "Нет" })
--   UI.setLocale("ru")            -- re-labels a live interface, no rebuild
--   win:setLocale("ru")           -- same, and the choice is saved with the config
--   UI.hasLocales()               -- false until a language is added
--
-- CONFIGS: win:saveConfig(name) / loadConfig(name) / listConfigs() / deleteConfig(name)
--   win:setAutoLoad(name|nil) / getAutoLoad()       -- which config loads on launch
--   win:setAutoSave(name|nil)                        -- auto persists that config a moment after any change
--   A config holds the flags, the palette with its opacity, the type family and its
--   weights, the toggle key, the language and the position and visibility of every
--   detached panel.
--
-- STATUS STRIP (inside the window, along the bottom; off unless asked for):
--   UI.new({ statusBar = true })   or   win:statusBar({ show = { .. }, text = fn })
--   fields: time, date, user, expires, runs. The last three come from UI.session(), so on
--   a build with no key system they are absent rather than empty.
--
-- OVERLAYS (detached, draggable, positions saved with the config):
--   win:watermark{...}      -- logo, brand, fps, time strip
--   win:keybindList{...}    -- every registered keybind with its live state
--   win:hud{...}            -- custom panel built from rows, bars and sections
--   win:notify({ title, text, icon, duration })
--
-- SEARCH: a field at the top of the sidebar. Every named control indexes itself as
--   the interface is built, and picking a result opens its tab and sub-page, scrolls
--   to the control and flashes it. Nothing to declare.
--
-- MISC: win:refreshAll() (re-sync every control from its flag), win:toggle()
--   (show/hide the window), win:unload() (remove everything the library made).
--   win:refit() re-fits to the screen, and it already runs on a timer.
--   win:applyTheme(name) / UI.themeNames() for the palette presets.
--   win:settingsTab(opts) builds the whole settings page (window key, theme, opacity,
--     configs, panels, clipboard, language, and the type on a sub-page) and returns the tab
--     and its page, so a script can add its own cards beside them. Every card drops with a
--     flag of its own, and the panel toggles fill themselves whichever order they are in:
--     local tab, page = win:settingsTab({ language = { { label = "English", code = "en" } } })
--   win:exportConfig() / win:importConfig(text) move a config through the clipboard.
--   UI.keySystem({ check = fn, getKeyUrl =, discordUrl =, .. }) asks for a key, checks it
--     with your validator and gates every window on the answer. Returns true when it
--     passed. UI.keyPrompt(opts) is the same window without the waiting, and UI.session()
--     is what the validator last reported (user, expires, runs).
--   UI.licence(fn [, seconds]) is the older, keyless form of the same gate.
--   UI.setFont(family) swaps the type family for a language the default misses.
--   UI.setWeight(w) puts one weight under all of the text, UI.setRoleWeight(role, w) under
--     one kind of it; roles are regular, medium, semibold, bold and w is a name
--     ("thin".."heavy") or an Enum.FontWeight. UI.roleWeights() reads them back.
--   UI.setTextScale(n) scales every size the kit writes, 0.85 to 1.15; UI.getTextScale() and
--     UI.textScaleRange() read it back. The family, the weights and the scale are all saved
--     with the config.
--   UI.setLogger(fn) receives the diagnostics; nothing is printed without it.

-- Services and the executor globals we rely on are captured once, at load time,
-- before another script in the session can hook them. Everything below uses the
-- captured copies, so a later hook on Instance.new or on a service cannot see or
-- redirect what the library builds.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")

local newInstance = Instance.new
local envGet = getgenv
local guiHidden = gethui
local fileWrite, fileRead, fileExists, fileDelete = writefile, readfile, isfile, delfile
local folderMake, folderExists, folderList = makefolder, isfolder, listfiles
local customAsset = getcustomasset

local LocalPlayer = Players.LocalPlayer

local Interface = {}
-- Bump this whenever interface.luau changes so the host build can be verified from the
-- console, which catches a stale copy on the CDN. Loaders also search for this field by
-- name to tell the library apart from the scripts that load it, so the assignment has to
-- stay spelled exactly like this in the source text.
Interface.version = "2026.07.31.27"

-- Five tables that hold what used to be a hundred and thirty separate locals ------------
--
-- Not tidiness. Luau allows a function two hundred local registers, and the top level of a
-- file is a function, so a library that declares everything up there is spending a budget it
-- shares with nothing. This file reached two hundred and one and stopped compiling, on the
-- executor rather than here: the bundled compiler in tools/harness is a later build that
-- packs registers better and took the same file happily, which is the worst way to find out.
-- The count is now around a hundred and seventy, and every constant added from here goes in
-- one of these rather than into a local of its own.
--
-- Worth being clear about what this limit is not, because it reads like a size limit and it
-- is not one. It is per function. A script that loads this library is its own chunk with its
-- own two hundred, and nothing in here is deducted from it: the library's locals live in the
-- library's chunk. A three thousand line product script has the same room as a ten line one.
--
--   LAYOUT      pixels: heights, insets, widths, counts
--   MOTION      durations, in seconds
--   TYPESET     the family, the weights per role and the size scale, with their defaults
--   THEME_META  how the presets are ordered and what a palette key is called on a card
--   ICONS       the icon cache: where it is, whether it is written, what is in it
--
-- The values are still written beside the comment that explains them rather than hoisted
-- into one block here, because the explanation is the valuable part and moving a number away
-- from its reason is how the reason gets lost.
local LAYOUT = {}
local MOTION = {}
local TYPESET = {}
local THEME_META = {}
local ICONS = {}

-- Theme: our grey palette with the NewReality cyan accent.
local PALETTE = {
    sidebar = Color3.fromRGB(24, 24, 28),
    background = Color3.fromRGB(31, 31, 36),
    card = Color3.fromRGB(38, 38, 44),
    cardTop = Color3.fromRGB(44, 44, 51),
    control = Color3.fromRGB(48, 48, 56),
    controlHover = Color3.fromRGB(58, 58, 67),
    track = Color3.fromRGB(58, 58, 67),
    stroke = Color3.fromRGB(58, 58, 68),
    text = Color3.fromRGB(255, 255, 255),
    subtext = Color3.fromRGB(150, 150, 162),
    -- Marks rather than text: icons, the toggle knob, the slider knob. They start
    -- white and they have their own keys on purpose. They used to follow text and
    -- subtext, so recolouring the text turned every icon and every knob in the
    -- interface that colour too, which is not what anyone means by "text colour".
    icon = Color3.fromRGB(255, 255, 255),
    iconDim = Color3.fromRGB(150, 150, 162),
    knob = Color3.fromRGB(255, 255, 255),
    accent = Color3.fromRGB(0, 255, 255),
}
Interface.palette = PALETTE

-- Snapshot of the default palette so the theme can be reverted. Derived keys are
-- added after this snapshot, which is what keeps them out of getColor, resetTheme
-- and the saved config: they are computed, not chosen.
local DEFAULTS = {}
for k, v in pairs(PALETTE) do DEFAULTS[k] = v end
Interface.defaults = DEFAULTS

-- accentSoft is the accent corrected for legibility against the window background.
-- It is recomputed whenever either of those changes, never set directly.
PALETTE.accentSoft = PALETTE.accent

-- Theme presets ---------------------------------------------------------------
-- A preset is a partial palette: only the keys it names are applied, so a scheme
-- can change the accent alone and leave the greys as they are. Add your own with
-- UI.addTheme(name, keys) and apply one with win:applyTheme(name).
local THEMES = {
    ["NewReality"] = {
        sidebar = { 24, 24, 28 }, background = { 31, 31, 36 },
        card = { 38, 38, 44 }, cardTop = { 44, 44, 51 },
        control = { 48, 48, 56 }, controlHover = { 58, 58, 67 },
        track = { 58, 58, 67 }, stroke = { 58, 58, 68 },
        text = { 255, 255, 255 }, subtext = { 150, 150, 162 },
        icon = { 255, 255, 255 }, iconDim = { 150, 150, 162 },
        knob = { 255, 255, 255 }, accent = { 0, 255, 255 },
    },
    Graphite = {
        sidebar = { 22, 22, 24 }, background = { 30, 30, 32 },
        card = { 38, 38, 41 }, cardTop = { 44, 44, 47 },
        control = { 49, 49, 53 }, controlHover = { 60, 60, 64 },
        track = { 60, 60, 64 }, stroke = { 62, 62, 66 },
        text = { 244, 244, 246 }, subtext = { 146, 146, 152 },
        icon = { 255, 255, 255 }, iconDim = { 146, 146, 152 },
        knob = { 255, 255, 255 }, accent = { 118, 168, 255 },
    },
    Midnight = {
        sidebar = { 16, 18, 30 }, background = { 21, 24, 39 },
        card = { 28, 32, 50 }, cardTop = { 33, 38, 58 },
        control = { 37, 42, 64 }, controlHover = { 47, 53, 78 },
        track = { 47, 53, 78 }, stroke = { 50, 57, 84 },
        text = { 236, 240, 255 }, subtext = { 138, 146, 178 },
        icon = { 255, 255, 255 }, iconDim = { 138, 146, 178 },
        knob = { 255, 255, 255 }, accent = { 124, 138, 255 },
    },
    Ember = {
        sidebar = { 26, 21, 20 }, background = { 33, 27, 26 },
        card = { 42, 34, 32 }, cardTop = { 48, 39, 37 },
        control = { 54, 44, 41 }, controlHover = { 66, 53, 50 },
        track = { 66, 53, 50 }, stroke = { 68, 55, 52 },
        text = { 253, 245, 242 }, subtext = { 168, 150, 144 },
        icon = { 255, 255, 255 }, iconDim = { 168, 150, 144 },
        knob = { 255, 255, 255 }, accent = { 255, 138, 76 },
    },
    Moss = {
        sidebar = { 20, 26, 23 }, background = { 26, 33, 29 },
        card = { 33, 42, 37 }, cardTop = { 38, 48, 42 },
        control = { 43, 54, 47 }, controlHover = { 53, 66, 58 },
        track = { 53, 66, 58 }, stroke = { 55, 68, 60 },
        text = { 240, 248, 243 }, subtext = { 146, 166, 153 },
        icon = { 255, 255, 255 }, iconDim = { 146, 166, 153 },
        knob = { 255, 255, 255 }, accent = { 116, 224, 152 },
    },
    Paper = {
        sidebar = { 232, 232, 236 }, background = { 244, 244, 247 },
        card = { 255, 255, 255 }, cardTop = { 248, 248, 251 },
        control = { 234, 234, 239 }, controlHover = { 222, 222, 229 },
        track = { 218, 218, 226 }, stroke = { 208, 208, 216 },
        text = { 26, 26, 32 }, subtext = { 108, 108, 120 },
        icon = { 48, 48, 56 }, iconDim = { 128, 128, 140 },
        knob = { 255, 255, 255 }, accent = { 0, 132, 168 },
    },
    -- The rest are spread over the wheel on purpose, because a list of fourteen is past the
    -- point where two schemes a few degrees apart can be told apart in it. Where an accent
    -- does land near an older one the surface carries the difference instead: Carbon is the
    -- only near black, Nord the only desaturated accent, Crimson red on neutral grey against
    -- Ember's orange on brown. Two of them are light, which the corrected accent and the bar
    -- shading both already handle.
    Amber = {
        sidebar = { 23, 22, 20 }, background = { 30, 29, 26 },
        card = { 38, 37, 33 }, cardTop = { 44, 42, 38 },
        control = { 50, 48, 43 }, controlHover = { 61, 59, 53 },
        track = { 61, 59, 53 }, stroke = { 63, 61, 55 },
        text = { 250, 248, 243 }, subtext = { 162, 158, 148 },
        icon = { 255, 255, 255 }, iconDim = { 162, 158, 148 },
        knob = { 255, 255, 255 }, accent = { 250, 214, 60 },
    },
    Amethyst = {
        sidebar = { 24, 20, 31 }, background = { 31, 26, 40 },
        card = { 39, 33, 50 }, cardTop = { 45, 38, 57 },
        control = { 51, 43, 64 }, controlHover = { 62, 53, 77 },
        track = { 62, 53, 77 }, stroke = { 64, 55, 80 },
        text = { 245, 240, 253 }, subtext = { 155, 145, 174 },
        icon = { 255, 255, 255 }, iconDim = { 155, 145, 174 },
        knob = { 255, 255, 255 }, accent = { 178, 132, 255 },
    },
    Carbon = {
        sidebar = { 10, 10, 11 }, background = { 15, 15, 17 },
        card = { 21, 21, 24 }, cardTop = { 26, 26, 29 },
        control = { 31, 31, 35 }, controlHover = { 41, 41, 46 },
        track = { 41, 41, 46 }, stroke = { 43, 43, 48 },
        text = { 247, 247, 250 }, subtext = { 136, 136, 145 },
        icon = { 255, 255, 255 }, iconDim = { 136, 136, 145 },
        knob = { 255, 255, 255 }, accent = { 190, 255, 70 },
    },
    -- Red on a neutral charcoal rather than on a warm one. The first draft put it on Ember's
    -- browns and the two came out as the same scheme with the accent swapped.
    Crimson = {
        sidebar = { 20, 20, 22 }, background = { 27, 27, 30 },
        card = { 34, 34, 38 }, cardTop = { 40, 40, 44 },
        control = { 46, 46, 51 }, controlHover = { 57, 57, 63 },
        track = { 57, 57, 63 }, stroke = { 59, 59, 65 },
        text = { 246, 244, 245 }, subtext = { 152, 150, 154 },
        icon = { 255, 255, 255 }, iconDim = { 152, 150, 154 },
        knob = { 255, 255, 255 }, accent = { 244, 63, 76 },
    },
    Frost = {
        sidebar = { 226, 231, 240 }, background = { 240, 244, 250 },
        card = { 255, 255, 255 }, cardTop = { 246, 249, 253 },
        control = { 229, 235, 244 }, controlHover = { 216, 224, 237 },
        track = { 212, 221, 235 }, stroke = { 201, 211, 227 },
        text = { 24, 30, 42 }, subtext = { 102, 113, 133 },
        icon = { 44, 52, 68 }, iconDim = { 124, 135, 155 },
        knob = { 255, 255, 255 }, accent = { 78, 92, 214 },
    },
    Linen = {
        sidebar = { 234, 228, 220 }, background = { 245, 241, 234 },
        card = { 255, 253, 249 }, cardTop = { 249, 245, 238 },
        control = { 236, 230, 221 }, controlHover = { 225, 217, 205 },
        track = { 221, 213, 200 }, stroke = { 211, 202, 188 },
        text = { 32, 28, 24 }, subtext = { 116, 108, 98 },
        icon = { 54, 48, 42 }, iconDim = { 136, 127, 116 },
        knob = { 255, 255, 255 }, accent = { 176, 106, 40 },
    },
    Nord = {
        sidebar = { 38, 42, 52 }, background = { 46, 52, 64 },
        card = { 55, 62, 76 }, cardTop = { 62, 70, 85 },
        control = { 68, 77, 94 }, controlHover = { 80, 90, 110 },
        track = { 80, 90, 110 }, stroke = { 82, 92, 112 },
        text = { 236, 239, 244 }, subtext = { 154, 163, 179 },
        icon = { 255, 255, 255 }, iconDim = { 154, 163, 179 },
        knob = { 255, 255, 255 }, accent = { 136, 192, 208 },
    },
    Orchid = {
        sidebar = { 29, 21, 28 }, background = { 37, 27, 36 },
        card = { 46, 34, 45 }, cardTop = { 53, 39, 52 },
        control = { 60, 45, 59 }, controlHover = { 72, 55, 71 },
        track = { 72, 55, 71 }, stroke = { 74, 57, 73 },
        text = { 253, 242, 251 }, subtext = { 176, 150, 172 },
        icon = { 255, 255, 255 }, iconDim = { 176, 150, 172 },
        knob = { 255, 255, 255 }, accent = { 240, 110, 200 },
    },
}
Interface.themes = THEMES

-- The order presets are offered in, which is not alphabetical on purpose.
--
-- THEMES is a hash, so it has no order of its own and the list used to be sorted by
-- name. That put the kit's own scheme fifth of six, below schemes it is the default
-- for, which reads as though the thing you are looking at were one of the
-- alternatives. So the default leads and the rest follow in alphabetical order, and a
-- preset added later goes on the end, where a caller expects the one they just added
-- to be rather than somewhere in the middle.
THEME_META.order = {
    "NewReality",
    "Amber", "Amethyst", "Carbon", "Crimson", "Ember", "Frost", "Graphite",
    "Linen", "Midnight", "Moss", "Nord", "Orchid", "Paper",
}

-- What a palette key is called on a card. Kept here rather than in the caller so the
-- built in theme card names its rows the same way everywhere and a translation covers
-- them once, instead of every script inventing its own wording for the same key.
THEME_META.label = {
    accent = "Accent",
    background = "Background",
    sidebar = "Sidebar",
    card = "Cards",
    cardTop = "Card Header",
    control = "Controls",
    controlHover = "Control Hover",
    track = "Track",
    stroke = "Outline",
    text = "Text",
    subtext = "Subtext",
    icon = "Icons",
    iconDim = "Dim Icons",
    knob = "Knob",
}

-- The six a user actually reaches for. The rest are still there through opts.keys, but
-- a card that lists all fourteen is a wall of swatches nobody reads.
THEME_META.shown = { "accent", "background", "sidebar", "card", "control", "track" }

-- The weights the type card offers, and what each role is called on it.
--
-- Four of the nine names setWeight takes, and the argument for stopping at four is the same
-- one that stopped the earlier list at six. Thin and ExtraLight are unreadable at interface
-- sizes on a family the client fakes them from, and ExtraBold is indistinguishable from
-- Bold. SemiBold and Heavy go for the same reason, one step further on: on the families the
-- client ships, only Regular and Bold are real faces and everything else is made from the
-- nearest one, so SemiBold lands between Medium and Bold without being either and Heavy is
-- Bold with the letter spacing squeezed out. Offering them is offering a choice that does
-- nothing, and it cost two of the four pills a row can hold.
--
-- setRoleWeight still takes all nine. This is what the card puts on screen, and every
-- weight the kit ships as a default is in here.
TYPESET.weights = { "Light", "Regular", "Medium", "Bold" }

-- Named by what the text is rather than by the role, because "semibold" is the weight it
-- happens to wear today and "Captions" is what it is for.
TYPESET.roles = {
    { key = "regular", label = "Body" },
    { key = "medium", label = "Labels" },
    { key = "semibold", label = "Captions" },
    { key = "bold", label = "Titles" },
}

-- Families the client ships. A name that is not one of these makes a Font the client cannot
-- resolve, and that Font would then be written to every label the kit owns, so the list is
-- kept here rather than left to each caller to get right.
TYPESET.families = {
    "Arial", "Arimo", "BuilderSans", "GothamSSm", "Merriweather", "Montserrat", "Nunito",
    "Roboto", "RobotoCondensed", "RobotoMono", "SourceSansPro", "TitilliumWeb", "Ubuntu",
}

function Interface.addTheme(name, keys)
    if type(name) ~= "string" or type(keys) ~= "table" then return end
    if THEMES[name] == nil then THEME_META.order[#THEME_META.order + 1] = name end
    THEMES[name] = keys
end

function Interface.themeNames()
    local out = {}
    local listed = {}
    for _, name in ipairs(THEME_META.order) do
        if THEMES[name] and not listed[name] then
            listed[name] = true
            out[#out + 1] = name
        end
    end
    -- Anything in THEMES that the order list has not heard of, which is a preset
    -- written straight into UI.themes rather than through addTheme. Sorted, because
    -- there is no stated order to respect.
    local rest = {}
    for name in pairs(THEMES) do
        if not listed[name] then rest[#rest + 1] = name end
    end
    table.sort(rest)
    for _, name in ipairs(rest) do out[#out + 1] = name end
    return out
end

-- Per key opacity (1 = fully opaque). Colour pickers may carry an alpha that is
-- mapped onto the matching transparency property when a themed part is painted.
local PALETTE_A = {}
for k in pairs(PALETTE) do PALETTE_A[k] = 1 end
Interface.paletteAlpha = PALETTE_A

-- Colour property -> transparency property, so a key's alpha can fade its parts.
-- UIStroke is in the list as well: an outline that does not follow the opacity
-- of the surface it wraps is the thing that gives a translucent window away.
local TRANS_OF = {
    BackgroundColor3 = "BackgroundTransparency",
    TextColor3 = "TextTransparency",
    ImageColor3 = "ImageTransparency",
    Color = "Transparency",
}

-- Type ------------------------------------------------------------------------
-- Why the text can look wrong when nothing about it is broken, since this has been chased
-- for a while and the answer is worth writing down.
--
-- What Roblox serves for the Arial family is Arimo, and Arimo ships two drawn faces:
-- Regular and Bold. Every other weight is made by the client from the nearest one it has,
-- and a made up weight thickens the letterforms without touching the space between them.
-- At interface sizes, thirteen to fifteen pixels, that is enough to close the gap between
-- adjacent stems, and the eye reads it as letters touching. So Heavy is not a heavier
-- Arial, it is Bold with the air squeezed out of it.
--
-- The other half is that Bold is a display weight. It is drawn to be read large. Used for
-- body copy it has wide stems and small counters, and a paragraph of it goes grey and
-- even. That is what makes a heavy interface look dense rather than crisp, and it is why
-- the same layout in Regular looks like everyone else's and in Bold does not.
--
-- Neither of those is a bug to fix, they are two ends of a trade, so the kit gives the
-- trade a name instead of picking for you. The default puts the reading weight under
-- anything you read and the heavy one on the things meant to be seen first, which is the
-- arrangement that looks the most like other interfaces:
--
--   regular    Regular   prose, values, options, rows on the detached panels
--   medium     Medium    control labels, sidebar tabs, sub-tabs
--   semibold   Bold      section captions, card titles
--   bold       Bold      the brand, page titles
--
-- And it is one call to move the whole thing either way:
--
--   UI.setWeight("bold")      -- everything heavy, the way this kit used to be
--   UI.setWeight("regular")   -- everything light
--   UI.setRoleWeight("medium", Enum.FontWeight.SemiBold)   -- one role only
--
-- Medium is a made up weight on this family, so it carries the tightening described
-- above, but far less of it than Heavy: it is one step from Regular rather than two from
-- Bold. It is there because control labels want to be a little heavier than their values
-- and a real face for that does not exist.
TYPESET.family = "rbxasset://fonts/families/Arial.json"
TYPESET.roleNames = { "regular", "medium", "semibold", "bold" }
-- The weight each role wears. One entry per role rather than one weight for all of them,
-- so a build can put the reading weight under the prose and keep the heavy one for the
-- titles without touching a single call site.
TYPESET.roleWeight = {
    regular = Enum.FontWeight.Regular,
    medium = Enum.FontWeight.Medium,
    semibold = Enum.FontWeight.Bold,
    bold = Enum.FontWeight.Bold,
}

-- What the kit ships with, snapshotted before anything can change it, so a reset has
-- somewhere to go back to. The palette keeps its own snapshot for the same reason.
TYPESET.familyDefault = TYPESET.family
TYPESET.roleWeightDefault = {}
for role, weight in pairs(TYPESET.roleWeight) do TYPESET.roleWeightDefault[role] = weight end

local FACES = {}
local function rebuildFaces()
    for _, role in ipairs(TYPESET.roleNames) do
        FACES[role] = Font.new(TYPESET.family, TYPESET.roleWeight[role], Enum.FontStyle.Normal)
    end
end
rebuildFaces()
Interface.fonts = FACES

-- Registry of the text parts that follow the family, so a swap re-faces what is
-- already on screen. Same shape as the theme registry below.
local FONT_REG = {}

local function colorOf(rgb)
    return Color3.fromRGB(rgb[1] or 255, rgb[2] or 255, rgb[3] or 255)
end
Interface.colorOf = colorOf

local function luminance(color)
    return 0.2126 * color.R + 0.7152 * color.G + 0.0722 * color.B
end

-- Black or white, whichever can be read on top of the given colour. Anything the
-- kit prints on an accent filled shape goes through this: the accent is the one
-- palette key a user is certain to change, and a label that assumes a bright
-- accent disappears the moment someone picks a dark one.
local function contrastOn(color)
    if luminance(color) > 0.55 then
        return Color3.fromRGB(16, 16, 20)
    end
    return Color3.fromRGB(255, 255, 255)
end
Interface.contrastOn = contrastOn

-- Recently used colours, shared by every picker in the session and saved with the
-- config. Theming an interface means going back and forth between a handful of
-- colours, and typing a hex code again each time is the slow way round.
-- Seven, not eight: the eighth slot in the row is the button that empties it.
LAYOUT.recentMax = 7
local recentColors = {}
Interface.recentColors = recentColors

-- One colour, however it was written, as six upper case hex digits. A Color3 is
-- recognised by carrying an R channel rather than by its type name, which keeps this
-- working for a { r, g, b } table as well.
local function normaliseHex(value)
    if type(value) == "string" then
        local hex = string.upper((string.gsub(value, "#", "")))
        if #hex == 6 and string.match(hex, "^%x+$") then return hex end
        return nil
    end
    local ok, red = pcall(function() return value.R end)
    if ok and type(red) == "number" then
        return string.format(
            "%02X%02X%02X",
            math.floor(value.R * 255 + 0.5),
            math.floor(value.G * 255 + 0.5),
            math.floor(value.B * 255 + 0.5)
        )
    end
    if type(value) == "table" and type(value[1]) == "number" then
        return string.format("%02X%02X%02X", value[1], value[2] or 0, value[3] or 0)
    end
    return nil
end

local function pushRecent(rgb)
    local hex = normaliseHex(rgb)
    if not hex then return end
    for i = #recentColors, 1, -1 do
        if recentColors[i] == hex then table.remove(recentColors, i) end
    end
    table.insert(recentColors, 1, hex)
    while #recentColors > LAYOUT.recentMax do table.remove(recentColors) end
end

-- Empty the row. The table is cleared in place rather than replaced, because
-- Interface.recentColors is the same table a script may already be holding.
function Interface.clearRecentColors()
    table.clear(recentColors)
end

-- Put a colour at the front of the row by hand, for a build that wants to seed it
-- from somewhere of its own. Same rules as a colour the picker records: duplicates
-- move up rather than repeat, and the row keeps its length.
function Interface.pushRecentColor(value)
    pushRecent(value)
end





-- The accent, lifted or dropped until it can be seen against the surface it is
-- drawn on. Used only by the thin marks: a two pixel underline, a sixteen pixel
-- tick, a seven pixel dot. Those vanish outright when someone picks an accent close
-- to their background, and there is not enough of them on screen for the shift to
-- be noticed as a different colour.
--
-- Large filled areas keep the literal accent. Correcting those would be answering
-- a colour the user chose with a colour the library preferred.
LAYOUT.markContrast = 0.18
local function legibleOn(color, surface)
    local gap = luminance(color) - luminance(surface)
    if math.abs(gap) >= LAYOUT.markContrast then return color end
    local h, s, v = color:ToHSV()
    -- Away from the surface: lighter on a dark one, darker on a light one.
    local up = luminance(surface) < 0.5
    for _ = 1, 12 do
        v = up and math.min(v + 0.08, 1) or math.max(v - 0.08, 0)
        if s > 0 and up and v >= 1 then s = math.max(s - 0.12, 0) end
        local tryColor = Color3.fromHSV(h, s, v)
        if math.abs(luminance(tryColor) - luminance(surface)) >= LAYOUT.markContrast then
            return tryColor
        end
        if (up and v >= 1 and s <= 0) or (not up and v <= 0) then
            return tryColor
        end
    end
    return Color3.fromHSV(h, s, v)
end
Interface.legibleOn = legibleOn

-- Tag registries --------------------------------------------------------------
-- Theme tagging: any element passed to themed(inst, prop, key) follows the
-- palette and is recoloured live by Window:setColor(key, rgb). Fonts work the
-- same way through faced(inst, role).
--
-- Both registries hold their instances strongly. The previous build used weak
-- keys, and a part that the builder did not keep a reference to (the accent half
-- of the logo is the clearest case) was dropped by the collector and silently
-- stopped following the palette. Entries are pruned while the registry is walked
-- instead: an instance that has been parented once and is now parentless has
-- been destroyed, so it goes.
local function tagAdd(reg, inst, value)
    local entry = reg[inst]
    if entry then
        entry.values[#entry.values + 1] = value
    else
        reg[inst] = { values = { value }, seen = inst.Parent ~= nil }
    end
end

-- fn(inst, value) for every live entry. Dead entries drop out on the way past.
local function tagWalk(reg, fn)
    for inst, entry in pairs(reg) do
        local parented = inst.Parent ~= nil
        if parented then
            entry.seen = true
        end
        -- Not parented yet means the builder is still assembling it, so it stays.
        if entry.seen and not parented then
            reg[inst] = nil
        else
            for _, value in ipairs(entry.values) do
                pcall(fn, inst, value)
            end
        end
    end
end

local THEME_REG = {}
for key in pairs(PALETTE) do
    THEME_REG[key] = {}
end

-- Base transparency of a themed part, remembered the first time an opacity below
-- 1 fades it, so a return to full opacity restores the part's own value and a
-- part that was hidden on purpose stays hidden.
local THEME_BASE = {}

-- Fade a part by the opacity of its palette key. The part's own transparency is
-- kept as the floor, so a card outline at 0.4 under a 50% window reads as 0.7
-- rather than snapping to a flat 0.5.
local function fadeProp(inst, prop, alpha)
    local tp = TRANS_OF[prop]
    if not tp then return end
    local bases = THEME_BASE[inst]
    local base = bases and bases[tp]
    if base == nil then
        local ok, current = pcall(function() return inst[tp] end)
        if not ok or type(current) ~= "number" then return end
        base = current
        bases = bases or {}
        bases[tp] = base
        THEME_BASE[inst] = bases
    end
    if base >= 1 then return end
    pcall(function() inst[tp] = 1 - (1 - base) * alpha end)
end

-- themed(inst, prop, key [, opts])
--   opts.fade = false  the part animates its own transparency between states
--                      (an inactive sidebar tab, an unselected list row), so the
--                      palette opacity must not fight the animation.
--   opts.paint = false the part's colour belongs to something else and only its
--                      opacity follows the key. A bar's fill is the case: the shading
--                      gradient over it owns the colour, and the fill underneath has to
--                      stay white for the gradient to be able to lighten as well as
--                      darken. Without this the fill would need either two owners
--                      fighting over one property or its own opacity handling.
local function themed(instance, prop, key, opts)
    local paints = not (opts and opts.paint == false)
    if paints then instance[prop] = PALETTE[key] end
    local reg = THEME_REG[key]
    if reg then
        tagAdd(reg, instance, { prop = prop, fade = not (opts and opts.fade == false), paint = paints })
    end
    if not (opts and opts.fade == false) then
        local alpha = PALETTE_A[key]
        if alpha and alpha < 1 then
            fadeProp(instance, prop, alpha)
        end
    end
    return instance
end

-- Controls whose colour depends on their own state as well as on the palette.
--
-- The theme registry paints by key: everything registered under "track" is written the
-- track colour. That is right for a surface and wrong for anything that changes colour
-- with its own state. A toggle that is on is wearing the accent, and it is also in the
-- track registry because that is what it wears when it is off, so a theme change painted
-- it the track colour and left it there looking switched off while its knob sat on the
-- far side. The same went for the open sidebar tab, whose label is registered under
-- subtext and is meant to be text while it is the open one.
--
-- A one-off refresh after the change does not fix it, because a change is eased over a
-- fifth of a second and the registry repaints on every frame of that. So these repaint
-- themselves at the end of every pass, from the colour that is on screen now rather than
-- the one being headed for, which means they follow the ease instead of snapping when it
-- ends.
--
-- Keyed by the instance and held strongly, with a control that has been destroyed dropped
-- on the way past in runStatePainters. Strongly, because a weak key is not a reference and
-- Roblox may drop the wrapper for an instance that nothing is holding: the entry then
-- leaves the table and the control silently stops following the palette. Every control on
-- this list happens to be in THEME_REG as well, which is strong and is what has been
-- keeping them alive, but a painter that does not need a registry entry would have gone.
-- That is what happened to the bar ramps, which were the one thing held only weakly.
local STATE_PAINTERS = {}

local function addStatePainter(instance, fn)
    STATE_PAINTERS[instance] = fn
    fn()
end

local function runStatePainters()
    for instance, fn in pairs(STATE_PAINTERS) do
        if instance.Parent then
            pcall(fn)
        else
            STATE_PAINTERS[instance] = nil
        end
    end
end

-- The colour a key is showing right now, which is not the colour it is heading for while
-- a change is easing. Reassigned once the fade state exists, further down.
local shownColor = function(key)
    return PALETTE[key]
end

-- Declared here and filled in with the logger further down, because the type and icon code
-- above the logger needs to be able to report a refusal. Without the forward declaration this
-- name resolves to a global, which is nil, so the one line that was meant to explain a
-- failure would throw on top of it.
local log

-- Text size, as a scale over the sizes the kit already writes rather than a size per control.
--
-- The kit has one scale of six sizes and every call site names one of them, so this is the
-- third axis of the type beside the family and the weight: a build that wants more on screen
-- at once turns it down, one being read from across a room turns it up. A size per control
-- would be the same idea with eighty knobs and no way to keep them in proportion.
--
-- The base is the size a control was built with, remembered the first time the scale moves it.
-- That is the trick the palette already uses for a part's own transparency, and it is the
-- right way round here for a specific reason: recording the base in faced() instead would
-- mean every call site had to set TextSize before faced(), and one that got the order wrong
-- would silently stop scaling with no sign of why.
--
-- It is kept on the font registry's own entry rather than in a table beside it, so it is
-- pruned when the registry prunes and there is no second table to leak.
--
-- The ceiling is 1.15 and not more because the boxes do not scale with the text. A card title
-- at 17 sits in a 20 pixel row and a HUD row's label at 13 sits in 15, so past about a seventh
-- over, the tallest text starts clipping the row it is in rather than growing.
TYPESET.scaleDefault = 1
TYPESET.scale = TYPESET.scaleDefault
TYPESET.scaleMin, TYPESET.scaleMax = 0.85, 1.15

local function sizeFor(instance)
    local entry = FONT_REG[instance]
    if not entry then return nil end
    if entry.base == nil then
        local ok, current = pcall(function() return instance.TextSize end)
        if not ok or type(current) ~= "number" then return nil end
        entry.base = current
    end
    return math.max(1, math.floor(entry.base * TYPESET.scale + 0.5))
end

-- faced(inst, role): pick a weight and follow the family.
--
-- Set TextSize before calling this, on a build that is running at a scale other than 1. The
-- size written afterwards is the one the scale is measured from, so a call site that writes it
-- the other way round leaves that one label at its unscaled size.
local function faced(instance, role)
    role = role or "regular"
    instance.FontFace = FACES[role] or FACES.regular
    tagAdd(FONT_REG, instance, role)
    -- Only when there is a scale to apply, so at the default nothing is recorded and the
    -- first change reads every base off a finished interface.
    if TYPESET.scale ~= 1 then
        local size = sizeFor(instance)
        if size then instance.TextSize = size end
    end
    return instance
end

-- Re-face everything already on screen, at each part's own role.
local function refaceAll()
    rebuildFaces()
    tagWalk(FONT_REG, function(inst, role)
        inst.FontFace = FACES[role] or FACES.regular
    end)
end

-- Re-size everything already on screen, from each part's own base.
local function resizeAll()
    tagWalk(FONT_REG, function(inst)
        local size = sizeFor(inst)
        if size then inst.TextSize = size end
    end)
end

-- Swap the type family for the whole interface (a language the default family
-- has no glyphs for). Existing labels are re-faced in place.
--
-- The face is built before anything is written, and a family the client will not make a Font
-- from leaves the interface on the one it already had. Half re-faced is the worst outcome
-- here, because the write goes to every label the kit owns and there is no way back from it.
-- Returns whether it took, so a caller offering a list of families can put the control back
-- on the one that is actually being drawn.
function Interface.setFont(family)
    if type(family) ~= "string" or family == "" then return false end
    local ok = pcall(function()
        return Font.new(family, Enum.FontWeight.Regular, Enum.FontStyle.Normal)
    end)
    if not ok then
        log("warn", "setFont: " .. family .. " is not a font family")
        return false
    end
    TYPESET.family = family
    refaceAll()
    return true
end

TYPESET.weightNames = {
    thin = Enum.FontWeight.Thin,
    extralight = Enum.FontWeight.ExtraLight,
    light = Enum.FontWeight.Light,
    regular = Enum.FontWeight.Regular,
    medium = Enum.FontWeight.Medium,
    semibold = Enum.FontWeight.SemiBold,
    bold = Enum.FontWeight.Bold,
    extrabold = Enum.FontWeight.ExtraBold,
    heavy = Enum.FontWeight.Heavy,
}

local function asWeight(weight)
    if type(weight) == "string" then
        return TYPESET.weightNames[string.lower(weight)]
    end
    return weight
end

-- Put one weight under every role. Live, like setFont.
function Interface.setWeight(weight)
    weight = asWeight(weight)
    if weight == nil then return end
    for _, role in ipairs(TYPESET.roleNames) do
        TYPESET.roleWeight[role] = weight
    end
    refaceAll()
end

-- Or one role at a time, for a build that wants its own scale: the roles are named at
-- every call site in the kit, so this changes a whole category of text at once.
function Interface.setRoleWeight(role, weight)
    if type(role) ~= "string" then return end
    role = string.lower(role)
    if TYPESET.roleWeight[role] == nil then return end
    weight = asWeight(weight)
    if weight == nil then return end
    TYPESET.roleWeight[role] = weight
    refaceAll()
end

-- What each role is wearing, by the same names setWeight takes.
--
-- Written as names rather than as the enums because this goes into a config file, and a
-- file holding "bold" can still be read by a build whose enum values have moved. It also
-- means a script can read the weights back, offer them and write them again without
-- knowing anything about Enum.FontWeight.
TYPESET.weightName = {}
for name, weight in pairs(TYPESET.weightNames) do TYPESET.weightName[weight] = name end

function Interface.roleWeights()
    local out = {}
    for _, role in ipairs(TYPESET.roleNames) do
        out[role] = TYPESET.weightName[TYPESET.roleWeight[role]] or "regular"
    end
    return out
end

-- The family the interface is drawing in, so a config can put it back.
function Interface.getFont()
    return TYPESET.family
end

-- Scale every size the kit writes. Live, like setFont and setWeight.
--
-- Clamped, and rounded to whole percents before anything is written: that is the granularity
-- the control offers, and a walk over every label in the interface is not worth doing for a
-- hundredth of a point. A value that rounds to the one already in use writes nothing at all,
-- which is what keeps dragging the control cheap.
--
-- Returns whether the value was usable, not whether anything moved, so a caller handed a
-- number out of range can tell it was refused rather than merely clamped.
function Interface.setTextScale(scale)
    scale = tonumber(scale)
    if not scale then return false end
    local wanted = math.floor(scale * 100 + 0.5) / 100
    local clamped = math.clamp(wanted, TYPESET.scaleMin, TYPESET.scaleMax)
    if clamped ~= TYPESET.scale then
        TYPESET.scale = clamped
        resizeAll()
    end
    return wanted == clamped
end

function Interface.getTextScale()
    return TYPESET.scale
end

-- The range the control offers, so a caller building its own does not have to guess and
-- cannot offer a value setTextScale will refuse.
function Interface.textScaleRange()
    return TYPESET.scaleMin, TYPESET.scaleMax
end

-- Translations ----------------------------------------------------------------
-- Phrases are keyed by their English text, so a script that never calls
-- addLocale reads exactly as it was written and a translated build only has to
-- list the strings it wants changed.
--
--   UI.addLocale("ru", { ["Auto Farm"] = "Автофарм", None = "Нет" })
--   UI.setLocale("ru")
--
-- Every label the kit draws is registered, so a language change re-labels what
-- is already on screen instead of asking for a rebuild.
local LOCALES = {}
local localeCode = "en"
local TEXT_REG = {}
-- Live windows, so a language change can re-sync the controls that build their
-- text from more than one phrase (a keybind reading "None", a multi dropdown
-- joining its picks). Cleared entries drop out as windows unload.
local WINDOWS = {}
Interface.locales = LOCALES

-- Nothing here is required. A script that never calls addLocale gets its strings
-- back exactly as it wrote them, and the lookup is skipped entirely, so opting out
-- costs nothing at all.
local localeCount = 0

local function translate(phrase, ...)
    if type(phrase) ~= "string" then return phrase end
    local out = phrase
    if localeCount > 0 then
        local phrases = LOCALES[localeCode]
        local hit = phrases and phrases[phrase]
        if hit ~= nil then out = hit end
    end
    if select("#", ...) > 0 then
        local ok, formatted = pcall(string.format, out, ...)
        if ok then return formatted end
    end
    return out
end
Interface.translate = translate

-- Whether any language has been registered. A script can use this to decide
-- whether to show a language control at all.
function Interface.hasLocales()
    return localeCount > 0
end

-- The registered language codes, in the order they were added.
function Interface.localeCodes()
    local out = {}
    for code in pairs(LOCALES) do out[#out + 1] = code end
    table.sort(out)
    return out
end

-- Bind a label to a phrase: written now, rewritten on a language change.
--
-- The returned setter changes the phrase the label is bound to, not just the text
-- on screen. It writes into the same entry the registry holds, so a label renamed
-- at runtime (hud:setTitle, row:setLabel) is still the renamed one after the
-- language changes rather than reverting to whatever it was built with.
local function localized(instance, prop, phrase, transform)
    local entry = { prop = prop, phrase = phrase, transform = transform }
    local function write()
        local value = translate(entry.phrase)
        if entry.transform then value = entry.transform(value) end
        instance[prop] = value
    end
    write()
    tagAdd(TEXT_REG, instance, entry)
    return function(nextPhrase)
        entry.phrase = nextPhrase
        write()
    end
end

function Interface.addLocale(code, phrases)
    if type(code) ~= "string" or type(phrases) ~= "table" then return end
    local target = LOCALES[code]
    if not target then
        target = {}
        LOCALES[code] = target
        localeCount += 1
    end
    for phrase, value in pairs(phrases) do
        target[phrase] = value
    end
    if code == localeCode then Interface.setLocale(code) end
end

function Interface.setLocale(code)
    if type(code) ~= "string" or code == "" then return end
    localeCode = code
    Interface.locale = code
    tagWalk(TEXT_REG, function(inst, entry)
        local value = translate(entry.phrase)
        if entry.transform then value = entry.transform(value) end
        inst[entry.prop] = value
    end)
    for i = #WINDOWS, 1, -1 do
        local win = WINDOWS[i]
        if win._dead then
            table.remove(WINDOWS, i)
        else
            pcall(function() win:refreshAll() end)
        end
    end
end

function Interface.getLocale()
    return localeCode
end
Interface.locale = localeCode

-- Session guard ---------------------------------------------------------------
-- The kit is paid and closed source, so the runtime makes a loaded copy harder
-- to read and harder to touch from another script in the same session:
--   * services and executor globals are captured above, before any foreign hook
--   * every instance it builds gets a random name, nothing is findable by name
--   * the ScreenGui goes into the executor's hidden container when there is one
--   * that ScreenGui is watched, a foreign reparent is undone
--   * the table the loader gets back is a locked proxy over the real module
--   * an optional licence check gates window creation and keeps re-checking
-- None of this makes a script unbreakable, it removes the easy ways in.
local NAME_POOL = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
local nameRandom = Random.new(math.floor(os.clock() * 1e6) % 2147483647)
local function randomName(length)
    length = length or 12
    local out = table.create(length)
    for i = 1, length do
        local at = nameRandom:NextInteger(1, #NAME_POOL)
        out[i] = string.sub(NAME_POOL, at, at)
    end
    return table.concat(out)
end

-- The gate ------------------------------------------------------------------
-- What stands between a loaded library and a built window.
--
-- This was a dead letter before: there was a licence(fn) that stored a validator, an
-- ok() that would have run it, a comment claiming both ran on window creation and on a
-- timer, and not one call site for either. A gate nothing consults is worse than no
-- gate, because the comment says the product is protected and it is not.
--
-- What it is now:
--   * arm(check, opts) is handed a validator and nothing else. What the validator does
--     is the caller's business: an HttpGet to a key site, Luarmor, a local compare.
--   * a pass mints a token, and building a window requires the token rather than a
--     boolean. There is no `passed = true` anywhere to flip.
--   * the token is re-minted on every re-check and dropped on the first failure, and a
--     failure takes every live window down with it.
--   * the key itself is never held. It goes to the validator as an argument and the
--     field it was typed into is cleared. It is not in the config, not in a file, and
--     not on any table this library returns.
--
-- What it is not: unbreakable. The code runs in the reader's own process, so anyone
-- willing to edit the file can delete the check. Everything here raises the cost of
-- doing it casually and none of it survives a deliberate patch, which is what a
-- bytecode obfuscator is for and this is not.
local gateCheck = nil
local gateOpts = nil
local gateToken = nil
local gateLastRun = 0
local gateInfo = nil
-- Whether a key has just been accepted and nothing has been built on it yet.
--
-- The first window built after a pass gets the debut animation; every window after it, and
-- every window in a build with no gate, opens the ordinary way. Read once and cleared, because
-- "the first one" is exactly what it means, and because a script that unloads and rebuilds its
-- interface should not get the opening titles again.
local gateFresh = false
-- Rebuilt on every pass. Long enough that guessing it is not a shortcut, and it never
-- leaves this file: nothing returns it and nothing writes it to a config.
local function mintToken()
    return randomName(24) .. tostring(math.floor(os.clock() * 1e6))
end

-- Run the validator once. Returns whether it passed, and the table it reported.
--
-- Anything other than an explicit false is a pass, so a validator that returns nothing
-- does not lock a user out of a product they paid for over a typo. A table is read for
-- the session facts the status bar shows; ok = false in the table is still a refusal.
local function gateRun(key)
    if not gateCheck then return true, nil end
    local ok, result = pcall(gateCheck, key)
    gateLastRun = os.clock()
    if not ok then return false, nil end
    if result == false then return false, nil end
    if type(result) == "table" then
        if result.ok == false then return false, result end
        return true, result
    end
    return true, nil
end

local function gateArmed()
    return gateCheck ~= nil
end

-- Ask again whether the session is still allowed, part way through it.
--
-- This is a different question from the one the key answered, and it takes a different
-- function, because the key is not kept: it went to the validator as an argument and it is
-- gone. There is nothing here to send a second time.
--
-- It used to call the same validator with no key at all, and that is a trap rather than a
-- feature. Every validator worth writing looks at its argument, so nearly all of them refuse
-- a nil, and the refusal arrives as the interface unloading itself moments after a key was
-- accepted. The worked example's own validator did exactly that. So a caller that wants a
-- session re-checked says what to re-check it with, and a caller that does not gets one
-- check at the start and a session that lasts.
--
-- Returns whether it can be asked at all, then the answer and the facts.
local function gateRecheck()
    local fn = gateOpts and gateOpts.revalidate
    if type(fn) ~= "function" then return false end
    local ok, result = pcall(fn)
    gateLastRun = os.clock()
    if not ok then return true, false, nil end
    if result == false then return true, false, nil end
    if type(result) == "table" then
        if result.ok == false then return true, false, result end
        return true, true, result
    end
    return true, true, nil
end

-- Whether the gate is open right now, asking again if the last answer is older than the
-- caller allowed for. The staleness check is here rather than only on a timer so that a
-- window built an hour after the key was entered is a window that was checked, not one that
-- inherited a pass. With nothing to re-check against, the token stands for the session.
local function gateOpen()
    if not gateCheck then return true end
    if not gateToken then return false end
    local period = (gateOpts and gateOpts.recheck) or 0
    if period > 0 and os.clock() - gateLastRun > period then
        local can, passed, info = gateRecheck()
        if can then
            if not passed then
                gateToken = nil
                gateInfo = nil
                return false
            end
            if info then gateInfo = info end
        end
    end
    return gateToken ~= nil
end

-- What the validator last reported: the user it belongs to, when it runs out, how many
-- times it has been used. Read only, and a copy, so a caller cannot write into the
-- gate's own record through the table it is handed.
function Interface.session()
    if not gateInfo then return nil end
    local out = {}
    for k, v in pairs(gateInfo) do
        if k ~= "ok" then out[k] = v end
    end
    return out
end

-- The old name, kept because a script in the wild may call it. It arms the gate with a
-- validator that takes no key, which is what it always meant.
function Interface.licence(fn, period)
    if type(fn) ~= "function" then
        gateCheck = nil
        gateOpts = nil
        gateToken = nil
        return
    end
    gateCheck = fn
    -- The same function for both, because this form never took a key: it asks whether the
    -- session is allowed, which is exactly what a re-check asks.
    gateOpts = {
        recheck = (type(period) == "number" and period >= 10) and period or 60,
        revalidate = fn,
    }
    local passed, info = gateRun(nil)
    gateToken = passed and mintToken() or nil
    gateInfo = passed and info or nil
end

-- Diagnostics ----------------------------------------------------------------
-- The library writes nothing to the console. A product script shares that console
-- with the game and with whatever else the session is running, and a UI kit
-- announcing that it loaded is noise in someone else's output.
--
-- What it used to print is still available, it just has to be asked for:
--   UI.setLogger(function(level, message) print(level, message) end)
-- level is "info" or "warn". Passing nil turns it back off.
local logger = nil
log = function(level, message)
    if not logger then return end
    pcall(logger, level, "[NewReality] " .. tostring(message))
end

function Interface.setLogger(fn)
    logger = type(fn) == "function" and fn or nil
end

-- Input hub -------------------------------------------------------------------
-- One connection per input signal for the whole library. Controls register a
-- listener instead of connecting on their own, so a window with a few hundred
-- controls costs three connections instead of a few hundred that all wake up on
-- every mouse move.
--
-- The three are also opened on the first listener and closed after the last one goes.
-- Roblox drops a connection when the instance it was made on is destroyed, but these
-- are on a service, so nothing destroys them: connected at load, they would still be
-- running after the interface had been unloaded, iterating over an empty table on
-- every mouse move for the rest of the session.
local keyListeners = {}
local keyListenerCount = 0
local activeDrag = nil
local inputConns = nil

local function isPointer(inputType)
    return inputType == Enum.UserInputType.MouseButton1 or inputType == Enum.UserInputType.Touch
end

-- Declared ahead of the hub, because the release handler inside it closes the hub when
-- the drag it was waiting for is the last thing that needed it.
local closeInputHub

local function openInputHub()
    if inputConns then return end
    inputConns = {
        UserInputService.InputBegan:Connect(function(input, gpe)
            for fn in pairs(keyListeners) do
                local ok, err = pcall(fn, input, gpe)
                if not ok then log("warn", "input listener: " .. tostring(err)) end
            end
        end),
        UserInputService.InputChanged:Connect(function(input)
            local drag = activeDrag
            if not drag then return end
            local kind = input.UserInputType
            if kind == Enum.UserInputType.MouseMovement or kind == Enum.UserInputType.Touch then
                drag.move(input.Position.X, input.Position.Y)
            end
        end),
        UserInputService.InputEnded:Connect(function(input)
            local drag = activeDrag
            if drag and isPointer(input.UserInputType) then
                activeDrag = nil
                if drag.stop then drag.stop() end
                closeInputHub()
            end
        end),
    }
end

closeInputHub = function()
    -- A drag in flight still needs the move and release signals.
    if not inputConns or keyListenerCount > 0 or activeDrag then return end
    local conns = inputConns
    inputConns = nil
    for _, conn in ipairs(conns) do
        conn:Disconnect()
    end
end

-- Register a key / mouse button listener: fn(input, gameProcessed).
local function onKey(fn)
    if not keyListeners[fn] then
        keyListeners[fn] = true
        keyListenerCount += 1
        openInputHub()
    end
    return function()
        if not keyListeners[fn] then return end
        keyListeners[fn] = nil
        keyListenerCount -= 1
        closeInputHub()
    end
end

-- Take over the pointer. handlers.move(x, y) runs while it moves, handlers.stop()
-- when the button is released. Only one drag is ever active, which is all the
-- pointer can do anyway, and it keeps the move signal down to one branch.
local function beginDrag(handlers)
    local previous = activeDrag
    activeDrag = handlers
    openInputHub()
    if previous and previous.stop then previous.stop() end
end

-- Frame driver ----------------------------------------------------------------
-- Everything that shows a live value (watermark, keybind panel, HUD, the brand
-- gradient) shares one RenderStepped connection and runs on its own interval, so
-- a panel that only needs a few updates a second is not rebuilt every frame.
--
-- Opened with the first timer and closed after the last one, for the same reason the
-- input hub is: RenderStepped belongs to a service, so a connection left on it
-- outlives everything the kit built and keeps waking up once a frame to find nothing
-- to do.
local tickers = {}
local tickerCount = 0
local tickerConn = nil
-- Timers created by a timer, waiting to join.
--
-- Lua forbids adding a key to a table that is being traversed with pairs, and a callback on this
-- driver adding a timer is not unusual: a HUD row reading a value that starts an animation does
-- it, and so does a gauge whose polled value moved and now has a dial to fill. Done straight it
-- is an "invalid key to next" out of the middle of the frame, which takes every timer with it.
-- So they queue here and are folded in at the top of the next frame.
local tickerNew = {}
local tickerBusy = false

local function dropTicker(entry)
    -- Marked rather than looked up, because an entry can be dropped while it is still queued to
    -- join, and then there is nothing in tickers to find.
    if entry.dead then return end
    entry.dead = true
    tickers[entry] = nil
    tickerCount -= 1
    if tickerCount <= 0 and tickerConn then
        tickerConn:Disconnect()
        tickerConn = nil
    end
end

-- acc starts at interval, so the callback runs on the very next frame and then every
-- interval after it. That is what a live readout wants: a HUD row polling twice a second
-- should show its value now rather than in half a second, and so should the clock on the
-- status strip.
--
-- deferFirst turns it off, for a caller measuring a period rather than a refresh rate. The
-- gate's re-check is the one, and it is not a small difference: armed the other way it ran
-- the moment the window finished building, which is one frame after the key was accepted,
-- so a validator that refused it took the window down again before anyone saw it.
local function addTicker(interval, fn, deferFirst)
    local entry = { interval = interval or 0, acc = deferFirst and 0 or (interval or 0), fn = fn }
    if tickerBusy then
        tickerNew[#tickerNew + 1] = entry
    else
        tickers[entry] = true
    end
    tickerCount += 1
    if not tickerConn then
        tickerConn = RunService.RenderStepped:Connect(function(dt)
            -- Whatever last frame's callbacks created joins here, before the traversal starts.
            for i = #tickerNew, 1, -1 do
                local waiting = tickerNew[i]
                tickerNew[i] = nil
                if not waiting.dead then tickers[waiting] = true end
            end
            tickerBusy = true
            for e in pairs(tickers) do
                if not e.dead then
                    e.acc += dt
                    if e.acc >= e.interval then
                        local step = e.acc
                        e.acc = 0
                        -- One bad callback (a HUD value that reads a missing
                        -- object) must not take the whole driver down with it.
                        local ok, err = pcall(e.fn, step)
                        if not ok then
                            dropTicker(e)
                            log("warn", "timer stopped: " .. tostring(err))
                        end
                    end
                end
            end
            tickerBusy = false
        end)
    end
    return function() dropTicker(entry) end
end

-- Viewport size, used to keep dragged panels and floating lists on screen.
local function viewport()
    local cam = workspace.CurrentCamera
    return (cam and cam.ViewportSize) or Vector2.new(1920, 1080)
end

-- Round down to an even number. The card area is split in two by a scale of 0.5, so
-- an odd width there puts the right hand column, every card on it and every label on
-- those cards half a pixel off the grid. Text sampled between pixels is the whole of
-- what "the font looks wrong" turned out to be, and this is the half of it that no
-- amount of choosing fonts would have fixed.
local function evenDown(value)
    local n = math.floor(value)
    return n - (n % 2)
end

-- How big the window should be on this screen.
--
-- A fixed 900 by 580 covered almost all of a 1366 by 768 laptop and looked like a
-- postage stamp on a 4K monitor. This takes a share of the viewport and clamps it,
-- so the window is the same shape everywhere and always leaves the game visible
-- around it. The share is set so a 1920 by 1080 screen lands on 902 by 582, near
-- enough the size this kit was designed at. A smaller screen gets a smaller window
-- and a larger one stops growing, rather than the window taking the same share of a
-- 4K monitor and turning into a wall.
--
-- Both dimensions come back even, and so does the sidebar, which keeps the width left
-- for the cards even as well: page width is window minus sidebar minus a 48 margin,
-- and even minus even minus even is even.
-- reserve is room kept below the window for something that travels with it, which is the
-- status strip and nothing else. The pair is meant to read as one object, so the strip's
-- height comes off the window rather than being added to it: a build that turns the strip
-- on gets the same footprint on screen, not a window that hangs 32 pixels lower.
local function windowFit(view, reserve)
    reserve = reserve or 0
    local w = math.clamp(evenDown(view.X * 0.47), 600, 920)
    w = math.min(w, math.max(320, evenDown(view.X - 32)))
    -- The height the window and anything travelling under it get between them, worked out
    -- first and then divided, so a build with a strip has the same footprint as one without.
    local total = math.clamp(evenDown(view.Y * 0.54), 380, 600)
    total = math.min(total, math.max(260, evenDown(view.Y - 32)))
    -- With a floor under it, so a tiny viewport gives up the symmetry rather than leaving a
    -- window shorter than its own header and one card.
    local h = math.max(evenDown(total - reserve), 260)
    return w, h
end

-- The sidebar takes a quarter of the window, within reason: below about 176 the tab
-- names start truncating, above 240 it is just empty space.
local function sidebarFit(windowWidth)
    return math.clamp(evenDown(windowWidth * 0.255), 176, 240)
end

-- The same idea for the window, which is anchored on its middle rather than its corner, so its
-- position is a centre and the arithmetic is not the same.
--
-- Enough of the title strip stays on screen to grab: a config written on a wide monitor and
-- loaded on a narrow one would otherwise put the window somewhere with no pixels, and a window
-- whose title bar cannot be reached cannot be dragged back.
LAYOUT.windowGrab = 140
local function clampWindow(position, width, height, view)
    local half = width / 2
    local left = math.clamp(
        position.X.Offset - half,
        math.min(-(width - LAYOUT.windowGrab), 0),
        math.max(view.X - LAYOUT.windowGrab, 0)
    )
    -- Never above the top edge: the title strip is the only handle, and it is at the top.
    local top = math.clamp(position.Y.Offset - height / 2, 0, math.max(view.Y - 40, 0))
    return UDim2.new(
        position.X.Scale, math.floor(left + half + 0.5),
        position.Y.Scale, math.floor(top + height / 2 + 0.5)
    )
end

-- Keep a detached panel on screen. A config written on a large monitor puts panels
-- where a smaller one has no pixels, and a panel that cannot be reached cannot be
-- dragged back. A strip of it always stays grabbable.
local function clampToView(position, size, view)
    local w = (size and size.X or 0)
    local ox = math.clamp(position.X.Offset, 60 - w, math.max(60 - w, view.X - 60))
    local oy = math.clamp(position.Y.Offset, 0, math.max(0, view.Y - 28))
    return UDim2.new(position.X.Scale, math.floor(ox + 0.5), position.Y.Scale, math.floor(oy + 0.5))
end

-- Element helpers

local function corner(instance, radius)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, radius or 8)
    c.Parent = instance
    return c
end

-- stroke(inst [, key or Color3, thickness, transparency])
-- A palette key is the normal call: the outline then follows setColor and fades
-- with the key's opacity like the surface it wraps. A raw Color3 stays fixed,
-- which is what the picker cursors want.
local function stroke(instance, color, thickness, transparency)
    local s = Instance.new("UIStroke")
    s.Thickness = thickness or 1
    s.Transparency = transparency or 0
    s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    if type(color) == "string" then
        themed(s, "Color", color)
    else
        s.Color = color or PALETTE.stroke
    end
    s.Parent = instance
    return s
end

-- An outline that a control animates between states (hover, focus, capture). It
-- follows the palette colour but the opacity is left to the animation.
local function stateStroke(instance, key, thickness)
    local s = Instance.new("UIStroke")
    s.Thickness = thickness or 1
    s.Transparency = 1
    s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    themed(s, "Color", key or "stroke", { fade = false })
    s.Parent = instance
    return s
end

local function padding(instance, all, custom)
    local p = Instance.new("UIPadding")
    if custom then
        p.PaddingTop = UDim.new(0, custom.top or 0)
        p.PaddingBottom = UDim.new(0, custom.bottom or 0)
        p.PaddingLeft = UDim.new(0, custom.left or 0)
        p.PaddingRight = UDim.new(0, custom.right or 0)
    else
        p.PaddingTop = UDim.new(0, all)
        p.PaddingBottom = UDim.new(0, all)
        p.PaddingLeft = UDim.new(0, all)
        p.PaddingRight = UDim.new(0, all)
    end
    p.Parent = instance
    return p
end

local function listLayout(instance, pad, dir)
    local l = Instance.new("UIListLayout")
    l.FillDirection = dir or Enum.FillDirection.Vertical
    l.Padding = UDim.new(0, pad or 8)
    l.SortOrder = Enum.SortOrder.LayoutOrder
    l.Parent = instance
    return l
end

local function shadow(instance)
    local img = Instance.new("ImageLabel")
    img.Name = "Shadow"
    img.BackgroundTransparency = 1
    img.Image = "rbxassetid://6014261993"
    img.ImageColor3 = Color3.fromRGB(0, 0, 0)
    img.ImageTransparency = 0.55
    img.ScaleType = Enum.ScaleType.Slice
    img.SliceCenter = Rect.new(49, 49, 450, 450)
    img.Size = UDim2.new(1, 48, 1, 48)
    img.Position = UDim2.new(0.5, 0, 0.5, 0)
    img.AnchorPoint = Vector2.new(0.5, 0.5)
    img.ZIndex = 0
    img.Parent = instance
    return img
end

-- The grey grid that sits under a translucent colour so 40% opacity reads as
-- 40% and not as a darker shade. Used by the picker's opacity bar and by the
-- swatch on the control row.
--
-- The holder is a CanvasGroup because the grid has to be rounded off with the
-- element it fills. ClipsDescendants clips to a rectangle, so on a rounded swatch
-- the corner squares poked out past the curve and the swatch read as a square. A
-- CanvasGroup rasterises its children first and the corner then masks the raster.
--
-- The grid is laid out from the real pixel size, which a scale sized element
-- only reports once the layout has run, so it is built again whenever that size
-- changes and skipped while the size is still zero.
local function checkerboard(parent, cell, zIndex, radius)
    cell = cell or 8
    local holder = Instance.new("CanvasGroup")
    holder.Name = "Checker"
    holder.Size = UDim2.new(1, 0, 1, 0)
    holder.BackgroundColor3 = Color3.fromRGB(208, 208, 214)
    holder.BorderSizePixel = 0
    holder.ZIndex = zIndex or 0
    holder.Parent = parent
    if radius then corner(holder, radius) end

    local builtFor = -1
    local function build()
        local size = holder.AbsoluteSize
        if size.X < 1 or size.Y < 1 then return end
        local signature = math.floor(size.X) * 4096 + math.floor(size.Y)
        if signature == builtFor then return end
        builtFor = signature
        for _, child in ipairs(holder:GetChildren()) do
            if child:IsA("Frame") then child:Destroy() end
        end
        local cols = math.ceil(size.X / cell)
        local rows = math.ceil(size.Y / cell)
        for row = 0, rows - 1 do
            for col = 0, cols - 1 do
                if (row + col) % 2 == 1 then
                    local square = Instance.new("Frame")
                    square.BackgroundColor3 = Color3.fromRGB(150, 150, 158)
                    square.BorderSizePixel = 0
                    square.Position = UDim2.new(0, col * cell, 0, row * cell)
                    square.Size = UDim2.new(0, cell, 0, cell)
                    square.Parent = holder
                end
            end
        end
    end
    build()
    local conn = holder:GetPropertyChangedSignal("AbsoluteSize"):Connect(build)
    holder.Destroying:Connect(function() conn:Disconnect() end)
    return holder
end

-- Icons: white PNGs loaded once and cached. The icon pack must sit in the
-- executor workspace. We probe several common folders so it is found wherever
-- it was dropped, and you can force a folder with Interface.setIconFolder("..").
-- You can also hand specific names a Roblox asset id via Interface.icons[name].
ICONS.dirs = {
    "NewReality/icons/", "newreality/icons/", "NewReality/", "newreality/",
    "icons/", "Icons/", "src/icons/", "assets/icons/", "NewReality icons/", "",
}
ICONS.cache = {}
ICONS.folder = nil
ICONS.logged = false
Interface.icons = {}

-- Embedded icon pack: white PNGs stored as base64 keyed by lowercase name.
-- This makes the library self contained, no external PNG files are required.
-- The block between the markers is generated, do not edit it by hand.
local ICON_DATA = {
--__ICON_DATA_START__
    ["adjustments"] = "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",
    ["adjustments-horizontal"] = "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",
    ["affiliate"] = "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",
    ["alert-triangle"] = "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",
    ["archive"] = "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",
    ["asset"] = "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",
    ["ball-bowling"] = "iVBORw0KGgoAAAANSUhEUgAAAPAAAADwCAQAAACUXCEZAAAAIGNIUk0AAHomAACAhAAA+gAAAIDoAAB1MAAA6mAAADqYAAAXcJy6UTwAAAACYktHRAD/h4/MvwAAAAd0SU1FB+oGHBYlJCLfZDcAAAAldEVYdGRhdGU6Y3JlYXRlADIwMjYtMDYtMjhUMjI6MDE6NDErMDA6MDAIUyd/AAAAJXRFWHRkYXRlOm1vZGlmeQAyMDI2LTA2LTI4VDIyOjAyOjI4KzAwOjAwwc5olAAAACh0RVh0ZGF0ZTp0aW1lc3RhbXAAMjAyNi0wNi0yOFQyMjozNzozNiswMDowMHWFn80AABA9SURBVHja7Z15dFbF3YCfECJLQhbCEowCFoQaCocditsRcfkOaFkEqWKNPRX9FKmKC+La2roc28NxqYqfaFE8YEtqi6KigBRiQfArSxFUQFT2IGQhCUsg6R8phZht5t5Z7jvvPPyXd+5sD3Pf+86d+U1CFR6XaWK7Ah69eMGO4wU7jhfsOF6w43jBjuMFO44X7DhesON4wY7jBTuOF+w4XrDjeMGO4wU7jhfsOF6w43jBjuMFO05T2xXQQgI/oA2tSCaFZFJq/EuljBLKKKWUQgoppYwyDlLCfnbj3BI1twQn0pxuXEgvzqI1HUkXvK6KQrawh6/ZxFa2s4syKt2QneBEK9LpyUAG0Z/OJCjIr5wdfM0G1rGCLbEtOpYFJ5HJWfSjLzl0pL2G54kSdrGVTXzCKgo4bLvBQYhVwRmMYCRDhW/CYSlhOW+zlC9sN1yWWBOcSk/6cz4X0EbJzViGKg6xmff4gH9wxHZHiBI7ghPoyGVcwRBaW65JKUt4hcWU2u4SEWJDcGvGkks/kmxX5BSKeIs3WEaF7Yo0TPQFZzGe8fQn0XZF6qCYVbzMQoptV6R+oi24K7eRS6rtajTC1/ya1zlmuxp1E1XBTRjIJMbQ3HZFBNnAC8xnh+1q1CaagrO5ixtJtl0NSdbxLK9F7Ts5eoLP4lZu4zTb1QjIFmbyGrtsV+Mk0RLcilxuooftaoSiik38kkW2q3GC6AhOYDy/4mzb1VDE35nEBtuVgOgIvpx7ON+pd1vf8QK/o8R2NaIg+DQe4C5a2K6GBpZzJ5/arYJtwU0YxUP0slsJjZTzGr+1+fPJruBOTOEGUmxWwQDreZD5tgq3KXgC02ljr3ijPMkDdua6bAnuzDR+Hsn5ZV3M4062my/WjuDBzKKbjYKt8gVXs850oTaWzU5iYRzqhe4s5g7Tdy3TI7gp9/BgzLxCUE8Fz/EgZeYKNCu4Ga/yU5MFRpL5/JRyU4WZFNyJPPqZKy7CLOUadpspypzg7izhdFOFRZ6PGWfmnZMpwb14z+utwVYu5Sv9xZh5iu7hR28turDAxItREyN4MH+jnf5iYpBCLmaN3iL0C+7OMq+3Xoq4kuU6C9B9i+7OEq+3AdJZyKU6C9A7gjuzlE46C3CCMoaySlfmOkfwGXzg9QqQzDx+pCtzfSO4OcsYoCtz59jIAD2zW7pGcCIver0S5PCqnkVLugTfxPUau8NFxjFNR7Z6BE/gca2d4SZ3crP6THV8B3dlOVn6+8NBihiqeuJD/Qhux1yvNyDpvEIHtVmqF/yofyUYgt48rDZD1bfoe3nCXG84ykj+pi4ztYIH87EPjhiaQi5StzhPpY40nvB6FZDBQ+p2aakUMpkLLHSHi/yEu1Rlpe4W3YG1/r2RMoo5l89UZKRqBCfwW69XIWk8oyaKnyrB1/Aze73hJEN5SEU2am7RLVjp8BZQWxwmh21hM1Ezgqd6vRpozrTw8ThVjOBsNju5P/8ke5jPRrbTlCx68D+caajcSs5jRbgsVPzeus9pveuZwkccP+UviVzEs/zQQNlNeJyLwgUkD3+LHsBYA021xXSGsKiGXjjOIgbxKyPlD+HqcBmEv0XP5lojTbXBjAbf0D7P/xqow+ecE+bysIK7sClSQX5VsoYLGowJ3ZYFRpYlXc9rwS8Od4tuyhRn9R7nuUZCfu/jeSM1mUrn4BeHEzzA4ZVX7/KXRtP8hXwDNTmHccEvDid4Mi0NNNAOH1DUaJoS3jFSlxDDKIzg3ow20jw7/L9QqhVGjufI4ZKgl4YRPC1mg/42zjHB7dk7DMXbuCVoXwef6OjEKCNNC8J+VrGenRTRkx8zOEArKwUDe1d87zeyLq6gLyuDXBhc8PiIxobdwv28zaFT/pLO1dwnuUsqiQ5CY/h0Q4EYE5kYTHDQW3RaRMdvHqP4Uw29UMQMLuRjqXwS6C6UrqexadrL+UGQy4IKHkEfQw2TIY+r6gnD/Q1D+ZNUXn0EQpYlMdBY2zpwa5DLgs5kfcgwY00TZSNj2djA521ZKxEpZA+jG32TM4QlNDPWvt10kz9tLdgIbs+5xpolztMN6oV9PCXxSJTFxEZSJJBrUC90CPLWPZjgERF8QbiB2Y2m+aNUPIzr+HmDn99ofB5vuPwlQQSnR/AFYRXzBTZQF0mdhpLIC0yo99PLmG58HmCo/M6lIIL7RfAGXSy48mG1VK6n8TpvcUatv2fzPu9bmKb9EUNkLwnyW3ZgBIPwf8cmoXQHpHMeyTDyeZNvOEAC6XRkDEMt9UAKF5End0kQwYOtNK5hyjkolK6CKumFbClczuVUcYAkWhk/lrom0ntH5G/RyfS32sS66SAYFrBtYEEJZJJqWS/kkCN3gbzgYbS33Mi6yBDclRzrJ6slcq3cfzJZwYn8JJJHaTQVnFnrbbuioRkuFz9BVnAmV9huYT1cKTAN8GNG2K5maHrJzUnLCj47sicdpXBHo2dB3ONAUOMEuSDEsoIvtt2+BsjlpQYUp/A0I21XUQmDZBLLCu5ru3UNch1/rmfHQRYvMtl29RQhtU5aTvDpYRZwGmEEa/gFmTX+1oJJbHBoeX62zISl3ERHTiR/ItWkOTOYyifkU8AR+tKHHnRxKnZIJn3Ez2yRE9wzso9Yp9KELnThGtvV0EYy5/GueGfI0Dui67DijSHi76FlBDcxcUqIR4Ae4i87ZAQnRv4RK17IFA/QIiO4tZq4L57QJJAhmlRGcKdIzkLHJ8IPuzKC4/HM36hyhmhCuRHsiQrCYWBkBGdKpPXoJVs0oczv2jTbrTJGBaVUkhrh6AVZNOWYSEJxwafTynarjLCbxSzjcw6Tw2WcL/5tZ5S2dBcLViouOI22tlulnXU8Sj77qARgNa/ThvN5RN+5ZIFpTXsxweLfwenG4rvZYg7DyWPvf/QCVFJAHsNll6oaIEs0tq+M4M62W6WV2VzHzjo/+ZbxYQIZaSFFdNJJXHCG09McG5jUwMa0Y/yykY1t5kkWSyYuuLXtFmmkiocpbjBFEY+ccuuOAoIbZ8QFR28/oTpWCOw6XM4ntqtZA8EXhuKCTe6ENc1c9jWaZg9/tV3NGigX7C6VgqcUrQ0X2FcxgltXvWA4yg6hdNvF5o4MIfjI6wXDUYGghQCFkRIsiLjgo7arqo3mglM4nSIV2U/5LVos8lsskkRPoXQ9IzUTIDjJ7G/RkEA/IXXROja38YgkgBdczWiBHXs9gkd81YJgEFQvGKCjwLltE+hiu5o1KBFLJi5YOsZaTHEbYxr8fEywQIIa+U4smbjgQtst0koaL3FVvZ+OYWbEljvsVC94t/iGp5ikNXP5cx0rR88hjzcjt1ypWGByFZBZ0XGAr+TjrMUUiVxFDvNZxFYKgdZ05RKuFAwsbJYStoslFBd8kP22W2WAHHKYSiXFQFqEH0HL61mcUAtxwTtEs3SAJuJbQyxRJDqzKPN/9FvbrfL8F+FHXhnB8TOCo4/gI5ac4L22W+X5L2IvOJETLB+p1aOLzaIJZQTvMnRGkKdxtIzg7xyfrowdSvV8Bx/lX7Zb5gFgm+jLQtm3SasjtewsfvmX+JGYcoLXGzqK0dMQFXwqvjpMTvAyCmy3zkOZ4NG3gKzgr/xsVgQo4nPxxLLT6V/abp2HnTL3UVnB/jnaPlL7HGUFr7LdOg8fyiSWFfyV4NHnHl1sY41MclnBhbxvu4Vxzkfi05QgL/g4c2Nxh45DvM9hmeTyB0Q3Z3NEQwvFA0fozB6ZC+RXHR1mpe1WxjGb5fQG29mw2HYr45iPZC8IIjifb2y3M04p5R3ZS4II3ix1jrZHHYvIl70kiOAj8v+PPEqYJ/4e+ATyT9EAqXzjw/sb5xAdRXcknSTY2v0SuekyjxLek9cbfH/wy41EhvOo5jAvB7ksqOAPWGK7xXHGWhYGuSz49qo5tlscZ7wbLFZmcMGL/eoOgxzl7WAXBhd8gOdttzqOeJMNwS4M9jOpmky2RSywgbv045/BLgyzxXl/BEPdu8nHQfWGDaP0lN+QZoAyHgl+cTjBm3jGduvjgLksDX5xmO9ggHZscjrYv32q6Mva4JeHDTNSwHTbPeA4c8PoVRHK8CVW2O4Dh9nNk+EyCC+4gGdt94LD/FXwuIF6CfsdDNCSfPrY7gknKWGQzD6kulAR6qucezlkuy+c5IGwelWFE/6Q2bb7wkEWq/jyUxWs72m2We0M99jPYyqyUSX4M6Za7AwXma7mjbuKh6wTvMVIS53hHpvpLb/Ari5UxlO9m02WusM1DjBRjV61grdwn5XucI/fh5l9ronaiMgLInaAY2yyjv9Tl5nK72CAjqx0PC68bsroH/7X70lUxzT/lruNdodrVHKvSr06zk16g4eNdYd7/I4/qM1Q9S26mjmMN9EbzrGYS1UfJK/n2Inb1T0FxhEbuUW1Xl0jGLJZ7R+2pDjKhTpiJ+g6OGYn1/sjACQoZaKe0Bj6Tgb6kGna8naNKn7NLD1Z6zz66VU/syXEcW7n97oy1/UdXE0T5jBOZwEOUMnTTNEXaF3v4W2V5DJTawmxz6PcpTOOvt4RDJDCLEbrLiRGqWIGd8hFrpNFv2BIYibX6S8mBpnFDbpPwTBxvmYFN/OMP86jFjOZrL9XTIxggET+wE1miooRlnCliSNOTJ2Qe5xbud9QWbHAc4w0c4KN+PnBYTnOkzRjCsnGSowq5TzFE3ofrU5i6hZ9gnH8kRZmi4wYR5moa9aqLkwLhm68wrmmC40MX5JrdrOe+VPqv2RM3IZ+WMlo03sxzQuGvVzFPXF4VO0szuUz04XaEAzwFDebesyIBMf4DTeof53fOOa/g0/SjulcY694g+Rzra2wcbZGMEABNzDa+d0Q+7md4faiAtocwdV04XHG2q6ENtZzG8tsVsDmCK5mK+O4ImyggkhSzN0Msqs3CiO4mjO5lclOTYH8g8dYYLsS0REM0IsZDLZdCSUUcD+v2Hhmrk2UBEMaY7mRgbarEYrtzOYlvrZdjRNESzBAGr/gbtrbrkYgKpnDY3Ln++omeoIB2jKBW+hquxpSHCGP6XxquxrfJ5qCAc5mIj+jne1qCPIJj7GQI7arUZvoCgZozihu5rwI/Jirn1Le4MVw8SR1Em3BAKn0YRyjIrjTqYJ/kscCvojyi5PoC64mm1xyI/StXMFSZjIvymqriRXBAM3oxcUMoy8ZFmuxm1UsYR67bHeHGLEkuJoMBjCMi+lufHXXEVbyDkv4XFWIIxPEnuATtOMSRjHUyGjexkfMZ3ksnlARu4IBWtCFvvSjB23JIIOWyp63qyhjP3vZy1aWs5YdHLXd2GDEtuCTJNGevgygBzl0DPXS4hh72Mhq8lnjwhZ2VwSfIIlmtCSZTLqSTRbZZNGGlpzGmbXSFnCQcg5RThlFFFLMNj5lH2WUU2G7IapwTXBtkujGGaSRSitSSSOdgxRTQgkHOcgBvqCY4+7unHJfcJwT5UlAjwK8YMfxgh3HC3YcL9hxvGDH8YIdxwt2HC/Ycbxgx/GCHccLdhwv2HG8YMfxgh3HC3YcL9hxvGDH+TdAxEQyF0eIWwAAAABJRU5ErkJggg==",
    ["balloon"] = "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",
    ["bandage"] = "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",
    ["barbell"] = "iVBORw0KGgoAAAANSUhEUgAAAPAAAADwCAQAAACUXCEZAAAAIGNIUk0AAHomAACAhAAA+gAAAIDoAAB1MAAA6mAAADqYAAAXcJy6UTwAAAACYktHRAD/h4/MvwAAAAd0SU1FB+oGHBYlJCLfZDcAAAAldEVYdGRhdGU6Y3JlYXRlADIwMjYtMDYtMjhUMTU6MzA6NDMrMDA6MDDo/hjqAAAAJXRFWHRkYXRlOm1vZGlmeQAyMDI2LTA2LTI4VDIyOjAyOjI4KzAwOjAwwc5olAAAACh0RVh0ZGF0ZTp0aW1lc3RhbXAAMjAyNi0wNi0yOFQyMjozNzozNiswMDowMHWFn80AAAYgSURBVHja7Z3Reds4EAbXyRWQEpRKzFRyciVUKjFdwlUguRLxOkgHzEPui2MfQa4IkAv+msGbLEHLHQOEQGn5MBgo8yk6AFgXBIuDYHEQLA6CxUGwOAgWB8HiIFgcBIuDYHEQLA6CxUGwOAgWB8HiIFgcBIuDYHEQLA6CxUGwOAgWB8HiIFgcBIuDYHEQLA6CxUGwOAgWB8HiIFgcBIuDYHEQLA6CxUGwOAgWB8HiIFgcBIuDYHEQLA6CxUGwOAgWB8HiIFicv6IDSHC0RzvYwQ5m1ltvZi92sT46rN3E98ZQW2uH65DiPByHA/Hd0sID+JA8D3FJrD2+qgU3EyPjI9fhSHz7EuwbG3/SEp+nfT5FLwLMzM52vPk1jZn9az+Ib5oaBJ+tWfS6xn7YK/HNED2FLJj8tp0Ia49vpj0E3/mssXNmD9/scsfxzRIr+GDX7D56+7baBkPt8TmI3ar8u0AfhyK97DM+B5EjuMT4+MXXVcZI7fG5iBzB5f6z1xkjtcfnIlLwsVhPzV3G5yJuii43AZqtMQnWHp+TuBFcdtpq7i4+J3GCD0V7e7y7+JyoCC7b2x7ic4LgvcbnJG6RVfqNH+4sPiflRvDRnu1qgw12tbM1cf+zO2Wt/BW5ZjH2bYfzzLcaSlP6OsyW8S3Jn7Ote0Gtnfh2EoLz8reZ4HbysNLXQxGclz9ny11kzV8vfbIucW4oyz4XWcvz533bzOO4zi4GUtdDEWyWkz8neavo1rHWO0RutVfOBvnbYqMjbJtOhKz85U3R8xOMmVlvX0ceZYrOy5/3bbOOw/vih4zXuo+kcH9bxJeTPyf8fFQcBIuDYHEQLA6CxUGwOAgWB8HiIFgcBIuDYHEQLA6CxUGwOAgWB8HiIFgcBIuDYHEQLA6CxUGwOAgWB8HiIFgcBIuDYHEQLA6CxUGwOPOC3+o3jZRwqYjSVVhqYjxCVz2t6d8HN/ZcpCDXFr8Prp21cnCxl6kyLVOCWztVfnB7Ys0cnOwlVaglPUWX0wtrc0pXt06N4Pz7Bb17l5HHGMFlc5Cop5US7CsPUsvB7YG1c5CopzU+RXvqN0FdJOpp8TlYh9F6WuNTdNkJmil6mxyM1tMaF1xTjSgVgmqFjU/RfXQ2YAH92IOcg8UZF3yJDgsW0I09OC44/sbkUAg2OrZi/Y2O0Zq0qXNwF50PuJGn8YdTgr9zqWFXnFLrpvQqGsX74WTfU3+avuB/LLQrzTl4vRz09jT1qWe+4nvzn+RDhQe3J8rnoLeLvc6tlijpn3tsOfFR0h9yQbA4CBYHweIgWBwEi4NgcRAsDoLFQbA4CBYHweIgWBwEi4NgcRAsDoLFQbA4CBYHweIgWBwEi4NgcRAsDoLFQbA4CBYHweIgWJw8wX3BZ90jfcFnJWAEi5Mn+OJ6Vhd9kNVycT2ry3mLPMHU08pjg/zl/cLfU08rUb+JX/ibWU7+nOSeg7vZZzzNd3LHdLPPyM1f9g2G2mGKNvm60pS+cdJW8S3Nn/f2TwVS0S4KD8F5+dtQsA3H4fq/4K5DU0kCaxe8LH/OlrvIeuOtnparfpOxyHrPrfnzvm1YPbKy9Wwz15o7jM8JO1nixAnuK+5tD/E5QfBe43MSJ7jsNl1/d/E5iVtkrX/7S+34nMSN4EvB/+pyPe0nPieRq+iuwp72FJ+LuCnarNRnzfU+Y9Yen4PYz8FdRb3sMT4HsSO4xBhZd3zUHt8s0TtZXfYCZN3rzbXHN0/xqzC3tvbm6zKFL6jtPL6ZFq3XBhueF6fvTHx7ELw0hdulr/b4JtrnU/ApwszM/jGzg3256TWnDc9utcc3RfR/2O829q2GNA3x+Vp4AO/asyuJcQuX2uOrXrANNrSTSYxPXu3xfWjRGx3jNPZojdnv7yj11ttr0e1/7fj+oE7BUIzonSxYGQSLg2BxECwOgsVBsDgIFgfB4iBYHASLg2BxECwOgsVBsDgIFgfB4iBYHASLg2BxECwOgsVBsDgIFgfB4iBYHASLg2BxECwOgsVBsDgIFgfB4iBYHASLg2BxECwOgsVBsDgIFgfB4iBYHASLg2BxECwOgsVBsDgIFgfB4iBYnJ/gPZeaHtKtnQAAAABJRU5ErkJggg==",
    ["bell"] = "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",
    ["bolt"] = "iVBORw0KGgoAAAANSUhEUgAAAPAAAADwCAQAAACUXCEZAAAAIGNIUk0AAHomAACAhAAA+gAAAIDoAAB1MAAA6mAAADqYAAAXcJy6UTwAAAACYktHRAD/h4/MvwAAAAd0SU1FB+oGHBYlJCLfZDcAAAAldEVYdGRhdGU6Y3JlYXRlADIwMjYtMDYtMjhUMTU6MzA6NDMrMDA6MDDo/hjqAAAAJXRFWHRkYXRlOm1vZGlmeQAyMDI2LTA2LTI4VDIyOjAyOjI4KzAwOjAwwc5olAAAACh0RVh0ZGF0ZTp0aW1lc3RhbXAAMjAyNi0wNi0yOFQyMjozNzozNiswMDowMHWFn80AAAcJSURBVHja7d3hcRtHDAVgKJNC6EpMVSKpEkmVyK5EdCVmJ8wPDLN3K5G84y0W2If3+Z/DYZbzsgABMtLDSQjZP94HIFsMGBwDBseAwTFgcAwYHAMGx4DBMWBwDBgcAwbHgMExYHAMGBwDBseAwTFgcAwYHAMGlzvgvbzKSU5ykr/yIc/ex7HwkPZLd3v5kF31d0f5Je/eB2vslPPP6+mSV/ezNf3zr/d/YC6uleM3EaRbnLFE7+XzxiMe5eB9yFbyBbyTvzcfc5Qf3sdsJd+76I8Fj9nJ3vuYrWQL+HVhdE/eB20lV4m+3X3PYIp0roDXvNgH78O2kalEL729UPIEvLT7gslSopd33zOW6KG8eh/AS46AP3OWZ5EcAe/zxpuhBy9ZTX6HPXgQS1aTwNADTjocFdglev1wVICUaOyAt7w4kICRS3TK1WQNN+D03Vehlugt3VexRIeWdjVZwww48Wqyhhhw6tVkDa8H37uarLEHB5V8NVlDC5jDUQWrRG8fjgqQEo0VcMsXAxIwUonmavIbOAGz+34LpUS37L6KJToUriYvwAiYq8mLEALmavKK8Xtwq9VkjT04CK4mrxo9YA5HN4xdotsPRwVIiR47YMvDgwQ8conmanKBcQNm911k1BJt2X0VS7QrriYXGjNgriYXGzFgriZXGK8HW60ma+zBTriaXGW0gDkcrTRWibYfjgqQEj1WwD0PCxLwSCWaq8k7jBMwu+9dRinRPbuvYonuiqvJO40RMFeTdxshYK4mN4jfg3utJmvswZ1wNblJ9IA5HG0Uu0T3H44KkBIdO2DPw4EEHLlEczXZQNyA2X2biFqiPbuvYok2xdVkIzED5mqymYi/4j3GarJH7zqKyEF+W/6+8Xg92Gs16ekoL1YhxyvRGVeTO/mwetcRLeCsw9FO3mwijlWi/YcjTyaFOlbAoQ7jwOAXy0cq0Zlvr9q1b1BxAs7afeea9+EoJTp39y2aF+koN5irSSMxbjBXk0XjDzki3OAYq8kYDq2f0D/gHbvvxLH1E/oHnHE1ednv1k/oHTCHo7lD6yf0DXgvb67//mge2z+l77voEG/hwzhYBOx5g/nmaupoEa9nwOy+cy82T+sVMLvv3JvVNzq8ejB3V1Mm3Vf5BMx4pww+BS48SjRXk3NG3Vf1D5iryTmz7qv6l2iW5ynD7qt632AOR3Om5Vmk9w3m9zbmHm3Ls0jvgLmanDIvzyJ9SzRv75TRarLWL2B23znz7qt6BczV5JzxcFT06sEcjqa6dF/VJ2DGO2W6mqz1KNFcTc516r7KPmCuJue6dV9lX6JZnqc6dl9lfYM5HM11Lc8i1jeYq8m5DqvJmm3AXE1OdS/PIrYlmrd3qtNqsmYXMLvvXPfuq6wC5mpyrvNwVFj1YA5HUy7dV9kEzHinuq4maxYlmqvJOafuqywC5v/xO+XWfVX7gJ9l5/mCgjnIu+8B2gf80/cFBeNankUsAt57v6RAHtv/zI212r+L5nryzHE4Ktrf4KP3SwrCaTVZY8BW3Luv8v4pO6ich6OifQ/mZ8BBuq+yWFVmX1S6riZrFiXaebR3F6T7KouAD6k/KgzTfZXVx4WvSUMO1H2V3XeydvKZcCv9I9qYaPmlu53s5MniF02E5fCtyVti/MT3FvxfSLjyLMKA2wk1HBXcZLUSajgqGHAbwYajgiW6hZDdVzHg7YJ2X8USvV3Q7qsY8FZhu69iid4mcPdVDHibcKvJGkv0FgG+NXkLA77fIXb3VSzR9wo9HBW8wfcKPRwVDPg+wYejgiX6HuGHo4IBrzdI91Us0esN0n0VA15rmO6rWKLXGaj7Kga8TvjVZI0leo0BVpM1BrzcEKvJGkv0UkMNRwVv8FJDDUcFA15msOGoYIleYrjhqGDAtw3afRVL9G2Ddl/FgG8ZtvsqlujrBu6+igFfN9xqssYSfc2Aq8kaA75syNVkjSX6kqGHo4I3+JKhh6OCAX9v8OGoYIn+zvDDUcGAvwLpvool+iuQ7qsYcA2m+yqW6Dmg7qsY8Nzwq8kaS/QUwGqyxoALiNVkjSX6DGo4KniDz6CGo4IBK7DhqGCJFgEcjgoGDNt9FUs0bPdVDBi2+6rsJRq4+6rsAcOtJmu5SzTgarKWOWDI1WQtb4mGHo6KvDcYejgqsgYMPhwVOUs0/HBU4Nzg44pHpok3Z8BJuq/KF3Ca7qtwAv6z6FEHefc+aF84AS9bW6QqzyJIAR8X3M0Eq8kaTsAiB3m7+s9fcnVfhRSwyPuViF/kl/fxPOAsOs6e5Un21d8d5T1nvIgBi4g8y0/ZyV6OInKQP1nDFUENmP6H1YPpCwYMjgGDY8DgGDA4BgyOAYNjwOAYMDgGDI4Bg2PA4BgwOAYMjgGDY8DgGDA4BgyOAYP7D4CzagoEYVH1AAAAAElFTkSuQmCC",
    ["bomb"] = "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",
    ["bone"] = "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",
    ["book"] = "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",
    ["bookmark"] = "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",
    ["brand-discord"] = "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",
    ["brand-kick"] = "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",
    ["brand-paypal"] = "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",
    ["brand-sketch"] = "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",
    ["brand-tinder"] = "iVBORw0KGgoAAAANSUhEUgAAAPAAAADwCAQAAACUXCEZAAAAIGNIUk0AAHomAACAhAAA+gAAAIDoAAB1MAAA6mAAADqYAAAXcJy6UTwAAAACYktHRAD/h4/MvwAAAAd0SU1FB+oGHBYlJCLfZDcAAAAldEVYdGRhdGU6Y3JlYXRlADIwMjYtMDYtMjhUMTU6MzA6NDMrMDA6MDDo/hjqAAAAJXRFWHRkYXRlOm1vZGlmeQAyMDI2LTA2LTI4VDIyOjAyOjI4KzAwOjAwwc5olAAAACh0RVh0ZGF0ZTp0aW1lc3RhbXAAMjAyNi0wNi0yOFQyMjozNzozNiswMDowMHWFn80AAAkeSURBVHja7Z1rkuO2Dka/vpV9DHslo17JyCuxeyVWr8TqlZizEueHrsdOe9x6ACBAEGcqlUoiUo8TQCAl0S8XBJ75n/YBBLKEYOeEYOeEYOeEYOeEYOeEYOeEYOeEYOe0KbjHEWdccMYJR3TahyPKpbU//eV8+crp0qkfl9Cfl8bmoo/on/yXETtk7cPjpy3Bp5l0PODdm+SWBPc4Lthqh9GT5HYEJ5wXbpnxjkH7cLlop4r+tXjLhONsMq+GdgR3K7c+4YikfdB02knR2050V3uybieCt3HEqe44DsFzdDg/HTtXQAheQsVx3I7gTGo9xXHSPon1hODlHGusq9sRzEGHM/baB7GOdgRnpn4OdcVxO4L56GsqudoR/MnYV6pn6NSOYG4qKbnaEZzZe+xrUNyOYAkqmOX6R/sAqueIH/iw+4pARDAd0wOnEMxBZ1dxO4KzaO+d1bFxO4KlSTYVtyM4FdiDwZq6HcFlOFpTHIK5Odp63hTjYH4OgJ2RcTsRnAru67DiLWxh2hH8o+jeDlYSdTuCS2NEcQiWw4TidgQnhX0aUByCZTloj4vj2yR5VL9vCsEleMOotetWUnRS3bviY4gQXAY1xa0I/qm8/4S9juJWBCftA0CvM31pucjq8RMJQMYneeUbG6d5wHvpXVoV/PhclbJQ2fIVdqR5Lf2UyWKK7nH5y/RAh9PmSYOkfUp/KF5s2RN8erpcWdq8cKh2iXV/DoWLLVuC0+z6VNsioNvQRorCxZale/Cy9xJHvK3u18od+ErBmS07EdzhvCg6u9UxvHZ7eQq+Jm9FcIfT4m3Xpjg7d+ArqVyatpGi9zis2HptkjZxig8UStMWIvi0Su/alLtu63IUStP6gtev65pWbW3m/caHsyhyZNopetuyvWvmg2wm6IkCaVozgudHvXTU34n6lgJpWk/w9nmpNcjvgXYNxNO0VoqmfWy5NLXZm+J4RPjxg04Ep4WTGs/bL8NqgXWP8OMHDcGl4iqtHH7pIJymywvm0LtsbqqG+AUgu0xxacHl7op1xO90pIL/K5YVzKU3LdhmyY9gWeEgF8MlBSe2i97NbrE3PkD6ilgMlxsm8Y57vx9c1DA8WndGmykXwbzTGmlmX/UhFMOlBHNPSqZv/ltt6XlC6D5cRjD/JX8+UOqqqZ6/IjJvXuIevOZtjaU8e+gvsa9yCNyH5QVLFTwvf/l3devd8kLhLNIpWq6eTQ//Zl+53i0vFM4iLViunu2+/PPaF39swn4flhUsWc/el1k9LlVWzo+wz0tLCpadDb5eiB7nKse9z2AeD0sWWbRnvvMc0DmJ23sy3jhrabkIlv/I6uBQL5B4z0oqgmsfsGjCOliSEiydnn3DOOEhk6KVFhxxA2OhJRHBNT6sswZbDEtEsO2XzeuALYb5BSft5Tdd0HF1xJ+io7zigSlJc0dwlFdcdDzdcEew5W/56oJpNMwbwVFe8cH06JBXcK9wIfzScXTCKVjgcXXTsCwew3kPjvqZG4ZKmi+CU+hlJ9G74BMcBRY/DEmaS3DMX0nQ0bvgElzLt7h1wVC2cgnuVS+EXzpqBzyCo8CSgnwX5hEcCVqKRO2AR3CvfBn8kqgdcAiOBC0H+dpyCI4ELUmiNecQ3GlfA9ckWnO6YOYXtYMvEOtoDsGBJInWnC7Y3i8i+II4m0UX3GtfgeA7qIJjiCRPojSmCw6kSZTGVMFxBzaO/q+uBHOQgogquNM+++B7QrB9EqUxTTBp10EJQrB9EqUxTXDU0CVIlMZRRddA2t40BDuHJrjTPvxgjohg50QVXQN5e1Pa14XxPX8ZXrY3jRTtnBDsnBDsnBDsnBBsn0xpHIKdE4KdQxOctQ+/CTKlcUSwfTKlcUSwfTKlcQi2z29K40jR9smUxiHYPiOlMU3wp/a5B3PEPdg6mdY8BFsn05pTBRN3H8ySac2jyLJOpjWnCh61z989xEI2Itg2mRpCVMExUJIlUzugCh60r4BzRmoH9BSdta+Ba8gZki541L4GrhmpHdAFx11YjkzvIlK0ZQZ6FxwpOmtfB7cwZEeOcfCofR3cMtK74BAcd2EZMkcnHIKHSNIiDByd8ExVjoqXwS/vHJ3wCI4kzc/I0w2P4EjS/HzwdMP1NGnUug5OyVyz/FyCI0nzMnB1xCU4kjQvbAHD98B/0LgOTiE/5r/BJ/gjYpiNga8r2jJK/+UYv8DCBGHZpK9wvpMVhRYPB87OOCMYOMfadwy8ct7seN+qZJlca5wDby3DG8ERw3RY45f/veiIYRrsr09wR3DEMA3m+JX4smEociF8IvD6E38ERwxvhz1+Zb5N2sWc1iZE5vMlBI+RpjeQsZPoVubrwpiXXs8g062MYLbH1c0wSg0wJYqsiSi11iBQXk3IfQD+Fml6MczTk/fICY40vZQsOf8nl6KBSNPLeJN8ZVF2jY5I0/McZN9IlRUcaXoOser5imyKBoA97xsKrsh4ld6FvOC4Ez9H9O47UWKdrLgT/51die9BSgjOeA/FDwxl6pMyK90VOpmKGGUeLTxS4h48EcXWjQLF1ZVya1W+h+A/FIpeoGQEA/Htw0SB2vlGWcExZMplaucbpZcTFnssVgXF9WqsF92uYgW9OguCvzY5aFLRq7Xi+645xUp6yxdZN1oaFxcc935F7zcb2hkXj3p6dX+U472JV+QPeNPcvV6Knkg4OR4Zq915b2j/rE52XFOPeNXWqy8YAHaSr42qoZyar2in6Csdjo5StYHUfMWKYADYo3cheSj5tGgOS4I9xPFobWRg4R58Y8RrxffjEW/23j+zFcETHX5V+NzY6PSrRcEA0GGPTvsgFnOwu7qQVcFALXfkwfY7o5YFA0CPvVnJIz5spuV7rAsGbKbrAR9WRrrfU4NgYCq8OhOxXEXc3qhF8ESPX0iKmquJ2xt1CQaADj/RFU7ZAz5r/RHO+gRPTJqlo7lisVdqFXxFQvSIXL/YK7ULvtIh4QdBdcaIjN9etN7wIvieSTb+L/v610T+8/cMIOM3nP/EtUfBwR22niYF7IRg54Rg54Rg54Rg54Rg54Rg54Rg54Rg54Rg54Rg54Rg54Rg54Rg54Rg54Rg54Rg54Rg54Rg5/wLvYrAbRXqzO8AAAAASUVORK5CYII=",
    ["briefcase"] = "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",
    ["briefcase-2"] = "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",
    ["calculator"] = "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",
    ["cannabis"] = "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",
    ["cardboards"] = "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",
    ["caret-right"] = "iVBORw0KGgoAAAANSUhEUgAAAPAAAADwCAQAAACUXCEZAAAAIGNIUk0AAHomAACAhAAA+gAAAIDoAAB1MAAA6mAAADqYAAAXcJy6UTwAAAACYktHRAD/h4/MvwAAAAd0SU1FB+oGHBYlJCLfZDcAAAAldEVYdGRhdGU6Y3JlYXRlADIwMjYtMDYtMjhUMTU6MzA6NDMrMDA6MDDo/hjqAAAAJXRFWHRkYXRlOm1vZGlmeQAyMDI2LTA2LTI4VDIyOjAyOjI4KzAwOjAwwc5olAAAACh0RVh0ZGF0ZTp0aW1lc3RhbXAAMjAyNi0wNi0yOFQyMjozNzozNiswMDowMHWFn80AAARYSURBVHja7d3dUSMxEEXhZmsD8UayJhJMJJhIMJmYSJhMdh8MxYD/NDMCqe895xH00FVf9YgndPMvSLlfrQeg7w1g8QAWD2DxABYPYPEAFg9g8QAWD2DxABYPYPEAFg9g8QAWD2DxABYPYPEAFg9g8QAWD2DxABYPYPEAFg9g8QAWD2DxABYPYPEAFg9g8QAWD2DxABYPYPEAFg9g8QAWD2DxABYPYPEAFg9g8QAWD2DxABYPYPEAFu936wEWt4m/sY6IVexjiOcYYmg9Uk/dpP6X/ut4itWXn+3jMfatB+unzMAPsT3zm208s8eH8t7B53kjtnF3tNmmZd3gTTxdOcEWR0Re4NeCDYU4sn6i10UfYD7UkRX4rvAcxEmBV8Un7Ylz3sHThra+i3Nu8LSst9gB2JrYA9iY2AXYltgH2JTYCdiS2AvYkNgN2I7YD9iM2BHYitgT2IjYFdiG2BfYhNgZ2ILYG9iA2B1YnhhgcWKAI6SJAT4kSwzwe6LEAH8kSQzwOEFigD8nRwzw18SIAT5OihjgUwkRA3w6GWKAzyVCDPD5JIgBvpQAMcCXS08M8LWSEwN8vdTEAJeUmBjgstISA1xaUmKAy0tJDPCUEhIDPK10xABPLRkxwNNLRQzwnBIRAzyvNMQAzy0JMcDzS0EM8JISEAO8rO6JAV5a58QAL69rYoBr1DExwHXqlhjgWnVKDHC9uiQGuGbb4hedfiyHZ3V+tvvYtR5hHMC1G+K2p1ea+ETXbhXr1iOMA7h+f1sPMA7g+q1aDzCOO/g7umk9wEdscP2G1gOMA1g8gOu3bz3AOIDr99J6gHH8kVW7If60HmEcG1y7+9YDfA7guu36uoH5RNdtH7etR/gaG1yvDnkBrleXvADXqlNegOvULS/ANeqYF+Dldc0L8NI65wV4Wd3zArykBLwAzy8FL8BzS8IL8LzS8AI8p0S8AE8vFS/AU0vGC/C00vECPKWEvACXl5IX4NKS8gJcVlpegEtKzAvw9VLzAnyt5LwAXy49L8CXEuAF+HwSvACfS4QX4NPJ8AJ8KiFegI+T4gX4a2K8AH9OjhfgcYK8AH8kyQvwe6K8AB+S5QU4QpoXYHFegMV53YHleb2BDXidgS14fYFNeF2BbXg9gY14HYGteP2AzXjdgO14vYANeZ2ALXl9gE15XYBteT2AjXmzAg8TzlrzZgXeTzhpzZsVuPR1QHverA9jRbwWvLMNb2Td4Ijd1RPwRkRe4MfYXvw9vG9lBb5MvIP3vax38KFNPBzdxUPc9/YCaMtyA0dEbOIuVm/Mu3gpuJ2tyg9MF8t7B1NRAIsHsHgAiweweACLB7B4AIsHsHgAiweweACLB7B4AIsHsHgAiweweACLB7B4AIsHsHgAiweweACLB7B4AIsHsHgAiweweACLB7B4AIsHsHgAiweweACLB7B4AIsHsHgAiweweACLB7B4AIsHsHgAiweweACLB7B4/wGdjbdIwJvZlwAAAABJRU5ErkJggg==",
    ["chart-pie"] = "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",
    ["check"] = "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",
    ["chevron-down"] = "iVBORw0KGgoAAAANSUhEUgAAAPAAAADwCAQAAACUXCEZAAAAIGNIUk0AAHomAACAhAAA+gAAAIDoAAB1MAAA6mAAADqYAAAXcJy6UTwAAAACYktHRAD/h4/MvwAAAAd0SU1FB+oGHBYlJCLfZDcAAAAldEVYdGRhdGU6Y3JlYXRlADIwMjYtMDYtMjhUMTU6MzA6NDMrMDA6MDDo/hjqAAAAJXRFWHRkYXRlOm1vZGlmeQAyMDI2LTA2LTI4VDIyOjAyOjI5KzAwOjAwZ7ljIAAAACh0RVh0ZGF0ZTp0aW1lc3RhbXAAMjAyNi0wNi0yOFQyMjozNzozNiswMDowMHWFn80AAAS5SURBVHja7d3dcdNAFEDhy08hogM6iKkEU0lCJSQlUIFNJREd0IF44I2BWNpIV3uPztFbRhrv6vNGduxR3kxh5N7uPQDbNoHhCQxPYHgCwxMYnsDwBIYnMDyB4QkMT2B4AsMTGJ7A8ASGJzA8geEJDE9geALDExiewPAEhicwPIHhCQxPYHgCwxMYnsDwBIYnMDyB4QkMT2B4AsMTGJ7A8ASGJzA8geEJDE9geALDExiewPAEhicwPIHhCQxPYHgCwxMYnsDwBIYnMDyB4QkMT2B4AsMTGJ7A8ASGJzA8geEJDE9geALDExiewPAEhicwPIHhCQxPYHgCwxMYnsDw3qc/4hCf4xQRQ4wxxlNc9z4FG3eKuzjHEGNEXONHPCY//pS5DdNl+rvn6Zw6hsztND3/Y773mWPIne7/Sp1y2nbfw3x74J2mafq2O8fa2+XF+aYRv5lyrgRDPN/Y4zG+JF+dtuwSpxt7fMp59ZH1KvrbzT3OM/ap0m3eOWdklbJW8LyHYaziObwRSWs4ZwWfZ+9XfxXP5Y24zxhODvDd7D2rE8/njRgyBpQDPH/StYmX8CaVAzwu2rsq8VLeIWNQff4tuiLx8tU7ZgwrB/i6+IhqxC2/nK8ZA8sB/tFwTCXitmtvy1lZXNb74LZTUON9cdvcxviQMbisa/DXpqMqrOLWV85JT90s4Gs8NB3XO3Er70Pa5+Bpn64ML3x89nL9ftJ0aZzRJW+M7x6SnkjxK37Gr6bn+8cY4nvWMBfUunqv8SlvkHnANOISvLnAJOIivNnAFOIyvPnABOJCvHsAVycuxbsPcGXiYrx7AVclLse7H3BF4oK8ewJXIy7Juy9wJeKivHsDVyEuy7s/cAXiwrw9APdOXJq3D+CeiYvz9gLcK3F53n6AeyQG8PYE3Bsxgrcv4J6IIby9AfdCjOHtD7gHYhBvj8B7E6N4+wTekxjG2yvwXsQ43n6B9yAG8vYMnE2M5O0bOJMYyts7cBYxlrd/4AxiMG8F4K2J0bw1gLckhvNWAd6KGM9bB3gL4gPwVgJem/gQvLWA1yQ+CG814LWID8NbD3gN4gPx7vFvdV7fGE8RTbdlOkfEcCTevDvdrd0QnxvvvNVWUd5e7zZ7uzGeEoHL8tYFziQuzFsZOIu4NG9t4Azi4rzVgbcmLs9bH3hLYgAvAXgrYgQvA3gLYggvBXhtYgwvB3hNYhAvCXgtYhQvC3gNYhgvDfi1xDheHvBriIG8ROBWYiQvE7iFGMpLBV5KjOXlAi8hBvOSgecSo3nZwHOI4bx04FvED3Teut+qXNY57mP462djfEn7D6A7dgzgP9+GvoshTjFGxGP8jMe9h5TTUYAPG/0afPgEhicwPIHhCQxPYHgCwxMYnsDwBIYnMDyB4QkMT2B4AsMTGJ7A8ASGJzA8geEJDE9geALDExiewPAEhicwPIHhCQxPYHgCwxMYnsDwBIYnMDyB4QkMT2B4AsMTGJ7A8ASGJzA8geEJDE9geALDExiewPAEhicwPIHhCQxPYHgCwxMYnsDwBIYnMDyB4QkMT2B4AsMTGJ7A8ASGJzA8geEJDE9geALDExiewPAEhicwPIHhCQxPYHgCw/sN7EO6lmlZyVsAAAAASUVORK5CYII=",
    ["chevron-right"] = "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",
    ["circle"] = "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",
    ["clipboard-text"] = "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",
    ["clock"] = "iVBORw0KGgoAAAANSUhEUgAAAPAAAADwCAQAAACUXCEZAAAAIGNIUk0AAHomAACAhAAA+gAAAIDoAAB1MAAA6mAAADqYAAAXcJy6UTwAAAACYktHRAD/h4/MvwAAAAd0SU1FB+oGHBYlJCLfZDcAAAAldEVYdGRhdGU6Y3JlYXRlADIwMjYtMDYtMjhUMTU6MzA6NDMrMDA6MDDo/hjqAAAAJXRFWHRkYXRlOm1vZGlmeQAyMDI2LTA2LTI4VDIyOjAyOjI5KzAwOjAwZ7ljIAAAACh0RVh0ZGF0ZTp0aW1lc3RhbXAAMjAyNi0wNi0yOFQyMjozNzozNiswMDowMHWFn80AAA5KSURBVHja7Z1plBbFFUAvQVRWR2SL4EJkR1BBgXgEOQIiJIfFLSqIxhAVcY+oOYlHkhg9GBeEBNQImKiIERHGuEVJlBlEDagYVoOsiqKyOgENoPkxDGKYgarqqnrVNXX9J9VV7/WdV19/X3dXVfmaRMx8RzqAhFuS4MhJgiMnCY6cJDhykuDISYIjJwmOnCQ4cpLgyEmCIycJjpwkOHKS4MhJgiMnCY6cJDhykuDISYIj5wDpABxxHEfQgPrUpwH1OYSa1KQGNakDwGa27vpvE2tYzWpWsYb3pYN2QZVoHrqrQQfa0IqWtKapYR8rWMxSFrOEhWyQTsgOeRdckw50pCMdaWn542Y1syhiFkukU8xGfgV3pjd96OJ8nPUU8Xee5GPphM3In+DaDKAvvTnU87iv8TRTWSmdvi75EtyXCxgkGsFbTGVSnqo5L4JbMJTBfFc6DAC+4mUeZhpfSgeiQh4En811nCwdxF6UMJUHmSMdxv4IW3ABlzGcI6TD2AdzuIunCfgkhiu4JT9jMNWlw1BgGfcyiW3SYZRPmIKbMYozpYPQYh238QDbpcPYm/AEN+Y3DKGqdBgGrOAWJoc2XYcluCYjuUE6iEws5Gb+Kh3EnoQk+CJ+R33pICxQzLXMkw6ijFAEt2UCnaWDsMZOfs8tfC4dBoRxP7g2Y5kfkV6oyjUsZqB0GBBCBffgURpJB+GIZxnOKtkQZCv4QO7jpWj1wg9YwGWyIUhWcDueoLVs+l54hUGslRpcroKv5d1KoRe6s5SLpAaXqeDqTOJHUikLUciFbPE/rITgpjxbSWr32yyjD8t8D+p/iu7J/EqpF5oxj76+B/Ut+Hr+Rm3fSQZDHZ7hRr9D+pyiq/AHhvlNL0ieZAhf+BrMn+CDmUJ/X4MFTjG92epnKF+C6/IiJ/oZKhd4U+xH8FHM5BgfA+WIYs7gP+6H8SG4CXNo4n6Y3FFMH0pcD+L+KroJrya95XIKz3Ow60FcC25EEd9znURuOYUZrt/vdCu4PkUc7TaBnHM6U9w6cNl5TWbSzGXwUXAWE1x2705wVabTzmXo0XAxo9117k7wBHq6CzsyruE6V127+po0gjtdhRwlX3E6M1107EbwQJ6iitszEh2b6cBy+926ENyON91/v4uQ9+jEZtud2v8MrsW0pNeIFjxl34d9wZPTVyNjejDSdpe2p+hhjPN0MnQpppg5bAEOoQun8n3pgCqgG0U2u7MruD1zqeb3fCixhCv3ukY9g3uCfHRoDW1tvvRid4p+Iki9N9C6nK8gL9CGm6RDK4cjeNhmdzYFj6SV33OhxGjurvDf7mSMdHjlcCZD7XVmb4puzqIAV76cxWns3Me/V6XYw2JqumyjBR/Y6cpWBVfhkQD1wrX71As7uVo6xHKozkO2urIleFiQr38u5+39tvmn/4fRFejNuXY6siO4IaMET0bFPKzU6nHpMMvlPgpsdGNH8L3UkjwXFfKEUqsp0mGWSyM7RWPjIqszr0ufjYqyU2wn/hZ8BZzC7MynwEJub3O89JmoKDvFVl9JB1oBczkpaxfZp+jBwerNPydmv9TKWsEHsSKQNWDLzU6xVagVDCtovp8vevshawX/PGC9MdCUy7N1kK2CC1gb9HKh+a9g2MCRWV5xyVbBI4LWGwd1GZ7l8CwVXMCaQL//7s5OsVXIFQyf0oT/mh6cpYKvC1xvLNTnEvODzSu4Fh8FLziOCoaVHGMao3kFXxa8XlVC/R3rG442X3TKtIKrsCrovRTKolRrFXoFwwLam/0hmlZwzxzoVSX8CoZj6WV2oKngmFbLycc7GD81TM7oz7cha4NYaXq/2Sm2Cn+Khu00YJP+YWaahuVCb1xUY4jJYWYVvIojpfNVy06xVR4qGOab3LczqcQOOdEbG8dxgv5BJoLPks600nK+/iEmU/R7NJfOVDU7xVb5mKJhhf6KRfoV3C43euOjKW10D9EXnCZoSQboHqAvOIjdgKySh1+yyhige4DuZ3B9PpHOUSc7xVZ5+QwGaKy3g4tuBZ8unZ8D8lTB6K65rSs4xrWv8vFbdBmnaSan+ef7Sa72B41xil5PPZ3mehXcMld64+QwWug01xNseE8yYZWuOo31BJ8snVsC6KbTWE9wB+ncEmhWsM5FVnVfW8FYI8aLLIB6rFdtqlPBBjerEk7Q+EVaR3CaoEOhrXrTVMF5xJHgEJc5q5w4Epy2xwkFDcHqV9E1fGzEZpm8L8JSMQWqS4erV3BT6Zycka+bDaUoP/aoLjhN0CFxuGrDJDifNFZtqC44LbYSEg4E15XOKbEHDqboQ6VzSuyBgwpOgkNCeT5NgvNJDdWGSXAef+ZAfeuxJBigr3QA2jio4IOkc3LI8/QxX2pMhJqqDdUFh7jlhj1eoH+uFCsvIal+syGPn1R6vzL35VnpgO3npl7BeRSs97HyHP3ZIR2yIspPx6kLzuM9l6M12xfm5uXYL1QbqgveJp2TAT20jyjMSRUrXy+oC1b+mwkIzRe1ACjkHOmwFXBQwdY3H/fAD40eU5hO/2z7JHhgu2pDdcGbpHMy4CAmGh1XyHmBK/5StWHcgqE7txgdNzVwxcrzaeyC4deGC6eGrXidasP4BcO4DIpDfWspCf4W5oqHBKrYgeCPpHPKhKnixwJV7EDwcumcMhKXYgeC35fOKTPjuMrouMe4WDr0vfhAtaH63aQCNkpnZYErGG903CAeCerX+NqUqDXUuciKQbD5RD00oPtpH6vq1Xu7MO+fwqWYKp4YkOIl6k11BC+SzssSpp/FE7lUOvRdLFZvqiP4Hem8rDHGsIof4ifSoQOwVL2pjuB50nlZxHyivkI6dLSmaJ1llPL4Cvi+ML2iHsY44cgdLaO0lWXCidnFtIrHC1fx++p6dVe6i2mShrwqfk2nsZ7gtwTTckMeFTsUPEssKXeYfmkab7pdZGa0BOstCF6FDRQIpeUS08utGfTzHuvnFOjc/NCr4K+Z6T0hH5hO1DcK3Gd6RW9M3T0bXvSekB/MFC81fKgvC5qv1yTBZZgpnuo9zmf0musKXh3NL9J7Y3K5tcZzjPP1dk0y2flsmueUfKL/G/WHniN8TvcAfcF/8ZySX3Qnat+vxWu/4Kov+F/823NSftFTrL0baCY+1fsODGYbRD/uNSn/6Cj2K3iS/iMHJoLjnqRBR/HZXuOapH+IyQ7gedoD3ByVX7e6MMdjRG+b7JphUsHwkMe0pFCp4tu8RvSIyUFmFVyPT72mJsXVjN3Hv17KA16jaWBy1s0q+DOmeE1NijH7eMzOt97pZkVlJhge9JqcHPfzJC33+r8tmcr9niO5z+wwsykaKseFVhl/ooglLOBAWtCK7gz2HsF8jjc70Fzw9dztPc3Ky0X82exAc8G1WBPlzf8Q+YTGpos7mX4GQwmjpfOuNIwxX7vLvIKhgDXUks69ErCZo8wXsTKvYNjEGOncKwX3ZFmjLEsFQwFr1Re2TRixmcZZ3ijJUsGwSfwljvi5I9sLQ9kqGA5lJXWkz0HErKdJtlVCs1UwbORX0ucgam7Lughs1gqGaiyimfR5iJTltFFflbJ8slYwbOd66fMQLUOz6rUhGJ7hVekzESXT+Ef2TrJP0QBtWSB9NqLjC5qrr4ZVMTYqGBZyq/DpiI9bbei1VcFwAPM9P2EYN0tpp76q+76wU8Gwg0G52MwiH+zgPDt67QmGd7hD6HTExy/sLVlla4qGNE3bophu9tbUsykYWjNXfV/MRLl8Rjs+ttedvSkaYLHYuhXxcLFNvbYFw2TD1S4Spdxue4NMu1M0QDXm0NHX+YiMmfSyvaKtfcHQmAXpcTwDltPB/v5ytqdogA/pa+tbXCWihL4utg90IRjmBLjLQeicq7NIsDpuBMNkfunwZMTHzTzvpmMXn8FlTOTH7jqPigkMddW1S8FVmcmp7rqPhkIGulsxz6VgqMXLdHY5QAS8SVf1/bz1cSsYavESXdwOkWveo4vb7YpcXWSVUUIv3nA8Rn5ZRFfXu1G5rmBIE3VFvMup7vd0dV3BACX0pNjDOPnidbr62LLXh+BSxTO8jJQXiujJFh8D+REMXzIw3WfazTR6+tqiyJdg+JorGBHM7n+SjOIsl1+Mvo2Pi6w9OYfHqOZ3yKDYySWmq22Y4VswdGIajX0PGggl9LPxtoIO/qboMt6kPS97HzUEVtHFt14JwbCB3owU2K9Elukcy0L/w/qfosvowWQaSA3uncs9L3y4GznBUJdJAhtL+Wcp/d3czFdBYoouYwP9uYANghG4Zzt3cJycXtkKLqUhj9JTOghHzGWIznbsLpCs4FLW0Yvz+Ug6DOtsYTidpPWGUMGl1OF2hksHYZFpDLf7hoIpoQgGaMMkOkkHYYF3uJLZ0kGUIT9Ff8MiOjOUddJhZGIl53FCOHrDquBSqnM5N+fyG/JGfstYf7cR1AhPMEANhnET9aXD0GA9oxnr4s2ErIQpGKAGVzKCetJhKLCOuxjv6/6uLuEKBqjOYK6inXQY+2A1o5iYdblBl4QtuJRuXMUADpAO4//YQSF/5MXQH2HIg2CAw7mQC2gvHcYuVjOeSfm43s+L4FJacCHnc4xgBPOZQSHzpE+EOvkSXEp7+tGfjlTxOOZ2XqWQad53/M5MHgWX0pAB9KOH4z24t/EGRRQxm63SCZuRX8Gl1KA7J9KRDjSx2u9GZlNEsf6O26GRd8HfcBgncQJtaUXLDJv9rKSYYoolHq5xQzyC96QxrWhFE5rQgEY0KueHz8/Zuuu/Ej5kJR+whtUsz+tEXDFxCk7sJqS7SQkHJMGRkwRHThIcOUlw5CTBkZMER04SHDlJcOQkwZGTBEdOEhw5SXDkJMGRkwRHThIcOUlw5CTBkZMER87/AKrg1Qq/75FcAAAAAElFTkSuQmCC",
    ["cloud"] = "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",
    ["clover"] = "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",
    ["coin-monero"] = "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",
    ["coin-pound"] = "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",
    ["cookie"] = "iVBORw0KGgoAAAANSUhEUgAAAPAAAADwCAQAAACUXCEZAAAAIGNIUk0AAHomAACAhAAA+gAAAIDoAAB1MAAA6mAAADqYAAAXcJy6UTwAAAACYktHRAD/h4/MvwAAAAd0SU1FB+oGHBYlJCLfZDcAAAAldEVYdGRhdGU6Y3JlYXRlADIwMjYtMDYtMjhUMTU6MzA6NDMrMDA6MDDo/hjqAAAAJXRFWHRkYXRlOm1vZGlmeQAyMDI2LTA2LTI4VDIyOjAyOjI5KzAwOjAwZ7ljIAAAACh0RVh0ZGF0ZTp0aW1lc3RhbXAAMjAyNi0wNi0yOFQyMjozNzozNiswMDowMHWFn80AAAsUSURBVHja7Z3RYds4DIb/Xm+AblBkkqqTRJngRrA6wd0GViaJMkmZDbpB7kF17SSyRVIAAUL88tYqNqk/AEkQBD+9ouGZv7Qb0JClCeycJrBzmsDOaQI7pwnsnCawc5rAzmkCO6cJ7JwmsHOawM5pAjunCeycJrBzmsDOaQI7pwnsnCawc5rAzmkCO+dv7QYUggAQCF8BvCAAmLSbVAbfAhPu0YFAi/8bAAQEPHoW+5PLvGhCh68Yop8PmPCMUbvZEvgT+IAOXdZvztY8aneAF18CdzheccfxBEyenLYfgQn3CU55jYAfPmzZi8AHRnFPBIx4RNDu2jY8CEw4Zo6661TvsGsXmNcxXyNgxA/truZRt8ASjvkaldpyvQIf0G+eMadT3eSrToE5lkP5VDX5qk9gXXHPjHXEvuoSWMctX6eCyVctApeZLecQMOGHXYdtX2C70p4JmPCg3Yhl7ApMIHwzL+2ZgO8W7diiwPMubqfdjGQC7rSb8BFLAhPugYps9iOjPUdtIaOjfmFPdOisxbq0Be5xX6Ezvgbhvgl8xkrIgrdPxtASWHKLr3GBRl404YifTuUlaz6pvAX3OGp3ek+UXiYd0Wt3WZhP2g14S0kXTXhyL++o3YD3lHPRhJ/anS3As3YD3lPKRXd40u5qAQwGK8u46H3IC3uByjIC70XeyVoUCyjhoglP1taGQtxZ3C6Ut2B/4chlHizKK2/BT04jVu+Z8F27CcvIWvBhJ/LCbuqdpAXvZXJl2H5lLfig3bliPGo34DpyFrwf+zUXf75EzoL3Y7+jdgNuISVwv5vplcH48yVSAt9rd6wgk3YDbiEj8J7sd7IZ4DghI/B+xl/YlldKYNLuVkFMj8AyAvfanWqckRD4m3anijJpN+A2EgJ32p1qnJGIZBk6z1YAw1EsQCLprtfuEubcimdMIAAdvplokxL8Fqyd+Rzw8GFclKwSYDKP4wz/GNyp9mfA3cK0J+CHmMCk2t9VuAXWrYIz3Nh4l5PYNNwCay6RwkpehUyNOlLscQTcAneKfVnPSpZIrPmq2OMIuAUmtZ6MESGHIBCW6NV6HAWvwJqdDVFP8dswKfY5Al6BNUfgl6ingsA3d4q9XsWPBU9q32w6uYFT4F61J4HxqTQ61X6vwCmw7i4SMT6V+s29as9vwilwp9oTUmyj4QwWPoG1KznHvWQZL0N23TSfwNrb/DEvWc6ZmrVhTgvWhSJms3IFnDqrEnMJ3Gt3BEC/8pJlzzpqD1FX4NoP/mmie7fuUJAvwGbyjOHngeNTehMWDHxBB+AFv979O+HfApuFBINJtDwWbOscf/idsBNQ+mIAg7ewcAi8p4OiaywlDKnCIbAt+9XG2OUc22fRezpoFgPhydKSabsF25g/W2OwMhZvtWCjqz91BitVsbda8L5OMaRhYk69zYKN/JUahTDgp3aEYIsFt+VRHKmXStOfq4bC9itstwjclkfxxFwQvxyU2ejo8wVul2ukEwBMeEb4s1IOv2XFzdsaN6yt8wVu06uSZEucO8lqo29ZKPeN5wlc4+WvtUN5Q2Kei27RKw2yrvzIseAWvdIhK6MsR2DTmfyuyXjzOS66zZ+1yHDS6Rbca/dyx2TkX6cLrJ3/vG+Sd5rTBe60+7hrKPUXUgWudwY9YMAdPuEOd3iwXaX9BslOOnWSpV0FK49p4doqydpZkiTmiqRaMGn3L4NhMY4rWTtLki7tcf8Ce6udRWmPp7ro2tbA68dJaht0EtfC3gVeryRZ383kSdUx01w0afctkTHiVUjUzpKFUh5OE7jT7lsicUfB1DMfJSlzxbsWU9RTQbuZiVDKw2kCG6/L+IGg3QARklTgr/jOxQDgEaFA1fag3VVRXlN++tcyPL3Sh++m10Py51BUr6hQr7joUzRLc9GhyN8cX+SJop7qivSKj5DysD2BOSNPmrWz5AgpD1ubRU+sVdspyoZ77U5LYi2SxR15GlfrwNd3ACfppqZUCw6iTeePPK3VzqovwzukPW5LYInI0y2J+wpPaIS0x1MFnkQbH/fpaV0kDDgsjMWEQ5XH59J6nzwGy54JjhtdcvZ/3h7frDWbAwC+pxlZqsCym2ux04f8qV5g2xEbUCrS9pbUyzCTIll4xeuTYIymlsgTV6QtnWOqXunrYMnNNYp6qhNsQQyaOV7JtTDTBQ7JvxFPDZEn3RyvMfUXcgSexJpvP/LEG2lLJeOzc0KVj2IdoAgb1l256tyPeCKjWHGOwJOgDduOPOnmeIVSFrx2jes2LEeedHO81r3HEsnLpPnnKLoYOKgtQ26juYxLXiDNP7lllKSziW1GnuQibeskZUNfNNl4ITS+yBMH8pG2a2Sfh2ylDFOIsyJ+C95wn8uWjI68Qb9mKOqpjv17N0zbtgicNW2vGp1IW8zl9VfZVhC8voNb24irGMk9AmdOr2a2Jd2FnblpjUjbsC36vzWrUjKqZZHSkbbNQaWtAstGtSxSNtK2+e22i7FyGPBYpKgLw3WX7Wq7PC4jbQQIRdoS86+W8Hg5ZUkkI20s19XyCLxHG5aHwX75Lojerw1LkVX++yNch8/ksjz2CtPqhMuC9xbTkic1//kKXBa8v7i0LCPXB/GdD25OmhO2t8nlooE20eKEyUHznvCfyr8Hp4x8H8UpcEbWbmMRxuGO00XbnkkP0DkNmAObg+YV2O4oXFfF9/W6IgnwVtmxuXVYW8V31qGO14ItOunbdxwcDIrM6KC5Ldhe7WXd04A5MLeHuxDaVOg1xKJ7GjAH5rUIt8C2lko1Vnxnbg23wKHQa4ijxorvgffj+AWeCr2IGOLaErSbecHI/YH8xUgtbToE7QYkwz7E8S6TAFtLJb3TgLlsOsWwBL8FB0N2Q4xPlSFwf6BEvWj2RmZDUU912s38w8j/kRIC25mV1lB36xKBRaZ3C6aIp3rtZv5h4v9IGYEFGpqF/bpbl0wSpiFzZ4OdpZLtultvEXlrMgJvOpPOjOW6W5dMMtsenweZ5r6YGdm+oAPwgl/v/p3wD/7TbtwFDzJzF/5Axwlb2R02626dYTlotoScwDYPpNmqu3WG5aDZEnIXY9ks7kDaDVhEcM4iefPZvgq0bEFw1SEpcDA2zlnlQdLXyY3BMxaT2mwhNr2akb6c8tHkSGwHYXnlLRggPBmd2ujDdIr/FvLXywbpv9GKKTANLXF/8N4KHsYitva9pMwF0WOban2giLwlxuATbSw+E2SXRpeUE7hJfEJ85nxJGRc9E/C9uWqMZSedJS14Zt+hj6F0xlp5gedEmr7816ozSe353kJDYAAgHE3tF0tTcFr1Fi2BAaDH/S5EVhMX0BUYIHTORQ4YdfPEdQWeIXT4hs7VEmou7WjgCIAFgU+Q+fJG64Tf2V9BuyEnLAl8ok7HHTDi2d7mqEWBZ2qxZzPOeBm7As8QgHv0Jsdnozb7FusCn7AVHKlC2plaBAZmp31Qt2X1hU8aNQk8oxkeCQYLp61Qn8DAfKCMCn+najwqnzoFLu2uK7TcE7UKDJQ6QlbZmPuemgUG5EUuvn/LTe0CA3KpQJWOum8pmbIjhUQqUMCAu/rl9WHBM5zOmrWovi5+BAaADsfNztqFYz7jS+CtO1GVz5iX8CbwTOpOlPEdoS34FHiGQL8zRejKE/P2fCXbBnl4FvgSwqmw4Ve8IMDe7RJC7EXg3eJhHdy4QRPYOU1g5zSBndMEdk4T2DlNYOc0gZ3TBHZOE9g5TWDnNIGd0wR2ThPYOU1g5zSBndMEdk4T2DlNYOc0gZ3TBHbO/1gxSzrbGymIAAAAAElFTkSuQmCC",
    ["copy"] = "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",
    ["credit-card"] = "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",
    ["crown"] = "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",
    ["current-location"] = "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",
    ["database"] = "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",
    ["device-floppy"] = "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",
    ["device-imac"] = "iVBORw0KGgoAAAANSUhEUgAAAPAAAADwCAQAAACUXCEZAAAAIGNIUk0AAHomAACAhAAA+gAAAIDoAAB1MAAA6mAAADqYAAAXcJy6UTwAAAACYktHRAD/h4/MvwAAAAd0SU1FB+oGHBYlJCLfZDcAAAAldEVYdGRhdGU6Y3JlYXRlADIwMjYtMDYtMjhUMTU6MzA6NDMrMDA6MDDo/hjqAAAAJXRFWHRkYXRlOm1vZGlmeQAyMDI2LTA2LTI4VDIyOjAyOjI5KzAwOjAwZ7ljIAAAACh0RVh0ZGF0ZTp0aW1lc3RhbXAAMjAyNi0wNi0yOFQyMjozNzozNiswMDowMHWFn80AAAVsSURBVHja7dzvcdtGEIbxZZwC3EHOlQipRFQlpCoxXQmhDtKBLiWkAuWD7BmOnZns4g9379Xz09cDdKdnABAYCoc3g7LfsieAfRFYHIHFEVgcgcURWByBxRFYHIHFEVgcgcURWByBxRFYHIHFEVgcgcURWByBxf2+yV6aPVr7/oN1upl16/Zi3eb1uzus/NJds0c7knUn3S72vG4XawI3e7Rz9t9A3srIywNPds1e+4exIvLSD1kn8t5Rs6Odlm267Ai+2pS95g/oYk/xjZYcweTNcbSv8Y3igU/kTbPgRP3pHBs/2SV7lR9as3/sr8gG0WvwK/e8ybp9iQyPnaJP5E3XYlfi2BHM/5pWEDqGI0fwwjsxbKxFSkSOYK6/VQSO4cgR3LLXhe+a/1bVH/iYvSrcePAO9Ad27xJ3MHkH+gO37DVhCQKPqXkHElic/zaJhxy1HHzD+FalOAKLI7A4AosjsDgCiyOwOAKLI7A4AosjsDgCiyOwOAKLI7A4AosjsDgCiyOwOAKLI7A4AosjsDgCiyOwOAKLI7A4AosjsDgCiyOwOAKLI7A4AosjsDgCiyOwOAKLI7A4AosjsDgCiyOwOAKLI7A4AosjsDgCiyOwOAKLI7A4AosjsDgCiyOwOAKLI7A4AosjsDgCiyOwOAKLI7A4AosjsDgCiyOwOAKLI7A4AosjsDgCiyOwOAKLI7A4AosjsDgCiyOwOAKLI7A4AosjsDgCiyOwOAKLI7A4AosjsDgCiyOwOAKLI7A4AosjsDgCiyOwOAKLI7A4AosjsDgCiyOwOAKLI7A4AosjsDgCiyOwOAKLI7A4AosjsDgCiyOwOAKLI7A4AosjsDgCi/MH7tlTxY3uHUjgMXXvQE7RY+regf7A37LXhBsv3oH+wHP2mnBj9g6MXIPdO8Xuundg5BrMSbqKs3/o4c0/ttlr9spgZmYH/9DIEdztKXtlsNDxGzuCzZpdrWWv78MLHL/R++Buz9mr+/D+jA2PPui4xE4Q2Ng5ei8TO0W/OxE5yRw9fpc9qvxG4BQL8i4L3O2ZxHd3XpJ32Sn63WRf+UR9J92elj5HXB7YrNkjR/Luul3W3LusCWz2HnmyKfuvIGplXLP1gd81m+zBmjVO2qt1M+vWN3vm8Dbaz/HN5xra69W512P6+oM/432j4w/nuJ7628sYL3Bzjuuhvc7OcVP28qPGCzw5x/0d2mts9EDGC+zVdxndspcVNV7g5hzXQ3v1jvb+9jJGC9zcI3v6DEoYLfC003676jE8WmCvObxFd45r2UuLGS1w7l1wZAZFjBa4Ocf18J5n57gp+08QM1rgyTkufl8reic8WmCvvtsWLXtpMaMFbs5xPbxn7xbeGRQxVuDmHtlLzKKAsQJPO+5b9E54rMBe86KtunNcy15exFiB8++CI7MoYazAzTmuL9r77Bw3Zf8ZIsYKPDnHLbunlbwT3uZLd3s4mdlxgOtdN7PZXuySPZH/VjPwiF+q3+Arrnv4dM6ewa9OdrHP2ZMI+2yTBd5+cy/1rsEj/+/i2U7ZU/hZtVP0ZNfsKaz0VOtqXC3w63DX3p91+5I9hVu1TtEjfGr+P63WfXKtwA/ZE9hEqetwrcBT9gQ20bIncKtW4JY9AT21PmSVmswKoTdZ7avWEdyzJ6C3CgJvb86ewK1agQs+y12g1OPKWoEV3kndaz3JqhZ4/HdSF3sjb63A478LM/wuyb1VCzz2ixLP9T5F1LoP/uFop+Eeeqx4G92eagb+8eataYDM3cwuVvYOoGpgbKTeNRibIrA4AosjsDgCiyOwOAKLI7A4AosjsDgCiyOwOAKLI7A4AosjsDgCiyOwOAKL+xetzcYq+lBYzAAAAABJRU5ErkJggg==",
    ["device-vision-pro"] = "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",
    ["diamond"] = "iVBORw0KGgoAAAANSUhEUgAAAPAAAADwCAQAAACUXCEZAAAAIGNIUk0AAHomAACAhAAA+gAAAIDoAAB1MAAA6mAAADqYAAAXcJy6UTwAAAACYktHRAD/h4/MvwAAAAd0SU1FB+oGHBYlJCLfZDcAAAAldEVYdGRhdGU6Y3JlYXRlADIwMjYtMDYtMjhUMTU6MzA6NDMrMDA6MDDo/hjqAAAAJXRFWHRkYXRlOm1vZGlmeQAyMDI2LTA2LTI4VDIyOjAyOjI5KzAwOjAwZ7ljIAAAACh0RVh0ZGF0ZTp0aW1lc3RhbXAAMjAyNi0wNi0yOFQyMjozNzozNiswMDowMHWFn80AAAjWSURBVHja7Z3beeNGDEaxSQrYEugO3IHpDpIKLHWQVGC5hFRgbQVJB5Y72FSw3A6cCpIHrz6LlGXOBcAA/+C8hl5eTjDCgJjhp/8oQOan1hcQyBKCwQnB4IRgcEIwOCEYnBAMTggGJwSDE4LBCcHghGBwQjA4IRicEAxOCAYnBIMTgsEJweCEYHBCMDghGJwQDE4IBicEgxOCwQnB4IRgcEIwOCEYnBAMTggGJwSDE4LBCcHghGBwQjA4IRicEAzOL+pn3NANjTS0vvEGHIjogSaaNE/6SXUjtJEeu1R7ykRbOuidTnOIfqSn7vUSDfRE93qn0xP8SBu92zLOTk+x1hA90pPWLTlhS3uN0+gIHuibxmlcMdGtRrqlM0TfqZzFF4POU9GI4IjfS1zJx7BGBD8qnMMnCk9GXvCGRvnbcMooP7OQHqJjeP4Y8VRLOoIjvfoY8VRLNoIjflMQTbVkIzjSqxREn5Kk4Eiv0hBNteSG6Bie0xFMteQiONKrdARTLakIjvjNRSjVkorgSK9yEXpiMoIjvcpHKNWSGKJjeC5DJNWSiOBIr8oQSbX4Izjitwb2VIs/giO9qoH96XELjvSqDvZUi3eIjuG5HuZUizeCI72qhznV4ozgiF8uGFMtzgiO9IoLxifJJzjSKz4YUy2uITqGZ17YUi2uCI70ihe2VIsngiN+JWBJtXgiONIrCVieKofgSK9kYEm16ofoGJ7lYEi16iM40is5GFKt2giO+JWmMtWqjWCd9GpPW7qiT3RFt3RLB919ahpT+YTrInijIPhA2zOhI911tONH1WYPNYI1hufLN3dPO/Gz26Aq1aoZouXTq90H/+8+dCO4KtUqj2D5+D3Q7coRT93MwItTrfIIlv71nVb10ju/zqgUP+1SwfLVq33CMZPmpoBNKa5qlQ3R8sPzRFdJx2nk8TYoTLXKIlg+vdom33YvFKZaJREsH7/7ZMFEqtvlNqYg1SqJYPn0Kl1vXxQ8+XzBNtKrI4PwtdiiINXKHaLtpFfHW+5rF9vsVCs3gu2kV1rXY4vsVCsvgm2lV72+rMxKtfIiWH7O+ZB1dG/x+0qWhRzB8ulV3pveoZvXDXOyUq0cwfLfGThkHd1XenVKxsiVLljjW0fPGcfedzZFOiXDRbrgG4ULnzKO/dJRmfKc5NE0XfCm9T0tUPqohVGG1AM9f7uwZ8VD6oG2BI+Zx08dvfIvxJbg/Hntgfah+CPSBR8UrqYkU3/Q+YKYMZLvOV3wF5ULL/k6aT/9lW98Tz0wJ4InhQsfi8qPvSmeJCI49z1PKbuiCVlfA3WGiby3SVqrCcq6gL91UtvKeuOW+8Jf6yvAofgS68sBZuROk7TmnWXfCscvfGTqLZkH6zzEoUgxem0rZbXHgnzBWg8xFL93b9mUVLL0FJe8EsQtXxbd18+7klO90L90TZ/Fb+maXug7vWT+1USfaVC4Ol1uy2qJZYKJvtJnlaWbI71ktQG88qx0dXoU6i0X/Np9MSrc2kh5nR7HqxvoWuHqdNjS36V/Wi7YuuJ/6FeQYXqf2Ws6o0awXpyM9J2+Zv7NC11DxPCBfqv589r3wVoZa8lbpvyot0d2YWMJx26zWgXC3PKl/3UPeeu03oWjo0OrtJBb+NC5KjkY9PIItlrbyjnWHkyrpHl6srSqR2XlS59seZqkuJrutJrfcsqXnpemFRc2lvB1VWr1VGzoDj6KmaKXqHYePEev8JFSvhzKqz+N2dGffP8Yp2Bbta2/nMb5nv7g/Od4BWvWtj5WvKHfFa6Cn8q61TkSn3jXKnzsLtZovW41XF23OkdCsN5kZk8PZ7n7QI9OXxWyFDaWSAjWna8efkieaKCRbswtc01FqFwkI7ivkgQPbDPfOVKrC6d3Bs/gMkJ6JZeP7rtaTFKHmF7Z9cG9LQkrhbFudY7sAvBQvI7wSCeVZL2htZrJJwIz3znygvtYElaGuF4dwaH4fUQKG0t0NmHBXS9UjopeLcHIS8LKUPtsgdY2SrhLwsoQnRqdordPVuxo9YZgYWOJ5kZofW2Uchm16CXS3ukuCh8ff1FVAJ1p0ileX8bzkPdNCgb0Bfdc21IobCxpIbjXwkcDva12m+1xVly0hUo9bQT3V/hopLfdftG9KW5W5mm3IXhPTT2KhY0lLXd876Wpp6He1lv691D4UK1bndP6mw3oipuPUm3mwXNwCx9NZr5zLAhGLXwY0GtFMKJipY6NNVr/Bh9BmxUb0WtHMFbhQ60hZx0rgrGaehpPjU6xIxinqadpYWOJJcEYTT2GopfImmD/hQ/lhpx1rEyTTvHb1KPekLOORcFea1smChtLbAr2WPgwqdfeb/ARb7PiZh0ba1gV7KvwYaZudY5Vwb4Um0ut3rAr2E9Tj6nCxhLLgg28Lk/AtF7rgu0XPozVrc6xLti2YgcjjNV58BybhQ+jM985PgRbLHy40OtHsDXFhme+c+z/Bh+xNCt2o9eTYDuFD0MNOev4EWynqcf81OgUT4JtNPUYL2ws8SW4fVOPq+gl8ie4beHDXEPOOn6mSae0aeox2JCzjk/BLWpbTgobS7wK1i58ONXr8Tf4iOas2GxDzjp+BesVPhzVrc7xK1hPscPU6g3PgnWaepwVNpb4Fiz/yt25Xv+CZQsf7upW5/gXLKfYQUPOOn7nwXP4Cx9uZ75zUARzFz5A9CIJ5lTseuY7B+E3+AjXrBhIL5ZgnsKHq4acdZAE8zT1AEyNTsESXN/U476wsQRNcF1TD1j0EiEKLi98OGzIWQdpmnRKflOPy4acdRAjmCg/ineYenEjmIhoQ/eJpQ+41OoN1AgmItoniTsg68WO4FdGuqfxwn/b0xdkuUQ9CCYiGumGRhqIfgzZEx3omQ7Nl8Eo0IfgjkH+DQ4oBMMTgsEJweCEYHBCMDghGJwQDE4IBicEgxOCwQnB4IRgcEIwOCEYnBAMTggGJwSDE4LBCcHghGBwQjA4IRicEAxOCAYnBIMTgsEJweCEYHBCMDghGJwQDM7/X8sOVDl0dpYAAAAASUVORK5CYII=",
    ["dots"] = "iVBORw0KGgoAAAANSUhEUgAAAPAAAADwCAQAAACUXCEZAAAAIGNIUk0AAHomAACAhAAA+gAAAIDoAAB1MAAA6mAAADqYAAAXcJy6UTwAAAACYktHRAD/h4/MvwAAAAd0SU1FB+oGHBYlJCLfZDcAAAAldEVYdGRhdGU6Y3JlYXRlADIwMjYtMDYtMjhUMTU6MzA6NDMrMDA6MDDo/hjqAAAAJXRFWHRkYXRlOm1vZGlmeQAyMDI2LTA2LTI4VDIyOjAyOjI5KzAwOjAwZ7ljIAAAACh0RVh0ZGF0ZTp0aW1lc3RhbXAAMjAyNi0wNi0yOFQyMjozNzozNiswMDowMHWFn80AAAP1SURBVHja7dzRcdNQEEDRDVDIo5KISgiV2FQSqMROB3Qg0QFUID4IM8Q8Q+JdWZrLPfoXu7qRMwq2b+YQ2au1B9CyDAxnYDgDwxkYzsBwBoYzMJyB4QwMZ2A4A8MZGM7AcAaGMzCcgeEMDGdgOAPDGRjOwHAGhjMwnIHhDAxnYDgDwxkYzsBwBoYzMJyB4QwMZ2A4A8MZGM7AcAaGMzCcgeEMDGdgOAPDGRjOwHAGhjMwnIHhDAxnYDgDwxkYzsBwBoYzMJyB4QwMZ2A4A8MZGM7AcAaGMzCcgeEMDGdgOAPDGRjOwHAGhjMwnIHhDAxnYDgDwxkYzsBwBoYzMJyB4QwMZ2A4A8MZGM7AcAaGMzCcgeEMDGdgOAPDGRjOwHAGhjMwnIHhDAxnYLg3i525xfsYIqJFiykippjiIaY4rrDl/zzLXH+0eTeP8znjvFvg33SWM8cSS/zbdS6ss5QHHp6xxLUurLOUB37Oz+i1LquzlAc+vHCNn+4XuaTOUh74sjWWuazOUh54d/Ea8zwXvzg6y5Pj9T7/pDXEp+ST4ff4UvTU5ywnbub8ImO05BmmeJsfw1l68n+q3KXXiGhxnz6Hs3Tl7+CCl4Coum+c5Q/ZO/iuZI2IFrv0OZylI3sH53/P/JK/b5ylI3sHV60R0WJwlvpZcoHvytaIiLh1lvpZcoFzl+HU4Cz1s+QCt9JFcpyla0uBc2dzlq4tBV7xMnBnyT0m1TzM/zaNs1TPkruDp9I1cmdzli4Dw2fZ0vuiU4s4S18u8OfSRR6cpX6WXOBj6SK5szlLV/Z3cOUqk7PUz5L9HVz3YrRPn8FZOrL/XdhiLFok89zpLGdl7+ApPpSssS84h7N05N+y0+JQ8Ke5/D3jLF355+ApPqbP8S59Bmc5h/IGb2fpH+uvcii9pM5yclR8siEi4mt8u+idB8eyl0Rn6Vv1p3U7H9nEzlK7yvCXryg4Nc7DYpfUWRYK7NcmbG6WpZY5rHxBneXxqPh0YV+LIW6jPfm6oIpnQ2d5keUCaxO29I4OLcDAcAaGMzCcgeEMDGdgOAPDGRjOwHAGhjMwnIHhDAxnYDgDwxkYzsBwBoYzMJyB4QwMZ2A4A8MZGM7AcAaGMzCcgeEMDGdgOAPDGRjOwHAGhjMwnIHhDAxnYDgDwxkYzsBwBoYzMJyB4QwMZ2A4A8MZGM7AcAaGMzCcgeEMDGdgOAPDGRjOwHAGhjMwnIHhDAxnYDgDwxkYzsBwBoYzMJyB4QwMZ2A4A8MZGM7AcAaGMzCcgeEMDGdgOAPDGRjOwHAGhjMwnIHhDAxnYDgDwxkYzsBwBoYzMJyB4QwMZ2A4A8MZGM7AcAaG+wGalFWSZ+WcRQAAAABJRU5ErkJggg==",
    ["dots-vertical"] = "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",
    ["download"] = "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",
    ["droplet"] = "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",
    ["droplets"] = "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",
    ["ease-in-control-point"] = "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",
    ["ease-out-control-point"] = "iVBORw0KGgoAAAANSUhEUgAAAPAAAADwCAQAAACUXCEZAAAAIGNIUk0AAHomAACAhAAA+gAAAIDoAAB1MAAA6mAAADqYAAAXcJy6UTwAAAACYktHRAD/h4/MvwAAAAd0SU1FB+oGHBYlJCLfZDcAAAAldEVYdGRhdGU6Y3JlYXRlADIwMjYtMDYtMjhUMTU6MzA6NDMrMDA6MDDo/hjqAAAAJXRFWHRkYXRlOm1vZGlmeQAyMDI2LTA2LTI4VDIyOjAyOjI5KzAwOjAwZ7ljIAAAACh0RVh0ZGF0ZTp0aW1lc3RhbXAAMjAyNi0wNi0yOFQyMjozNzozNiswMDowMHWFn80AAAmuSURBVHja7Z1LbhRJEIaDGQ7AjsWMNOkjcAKX99zBbcExkKo5AywZdXMH9m6fgCN0Ig0ScwekmkXbYKZfGZGRmZFR/9crTLurqj/HozKzqp5MBDzzW+sdAGWBYOdAsHMg2DkQ7BwIdg4EOweCnQPBzoFg50CwcyDYORDsHAh2DgQ7B4KdA8HOgWDnQLBznhb63EDXFCgQUaBAkYiIIkW6o0ib1gc9J54oL7oLdE1Ey5PviRRpQ29bH/o80BQc6PqM2sdE2tBHRHNptAQHGmkh+L1IN5BcEg3BUrk7Iq2RrsuRL3igFYXMz4DkYvy+zPv9kdb0LHsvntFARHetvwyP5EXwLQ2K+7Kmm7ZfhkdyBOvqJSKKdHV/zgyUkAvW10tEFOmi3ZfhEelQZRm9RIFWzb4Ll8gErwrpJSJa0Njou3CJJEUPdFt4r25o3eLL8IhE8Db7vPccqMRq8FP0WFwvKrEi3Agun54fuMIYtQbcCK7XAKHVUoEneCjYPbfclmN4gq+r7lvdrTmFV4Pr3nMJA5cKcNZkLSrvW6Dtkf+JRLShO8bZ8lN6RS/pBf3B2P5X+kyf6G/6XvGId2vY/rr/18O/+cf7kyn9dTtZYzuNSXv+evom3sa36TXjO5K9wjRO47RVO95HL86bbXL+kN9lb+NdIa3DNLLDhqk4/a1Da5PCQ87XO03aisM0FjteseBFa48nWBzd69dq29BJ1Hlqzx/v3iu9i15Vb7LSOTZ2/ZT+oedK2/iX/sxqtwJd00JpmJcxVp9+Hjyo7FoZwpG9e6Wml+g5vRLv3Uhb2tJSbRQ/pNvwcm3S4YHNl6rbkHzaSLeqak8f7wFKXZtUm3Dwpy9Ut8H9tFEtJace7wG8CD4MZ1hD89N4F/EUxYvg0HoHHu1JDbnJx5suOPkjmxAP/vSragx/PfuOepEbU9+Y3mRtquy4lMN791l1G6c/bdcrL5se7wG8dNGHL3v5pLqN459WV+7x4z1A+kDHaKVtOEDbgY7630yRgY4vlQ+Cw7Frmr7TG7VtvDmod6gcuaeP9wDpgmP1w0hleaIifaD3Ktt4Tx/2fhZoRbcNms8lqx9iDJPbpNV04Wj2eIWzSTYn/IekPdee8G81s5Z6vKLZpJpros8RiWhNxLgrgN6SnVD0yiyt4/0BR/DxNVKluDBX+RfFr7mI9y+iLxTv/50BZ6gy0qbq3+7amN6ysRulMXoa3rLZuknaVvyWit1Ia7orOE7ILNq31RqKlcoSGZ1XKHLcgjWS/Bf34rN6ddjOxWf6sRtpTR/r5CfudGGkdZW1WWsjerXrbumEvAf/AvAaMWzlAnDdnqPJ7d74s0mxwt2sbNwva1TUG2lJF03u5icq3WPR9qpC61G1rdpy1jFrv6S/WE7xbXO5mldxNJWbI7jMiYMNvVp/vIKRYzuCaQoJV8P1p1frD7d55OYL1rrOxpJerdRsoYtQEEyTZi1u/6XoTAJaGoFTEKzzV2+hWq2cHIe64PxU3T52NSpvlZHlNoJ3X5EsAiz8zWu0i8YSs77g3RfFiYPtNE6h9eFPGiXGwh/p0Zf+g7EGujwzHWHpwVj5M0Ubump9EKfQFrwjUKBAlxSIaPgxLbZ7qF3VuZQz5N61oIOnPpUR3AP5E4HGY3eHl8tHuYTMJesdxO6OeQrOneftInZ3eLm6kEOu3mU/eucYwXl6u0nND8wtghdZejd00ZfeuQleZZ31dpWaH5hTis55mFd3qfmB+QjO0dtR1/x/5pGiQ5bedb965yE4b8xqaWQRrxD/KTpvob6dC2iEeI/gHL2xf73eIzhHb8eN1WM8R3CO3q4bq8f4FZyjt/PG6jFeU3TOiLODyvsTnxEs1+uisXqMxwjO0xtb774u/iJYrndj7LYvKngTnKPXSd/8K74EQ+8engTL9bo5693Hj2C5Xkdnvft4WRctH9a4ET2Vtxt8nCbJ9To7693HQ4qG3hP0LziIF9LNQG//guWrNWaht/8mS7rWaiZ6e49g6D1Lz4Jlet3NF52mX8FSvZ0uYJfSq2BZazU7vb0KHkW3Xpih3j67aNmo8yz19hjB0MuitwiWzhnNqnN+TF+CpaPOs9XbV4oOiF4+PQleiW58NGu9PQmWDWzMXG8/gqFXSB+CZeNWMz0x+pUeBC9E41bO11qlYv80SXbmuzRyu+LmWBcsO/Nde14Iy8N6ipast9pA709sC5b0zm4vQpFhWfAo0Buh91fs1mBJc2XlucOGsBrBst4ZtXcPmxEs650xbnUAmxEs6Z2h9yAWBUt6ZwxLHsGeYEnvvMSw5DGs1WBJc4Uz3xPYimDoVcdSBEseVoUz3zNYimDJkhyc+Z7BjmBJ74xTo7NYESzrnTetd9s+NmowmqtiWBAsGZiE3kQspGj+wCQmBZNpL1g2MAkSaS1YsiAWvTODtoIlC2LRO7No2WShd65AO8HonavQLkVLemc0V2xaCZb1zrHR3nZMG8EL9M61aFGDJdUX1xoJaSGYn57RXImpL5ivF5P6GdSuwQMGJutSN4Il1RfNVRZ1I5h/7ov1zpnUjGA0Vw2oF8H86gu9CtSKYH71Re+sQq0IllRfoEAdwfzqi95ZiRqC+dV3Db1alK/B/OqL5kqR8hHMr76YVlCktGD+FQuovqqUTdH8VVe4R50yJQXj3NcAJVM0zn0NUE4wqq8JSqVofvXFyVERyghG9TVDmRSN6muGEoJRfQ2hn6JRfU2hLRjV1xjaKRrV1xi6gvnVF1f7FkYzRaP6GkRTMHfdBqpvBfRSND89o/pWQEvwQEvmb6D6VkErRXPTM6pvJXQimHszJNzIrBoaggf2zZBQfauhIZg7uIHqW5H8Gozqa5pcwdzBDZz7ViZXMPfXMTFYmbwazB2aRPWtTk4EL5jtFapvA+SC+TO/SM8NkKdonBx1gTSCkZ47QSaYn54vcCPRNshSNDc9X0FvKySCuTO/G1TfdvBTNNJzV/AjGOm5K7iCubfyRnpuDC9Fc9Mzphaaw4tgbnrGxH5zOIK597vC3a4MwEnRW9YTupGeTZAewQvmA9iRnk2QLviS9blIz0ZIT9GcBI30bIYyt3BAejZDuuCQ/E6kZ0OkC94kvg+PkDSFfoqGXlOkC067yS/SszHSBcckdYhfY3AEn49hrLsyB6cGb85c5I30bBBek/X2hGLcytsk/CU7Cxr3zokjnjFoFcmy2UADXdJAgXat1x2tWx8GOEaLJ4CDitR+QDSoDAQ7B4KdA8HOgWDnQLBzINg5EOwcCHYOBDsHgp0Dwc6BYOdAsHMg2DkQ7BwIdg4EOweCnfMfIAiZAahuCioAAAAASUVORK5CYII=",
    ["edit"] = "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",
    ["egg"] = "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",
    ["exclamation-circle"] = "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",
    ["eye"] = "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",
    ["feather"] = "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",
    ["file"] = "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",
    ["file-description"] = "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",
    ["filter"] = "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",
    ["folder"] = "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",
    ["folder-open"] = "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",
    ["folders"] = "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",
    ["gauge"] = "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",
    ["ghost-3"] = "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",
    ["guitar-pick"] = "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",
    ["headphones"] = "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",
    ["headset"] = "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",
    ["heart"] = "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",
    ["heart-broken"] = "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",
    ["home"] = "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",
    ["icons"] = "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",
    ["info-circle"] = "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",
    ["keyboard"] = "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",
    ["keyframes"] = "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",
    ["layout-2"] = "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",
    ["layout-dashboard"] = "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",
    ["link"] = "iVBORw0KGgoAAAANSUhEUgAAAPAAAADwCAQAAACUXCEZAAAAIGNIUk0AAHomAACAhAAA+gAAAIDoAAB1MAAA6mAAADqYAAAXcJy6UTwAAAACYktHRAD/h4/MvwAAAAd0SU1FB+oGHBYlJVXYVKEAAAAldEVYdGRhdGU6Y3JlYXRlADIwMjYtMDYtMjhUMTU6MzA6NDMrMDA6MDDo/hjqAAAAJXRFWHRkYXRlOm1vZGlmeQAyMDI2LTA2LTI4VDIyOjAyOjI5KzAwOjAwZ7ljIAAAACh0RVh0ZGF0ZTp0aW1lc3RhbXAAMjAyNi0wNi0yOFQyMjozNzozNyswMDowMNPylHkAAAsSSURBVHja7Z3rces2EEa/m0kfF67EcCWmKqFciXgrEV0JkUqUH5IsW1cPLHYXgFZ7OJOZJJQB8WgBEM9fOziW+ad1BhxdXLBxXLBxXLBxXLBxXLBxXLBxXLBxXLBxXLBxXLBxXLBxXLBxXLBxXLBxXLBxXLBxXLBxXLBxXLBxXLBxXLBxXLBxXLBxXLBxXLBxXLBxXLBxXLBx/m2dgW4JiPiNgAAgHP4LkICvf874RPr6t0755ctHzxjwinhQmkdCwh/MfYp2wUfoYs+ZAXwg9SXaBQMD3hEF/97ck+bnFhzxzoza60z46EHy8wqOGEXj9hIzPjC3/ZrPKbiG3CONJT+f4JpyjzSU/GyCt9XlHmlUJz9TT9aAXTO9wIAthvrJPksEB2wayj0xY1U3jp9DcMS2dRa+scJUL7FnKKLHrvQCG4xK794XsB7BvRTN51Qrqm0LDlhaZ+EqCW81FFsuomPHevc/vqCfjF3BfTWsLrPovzhZFfwIegFgo63YZh38KHr3vGl2Y1oUrNe0Skq15otec8ueYEm9ExL+Aw7D9wn4mqO1n60VhIQrtqjtCZYYTpjwmTnHKuIVg4BmNcXWBHP1Tvgs6EiMh/lcgZGyluKdpWvccdjsAiv1uNuy0h81nklrJZJXbChXRnJ0wbeupbHck+TSnCzCOTEleCx8pFElN6WSpX9sZnuy8pjxotTJMBc2mQa8C+ekeeRJXfSIUWnU/Lg2RVEsGsN2IjgQ73/Dh3qeVlgXxLFoDNt5D6Z8kYRVtWmsERvyj0+w69KO4PzR1YSXqjkL2BIVz3iTStxOET1n3pfkHh4hxUT6RJQbRLQj+DPzvsrTVgGUKBarh+0U0XmFtOrY600G4lxKoXrYTgQjY5Bg3XAZ2EQcxBiF0m3+/ip53e7N2jTP37b++7ClCAY+sL76/9ZYtc4esSaWqYeb/6qlr+FCn5ZWjzP9GmvHsKVG1okB74epNQlz0RC+HpQpCQKrmGwK7hlKt8fEr1Zs1cGPQCK05AVme7ng+lBW+kduYi64PpQYfuUm5oJb8Cf7zsBNyhtZbcgf+2J2WXoEt2HKvjPyEnLBbchvaDFrYRfcipR5X+Al44JbMWfeF3nJuOAcIkYs2GHBIrZkO3eCAjeGm3e/937Fi4MXElNucyf6Rk4qHsG3GS/2HAesBQbkU+Z9IfO+i7jgW2xvji9zFafM+1jtaBd8nXsDe2tmAyi/Fmbggq+RM267YaWQMu8LnERc8GXyhuVDl9sk/sAFXyJ/1gWnHk41vooL/hvKpJpQIT+sNFzwOfU2/U81EnHBP6HqDa0zfA8X/B169CZGaqHGV3LBJ0oK57lCvhLnwy74SFndW6WzgoML3lOmN7EmpocaX8wFA+UtZ9609Nw+5sRJxAWX6621GDVxPuyCS/XO7F16ytIl8uyCy/Xyd/rITZnVkHvuedEt9eZvXP6Lk0z9CB6wwYIFO2yxVTt/O4eWevOXdydmOh3Mb2LNOSq+aNspnNhWTn/hpVPzkV5f3a6/a2RvekN2isxn869AYZPHrQJxDVTYOTIvL7eQ24Euf/8Nbl9ZlXgJGRETnyZ6saPsjctMqRe9Krudd6s3v4Bm1sA15kVHLB3Nb2pfOAOUAnriJqUtmHLIHHs1+1360BtuzLY+hz1apSs4kM4QDKp56UUvJX4pmz1cQ7XupWK97qU+FYHXR70IDsxp4bL0Er20yfL5e3lcp6OIYbcYu49e2uFdIs9DK4J7mt/UT/TS2iSTSJoqETMUxctgPHqpeRFJU+OR0htXYgVS13pHUg6E+uc1xoPz94D6jsZm+/0UzvRj51mjwCfk62D6KUEAMBnXS6t9QegKuYdwMVR2xKvGZvs9Fc70SitIpS39VZaCR6oxGtyXXmpuBH/wsl9lLHik0bheepkm2tyU/aW6Xr5e4RKt5YPVmY3Vk96xIB/Cr4tyf4oav/b1bopyIvxU2n0d63rHopyIv09I/SFq/FrXW/a6qNCbJ9XRQTulS2PZVk/dGiB2axzROJutQfy278bXzUvpYIvK7HCZCKbEr8YBzX1FL/C7KC8qM8NlBK8J907i36E3vSULQ9XOJZcYTcpfJ6fxUPvTC1AfasKLVlYkIphSQEs3I3rUS10RmFQPvq3awJJuRvTVtDpdCyk3UTMv/AimxK/ELMETfUbvPoV8NCY6fKPmAvC16O6M/eqlrEdQ1ivRyMr/A8xD2n7Qs14gb9pSwkp/nx5uBN//Gqevk8Ry3bvenJfBGS81tmHiCq64Tu6L/vUCH3f6BurlhdlKG7PbitZbzpRnozEH7cpV64Wg9tYl7fVi18WmM9w9OkLmfbNIcfMIhfPPdF8QMSIACEiY8anQVXsTXis6v5NS4nXg0fR2Aa+RFTLvk1jI7HqL4AmusiEuANdbTJ2erJn5+Y3rLYUnOFbJYyw8sdf1olYE8/aKKdsKwvUCqNfIKmcoWq3oeg/0vyE4bb7mHtf7Be89OPfDnMXM9Ay63m/0H8FUXO8PehcciPe73jN4glPmfUE9hT2u9y96j2BKJ4nrvYAdwa73Ir0X0bkzMV3vFepEcGB8NmUsjHG9V6kTwbytvv/cKaZd7w14gnP7mAMrlYTVjXkQk+u9RZ0iOjI/n67MUkxYqa7rMQCvqzJ//0WJSe8B74iHH0sCMFU9a+lB4a5syP34SnCyWRBdAmMcbhGdMu8rGRPipumAL3jOvK/lKaNPDVdw/lyN2PqrPie1imjZQtrJhr98NH9/d8nlo04m/PfgOftOj+EG8AXn18Jrb2jVhy948nq4ZyS6KufsOz2GqyMhmLJ3Tk/nGQIDNliwYIcttkbf1UWWGecuA9/tlLbcfMzF2TUumdGkmXBv2UoFaUZsL+QjYIuxddaEEfmd0LYT3sidClR4bR6ijBG56jyyvh7h/d2ch9Za5C6pswupJ/Op7/B2lZxtJxLerPS6Sc3omInjvdtmNXFOOz7YGRqRm7JD3Wi07IxSLmOmOt40wY6QEzyTC7X6URyz96avnTM1JM8PDgXKao4wDaRuFqHze1sjOasyFcy7Wgr336Cz6awXrRLSJ4CX1Kxr/FGO40Dep0fxFIW6SM+Lngo+sy48NTyXiIXcKk6K+amKtOCPovfbiEWtC3NTdAqZ7OEDDZEuosuaWntmrIQjh9asOmGmgNZYulLeCxSxCL46DdgWN6ssLYdR6QEdST3T52zZg3YD8WCb88GQ5j3I/fVFn1O6eeiRGXNR23rAK/PFy1DxDGjUwUckuiJnzPjMPM5jwKvInIx2wyAq6Akub2z9zQxgxieOry8JOOyiHvAbQXCyzdraikU9wbKK62BwrwBNwY+m2Fjtu0d3hX8Sf7PVzKtBvfpbOMh3Xmjl06Re7SJ6T/8FtcG690iNTVh6n+FkWG+tXXYSXmofCJXN2rLeOkX0kbGTSe8nqhzw2paagoGoPPJLw3TRfKTubrNzR0W18aL5SN0I3tM+jh/l5U2AFoKBlvXxE9S732klGAgYG6zINTeYcI92ggEg4r2i5KeTC7QWDNSS/JRygR4EA/t9ZLXq5Kn+qds90YfgPdKxnPBRsGLKGD0J3hMPU28C429M+HS1e/oTfKRE9ISEz2d6CbpPv4KPhMPMq3j4t+M/09f8rIT/MMPQchNJ+hfssOj/5DOHhQs2jgs2jgs2jgs2jgs2jgs2jgs2jgs2jgs2jgs2jgs2jgs2jgs2jgs2jgs2jgs2jgs2jgs2jgs2jgs2jgs2jgs2jgs2jgs2jgs2jgs2jgs2jgs2zv9SRwIjgtnQ9QAAAABJRU5ErkJggg==",
    ["list"] = "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",
    ["lock"] = "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",
    ["logo"] = "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OiRJgYwOSVIgo0OSFMjokCQFMjokSYGMDklSIKNDkhTI6JAkBTI6JEmBjA5JUiCjQ5IUyOiQJAUyOiRJgYwOSVIgo0OSFMjokCQFMjokSYGMDklSIKNDkhTI6JAkBTI6JEmBjA5JUiCjQ5IUyOiQJAUyOiRJgYwOSVIgo0OSFMjokCQFMjokSYGMDklSIKNDkhTI6JAkBTI6JEmBjA5JUiCjQ5IUyOiQJAUyOiRJgYwOSVIgo0OSFMjokCQFMjokSYGMDklSIKNDkhTI6JAkBTI6JEmBjA5JUiCjQ5IUyOiQJAUyOiRJgYwOSVIgo0OSFMjokCQFMjokSYGMDklSIKNDkhTI6JAkBTI6JEmBjA5JUiCjQ5IUyOiQJAUyOiRJgYwOSVIgo0OSFMjokCQFMjokSYGMDklSIKNDkhTI6JAkBTI6JEmBjA5JUiCjQ5IUyOiQJAUyOiRJgYwOSVIgo0OSFMjokCQFMjokSYGMDklSIKNDkhTI6JAkBTI6JEmBjA5JUiCjQ5IUyOiQJAUyOiRJgYwOSVIgo0OSFMjokCQFMjokSYGMDklSIKNDkhTI6JAkBTI6JEmB/n/uKjCC6SGrrgAAAABJRU5ErkJggg==",
    ["logo-c"] = "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",
    ["logo-h"] = "iVBORw0KGgoAAAANSUhEUgAAAPAAAADwCAYAAAA+VemSAAAAAXNSR0IArs4c6QAAAARnQU1BAACxjwv8YQUAAAAJcEhZcwAADsMAAA7DAcdvqGQAAATjSURBVHhe7dktqJ91GMfhzbMx0TAUwajBoOJ0CgZtgsVm0qTNNzSKQRBBk4hBDItmFYyCxWA0GAzbEQRN8w0MgmEIm9+z/4MMPDD03vy9XRfcPGdnh3Pu7bk/LOwIAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAACM7eLFi49kXrp06dLzvUz2eTHzdD4+uq3Zrex567bzC1f+GVrPwTvNPLCtyazyks/khXcne/2Ux962Zrey4+nLC3cof4dvbmsyq7zk97b33ZXstZ9H9wFnz1O7jfuT3V7b1mRWAq4RME0JuEbANCXgGgHTlIBrBExTAq4RME0JuEbANCXgGgHTlIBrBExTAq4RME0JuEbANCXgGgHTlIBrBExTAq4RME0JuEbANCXgGgHTlIBrBExTAq4RME0JuEbANCXgGgHTlIBrBExTAq4RME0JuEbANCXgGgHTlIBrBExTAq4RME0JuEbANCXgGgHTlIBrBExTAq4RME0JuEbANCXgGgHTlIBrBExTAq4RME0JuEbANCXgGgHTlIBrBExTAq4RME0JuEbANCXgGgHTVMcBn9tW7Fr2vHdbuTsCXkDHAX+bx42ZY5njnc5e9nwwzy4JeAEdB3zhIOLM/vbscc5lvt9W7k52E/Ds8pK7DJg6AS9AwPMS8AIEPC8BL0DA8xLwAgQ8LwEvQMDzEvACBDwvAS9AwPMS8AIEPC8BL0DA8xLwAgQ8LwEvQMDzEvACBDwvAS9AwPMS8AIEPC8BL0DA8xLwAgQ8LwEvQMDzEvACBDwvAS9AwPMS8AIEPC8BL0DA8xLwAgQ8LwEvQMDzEvACBDwvAS9AwPMS8AIEPC8BL0DA8xLwAgQ8LwEvoNeAs9fvmU8yH+WXH/c4B7tlPs/HXcpuAp5dXnKvAZ/dVuxaVr1zt3F/BLyAjgPez+OGbc1uZc/7dhv3R8ALyEt+f3vfXdkC3tvW7Fb2PLXbuD8CXkBe8tvb++6KgOsEvIC85Jvzrh/P893MN7tX3152EXBRdhPwSvLOj2ZO58W/mvki88flS2ggP1vARdlNwCvLAdyReTa3cPBfJud3Z/H/yM8TcFF2EzA7uYeTOYgnMh9kzu5O5PrJzxBwUXYTMP+U2ziW43g480bmy8yF3clcO/meAi7KbgLm6nIod2Wey3ya+XW7n5J8HwEXZTcB8+/kbm7LPJnjOZP57vIl/QcCrhMwJTmgE5lHM29lvsr8ud3WVeVrBVyU3QTMtZObujtH9Urms8xvuzM7XH5fwEXZTcBcHzmu2zNPZT7M/LDd3N/yOQEXZTcBc/3l1m7KsT2WeSfz9XZ8P+dxbPuSbmVPAcOVcngPZZ7JDR7fPtUtAcPABAwDEzAMTMAwMAHDwAQMAxMwDEzAMDABw8AEDAMTMAxMwDAwAcPABAwDEzAMTMAwMAHDwAQMAxMwDEzAMDABw8AEDAMTMAxMwDAwAcPABAwDEzAMTMAwMAHDwAQMAxMwDEzAMDABw8ASyf1bL93Jbq9vawKHSST3ZM5nftyevcwvmZe3NYHD5B+6vczJDueWBHxiWxMAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAGNaRI38BN9zxgfhFP18AAAAASUVORK5CYII=",
    ["macro"] = "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",
    ["magnet"] = "iVBORw0KGgoAAAANSUhEUgAAAPAAAADwCAQAAACUXCEZAAAAIGNIUk0AAHomAACAhAAA+gAAAIDoAAB1MAAA6mAAADqYAAAXcJy6UTwAAAACYktHRAD/h4/MvwAAAAd0SU1FB+oGHBYlJVXYVKEAAAAldEVYdGRhdGU6Y3JlYXRlADIwMjYtMDYtMjhUMTU6MzA6NDMrMDA6MDDo/hjqAAAAJXRFWHRkYXRlOm1vZGlmeQAyMDI2LTA2LTI4VDIyOjAyOjI5KzAwOjAwZ7ljIAAAACh0RVh0ZGF0ZTp0aW1lc3RhbXAAMjAyNi0wNi0yOFQyMjozNzozNyswMDowMNPylHkAAAdqSURBVHja7Z3bddtIEETLuw7AGXiUgTMQFInISEhFIiiCDYFgJJpMtB8QTMoiZZHdPY9SXR/7+AdDdF/2vAAC314gmPmn9gmIWCSYHAkmR4LJkWByJJgcCSZHgsmRYHIkmBwJJkeCyZFgciSYHAkmR4LJkWByJJgcCSbne8HPSrgHkF7/nCIDyMgA9siYKueGIrZvBW66SxjwE9uLj8uYsMdYKhWksb3E/kkvjy82nl8eX1LwWRLHFpuAjTEB7UruJrb2E3BIxKYRyV3FFpOCwTkBh0SsquvtLLZ/L58f/JUV/guaMPzAL/zAPnJOQheb+3fmMegbfmBTrXo7jM13mZTwiCHoG35Mxh1ygc8hiM1X8K5ICuY03BT6pM5j89yqLJeCuZ5K0m1sfpOsDVbFUgAAv4Bi062OY/PqogfsiqYAADLWRfZ0u47NS3Cd35GXmWx1HZvPGFx2PDyQsAn/jM5j8xCcCo9QxwzBk5/uY/MQHF9F55mvw8bRfWx2wTW/40BsDRPEZhdca4xaiKxhgtjss+j6z2GK29UiiM1awavaGcB820wEFLFZBd/WzgCAqKkQRWxWwUPt+AHgzH2MVihiswleBaX28iQM7m2SxMZy43sb3WmDsdkEt5PW5N4iSWwsFWxKQuOYYrMJNn1045DExiLY/0xIYmMR7A9JbLatyvpbeUeROLdHEhvLJEucQYLJkWByJJgcCSZHgsmRYHIkmBwJJkeCyZFgciSYHAkmR4LJkWByJJgcCSZHgsmRYHJKPBBcVEQVTI4EkyPB5EgwORJMjgSTI8HkSDA5EkyOBJMjweRIMDkSTI4EkyPB5EgwORJMjgSTI8HkfDcd3dINXXpO1klUweRIMDkSTI4EkyPB5EgwORJMjgSTI8HkSDA5EkyOBJMjweRIMDkSTI4EkyPB5EgwORJMjgSTI8HkSDA5EkyOBJMjweRIMDkSTI4EkyPB5EgwORJMjgSTI8HkSDA5EkyOBJMjweRIMDkSTI4Ek2MTnGuf/hGp4dYqwlPBqeHWbGTLwTyCfUm1T8ALni763rW129rhHJEtB/NU8NBwaxXhEZxcpaTa4RyRLQfzdNGenfSmdih+MAke3Fra1g7FD54uGkh4dGmntfrdWw62CTZ9dACDy9i5rR2GJ0xdNJAcqm9XO4h3TJaDmbpoAFgZFW8aXCBly8HfjO+eeG5qQTGzxcOVRw4N1q/xdSPWCs61oz/BtVXcpt7Jdjij4ITtFYo3Teo1Z5hRMABssbtg8EjYNTt3Nq5UrIJbWygdGLD7VB0nbPDc4NRqYbIdbp1kJTzXzsCHZIzYn01Swn2zlbtgfKObVTCwa/jbv5AxYY+MjIwEICHhZ/NqAWDE2taA7d2FADB1IDhhhVXtk6iDfaOj3VGYAXN27YJz7RxQM1kb8BBsPglxhslePh570VPtPNCS7U14CNYoHMWTvQn7Mqn9tXC/OLzV3KOCM8bamaBk9GjE53qwQ1ci3uGSVY8uGuhjP6s3HDpovzs6pnp5IGX0acZLsGbS3jgNe15dtDppb1w6aM+b7jTR8mTr1ZBfBWs17MmN1x6/XwVrNezH6HcJx6+CVcN+uNWv743vuq7kg2P9ev+y4dobzsUxrtNVX8GTatiMcw69f5ukGrbinEFvwaphG+758/91oWrYgnv2/AVPWg9fzejf/3mugxe0Hr4Wx/XvQsQPwLP1bvwvyjbiFuSICp5/rZdis0FHxk1EszGPcMiaal1MUK8XU8GArg9fxoS7mIbjBGuqdQl3UfsHcU/Z0VTr84TpjX2M0qgV8acI3f2L66IBzaY/Q9DseSH2QWg5aupARPBAFv2ku9zFgxLqsY2+OBPbRQPzM2CH6A/plLDF0YF4wRqJzxE8+s6UeBipRuLTFFlGlnnarBS/J3Dte0ypxwlP2vZ4QyG9JZ8XPWo+/Zt1uRubSj4Q/EGKAQDbkjt8JWbRx2y+vOQCS6NjSj/S/+mLCy6st7zg/KUVF9db46Uc+cuOxWONxaL9abPX8ACytxN9gnWdi6elJ1kHVk7vKeuDYuveP6kn+Cvd1FNNb90XY+WIG72bI9fUW/vNZxl35Lf1TLip+3O82q+2y1gTT7e29S+y1ByDDzBeMc4ld5zP04bgPl5wcwkVtjROU7uLXuDa/miga15opYJnGO7fmrBuaW3QSgXPZNy1lZ6Lz3+Nu7bOv60Knul1PL7+vcWBtCgY6E9yM5OqP2lVMNDPiNzIgug0bY3Bb5lH5Kn2afzlHNe196o+puUKXkjYNPlqyREPbU2oTtGDYKC9MXmLp/blAv0IBmbJQ/VROWNscbZ8jp4EzyTcY1Vl5zpj7KVuD/QneKas5o9fFN80vQqeie+0O1Y707fgmYSEW1fRGRlT32IXGAQvJAADbpGQruq88+tLCSjELjAJfkt6rez5/8u/Cctrl/PR3z1yb5Onz8IrWABoe6tSOCDB5EgwORJMjgSTI8HkSDA5EkyOBJMjweRIMDkSTI4EkyPB5EgwORJMjgSTI8HkSDA5/wM0JKHRy0NxPQAAAABJRU5ErkJggg==",
    ["mail"] = "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",
    ["map-pin"] = "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",
    ["menu-2"] = "iVBORw0KGgoAAAANSUhEUgAAAPAAAADwCAQAAACUXCEZAAAAIGNIUk0AAHomAACAhAAA+gAAAIDoAAB1MAAA6mAAADqYAAAXcJy6UTwAAAACYktHRAD/h4/MvwAAAAd0SU1FB+oGHBYlJVXYVKEAAAAldEVYdGRhdGU6Y3JlYXRlADIwMjYtMDYtMjhUMTU6MzA6NDMrMDA6MDDo/hjqAAAAJXRFWHRkYXRlOm1vZGlmeQAyMDI2LTA2LTI4VDIyOjAyOjI5KzAwOjAwZ7ljIAAAACh0RVh0ZGF0ZTp0aW1lc3RhbXAAMjAyNi0wNi0yOFQyMjozNzozNyswMDowMNPylHkAAANmSURBVHja7d3BTdxQAEXRT0QPLJIm6IMugB10wDIdwC6kC/qgibCYHpCSCrLJH8df1+fssbCvYMAz8rv4PSj7svc3wLYEjhM4TuA4geMEjhM4TuA4geMEjhM4TuA4geMEjhM4TuA4geMEjhM4TuA4geMEjhM4TuA4geMEjhM4TuA4geMEjhM4TuA4geMEjhM4TuA4geMEjhM4TuA4geMEjhM4TuA4geMEjhM4TuA4geMuz3ac23EzrsfXvU8o4GO8j7fxc3ye42AXZ3mk/934Pq72vSo5p/E0XucPc47Az+Nh76sR9TIeZw8x/xos73YexvPsIWZ/gu/Gj72vQtz93C/qucCX45fX3o2dxreZP7fmfkXfyru5q3E78+VzgW/2PvtDmLrKc4Gv9z73Q5i6ynOvwXbx/o+Lf/9Styrj5gJ/7P3tH8LUVZ4L/L73uR/C1FWeC/y297kfwtRVdqNjdbve6PgcT3uff97T3NuGs39Fv46Xva9A2svsW4bz/yY9SryZJd4uHONx3I/T3tci5zTu5/Oe6xMdPrJzTgt+ZIdluVUZJ3CcwHECxwkcJ3CcwHECxwkcJ3CcwHECxwkcJ3CcwHECxwkcJ3CcwHECxwkcJ3CcwHECxwkcJ3CcwHECxwkcJ3CcwHECxwkcJ3CcwHECxwkcJ3CcwHG2C9ez4IPQbBeen+3CA1jiYaTybsd24QHYLoyzXRhnuzDPdmGc7cI824X8je3C9dkujLNdGGe7MM12YZztwjTbhWlLvF1ou3AbtguzFvzIDstyqzJO4DiB4wSOEzhO4DiB4wSOEzhO4DiB4wSOEzhO4DiB4wSOEzhO4DiB4wSOEzhO4DiB4wSOEzhO4DiB4wSOEzhO4DiB4wSOEzhO4DiB4wSOEzhO4DiB42wXrmfBB6HZLjw/24UHsMTDSOXdju3CA7BdGGe7MM52YZ7twjjbhXm2C/kb24Xrs10YZ7swznZhmu3CONuFabYL05Z4u9B24TZsF2Yt+JEdluVWZZzAcQLHCRwncJzAcQLHCRwncJzAcQLHCRwncJzAcQLHCRwncJzAcQLHCRwncJzAcQLHCRwncJzAcQLHCRwncJzAcQLHCRwncJzAcQLHCRwncJzAcQLHCRwncJzAcQLHCRwncJzAcQLHCRwncNwf636dQcG1ueMAAAAASUVORK5CYII=",
    ["message"] = "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",
    ["palette"] = "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",
    ["paw"] = "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",
    ["pencil"] = "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",
    ["phone"] = "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",
    ["pig"] = "iVBORw0KGgoAAAANSUhEUgAAAPAAAADwCAQAAACUXCEZAAAAIGNIUk0AAHomAACAhAAA+gAAAIDoAAB1MAAA6mAAADqYAAAXcJy6UTwAAAACYktHRAD/h4/MvwAAAAd0SU1FB+oGHBYlJVXYVKEAAAAldEVYdGRhdGU6Y3JlYXRlADIwMjYtMDYtMjhUMTU6MzA6NDMrMDA6MDDo/hjqAAAAJXRFWHRkYXRlOm1vZGlmeQAyMDI2LTA2LTI4VDIyOjAyOjI5KzAwOjAwZ7ljIAAAACh0RVh0ZGF0ZTp0aW1lc3RhbXAAMjAyNi0wNi0yOFQyMjozNzozNyswMDowMNPylHkAAAgvSURBVHja7Z3ddeM4DIXhPdvHKpVEqSRyJdZUYqUSeyoxtxLtAyfrOLFlgiQIEryfzzyNIkO6viBE8We3ErDMX9oBAFkgsHEgsHEgsHEgsHEgsHEgsHEgsHEgsHEgsHEgsHEgsHEgsHEgsHEgsHEgsHEgsHEgsHEgsHEgcCwTHelCK610oRONNGgHdJ8dBt1FMNHhh6Bn+qBFO7CfQGAuAx1pfPB/M32Q0w7wFqRoHhNdHspLNNO7doDfgYPD2fLulX1diRoChzLRMeg4R281pWmk6BAGOgXKSzQEuLwgEPg52+3uT161A/7K39oBVE5Yu3sL93hR0AZvEdrufmenHfgVOPgRMd6tELTB9+G2u9UCB//EiHc9cPB3zHjXAwd/xZR3PXDwFWPe9cDBHoPe9cDBREa964GDzXrX07uDDXvX07ODjXvX06+DzXvX06eDu/Cup0cHd+JdT28O7si7nr4c3JV3Pf04uDvvenpxcIfe9fTg4E6967Hv4G6966ndwX7W3isRDX+mew3aIbVFnQJPRPRa75TMlqhL4ImIXmnSDsMStQg8wbEy6As80juklUNX4Inee65wS6An8L1lEEB2dAQ+0Kx94b1QXmA4tyhlBR7pCHHLUk7grnuE9SjVF915j7AeJQTmrHBhg0E7gCvyAo8dereiK5YW+EAn7UtU4UQH7RA8kmt09F5WLfRLf8UsOYHHTr37lTPttSWWStGQl8jXH5NuCDICQ94rR12JJQSeIO8NqhLnFzh28TDLKEqcW2DIex81ifMKDHkfoyRxzscklFbPUFgsPJ/AA11KB98gL6Wfi3OlaMgbxqn0i4hcAqPtDWMovW1HHoEPXfc585jLvobI0QajuOJSsCVOd/AAedkUbInTBUbry2coN7I0VWC0vnFMpYqttDYYD0fxFNpAK83BSM/xFHpgSnEwqudUClTTKQ6Gf1MpcAfjBcYMo3RG+TdM8SkaW6blQLzUinVwJaN+m0e81IpzMB6PciJaasXNLqxuI/Om+W4WR46IPuicQ/g4B6P9LcM5XeYYgTHyqiz7FJFjBL7gAakwjvZ0jvtTfhU9QN7iDPGzFflFFgosHWYi+uCnan6KRoGlx0y/uH/CTdGD9jV2TcR4Lq7ASNC6zNzea26KRgWtDbP3mufgXivohfb0Qjva0Qu95elhiobZe81zcI9rTN5bhmGkd9Vp3Yzea/ubcqQx302IZ9rTrOhjhod5Du7tEWl7NqBePjvTW+ihHIF7e0n4/DbqzdwPTtKcFN3bI9L+6RF662CNoQdyBA4+qQmWAPFc7CuAZF5DD0SR9QgXdNRvpeiG0AM5bXBfJVZYK6dVlzh6CTswXODeSqxd4HFaP/vA+JCiHzFoB5CHcIFH7VCrZNAO4BnhAv+jHWphxoxHKYIU/YiwB5Hqf/bhRdap/l9rZp7X0ZqFZ/Yia1C7FC2e99w10LeHFP2YZwNkxhZenkLgLbYGyDQy/R0Cb3N8sBnfqQ15OUVWz6OxFvr4MyXM71U+aQdEwUUWBA7HVXUH0FWZnUE7gBggsHEgsHHCBXbaoYIY4GDjwMHGgYONEy6w1vAykARStHEwqrJNgkdVctpgp31VgA8EbhMXeiAEbhMXeiBHYNTR9eBCD+QUWY2MYeiC0HkXLAfrrk0BrrjwQ3k9WWftKwNERJxdiHkCoxWuAcdZ744ncMikaCDNwjkYC6G1RnAflof7NmnRvr7ueb5yyA1cgdEK6zJzC13+csJI0now1sf6hP/C/6x9ld0SIW+MwHprQ/XNHCNvjMB6a0P1zBt/rXdPzJisD+2r7YyZdvGmitsYC4VWKSJ2abglTmBsjSWJI0eOfmtubQcP54PZM8Uldlz0Uv5OGGWRPX38BtHwcA6E/Zsys2EpeyeMklhCPSfewfBwOlF9UzxS5ibt0aeVCPPNUAwpAp+RppMosm9LSoomQpqOR7y88qROH11KBGmSAumZKN3BmlvLtEyB8sqTLvBAJ6RpJswNJlNIn+HvkKbZFHz+yLGEw68WVl2tCPa4qhTSU7QHLXEoS6nyypNLYDwwhVHo4ehKvlV2ipUNDVNc3pwCF6wMm6VocvbkXCcL9fQ2e43hinkXQkM9/Zi9zs8/X5H1CRZbuk/wnPy8YClD40Bg40Bg40Bg40Bg40Bg40Bg40Bg40Bg40Bg40Bg40Bg40Bg40Bg40Bg4+QX2GlfUpU4rS+Gg40DB5fBaX0xBC6D0/pipOgyOK0vzi+w/IrSM+0yf+THK6uts51/VKX8JJaX7H6Q3xFKaUylTIp2ohE7gfNL7wgle/ZNJAQ+i0a8NHTWMmffRCJFy875l0l2LcYchEyKXsTilTqz5DLns9iZA5BwsKQf8hdY8jEr+lfqOVjKw5JLh8nFrIqMg4kkHpakp09LeFhhyvctcj1Z+Xdnke6OkPCwwpTvb6xyn8Oak4NgpG3HvPlp5Xadit2SU4Mxb3zk2mBPnpa42MJ/zcb8EOm3SS8Z2rXSt6rFmB9TIE0c1ktCojuqpLZjUnKuoO39/JT5mjFS4ss6qt2aFmNWE5hWWo/sG6bj3duYG/ZuaYFpHRgiH9dB+9astNI6NhjzzUe6iv7OQO800rBRpy65NnXLGvO0WVnXF/P/lBb4k5FeaSSi4c8//zan2tt0N+YzOXL0b9UxqwkMCoFRlcaBwMaBwMaBwMaBwMaBwMaBwMaBwMaBwMaBwMaBwMaBwMaBwMaBwMaBwMaBwMaBwMaBwMaBwMaBwMaBwMaBwMaBwMaBwMaBwMaBwMaBwMaBwMaBwMb5D5DCmBLBh2VdAAAAAElFTkSuQmCC",
    ["pin"] = "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",
    ["pinned"] = "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",
    ["plane"] = "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",
    ["player-play"] = "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",
    ["player-track-next"] = "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",
    ["plus"] = "iVBORw0KGgoAAAANSUhEUgAAAPAAAADwCAQAAACUXCEZAAAAIGNIUk0AAHomAACAhAAA+gAAAIDoAAB1MAAA6mAAADqYAAAXcJy6UTwAAAACYktHRAD/h4/MvwAAAAd0SU1FB+oGHBYlJVXYVKEAAAAldEVYdGRhdGU6Y3JlYXRlADIwMjYtMDYtMjhUMTU6MzA6NDMrMDA6MDDo/hjqAAAAJXRFWHRkYXRlOm1vZGlmeQAyMDI2LTA2LTI4VDIyOjAyOjI5KzAwOjAwZ7ljIAAAACh0RVh0ZGF0ZTp0aW1lc3RhbXAAMjAyNi0wNi0yOFQyMjozNzozNyswMDowMNPylHkAAAP0SURBVHja7d3RcdpAGEXhS5ICXIJcCSoFKhGpxKISQyVWJ867M7YVZ3/WHJ2PN6zZWXRGrBCMtXuNyH70noBqGRjOwHAGhjMwnIHhDAxnYDgDwxkYzsBwBoYzMJyB4QwMZ2A4A8MZGM7AcAaGMzCcgeEMDGdgOAPDGRjOwHAGhjMwnIHhDAxnYDgDwxkYzsBwBoYzMJyB4QwM96v3BG5mSnLIkCXJJdfMvSd0G7tN/CO0MU8Z3jy3ZM7v3hO7gVf+Y3p9z9R9buWP7hPomHcTielv0WOeP9niyF6N6YFf/lp731ry2HuSldgfkw6f5k2GjL2nWYkdeL9qq6n3NCuxA4+rthp6T7MSO/DQewL9sU+y1r64Xe+J1mEfwTIwnYHhDAxnYDgDwxkYzsBwBoYzMJyB4QwMZ2A4A8MZGM7AcAaGMzCcgeEMDGdgOAPDGRjOwHAGhjMwnIHhDAxnYDgDwxkYzsBwBoYzMJyB4QwMZ2A4A8MZGM7AcAaGMzCcgeEMDGdgOAPDGRjOwHAGhjMwnIHhDAxnYDgDwxkYzsBwBoYzMJyB4WrvXThl3T18t2pJcsm18h7kdYHHPJl2pSVzftcM/fNUM+6UOQ9V+wPnIWOSa8XQNWvwlFPd3oA61dyJvOItesxz9d6AOrZfjSsCv7j2ftGSx9ZDtn+L9qz564aMrYdsH3h/iz2B1Xwdbh94vMV+wBpaD9g+cPMp6n+0P8kqvTS2Abu2w7U/gpfb7AeopfWABv5eLq0HbB+46JrqRjS/XFlxBF9usSeQlvZXsioCn2+xL5CO7Yes+LJh9quGLzlVvPfVfJt0NvE/O9WcvdR94X/I5EWPlZYcq85cKn+yM2TMPqOZ37UkmVP6yaP2N1m9rX1xja8efSf+qhLOwHAGhjMwnIHhDAxnYDgDwxkYzsBwBoYzMJyB4QwMZ2A4A8MZGM7AcAaGMzCcgeEMDGdgOAPDGRjOwHAGhjMwnIHhDAxnYDgDwxkYzsBwBoYzMJyB4QwMZ2A4A8MZGM7AcAaGMzCcgeEMDGdgOAPDGRjOwHAGhjMwnIHhDAxnYDgDwxkYzsBwBoYzMBw78NJwqztl4FTdufd7YAded1/ea+9pVmIHXlYcnUvm3tOsRA98/nSbY+9J1mIHTuacPvz7ib0C8wMn5w8Sn1au0ndst/Y293ftkCnDm+eWHOlHb7KVwMmQMfuMGbIkmbP2DPvubSXwZvHX4I0zMJyB4QwMZ2A4A8MZGM7AcAaGMzCcgeEMDGdgOAPDGRjOwHAGhjMwnIHhDAxnYDgDwxkYzsBwBoYzMJyB4QwMZ2A4A8MZGM7AcAaGMzCcgeEMDGdgOAPDGRjuD4NuViZvJ9ebAAAAAElFTkSuQmCC",
    ["pointer"] = "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",
    ["puzzle"] = "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",
    ["quote"] = "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",
    ["radioactive"] = "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",
    ["search"] = "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",
    ["seedling"] = "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",
    ["settings"] = "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",
    ["shield-half"] = "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",
    ["shirt"] = "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",
    ["shopping-cart"] = "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",
    ["sparkles-2"] = "iVBORw0KGgoAAAANSUhEUgAAAPAAAADwCAQAAACUXCEZAAAAIGNIUk0AAHomAACAhAAA+gAAAIDoAAB1MAAA6mAAADqYAAAXcJy6UTwAAAACYktHRAD/h4/MvwAAAAd0SU1FB+oGHBYlJVXYVKEAAAAldEVYdGRhdGU6Y3JlYXRlADIwMjYtMDYtMjhUMTU6MzA6NDMrMDA6MDDo/hjqAAAAJXRFWHRkYXRlOm1vZGlmeQAyMDI2LTA2LTI4VDIyOjAyOjI5KzAwOjAwZ7ljIAAAACh0RVh0ZGF0ZTp0aW1lc3RhbXAAMjAyNi0wNi0yOFQyMjozNzozNyswMDowMNPylHkAAApOSURBVHja7Z3bYeM4DEXv7E4hTCWRO9gOIldipxIrlVipJJxKvB/arJ3ED5IACYDC0d+MPKZ854IUH8CvE5ye+Uu6AU5dXODOcYE7xwXuHBe4c1zgznGBO8cF7hwXuHNc4M5xgTvHBe4cF7hzXODOcYE7xwXuHBe4c1zgznGBO+e3dAO6YsALAgZERES8Y5JuEPDLN90xscOI8O3PIl6lRXaBeThgvPE3e7xKNsz7YA5uywvssZNsmjuYzojDgzs2mKUa5w6m8/LwDkEPu8BUBgws91TCBaby2L+AoIe9D6aS9gNGPMk0zx1MY0y8L0gFaReYxnPynUJB2gWmMSTfGWQa6AJTGDNkEwrSLjCF9AANpI63mXGBKQwV72bCBS4nJ0ADQkHaBS4nL0ADIiNpn+goJ/+ni9ggtm2kO7iUEjeG9gMtd3ApH0Vvts2nLN3BZeQOsD5pPtBygcsoD7WPNgcw4wKXMBJ8GJIXKFjwPrgE2o/WtB92B+dDDbKhZZh2gXPhCLENt/B4iM7lyCJOszDtDs6DR14g4NimwS5wDgfG0Dq0mZl2gdMZmV9wmpx5cIFT2VUY+zaQ2AdZKQTW4PyVGZuaTXeBHxNwrLplruoioofo+wTsCteNcr7jWC9Uu4PvscO+2XdFTDVOErvAt9gVLwmWUyEjgAv8k4CXhs79TsSEN74+2QX+SsCu7XLeVSJmvPEcGneBP5H17TVYZHaBgQHPyqS9JGKmJGSyLzAlN9Wu9f6KYsrdfLJ87U4fp+98nMakzw4ne6Q+28UlLRHlOtz8IXaEz2rn8bN9uf7eSwefUu7lphoAvN/57BH/SDe/mEfP9g2rfTAlN9XQarG9Gtv0kYZVgR/vrLi9SlN7brk+GRt+bC42UHJTtZ+A5CfjfIRNgSm5qfIPfWokefXJpsBj0l3h6p8O0o1vi0WBx8T7rgeyIN18FpKfwqLA6nNTNSCk3mhR4JH0M0Tp5rMwp95oT+Ax495rQTpKPwALyU9hT2BqbirRBPtsvKXeaE/ggXh37MDDc78hmp6bKnbg4YwnsCZw/jTFzyA9KV7eT2HKWRe2JvDA8ok3wxJP2Obcbkvgknnk6yPpV2wN9sUR2zx5rQlcNo98/VMTNjnLbuJM2OApv722lgtrJB8LGPCseGdWxIQ/69h0V75Qn1KYKuBF2VJixIR36rZZSyG6fKEv5ZMRr3hSE7QjtnjCK33zuyUHl+/EyEt50tXRFemdkenXSNqLOGR+WziNV7bk1uYjd8/k48uOg2n5bUrO0bd1cqXjo9K+TL+o3sj18KeTd028y+7cz8vKIIuePrAsP+wy9IpVny1iU29+3IrAg+C/ELGpGKpnPNWsLmxDYI73U0oq7lht9nqqm2MHRvrgI0s/dyS2gr83Huv/dtLSpVx85wAHVRJXG1hdXhZek7gSgNKTjnEmRKucAO0T/QLzHhVLmZW+B1dStGbphPULzOdfgOOHDfhgaAf1P1oy2kfRlPIX16CXtYkM4+msTTc0tDuY178Aj4epYfoX8zPdQbeDuf0LcNRcoO7LzNx0Q0O3g+sc1ebwcPloutHo+RPNDq6VxJde1obi4eQzCTzodXDdTBpyr0sN+19As4PrFo+ie3gq+lzZpwhoFbhujnWOMF0Wapsfm9EpcIvKYNQaKrEgyE/tN9tr7IN55ooeQ62VkD9KaDZ/dUajwPyTG7egSpzb0sYDLEBjiG4nL73A3Jx199TsuS7QJnBLeQHqYCsjZySavwEv6BK4Xvmp24yEXDwx6+65+bNBl8DctQFTKS8wlzOSnkSeTZHANWoDplIucfp7bV44Z0PLKLp13/uTzJPz/5H+SicwggZ0ODgokBcYi9auUoP0JPVY8gLXrOyZ25KSCdK0IC0yggbkBR7woUReoKxMZErOqoy8VtxIChxwVJdcP2CPQ6aPH3tYzL8Q3PiuuaxN7jnd+xviD5LHBmS+NjAdRqnJ4RRYJBaVV0bgXfKPLEuej8cr/2kLCllxX63fgyWq8lLIO3c/4vm/MnugVRzko6XAQ/bwRQcVyja3o5XAet52y4jYyr3qUGghsLWwfItaaVKqUldgfUWXqXBnsapOPYF1FEuvw4w3K71yDYH1ZX2sAUsmyfrwCtxfSH6E+pDNJfD6pL1Escx0gQc8r1jaS1QG7XKBl9xxe+kHUEfEjDc9MpcJvGM4Rt03amTOF9h+gfR2KJjkzF3wP7i8GQQcpCug5gl88MCcTfmWXBZyQrQH51IEK0HkCFwnJcoaaJbX7ifpIbr/ycd60NOvFZMucHlRG0ew2Hy6wINUEx0K6QIH6aaaJkh9cfogS8kpNbOoP3wWZRrYCbPUF7vAbYhSX5wusLntZqowcLowuoeLMXG6kJolec0Ini7MWWyYfHm/iElyyTBvNalW/a+eKcv9wUb+gv+InU96JKJgwb9ky07AgGdfGX7AzFGgnQ5l053LfI0lVbiaASl126zLfCZiwh/pkPwdno3vAQEvGFbbN6vcEb3Af3SlRbZ2PSiWdsEPn5Wi+LjKJbWOjwYMeOnWywpef1LxA+B5GPHtmfopHPrxsqdwuIMnYRGiVa7KiI3VnwgRWzwZbXvzRGjWZrJNhuVL2md8DxiMiGxeXEAqpb+F0bXwMh8XcjUbNAdrs0Oqn0gW5dDq48Y1uusiXXVFm4878u6CtMCUWtr8UItVKkS6KMfyo87SjQAAzHjqTV4NDgZ09MZd9bxn5B0MLKsze9EW7PuUF/gt3YD/eYVcWjXBHBq10eHgBSkX7/uVV0sffGbXXORO+95PNDkYQPP0f53Lq8/Bbd+LBdMbtUKbg1tONsTe3QtoFHiZLmzBtr9pjZ9oFBiYG4xrJyXzZ5XR1wcv1O6JV9D7Luh0cP0w3cVifgpaBa4bplcSngG9IRqoF6ZXE54BzQ6ul/ZlNeEZ0C1wnfRDgimNJNAcooEaWea1bC9ohG4H8/ttZf7VLzB3tgvzG9lz0S8wp+dW51/9fTAABHww/Usr638BCw5eysRxsEL/2hCYq+cUTAkqh4UQzTWnJZRUXxYbDo4M89J76YeQwYaDOQZaHZ5aSMGGg+kDrWmd8toRmDrQWuUAC7ATogHgWJynZ1ULhF+x42BK7aHVTVCeseTg8oHWSgdYgC0Hlw+0onTT5bAkcGmQnqSbLYmlEF0apFccoK05uCxIR+lmS2JL4JIgPUk3WRZrAr9nf2K1UxwLtvrgkl54lWtIZ6w5OHddKe/uDrEmcG7IzQ/pnWEtROcG6ZUHaIsOznlVmqQbK489gXOWDlYfoC2G6JwgvfoAbdPBqUF6km6oBiwKnBqkVz7FsWBT4JQt7Kvc5v4TmwKneHjFuzgusSrw/GCf84qycNzHqsD3c9N2UhKHA4uvSWfGK2UvuyhnxYdtgQFgxDMCBkQAM9795egr9gV27mK3D3aScIE7xwXuHBe4c1zgznGBO8cF7hwXuHNc4M5xgTvHBe4cF7hzXODOcYE7xwXuHBe4c1zgznGBO8cF7px/Aclq6b/KM/nDAAAAAElFTkSuQmCC",
    ["spider"] = "iVBORw0KGgoAAAANSUhEUgAAAPAAAADwCAQAAACUXCEZAAAAIGNIUk0AAHomAACAhAAA+gAAAIDoAAB1MAAA6mAAADqYAAAXcJy6UTwAAAACYktHRAD/h4/MvwAAAAd0SU1FB+oGHBYlJVXYVKEAAAAldEVYdGRhdGU6Y3JlYXRlADIwMjYtMDYtMjhUMTU6MzA6NDMrMDA6MDDo/hjqAAAAJXRFWHRkYXRlOm1vZGlmeQAyMDI2LTA2LTI4VDIyOjAyOjI5KzAwOjAwZ7ljIAAAACh0RVh0ZGF0ZTp0aW1lc3RhbXAAMjAyNi0wNi0yOFQyMjozNzozNyswMDowMNPylHkAAAmqSURBVHja7Z3tddpKEIZf39wC6CByB+nAooObCoIrgVQCruCeVAAuIRWgdOAOlB8ysXGA/ZyPHc2jcxInGDTah1ntrnaluxGOZf6RDsChxQUbxwUbxwUbxwUbxwUbxwUbxwUbxwUbxwUbxwUbxwUbxwUbxwUbxwUbxwUbxwUbxwUbxwUbxwUbxwUbxwUbxwUbxwUbxwUbxwUbxwUbxwUbxwUbh1bwClscMWLEEXv06KQPVwmc5TJSbf14HD+yH1dk+2tlYy4XqsNYj9dYj514IcttW+5y4dY7HYp0MUttAuVCcRj9GGIlXtQSm0i53BHcwuEYbDQMWGIgbFjoRKRc6rei1xFtwg599f1qR6hcpPrBD0L71U71cqlfRYcrIgAYcF97x8oRKpf6gmM/8K72jpUjVC4+VGkcF2wcF2wcF2wcF2wcF2wcF2wcF2wcF2wcF2wcF2wcF2wcF2wcF2wcF2wcOcGd9KHPAznB32aleC+1YznBmxkp3stNMpQ8B89FsaBe6UbWHBSL6gX+rf6JQ5KyDYAn4knwK3xGhw4dpqbdgOH1z+fXn+lI1Vs9GmnBtIpXeMDqr//tziI84EC2//TsrR9H9dUw2+AKHI6VdX1iHFuCtX37rJKoHEV9wauMw6qruM8q2nHcj72w3rFqBESCcWGBM6fivII9USuT86I41rdBIbgTU9xn7vm8kHuxL1mdL9fZ9mlTv2nxgkVW16DHC37hJXu/a+ywKI5+gRVQFEdux2iDH8XR/w1BBmPMa2qVZXFu1lxmzx7HnsYElWBuxXX15itWppemip74gQ5fMt6XU1FTjBZ1WOAnUxwHLKvH/wqdYD7FVIOBX5jiINQLwiqaq6LO3UNsHM1WztNGLZhacfjONaX0LevlEEyr+Egu+BgRhVq9lI2sN+jOxWv8Rx79Ai94vvkbOs+9JxgymCqLO/LsPXErhxVnL1cVTaX4yCb4ugzlejkF11bMl7/jeC2H1esdWafsPGKX9b7LE3u+MUZ+eW+6z70nGDO4Zhbz5u+lHG4ge7kzGKiXxbz5C+BDtraRvZCYVVlHcc8e9/uvVDN6KW5lGMP2wlS4GDZ/psdJhH26yWBDeqXmRZdmcScS9bTXpvTKTXwvU8x/Bgam00JjelPnRa/wgB4DgAOecSja8yOQVVFvIJXBD/gmpneFB3ToXss+ZR53ZHO7u9AtKJ9mmttpaovSjlF/sey7uHfH7uIapTMht9KlT06p3vXVT17VEnz7mqsrvkWp3v3NT49QHN5FeMzIFV+DVu84RsykDl8P/j/YpCmdz5x7vVg7pU2rmBb7IjiXujh/JzyLP0KfvROBcg/1g2N7nKVLuXP7xVrhyN6JgKGQ4NjduOL38OkNGqo5kuWKJzj1BgkJ7pI+zRXz6+1uvxwSPCSGN3fF/Nk73H65tuB5K5aonA+3Xw4JfsoIc66KZc69z4HXg/2xY1YvcH79Yq5+7znBmz6EZ3SssKX70juFLEuraGCHjfRROFfYhK/Jx83Jyp1D5VASdc6PG+hotdljmcgmXexIlivWRXSLPX6o0hXrIaFDljIW7Yp1kNTfTrvY4IrlSRxOSb2a5IplSR4tS79c6IrlyBgMzbke7IplyBrrzrvg74r5ybyUkTujwxXzkn2lKn/Kjivmo+BCZMmcLFfMQ9F15rJJd66YnsJpBKWzKl0xLcULT8unzT5iQ/xwqfmyKV82XuceHT225h9Rx80B3wuX2AOoeROWHg/oPzxVzMlhhwG/ap36ZO6yE0b4kY4ZbMifwZiFzke8t6dX7ZNUNQpuUS+gVLE+wa3qBVQq1ia4Zb2AQsW6BLeuF1CnWJNgC3oBZYr1CLaiF1ClWItgS3oBRYp1CLamF1CjWINgi3oBJYrlBVvVC6hQLC3Ysl5AgWJZwdb1AuKKJQXPQS8grFhO8Fz0AqKKpQTPSS8gqFhG8Nz0AmKKJQTPUS8gpJhf8Fz1AiKKuQXPWS8goJhX8Nz1AuyKOQW73glWxXyCXe8bjIq5BLvec9gU8wh2vX/DpJhDsOu9DItiesGu9zoMiqkFu97bkCumFex6wxArphTseuMgVUwn2PXGQ6iYSrDrTYNMMY1g15sOkWIKwbl6DzXuSaGAIfP2CySK6wvO17vUeAuErCPJvbkUgeLagkv0WmFA/v3DqiuuK7hUb+gxbS2hRHFNweXZO1SMRo7T11SF4nq3UapTOSu9q1MSd+9+zn2kWLWbMtXK4Frn3ioHJcr5EYhncR3B9ZpWhyrxSLL78G9hxTUE12w5W2pmnZBVXPjUW4zrqs/b7aQfA1xM3echr0v9lDayOhyz3ne933uUXjJdxID7K6/kNrfuy9olpVV03sOjbw1r7AojkuV69LkVdeGNmssE91ln39ujVm2fhZ9uvJanOK+M/1Am+CHjPaFByUPDXaUhEHue4s8lIZVmcCoxY845haCDcOQ5ivuSkMoaWalvjr2k0GZD63oD65z05tZd4u+/g3NtUvwVowNjVPXYRf4e65Nq+DI45YJgh32DOZzSoUnL4gYyOO16b+6cCEnSHi7ElsU8GZx+Ob+9HE7PsvgsVp/B6bM1WsvhTcZ7HjkC48ngvG9gO23p2PbzR2jLD4D0rQxvs5MOIBqWXMxDcwbnD9Dzkj9hkCGDdQtuoamVWz0Ds6+i22hqfZcO4Da6BQPfs9qnfGy0fwV1V9ETelvTpdP1Z19FT2hd0jK0sBqjBcGDSsWD5s7RGy0I1qh4wGMb17xaOAdP6OoyLavo9XPwOwY8qsniOnpZaEewlhXEQ0t6W6qiT8jeHqLuOmavoi+wFBxa2LXQMTqnTPAgEvOj0Nl4Wb1jFHcURcfKkcFFAV5kx57HB9y1dOZ9o0xw3CHvCOIeWPN4SVQ1H6J+a1eyizLBsstMdrjHjlzyhjB3OcqvcHniMbgA8li8QPX21o3biCjy2I4dcfTk5fdpU/b9WAQ7LV+Jc+wFP/ATwAKLqp+7w1c84YU0do7yI14AXryAOWFbVcrk/bhijJq4/GhD3DIW1LT147pA835ckVfKKeVXIT3qhHgpd45jz15Ub5r7pDPzcdyKqGUov3r3yeqxRgegw4ADnpVMZenR4TN64PVK1PTngGkt74Bfr3/LQ1R+9QQ7KmlvLNpJwgUbxwUbxwUbxwUbxwUbxwUbxwUbxwUbxwUbxwUbxwUbxwUbxwUbxwUbxwUbxwUbxwUbxwUbxwUbxwUbxwUbxwUbxwUbxwUbxwUbxwUbxwUbxwUbxwUbxwUbxwUbxwUbxwUbxwUbxwUbxwUbxwUbxwUb5zf7VmvUb4sN/AAAAABJRU5ErkJggg==",
    ["square"] = "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",
    ["square-rounded-chevron-left"] = "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",
    ["square-rounded-chevron-right"] = "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",
    ["square-rounded-chevrons-left"] = "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",
    ["square-rounded-chevrons-right"] = "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",
    ["stack-2"] = "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",
    ["star"] = "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",
    ["sunglasses"] = "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",
    ["table"] = "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",
    ["ticket"] = "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",
    ["trash"] = "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",
    ["trash-x"] = "iVBORw0KGgoAAAANSUhEUgAAAPAAAADwCAQAAACUXCEZAAAAIGNIUk0AAHomAACAhAAA+gAAAIDoAAB1MAAA6mAAADqYAAAXcJy6UTwAAAACYktHRAD/h4/MvwAAAAd0SU1FB+oGHBYlJVXYVKEAAAAldEVYdGRhdGU6Y3JlYXRlADIwMjYtMDYtMjhUMTU6MzA6NDMrMDA6MDDo/hjqAAAAJXRFWHRkYXRlOm1vZGlmeQAyMDI2LTA2LTI4VDIyOjAyOjMwKzAwOjAwPosmbQAAACh0RVh0ZGF0ZTp0aW1lc3RhbXAAMjAyNi0wNi0yOFQyMjozNzozNyswMDowMNPylHkAAAk1SURBVHja7Z3bYeM2EEWvkxRCV2KqkpUqEVWJ5Uosd5AONFtCKnA+GD92Y0kggTuDGc/xr4QBeDwgBeJx94okMn9YVyDhkoKDk4KDk4KDk4KDk4KDk4KDk4KDk4KDk4KDk4KDk4KDk4KDk4KDk4KDk4KDk4KDk4KDk4KD85d1BaoY8APAiJFQtgAQCF4gOFk3dD13TifdDfiBLQalaIIjDtZNXodPwXtM6jGdSvYneMSzWWyHkr09ZO0N9QIDtthbX4Jl+MrgZ8rj1FKO2FlXoRxPGdyHXmCLR+sqlONH8L4TvQA8ddR/TtY1KGPE0boKvzDgH/xtXYkSvNyD+6um4N66CiX46KJ77BAHH3diHxncZyVd5LCHDO4xfwFg6LZmn/CQwWe1MeelOMhhDxk8WFfgSs1G6yrcon/BW+sKXOXBugK36F9w35dwtK7ALfoXPFhXwDcpOHLtkILD0//PpNIK3gWJ25j+M1gafmoJJ6O4jYki+GRUO6u4xfQvuGwO1EuYuI3pX3DJrGQhvC22itsYD4Kfbn6GMUdKCnLYw9ysVw9/+9dr7MPFbfhnXoHqS/1oFNeFXj+C8bp9Pf/vIp9fR3rc0Shuo7/+Bzo+GDDiAQNGCIATXpQecT7izo9VP/t/tPrAk+BkBf0/RSdVpODgpODgpODgpODgpODgpODgpODgpODgtNsna4sHjDlFrgECwQHSZjpQm6HKEY+ptjEnPLUY824h+LHz5SV+meo3baq/B+9TL42pfoFqbQZbbkv2PdjVddS1gvtduxsFwabmcauui86nZj6Va5DrBPe9tDMKVVe5NoMTPkPNl+vuwTnfR4eKBW51GSzWLf8WSM2Xcyw6OHWCT9bV/xacar5cJ7j7tXUhqLrKOdDRO5WbrdXeg52dYOCQyhWMtYKPBueffCeOtc859U/Rh1RMY6pfgdzmhf8W+7wXN0awa/Erpd3is/E/yYPVFQmDtFw52X514YCz8gWJxH3r0UHG8tEcoV5P823VcqgyOAzBYt0ot0j7IjODg5MZ3BPSvsgU3BPSvsjsontC2heZGRwchuCf1o1yC+HKZRfdE9K+yOyig5OCe0LaF8nZyjBHo9dBOOAj78HB4QgW62a5RBiFZgYHJzO4H4RRaAruB2EUml10Pwij0Mzg4HAE52j0GihXLbvofhBGodlFBycF94MwCmUdq5Oj0cuhHDWd9+DgsASLdcPcIZxiM4ODkxncC8Ip1r/gI3a4xx3ucI8NTtWR38q7x6ZJeaWw4pCONX181eD5dfjiONj1sb8u71mlLaTziD1n8ObLjXZP2GFaFX+6UN7G8yYV7Q7l+BX+aPS1DQ4OALYL9xrY3ChvIreHdMW8PkWfbmxxcMBxURZvbuyHcaDv6rektgvw2kVvbn5iieJbegFg5/OXgU/BU9GnShWX6J23RmFSUtMV+BRcSoniMr0Ae2fOW/Vcic978FPxJ28pLtfbyz/tQlhvk7jblC5777K/+ES9RC/AfEdWueXoZXxm8LDo05eyeKlel/AEi3XTPvGV4uV6B2INpbqEC/gUPC7+xu+K12Tv8qjlSHUJF/DZRa85Seiz4nWdM/OUKKku4QI+M3jpMOTMm+J1egefh3DyBHNHo3+s+tYBx9WPVo/U9tCuFutlA5sJ644TWHsEwZZ8ypuwCvbZRQPApNhljuT8JeJXsN7J4xpnJAurYN5Ils7c6MrjkwvQOQKbMica8Poz6QN2Frs/4ZwpWFRawFSspVd4RXvPYICn2H32AhEyGOAo1tQrvKJjCG6vWDd7hVd0hC56pqVi7c5ZeEVHyWCgneIQ9943mIL1d+poodhCL/FKxemiZ2oV22Sv8IqO1EXP1CgO1TnPxBNcE/fBqM7EqMyxaJudOuqm0u1XTiaogzYSHe8eXDtTcumapu7hChbl1rSYCKuvmBotUga3muccKovjZHDLaey6iqmRoghuvUpBUzE1TowumrEIRU8xNUqEDGatMQpxL+YK1hiNZi4h01FMvUreu2j2CkENxdTyfXfRGgtAnXfUngVrre9lK2aW7VjwTnH59oE6+1qYVee+bOC9bjgVbKT0FSOGlbJ403OJrxr4glk7day7KPP73nWrIQY8U9pC251jxudT9HHVt95e56/LRfY+WSTYgqWbUj/P1linmLNP1pq2LMCn4OWX+vfJOGsUc9rCKfUdn130aeHnv5prtVzx0qhlCKXUd3xm8DIuTaVbqniwbsga2II546zDgs9emymptYT8GuTxep9d9Ljgk9cnwi5RvG7jl1sIpdR3fHbRpTtWlcxz7iGLifjM4LKpraXT2MsUD6RN/YVS6js+M7iku1yySqFEMWufHSGV+wbpWJ2PP5tjaMbF5W2vlrentYN8/fmCzwaK1+loXV4J5xR8ja8OshoqDrJqXV4HgvkPWcx7zIgznjFiwIB5u9BHnCs2HfwoD/+V91xVnu3VAaCxVyW7CWNjAa3Lu46wA/j8mRQHYQfw3UUnN+EL1t+pwxP0q5NdtC3CDpBddHAyg20RdoDMYFuEHYA9bRaw2YrFC9Q50YBOFy0KMXwi/BB5Dw5OZrAlwg+Rgi0Rfojsoi0RfojM4OBoCM7R6EsoXJnsoi0RfojsooOTGWyJ8ENkBlsi/BAaY9E5Gn0J+kh0dtGWiEYQHcEqTXGHaARJwcFJwXaIRhAdwZz9abwjGkEyg+1Q+bdPwVYobaymJVhU4njiqBNG63ewUnOS39EZyQIGnK2b2hkKo1iAXgY73cqTxqQVSG+o8kktkgfUroaeYNcnHzRm0rsWmi8bDoqx+kaxN9MUfMxnaQCq+av3FD3D2hbfE+Qt/H9H932wZA5jpxtO+4U/94Ca/pm0fy7qdtEzrJNY+mftYUAVWAj+roqV774zNnOyNt/wN/HJQq+VYFE7d7AXDDrnGatZlYKN3nisOZOVXqt78Btb7L/B3di0t7KdF33EJvgY9YQ725uRbQbPjNir7vCqxREH+3/eHgQDs+QhUHd9xFMfj5G9CJ6JoPmIl55G6/oSPDPiAfPhVwN8HCg3z1d56XHeSo+Ck4bk6sLgpODgpODgpODgpODgpODgpODgpODgpODgpODgpODgpODgpODgpODgpODgpODgpODgpODgpODg/AuI2bloUHsPBgAAAABJRU5ErkJggg==",
    ["trophy"] = "iVBORw0KGgoAAAANSUhEUgAAAPAAAADwCAQAAACUXCEZAAAAIGNIUk0AAHomAACAhAAA+gAAAIDoAAB1MAAA6mAAADqYAAAXcJy6UTwAAAACYktHRAD/h4/MvwAAAAd0SU1FB+oGHBYlJVXYVKEAAAAldEVYdGRhdGU6Y3JlYXRlADIwMjYtMDYtMjhUMTU6MzA6NDMrMDA6MDDo/hjqAAAAJXRFWHRkYXRlOm1vZGlmeQAyMDI2LTA2LTI4VDIyOjAyOjMwKzAwOjAwPosmbQAAACh0RVh0ZGF0ZTp0aW1lc3RhbXAAMjAyNi0wNi0yOFQyMjozNzozNyswMDowMNPylHkAAAgPSURBVHja7Z3deds4EEWv99tCqEpMV2KpEkmViK5EVCXCVqJ9oBXbsRMBBMgZXNyTV0b4OR4QJIHB0w2CmX+sKyCWRYLJkWByJJgcCSZHgsmRYHIkmBwJJkeCyZFgciSYHAkmR4LJkWByJJgcCSZHgsmRYHIkmBwJJkeCyZFgciSYHAkmR4LJkWByJJgcCSbnX+sKAAC2eEaPzroaBQkIOCIgWFfkyXz7aI8TldrPjHjDYFsFa8F7HGwrsDgHHC2Lt70H8+sFDthbFm8ZwT3Olk1fkReMVkVbCr7S3nt/J+DFarplN0Tvm9ELdOititZz8Do8WxVsJ3hrVrIFnVXBdvdg8wfwlXmyKVZDNDkSTI4EkyPB5EgwORJMjgSTI8HkSDA5EkyOBJMjweRIMDkSTI4EkyPB5EgwORJMjgSTI8HkLLW7cAvg+X01cAcA7zvtRlw87LkzYwvgGR06TP0SMPVMWKpfyq+q3OL14TLvEWMDu5K+sovqlzeMZTWXFNzjtbHVzssw4FhOcinBPfZ22zMIGbErI7mM4LPkLkCRSM4X3M4m0PUJOOZmCMh9TNpL74J0OOXuwsyLYA3Na5A1VOcIlt61yJhyzR2iO+ldkYxMRHMFn6R3Vfq59+J5gvXMuz5bvM75b3PuwXowsmJGtp50wR2u1u1slhnZetKH6FkDhShCl977qRGs+LVmkxbDqRF8sm5f8yQaSItgxa8HkmI4LYJN02qKd5IspESw4tcLCTGcEsHp8+cBO2zwhCds8FJ6MUrF5PZLn3DtLf7f+ZbC+dZ9+4X+dkr6DUZK9Msp3lqK4BT2f/yV/e1q3ceGlOqXrrzgrkgzpqa0Srl+6csLji/+/PC3TtY9bULJftnGeoufZHXRV+4eXlFwWWhFlOyX6PzT5QUfIioZ7M4wMKNsv3SxxS4RwTFciv4aD7H90sX+YPyLjtgL4x7C23tpUrZfAjZxxZYXHJvZXBnff6ZwP5ffPtoVvIqJuBbHXYVlXlWKCokXHCKv66Ouam9dSB91VfF+KS/Y7IQg55TtlxB7YXnB24j7SNfc9u/S/TLGFltecMww0+bCH5N+iRcc/2ri0YGqrS6bL9kv8TYMPhe2TJl+ucZbSxF8TWrK6Ydvll3iogFGSvTL4+9SM74mIXGv+RZXnNH/Shm0xQnXRgfnz5TolzH+Ui26q5GEgy5TIjjk5osQRTikXJz2qvLNum0CiRbSBGvhqz2JDlI/NjxediKWJdFAquBR92FTYhb+fGHOBvBzg19zfRC9juOD9O/BmkvbMeMGOeeD/7HBb0EeOMxZizo3EdpVw/TKjHiZ89/mLtlJTgYispipNy+VoaJ4LWbrzVt0l5gORMwkQ2/uqsqNZtSLc8jRWyIh+DY3o7H4CzNy230lf130gBfF8SIMeMrfpFfuUI7ZCW/FDwx4K7MDs+yxOvv3dQoih2JygfIHY3V4/bUc5W9NuDS3dPYQ2S+OD8b6TP9+sF2Hz0fbBVxwX9vV5u7C3/slvPfMZalN8UsJfkybgldHuwvXIVgVbCfYrMltoQgmRxFMjiJ4HYJVwYrgdRitClYEk2MnuK1UaP9ZFawhmry1dm+y2nqXZfQey/YeHAzLbqalloJHw7LXZbAr2lJwW9MsIzREr4Hhn7LlJKuVldUztoyVw/ZFx2ha+loMloXbCm7jLmz2kgOwHqLbGKTNnoEB6whuYZAOtsVbC+YfpAfb4q2HaPZB2nQGDdhHMPsgPVhXwF4wd3I189bZC2ZOzBSsp1geBDv4K18MB2nj7CdZAOtEy3yCBfiIYOBoXYFFcBC/XiKYMYZdxK+XCHby187YIi+C2ebSg5fney9DNFeSUyfDM+AngrmSnDpqiZ8IBoAzxaksWYnLSuMnggFgZ//mJ5vgZXo14UswwzDt7I/Ul+D6c1HPyum8JL7uwRP1vvRwdfed8BbBQL25qIM/vT4Fh0oVu5pc3fEoeJqJButKJJKdF3YZfAoGRhyrUuxUr1/BwIChGsVu9XoWDBwrUexYr8/HpM/4z0PtWq/vCAamJ8tgXYk/Erzr9R/BgN8PiQ5fa3zHewQD09fVwboS38g8DWUtaojgCV+nu7gfmu/UEMETg5tOHbFxUpMI6hE8TWns33DtXE/7vlHPEH2nwx5bo7IHn++b/0Z9ggGbp+MRx3oG5g9qGqI/GLFZ9Y484sXNDCCROiP4To/94sv0Ko3cO3ULBoD+/SiuJRgq+6b1A/ULnih9rN6Ai8OXKzNgETxRQjON2gkuwRPT8XGpohc4N9ADjII/iG0c8WH1EgwY56Jbljqfg0U0EkyOBJMjweRIMDkSTI4EkyPB5EgwORJMjgSTI8HkSDA5EkyOBJMjweRIMDkSTI4Ek+NX8BYnXHHL+hdLXilXnBdbep+Nz0V3/lOvfGfEm8f11B4Fn8y2h+Zy8HdAkL8h2m73bz4H7K2r8DveIrjH2boKmex8DdTeBNebK/qOs1y5voZot3PRBDpfB4v4EvxsXQG+VvgS3FtXoAiddQU+4+se7KoyGTjazOYrgoN1Bfha4UuwKI4vwaN1Bfha4UvwxboCfK3wNcnieNHh5mhZwFsEw9/L+mScZbP0Jnio/OxCNyd/3/EmuO7jKQ/e4tffPXjCV3b3OAJ23qIX8CoYuGetc/bi70cCRr/Z8fwKFkXwdw8WRZFgciSYHAkmR4LJkWByJJgcCSZHgsmRYHIkmBwJJkeCyZFgciSYHAkmR4LJkWByJJic/wFOh3mZ9oWawQAAAABJRU5ErkJggg==",
    ["ufo"] = "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",
    ["user"] = "iVBORw0KGgoAAAANSUhEUgAAAPAAAADwCAQAAACUXCEZAAAAIGNIUk0AAHomAACAhAAA+gAAAIDoAAB1MAAA6mAAADqYAAAXcJy6UTwAAAACYktHRAD/h4/MvwAAAAd0SU1FB+oGHBYlJVXYVKEAAAAldEVYdGRhdGU6Y3JlYXRlADIwMjYtMDYtMjhUMTU6MzA6NDMrMDA6MDDo/hjqAAAAJXRFWHRkYXRlOm1vZGlmeQAyMDI2LTA2LTI4VDIyOjAyOjMwKzAwOjAwPosmbQAAACh0RVh0ZGF0ZTp0aW1lc3RhbXAAMjAyNi0wNi0yOFQyMjozNzozNyswMDowMNPylHkAAAlKSURBVHja7Z0/bFXnGYcfSlq1qkRbxa5ikuJIuBIXxddDB+zBpAqSPRCIyJShKKDwJ5KdIVKYGKwMmTJ44coyqZVIYaATTb3UlpCSeIAlUgAJIwWGKxIRFZTBMygdXFIMOD733HPef36fNcTv7/sevefee873fWfLjySR+YV2gKReUnBwUnBwUnBwUnBwUnBwUnBwUnBwUnBwUnBwUnBwUnBwUnBwUnBwUnBwUnBwUnBwUnBwUnBwntEOUCvbadJgJ/300UP/I/+lzT3u0OYWy1zjO+2g9bEl5KK7Bq+wl2F2FPz3t7nEEhdZ1g5ePdEE7+F1DtAo+X8vM88FLmsPokriCH6Wo7zJSxX8pRvM8Qn3tAdUDTEEDzLByYr/5iwtrmkPrHv8C27yHodr+tvn+JCr2gPsDt+Ce5liouYaLd7nrvZAy+NZ8AQf8DuBOiuc5oz2YMviVXCDacYF6y3yLte1B10Gn4JP0BK/RXOfSWa1B945HgXPckKp8tnKv6vXjjfBO/iUvYr1lzhMW3sSOsGX4D2c50XlDG3e8HSvy5PgMf7Jb7RDADDOonaEovh5XLiffxvRCwvs145QFC8dPMaCdoTHcNLFPgTv4SK/1Q7xBCMePos9XKJ38A+DeuH8miUERvHQwV8yqh1hHZZUf7IVwn4Hz5rVC6Oc1Y6wEdYFn1C7a1WM49bvbdm+RDe4wi+1Q2zAA5qWH0PY7uBp83phK9PaEX4Oy4InRB8IlmeMSe0I62P3Et3DN/xeO0RBVhiwuurDbgdPudEL25jSjrAeVjt40N1ityGbia128HvaATrmlHaAp2Ozg19yuSK5aTG1zQ6ueynsJkptsYOfdbttpNdecosdfFQ7QGmOaAd4Eosd/DVD2hFKcqP0vsbasNfBe9zqhV0Ma0d4HHuCX9cO0BWHtAM8jj3BB7QDxEpvTXDD3qeY7/zWBL+iHaBr9mkHWIs1wXaX5zgdgTXBI9oBoo3A1u/g7SFOrHrB0ihsdfCgdoB4o7Al2Ng30AijsCV4p3aAeKOwJbjo0YO2MbWhxZbg7doBKqFPO8Cj2BL8nHaASujRDvAotn4m/cAftCNUwhbtAP/HVgf/WjtAPGwJ/pV2gHjYukSbCtMFeYlOpEjBwbEl2NUZcj5GYUuwuVXF/kdhS/Ad7QDxRmFLsKmLW4xR2BJ8SztAvFHYEhzjxVSmRmFLsMHtl95HYUvwd9zWjtA1ty2tyLImGC5pB4g2AmuCl7QDRBuBNcEXtQNEG4E1wcu2voP6z29NMMxrB4iV3p7gC9oBYqW39cB/lWV2aUcoSR7hUIg57QCRklvs4B6rB3tuSB6jVIh7Hl8CCcza02uzgz0eRQp5lGEHXOOcdoSOOWdRr9UOhiZXtCN0SB4n3BFXaWlH6IiWTb12Oxh6uck27RAFySP9S3CX09oRCnPaql7LHQywwJh2hAIsWn47jG3Bu7nKVu0QG3CfoXwxVlmu2zxFfQ2TlvVa72CAsxzXjvCz6fLdhV2Tr5ftAtuX6FUO29or8BNtDmtH2BgPHQzD1tYqAvmK9wq5bPCHyLgHvV4EwyKvakdYw6ssakcoho9L9CpjLGhH+B/jXvT66WCARUYMfN1qM+JHry/BcJmXlXcOLPGyj8/eh/gSDG32clat+kfsNXAN6QhvggFO8jb3xas+4G1OaA+9czwKhlmGhD8HF2n6XAroUzBcZ5x3WBGptcI7jNt+pLA+XgUDnGFAYGFPiwHOaA+1PJ5+Bz+dJqf4W01/+xwfWl1rVRT/ggEGmaj8sd0sLZsLYTsjhmCAHo7wViXb1m4wxycWdymUIY7gVYY5xIHSe/yWmeeCrxsZGxFN8CoN9jHKCH8q+O9vc4klLlrbnV8FMQU/5HkGabCTfvroWfO6mzb3uEObWyxzzdbBR9USW3Di+ndwUoAUHJwUHJwUHJwUHJwUHJwUHJwUHJwUHJwUHJwUHJwUHJwUHJwUHJwUHJwUHJwUHJwUHJwUHJxntAOUYv3FdFXjfnGer0V3nS6HrRqHy2u9CO5uQXvVOFogb19wdVtSqsbFFhfbguvYVFY1xjep2RVc57bQqjG8zdSm4F6mHBwkvJYW71s8992i4Ek+cPO2hkdZ4bS9swCsCd7NtItj/NdjkXdtneZhS/BJWuaP8N+I+0xaOo/HkmDbZ7t3NhIz3/2tCO7nU7Pnupdhycox5jYED3O+1jvKGrR5w8K9LguC7RwTXDUGjh3Wf1y4P6xeWGC/dgTtDo7bvQ9R7mJdwTZftlE1qi/v0LxE93Nesbocql8gNTvY7guvqkbxBVp6HTy7afTCqN4p9VqCT3o8Pb0Ljmvd29K5RO/mitPlfuV5QFPjMYROB09vOr2wlWmNshqCJ10/ECzPGJPyReUv0b3cdPk4vwpWGJBe9SHfwVObVi9sY0q6pHQHN7kiPURjDMkuz5Pu4FPC9ewhPAOyHTxodXGpKE3JddSyHextKWw9iM6CZAf3WFw3rEKv3IYXyQ4+IljLNkfkSkl28LLJLWQa3JDbJynXwcOp9yd2MSxVSk7wIbFKHhCbDTnBB8QqeUBsNqQEN8zszreB2HxICd4nVMcPQjMiJXjzLM8pitCMSAkeEarjB6EZkfkd/DzfygzHFS9InLsl08GDIlW8ITIrMoLzG/TTEJkVGcE7Rap4Q2RWZARH2/tbDSKzIiO4T6SKN0RmRUZwj0gVb4jMiszPJAPHCJhkS/0l9Hf4J7WSgoOTgoOTgoOTgoOTgoOTgoOTgoOTgoOTgoOTgoOTgoOTgoOTgoOTgoMjI/gz7WGaRGRWZAR/JVLFGyKzIiP4C5Eq3vhcoojUDv//0CtTyA13+aNEGakvWR8L1fGD0IxIdfAA38gUcsOfuSlRRqqDbzIjVMkHMzJ6JU/ZeY47UqUc0Mf3MoXkbnR8zzGxWtY5JqVX9k7WXF6mAZhhTq6Y9HHC/9r0p+3Mc1CynPS96IPMC1e0hbBejYcNBzfxhXpGWq/Wa3Xe4u8aZZU5JvnZ+xCdx4Vz9G2yPp6hT0Ov7rsLBzjO0fD3qO/yMR9J3dZ4Eu33B8Mof+UvvKYdowY+4yu+4EvdEPqCk1rJJTvBScHBScHBScHBScHBScHBScHBScHBScHBScHBScHBScHBScHBScHBScHBScHBScHBScHBScHB+S/Nz6YLyGbchQAAAABJRU5ErkJggg==",
    ["windmill"] = "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",
    ["world"] = "iVBORw0KGgoAAAANSUhEUgAAAPAAAADwCAQAAACUXCEZAAAAIGNIUk0AAHomAACAhAAA+gAAAIDoAAB1MAAA6mAAADqYAAAXcJy6UTwAAAACYktHRAD/h4/MvwAAAAd0SU1FB+oGHBYlJVXYVKEAAAAldEVYdGRhdGU6Y3JlYXRlADIwMjYtMDYtMjhUMTU6MzA6NDMrMDA6MDDo/hjqAAAAJXRFWHRkYXRlOm1vZGlmeQAyMDI2LTA2LTI4VDIyOjAyOjMwKzAwOjAwPosmbQAAACh0RVh0ZGF0ZTp0aW1lc3RhbXAAMjAyNi0wNi0yOFQyMjozNzozNyswMDowMNPylHkAAA2eSURBVHja7Z3Pq2RHFce/44+oJKKCEJMspibqZDPRrB1l7kvAERQmOpKFoq+fMYJi/oZ+sxVcBLJy4esJiKBEDCj4I7F7FtkFHEk2TkK6AmY0IKiYoEbMddGv8+bNe939PbfOOXVvUZ/ezI9Tp6rut0/Vqbp1b59oUSmZd+RuQMWWKnDhVIELpwpcOFXgwqkCF04VuHCqwIVTBS6cKnDhVIELpwpcOFXgwqkCF04VuHCqwIVTBS6cKnDhVIEL5125G2BCABBwDgBwBbO1lgHn8AoigIiYu+H6nCjm0F0AsA2gQbP/LxGXMKFK7u2XiYiIuIK49ksxKIYvcMA2gN0j/z7BjsDL+IiHiFkJUg9X4FXCLphhS+hvvMLX0IVuh/cJ7bidt+uYdvK6t9bnvB23Tfa+iz/DiuCAbYwQNtqd6pQuBcw32kTMcHlQ0Zz7G6YWtQeMO9cyImuYJ9RRI/gIAdsr59qjRJxKqGlKjA/LeoYRy7m/YRs+fNwuGSXVx8bwYGI5ewNWfkI7Fl7srunV4c9UXGevRc7eAEVx27ZVyHObTvX2VuTsDVAUt233VFqw17H2XorctyRrLEinjtJteXQzzHJpFRETXFK+Jmnk/obd8GnECdVh9OKn+xiyiOQm+7XsXQQfbPh354Ria/jl0vFMcKkf96b6cT94jHmyvJJbC5uIycPsCFOMFVvUndxDSBs6LEyOkr48smjVvA25r29uedNmuwMa9ZZ1Wy4dlThzZp1zDtaYdxfIbw4yTJVaF7GVbz7ONwc3CvPuEpuFiZbXkHU+HvjQvBgGrVo5VWxlpqE6RwQHTJO2M25GEmmfwVmB9WXFVu5inrj06oT/HNxgqt0Hge1v8RbO09bp6+HDsMcANXEeMqS34zYzEtT+UNu2bXsxY3vds2pfecfq8rai+n/ftm3bPicoEQxa7Cqxp7x7BhdLcv/okbdLPZz5S+kosd8crLWqPIzk/tGL+Nj+n67hHrpUyr2l1dis3I/BJ4sORvJOBPI++ra8wGl8hy4XTdKixuRrcww+EWwjryx+I07e8LeX8VG6pE0Mpx0PpPGIYCt5JfH73UPyAneLYnhm0n6rL84h7CPYSl5gS3DhXzoSsS/iNF1af+2+xDyKrSPYTt6ZQN5vHjMgfxzfMKlLhnkU2wpsJ69sG/FRwb+m1ybDWGJLgS3lhSCmvoxPHPvv9+FLBrXJCdizc24n8NhUXkmC9e2V/5M/0VowMrydaLSDonMeYjUjuiWfXuvnU73pkdHulk0E22WdSya05SNr//dbtJ9o3KORzYhnsUyyX9/xr2e4C3/aaHGd9LWHkWmvTI72WESwYcqwD5/TPqxgIa+1G8Fi3NMX2Da5WjCjLTdHeh9Ww0sM8mltgRvVwzjHw9dwkTiPEXqyWFow0p4GdAU2GWSOwA+VX6Osvm5Qc3fGuie3dAW2n30lK+CTuEDZXbjpRsRqPF6mpBwkmgJ7zL7AFdryq7TlV2hLjxgOmtseessk+7Xvfotpy+dxhrR8AfeSli63+BCxozVW6EWwz9n9CW15lpYXOEOflvZ5451iNq0lsM/wLBmgHxL55a09BmnFYVpniPYZuADJIZ3ruEPg9zru6llflfa1dCLYI3tedpvjvEhe4E76eQev15IqDdMaAjdOw7NkBv6i2DdfYubUW5XrqiGw36OR/Az8oNg3X4JvRSoKMZwusNFtrmOZkHYP4Hax79vxAGkZ3fob0jcu0wX2i98JbfmFTv7ZUp4vB0++uqkCK++criXSlp/v5J8vNXPrc3KqlbpM8ny8mF0ifRJXO9ZwH/5A2Xnt2gHJy6W0CPZbHi26yvG5zjWwJdmWaJC45ZEm8MixoxPa8rOd62BL+v5ER5NSOEVg3zfHsIuT23B/5zrux22kpc+G5YKkeThF4JFjJ/nEhl3spJVmW6ND071od4GZXz/RJJJ2aQ9Ws6V9B+mE9XBf3jarxzsTy/8vdwd0KU/gyiH68TrhihlV4MKpAhdOFbhwqsCFUwUunCpw4VSBC6cKXDhV4MKpAhdOFbhwqsCFUwUunCpw4VSBC6cKXDhV4MKRCBzcfgvmxk9Dtu5x1VofJ2ttslyTYCNwvxF02t1bxr5KBG6ydCbqd1rRG9s6XQR9lQjMvi5Ml6jfaUVvbOt0Oceb9j+COW7Brar+bsUtpGXM3fX19H0OjqTdR9Rr1veoR+BNS4lg+SsbtDzGDL1teFNe4JChI/zl+7B6zfoeNQmsYRU41SPbQl0Ca8gLLMjcFImk3YfUa9b3qElgDfueZLF8MJvHmKW/9JK170M0ywcG4FGTwBqWEsHvz+bxldxdX0/fI5i9fLrbHDYes1BKBL9vAB41CaxhKQK/dwAes9D3IZrlPQPwmIW+R3Ak7d6tXjPrkW2hLoE1LCWCU9+t4+ExC32P4Hz96PeVCWV0o5IML3DM3dS1vDUAj5pE1rCUCNZ/P10hb7zru8CBtPuves2sR7aFmShliP7PADxqElnDvkcwy78H4DELpUTwvwbgUZPIGpYSwW9k85jntDhN3wVmL98/1WvW96hJZA1LGaL/MQCPWeAFznNyIZB2f1evWd9jFkqJ4L9l8xiy9Jf+gcy+CxxIu7+q18x6ZFuoy4w1lAgcs3SFI5/APafvWXQg7V5Tr5n1yLZQk8ibSgSeZehKIO3+ol4z65FtoSYz3rTvEcxewDeVtzrewJu5O76GyJtKBPb7aXPjTit6C1n6KliySgRmO61LyNK6PH01aF3f52CTTit6C1n6OuNN60/bFU7/k6xKElXgwqkCF04VuHCqwIVTBS6cKnDhVIELpwpcOFXgwqkCF04VuHCqwIVTBS6cKnDhVIELpwpcOFXgwqkCF053gUeuv9Y3p9v1WFI9j9H1zF37P/IXeOZ6tDTQPyXzu6R6+NLBsffApGvB7gJHXHLtIvujIM8k1cKWHrn2fad70ZQ5eObayYa0ex3TznVM8Tpp6fsbNJPuRVMEjinfLDGBtvxN5zr4ko1jz3dTCqdl0TPHbvKz8K8618GWHLnOwJdTCqcJ7BvD7LB4FS918v8Srjr2hmU3LZlNXQd75tINbfnLTv75UttufUZqKpsqsGcuHWjLX3Tyz5dq3PqcPEKm72TN3GZifhZ+usMrHV7D06TlyKm/wCwlf16QLrBnDPND41Ni33wJvyWSwpXV2Iv2i+GGtvyZ2Ddfgm9FGirXVef54CDYK05ji+70ddwh8Ptn3Enbej1SfUojgdW5m+S3XAq05U9FfnnrkVNPd3TWJ1q3CydOwzQ/C/9E5Je39pmBFdKrBXqvcPAZpiNO0bbP4wxp+QLupb36DND8VLQBvRv+PsN0EAyRPzaw5GtPYVdvPNQ80eGTTfOD9I8MLD32sGaaC0/dt+z4DNP88PVzXCCsnsKDdN0eA7RK9rxE90yWzzDNpzlPKFoBPgP0lvLuvvrxoXFrzVzQmrmzt1TG2nron6q8bD4T83vSwA8VLJY05neBVWffBfoCR60l+hr4VEdTYPsEy2CCszgXHbFlfCEa2vLVDTPsE3jVoNZuaM++AKwOvlsnW5JB+gcJ/3sj1sd01LY2DmP1ZMMk7ajYRsa05bNrjsI+g2dpP7ZblIpbGzdheBzfMp+W5L4XV3q5KPBiydROBctnkyzzacmW5ZMrDtNdxZO0D742OTPLnMVS4IgdQ4klOe3jgn9Nr02GqbwwHaLRog3t1GxgawTtuHak9DVB6WaIg7P9EA3YRjGfaOGYpwb55whlNUmwjl74vNI/YM9oDSlZWrx86E7yHHcL2m9zC8VBXp8HwO2iWDIzfn/N39ZjE78u8vr9KEfAtsHKOIp2f/6I0/t/uoZ7BLVYXCInef1e4RBx2UDgIIqu7x3zp83sGVyNiZe8MM+iD3/G6lmoZMMD7XNt27btc6Iy+qjfElz38RXYQuKRoPbFnpZk/2qk3t7G94r7/zBWwFR1215yzhL4NYDzAvu5clstt36OxzmC0epvfkhi+Gx7Nlv8mm9q9COCAe2cWhbDEjTjd9f5pTVLcnyrWrS623+NSQv14nfuPfMefPK96W6GU2rzkc1WhNYNhmh1M58h56sMI3aUBurGYCtUy+eu7jlnKfl/XlZnp1p/Hp6qtMrknJWE/C8jjdhSiGPJAQCGkYK8mWN3Qf4IXhAwTpRIN4ZT8+eZw+FhivwRvCBiJzHpCoq7xuMkeSO28g/NS/oSwQsCmoSLqzXjpdz/jZhkWu+uIts6eNUnJOxX76m0YNq5ftfbCNwnewOURW6S6+62ATPvo7gtcm1VMgRsd3iaID3Vki+P+jcs30jub9iGSB6JB8xRUo3S7cneRm7/I/gA2RIqLYYly6NdXMm3BUmT+xtmEMvdUy125u993A4rgg8I2Cb2iLsul5jlUcQEl/uyxmUYlsALNss86fT46vr0anDSLhiiwAsCGpxbOTfLJV4lb8TM/RdmFBmuwEsWQh99JFx2gmLvyFclYgKVF/rmZfgCLwkICIeknuESleUe3LCMiJgBg8iOScoR+EYCFoKfBDbMm83+k/tX4P07UE6UKXDlbfpyu7BiRBW4cKrAhVMFLpwqcOFUgQunClw4VeDCqQIXThW4cKrAhVMFLpwqcOFUgQunClw4VeDCqQIXThW4cKrAhfN/67TOvvnPhtMAAAAASUVORK5CYII=",
    ["x"] = "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",
--__ICON_DATA_END__
}
Interface.iconData = ICON_DATA

-- Minimal base64 decoder for the embedded pack.
local B64 = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
local b64lookup
local function base64Decode(data)
    if not b64lookup then
        b64lookup = {}
        for i = 1, #B64 do
            b64lookup[string.byte(B64, i)] = i - 1
        end
    end
    data = string.gsub(data, "[^" .. B64 .. "=]", "")
    local out = {}
    local i = 1
    local n = #data
    while i <= n do
        local c1 = b64lookup[string.byte(data, i)] or 0
        local c2 = b64lookup[string.byte(data, i + 1)] or 0
        local c3 = b64lookup[string.byte(data, i + 2)]
        local c4 = b64lookup[string.byte(data, i + 3)]
        local b1 = c1 * 4 + math.floor(c2 / 16)
        out[#out + 1] = string.char(b1)
        if c3 ~= nil and string.byte(data, i + 2) ~= 61 then
            local b2 = (c2 % 16) * 16 + math.floor(c3 / 4)
            out[#out + 1] = string.char(b2)
            if c4 ~= nil and string.byte(data, i + 3) ~= 61 then
                local b3 = (c3 % 4) * 64 + c4
                out[#out + 1] = string.char(b3)
            end
        end
        i = i + 4
    end
    return table.concat(out)
end

-- Decode the embedded pack to a cache folder, then load it via getcustomasset.
-- A build stamp sits next to the cached PNGs: while it matches this build the
-- files are reused as they are, so a session only decodes and writes an icon the
-- first time that build sees it.
ICONS.cacheDir = "NewReality/iconcache/"
ICONS.stampPath = ICONS.cacheDir .. "build.txt"
ICONS.ready = false
ICONS.fresh = false
local function ensureCache()
    if ICONS.ready then return ICONS.ready end
    pcall(function()
        if folderMake and folderExists then
            if not folderExists("NewReality") then folderMake("NewReality") end
            if not folderExists(ICONS.cacheDir) then folderMake(ICONS.cacheDir) end
        end
        if fileExists and fileRead and fileExists(ICONS.stampPath) then
            ICONS.fresh = fileRead(ICONS.stampPath) == Interface.version
        end
        if not ICONS.fresh and fileWrite then
            fileWrite(ICONS.stampPath, Interface.version)
            ICONS.fresh = true
        end
        ICONS.ready = true
    end)
    return ICONS.ready
end

local function embeddedAsset(name)
    local b64 = ICON_DATA[name]
    if not b64 then return nil end
    if not (fileWrite and customAsset) then return nil end
    local path = ICONS.cacheDir .. name .. ".png"
    local ok, asset = pcall(function()
        ensureCache()
        -- Only decode when the cached file is missing or was written by an older
        -- build, so updated embedded data is never masked by a stale file.
        local cached = ICONS.fresh and fileExists and fileExists(path)
        if not cached then
            fileWrite(path, base64Decode(b64))
        end
        return customAsset(path)
    end)
    if ok then return asset end
    return nil
end

local function probeIconFolder()
    if ICONS.folder ~= nil then
        return ICONS.folder
    end
    ICONS.folder = false
    pcall(function()
        if not fileExists then return end
        for _, dir in ipairs(ICONS.dirs) do
            if fileExists(dir .. "settings.png") then
                ICONS.folder = dir
                return
            end
        end
    end)
    return ICONS.folder
end

local function iconAsset(name)
    if not name or name == "" then
        return nil
    end
    -- Explicit overrides and direct asset ids pass straight through. An override
    -- is meant to be an asset id string, so anything else is ignored rather than
    -- carried into the string calls below.
    local override = Interface.icons[name]
    if type(override) == "string" and override ~= "" then
        name = override
    end
    if string.sub(name, 1, 3) == "rbx" or string.sub(name, 1, 4) == "http" then
        return name
    end
    name = string.lower(name)
    if ICONS.cache[name] ~= nil then
        return ICONS.cache[name] or nil
    end
    local result = false
    -- Embedded pack first (self contained), then an optional workspace folder.
    local emb = embeddedAsset(name)
    if emb then
        result = emb
    else
        pcall(function()
            if not (fileExists and customAsset) then return end
            local dir = probeIconFolder()
            if dir then
                local path = dir .. name .. ".png"
                if fileExists(path) then
                    result = customAsset(path)
                end
            end
        end)
    end
    if not ICONS.logged then
        ICONS.logged = true
        local count = 0
        for _ in pairs(ICON_DATA) do count += 1 end
        if count > 0 then
            log("info", "embedded icons: " .. count)
        else
            log("warn", "no embedded icons present")
        end
    end
    ICONS.cache[name] = result
    return result or nil
end
Interface.iconAsset = iconAsset

-- Force a specific icon folder (relative to the executor workspace).
function Interface.setIconFolder(folder)
    ICONS.folder = folder
    ICONS.cache = {}
    ICONS.logged = false
end

-- Every name the pack answers to, sorted, so a script can browse what it has
-- instead of guessing at a name and getting an empty square.
function Interface.iconNames()
    local names = {}
    for name in pairs(ICON_DATA) do
        table.insert(names, name)
    end
    for name in pairs(Interface.icons) do
        if not ICON_DATA[name] then
            table.insert(names, name)
        end
    end
    table.sort(names)
    return names
end

-- makeIcon(parent, name, size [, key]) where key is a palette key the tint
-- follows. Passing a Color3 pins the tint instead.
local function makeIcon(parent, name, size, key)
    local img = newInstance("ImageLabel")
    img.BackgroundTransparency = 1
    img.Size = size or UDim2.new(0, 18, 0, 18)
    img.Image = iconAsset(name) or ""
    img.ScaleType = Enum.ScaleType.Fit
    if type(key) == "string" then
        themed(img, "ImageColor3", key)
    else
        img.ImageColor3 = key or PALETTE.text
    end
    img.Parent = parent
    return img
end

-- The NewReality mark: one logo cut into two layers that sit exactly on top of
-- each other. The C follows the accent colour, the H stays white, so a theme
-- change repaints half the logo and nothing has to be re-exported.
local function logoMark(parent, size, opts)
    opts = opts or {}
    local holder = newInstance("Frame")
    holder.Name = randomName()
    holder.BackgroundTransparency = 1
    holder.Size = size or UDim2.new(0, 40, 0, 40)
    holder.Parent = parent

    local back = newInstance("ImageLabel")
    back.Name = randomName()
    back.BackgroundTransparency = 1
    back.Size = UDim2.new(1, 0, 1, 0)
    back.Image = iconAsset("logo-c") or ""
    back.ScaleType = Enum.ScaleType.Fit
    back.Parent = holder
    -- Registered after it is parented, and the registry holds it strongly, so
    -- the accent half keeps following setColor even though the caller keeps no
    -- reference of its own.
    themed(back, "ImageColor3", "accent")

    local front = newInstance("ImageLabel")
    front.Name = randomName()
    front.BackgroundTransparency = 1
    front.Size = UDim2.new(1, 0, 1, 0)
    front.Image = iconAsset("logo-h") or ""
    front.ScaleType = Enum.ScaleType.Fit
    front.ZIndex = (opts.zIndex or 1) + 1
    front.Parent = holder
    if opts.letterColor then
        front.ImageColor3 = opts.letterColor
    else
        themed(front, "ImageColor3", "icon")
    end

    if opts.zIndex then
        holder.ZIndex = opts.zIndex
        back.ZIndex = opts.zIndex
    end
    -- The last return says whether the pack is missing both halves, the caller
    -- then hides the holder instead of leaving a blank square.
    return holder, back, front, (back.Image == "" and front.Image == "")
end
Interface.logo = logoMark

-- Where the ScreenGui goes. The executor's hidden container is preferred: the
-- GUI is then not listed under CoreGui, so nothing walking the tree finds it.
local function guiParent(gui)
    if gui then
        pcall(function()
            if syn and syn.protect_gui then syn.protect_gui(gui) end
        end)
        pcall(function()
            if protectgui then protectgui(gui) end
        end)
    end
    if guiHidden then
        local ok, hidden = pcall(guiHidden)
        if ok and hidden then return hidden end
    end
    local ok, coreGui = pcall(game.GetService, game, "CoreGui")
    if ok and coreGui then
        return coreGui
    end
    return LocalPlayer:WaitForChild("PlayerGui")
end

-- Layout order counter per container. Kept in a weak table instead of an
-- instance attribute: it is one table lookup instead of two property calls per
-- row, and the GUI tree carries no marks that describe the layout.
local ORDER = setmetatable({}, { __mode = "k" })
local function nextOrder(holder)
    local n = (ORDER[holder] or 0) + 1
    ORDER[holder] = n
    return n
end

-- Motion ----------------------------------------------------------------------
-- Four curves, each with a job:
--   EASE      Quint out, the base curve for anything that travels
--   EASE_SOFT Sine out, colour and opacity, where an overshoot reads as a glitch
--   EASE_POP  Back out, parts that should settle: a knob, the window, a panel
--   EASE_JELLY Back out over a longer beat, the toast stack shifting up
local EASE = Enum.EasingStyle.Quint
local EASE_SOFT = Enum.EasingStyle.Sine
local EASE_POP = Enum.EasingStyle.Back
local EASE_JELLY = Enum.EasingStyle.Back
local OUT = Enum.EasingDirection.Out

local function tween(instance, time, props, style, dir)
    local info = TweenInfo.new(time, style or EASE, dir or OUT)
    local t = TweenService:Create(instance, info, props)
    t:Play()
    return t
end

-- Fade a whole panel, text and all, with one number.
--
-- This is what a CanvasGroup is for and there is no substitute for it. Two other ways
-- were tried and both were worse. Writing a transparency onto every part of the panel
-- only works if nothing else writes the same property, and in a kit this size something
-- always does: the palette opacity has an opinion about text transparency, a dropdown
-- row paints its own background by state, a hover lifts a fill. Fading only the panel's
-- own surface and leaving the content alone is worse still, because a panel on its way
-- out then leaves its words hanging in the air, and a half faded card with solid text on
-- it does not read as a panel leaving, it reads as a rendering fault.
--
-- The reason a group was taken out in the first place was soft text, and the condition
-- for that is worth stating, because it is avoidable. A group renders its children into
-- a texture and blits it. If the blit is one to one the result is pixel exact and the
-- text is identical to text drawn straight to the screen. It is only soft when the blit
-- is not one to one: a fractional position, a UIScale, a size that is not a whole number
-- of pixels. So the rule is not "no groups", it is "no group is ever moved to half a
-- pixel and nothing is ever scaled", and the kit holds to that: whole pixel drags, whole
-- pixel placement, even window and sidebar widths, no UIScale on anything with text.
--
-- A UIStroke is drawn outside the raster, so GroupTransparency does not composite it and
-- it is faded on the same clock by hand. Any difference between the two and the border
-- is the last thing left on screen.
local function groupFade(root)
    local edge = nil
    for _, child in ipairs(root:GetChildren()) do
        if child:IsA("UIStroke") then edge = child end
    end
    local line = edge and edge.Transparency or 0
    -- Only a CanvasGroup has GroupTransparency. If this ended up on a plain frame, because
    -- a client would not create the group, the surface alone is faded rather than throwing:
    -- an interface that animates poorly still beats an interface that does not appear.
    local grouped = root:IsA("CanvasGroup")
    local fill = root.BackgroundTransparency

    -- alpha 1 is the panel at rest, 0 is gone.
    return function(alpha)
        if grouped then
            root.GroupTransparency = 1 - alpha
        else
            root.BackgroundTransparency = fill + (1 - fill) * (1 - alpha)
        end
        if edge then
            edge.Transparency = line + (1 - line) * (1 - alpha)
        end
    end
end

-- Make a group, or the nearest thing to one this client will give us. CanvasGroup has been
-- in the engine for years, but this runs under executors on clients nobody chose, and a
-- window that fails to build is a window nobody can use.
local function newGroup()
    local ok, group = pcall(newInstance, "CanvasGroup")
    if ok and group then return group end
    log("warn", "CanvasGroup unavailable, falling back to a frame")
    return newInstance("Frame")
end

-- How far below its resting place the window starts and ends. Kept in one place so
-- opening and closing cannot drift apart.
LAYOUT.windowRise = 34
local function WINDOW_LIFT(resting)
    return UDim2.new(resting.X.Scale, resting.X.Offset, resting.Y.Scale, resting.Y.Offset + LAYOUT.windowRise)
end

-- A section change: the page that was open is hidden at once, and the content of the
-- one that opens settles into place.
--
-- The two columns rise, the right one a beat behind the left. That stagger is the whole
-- animation, and it is deliberately the only thing that moves: two frames, each written
-- to its resting place by its own tween, so an interrupted change cannot leave anything
-- parked off screen. There is no fade, because fading a page means fading every card on
-- it, and no exit animation, because an exit that has to hide the page when it finishes
-- needs a completion callback, and a position tween reports completion the moment
-- something else takes the property over. That is what left two pages drawn on top of
-- each other: the sub-tab bar of the section you had left, over the one you had opened.
LAYOUT.columnRise = 14
MOTION.columnLead = 0.26
MOTION.columnTrail = 0.34

local function enterColumns(columns)
    for index, column in ipairs(columns) do
        local home = column.home
        local frame = column.frame
        frame.Position = UDim2.new(
            home.X.Scale, home.X.Offset,
            home.Y.Scale, home.Y.Offset + LAYOUT.columnRise
        )
        tween(frame, index == 1 and MOTION.columnLead or MOTION.columnTrail, { Position = home }, EASE)
    end
end

-- Gentle icon colour transition.
local function tintIcon(img, color)
    tween(img, 0.18, { ImageColor3 = color }, EASE_SOFT)
end

-- The shading on a filled bar.
--
-- Every bar in the kit carries it, sliders and progress rows alike, because one bar
-- shaded and the next one flat reads as a mistake. It runs the full width of the fill
-- at every value, so the slope is the same whether the bar is at a tenth or full, and
-- the shading reads as one piece across the track rather than as per bar decoration.
--
-- The gradient owns the bar's colour, and the fill under it is white.
--
-- That is the whole trick, and it is there because a UIGradient multiplies whatever it
-- sits on. Over a coloured fill it can therefore only ever darken, which is fine over
-- cyan and useless over navy: multiplying a dark accent takes it to black and the
-- shading vanishes into the track behind it. Painting the fill white and putting the
-- real colour in the keypoints puts both directions in reach, so the ramp can run
-- below the accent at one end and above it at the other.
--
-- The fill still follows the accent's opacity through the theme registry, it just does
-- not follow its colour. See themed() and opts.paint.
--
-- Which ramps follow the accent, held the same way and for the same reason as the theme
-- registry: strongly, and swept of dead entries when it is walked. The value is the fixed
-- colour a bar was given, or false when it follows the accent.
--
-- This was a weak keyed table, and that was the bug behind "the accent does not change the
-- bars". A ramp is a UIGradient that nothing in Lua refers to once barRamp has returned:
-- the fill holds it in the tree, not in a table. So the only Lua reference to it was the
-- key of this table, and a weak key is not a reference. Roblox is free to drop the wrapper
-- for an instance nothing is holding, and when it does the entry leaves the table, and a
-- ramp that has left the table is never rebuilt again. The bar keeps the accent it was
-- built with for the rest of the session.
--
-- Nothing else in the kit was hit by this, which is why it looked like the bars were
-- special: every other part that follows a colour is in THEME_REG, which is strong, and
-- that reference is what was keeping the state painters alive too. A bar's fill is in
-- there, so the fill kept following the accent's opacity. Only the gradient over it, the
-- one thing that owns the bar's colour, was held weakly.
local BAR_RAMPS = {}
local RAMP_DARK = Color3.new(0, 0, 0)
local RAMP_LIGHT = Color3.new(1, 1, 1)

local function rampColours(color)
    local base = color or PALETTE.accent
    -- Which way the ramp runs comes from how bright the colour is, and it rotates
    -- rather than switching over: a bright accent is shaded down towards the start of
    -- the bar, which is the look the kit has always had, and as the accent darkens that
    -- shading gives way to a lift towards the end. In the middle both are present and
    -- shallow. A hard threshold was the obvious version and the wrong one, since two
    -- accents a shade apart would then be shaded in opposite directions.
    local weight = math.clamp((luminance(base) - 0.15) / 0.45, 0, 1)
    return ColorSequence.new({
        ColorSequenceKeypoint.new(0, base:Lerp(RAMP_DARK, 0.55 * weight)),
        ColorSequenceKeypoint.new(1, base:Lerp(RAMP_LIGHT, 0.48 * (1 - weight))),
    })
end

local function refreshBarRamps(accent)
    tagWalk(BAR_RAMPS, function(ramp, fixed)
        ramp.Color = rampColours(typeof(fixed) == "Color3" and fixed or accent)
    end)
end

-- barRamp(fill [, color]) takes over the fill's colour. Without a colour the bar
-- follows the accent, with one it stays that colour through a theme change.
local function barRamp(fill, color)
    fill.BackgroundColor3 = RAMP_LIGHT
    if not color then
        themed(fill, "BackgroundColor3", "accent", { paint = false })
    end
    local ramp = newInstance("UIGradient")
    ramp.Color = rampColours(color)
    -- Parented before it is registered, so tagWalk knows it is a live part rather than one
    -- the builder has not finished assembling.
    ramp.Parent = fill
    tagAdd(BAR_RAMPS, ramp, color or false)
    return ramp
end

-- Hover on a filled surface: the fill lifts to the hover colour and nothing else
-- happens. An outline that appeared on hover was tried and dropped, it drew a
-- second border on top of a shape that already had one and read as a defect
-- rather than as feedback. Returns settle(), so a control can force the resting
-- look after a click without re-reading its own state.
local function hoverSurface(part, opts)
    opts = opts or {}
    local base = opts.base or function() return PALETTE.control end
    local over = opts.hover or function() return PALETTE.controlHover end
    local hovering = false
    local queued = false

    local function apply(instant)
        local color = hovering and over() or base()
        if instant then
            part.BackgroundColor3 = color
        else
            tween(part, hovering and 0.14 or 0.2, { BackgroundColor3 = color }, EASE_SOFT)
        end
    end

    -- Enter and leave are coalesced into one repaint per frame.
    --
    -- Clicking a button quickly makes the engine deliver several enter and leave
    -- pairs in a single frame, and sometimes out of order. Acting on each one starts
    -- a tween that the next one immediately supersedes, and the surface flickers or
    -- ends up stuck on whichever colour the last stray event asked for. Recording
    -- the state and repainting once, from the state, cannot be knocked out of order.
    local function settle(instant)
        if instant then
            queued = false
            apply(true)
            return
        end
        if queued then return end
        queued = true
        task.defer(function()
            queued = false
            if part.Parent then apply(false) end
        end)
    end

    part.MouseEnter:Connect(function()
        hovering = true
        settle()
    end)
    part.MouseLeave:Connect(function()
        hovering = false
        settle()
    end)
    return settle
end

-- There is no press animation anywhere in the kit, and this is the note that says so
-- rather than an implementation.
--
-- A squash on mouse down was the last one left, on the toggle pill. It was a UIScale, and
-- a UIScale inside the body group means that part of the raster is re-rendered at a
-- fractional size for the length of the tween. Three separate things came out of that: the
-- knob shivered, the pill's rounded corner was resampled and showed a bright edge, and
-- pressing repeatedly stacked a squash on a release on a squash. The expanding ring that
-- used to mark a click went earlier for a related reason: it was clipped to the button's
-- rectangle, so on a rounded button it squared off the corners on the way past.
--
-- A press is already answered by what the control does. A toggle moves its knob, a button
-- lifts its fill, a slider follows the pointer. None of them need to be squeezed as well.

-- Drag a frame by a handle. The frame is kept on screen (a margin of it always
-- stays inside the viewport) and onDrop fires once the pointer is released, so
-- the overlays can persist their new position.
-- Take a press and turn it into a drag of the frame. Split out from makeDraggable
-- because the window has a second way in: a press that lands on its title strip
-- while a floating panel is open arrives at the panel's click catcher instead of at
-- the strip, and it has to be handed on rather than swallowed.
local function startDrag(frame, input, onDrop)
    local origin = input.Position
    local startPos = frame.Position
    local startAbs = frame.AbsolutePosition
    local size = frame.AbsoluteSize
    local view = viewport()
    beginDrag({
        move = function(x, y)
            local wantX = startAbs.X + (x - origin.X)
            local wantY = startAbs.Y + (y - origin.Y)
            local keptX = math.clamp(wantX, 40 - size.X, view.X - 40)
            local keptY = math.clamp(wantY, 0, view.Y - 28)
            -- Whole pixels only. A frame parked on a fractional offset is sampled
            -- between pixels, and text on it comes out soft.
            frame.Position = UDim2.new(
                startPos.X.Scale, math.floor(startPos.X.Offset + (keptX - startAbs.X) + 0.5),
                startPos.Y.Scale, math.floor(startPos.Y.Offset + (keptY - startAbs.Y) + 0.5)
            )
        end,
        stop = function()
            if onDrop then onDrop(frame) end
        end,
    })
end

-- Is this press inside the rectangle of that element?
local function pressedOver(input, element)
    if not (element and element.Parent) then return false end
    local at = input.Position
    local origin = element.AbsolutePosition
    local size = element.AbsoluteSize
    return at.X >= origin.X and at.X <= origin.X + size.X
        and at.Y >= origin.Y and at.Y <= origin.Y + size.Y
end

local function makeDraggable(frame, handle, onDrop)
    handle.Active = true
    handle.InputBegan:Connect(function(input)
        if not isPointer(input.UserInputType) then return end
        startDrag(frame, input, onDrop)
    end)
end

-- The NewReality brand text with the text to accent scrolling gradient. The
-- sweep runs off the shared ticker and stops itself when the label is gone.
--
-- The colours cannot come from the theme registry. The registry writes one property
-- per entry, and this needs a whole ColorSequence rebuilt out of two keys at once, so
-- there is nothing for it to write. It goes in with the state painters instead, which
-- is where everything whose colour is not a single palette key already lives: they run
-- at the end of every palette pass, so the wordmark eases along with the rest of the
-- interface rather than snapping when the ease ends.
--
-- The rebuild used to be handed back for the caller to drop into _refresh. That is the
-- list that re-reads control values, and setColor does not walk it, so the one accent
-- coloured thing at the top of the sidebar sat on the old accent through every theme
-- change until something unrelated happened to force a refresh.
local function animateBrand(label)
    local gradient = newInstance("UIGradient")
    gradient.Parent = label
    -- shownColor, not PALETTE: during a change the first is the colour on screen and
    -- the second is the one it is heading for.
    --
    -- The label itself is held white, because a UIGradient multiplies the colour of the
    -- thing it sits on. Painting the label the text colour as well squared it: the ends
    -- came out dimmer than text everywhere else, and the accent in the middle came out
    -- dimmer than the accent everywhere else. On a light preset it stopped being a shade
    -- and became the whole of it, since text there is nearly black and the wordmark was
    -- the accent multiplied by a tenth: a dark smear with no accent in it at all.
    --
    -- Written here rather than left to the builder because a TextLabel starts out black,
    -- and a gradient over black is invisible. The label still goes into the text key's
    -- registry for its opacity, with paint = false so the key does not write its colour
    -- (see themed and opts.paint), which leaves nothing else to set it.
    addStatePainter(label, function()
        label.TextColor3 = RAMP_LIGHT
        gradient.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, shownColor("text")),
            ColorSequenceKeypoint.new(0.5, shownColor("accent")),
            ColorSequenceKeypoint.new(1, shownColor("text")),
        })
    end)
    local phase, stop = 0, nil
    stop = addTicker(0, function(dt)
        if not label.Parent then
            if stop then stop() end
            return
        end
        phase = (phase + dt * 0.55) % 1
        gradient.Offset = Vector2.new(-1 + phase * 2, 0)
    end)
end

-- An accent underline that slides between the buttons of a bar instead of one
-- line per button blinking on and off. The geometry comes from the buttons'
-- absolute rectangles because they are auto sized, and the first placement is
-- deferred until the layout has given them a width.
local function slidingUnderline(bar, thickness)
    local line = newInstance("Frame")
    line.Name = randomName()
    line.AnchorPoint = Vector2.new(0, 1)
    line.Position = UDim2.new(0, 0, 1, 0)
    line.Size = UDim2.new(0, 0, 0, thickness or 2)
    line.BorderSizePixel = 0
    line.ZIndex = 3
    themed(line, "BackgroundColor3", "accentSoft")
    line.Parent = bar
    corner(line, 1)

    local current = nil
    -- Auto sized buttons have no width until the layout has run, and a tab that
    -- was never opened has none at all, so the retry is capped rather than
    -- deferring itself for the rest of the session.
    local function place(target, animate, attempt)
        attempt = attempt or 0
        current = target or current
        if not current or not current.Parent then return end
        local width = current.AbsoluteSize.X
        if width < 1 then
            if attempt >= 8 then return end
            task.defer(function() place(nil, false, attempt + 1) end)
            return
        end
        local x = current.AbsolutePosition.X - bar.AbsolutePosition.X
        local size = UDim2.new(0, width, 0, thickness or 2)
        local position = UDim2.new(0, x, 1, 0)
        if animate then
            tween(line, 0.28, { Position = position, Size = size }, EASE)
        else
            line.Position = position
            line.Size = size
        end
    end
    -- The bar shifts when the window moves or the sub-tab list is re-laid out.
    local conn = bar:GetPropertyChangedSignal("AbsolutePosition"):Connect(function() place(nil, false) end)
    line.Destroying:Connect(function() conn:Disconnect() end)
    return place
end

-- Floating panels -------------------------------------------------------------
-- Dropdown lists, colour pickers and gear popovers are not children of the
-- control that opens them: they live in the window overlay so they always draw
-- above the cards. That also means they have to be told where their control
-- went, otherwise scrolling the column leaves the panel behind, floating over
-- the wrong row.
--
-- openPanel glues a panel to its anchor. AbsolutePosition of the anchor changes
-- on every scroll and every window move, the panel is placed again from it, and
-- while the anchor is scrolled out of its column the panel hides with it.

-- Nearest scrolling ancestor, so a panel knows which viewport it belongs to.
local function scrollerOf(instance)
    local node = instance.Parent
    while node do
        if node:IsA("ScrollingFrame") then return node end
        if node:IsA("ScreenGui") then return nil end
        node = node.Parent
    end
    return nil
end

-- cfg: anchor, width, height (first guess until auto size settles), gap,
-- offsetX, radius, popover (stays open when a child panel opens), onClose.
local function openPanel(ctx, cfg)
    local stack = ctx._panels
    local zBase = 50 + #stack * 10
    local anchor = cfg.anchor
    local width = cfg.width or 210
    local gap = cfg.gap or 6

    -- Click catcher under the panel: anything outside it closes this panel only,
    -- so a dropdown opened inside a gear popover does not close the popover.
    local backdrop = newInstance("TextButton")
    backdrop.Name = randomName()
    backdrop.Size = UDim2.new(1, 0, 1, 0)
    backdrop.BackgroundTransparency = 1
    backdrop.AutoButtonColor = false
    backdrop.Text = ""
    backdrop.ZIndex = zBase
    backdrop.Parent = ctx.overlay

    -- The panel itself is not a button, so a click landing on its padding rather
    -- than on one of its controls went straight through to the catcher underneath
    -- and closed the thing that was being clicked. The shield swallows those. It is
    -- inflated a little past the panel as well, so nearly missing the edge of an
    -- open panel does nothing instead of dismissing it.
    local SHIELD_MARGIN = 10
    local shield = newInstance("TextButton")
    shield.Name = randomName()
    shield.BackgroundTransparency = 1
    shield.AutoButtonColor = false
    shield.Text = ""
    shield.ZIndex = zBase + 1
    shield.Parent = ctx.overlay

    -- A group, so the whole panel fades as one thing: the rows, the words on them and
    -- the surface under them, all at the same rate. Placed on whole pixels and never
    -- scaled, which is the condition for the blit being one to one and the text being
    -- pixel exact. See groupFade.
    local panel = newGroup()
    panel.Name = randomName()
    panel.Size = UDim2.new(0, width, 0, cfg.height or 0)
    panel.AutomaticSize = Enum.AutomaticSize.Y
    panel.BorderSizePixel = 0
    panel.ZIndex = zBase + 2
    panel.Parent = ctx.overlay
    themed(panel, "BackgroundColor3", "card")
    corner(panel, cfg.radius or 10)
    -- 0.35 is the outline's resting opacity and the fade treats it as the floor, so
    -- the border arrives with the fill instead of ahead of it.
    stroke(panel, "stroke", 1, 0.35)

    local scroller = scrollerOf(anchor)
    local controller, closed = nil, false
    local resting = panel.Position
    -- Declared ahead of place(), which dismisses the panel when the row it belongs to
    -- has left the tree.
    local closePanel

    -- The entry movement is an offset that decays to zero, not a tween on Position.
    --
    -- place() has to stay the only thing that writes Position. When a tween owned it
    -- instead, two things went wrong: the tween's target was the resting place as it
    -- was known at the moment the panel opened, before an auto sized panel had
    -- reported its real height, and place() had to be muted for the length of the
    -- animation, so scrolling the column in that quarter second left the panel
    -- behind, floating over rows it did not belong to. Now a scroll and the entry
    -- can both be in flight and the panel is drawn from the sum of them.
    local slideOffset = 0
    local slideStop = nil
    -- Set by slide() while it is running. Shifts the rest of the travel by a number of
    -- pixels without moving its destination, which is how a change of target part way
    -- through an entry is absorbed instead of snapped. See place().
    local slideRebase = nil
    -- Which way the panel went when its row was scrolled out, so it can come back
    -- the same way.
    local lastExit = nil
    -- Which side of its row the panel ended up on, written by place(). It decides which
    -- way the panel travels on the way in: out of the row and away from it, whichever
    -- side that turns out to be.
    local onTop = false
    local setAlpha = groupFade(panel)
    local alphaNow = 0
    setAlpha(0)

    -- Where the panel is drawn on the vertical axis, as opposed to where it belongs.
    -- place() explains why those are two different things.
    local drawnY = nil
    local lastTarget = 0
    local lastAnchorY = nil
    local catchUpStop = nil

    local function drawY()
        return (drawnY or resting.Y.Offset) + slideOffset
    end

    -- Whole pixels, every frame of the travel and not only at the end of it.
    --
    -- fitPanel already rounds the resting place, for the reason given there: this is a
    -- CanvasGroup, so it is rendered into a texture and blitted, and half a pixel of offset
    -- is half a pixel of blur across everything written on it. The travel offset is a float,
    -- so during the slide the panel sat on fractions and only landed on a whole pixel on the
    -- last frame, which sharpened the whole panel in one step at the end of an animation
    -- that was otherwise smooth. Rounding here costs the last pixel or two of creep, which
    -- was below the threshold of being movement anyway.
    local function write()
        panel.Position = UDim2.new(
            resting.X.Scale, resting.X.Offset,
            resting.Y.Scale, math.floor(drawY() + 0.5)
        )
    end

    -- Ease the drawn position onto wherever the panel now belongs.
    --
    -- Exponential rather than a tween over a fixed distance, because the target can keep
    -- moving while this runs: a panel pushed off the bottom of the screen while the
    -- column is still being scrolled is being moved by two things at once, and a tween
    -- to a captured target would be heading somewhere that stopped being true.
    local function startCatchUp()
        if catchUpStop then return end
        catchUpStop = addTicker(0, function(dt)
            if closed then
                if catchUpStop then catchUpStop() catchUpStop = nil end
                return
            end
            local gap = lastTarget - (drawnY or lastTarget)
            if math.abs(gap) < 0.5 then
                drawnY = lastTarget
                write()
                if catchUpStop then catchUpStop() catchUpStop = nil end
                return
            end
            -- A share of the remaining distance per second, not per frame, so the slide
            -- takes the same time whatever the frame rate.
            drawnY += gap * (1 - 0.0005 ^ dt)
            write()
        end)
    end

    -- The shield sits over where the panel is drawn, not over where it belongs: while
    -- the panel is sliding onto a new place, a press has to land on the panel the user
    -- can see.
    local function syncShield()
        local size = panel.AbsoluteSize
        local h = (size.Y > 4) and size.Y or (cfg.height or 0)
        shield.Position = UDim2.new(
            resting.X.Scale, resting.X.Offset - SHIELD_MARGIN,
            resting.Y.Scale, drawY() - SHIELD_MARGIN
        )
        shield.Size = UDim2.new(0, width + SHIELD_MARGIN * 2, 0, h + SHIELD_MARGIN * 2)
    end

    local function place()
        if closed then return end
        -- The row this panel belongs to has left the tree, so there is nothing left to
        -- place against. That happens when a panel is opened from inside another one, a
        -- dropdown inside a gear popover being the case that matters, and the host is
        -- closed first: the child used to be left frozen on screen with no way to reach
        -- it, because everything that could have moved or dismissed it was placed
        -- relative to a control that no longer existed.
        if not anchor.Parent then
            closePanel()
            return
        end
        local origin = ctx.window.AbsolutePosition
        local at = anchor.AbsolutePosition
        local size = anchor.AbsoluteSize
        local height = panel.AbsoluteSize.Y
        if height < 4 then height = cfg.height or 0 end
        local x = at.X - origin.X + (cfg.offsetX or 0)
        local below = at.Y - origin.Y + size.Y + gap
        local above = at.Y - origin.Y - gap
        resting, onTop = ctx.fitPanel(x, below, width, height, above)

        -- Two different things can move a panel, and they want opposite treatment.
        --
        -- Following the row it is glued to has to be exact. A panel that lags behind a
        -- scroll by even a few pixels reads as coming loose from the control it belongs
        -- to, so that movement is written straight through.
        --
        -- Running out of room is not following anything. The panel has been put
        -- somewhere else because where it wanted to be is off the screen, or because it
        -- has grown and no longer fits below its row and has to go above it instead.
        -- That is a decision, not a drag, and taking it in one frame is what read as the
        -- panel jumping.
        --
        -- They are told apart by how far the row moved. If the target moved by the same
        -- amount, this is a scroll and it is written through. If it moved by more, the
        -- placement changed its mind and the difference is eased away.
        local anchorY = at.Y
        local target = resting.Y.Offset
        if drawnY == nil then
            -- First placement. Nothing is on screen yet, so there is nothing to be
            -- continuous with.
            drawnY = target
        elseif slideStop then
            -- The panel is arriving or leaving, and the place it belongs is moving under it
            -- while it travels.
            --
            -- It moves because the height is not known when the panel opens. The panel is
            -- auto sized and its content goes in after openPanel has returned, and cfg.height
            -- is a guess: exact for a dropdown, which knows its row count, and a flat 220 for
            -- a gear popover, which cannot know what the caller is about to build. Every
            -- placement that depends on the height then moves once the real one arrives, which
            -- is a panel flipped above its row (above - h) or one pinned to the bottom of the
            -- screen (vp.Y - 8 - h), and the side it lands on can flip outright.
            --
            -- This used to write the new target straight through, on the grounds that easing
            -- it read as the panel shivering. Both are true and both are wrong: a panel mid
            -- slide jumped a few pixels, which is small, sudden, and in the middle of the one
            -- animation the eye is following.
            --
            -- So the difference is folded into the travel instead. The rest of the path is
            -- shifted by exactly the amount that was not the row moving, which leaves the
            -- panel where it is on this frame, and the destination is untouched, so the same
            -- slide carries the correction away and still lands where it should. No second
            -- animation, no shiver, and nothing to interrupt.
            --
            -- Only the part that was not the row moving. A column scrolled while a panel is
            -- still arriving has to be followed exactly, for the reason given below: a panel
            -- that lags a scroll by a few pixels reads as coming loose from its control. So
            -- the two are told apart here the same way they are told apart once the panel has
            -- settled, by comparing how far the target moved with how far the row did.
            local rowMoved = lastAnchorY and (anchorY - lastAnchorY) or 0
            local decided = (target - lastTarget) - rowMoved
            if math.abs(decided) >= 1.5 and slideRebase and slideRebase(-decided) then
                slideOffset -= decided
            end
            drawnY = target
        else
            local rowMoved = lastAnchorY and (anchorY - lastAnchorY) or 0
            local targetMoved = target - lastTarget
            if math.abs(targetMoved - rowMoved) < 1.5 then
                drawnY += targetMoved
            else
                startCatchUp()
            end
        end
        lastTarget = target
        lastAnchorY = anchorY

        write()
        syncShield()
    end

    -- Move the offset and the opacity together on the shared frame driver.
    --
    -- One ticker for both, because they have to agree: a travel that outlasts its
    -- fade leaves the panel sliding after it is already fully drawn, which is the
    -- thing that read as broken everywhere else in this kit. Both start and finish
    -- on the same frame, and both pick up from where they are, so a panel that is
    -- scrolled out and back mid animation does not restart.
    --
    -- The travel eases out on a quint and the opacity on a sine: an overshoot on a
    -- position settles, an overshoot on a transparency clips and flickers.
    -- offsetFrom nil means carry on from wherever the panel currently is.
    local function slide(offsetFrom, offsetTo, alphaTo, duration, onDone)
        if slideStop then
            slideStop()
            slideStop = nil
        end
        if offsetFrom then slideOffset = offsetFrom end
        offsetFrom = slideOffset
        local alphaFrom = alphaNow
        local elapsed = 0

        -- Shift the remaining travel by `shift` pixels and leave its destination alone.
        --
        -- The frame's offset is offsetFrom * (1 - e) + offsetTo * e, so moving offsetFrom by
        -- shift / (1 - e) moves this frame by exactly shift and every later frame by less,
        -- reaching zero at e = 1. The panel therefore does not move on the frame the
        -- correction arrives, and the correction is gone by the time the slide is.
        --
        -- Declined near the end, where 1 - e is small enough that the division would ask the
        -- last frame or two to travel a long way. A correction that late means the panel's
        -- height changed a quarter second after it opened, which is a filter being typed
        -- rather than the content arriving, and that path is the one place() eases anyway.
        slideRebase = function(shift)
            local e = 1 - (1 - math.min(elapsed / duration, 1)) ^ 5
            local room = 1 - e
            if room < 0.05 then return false end
            offsetFrom = offsetFrom + shift / room
            return true
        end

        slideStop = addTicker(0, function(dt)
            if closed then
                if slideStop then slideStop() slideStop = nil end
                slideRebase = nil
                return
            end
            elapsed += dt
            local t = math.min(elapsed / duration, 1)
            slideOffset = offsetFrom + (offsetTo - offsetFrom) * (1 - (1 - t) ^ 5)
            alphaNow = alphaFrom + (alphaTo - alphaFrom) * math.sin(t * math.pi / 2)
            setAlpha(alphaNow)
            place()
            if t >= 1 then
                slideOffset = offsetTo
                alphaNow = alphaTo
                setAlpha(alphaTo)
                -- Cleared before the last place(), so a target that moved on this very frame
                -- is handled by the settled path rather than being rebased into a travel that
                -- is already over.
                slideRebase = nil
                if slideStop then slideStop() slideStop = nil end
                place()
                if onDone then onDone() end
            end
        end)
    end

    -- The panel leaves while its control is scrolled past the top or bottom of the
    -- column, otherwise it floats over the header or over the next card, and it
    -- comes back when the control does.
    --
    -- It leaves the way the row left. Scrolled off the top, the panel goes up after
    -- it; off the bottom, it goes down. A panel that only faded on the spot read as
    -- being switched off, and a panel that always went the same way argued with the
    -- direction of the scroll half the time. The travel is 26 pixels, enough to be
    -- a movement rather than a twitch on a panel that is already going transparent.
    local CLIP_TRAVEL = 26

    -- Where the panel starts its entry, measured from where it belongs.
    --
    -- A panel sitting below its row starts a little higher and settles down, so it reads
    -- as coming out from under the control that opened it. One that has been flipped above
    -- its row for lack of room below has to do the opposite. Starting higher there means
    -- starting further from the control and travelling onto it, which tells the wrong
    -- story and is what read as a panel dropping in from nowhere: the movement argued with
    -- the placement every time a control near the bottom of the screen was used. So the
    -- sign follows the side, and in both cases the panel comes out of its row.
    local ENTER_TRAVEL = 14
    local function entryOffset()
        return onTop and ENTER_TRAVEL or -ENTER_TRAVEL
    end

    local shown = true
    local function clip()
        if closed then return end
        local want, upward = true, true
        if scroller then
            local top = scroller.AbsolutePosition.Y
            local bottom = top + scroller.AbsoluteSize.Y
            local at = anchor.AbsolutePosition.Y
            local above = at + anchor.AbsoluteSize.Y <= top + 2
            local below = at >= bottom - 2
            want = not (above or below)
            -- Remembered rather than recomputed on the way back in: by then the row
            -- is inside the column again and there is no edge left to read.
            if above then upward = true elseif below then upward = false end
        end
        if want == shown then return end
        shown = want
        backdrop.Visible = want
        shield.Visible = want
        if want then
            -- Comes back from the side it left by, so leaving and returning are one
            -- movement reversed rather than two unrelated ones.
            panel.Visible = true
            slide(lastExit or entryOffset(), 0, 1, 0.3)
        else
            lastExit = upward and -CLIP_TRAVEL or CLIP_TRAVEL
            slide(nil, lastExit, 0, 0.22, function()
                if not shown and not closed then panel.Visible = false end
            end)
        end
    end

    local conns = {
        anchor:GetPropertyChangedSignal("AbsolutePosition"):Connect(function()
            place()
            clip()
        end),
        -- Auto sized panels report their real height a frame later, and a search
        -- filter changes it again, so follow the size instead of guessing once.
        panel:GetPropertyChangedSignal("AbsoluteSize"):Connect(place),
    }
    syncShield()

    closePanel = function()
        if closed then return end
        closed = true
        for _, conn in ipairs(conns) do conn:Disconnect() end

        -- Anything opened out of this panel goes with it. A dropdown inside a gear
        -- popover is anchored to a control on the popover, so once the popover is gone
        -- that dropdown can never be placed or dismissed again: it has to be taken down
        -- here, while there is still a way to identify it.
        for i = #stack, 1, -1 do
            local other = stack[i]
            if other ~= controller and not other.closed and other.anchor then
                local node = other.anchor
                while node do
                    if node == panel then
                        other.close()
                        break
                    end
                    node = node.Parent
                end
            end
        end
        -- Marked as well as removed. The controller is created after this function is,
        -- so a close that happens before it exists cannot take itself off the stack,
        -- and a dead controller sitting in the stack is a panel that nothing can place
        -- and nothing can close again.
        if controller then controller.closed = true end
        for i = #stack, 1, -1 do
            if stack[i] == controller then table.remove(stack, i) end
        end
        backdrop:Destroy()
        shield:Destroy()
        -- Guarded, because everything below it has to happen. The callback belongs to
        -- whatever opened the panel and it usually animates that control back: a dropdown
        -- turns its chevron round, a gear turns its cog. If the control has been destroyed
        -- in the meantime that write throws, and an unguarded call took the rest of the
        -- teardown down with it, so the panel was never destroyed and the button that
        -- opened it was left holding a controller that would never close. That button was
        -- then dead for the rest of the session, and clicking quickly is what made the
        -- race likely enough to hit.
        if cfg.onClose then pcall(cfg.onClose) end

        -- The panel sinks back under the control it came out of as it goes. Driven here
        -- rather than through slide(), because the closed flag has already stopped that
        -- driver and it has to stay stopped: it calls place(), and place() reads an anchor
        -- the caller may be tearing down.
        if slideStop then
            slideStop()
            slideStop = nil
        end
        if catchUpStop then
            catchUpStop()
            catchUpStop = nil
        end
        local base = resting
        local fromOffset = slideOffset
        local fromAlpha = alphaNow
        local drawn = drawnY or base.Y.Offset
        -- Back into the row it came out of, which is the entry reversed. A panel above its
        -- row sinks upwards. Sinking down from there would have it move across the control
        -- as it goes, and the last thing a closing panel should do is cover the thing that
        -- closed it.
        local sink = onTop and -8 or 8
        local elapsed = 0
        local stop
        stop = addTicker(0, function(dt)
            elapsed += dt
            local t = math.min(elapsed / 0.14, 1)
            local eased = 1 - (1 - t) ^ 3
            local offset = fromOffset + (sink - fromOffset) * eased
            -- Whole pixels here too, for the same reason write() rounds: the panel is a
            -- CanvasGroup and a fractional offset blurs everything on it.
            panel.Position = UDim2.new(
                base.X.Scale, base.X.Offset,
                base.Y.Scale, math.floor(drawn + offset + 0.5)
            )
            setAlpha(fromAlpha * (1 - eased))
            if t >= 1 then
                if stop then stop() end
                panel:Destroy()
            end
        end)
    end

    controller = {
        frame = panel,
        -- The control the panel came out of. Kept because the panel is placed from it
        -- on every scroll, so anything reasoning about an open panel needs to know
        -- which row it belongs to.
        anchor = anchor,
        close = closePanel,
        popover = cfg.popover == true,
        closed = closed,
    }
    -- Only if it is still open. Closing during the build is unlikely but a closed
    -- controller on the stack would be a panel nothing can reach.
    if not closed then
        stack[#stack + 1] = controller
    end

    -- A press anywhere outside the panel dismisses it, except on the window's title
    -- strip: that starts a window drag and leaves the panel open, so the window can
    -- still be moved with a dropdown or a picker on screen. The panel travels with
    -- it, because it is placed from its anchor and the anchor moves with the window.
    --
    -- On press rather than on click. The catcher covers the whole window, so waiting
    -- for the release meant the drag had already been lost to it.
    backdrop.InputBegan:Connect(function(input)
        if not isPointer(input.UserInputType) then return end
        if ctx.dragWindowFrom and ctx.dragWindowFrom(input) then return end
        closePanel()
    end)

    place()
    clip()
    -- Open: the panel rises the last few pixels into place as it comes up, so it
    -- reads as coming out from under the control it belongs to.
    --
    -- It is the panel's own position that moves and nothing inside it. A UIScale,
    -- which is what this used to be, grows the panel from whichever corner its anchor
    -- point sits on (the top left, so every panel unrolled to the right) and
    -- re-renders the text at a fractional size on every frame, which is what made the
    -- labels crawl while a menu opened.
    --
    -- place() ran just above, so the side the panel landed on is already known and the
    -- entry can travel out of the row rather than always downwards.
    slide(entryOffset(), 0, 1, 0.3)

    return panel, controller
end

-- Control builders. Each builds into a container (a card body or a popover body)
-- and returns the created row. ctx is the window, used for the overlay layer.

local function controlRow(parent, height)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, height)
    row.BackgroundTransparency = 1
    row.LayoutOrder = nextOrder(parent)
    row.Parent = parent
    return row
end

local function rowLabel(row, text, rightInset)
    local label = Instance.new("TextLabel")
    label.BackgroundTransparency = 1
    label.Position = UDim2.new(0, 0, 0, 0)
    label.Size = UDim2.new(1, -(rightInset or 54), 1, 0)
    label.TextSize = 15
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.TextTruncate = Enum.TextTruncate.AtEnd
    label.Parent = row
    faced(label, "medium")
    themed(label, "TextColor3", "text")
    localized(label, "Text", text)
    return label
end

local function makePill(row, ctx, get, set)
    local pill = Instance.new("TextButton")
    pill.AnchorPoint = Vector2.new(1, 0.5)
    pill.Position = UDim2.new(1, 0, 0.5, 0)
    pill.Size = UDim2.new(0, 44, 0, 22)
    pill.AutoButtonColor = false
    pill.Text = ""
    pill.BorderSizePixel = 0
    pill.Parent = row
    -- Deliberately not in the theme registry. Its colour is the accent when it is on and
    -- the track colour when it is off, so a registry that painted it by key would paint an
    -- on toggle the track colour along with every other track coloured thing. It repaints
    -- itself instead, from its own state, on every palette pass.
    pill.BackgroundColor3 = PALETTE.track
    corner(pill, 11)

    -- The knob is painted by render() alone and is deliberately not in the theme
    -- registry. Its colour depends on the state of the toggle, because on the accent
    -- it has to be legible against the accent, and a registry that also writes it
    -- would take turns with render() and leave whichever ran last on screen.
    local knob = Instance.new("Frame")
    knob.Size = UDim2.new(0, 16, 0, 16)
    knob.Position = UDim2.new(0, 3, 0.5, -8)
    knob.BackgroundColor3 = PALETTE.knob
    knob.BorderSizePixel = 0
    knob.Parent = pill
    corner(knob, 8)

    -- Where the pill and the knob should be, given the state. Written straight, no tween:
    -- this runs on every frame of a palette change and a tween per frame would fight
    -- itself.
    local function repaint()
        local on = get() and true or false
        pill.BackgroundColor3 = on and shownColor("accent") or shownColor("track")
        -- The knob sits on the accent once the pill is on, so its colour is picked against
        -- the accent. A white knob on a pale accent has nothing to stand against.
        knob.BackgroundColor3 = on and contrastOn(shownColor("accent")) or shownColor("knob")
    end

    local function render(value)
        tween(pill, 0.2, { BackgroundColor3 = value and PALETTE.accent or PALETTE.track }, EASE_SOFT)
        tween(knob, 0.2, { BackgroundColor3 = value and contrastOn(PALETTE.accent) or PALETTE.knob }, EASE_SOFT)
        -- Back easing gives the knob a small settle at the end of the travel.
        tween(knob, 0.28, { Position = value and UDim2.new(1, -19, 0.5, -8) or UDim2.new(0, 3, 0.5, -8) }, EASE_POP)
    end
    render(get())
    addStatePainter(pill, repaint)
    -- Re-apply on config load, which can change the value under the control without
    -- anything on screen having been touched. The knob has to move, not just recolour.
    if ctx and ctx._refresh then
        table.insert(ctx._refresh, function()
            render(get())
        end)
    end
    -- Hover feedback only where there is something to press.
    --
    -- A toggle built without a setter is a read out of a value the script owns, and it used
    -- to light up under the pointer like any other switch and then do nothing when clicked.
    -- Offering the affordance and refusing the press is worse than not offering it: it reads
    -- as a control that has broken rather than as a value being reported. Card:status is
    -- the row to use for a value like that, and this keeps the toggle honest for the scripts
    -- that already pass a getter on its own.
    if set then
        pill.MouseEnter:Connect(function()
            if not get() then tween(pill, 0.14, { BackgroundColor3 = PALETTE.controlHover }, EASE_SOFT) end
        end)
        pill.MouseLeave:Connect(function()
            if not get() then tween(pill, 0.18, { BackgroundColor3 = PALETTE.track }, EASE_SOFT) end
        end)
    end
    pill.MouseButton1Click:Connect(function()
        -- Without a setter the control is a read out of someone else's value, so
        -- the press is ignored rather than raising. win:flag returns two values
        -- and is truncated to the getter when anything follows it, which is the
        -- usual way a control ends up with no setter.
        if not set then return end
        local value = not get()
        set(value)
        render(value)
    end)
    return pill
end

local function gearIcon(row)
    local btn = newInstance("TextButton")
    btn.AnchorPoint = Vector2.new(1, 0.5)
    btn.Position = UDim2.new(1, -54, 0.5, 0)
    btn.Size = UDim2.new(0, 24, 0, 24)
    btn.BackgroundTransparency = 1
    btn.Text = ""
    btn.Parent = row
    local img = makeIcon(btn, "settings", UDim2.new(1, 0, 1, 0), "iconDim")
    img.Active = false
    -- Fallback drawn cog if the settings icon file is missing.
    if img.Image == "" then
        for i = 0, 2 do
            local tooth = Instance.new("Frame")
            tooth.AnchorPoint = Vector2.new(0.5, 0.5)
            tooth.Position = UDim2.new(0.5, 0, 0.5, 0)
            tooth.Size = UDim2.new(0, 16, 0, 5)
            tooth.Rotation = i * 60
            tooth.BorderSizePixel = 0
            themed(tooth, "BackgroundColor3", "subtext")
            corner(tooth, 2)
            tooth.Parent = btn
        end
        local hole = Instance.new("Frame")
        hole.AnchorPoint = Vector2.new(0.5, 0.5)
        hole.Position = UDim2.new(0.5, 0, 0.5, 0)
        hole.Size = UDim2.new(0, 7, 0, 7)
        hole.BorderSizePixel = 0
        themed(hole, "BackgroundColor3", "card")
        corner(hole, 4)
        hole.Parent = btn
    end
    btn.MouseEnter:Connect(function() tintIcon(img, PALETTE.icon) end)
    btn.MouseLeave:Connect(function() tintIcon(img, PALETTE.iconDim) end)
    return btn, img
end

local Controls = {}

-- Forward declaration so popovers can host the same controls via a Card.
local Card

function Controls.label(parent, text)
    local row = controlRow(parent, 18)
    row.AutomaticSize = Enum.AutomaticSize.Y
    local label = Instance.new("TextLabel")
    label.BackgroundTransparency = 1
    label.Size = UDim2.new(1, 0, 0, 0)
    label.AutomaticSize = Enum.AutomaticSize.Y
    label.TextWrapped = true
    -- A bold face needs a little more room than a light one before the stems of
    -- adjacent letters start closing up, so the running text in the kit sits a
    -- point above where it would with a regular weight.
    label.TextSize = 14
    -- And it needs the lines pushed apart. Roblox leaves wrapped lines at the
    -- font's own em height, which on a bold face is close enough that the
    -- descenders of one line sit on the ascenders of the next and a paragraph
    -- reads as a single grey block.
    label.LineHeight = 1.22
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.TextYAlignment = Enum.TextYAlignment.Top
    label.Parent = row
    faced(label, "regular")
    themed(label, "TextColor3", "subtext")
    local setPhrase = localized(label, "Text", text)
    return row, setPhrase
end

-- A caption that splits a long card into groups. Text only: a coloured tick in
-- front of a heading is noise once every card already sits on its own surface.
function Controls.section(parent, text)
    local row = controlRow(parent, 16)
    local label = Instance.new("TextLabel")
    label.BackgroundTransparency = 1
    label.Size = UDim2.new(1, 0, 1, 0)
    label.TextSize = 12
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.TextYAlignment = Enum.TextYAlignment.Bottom
    label.Parent = row
    faced(label, "semibold")
    themed(label, "TextColor3", "subtext")
    localized(label, "Text", text, string.upper)
    return row
end

function Controls.toggle(parent, ctx, text, get, set, buildSettings)
    local row = controlRow(parent, 30)
    rowLabel(row, text, buildSettings and 84 or 54)
    makePill(row, ctx, get, set)

    if buildSettings then
        local gear, gearImg = gearIcon(row)
        local opened = nil
        gear.MouseButton1Click:Connect(function()
            -- Second click on the gear closes the popover it opened. The handle is dropped
            -- here, not when the panel reports back, so a dead one cannot wedge the gear.
            if opened then
                local previous = opened
                opened = nil
                if not previous.closed then previous.close() end
                return
            end
            if ctx.closeOverlays then ctx.closeOverlays() end
            local panel, controller = openPanel(ctx, {
                anchor = gear,
                width = 270,
                height = 220,
                offsetX = -230,
                popover = true,
                radius = 10,
                onClose = function()
                    opened = nil
                    tween(gearImg, 0.25, { Rotation = 0 })
                end,
            })
            opened = controller

            local body = newInstance("Frame")
            body.Name = randomName()
            body.BackgroundTransparency = 1
            body.Size = UDim2.new(1, 0, 0, 0)
            body.AutomaticSize = Enum.AutomaticSize.Y
            body.Parent = panel
            listLayout(body, 8)
            padding(body, 12)

            local title = newInstance("TextLabel")
            title.BackgroundTransparency = 1
            title.Size = UDim2.new(1, 0, 0, 18)
            title.TextSize = 15
            title.TextXAlignment = Enum.TextXAlignment.Left
            title.LayoutOrder = nextOrder(body)
            title.Parent = body
            faced(title, "semibold")
            themed(title, "TextColor3", "text")
            localized(title, "Text", text, function(value)
                return value .. " " .. translate("Settings")
            end)
            buildSettings(Card.new(body, ctx))
            tween(gearImg, 0.25, { Rotation = 90 })
        end)
    end
    return row
end

function Controls.button(parent, ctx, text, onClick)
    local row = controlRow(parent, 34)
    local button = newInstance("TextButton")
    button.Size = UDim2.new(1, 0, 1, 0)
    button.BorderSizePixel = 0
    button.AutoButtonColor = false
    button.TextSize = 14
    button.TextTruncate = Enum.TextTruncate.AtEnd
    button.Parent = row
    faced(button, "medium")
    themed(button, "BackgroundColor3", "control")
    themed(button, "TextColor3", "text")
    localized(button, "Text", text)
    corner(button, 8)
    padding(button, nil, { left = 10, right = 10 })

    hoverSurface(button)
    button.MouseButton1Click:Connect(function()
        if onClick then onClick() end
    end)
    return row
end

function Controls.input(parent, ctx, text, placeholder, get, set)
    local row = controlRow(parent, 30)
    rowLabel(row, text, 150)
    local box = Instance.new("TextBox")
    box.AnchorPoint = Vector2.new(1, 0.5)
    box.Position = UDim2.new(1, 0, 0.5, 0)
    box.Size = UDim2.new(0, 140, 0, 26)
    box.BorderSizePixel = 0
    box.TextSize = 14
    box.Text = (get and get()) or ""
    box.ClearTextOnFocus = false
    box.TextXAlignment = Enum.TextXAlignment.Left
    box.TextTruncate = Enum.TextTruncate.AtEnd
    box.Parent = row
    faced(box, "regular")
    themed(box, "BackgroundColor3", "control")
    themed(box, "TextColor3", "text")
    themed(box, "PlaceholderColor3", "subtext")
    localized(box, "PlaceholderText", placeholder or "")
    corner(box, 6)
    padding(box, nil, { left = 10, right = 10 })
    -- Focus is shown by lifting the fill, not by drawing a ring. A ring around a
    -- field that already has an edge is one border too many, and it draws attention
    -- to the box at the moment the attention should be on what is being typed.
    box.Focused:Connect(function()
        tween(box, 0.16, { BackgroundColor3 = PALETTE.controlHover }, EASE_SOFT)
    end)
    box.FocusLost:Connect(function()
        tween(box, 0.2, { BackgroundColor3 = PALETTE.control }, EASE_SOFT)
        if set then set(box.Text) end
    end)
    if ctx and ctx._refresh then table.insert(ctx._refresh, function() box.Text = (get and tostring(get() or "")) or "" end) end
    return row
end

function Controls.slider(parent, ctx, text, min, max, get, set, decimals, format)
    local row = controlRow(parent, 44)
    local label = Instance.new("TextLabel")
    label.BackgroundTransparency = 1
    label.Position = UDim2.new(0, 0, 0, 0)
    label.Size = UDim2.new(1, -60, 0, 20)
    label.TextSize = 14
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.TextTruncate = Enum.TextTruncate.AtEnd
    label.Parent = row
    faced(label, "medium")
    themed(label, "TextColor3", "text")
    localized(label, "Text", text)

    local valueBox = Instance.new("TextBox")
    valueBox.AnchorPoint = Vector2.new(1, 0)
    valueBox.Position = UDim2.new(1, 0, 0, 0)
    valueBox.Size = UDim2.new(0, 54, 0, 21)
    valueBox.BorderSizePixel = 0
    valueBox.TextSize = 14
    valueBox.Text = "0"
    valueBox.ClearTextOnFocus = false
    valueBox.TextXAlignment = Enum.TextXAlignment.Center
    valueBox.Parent = row
    faced(valueBox, "medium")
    themed(valueBox, "BackgroundColor3", "control")
    themed(valueBox, "TextColor3", "text")
    corner(valueBox, 5)
    valueBox.Focused:Connect(function() tween(valueBox, 0.16, { BackgroundColor3 = PALETTE.controlHover }, EASE_SOFT) end)

    local track = Instance.new("TextButton")
    track.AnchorPoint = Vector2.new(0, 1)
    track.Position = UDim2.new(0, 0, 1, -4)
    track.Size = UDim2.new(1, 0, 0, 6)
    track.BorderSizePixel = 0
    track.AutoButtonColor = false
    track.Text = ""
    track.Parent = row
    themed(track, "BackgroundColor3", "track")
    corner(track, 3)

    local fill = Instance.new("Frame")
    fill.BorderSizePixel = 0
    fill.Parent = track
    corner(fill, 3)
    -- Paints the fill as well as shading it, so the accent is written in one place.
    barRamp(fill)

    local knob = Instance.new("Frame")
    knob.AnchorPoint = Vector2.new(0.5, 0.5)
    knob.Size = UDim2.new(0, 12, 0, 12)
    knob.BorderSizePixel = 0
    knob.ZIndex = 2
    knob.Parent = track
    themed(knob, "BackgroundColor3", "knob")
    corner(knob, 6)

    local function clampValue(value)
        if decimals and decimals > 0 then
            local mult = 10 ^ decimals
            return math.floor(value * mult + 0.5) / mult
        end
        return math.floor(value + 0.5)
    end
    -- While dragging the fill follows the pointer with no easing, every other
    -- change (typed value, config load, another script writing the flag) slides
    -- into place so the bar never jumps.
    local function render(value, instant)
        local ratio = (max > min) and math.clamp((value - min) / (max - min), 0, 1) or 0
        if instant then
            fill.Size = UDim2.new(ratio, 0, 1, 0)
            knob.Position = UDim2.new(ratio, 0, 0.5, 0)
        else
            tween(fill, 0.22, { Size = UDim2.new(ratio, 0, 1, 0) }, EASE_SOFT)
            tween(knob, 0.22, { Position = UDim2.new(ratio, 0, 0.5, 0) }, EASE_SOFT)
        end
        valueBox.Text = format and format(value) or tostring(value)
    end
    render(get(), true)

    -- The value box accepts a typed number (clamped to range).
    valueBox.FocusLost:Connect(function()
        tween(valueBox, 0.2, { BackgroundColor3 = PALETTE.control }, EASE_SOFT)
        local typed = set and tonumber(string.match(valueBox.Text, "[%-%d%.]+"))
        if typed then
            local value = math.clamp(clampValue(typed), min, max)
            set(value)
            render(value)
        else
            render(get())
        end
    end)

    local dragging = false
    local function setFromX(x)
        if not set then return end
        local ratio = math.clamp((x - track.AbsolutePosition.X) / math.max(track.AbsoluteSize.X, 1), 0, 1)
        local value = clampValue(min + ratio * (max - min))
        set(value)
        render(value, true)
    end
    -- The pointer is taken over by the shared drag controller, so the slider does
    -- not keep its own connection on InputChanged.
    track.InputBegan:Connect(function(input)
        if not isPointer(input.UserInputType) then return end
        dragging = true
        tween(knob, 0.12, { Size = UDim2.new(0, 16, 0, 16) }, EASE_POP)
        tween(track, 0.14, { Size = UDim2.new(1, 0, 0, 8) }, EASE_SOFT)
        setFromX(input.Position.X)
        beginDrag({
            move = setFromX,
            stop = function()
                dragging = false
                tween(knob, 0.18, { Size = UDim2.new(0, 12, 0, 12) }, EASE_SOFT)
                tween(track, 0.2, { Size = UDim2.new(1, 0, 0, 6) }, EASE_SOFT)
            end,
        })
    end)
    track.MouseEnter:Connect(function()
        if not dragging then tween(knob, 0.14, { Size = UDim2.new(0, 14, 0, 14) }, EASE_SOFT) end
    end)
    track.MouseLeave:Connect(function()
        if not dragging then tween(knob, 0.18, { Size = UDim2.new(0, 12, 0, 12) }, EASE_SOFT) end
    end)
    if ctx and ctx._refresh then table.insert(ctx._refresh, function() render(get()) end) end
    return row
end

function Controls.keybind(parent, ctx, text, getKey, setKey, opts)
    opts = opts or {}
    local multi = opts.multi
    local row = controlRow(parent, 30)
    -- The field is wide enough for the longest name it can hold. "MouseButton2" at
    -- the control text size fills 116 pixels once the clear button has taken its
    -- corner, and a bind that shows as "MouseButt.." is worse than a wider field.
    rowLabel(row, text, 158)
    local kbIcon = makeIcon(row, "keyboard", UDim2.new(0, 22, 0, 22), "iconDim")
    kbIcon.AnchorPoint = Vector2.new(1, 0.5)
    kbIcon.Position = UDim2.new(1, -134, 0.5, 0)
    local button = Instance.new("TextButton")
    button.AnchorPoint = Vector2.new(1, 0.5)
    button.Position = UDim2.new(1, 0, 0.5, 0)
    button.Size = UDim2.new(0, 124, 0, 24)
    button.BorderSizePixel = 0
    button.AutoButtonColor = false
    button.TextSize = 14
    button.TextTruncate = Enum.TextTruncate.AtEnd
    button.Parent = row
    faced(button, "medium")
    themed(button, "BackgroundColor3", "control")
    themed(button, "TextColor3", "text", { fade = false })
    corner(button, 6)
    -- Capture is shown by the accent coloured dots in the field, not by a ring
    -- around it. Same reasoning as a focused text field: the row already has an
    -- edge, and a second one reads as a defect rather than as a state.

    -- A visible clear button (tap to remove the bind) for users who do not know
    -- the right click shortcut and players on mobile / console. Uses the x icon.
    local clearBtn = Instance.new("TextButton")
    clearBtn.Name = "Clear"
    clearBtn.AnchorPoint = Vector2.new(1, 0.5)
    clearBtn.Position = UDim2.new(1, -5, 0.5, 0)
    clearBtn.Size = UDim2.new(0, 16, 0, 16)
    clearBtn.BackgroundTransparency = 1
    clearBtn.Text = ""
    clearBtn.AutoButtonColor = false
    clearBtn.ZIndex = 4
    clearBtn.Visible = false
    clearBtn.Parent = button
    local clearImg = makeIcon(clearBtn, "x", UDim2.new(1, 0, 1, 0), "iconDim")
    clearImg.Active = false

    -- Normalise the stored value into a list of key names.
    local function keyList()
        local v = getKey()
        if multi then
            if type(v) == "table" then return v end
            return {}
        else
            if v == nil or v == "" or v == "None" then return {} end
            return { tostring(v) }
        end
    end
    local function display()
        local list = keyList()
        if #list == 0 then return translate("None") end
        return table.concat(list, " + ")
    end
    local function commit(list)
        if not setKey then return end
        if multi then
            setKey(list)
        else
            setKey(list[1])
        end
        button.Text = display()
        clearBtn.Visible = #list > 0
    end
    button.Text = display()
    clearBtn.Visible = #keyList() > 0
    local function stopCapture()
        tween(button, 0.18, { TextColor3 = PALETTE.text }, EASE_SOFT)
    end
    clearBtn.MouseButton1Click:Connect(function()
        commit({})
        stopCapture()
        tween(button, 0.14, { BackgroundColor3 = PALETTE.control }, EASE_SOFT)
    end)
    clearBtn.MouseEnter:Connect(function() tintIcon(clearImg, PALETTE.accent) end)
    clearBtn.MouseLeave:Connect(function() tintIcon(clearImg, PALETTE.iconDim) end)

    local capturing = false
    -- Timestamp of the last successful capture, so the right-click that binds a
    -- mouse button is not immediately treated as a right-click clear.
    local lastBind = 0
    -- Mouse buttons can be bound too (aim on right click, side buttons, etc.).
    local function mouseName(it)
        if it == Enum.UserInputType.MouseButton1 then return "MouseButton1" end
        if it == Enum.UserInputType.MouseButton2 then return "MouseButton2" end
        if it == Enum.UserInputType.MouseButton3 then return "MouseButton3" end
        return nil
    end
    button.MouseEnter:Connect(function()
        if not capturing then tween(button, 0.14, { BackgroundColor3 = PALETTE.controlHover }, EASE_SOFT) end
    end)
    button.MouseLeave:Connect(function()
        if not capturing then tween(button, 0.18, { BackgroundColor3 = PALETTE.control }, EASE_SOFT) end
    end)
    -- Left click: start capturing the next key or mouse button.
    button.MouseButton1Click:Connect(function()
        capturing = true
        button.Text = "..."
        tween(button, 0.16, { TextColor3 = PALETTE.accent }, EASE_SOFT)
    end)
    -- Right click clears the bind, unless a mouse button was just captured (the
    -- capturing right-click is handled by InputBegan, so ignore its release here).
    button.MouseButton2Click:Connect(function()
        if capturing then return end
        if os.clock() - lastBind < 0.3 then return end
        commit({})
        stopCapture()
        tween(button, 0.14, { BackgroundColor3 = PALETTE.control }, EASE_SOFT)
    end)
    -- One shared InputBegan feeds every keybind, so a script with fifty binds
    -- still has a single connection on the service.
    local stopKeys = onKey(function(input, gpe)
        if capturing then
            local mn = mouseName(input.UserInputType)
            if input.UserInputType == Enum.UserInputType.Keyboard then
                capturing = false
                lastBind = os.clock()
                stopCapture()
                local name = input.KeyCode.Name
                if name == "Escape" or name == "Backspace" or name == "Delete" then
                    commit({})
                    return
                end
                if multi then
                    local list = keyList()
                    local has = false
                    for _, v in ipairs(list) do if v == name then has = true end end
                    if not has then table.insert(list, name) end
                    commit(list)
                else
                    commit({ name })
                end
                return
            elseif mn and mn ~= "MouseButton1" then
                -- MouseButton1 is reserved for clicking the button itself.
                capturing = false
                lastBind = os.clock()
                stopCapture()
                if multi then
                    local list = keyList()
                    local has = false
                    for _, v in ipairs(list) do if v == mn then has = true end end
                    if not has then table.insert(list, mn) end
                    commit(list)
                else
                    commit({ mn })
                end
                return
            end
        end
        -- Fire the callback when a bound key or mouse button is pressed.
        if not capturing and not gpe and opts.callback then
            local pressed = (input.UserInputType == Enum.UserInputType.Keyboard) and input.KeyCode.Name or mouseName(input.UserInputType)
            if pressed then
                for _, v in ipairs(keyList()) do
                    if v == pressed then
                        opts.callback(pressed)
                        break
                    end
                end
            end
        end
    end)
    if ctx and ctx._conns then table.insert(ctx._conns, stopKeys) end
    if ctx and ctx._refresh then table.insert(ctx._refresh, function() button.Text = display(); clearBtn.Visible = #keyList() > 0 end) end
    -- Register the bind so the keybind panel can list it.
    if ctx and ctx._binds and opts.list ~= false then
        table.insert(ctx._binds, {
            label = opts.listName or text,
            keys = keyList,
            active = opts.active,
        })
    end
    return row
end

function Controls.dropdown(parent, ctx, text, options, get, set, opts)
    opts = opts or {}
    local multi = opts.multi
    -- options may be a list or a function returning a list (for dynamic lists).
    local function getOptions()
        local list = (type(options) == "function") and options() or options
        return type(list) == "table" and list or {}
    end
    local row = controlRow(parent, 30)
    rowLabel(row, text, 150)

    local button = Instance.new("TextButton")
    button.AnchorPoint = Vector2.new(1, 0.5)
    button.Position = UDim2.new(1, 0, 0.5, 0)
    button.Size = UDim2.new(0, 140, 0, 26)
    button.BorderSizePixel = 0
    button.AutoButtonColor = false
    button.TextSize = 14
    button.TextXAlignment = Enum.TextXAlignment.Left
    button.TextTruncate = Enum.TextTruncate.AtEnd
    button.Parent = row
    faced(button, "regular")
    themed(button, "BackgroundColor3", "control")
    themed(button, "TextColor3", "text")
    corner(button, 6)
    padding(button, nil, { left = 10, right = 24 })

    local arrow = makeIcon(row, "chevron-down", UDim2.new(0, 18, 0, 18), "iconDim")
    arrow.AnchorPoint = Vector2.new(1, 0.5)
    arrow.Position = UDim2.new(1, -8, 0.5, 0)
    hoverSurface(button)

    local selected = {}
    if multi then
        if type(get()) == "table" then
            for _, v in ipairs(get()) do selected[v] = true end
        end
    end
    -- The stored value is always the option as the script wrote it; only what is
    -- drawn goes through the phrase table, so a translated build still hands the
    -- script back the identifier it knows.
    local function labelText()
        if multi then
            local list = {}
            for _, opt in ipairs(getOptions()) do
                if selected[opt] then table.insert(list, translate(tostring(opt))) end
            end
            return #list == 0 and translate("None") or table.concat(list, ", ")
        end
        return translate(tostring(get()))
    end
    button.Text = labelText()
    if ctx and ctx._refresh then
        table.insert(ctx._refresh, function()
            if multi then
                selected = {}
                if type(get()) == "table" then
                    for _, v in ipairs(get()) do selected[v] = true end
                end
            end
            button.Text = labelText()
        end)
    end

    -- Rows are 32 high with 3 of spacing, the body pads 6 top and bottom, and it
    -- stops growing at seven rows and starts scrolling instead.
    local ROW_STEP = 35
    local MAX_ROWS = 7
    -- Height of the search header. Declared here rather than where it is built, because the
    -- panel's first height is worked out before the field exists. Two copies of the number is
    -- how the guess drifts away from the real height, and a guess that is wrong is a panel
    -- that corrects itself part way through opening.
    local SEARCH_BLOCK = 36
    -- Passed to openPanel rather than left to its default, because the search header needs the
    -- same number on the client where it has to round its own corners. One name instead of the
    -- same literal in two places that must agree.
    local PANEL_RADIUS = 10
    local opened = nil

    button.MouseButton1Click:Connect(function()
        -- The handle is dropped here rather than waiting for the panel to report that it
        -- closed. A controller that is already closed must not be able to wedge the button
        -- shut: if the only thing that clears it is the panel's own callback, anything that
        -- stops that callback running leaves this button holding a dead handle and doing
        -- nothing forever.
        if opened then
            local previous = opened
            opened = nil
            if not previous.closed then previous.close() end
            return
        end
        -- Keep a gear popover open: a dropdown inside it is a child, not a rival.
        if ctx.closeOverlays then ctx.closeOverlays(true) end

        local list = getOptions()
        local guess = math.clamp(#list, 1, MAX_ROWS) * ROW_STEP + 12 + (opts.search and SEARCH_BLOCK or 0)
        local panel, controller = openPanel(ctx, {
            anchor = button,
            width = 210,
            height = guess,
            offsetX = -70,
            radius = PANEL_RADIUS,
            onClose = function()
                opened = nil
                tween(arrow, 0.25, { Rotation = 0 })
            end,
        })
        opened = controller
        tween(arrow, 0.25, { Rotation = 180 })
        listLayout(panel, 0)

        -- Search fills the top of the panel: full width, flush with the top edge, no inset and
        -- no rounding of its own.
        --
        -- Its top corners are cut by the panel's own corner mask. The panel is a CanvasGroup,
        -- so it rasterises its children and the UICorner masks the raster, which is the same
        -- mechanism the chequer grid behind a colour swatch uses. That is what lets a square
        -- header sit in a rounded panel and come out rounded at the top and straight at the
        -- bottom, which no UICorner can do on its own.
        --
        -- It was inset for a while, six pixels at the sides and three at the top, on the
        -- theory that it should look like every other field in the kit. It should not. A field
        -- inside a card is a control among controls and wants an inset; this one is the header
        -- of the thing it sits on, and inset it read as a control that had been dropped into
        -- the panel and left a strip of panel showing around it.
        --
        -- The fallback matters here. newGroup hands back a plain Frame on a client with no
        -- CanvasGroup, and a Frame does not mask anything, so a flush header there would show
        -- square corners poking out of a rounded panel. On that client the header takes its own
        -- rounding instead: both corners round rather than only the top two, which is a small
        -- oddity on a degraded client and not a defect on every other one.
        local searchBox
        if opts.search then
            local head = newInstance("Frame")
            head.Name = randomName()
            head.Size = UDim2.new(1, 0, 0, SEARCH_BLOCK)
            head.Position = UDim2.new(0, 0, 0, 0)
            head.BorderSizePixel = 0
            head.LayoutOrder = 0
            head.Parent = panel
            themed(head, "BackgroundColor3", "control")
            if panel.ClassName ~= "CanvasGroup" then
                corner(head, PANEL_RADIUS)
            end

            local sicon = makeIcon(head, "search", UDim2.new(0, 15, 0, 15), "iconDim")
            sicon.AnchorPoint = Vector2.new(0, 0.5)
            sicon.Position = UDim2.new(0, 12, 0.5, 0)
            searchBox = newInstance("TextBox")
            searchBox.BackgroundTransparency = 1
            searchBox.Position = UDim2.new(0, 34, 0, 0)
            searchBox.Size = UDim2.new(1, -46, 1, 0)
            searchBox.TextSize = 14
            searchBox.Text = ""
            searchBox.ClearTextOnFocus = false
            searchBox.TextXAlignment = Enum.TextXAlignment.Left
            searchBox.Parent = head
            faced(searchBox, "regular")
            themed(searchBox, "TextColor3", "text")
            themed(searchBox, "PlaceholderColor3", "subtext")
            localized(searchBox, "PlaceholderText", "Search..")
        end

        -- The list scrolls on its own. A long list then stays inside the panel,
        -- and the wheel over the list moves the list instead of the card column
        -- underneath it.
        local body = newInstance("ScrollingFrame")
        body.Name = randomName()
        body.BackgroundTransparency = 1
        body.BorderSizePixel = 0
        body.Size = UDim2.new(1, 0, 0, 0)
        body.CanvasSize = UDim2.new(0, 0, 0, 0)
        body.AutomaticCanvasSize = Enum.AutomaticSize.Y
        body.ScrollingDirection = Enum.ScrollingDirection.Y
        body.ScrollBarThickness = 3
        body.ScrollBarImageTransparency = 0.4
        body.LayoutOrder = 1
        body.Parent = panel
        themed(body, "ScrollBarImageColor3", "subtext")
        listLayout(body, 3)
        padding(body, 6)

        local optRows = {}
        local function fitBody()
            local shown = 0
            for _, refs in pairs(optRows) do
                if refs.btn.Visible then shown += 1 end
            end
            shown = math.clamp(shown, 1, MAX_ROWS)
            body.Size = UDim2.new(1, 0, 0, shown * ROW_STEP + 12)
        end

        local function paint(refs, opt)
            local on = (multi and selected[opt] and true) or ((not multi) and tostring(get()) == tostring(opt))
            refs.on = on
            refs.btn.BackgroundColor3 = PALETTE.controlHover
            tween(refs.btn, 0.14, { BackgroundTransparency = on and 0 or 1 }, EASE_SOFT)
            tween(refs.label, 0.14, { TextColor3 = on and PALETTE.accentSoft or PALETTE.text }, EASE_SOFT)
            if refs.tick then
                tween(refs.tick, 0.16, { ImageTransparency = on and 0 or 1 }, EASE_SOFT)
            end
        end

        for _, opt in ipairs(list) do
            local optBtn = newInstance("TextButton")
            optBtn.Name = randomName()
            optBtn.Size = UDim2.new(1, 0, 0, 32)
            optBtn.BackgroundTransparency = 1
            optBtn.BorderSizePixel = 0
            optBtn.AutoButtonColor = false
            optBtn.Text = ""
            optBtn.LayoutOrder = nextOrder(body)
            optBtn.Parent = body
            themed(optBtn, "BackgroundColor3", "controlHover", { fade = false })
            corner(optBtn, 8)

            local optLabel = newInstance("TextLabel")
            optLabel.BackgroundTransparency = 1
            optLabel.Position = UDim2.new(0, 14, 0, 0)
            optLabel.Size = UDim2.new(1, -46, 1, 0)
            optLabel.TextSize = 14
            optLabel.TextXAlignment = Enum.TextXAlignment.Left
            optLabel.TextTruncate = Enum.TextTruncate.AtEnd
            optLabel.ZIndex = 2
            optLabel.Parent = optBtn
            faced(optLabel, "medium")
            localized(optLabel, "Text", tostring(opt))

            -- A tick on the right of a picked row, so a multi select reads at a
            -- glance without counting highlighted rows.
            local tick = makeIcon(optBtn, "check", UDim2.new(0, 16, 0, 16), "accentSoft")
            tick.AnchorPoint = Vector2.new(1, 0.5)
            tick.Position = UDim2.new(1, -12, 0.5, 0)
            tick.ImageTransparency = 1
            tick.ZIndex = 2
            tick.Active = false

            local refs = { btn = optBtn, label = optLabel, tick = tick.Image ~= "" and tick or nil, on = false }
            optRows[opt] = refs
            paint(refs, opt)
            optBtn.MouseEnter:Connect(function()
                if not refs.on then tween(optBtn, 0.12, { BackgroundTransparency = 0.5 }, EASE_SOFT) end
            end)
            optBtn.MouseLeave:Connect(function()
                if not refs.on then tween(optBtn, 0.16, { BackgroundTransparency = 1 }, EASE_SOFT) end
            end)
            optBtn.MouseButton1Click:Connect(function()
                if not set then
                    if opened then opened.close() end
                    return
                end
                if multi then
                    selected[opt] = not selected[opt] or nil
                    paint(refs, opt)
                    local picked = {}
                    for _, o in ipairs(getOptions()) do if selected[o] then table.insert(picked, o) end end
                    set(picked)
                    button.Text = labelText()
                else
                    set(opt)
                    button.Text = labelText()
                    if opened then opened.close() end
                end
            end)
        end
        fitBody()

        -- A picked row's label wears the accent, so it is not in the registry under a key
        -- of its own and a palette pass would leave it on the accent it was opened with.
        -- The panel is short lived, so this only shows when the theme is changed while a
        -- list is open, which is exactly what the theme card is: a dropdown of presets
        -- sitting open over the interface it is repainting.
        addStatePainter(panel, function()
            for _, refs in pairs(optRows) do
                if refs.label.Parent then
                    refs.label.TextColor3 = refs.on and shownColor("accentSoft") or shownColor("text")
                end
            end
        end)

        if searchBox then
            searchBox:GetPropertyChangedSignal("Text"):Connect(function()
                local q = searchBox.Text:lower()
                for opt, refs in pairs(optRows) do
                    local shown = tostring(opt):lower()
                    local drawn = refs.label.Text:lower()
                    refs.btn.Visible = q == "" or shown:find(q, 1, true) ~= nil or drawn:find(q, 1, true) ~= nil
                end
                fitBody()
            end)
        end
    end)
    return row
end

function Controls.colorpicker(parent, ctx, text, getRgb, setRgb, opts)
    local row = controlRow(parent, 30)
    rowLabel(row, text, 120)
    -- Alpha (opacity) is shown by default; pass opts.alpha = false to hide it on a
    -- picker whose consumer ignores the 4th value. When shown, the value is
    -- { r, g, b, a } with a in 0..1 (scripts reading r, g, b still work).
    local useAlpha = not (opts and opts.alpha == false)
    local alpha = useAlpha and ((getRgb() or {})[4] or 1) or 1

    local function hexOf(rgb)
        return string.format("#%02X%02X%02X", rgb[1] or 0, rgb[2] or 0, rgb[3] or 0)
    end

    local pipette = Instance.new("TextButton")
    pipette.AnchorPoint = Vector2.new(1, 0.5)
    pipette.Position = UDim2.new(1, 0, 0.5, 0)
    pipette.Size = UDim2.new(0, 24, 0, 24)
    pipette.BackgroundTransparency = 1
    pipette.AutoButtonColor = false
    pipette.Text = ""
    pipette.Parent = row
    local palImg = makeIcon(pipette, "palette", UDim2.new(1, 0, 1, 0), "iconDim")
    palImg.Active = false

    local hexLabel = Instance.new("TextLabel")
    hexLabel.AnchorPoint = Vector2.new(1, 0.5)
    hexLabel.Position = UDim2.new(1, -30, 0.5, 0)
    hexLabel.Size = UDim2.new(0, 72, 0, 20)
    hexLabel.BackgroundTransparency = 1
    hexLabel.TextSize = 14
    hexLabel.TextXAlignment = Enum.TextXAlignment.Right
    hexLabel.Text = hexOf(getRgb())
    hexLabel.Parent = row
    faced(hexLabel, "medium")
    themed(hexLabel, "TextColor3", "subtext")

    -- Round swatch with the opacity grid under it, so a colour at 30% reads as a
    -- colour at 30% rather than as a darker shade of itself.
    local swatch = Instance.new("TextButton")
    swatch.AnchorPoint = Vector2.new(1, 0.5)
    swatch.Position = UDim2.new(1, -108, 0.5, 0)
    swatch.Size = UDim2.new(0, 18, 0, 18)
    swatch.BackgroundTransparency = 1
    swatch.BorderSizePixel = 0
    swatch.AutoButtonColor = false
    swatch.Text = ""
    swatch.Active = false
    swatch.Parent = row
    corner(swatch, 9)
    stroke(swatch, "stroke", 1, 0.2)
    -- Every layer carries the same rounding. A UICorner only rounds the element it
    -- is on, so a square child inside a rounded parent shows its own corners
    -- straight through the curve.
    if useAlpha then checkerboard(swatch, 5, 0, 9) end
    local swatchFill = Instance.new("Frame")
    swatchFill.Size = UDim2.new(1, 0, 1, 0)
    swatchFill.BackgroundColor3 = colorOf(getRgb())
    swatchFill.BackgroundTransparency = useAlpha and (1 - alpha) or 0
    swatchFill.BorderSizePixel = 0
    swatchFill.ZIndex = 2
    swatchFill.Parent = swatch
    corner(swatchFill, 9)

    local opened = nil
    local h, s, v = colorOf(getRgb()):ToHSV()
    local function openPicker()
        -- Second click on the palette icon closes the picker it opened. The handle is
        -- dropped here, not when the panel reports back, so a dead one cannot wedge it.
        if opened then
            local previous = opened
            opened = nil
            if not previous.closed then previous.close() end
            return
        end
        if ctx.closeOverlays then ctx.closeOverlays(true) end

        -- The layout is fixed, so the height is worked out rather than measured. Top:
        -- the saturation square and the hue bar, then the opacity bar under them.
        -- Bottom, stacked upward from the hex field: the recent colours, if there are
        -- any. The panel is shorter until there are, and grows when the first one is
        -- recorded, so an untouched picker has no empty strip in it waiting to be filled.
        local ROW_H, ROW_GAP, HEX_H = 22, 8, 28
        local top = 138 + (useAlpha and 28 or 0)
        local recentY = HEX_H + ROW_GAP
        local shortH = 24 + top + 14 + HEX_H
        local tallH = shortH + ROW_GAP + ROW_H
        local hadRecent = #recentColors > 0
        local panelH = hadRecent and tallH or shortH

        local panel, controller = openPanel(ctx, {
            anchor = swatch,
            width = 232,
            height = panelH,
            offsetX = -190,
            onClose = function() opened = nil end,
        })
        opened = controller
        -- The picker is a fixed layout, so it does not grow with its content the
        -- way a dropdown list does.
        panel.AutomaticSize = Enum.AutomaticSize.None
        panel.Size = UDim2.new(0, 232, 0, panelH)
        padding(panel, 12)

        local sv = Instance.new("ImageButton")
        sv.Size = UDim2.new(1, -32, 0, 138)
        sv.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
        sv.AutoButtonColor = false
        sv.BorderSizePixel = 0
        sv.Parent = panel
        corner(sv, 4)
        local satGrad = Instance.new("Frame")
        satGrad.Size = UDim2.new(1, 0, 1, 0)
        satGrad.BackgroundColor3 = Color3.new(1, 1, 1)
        satGrad.BorderSizePixel = 0
        satGrad.Parent = sv
        corner(satGrad, 4)
        local g1 = Instance.new("UIGradient")
        g1.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 1) })
        g1.Parent = satGrad
        local valGrad = Instance.new("Frame")
        valGrad.Size = UDim2.new(1, 0, 1, 0)
        valGrad.BackgroundColor3 = Color3.new(0, 0, 0)
        valGrad.BorderSizePixel = 0
        valGrad.Parent = sv
        corner(valGrad, 4)
        local g2 = Instance.new("UIGradient")
        g2.Rotation = 90
        g2.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(1, 0) })
        g2.Parent = valGrad

        local hue = Instance.new("ImageButton")
        hue.AnchorPoint = Vector2.new(1, 0)
        hue.Position = UDim2.new(1, 0, 0, 0)
        hue.Size = UDim2.new(0, 22, 0, 138)
        hue.AutoButtonColor = false
        hue.BorderSizePixel = 0
        hue.Parent = panel
        corner(hue, 4)
        local hueGrad = Instance.new("UIGradient")
        hueGrad.Rotation = 90
        hueGrad.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromHSV(0, 1, 1)),
            ColorSequenceKeypoint.new(0.17, Color3.fromHSV(0.17, 1, 1)),
            ColorSequenceKeypoint.new(0.33, Color3.fromHSV(0.33, 1, 1)),
            ColorSequenceKeypoint.new(0.5, Color3.fromHSV(0.5, 1, 1)),
            ColorSequenceKeypoint.new(0.67, Color3.fromHSV(0.67, 1, 1)),
            ColorSequenceKeypoint.new(0.83, Color3.fromHSV(0.83, 1, 1)),
            ColorSequenceKeypoint.new(1, Color3.fromHSV(1, 1, 1)),
        })
        hueGrad.Parent = hue

        -- Cursor indicators.
        local svCursor = Instance.new("Frame")
        svCursor.AnchorPoint = Vector2.new(0.5, 0.5)
        svCursor.Size = UDim2.new(0, 10, 0, 10)
        svCursor.Position = UDim2.new(s, 0, 1 - v, 0)
        svCursor.BackgroundColor3 = Color3.new(1, 1, 1)
        svCursor.BorderSizePixel = 0
        svCursor.ZIndex = 5
        svCursor.Parent = sv
        corner(svCursor, 5)
        stroke(svCursor, Color3.fromRGB(0, 0, 0), 1.5, 0.3)

        local hueCursor = Instance.new("Frame")
        hueCursor.AnchorPoint = Vector2.new(0.5, 0.5)
        hueCursor.Size = UDim2.new(1, 4, 0, 4)
        hueCursor.Position = UDim2.new(0.5, 0, h, 0)
        hueCursor.BackgroundColor3 = Color3.new(1, 1, 1)
        hueCursor.BorderSizePixel = 0
        hueCursor.ZIndex = 5
        hueCursor.Parent = hue
        corner(hueCursor, 2)
        stroke(hueCursor, Color3.fromRGB(0, 0, 0), 1, 0.4)

        -- Opacity bar: the grid first, then the colour over it with a
        -- transparency ramp, so the left end shows the grid straight through.
        local alphaHolder, alphaBar, alphaCursor, alphaValue
        if useAlpha then
            alphaHolder = Instance.new("Frame")
            alphaHolder.Position = UDim2.new(0, 0, 0, 150)
            -- Short of the full width: the number lives in the gap on the right.
            -- Reading opacity off the position of a cursor is guesswork, and the one
            -- value in this panel that has no digits anywhere was the one people
            -- asked about.
            alphaHolder.Size = UDim2.new(1, -44, 0, 16)
            alphaHolder.BackgroundTransparency = 1
            alphaHolder.BorderSizePixel = 0
            alphaHolder.Parent = panel

            alphaValue = Instance.new("TextLabel")
            alphaValue.AnchorPoint = Vector2.new(1, 0.5)
            alphaValue.Position = UDim2.new(1, 0, 0, 158)
            alphaValue.Size = UDim2.new(0, 40, 0, 16)
            alphaValue.BackgroundTransparency = 1
            alphaValue.TextSize = 13
            alphaValue.TextXAlignment = Enum.TextXAlignment.Right
            alphaValue.Text = math.floor(alpha * 100 + 0.5) .. "%"
            alphaValue.Parent = panel
            faced(alphaValue, "medium")
            themed(alphaValue, "TextColor3", "subtext")

            checkerboard(alphaHolder, 8, 0, 4)

            alphaBar = Instance.new("ImageButton")
            alphaBar.Size = UDim2.new(1, 0, 1, 0)
            alphaBar.BackgroundColor3 = colorOf(getRgb())
            alphaBar.AutoButtonColor = false
            alphaBar.BorderSizePixel = 0
            alphaBar.ZIndex = 2
            alphaBar.Parent = alphaHolder
            corner(alphaBar, 4)
            local aGrad = Instance.new("UIGradient")
            aGrad.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(1, 0) })
            aGrad.Parent = alphaBar

            alphaCursor = Instance.new("Frame")
            alphaCursor.AnchorPoint = Vector2.new(0.5, 0.5)
            alphaCursor.Size = UDim2.new(0, 4, 1, 4)
            alphaCursor.Position = UDim2.new(alpha, 0, 0.5, 0)
            alphaCursor.BackgroundColor3 = Color3.new(1, 1, 1)
            alphaCursor.BorderSizePixel = 0
            alphaCursor.ZIndex = 5
            alphaCursor.Parent = alphaBar
            corner(alphaCursor, 2)
            stroke(alphaCursor, Color3.fromRGB(0, 0, 0), 1, 0.4)
        end

        local hexBox
        -- Assigned once the recent row exists, further down. The drag handlers below
        -- call it when a drag ends: recording every intermediate colour a drag
        -- passes through would fill the row with a gradient.
        local commitRecent
        local function apply()
            sv.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
            local final = Color3.fromHSV(h, s, v)
            swatchFill.BackgroundColor3 = final
            svCursor.Position = UDim2.new(s, 0, 1 - v, 0)
            hueCursor.Position = UDim2.new(0.5, 0, h, 0)
            local rgb = { math.floor(final.R * 255 + 0.5), math.floor(final.G * 255 + 0.5), math.floor(final.B * 255 + 0.5) }
            hexLabel.Text = hexOf(rgb)
            if hexBox then hexBox.Text = hexOf(rgb) end
            if useAlpha then
                alphaBar.BackgroundColor3 = final
                alphaCursor.Position = UDim2.new(alpha, 0, 0.5, 0)
                swatchFill.BackgroundTransparency = 1 - alpha
                alphaValue.Text = math.floor(alpha * 100 + 0.5) .. "%"
                rgb[4] = alpha
            end
            if setRgb then setRgb(rgb) end
            -- A picker writes through a setter of its own, so the config is told
            -- by hand that something changed.
            if ctx and ctx.markDirty then ctx:markDirty() end
        end
        local function updSV(x, y)
            s = math.clamp((x - sv.AbsolutePosition.X) / math.max(sv.AbsoluteSize.X, 1), 0, 1)
            v = 1 - math.clamp((y - sv.AbsolutePosition.Y) / math.max(sv.AbsoluteSize.Y, 1), 0, 1)
            apply()
        end
        local function updHue(y)
            h = math.clamp((y - hue.AbsolutePosition.Y) / math.max(hue.AbsoluteSize.Y, 1), 0, 1)
            apply()
        end
        local function updAlpha(x)
            alpha = math.clamp((x - alphaBar.AbsolutePosition.X) / math.max(alphaBar.AbsoluteSize.X, 1), 0, 1)
            apply()
        end
        -- Each field hands the pointer to the shared drag controller for as long
        -- as the button is held, so the picker adds no permanent input listeners
        -- and a drag that leaves the panel still tracks.
        sv.InputBegan:Connect(function(i)
            if not isPointer(i.UserInputType) then return end
            updSV(i.Position.X, i.Position.Y)
            tween(svCursor, 0.12, { Size = UDim2.new(0, 13, 0, 13) }, EASE_POP)
            beginDrag({
                move = updSV,
                stop = function()
                    tween(svCursor, 0.16, { Size = UDim2.new(0, 10, 0, 10) }, EASE_SOFT)
                    if commitRecent then commitRecent() end
                end,
            })
        end)
        hue.InputBegan:Connect(function(i)
            if not isPointer(i.UserInputType) then return end
            updHue(i.Position.Y)
            tween(hueCursor, 0.12, { Size = UDim2.new(1, 6, 0, 6) }, EASE_POP)
            beginDrag({
                move = function(_, y) updHue(y) end,
                stop = function()
                    tween(hueCursor, 0.16, { Size = UDim2.new(1, 4, 0, 4) }, EASE_SOFT)
                    if commitRecent then commitRecent() end
                end,
            })
        end)
        if useAlpha then
            -- Moving the opacity does not record anything in the recent row. The row is a
            -- list of colours, and the colour has not changed: making it 40 percent
            -- transparent put an entry in that looked identical to the one already there.
            alphaBar.InputBegan:Connect(function(i)
                if not isPointer(i.UserInputType) then return end
                updAlpha(i.Position.X)
                tween(alphaCursor, 0.12, { Size = UDim2.new(0, 6, 1, 6) }, EASE_POP)
                beginDrag({
                    move = function(x) updAlpha(x) end,
                    stop = function()
                        tween(alphaCursor, 0.16, { Size = UDim2.new(0, 4, 1, 4) }, EASE_SOFT)
                    end,
                })
            end)
        end

        local function applyHsv(color)
            h, s, v = color:ToHSV()
            apply()
        end

        -- A colour chip. Clicking one loads it, which is the whole point of both the
        -- preset row and the recent row.
        local function chipFor(hex, parent, order)
            local r = tonumber(string.sub(hex, 1, 2), 16)
            local g = tonumber(string.sub(hex, 3, 4), 16)
            local b = tonumber(string.sub(hex, 5, 6), 16)
            if not (r and g and b) then return nil end
            local chip = Instance.new("TextButton")
            chip.Size = UDim2.new(0, 22, 0, 22)
            chip.BackgroundColor3 = Color3.fromRGB(r, g, b)
            chip.BorderSizePixel = 0
            chip.AutoButtonColor = false
            chip.Text = ""
            chip.LayoutOrder = order
            chip.Parent = parent
            corner(chip, 5)
            stroke(chip, "stroke", 1, 0.35)
            chip.MouseButton1Click:Connect(function()
                applyHsv(Color3.fromRGB(r, g, b))
                if commitRecent then commitRecent() end
            end)
            return chip
        end

        -- Recent colours, above the hex field. Rebuilt rather than reordered: seven
        -- swatches are cheaper to make again than to keep in sync.
        local recentRow = Instance.new("Frame")
        recentRow.AnchorPoint = Vector2.new(0, 1)
        recentRow.Position = UDim2.new(0, 0, 1, -recentY)
        recentRow.Size = UDim2.new(1, 0, 0, ROW_H)
        recentRow.BackgroundTransparency = 1
        recentRow.Parent = panel
        listLayout(recentRow, 4, Enum.FillDirection.Horizontal)

        local function drawRecent()
            for _, child in ipairs(recentRow:GetChildren()) do
                if child:IsA("GuiObject") then child:Destroy() end
            end
            for index, hex in ipairs(recentColors) do
                chipFor(hex, recentRow, index)
            end

            -- The row takes no height until it has something in it, and the panel grows
            -- into it when the first colour is recorded. Eased, because the panel is on
            -- screen while this happens: snapping thirty pixels taller under the pointer
            -- is the kind of jump that reads as a glitch.
            local wantRecent = #recentColors > 0
            recentRow.Visible = wantRecent
            if wantRecent ~= hadRecent then
                hadRecent = wantRecent
                tween(panel, 0.22, {
                    Size = UDim2.new(0, 232, 0, wantRecent and tallH or shortH),
                }, EASE)
            end

            -- The last slot empties the row, and is only drawn when there is something to
            -- empty.
            if not wantRecent then return end
            -- The icon on its own, with no surface under it. A filled chip here read as
            -- a ninth colour in a row of colours, which is the one thing it is not.
            local clear = Instance.new("TextButton")
            clear.Size = UDim2.new(0, 22, 0, 22)
            clear.BackgroundTransparency = 1
            clear.BorderSizePixel = 0
            clear.AutoButtonColor = false
            clear.Text = ""
            clear.LayoutOrder = 99
            clear.Parent = recentRow
            local mark = makeIcon(clear, "trash", UDim2.new(0, 14, 0, 14), "iconDim")
            mark.AnchorPoint = Vector2.new(0.5, 0.5)
            mark.Position = UDim2.new(0.5, 0, 0.5, 0)
            mark.Active = false
            if mark.Image == "" then
                mark:Destroy()
                clear.Text = "x"
                clear.TextSize = 13
                faced(clear, "medium")
                themed(clear, "TextColor3", "subtext")
            end
            clear.MouseEnter:Connect(function()
                if mark.Parent then tintIcon(mark, PALETTE.icon) end
            end)
            clear.MouseLeave:Connect(function()
                if mark.Parent then tintIcon(mark, PALETTE.iconDim) end
            end)
            clear.MouseButton1Click:Connect(function()
                Interface.clearRecentColors()
                if ctx and ctx.markDirty then ctx:markDirty() end
                drawRecent()
            end)
        end
        commitRecent = function()
            local rgb = getRgb()
            if type(rgb) == "table" then
                pushRecent(rgb)
                drawRecent()
            end
        end
        drawRecent()

        hexBox = Instance.new("TextBox")
        hexBox.AnchorPoint = Vector2.new(0, 1)
        hexBox.Position = UDim2.new(0, 0, 1, 0)
        hexBox.Size = UDim2.new(1, 0, 0, 28)
        hexBox.BorderSizePixel = 0
        hexBox.TextSize = 14
        hexBox.PlaceholderText = "#RRGGBB"
        hexBox.Text = hexLabel.Text
        hexBox.ClearTextOnFocus = false
        hexBox.Parent = panel
        faced(hexBox, "medium")
        themed(hexBox, "BackgroundColor3", "control")
        themed(hexBox, "TextColor3", "text")
        themed(hexBox, "PlaceholderColor3", "subtext")
        corner(hexBox, 6)
        hexBox.Focused:Connect(function() tween(hexBox, 0.16, { BackgroundColor3 = PALETTE.controlHover }, EASE_SOFT) end)
        hexBox.FocusLost:Connect(function()
            tween(hexBox, 0.2, { BackgroundColor3 = PALETTE.control }, EASE_SOFT)
            local hx = string.gsub(hexBox.Text, "#", "")
            if #hx == 6 then
                local r = tonumber(string.sub(hx, 1, 2), 16)
                local g = tonumber(string.sub(hx, 3, 4), 16)
                local b = tonumber(string.sub(hx, 5, 6), 16)
                if r and g and b then
                    applyHsv(Color3.fromRGB(r, g, b))
                    commitRecent()
                    return
                end
            end
            hexBox.Text = hexLabel.Text
        end)
    end
    pipette.MouseButton1Click:Connect(openPicker)
    swatch.Active = true
    pipette.MouseEnter:Connect(function() tintIcon(palImg, PALETTE.accent) end)
    pipette.MouseLeave:Connect(function() tintIcon(palImg, PALETTE.iconDim) end)
    -- Keep the swatch and hex in sync when the value changes from somewhere else: a preset
    -- applied, a theme reset, a config loaded. On the repaint list rather than the refresh
    -- list, so it costs a colour read and two writes per palette change instead of a
    -- re-render.
    if ctx and ctx._repaint then
        table.insert(ctx._repaint, function()
            local c = colorOf(getRgb())
            swatchFill.BackgroundColor3 = c
            hexLabel.Text = hexOf(getRgb())
            h, s, v = c:ToHSV()
            if useAlpha then
                alpha = (getRgb() or {})[4] or alpha
                swatchFill.BackgroundTransparency = 1 - alpha
            end
        end)
    end
    return row
end

-- A value the script owns and the user only reads: the label, a dot and the value.
--
-- This exists because of what it replaces. A toggle built without a setter draws the right
-- state and then ignores every press, which is correct and still wrong: it looks exactly
-- like a switch, so it gets clicked, and a switch that will not move reads as a broken
-- control rather than as a read out. A dot and a word cannot be mistaken for something
-- operable.
--
-- get returns a boolean, drawn as On or Off with a dot the accent lights when it is true,
-- or a string, drawn as it is with no dot. opts.lit is a getter for the dot on a row whose
-- value is a string, for the case where the words and the light say different things.
function Controls.status(parent, ctx, text, get, opts)
    opts = opts or {}
    local row = controlRow(parent, 26)
    rowLabel(row, text, 140)

    -- A dot only where there is a state for it to show. A permanently unlit dot beside a
    -- number reads as a warning light that never comes on. nil counts as a state, because a
    -- getter reading something that has not been set yet returns nil first and a boolean
    -- afterwards, and the row would otherwise be built without the dot it needs.
    local lit = opts.lit
    if lit == nil then
        local sample = get()
        if type(sample) == "boolean" or sample == nil then lit = get end
    end

    local dot
    if lit then
        dot = Instance.new("Frame")
        dot.AnchorPoint = Vector2.new(1, 0.5)
        dot.Position = UDim2.new(1, 0, 0.5, 0)
        dot.Size = UDim2.new(0, 8, 0, 8)
        dot.BorderSizePixel = 0
        dot.Parent = row
        corner(dot, 4)
    end

    local value = Instance.new("TextLabel")
    value.AnchorPoint = Vector2.new(1, 0.5)
    value.Position = UDim2.new(1, dot and -14 or 0, 0.5, 0)
    value.Size = UDim2.new(0, 120, 1, 0)
    value.BackgroundTransparency = 1
    value.TextSize = 14
    value.TextXAlignment = Enum.TextXAlignment.Right
    value.TextTruncate = Enum.TextTruncate.AtEnd
    value.Parent = row
    faced(value, "medium")

    -- Through the phrase table, so On and Off are translated along with everything else the
    -- kit draws, and so is a word the script reports if the script has a phrase for it.
    local setPhrase = localized(value, "Text", "")
    local shownPhrase = nil

    -- The word is text rather than subtext while the row is on, so a row that is on can be
    -- picked out of a column of rows that are off without reading any of them. Neither the
    -- word nor the dot is in the palette registry, because which colour each wants depends
    -- on the value rather than on the key.
    local function repaint()
        local raw = get()
        local phrase
        if type(raw) == "boolean" or raw == nil then
            phrase = raw and "On" or "Off"
        else
            phrase = tostring(raw)
        end
        -- Only on a change: this runs on every frame of a palette change, and rebinding the
        -- phrase each time would put a translation lookup on the frame driver for nothing.
        if phrase ~= shownPhrase then
            shownPhrase = phrase
            setPhrase(phrase)
        end
        local on = lit and lit() and true or false
        value.TextColor3 = on and shownColor("text") or shownColor("subtext")
        if dot then
            dot.BackgroundColor3 = on and shownColor("accent") or shownColor("iconDim")
        end
    end
    addStatePainter(row, repaint)
    -- A read out has no event of its own to follow, so it is re-read whenever anything else
    -- is: a config load, or a script calling refreshAll after changing what it reports.
    if ctx and ctx._refresh then
        table.insert(ctx._refresh, repaint)
    end
    return row
end

-- Segmented control: a row of mutually exclusive pills (Toggle / Hold / Always).
-- One accent block slides between them instead of each pill repainting itself,
-- which is what makes the change read as one movement.
--
-- opts.fill = true puts the strip on its own line under the label and divides the row's
-- whole width between the options equally, instead of sitting beside the label and growing
-- from the text. Two different shapes because they fail in different places, and a card
-- column is only about 270 pixels wide inside its padding:
--
--   beside the label, auto sized   three or four short words. Anything more runs off the
--                                  left of the row, and a translation half again as long
--                                  does it with three.
--   own line, shared width         four or five options of any length, because a pill that
--                                  is too narrow truncates its own text rather than pushing
--                                  the strip past the edge of the card.
--
-- So the default stays as it was and the second shape is asked for. It is what the weight
-- rows on the type card use: four options whose names are long in English and longer once
-- translated.
function Controls.segmented(parent, ctx, text, options, get, set, opts)
    opts = opts or {}
    local fill = opts.fill == true
    local named = text ~= nil and text ~= ""
    -- Filled and named is two lines: the caption, then the strip. Filled and unnamed is the
    -- strip alone, so the row is the height of the strip and not of a caption that is not
    -- there. Asking for the height before the label exists is why this is worked out here.
    local row = controlRow(parent, fill and (named and 52 or 30) or 30)
    local label = nil
    if named then
        label = rowLabel(row, text, fill and 0 or 200)
        if fill then
            -- Above the strip rather than beside it, and the caption size the section
            -- headings use, because at fifteen it reads as a row of its own rather than as
            -- the name of the thing under it.
            label.Size = UDim2.new(1, 0, 0, 18)
            label.TextSize = 13
        end
    end
    -- Three siblings of the row, in draw order: the recessed track, the accent
    -- marker, then the strip of labels.
    --
    -- The labels have to be the last of the three. An earlier build put the
    -- marker after the strip so it could be measured against the row, and
    -- because siblings of equal depth draw in tree order the marker landed on top
    -- of the label it was supposed to be highlighting: the selected option went
    -- blank behind a block of accent.
    --
    -- The marker stays out of the strip because the strip is padded, and a padded
    -- parent would offset it a second time on top of the rectangle it was already
    -- measured from.
    -- Where the strip and the track sit. Filled: pinned to the left, under the label, the
    -- full width of the row. Otherwise: pinned to the right of the row, as wide as its text.
    local stripAnchor = fill and Vector2.new(0, 0) or Vector2.new(1, 0.5)
    local stripPosition = fill and UDim2.new(0, 0, 0, named and 22 or 0) or UDim2.new(1, 0, 0.5, 0)
    local stripHeight = fill and UDim2.new(1, 0, 0, 30) or UDim2.new(0, 0, 1, -2)

    local track = Instance.new("Frame")
    track.AnchorPoint = stripAnchor
    track.Position = stripPosition
    track.Size = stripHeight
    track.BorderSizePixel = 0
    track.ZIndex = 1
    track.Parent = row
    themed(track, "BackgroundColor3", "control")
    corner(track, 7)

    local marker = Instance.new("Frame")
    marker.Name = randomName()
    marker.Size = UDim2.new(0, 0, 0, 0)
    marker.Position = UDim2.new(0, 0, 0, 0)
    marker.BorderSizePixel = 0
    marker.ZIndex = 2
    marker.Parent = row
    themed(marker, "BackgroundColor3", "accent")
    corner(marker, 5)

    -- The strip is auto sized from its labels and the track is sized to match, so
    -- a translated option twice as long as the English one still fits instead of
    -- being cut off at a fixed pill width. Filled, it is the row's width instead and the
    -- options share it, so the same growth truncates a pill rather than moving the strip.
    local strip = Instance.new("Frame")
    strip.AnchorPoint = stripAnchor
    strip.Position = stripPosition
    strip.Size = stripHeight
    if not fill then strip.AutomaticSize = Enum.AutomaticSize.X end
    strip.BackgroundTransparency = 1
    strip.ZIndex = 3
    strip.Parent = row
    padding(strip, nil, { left = 3, right = 3, top = 3, bottom = 3 })
    listLayout(strip, 3, Enum.FillDirection.Horizontal)

    local buttons = {}
    -- Auto sized labels report a width a frame after they are built, and the row
    -- reports a position only once its column has been laid out, so the first
    -- placement retries. The retry is capped: a tab that has never been opened
    -- has no geometry at all, and an uncapped retry would defer itself forever.
    local function place(btn, animate, attempt)
        attempt = attempt or 0
        if not btn or not btn.Parent then return end
        if btn.AbsoluteSize.X < 1 then
            if attempt >= 8 then return end
            task.defer(function()
                local current = buttons[get()]
                if current then place(current, false, attempt + 1) end
            end)
            return
        end
        local origin = row.AbsolutePosition
        local at = btn.AbsolutePosition
        local size = btn.AbsoluteSize
        local target = {
            Position = UDim2.new(0, at.X - origin.X, 0, at.Y - origin.Y),
            Size = UDim2.new(0, size.X, 0, size.Y),
        }
        if animate then
            tween(marker, 0.26, target, EASE)
        else
            marker.Position = target.Position
            marker.Size = target.Size
        end
    end
    -- Which option the pointer is over, so a repaint does not undo a hover. The palette
    -- pass below runs on every frame of a theme change, and without this a change made
    -- while the pointer rested on an option kept snapping that option back to subtext.
    local hovered = nil
    local function render(animate)
        local current = get()
        -- The selected label sits on the accent block, so its colour is picked
        -- against the accent rather than fixed. It used to be the background
        -- colour, which is dark, and a dark accent left the selected option
        -- reading as blank.
        local onAccent = contrastOn(PALETTE.accent)
        for value, btn in pairs(buttons) do
            local on = value == current
            tween(btn, 0.16, { TextColor3 = on and onAccent or PALETTE.subtext }, EASE_SOFT)
        end
        place(buttons[current], animate)
    end
    -- An equal share of the strip each, less the gap the layout puts between them, so the
    -- n options and the n-1 gaps come to the strip's width and no more. Auto sized instead
    -- when the strip is the one that grows.
    local share = 1 / math.max(#options, 1)
    for _, option in ipairs(options) do
        local btn = Instance.new("TextButton")
        if fill then
            btn.Size = UDim2.new(share, -3, 1, 0)
            -- Written rather than left at the default, because the share is the point: an
            -- auto sized pill here would grow past it and push the strip off the row.
            btn.AutomaticSize = Enum.AutomaticSize.None
            btn.TextTruncate = Enum.TextTruncate.AtEnd
        else
            btn.Size = UDim2.new(0, 0, 1, 0)
            btn.AutomaticSize = Enum.AutomaticSize.X
        end
        btn.BackgroundTransparency = 1
        btn.BorderSizePixel = 0
        btn.AutoButtonColor = false
        btn.TextSize = 14
        btn.Parent = strip
        faced(btn, "medium")
        localized(btn, "Text", tostring(option))
        local bpad = Instance.new("UIPadding")
        -- Narrower when the width is shared: the padding is there to keep a pill off the
        -- marker's rounded corner, and at a fixed share it is competing with the text.
        bpad.PaddingLeft = UDim.new(0, fill and 4 or 12)
        bpad.PaddingRight = UDim.new(0, fill and 4 or 12)
        bpad.Parent = btn
        buttons[option] = btn
        btn.MouseEnter:Connect(function()
            hovered = option
            if get() ~= option then tween(btn, 0.14, { TextColor3 = PALETTE.text }, EASE_SOFT) end
        end)
        btn.MouseLeave:Connect(function()
            if hovered == option then hovered = nil end
            if get() ~= option then tween(btn, 0.16, { TextColor3 = PALETTE.subtext }, EASE_SOFT) end
        end)
        btn.MouseButton1Click:Connect(function()
            if not set then return end
            set(option)
            render(true)
        end)
    end

    -- These labels are not in the palette registry, because which colour each one wants
    -- depends on which option is selected. So they repaint themselves at the end of every
    -- palette pass, from the colour on screen at that moment rather than the one the
    -- change is heading for.
    --
    -- Without this the selected label kept the contrast colour worked out against the old
    -- accent: switching from a light preset to a dark one left the one option sitting on
    -- the accent block dark on dark until it happened to be clicked, which is the label in
    -- the row that is guaranteed to be unreadable.
    addStatePainter(row, function()
        local current = get()
        local onAccent = contrastOn(shownColor("accent"))
        for value, btn in pairs(buttons) do
            if value == current then
                btn.TextColor3 = onAccent
            elseif value == hovered then
                btn.TextColor3 = shownColor("text")
            else
                btn.TextColor3 = shownColor("subtext")
            end
        end
    end)
    -- The track follows the strip, so the recess is exactly as wide as the labels,
    -- and the row's own label gives up whatever room the strip takes. A fixed
    -- reservation was enough for the English options and not for a translation
    -- twice their length, which then ran under the strip.
    local function fitTrack()
        -- Filled, the track is already the row's width and the label is above it rather than
        -- beside it, so there is nothing to measure and nothing to give up.
        if fill then return end
        local width = strip.AbsoluteSize.X
        track.Size = UDim2.new(0, width, 1, -2)
        if label then
            label.Size = UDim2.new(1, -(width + 12), 1, 0)
        end
    end
    fitTrack()
    render(false)
    local conns = {
        row:GetPropertyChangedSignal("AbsolutePosition"):Connect(function()
            place(buttons[get()], false)
        end),
        strip:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
            fitTrack()
            place(buttons[get()], false)
        end),
    }
    row.Destroying:Connect(function()
        for _, conn in ipairs(conns) do conn:Disconnect() end
    end)
    if ctx and ctx._refresh then table.insert(ctx._refresh, function() render(true) end) end
    return row
end

-- Inline searchable list with radio selection (single choice).
function Controls.list(parent, ctx, options, get, set, opts)
    opts = opts or {}
    local container = Instance.new("Frame")
    container.Size = UDim2.new(1, 0, 0, 0)
    container.AutomaticSize = Enum.AutomaticSize.Y
    container.BackgroundTransparency = 1
    container.LayoutOrder = nextOrder(parent)
    container.Parent = parent
    listLayout(container, 4)

    local rows = {}
    local searchBox
    if opts.search ~= false then
        local search = Instance.new("Frame")
        search.Size = UDim2.new(1, 0, 0, 30)
        search.BorderSizePixel = 0
        search.LayoutOrder = nextOrder(container)
        search.Parent = container
        themed(search, "BackgroundColor3", "control")
        corner(search, 8)
        local sicon = makeIcon(search, "search", UDim2.new(0, 15, 0, 15), "iconDim")
        sicon.AnchorPoint = Vector2.new(0, 0.5)
        sicon.Position = UDim2.new(0, 10, 0.5, 0)
        searchBox = Instance.new("TextBox")
        searchBox.BackgroundTransparency = 1
        searchBox.Position = UDim2.new(0, 32, 0, 0)
        searchBox.Size = UDim2.new(1, -42, 1, 0)
        searchBox.TextSize = 14
        searchBox.Text = ""
        searchBox.ClearTextOnFocus = false
        searchBox.TextXAlignment = Enum.TextXAlignment.Left
        searchBox.Parent = search
        faced(searchBox, "regular")
        themed(searchBox, "TextColor3", "text")
        themed(searchBox, "PlaceholderColor3", "subtext")
        localized(searchBox, "PlaceholderText", "Search..")
    end

    local function render()
        local current = get()
        for value, refs in pairs(rows) do
            local on = value == current
            refs.on = on
            tween(refs.label, 0.14, { TextColor3 = on and PALETTE.accentSoft or PALETTE.text }, EASE_SOFT)
            refs.row.BackgroundColor3 = PALETTE.controlHover
            tween(refs.row, 0.14, { BackgroundTransparency = on and 0 or 1 }, EASE_SOFT)
            if refs.tick then
                tween(refs.tick, 0.16, { ImageTransparency = on and 0 or 1 }, EASE_SOFT)
            end
        end
    end
    for _, option in ipairs(options) do
        local optRow = Instance.new("TextButton")
        optRow.Size = UDim2.new(1, 0, 0, 32)
        optRow.BackgroundTransparency = 1
        optRow.BorderSizePixel = 0
        optRow.AutoButtonColor = false
        optRow.Text = ""
        optRow.LayoutOrder = nextOrder(container)
        optRow.Parent = container
        themed(optRow, "BackgroundColor3", "controlHover", { fade = false })
        corner(optRow, 8)
        local label = Instance.new("TextLabel")
        label.BackgroundTransparency = 1
        label.Position = UDim2.new(0, 14, 0, 0)
        label.Size = UDim2.new(1, -46, 1, 0)
        label.TextSize = 14
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.TextTruncate = Enum.TextTruncate.AtEnd
        label.ZIndex = 2
        label.Parent = optRow
        faced(label, "medium")
        localized(label, "Text", tostring(option))
        local tick = makeIcon(optRow, "check", UDim2.new(0, 16, 0, 16), "accentSoft")
        tick.AnchorPoint = Vector2.new(1, 0.5)
        tick.Position = UDim2.new(1, -12, 0.5, 0)
        tick.ImageTransparency = 1
        tick.ZIndex = 2
        tick.Active = false
        rows[option] = { label = label, row = optRow, tick = tick.Image ~= "" and tick or nil, on = false }
        optRow.MouseEnter:Connect(function()
            if get() ~= option then tween(optRow, 0.12, { BackgroundTransparency = 0.5 }, EASE_SOFT) end
        end)
        optRow.MouseLeave:Connect(function()
            if get() ~= option then tween(optRow, 0.16, { BackgroundTransparency = 1 }, EASE_SOFT) end
        end)
        optRow.MouseButton1Click:Connect(function()
            if not set then return end
            set(option)
            render()
        end)
    end
    render()
    if ctx and ctx._refresh then table.insert(ctx._refresh, render) end
    -- The selected row's name is the corrected accent and every other name is text, so which
    -- colour each one wants depends on which row is selected. render() runs only when the
    -- selection changes, which left the selected name wearing the accent it happened to be
    -- selected under: pick a preset of a different colour and one row in the list stayed the
    -- old colour until it was clicked. These repaint from the colour on screen at the end of
    -- every palette pass instead, so they follow the change like everything around them.
    addStatePainter(container, function()
        for _, refs in pairs(rows) do
            refs.label.TextColor3 = refs.on and shownColor("accentSoft") or shownColor("text")
        end
    end)
    if searchBox then
        searchBox:GetPropertyChangedSignal("Text"):Connect(function()
            local q = searchBox.Text:lower()
            for opt, refs in pairs(rows) do
                local shown = tostring(opt):lower()
                local drawn = refs.label.Text:lower()
                refs.row.Visible = q == "" or shown:find(q, 1, true) ~= nil or drawn:find(q, 1, true) ~= nil
            end
        end)
    end
    return container
end

-- Stepper: a numeric value with minus and plus buttons (- value +).
function Controls.stepper(parent, ctx, text, min, max, step, get, set)
    step = step or 1
    local row = controlRow(parent, 30)
    rowLabel(row, text, 110)

    local holder = Instance.new("Frame")
    holder.AnchorPoint = Vector2.new(1, 0.5)
    holder.Position = UDim2.new(1, 0, 0.5, 0)
    holder.Size = UDim2.new(0, 100, 0, 24)
    holder.BorderSizePixel = 0
    holder.Parent = row
    themed(holder, "BackgroundColor3", "control")
    corner(holder, 6)

    local function mkArrow(symbol, x, anchorX)
        local b = Instance.new("TextButton")
        b.AnchorPoint = Vector2.new(anchorX, 0.5)
        b.Position = UDim2.new(x, 0, 0.5, 0)
        b.Size = UDim2.new(0, 26, 1, 0)
        b.BackgroundTransparency = 1
        b.AutoButtonColor = false
        b.TextSize = 17
        b.Text = symbol
        b.Parent = holder
        faced(b, "semibold")
        themed(b, "TextColor3", "subtext", { fade = false })
        b.MouseEnter:Connect(function() tween(b, 0.14, { TextColor3 = PALETTE.accent }, EASE_SOFT) end)
        b.MouseLeave:Connect(function() tween(b, 0.16, { TextColor3 = PALETTE.subtext }, EASE_SOFT) end)
        return b
    end
    local minus = mkArrow("-", 0, 0)
    local plus = mkArrow("+", 1, 1)

    local value = Instance.new("TextBox")
    value.AnchorPoint = Vector2.new(0.5, 0.5)
    value.Position = UDim2.new(0.5, 0, 0.5, 0)
    value.Size = UDim2.new(0, 48, 1, 0)
    value.BackgroundTransparency = 1
    value.TextSize = 14
    value.Text = tostring(get())
    value.ClearTextOnFocus = false
    value.TextXAlignment = Enum.TextXAlignment.Center
    value.Parent = holder
    faced(value, "medium")
    themed(value, "TextColor3", "text")

    -- The number is written straight in. Sliding it in the direction of the step
    -- was tried and dropped: moving a label a few pixels re-renders the glyphs at
    -- fractional offsets and the digits crawl instead of stepping.
    local function apply(v)
        if not set then return end
        v = math.clamp(v, min, max)
        set(v)
        value.Text = tostring(v)
    end
    minus.MouseButton1Click:Connect(function() apply(get() - step) end)
    plus.MouseButton1Click:Connect(function() apply(get() + step) end)
    value.FocusLost:Connect(function()
        local typed = tonumber(string.match(value.Text, "[%-%d%.]+"))
        if typed then apply(typed) else value.Text = tostring(get()) end
    end)
    if ctx and ctx._refresh then table.insert(ctx._refresh, function() value.Text = tostring(get()) end) end
    return row
end

-- Card: a titled surface that hosts controls. Built by a sub-page, and reused as
-- the body of a gear popover so a popover takes the same builders as a card,
-- with the same parent frame and owning window as context.
Card = {}
Card.__index = Card
function Card.new(frame, ctx, place)
    return setmetatable({ _frame = frame, _ctx = ctx, _place = place }, Card)
end

-- Every named control is added to the search index as it is built.
--
-- It is done here rather than inside each control builder for two reasons: the
-- builders do not know which card, sub-page and tab they ended up on, and a card
-- standing in for a gear popover is created without a place, which is exactly the
-- case that should not be indexed. A control inside a popover cannot be jumped to
-- without opening the popover first.
function Card:_index(label, row)
    local ctx = self._ctx
    if not (ctx and ctx._search and self._place and row and label and label ~= "") then return row end
    ctx._search[#ctx._search + 1] = {
        label = label,
        card = self._place.card,
        tab = self._place.tab,
        sub = self._place.sub,
        row = row,
    }
    return row
end

function Card:label(text) return Controls.label(self._frame, text) end
function Card:status(text, get, opts) return self:_index(text, Controls.status(self._frame, self._ctx, text, get, opts)) end
function Card:section(text) return Controls.section(self._frame, text) end
function Card:button(text, fn) return self:_index(text, Controls.button(self._frame, self._ctx, text, fn)) end
function Card:input(text, placeholder, get, set) return self:_index(text, Controls.input(self._frame, self._ctx, text, placeholder, get, set)) end
function Card:toggle(text, get, set, settings) return self:_index(text, Controls.toggle(self._frame, self._ctx, text, get, set, settings)) end
function Card:slider(text, min, max, get, set, decimals, format) return self:_index(text, Controls.slider(self._frame, self._ctx, text, min, max, get, set, decimals, format)) end
function Card:keybind(text, getKey, setKey, opts) return self:_index(text, Controls.keybind(self._frame, self._ctx, text, getKey, setKey, opts)) end
function Card:dropdown(text, options, get, set, opts) return self:_index(text, Controls.dropdown(self._frame, self._ctx, text, options, get, set, opts)) end
function Card:colorpicker(text, getRgb, setRgb, opts) return self:_index(text, Controls.colorpicker(self._frame, self._ctx, text, getRgb, setRgb, opts)) end
function Card:segmented(text, options, get, set, opts) return self:_index(text, Controls.segmented(self._frame, self._ctx, text, options, get, set, opts)) end
function Card:list(options, get, set, opts) return Controls.list(self._frame, self._ctx, options, get, set, opts) end
function Card:stepper(text, min, max, step, get, set) return self:_index(text, Controls.stepper(self._frame, self._ctx, text, min, max, step, get, set)) end

-- The palette editor, as a card method.
--
-- A preset dropdown, a colour row per key and a reset. Every script that ships a
-- settings page was writing this same block out by hand, and it existed twice inside
-- this repo in two slightly different shapes, which is the usual sign it belongs in the
-- library. Because the rows are named here they also go through the phrase table once
-- rather than once per script.
--
-- opts.preset = false   drop the preset dropdown and keep the colour rows
-- opts.keys = { .. }    which palette keys get a row, in that order
-- opts.reset = false    drop the reset button
-- opts.search = false   drop the search field from the preset dropdown
function Card:theme(opts)
    opts = opts or {}
    local win = self._ctx
    if opts.preset ~= false then
        -- The list is passed as a function, so a preset registered by the script after
        -- the card was built still turns up in the dropdown.
        --
        -- Searched by default. The panel shows seven rows and scrolls past that, and the
        -- kit ships fourteen presets before a script has added any of its own, so picking
        -- one by name means scrolling a list to find a word you already know. Pass
        -- opts.search = false on a build that has trimmed the list back down.
        self:dropdown("Preset", Interface.themeNames, function()
            return win:getTheme() or THEME_META.order[1]
        end, function(name)
            win:applyTheme(name)
        end, { search = opts.search ~= false })
    end
    for _, key in ipairs(opts.keys or THEME_META.shown) do
        -- Only real keys, and never accentSoft: it is computed from the accent and the
        -- background, so a row for it would offer a colour that is overwritten the next
        -- time either of those moves.
        if DEFAULTS[key] and key ~= "accentSoft" then
            self:colorpicker(THEME_META.label[key] or key, function()
                return win:getColor(key)
            end, function(rgb)
                win:setColor(key, rgb)
            end)
        end
    end
    if opts.reset ~= false then
        self:button("Reset Theme", function() win:resetTheme() end)
    end
    return self
end

-- The type controls, as a card method.
--
-- Weight is the first thing anyone asks to change, and it is four values rather than one:
-- the kit names a role at every call site, so one control here moves a whole category of
-- text at once. Both the family and the weights are saved with the config.
--
-- Pills rather than dropdowns, filled across the row. A weight is a point on a scale of four
-- and the interesting thing about it is where it sits relative to the others, which a row
-- shows and a closed dropdown does not: four dropdowns reading Regular, Medium, Bold, Bold
-- tell you the four values and nothing about the shape of the choice. It is also one click
-- instead of two, on the one card where the point is to try a setting and look at the result.
--
-- The earlier build used dropdowns because six weights side by side ran off the left edge of
-- the row. Two things changed: the list is four now, for reasons of its own, and the strip
-- can take its own line and share the width rather than growing from its text. See
-- Controls.segmented and opts.fill.
--
-- The family stays a dropdown. Thirteen families is a list to search, not a scale to see.
--
-- Size is a slider, and it is the one control on this card whose effect you cannot see by
-- reading it: a weight is a word, a family is a name, and a size is only worth anything next
-- to the size it was. So it is the shape that moves continuously and reports a number, and it
-- sits under the family because both of them are about the whole interface rather than about
-- one kind of text in it.
--
-- opts.family = false   drop the family list and keep the weights
-- opts.size = false     drop the size slider
-- opts.reset = false    drop the two buttons that move all four roles at once
function Card:typography(opts)
    opts = opts or {}
    local win = self._ctx
    for _, role in ipairs(TYPESET.roles) do
        self:segmented(role.label, TYPESET.weights, function()
            local current = Interface.roleWeights()[role.key] or "regular"
            for _, name in ipairs(TYPESET.weights) do
                if string.lower(name) == current then return name end
            end
            -- A weight set through setRoleWeight that this list does not offer, so the
            -- control names the nearest thing it can rather than showing nothing.
            return "Regular"
        end, function(name)
            Interface.setRoleWeight(role.key, name)
            win:markDirty()
        end, { fill = true })
    end
    if opts.family ~= false then
        self:dropdown("Family", TYPESET.families, function()
            return string.match(Interface.getFont(), "families/(.-)%.json") or TYPESET.families[1]
        end, function(family)
            Interface.setFont("rbxasset://fonts/families/" .. family .. ".json")
            win:markDirty()
        end, { search = true })
    end
    if opts.size ~= false then
        -- Whole percents, and the range comes from the library rather than being written here,
        -- so the slider cannot offer a value setTextScale would refuse.
        local low, high = Interface.textScaleRange()
        self:slider("Text Size", math.floor(low * 100 + 0.5), math.floor(high * 100 + 0.5), function()
            return math.floor(Interface.getTextScale() * 100 + 0.5)
        end, function(percent)
            Interface.setTextScale(percent / 100)
            win:markDirty()
        end, 0, function(value) return value .. "%" end)
    end
    -- The two that move all four roles together, on the same card as the four they move.
    -- They were a second card beside this one, headed "All of it at once", which is a card
    -- holding a sentence and two buttons: the page then read as two things to understand
    -- when it is one, and the sentence was there to explain a split that did not need to
    -- exist. Under a divider on this card they are what they are, the coarse end of the
    -- control above them.
    if opts.reset ~= false then
        self:divider()
        -- refreshAll after both, because these write the same four values the pills above
        -- read: without it the strips keep pointing at the weight that was there before, and
        -- the one control on the card that says what the type is now disagrees with the type.
        -- The old pair sat on a card of their own and had this same fault.
        self:button("One Weight Everywhere", function()
            Interface.setWeight("bold")
            win:markDirty()
            win:refreshAll()
        end)
        self:button("Reset Type", function()
            for _, role in ipairs(TYPESET.roles) do
                Interface.setRoleWeight(role.key, TYPESET.roleWeightDefault[role.key])
            end
            Interface.setFont(TYPESET.familyDefault)
            Interface.setTextScale(TYPESET.scaleDefault)
            win:markDirty()
            win:refreshAll()
        end)
    end
    return self
end
-- A thin divider line inside a card body.
function Card:divider()
    local line = Instance.new("Frame")
    line.Size = UDim2.new(1, 0, 0, 1)
    line.BackgroundTransparency = 0.4
    line.BorderSizePixel = 0
    line.LayoutOrder = nextOrder(self._frame)
    line.Parent = self._frame
    themed(line, "BackgroundColor3", "stroke")
    return line
end

-- Sub-tab page: two scrolling columns that hold cards.
local Sub = {}
Sub.__index = Sub
function Sub.new(page, ctx, left, right)
    return setmetatable({ _page = page, _ctx = ctx, left = left, right = right }, Sub)
end
function Sub:card(title, column)
    -- Accept either card("Title", "left") or card({ title=, subtitle=, icon=, toggle={get,set}, column= }).
    local cfg
    if type(title) == "table" then
        cfg = title
    else
        cfg = { title = title, column = column }
    end
    local col = (cfg.column == "right") and self.right or self.left

    -- A slot the column's layout owns, with the card inside it.
    --
    -- A UIListLayout writes Position on every child it manages, so a card parented straight
    -- into the column cannot be moved: the next reflow puts it back where the list says it
    -- goes. The slot takes the card's place in the list and the card sits inside it at nothing,
    -- which leaves the card's own Position free for an animation to use.
    --
    -- That is what lets the first opening bring the cards in one at a time rather than sliding
    -- both columns as a block. It costs one frame per card and it paints nothing.
    local slot = Instance.new("Frame")
    slot.Size = UDim2.new(1, 0, 0, 0)
    slot.AutomaticSize = Enum.AutomaticSize.Y
    slot.BackgroundTransparency = 1
    slot.BorderSizePixel = 0
    slot.LayoutOrder = nextOrder(col)
    slot.Parent = col

    local cardFrame = Instance.new("Frame")
    cardFrame.Size = UDim2.new(1, 0, 0, 0)
    cardFrame.AutomaticSize = Enum.AutomaticSize.Y
    cardFrame.BorderSizePixel = 0
    cardFrame.Parent = slot
    themed(cardFrame, "BackgroundColor3", "card")
    corner(cardFrame, 12)
    stroke(cardFrame, "stroke", 1, 0.4)

    local body = Instance.new("Frame")
    body.BackgroundTransparency = 1
    body.Size = UDim2.new(1, 0, 0, 0)
    body.AutomaticSize = Enum.AutomaticSize.Y
    body.Parent = cardFrame
    listLayout(body, 11)
    padding(body, 16)

    if cfg.title then
        -- Header row: optional icon, title with optional subtitle, optional enable toggle.
        local header = Instance.new("Frame")
        header.Size = UDim2.new(1, 0, 0, cfg.subtitle and 36 or 22)
        header.BackgroundTransparency = 1
        header.LayoutOrder = nextOrder(body)
        header.Parent = body

        local textX = 0
        if cfg.icon then
            local hicon = makeIcon(header, cfg.icon, UDim2.new(0, 24, 0, 24), "icon")
            hicon.AnchorPoint = Vector2.new(0, 0.5)
            hicon.Position = UDim2.new(0, 0, 0.5, 0)
            textX = 34
        end

        local titleLabel = Instance.new("TextLabel")
        titleLabel.BackgroundTransparency = 1
        titleLabel.Position = UDim2.new(0, textX, 0, 0)
        titleLabel.Size = UDim2.new(1, -textX - (cfg.toggle and 54 or 0), 0, cfg.subtitle and 20 or 22)
        titleLabel.TextSize = 17
        titleLabel.TextXAlignment = Enum.TextXAlignment.Left
        titleLabel.TextYAlignment = cfg.subtitle and Enum.TextYAlignment.Top or Enum.TextYAlignment.Center
        titleLabel.TextTruncate = Enum.TextTruncate.AtEnd
        titleLabel.Parent = header
        faced(titleLabel, "semibold")
        themed(titleLabel, "TextColor3", "text")
        localized(titleLabel, "Text", cfg.title)

        if cfg.subtitle then
            local subLabel = Instance.new("TextLabel")
            subLabel.BackgroundTransparency = 1
            subLabel.Position = UDim2.new(0, textX, 0, 20)
            subLabel.Size = UDim2.new(1, -textX - (cfg.toggle and 54 or 0), 0, 16)
            subLabel.TextSize = 13
            subLabel.TextXAlignment = Enum.TextXAlignment.Left
            subLabel.TextTruncate = Enum.TextTruncate.AtEnd
            subLabel.Parent = header
            faced(subLabel, "regular")
            themed(subLabel, "TextColor3", "subtext")
            localized(subLabel, "Text", cfg.subtitle)
        end

        if cfg.toggle then
            -- Either shape is accepted: { get = , set = } or the pair win:flag
            -- hands back, which reads as toggle = { win:flag("key", false) }.
            makePill(header, self._ctx, cfg.toggle.get or cfg.toggle[1], cfg.toggle.set or cfg.toggle[2])
        end

        -- Divider under the header to separate it from the controls.
        local line = Instance.new("Frame")
        line.Size = UDim2.new(1, 0, 0, 1)
        line.BackgroundTransparency = 0.4
        line.BorderSizePixel = 0
        line.LayoutOrder = nextOrder(body)
        line.Parent = body
        themed(line, "BackgroundColor3", "stroke")
    end
    -- Where this card sits, carried into the search index by every control it builds.
    return Card.new(body, self._ctx, {
        card = cfg.title,
        tab = self.tab,
        sub = self.entry,
    })
end

-- Tab: a sidebar entry that owns a top sub-tab bar and sub-pages.
local Tab = {}
Tab.__index = Tab
function Tab:sub(name)
    local order = #self._subs + 1
    local btn = Instance.new("TextButton")
    btn.AutomaticSize = Enum.AutomaticSize.X
    btn.Size = UDim2.new(0, 0, 1, 0)
    btn.BackgroundTransparency = 1
    btn.AutoButtonColor = false
    btn.TextSize = 15
    btn.LayoutOrder = order
    btn.Parent = self._subBar
    faced(btn, "medium")
    themed(btn, "TextColor3", "subtext", { fade = false })
    localized(btn, "Text", name)
    local bpad = Instance.new("UIPadding")
    bpad.PaddingLeft = UDim.new(0, 2)
    bpad.PaddingRight = UDim.new(0, 2)
    bpad.Parent = btn

    -- Plain frames for the pages as well: a page holds every card on it, so a group
    -- here is a render target around most of the text in the interface.
    local page = Instance.new("Frame")
    page.Size = UDim2.new(1, 0, 1, 0)
    page.BackgroundTransparency = 1
    page.BorderSizePixel = 0
    page.Visible = false
    page.Parent = self._subPages
    local columns = Instance.new("Frame")
    columns.BackgroundTransparency = 1
    columns.Size = UDim2.new(1, 0, 1, 0)
    columns.Parent = page
    local function makeColumn(nm, x)
        local sf = Instance.new("ScrollingFrame")
        sf.Name = nm
        sf.Size = UDim2.new(0.5, -8, 1, 0)
        sf.Position = UDim2.new(x, x == 0 and 0 or 8, 0, 0)
        sf.BackgroundTransparency = 1
        sf.BorderSizePixel = 0
        sf.ScrollBarThickness = 0
        sf.ScrollingDirection = Enum.ScrollingDirection.Y
        sf.CanvasSize = UDim2.new(0, 0, 0, 0)
        sf.AutomaticCanvasSize = Enum.AutomaticSize.Y
        sf.Parent = columns
        listLayout(sf, 12)
        local pad = Instance.new("UIPadding")
        pad.PaddingBottom = UDim.new(0, 10)
        pad.PaddingTop = UDim.new(0, 2)
        pad.Parent = sf
        return sf
    end
    local leftCol = makeColumn("Left", 0)
    local rightCol = makeColumn("Right", 0.5)

    -- Captured now, so the entry animation always has a resting place to return the
    -- columns to and never reads one back off a frame that is mid-tween.
    local risers = {
        { frame = leftCol, home = leftCol.Position },
        { frame = rightCol, home = rightCol.Position },
    }
    local sub = {
        name = name, btn = btn, page = page, columns = columns, tab = self, order = order,
        -- Not while the first opening is in flight. That animation brings the cards in one at a
        -- time, and this one lifts both columns as a block: run together they are two animations
        -- writing to the same page and the result reads as a stutter. Activating the first tab is
        -- what used to trigger it, which happens inside the debut every single time.
        enter = function()
            if self._ctx._debutting then return end
            enterColumns(risers)
        end,
    }
    table.insert(self._subs, sub)

    local function activate()
        for _, other in ipairs(self._subs) do
            if other ~= sub then
                other.page.Visible = false
                tween(other.btn, 0.16, { TextColor3 = PALETTE.subtext }, EASE_SOFT)
            end
        end
        if self._ctx.closeOverlays then self._ctx.closeOverlays() end
        page.Visible = true
        sub.enter()
        tween(btn, 0.16, { TextColor3 = PALETTE.text }, EASE_SOFT)
        self._placeUnderline(btn, true)
    end
    btn.MouseEnter:Connect(function()
        if not page.Visible then tween(btn, 0.14, { TextColor3 = PALETTE.text }, EASE_SOFT) end
    end)
    btn.MouseLeave:Connect(function()
        if not page.Visible then tween(btn, 0.16, { TextColor3 = PALETTE.subtext }, EASE_SOFT) end
    end)
    -- Exposed so the interface search can bring a sub-page forward.
    sub.activate = activate
    btn.MouseButton1Click:Connect(activate)
    -- The buttons are auto sized, so translating one changes its width and the
    -- underline under it is suddenly the wrong length in the wrong place. Following
    -- the button's own size covers a language change, a font change and the first
    -- layout pass with one connection.
    local sizeConn = btn:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
        if page.Visible then self._placeUnderline(btn, false) end
    end)
    btn.Destroying:Connect(function() sizeConn:Disconnect() end)
    -- A palette pass paints every sub-tab the subtext colour it is registered under, so
    -- the open one claims its colour back on every frame of the change.
    addStatePainter(btn, function()
        btn.TextColor3 = page.Visible and shownColor("text") or shownColor("subtext")
    end)
    if self._ctx._refresh then
        table.insert(self._ctx._refresh, function()
            if page.Visible then self._placeUnderline(btn, false) end
        end)
    end
    if #self._subs == 1 then
        activate()
    end
    local subObj = Sub.new(page, self._ctx, leftCol, rightCol)
    subObj.entry = sub
    subObj.tab = self
    return subObj
end

local Window = {}
Window.__index = Window

function Window:tab(opts)
    opts = opts or {}
    local groupName = opts.group
    if groupName and not self.groups[groupName] then
        local header = Instance.new("TextLabel")
        header.BackgroundTransparency = 1
        header.Size = UDim2.new(1, 0, 0, 24)
        header.TextSize = 12
        header.TextXAlignment = Enum.TextXAlignment.Left
        header.LayoutOrder = nextOrder(self.sidebarList)
        header.Parent = self.sidebarList
        faced(header, "semibold")
        themed(header, "TextColor3", "subtext")
        localized(header, "Text", groupName, string.upper)
        local hpad = Instance.new("UIPadding")
        hpad.PaddingLeft = UDim.new(0, 12)
        hpad.PaddingTop = UDim.new(0, 8)
        hpad.Parent = header
        self.groups[groupName] = true
    end

    -- A holder the sidebar's list owns, with the row inside it. Same reason as the card slots
    -- in Sub:card: the list writes Position on whatever it manages, so a row parented straight
    -- into it cannot be moved, and the first opening brings the rows in one after another.
    local slide = Instance.new("Frame")
    slide.Size = UDim2.new(1, 0, 0, 38)
    slide.BackgroundTransparency = 1
    slide.BorderSizePixel = 0
    slide.LayoutOrder = nextOrder(self.sidebarList)
    slide.Parent = self.sidebarList

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 1, 0)
    btn.BackgroundTransparency = 1
    btn.AutoButtonColor = false
    btn.Text = ""
    btn.BorderSizePixel = 0
    btn.Parent = slide
    corner(btn, 8)

    -- The active tab is marked by the fill alone. The old build also drew a short
    -- accent bar on the left edge, which repeated what the fill already said and
    -- read as an artefact once the fill was there.
    --
    -- The fill is its own frame rather than the button's background: the button
    -- animates between three states, and a palette opacity written onto the same
    -- property would fight that animation.
    local fill = Instance.new("Frame")
    fill.Size = UDim2.new(1, 0, 1, 0)
    fill.BackgroundTransparency = 1
    fill.BorderSizePixel = 0
    fill.Parent = btn
    themed(fill, "BackgroundColor3", "accent", { fade = false })
    corner(fill, 8)
    local fillGrad = Instance.new("UIGradient")
    fillGrad.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.35),
        NumberSequenceKeypoint.new(0.65, 1),
        NumberSequenceKeypoint.new(1, 1),
    })
    fillGrad.Parent = fill

    local icon = makeIcon(btn, opts.icon, UDim2.new(0, 24, 0, 24), "iconDim")
    icon.AnchorPoint = Vector2.new(0, 0.5)
    icon.Position = UDim2.new(0, 14, 0.5, 0)
    icon.ZIndex = 2

    local label = Instance.new("TextLabel")
    label.BackgroundTransparency = 1
    label.Position = UDim2.new(0, 48, 0, 0)
    label.Size = UDim2.new(1, -56, 1, 0)
    label.TextSize = 15
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.TextTruncate = Enum.TextTruncate.AtEnd
    label.ZIndex = 2
    label.Parent = btn
    faced(label, "medium")
    themed(label, "TextColor3", "subtext", { fade = false })
    localized(label, "Text", opts.name)

    local tabPage = Instance.new("Frame")
    tabPage.Size = UDim2.new(1, 0, 1, 0)
    tabPage.BackgroundTransparency = 1
    tabPage.BorderSizePixel = 0
    tabPage.Visible = false
    tabPage.Parent = self.pages

    -- The bar sits in a holder so the underline has somewhere to live: the bar
    -- itself is laid out by a UIListLayout, and a line parented into it would be
    -- arranged as one more sub-tab.
    local subBarHolder = Instance.new("Frame")
    subBarHolder.Size = UDim2.new(1, 0, 0, 34)
    subBarHolder.BackgroundTransparency = 1
    subBarHolder.Parent = tabPage

    local subBar = Instance.new("Frame")
    subBar.Size = UDim2.new(1, 0, 0, 30)
    subBar.BackgroundTransparency = 1
    subBar.Parent = subBarHolder
    listLayout(subBar, 16, Enum.FillDirection.Horizontal)
    -- One underline that travels between the sub-tabs, instead of a line per
    -- button appearing and disappearing where it stands.
    local placeUnderline = slidingUnderline(subBarHolder, 2)

    local subDivider = Instance.new("Frame")
    subDivider.Position = UDim2.new(0, 0, 0, 34)
    subDivider.Size = UDim2.new(1, 0, 0, 1)
    subDivider.BackgroundTransparency = 0.3
    subDivider.BorderSizePixel = 0
    subDivider.Parent = tabPage
    themed(subDivider, "BackgroundColor3", "stroke")

    local subPages = Instance.new("Frame")
    subPages.Position = UDim2.new(0, 0, 0, 44)
    subPages.Size = UDim2.new(1, 0, 1, -44)
    subPages.BackgroundTransparency = 1
    subPages.Parent = tabPage

    local tabObj = setmetatable({
        _ctx = self, _subBar = subBar, _subPages = subPages, _subs = {},
        _placeUnderline = placeUnderline,
        name = opts.name, btn = btn, icon = icon, label = label, page = tabPage,
        -- The holder the row travels in. Only the first opening uses it.
        slide = slide, subBarHolder = subBarHolder,
    }, Tab)
    table.insert(self.tabs, tabObj)

    local function activate()
        for _, other in ipairs(self.tabs) do
            if other ~= tabObj then
                other.page.Visible = false
                if other.fill then tween(other.fill, 0.18, { BackgroundTransparency = 1 }, EASE_SOFT) end
                tween(other.label, 0.18, { TextColor3 = PALETTE.subtext }, EASE_SOFT)
                tintIcon(other.icon, PALETTE.iconDim)
            end
        end
        if self.closeOverlays then self.closeOverlays() end
        tabPage.Visible = true
        -- The page frame itself does not move. What settles in is the content of
        -- whichever sub-page is open on it, the same movement a sub-tab change makes, so
        -- changing tab and changing sub-tab read as the same thing happening.
        for _, entry in ipairs(tabObj._subs) do
            if entry.page.Visible and entry.enter then entry.enter() end
        end
        -- The fill slides in from the left as the section opens.
        fillGrad.Offset = Vector2.new(-0.6, 0)
        tween(fill, 0.2, { BackgroundTransparency = 0 }, EASE_SOFT)
        tween(fillGrad, 0.4, { Offset = Vector2.new(0, 0) }, EASE)
        tween(label, 0.18, { TextColor3 = PALETTE.text }, EASE_SOFT)
        tintIcon(icon, PALETTE.icon)
        self.title.Text = translate(opts.name)
        self._titlePhrase = opts.name
        if self.subtitle then
            self._subtitlePhrase = opts.subtitle or opts.group or ""
            self.subtitle.Text = translate(self._subtitlePhrase)
        end
        -- The bar was hidden while the page was, so the underline is placed once
        -- the layout has measured the buttons again.
        task.defer(function() placeUnderline(nil, false) end)
    end
    tabObj.fill = fill
    -- Exposed so the interface search can bring a tab forward.
    tabObj.activate = activate
    btn.MouseButton1Click:Connect(activate)
    btn.MouseEnter:Connect(function()
        if not tabPage.Visible then
            tween(fill, 0.14, { BackgroundTransparency = 0.55 }, EASE_SOFT)
            tween(label, 0.14, { TextColor3 = PALETTE.text }, EASE_SOFT)
            tintIcon(icon, PALETTE.icon)
        end
    end)
    btn.MouseLeave:Connect(function()
        if not tabPage.Visible then
            tween(fill, 0.18, { BackgroundTransparency = 1 }, EASE_SOFT)
            tween(label, 0.18, { TextColor3 = PALETTE.subtext }, EASE_SOFT)
            tintIcon(icon, PALETTE.iconDim)
        end
    end)
    -- The open tab wears the text and icon colours; every other tab wears subtext and
    -- iconDim, which is what they are registered under. So a palette pass paints the open
    -- one as though it were closed, and it has to claim its colours back afterwards, on
    -- every frame of the change rather than once at the end of it.
    addStatePainter(btn, function()
        local open = tabPage.Visible
        label.TextColor3 = open and shownColor("text") or shownColor("subtext")
        icon.ImageColor3 = open and shownColor("icon") or shownColor("iconDim")
        fill.BackgroundColor3 = shownColor("accent")
        fill.BackgroundTransparency = open and 0 or 1
    end)
    if #self.tabs == 1 then
        activate()
    end
    return tabObj
end

-- Interface search ------------------------------------------------------------
-- Every named control registers its label, its card and the page it lives on while
-- the interface is built. Typing in the sidebar filters that index, and picking a
-- result opens the tab, opens the sub-page, scrolls the column until the control is
-- in view and flashes it.
--
-- Labels are matched in both the language they were written in and the language they
-- are drawn in, so a translated build is searchable either way.
LAYOUT.searchResults = 7

-- Pull a row into view inside whichever column it belongs to.
local function scrollTo(row)
    local column = scrollerOf(row)
    if not column then return end
    local offset = row.AbsolutePosition.Y - column.AbsolutePosition.Y + column.CanvasPosition.Y
    local target = math.max(0, offset - 48)
    tween(column, 0.32, { CanvasPosition = Vector2.new(0, target) }, EASE)
end

-- Mark the control that was found. The flash sits behind the row and fades out, so
-- it never covers the thing it is pointing at.
local function flashRow(row)
    local glow = newInstance("Frame")
    glow.Name = randomName()
    glow.AnchorPoint = Vector2.new(0, 0.5)
    glow.Position = UDim2.new(0, -8, 0.5, 0)
    glow.Size = UDim2.new(1, 16, 1, 8)
    glow.BackgroundTransparency = 0.72
    glow.BorderSizePixel = 0
    glow.ZIndex = 0
    glow.Parent = row
    themed(glow, "BackgroundColor3", "accentSoft", { fade = false })
    corner(glow, 8)
    local out = tween(glow, 0.9, { BackgroundTransparency = 1 }, EASE_SOFT)
    out.Completed:Once(function() glow:Destroy() end)
end

function Window:_buildSearch(parent)
    local box = newInstance("Frame")
    box.Name = randomName()
    box.Size = UDim2.new(1, -20, 0, 30)
    box.Position = UDim2.new(0, 10, 0, 70)
    box.BorderSizePixel = 0
    box.Parent = parent
    themed(box, "BackgroundColor3", "control")
    corner(box, 8)

    local icon = makeIcon(box, "search", UDim2.new(0, 15, 0, 15), "iconDim")
    icon.AnchorPoint = Vector2.new(0, 0.5)
    icon.Position = UDim2.new(0, 9, 0.5, 0)

    local field = newInstance("TextBox")
    field.BackgroundTransparency = 1
    field.Position = UDim2.new(0, 30, 0, 0)
    field.Size = UDim2.new(1, -40, 1, 0)
    field.TextSize = 14
    field.Text = ""
    field.ClearTextOnFocus = false
    field.TextXAlignment = Enum.TextXAlignment.Left
    field.TextTruncate = Enum.TextTruncate.AtEnd
    field.Parent = box
    faced(field, "regular")
    themed(field, "TextColor3", "text")
    themed(field, "PlaceholderColor3", "subtext")
    localized(field, "PlaceholderText", "Search the interface..")
    self._searchField = field

    -- The result list floats in the overlay layer, like every other panel, so it is
    -- not clipped by the sidebar and draws over the content.
    local list = newGroup()
    list.Name = randomName()
    list.Size = UDim2.new(0, 260, 0, 0)
    list.AutomaticSize = Enum.AutomaticSize.Y
    list.BorderSizePixel = 0
    list.Visible = false
    list.ZIndex = 300
    list.Parent = self.overlay
    themed(list, "BackgroundColor3", "card")
    corner(list, 10)
    stroke(list, "stroke", 1, 0.35)
    local body = newInstance("Frame")
    body.BackgroundTransparency = 1
    body.Size = UDim2.new(1, 0, 0, 0)
    body.AutomaticSize = Enum.AutomaticSize.Y
    body.Parent = list
    listLayout(body, 2)
    padding(body, 6)

    local setAlpha = groupFade(list)
    setAlpha(0)

    -- Where the list sits when it is fully open, and how far below that it starts.
    -- Only the offset moves, so a result list that grows a row while it is opening
    -- still lands in the right place.
    local restY = 0
    local dropOffset = 0
    local LIST_DROP = 10

    local function draw()
        list.Position = UDim2.new(0, list.Position.X.Offset, 0, restY + dropOffset)
    end

    local shown = false
    local alphaNow = 0
    local fadeStop = nil
    local function setShown(want)
        if want == shown then return end
        shown = want
        if fadeStop then
            fadeStop()
            fadeStop = nil
        end
        if want then list.Visible = true end
        local fromAlpha = alphaNow
        local fromOffset = dropOffset
        local toAlpha = want and 1 or 0
        local toOffset = want and 0 or LIST_DROP
        if want and fromAlpha <= 0 then fromOffset = -LIST_DROP end
        local duration = want and 0.24 or 0.16
        local elapsed = 0
        dropOffset = fromOffset
        draw()
        fadeStop = addTicker(0, function(dt)
            elapsed += dt
            local t = math.min(elapsed / duration, 1)
            local eased = 1 - (1 - t) ^ 4
            alphaNow = fromAlpha + (toAlpha - fromAlpha) * eased
            dropOffset = fromOffset + (toOffset - fromOffset) * eased
            setAlpha(alphaNow)
            draw()
            if t >= 1 then
                if fadeStop then fadeStop() fadeStop = nil end
                if not shown then list.Visible = false end
            end
        end)
    end

    local function place()
        local origin = self.window.AbsolutePosition
        local at = box.AbsolutePosition
        restY = math.floor(at.Y - origin.Y + 36)
        list.Position = UDim2.new(0, math.floor(at.X - origin.X + 0.5), 0, restY + dropOffset)
    end

    local function jump(entry)
        setShown(false)
        field.Text = ""
        if entry.tab and entry.tab.activate then pcall(entry.tab.activate) end
        if entry.sub and entry.sub.activate then pcall(entry.sub.activate) end
        -- The columns have just been made visible, so their geometry lands a frame
        -- later and the scroll has to wait for it.
        task.defer(function()
            if not entry.row.Parent then return end
            scrollTo(entry.row)
            flashRow(entry.row)
        end)
    end

    local function render()
        for _, child in ipairs(body:GetChildren()) do
            if child:IsA("GuiObject") then child:Destroy() end
        end
        local query = string.lower(field.Text)
        if query == "" then
            setShown(false)
            return
        end
        local hits = 0
        for _, entry in ipairs(self._search) do
            if entry.row.Parent then
                local written = string.lower(entry.label)
                local drawn = string.lower(translate(entry.label))
                if written:find(query, 1, true) or drawn:find(query, 1, true) then
                    hits += 1
                    local hit = newInstance("TextButton")
                    hit.Size = UDim2.new(1, 0, 0, 34)
                    hit.BackgroundTransparency = 1
                    hit.BorderSizePixel = 0
                    hit.AutoButtonColor = false
                    hit.Text = ""
                    hit.LayoutOrder = hits
                    hit.Parent = body
                    themed(hit, "BackgroundColor3", "controlHover", { fade = false })
                    corner(hit, 7)

                    local name = newInstance("TextLabel")
                    name.BackgroundTransparency = 1
                    name.Position = UDim2.new(0, 10, 0, 3)
                    name.Size = UDim2.new(1, -20, 0, 17)
                    name.TextSize = 14
                    name.TextXAlignment = Enum.TextXAlignment.Left
                    name.TextTruncate = Enum.TextTruncate.AtEnd
                    name.Text = translate(entry.label)
                    name.ZIndex = 2
                    name.Parent = hit
                    faced(name, "medium")
                    themed(name, "TextColor3", "text")

                    local where = newInstance("TextLabel")
                    where.BackgroundTransparency = 1
                    where.Position = UDim2.new(0, 10, 0, 18)
                    where.Size = UDim2.new(1, -20, 0, 13)
                    where.TextSize = 12
                    where.TextXAlignment = Enum.TextXAlignment.Left
                    where.TextTruncate = Enum.TextTruncate.AtEnd
                    where.ZIndex = 2
                    where.Parent = hit
                    faced(where, "regular")
                    themed(where, "TextColor3", "subtext")
                    local trail = translate(entry.tab and entry.tab.name or "")
                    if entry.card then trail = trail .. "  /  " .. translate(entry.card) end
                    where.Text = trail

                    hit.MouseEnter:Connect(function() tween(hit, 0.12, { BackgroundTransparency = 0.45 }, EASE_SOFT) end)
                    hit.MouseLeave:Connect(function() tween(hit, 0.16, { BackgroundTransparency = 1 }, EASE_SOFT) end)
                    hit.MouseButton1Click:Connect(function() jump(entry) end)
                    if hits >= LAYOUT.searchResults then break end
                end
            end
        end
        if hits == 0 then
            local empty = newInstance("TextLabel")
            empty.BackgroundTransparency = 1
            empty.Size = UDim2.new(1, 0, 0, 28)
            empty.TextSize = 14
            empty.Parent = body
            faced(empty, "regular")
            themed(empty, "TextColor3", "subtext")
            localized(empty, "Text", "Nothing found")
        end
        place()
        setShown(true)
    end

    field:GetPropertyChangedSignal("Text"):Connect(render)
    field.FocusLost:Connect(function()
        -- Left open for a moment so a click on a result is not thrown away by the
        -- field losing focus first.
        task.delay(0.15, function()
            if field.Text == "" then setShown(false) end
        end)
    end)
    box:GetPropertyChangedSignal("AbsolutePosition"):Connect(place)
    self._closeSearch = function()
        field.Text = ""
        setShown(false)
    end
    return box
end

-- Show or hide the window: it travels, and all of it fades together.
--
-- The fade is one number on the body group, so the sidebar, the cards, the labels on them
-- and the outlines all go at the same rate. Both alternatives were tried and both are
-- worse. Fading the parts one at a time is thousands of property writes a frame and it
-- fights everything else that writes a transparency. Fading a sheet of background colour
-- over the top leaves the text under it fully solid behind a grey film, which does not
-- read as the window leaving, it reads as the window being covered up.
--
-- Nothing is scaled, though, and that part stands. A scale re-renders every glyph under
-- it at a fractional size on each frame, which is a shimmer, and it resamples the rounded
-- corner at sizes it was not drawn at, which is the striping that used to show along the
-- curve. Travel and a group fade do neither.
--
-- The resting position is remembered rather than assumed, because the window is
-- draggable and its resting place is wherever it was last left.
MOTION.windowIn = 0.32
MOTION.windowOut = 0.18

-- Everything the open and close animation fades, on one alpha.
--
-- The body group was the only one for a long time and the code read that way: one function in
-- _bodyFade, called from one place. The status strip is outside the body, because it is beside
-- the window rather than in it, and it still has to arrive and leave with the window. A list
-- rather than a second field, because the first open drives the same set one part at a time
-- and a third caller would otherwise be a third field and a third call site.
function Window:_addFade(fn)
    if type(fn) ~= "function" then return nil end
    self._fades = self._fades or {}
    self._fades[#self._fades + 1] = fn
    return fn
end

function Window:_dropFade(fn)
    if not self._fades then return end
    for i = #self._fades, 1, -1 do
        if self._fades[i] == fn then table.remove(self._fades, i) end
    end
end

function Window:_setAlpha(alpha)
    self._alphaNow = alpha
    if not self._fades then return end
    for _, fn in ipairs(self._fades) do pcall(fn, alpha) end
end

-- The first appearance, once, and only where a build asked for one.
--
-- Every other opening is Window:toggle: the whole window travels a little and fades on one
-- number, which is what something that happens on every press of a key should do. This happens
-- once a session, so it is allowed to be an event.
--
-- It is built out of the three things this kit will do and nothing it will not. No scaling,
-- because a scale re-renders every glyph under it at a fractional size and shimmers. No
-- transparency per part, because that is thousands of property writes a frame fighting
-- everything else that writes one. Whole pixels only, because the body is a render target and
-- a fractional offset softens every word on it.
--
-- So what is staggered is where each part comes from, not how solid it is. Every part travels
-- out of an edge that clips it, so it appears from inside the interface rather than sliding
-- across the screen: the sidebar and the tab rows out of the left, the heading down from the
-- top, each card up out of the bottom of the page, and the strip under the window last. One
-- alpha still carries the whole body, so there is no frame on which half of it is painted and
-- half is not.
--
-- The parts are gathered on the first frame, not when this is called. A script builds its tabs
-- and cards after UI.new has returned, so at the moment the debut starts there is nothing on
-- the page to bring in; one frame later there is all of it.
LAYOUT.debutSlide = 24
LAYOUT.debutCardRise = 46
-- start, length, in seconds. Listed in the order they arrive in.
MOTION.debutFrame = { 0, 0.34 }
MOTION.debutSidebar = { 0.04, 0.34 }
MOTION.debutRows = { 0.12, 0.26 }
-- Between one sidebar row and the next, and between one card and the next.
MOTION.debutRowStep = 0.035
MOTION.debutHeading = { 0.16, 0.28 }
MOTION.debutCards = { 0.24, 0.42 }
MOTION.debutCardStep = 0.07
MOTION.debutStrip = { 0.5, 0.3 }

-- One thing that travels, from an offset to where it belongs, over its own slice of time.
local function debutMover(frame, dx, dy, start, length)
    local home = frame.Position
    return {
        frame = frame,
        home = home,
        dx = dx,
        dy = dy,
        start = start,
        length = length,
        put = function(eased)
            frame.Position = UDim2.new(
                home.X.Scale, math.floor(home.X.Offset + dx * (1 - eased) + 0.5),
                home.Y.Scale, math.floor(home.Y.Offset + dy * (1 - eased) + 0.5)
            )
        end,
    }
end

function Window:_debut()
    local window = self.window
    local resting = self._resting or window.Position
    local from = WINDOW_LIFT(resting)
    local stripFade = self._statusFade

    -- The strip comes off the shared alpha for the length of this, because it is the one part
    -- outside the body and therefore the one part that can carry a fade of its own.
    if stripFade then self:_dropFade(stripFade) end

    self._open = true
    self._debutting = true
    window.Visible = true
    window.Position = from
    self:_setAlpha(0)
    if stripFade then stripFade(0) end
    if self._shadow then
        self._shadow.ImageTransparency = 1
        tween(self._shadow, 0.45, { ImageTransparency = 0.55 }, EASE_SOFT)
    end

    local movers = {}
    local gathered = false
    local elapsed = 0

    local function add(frame, dx, dy, start, length)
        if not frame then return end
        movers[#movers + 1] = debutMover(frame, dx, dy, start, length)
    end

    -- Everything on the page, in the order it is read in.
    local function gather()
        gathered = true

        add(self._sidebar, -(self._sidebar and self._sidebar.Size.X.Offset or 0), 0,
            MOTION.debutSidebar[1], MOTION.debutSidebar[2])

        -- The sidebar rows, one after another.
        --
        -- The button, not the holder. The holder is what the sidebar's list manages, and moving
        -- something a UIListLayout owns is a fight: the list writes the position back on its next
        -- reflow, so the row jitters between the two of them for the length of the animation.
        -- That is what the holder exists for, and it is the same arrangement the cards use.
        do
            local step = 0
            for _, tabObj in ipairs(self.tabs) do
                if tabObj.btn then
                    add(tabObj.btn, -LAYOUT.debutSlide, 0,
                        MOTION.debutRows[1] + step * MOTION.debutRowStep, MOTION.debutRows[2])
                    step += 1
                end
            end
        end

        add(self.title, 0, -LAYOUT.debutSlide, MOTION.debutHeading[1], MOTION.debutHeading[2])
        -- A beat behind the title, so the heading reads as two lines arriving rather than as
        -- one block of text moving.
        add(self.subtitle, 0, -LAYOUT.debutSlide,
            MOTION.debutHeading[1] + 0.05, MOTION.debutHeading[2])

        -- The cards of whatever page is open, one at a time, left column first and then right,
        -- interleaved so the two columns fill together rather than one and then the other.
        --
        -- Each card is inside a slot the column's layout owns, so moving the card itself is
        -- free: the list keeps the slot where it belongs and never writes to the card. See
        -- Sub:card. The page clips at the bottom, so a card starting below the fold appears out
        -- of the page's own edge.
        do
            local order = {}
            for _, tabObj in ipairs(self.tabs) do
                if tabObj.page and tabObj.page.Visible then
                    -- The sub-tab bar with the heading, because it reads as part of it.
                    add(tabObj.subBarHolder, 0, -LAYOUT.debutSlide,
                        MOTION.debutHeading[1] + 0.04, MOTION.debutHeading[2])
                    for _, entry in ipairs(tabObj._subs) do
                        if entry.page.Visible then
                            local cols = {}
                            for _, column in ipairs(entry.columns:GetChildren()) do
                                if column:IsA("ScrollingFrame") then cols[#cols + 1] = column end
                            end
                            -- Left before right at the same height, which is the order the
                            -- page is read in.
                            table.sort(cols, function(a, b)
                                return a.Position.X.Scale < b.Position.X.Scale
                            end)
                            local rows = {}
                            for index, column in ipairs(cols) do
                                local slots = {}
                                for _, node in ipairs(column:GetChildren()) do
                                    if node:IsA("Frame") then slots[#slots + 1] = node end
                                end
                                table.sort(slots, function(a, b)
                                    return a.LayoutOrder < b.LayoutOrder
                                end)
                                for depth, holder in ipairs(slots) do
                                    -- One child, and it is the card. Walked rather than asked
                                    -- for by name, because the slot paints nothing and holds
                                    -- nothing else.
                                    local card = nil
                                    for _, node in ipairs(holder:GetChildren()) do
                                        if node:IsA("Frame") then
                                            card = node
                                            break
                                        end
                                    end
                                    if card then
                                        rows[#rows + 1] = {
                                            card = card,
                                            -- Depth first, then column, so the top of both
                                            -- columns arrives before the second row of either.
                                            rank = depth * 10 + index,
                                        }
                                    end
                                end
                            end
                            table.sort(rows, function(a, b) return a.rank < b.rank end)
                            for _, row in ipairs(rows) do order[#order + 1] = row.card end
                        end
                    end
                end
            end
            for index, card in ipairs(order) do
                add(card, 0, LAYOUT.debutCardRise,
                    MOTION.debutCards[1] + (index - 1) * MOTION.debutCardStep,
                    MOTION.debutCards[2])
            end
        end

        add(self._status, 0, 12, MOTION.debutStrip[1], MOTION.debutStrip[2])

        -- Every part is put at its start here rather than when the debut began, because until
        -- this frame most of them did not exist.
        for _, mover in ipairs(movers) do mover.put(0) end
    end

    -- What to do if something interrupts this. Pressing the show and hide key half a second in
    -- is a thing people do, and toggle only knows about the window's own travel and the shared
    -- alpha: without this a card would be left parked below the fold for the rest of the
    -- session, which is a card nobody can reach.
    self._debutSnap = function()
        self._debutSnap = nil
        self._debutting = false
        self._debutDone = true
        for _, mover in ipairs(movers) do mover.frame.Position = mover.home end
        if stripFade then
            stripFade(self._alphaNow or 1)
            self:_addFade(stripFade)
        end
    end

    if self._fadeStop then
        self._fadeStop()
        self._fadeStop = nil
    end
    self._fadeStop = addTicker(0, function(dt)
        if not gathered then
            gather()
            -- Nothing is advanced on the frame the parts were placed, so the first thing drawn
            -- is the first frame of the animation and not the finished interface for a moment.
            return
        end
        elapsed += dt

        local f = math.min(elapsed / MOTION.debutFrame[2], 1)
        local frameEase = 1 - (1 - f) ^ 4
        self:_setAlpha(frameEase)
        window.Position = UDim2.new(
            from.X.Scale,
            math.floor(from.X.Offset + (resting.X.Offset - from.X.Offset) * frameEase + 0.5),
            from.Y.Scale,
            math.floor(from.Y.Offset + (resting.Y.Offset - from.Y.Offset) * frameEase + 0.5)
        )

        local settled = f >= 1
        for _, mover in ipairs(movers) do
            local t = (elapsed - mover.start) / mover.length
            if t < 1 then settled = false end
            t = math.clamp(t, 0, 1)
            mover.put(1 - (1 - t) ^ 4)
        end

        if stripFade then
            local st = math.clamp((elapsed - MOTION.debutStrip[1]) / MOTION.debutStrip[2], 0, 1)
            stripFade(1 - (1 - st) ^ 4)
        end

        if settled then
            if self._fadeStop then self._fadeStop() self._fadeStop = nil end
            -- Everything back on the shared alpha and on its resting place, so the next hide
            -- takes the strip with it and nothing is left a rounding error off home.
            if self._debutSnap then self._debutSnap() end
        end
    end)
end

function Window:toggle(show)
    local window = self.window
    if show == nil then show = not window.Visible end
    show = show and true or false
    if show == self._open then return end
    self._open = show
    -- A debut in flight is put where it was going before this takes the properties over.
    if self._debutSnap then self._debutSnap() end
    if self.closeOverlays then self.closeOverlays() end

    local shade = self._shadow
    if show and not self._resting then self._resting = window.Position end
    local resting = self._resting or window.Position

    -- One driver for the travel and the fade, so they cannot come apart, and it starts
    -- from wherever the window currently is, which is what lets a fast off and on pick up
    -- mid animation instead of starting over.
    if self._fadeStop then
        self._fadeStop()
        self._fadeStop = nil
    end
    local from = self._alphaNow or (show and 0 or 1)
    local target = show and 1 or 0
    local liftFrom = show and WINDOW_LIFT(resting) or window.Position
    local liftTo = show and resting or WINDOW_LIFT(resting)
    local duration = show and MOTION.windowIn or MOTION.windowOut

    if show then
        window.Visible = true
        window.Position = liftFrom
        if shade then tween(shade, 0.3, { ImageTransparency = 0.55 }, EASE_SOFT) end
    else
        self._resting = window.Position
        resting = self._resting
        liftTo = WINDOW_LIFT(resting)
        if shade then tween(shade, 0.14, { ImageTransparency = 1 }, EASE_SOFT) end
    end

    local elapsed = 0
    self._fadeStop = addTicker(0, function(dt)
        elapsed += dt
        local t = math.min(elapsed / duration, 1)
        -- Arriving settles, leaving accelerates away. A close that eases out reads as
        -- the window being dragged shut.
        local eased = show and (1 - (1 - t) ^ 4) or (t * t)
        self:_setAlpha(from + (target - from) * eased)
        -- Whole pixels on every frame of the travel. A group blitted between two pixel
        -- rows is the one thing that would soften the text inside it.
        window.Position = UDim2.new(
            liftFrom.X.Scale,
            math.floor(liftFrom.X.Offset + (liftTo.X.Offset - liftFrom.X.Offset) * eased + 0.5),
            liftFrom.Y.Scale,
            math.floor(liftFrom.Y.Offset + (liftTo.Y.Offset - liftFrom.Y.Offset) * eased + 0.5)
        )
        if t >= 1 then
            if self._fadeStop then self._fadeStop() self._fadeStop = nil end
            if not self._open then
                window.Visible = false
                -- Put it back, so the next open starts from the resting place and a drag
                -- never inherits the lifted offset.
                window.Position = resting
            end
        end
    end)
end

-- Recolour every part that follows this palette key, then refresh the dynamic
-- controls (toggles, segmented, lists) that pick colours at runtime.
--
-- Only parts passed to themed(inst, prop, key) follow the palette, and they are
-- read from that key's registry, so one colour never bleeds onto unrelated
-- elements and no walk over the GUI tree is needed.
-- The repaint eases into the new colour rather than snapping to it.
--
-- The palette value itself is updated at once, because everything that reads
-- PALETTE while building or animating has to see the value it is heading for. Only
-- the walk over the registry is interpolated, on the shared frame driver, which is
-- one pass per key per frame for about a tenth of a second. A second change to the
-- same key while the first is still running picks up from the colour that is
-- actually on screen, so dragging a colour picker trails the pointer smoothly
-- instead of stepping.
-- Long enough to read as a colour moving rather than a colour being replaced. A tenth
-- of a second is six frames, which is short enough that the eye takes it as a step.
MOTION.theme = 0.22
local themeFade = {}
local themeFadeStop = nil

-- What a key is showing right now. During a change that is the eased colour, not the one
-- it is heading for, which is what lets the state painters follow the ease.
shownColor = function(key)
    local state = themeFade[key]
    return (state and state.shown) or PALETTE[key]
end

-- Set while a frame of the fade is walking several keys, so the state painters run once for
-- the frame rather than once per key. A preset moves fourteen keys at a time, and every one of
-- them used to drag the whole painter list behind it: fourteen sweeps a frame doing thirteen
-- sweeps worth of nothing.
local paintersHeld = false

local function paintKey(key, color, alpha)
    local reg = THEME_REG[key]
    if not reg then return end
    tagWalk(reg, function(inst, entry)
        if entry.paint ~= false then inst[entry.prop] = color end
        if entry.fade then
            fadeProp(inst, entry.prop, alpha)
        end
    end)
    -- The shading over a filled bar is derived from the accent, so it follows the colour
    -- that is on screen rather than the one being headed for. Rebuilding it once at the
    -- start instead meant the bar's fill eased while its shading jumped.
    if key == "accent" then refreshBarRamps(color) end
    -- Last, because the pass above has just painted a few of these as though they had no
    -- state of their own. Held back when the caller is walking several keys in one frame and
    -- will run them itself once it is done.
    if not paintersHeld then runStatePainters() end
end

local function driveThemeFade(dt)
    local running = false
    paintersHeld = true
    for key, state in pairs(themeFade) do
        state.t = math.min(state.t + dt / MOTION.theme, 1)
        -- Cubic out: most of the distance early, the last of it gently, which is what
        -- makes a colour change read as one movement.
        local a = 1 - (1 - state.t) ^ 3
        state.shown = state.from:Lerp(state.to, a)
        state.shownAlpha = state.alphaFrom + (state.alphaTo - state.alphaFrom) * a
        paintKey(key, state.shown, state.shownAlpha)
        if state.t >= 1 then
            themeFade[key] = nil
        else
            running = true
        end
    end
    paintersHeld = false
    runStatePainters()
    if not running and themeFadeStop then
        themeFadeStop()
        themeFadeStop = nil
    end
end

local function applyKey(key, new, alpha)
    local reg = THEME_REG[key]
    if not reg then return end
    local running = themeFade[key]
    local from = (running and running.shown) or PALETTE[key]
    local alphaFrom = (running and running.shownAlpha) or PALETTE_A[key] or 1

    PALETTE[key] = new
    PALETTE_A[key] = alpha

    if from == new and alphaFrom == alpha then
        themeFade[key] = nil
        paintKey(key, new, alpha)
        return
    end
    themeFade[key] = {
        from = from, to = new,
        alphaFrom = alphaFrom, alphaTo = alpha,
        shown = from, shownAlpha = alphaFrom,
        t = 0,
    }
    if not themeFadeStop then
        themeFadeStop = addTicker(0, driveThemeFade)
    end
end

function Window:setColor(key, rgb)
    if not THEME_REG[key] or key == "accentSoft" then return end
    local new = (typeof(rgb) == "Color3") and rgb or colorOf(rgb)
    local alpha = (type(rgb) == "table" and rgb[4]) or PALETTE_A[key] or 1
    applyKey(key, new, alpha)

    -- The corrected accent depends on both the accent and the surface behind it, so
    -- either one moving recomputes it.
    if key == "accent" or key == "background" then
        applyKey("accentSoft", legibleOn(PALETTE.accent, PALETTE.background), PALETTE_A.accent)
    end

    -- The repaint list, not the refresh list.
    --
    -- This used to run refresh: every control on the interface, re-read and re-rendered, on
    -- every call. A colour is not a value, so none of those controls had anything to re-read,
    -- and each one repainted itself with a tween anyway. Harmless for a button press and
    -- ruinous for a drag, because a colour picker or an opacity slider calls setColor once per
    -- frame for as long as the pointer is down: the cost was a tween per control per frame. On
    -- a page of two hundred controls that is several hundred live tweens a second, climbing
    -- for as long as the drag lasts. It raises no error, it takes the client down, and
    -- dragging the opacity slider in the worked example was enough to do it.
    --
    -- What is left on this path is the handful of things that genuinely read a colour and
    -- cannot be painted by key: a picker's swatch and its hex readout. Everything whose colour
    -- depends on its own state is handled by the state painters, which already run at the end
    -- of every palette pass and write straight, with no tween and no allocation.
    --
    -- The harness measures it: sixty frames of dragging a palette key has to stay under a few
    -- hundred tweens. Before this it was two thousand on a window with thirty controls.
    if self._repaint then
        for _, fn in ipairs(self._repaint) do pcall(fn) end
    end
    self._dirty = true
end

function Window:getColor(key)
    local c = PALETTE[key]
    return { math.floor(c.R * 255 + 0.5), math.floor(c.G * 255 + 0.5), math.floor(c.B * 255 + 0.5), PALETTE_A[key] or 1 }
end

-- Restore the default palette and full opacity for every key.
function Window:resetTheme()
    for key, def in pairs(DEFAULTS) do
        self:setColor(key, { math.floor(def.R * 255 + 0.5), math.floor(def.G * 255 + 0.5), math.floor(def.B * 255 + 0.5), 1 })
    end
end

-- Apply a named preset. A preset only names the keys it changes, so one that sets
-- the accent alone leaves the rest of the palette where the user put it. The change
-- runs through setColor, so it eases in like any other.
function Window:applyTheme(name)
    local preset = THEMES[name]
    if not preset then return false end
    for key, rgb in pairs(preset) do
        if DEFAULTS[key] and type(rgb) == "table" then
            self:setColor(key, { rgb[1], rgb[2], rgb[3], rgb[4] or PALETTE_A[key] or 1 })
        end
    end
    self.theme = name
    self._dirty = true
    return true
end

function Window:getTheme()
    return self.theme
end

-- A settings page, built in.
--
-- The window's own key, the palette, the configs and the language: none of it belongs to
-- the script, all of it was being written out by every script that used the kit, and
-- because each one wrote it slightly differently the same page looked different in every
-- product. So the kit ships the page and a caller drops whatever it does not want.
--
-- The tab and its page both come back, so a script can hang its own cards on the same page
-- instead of having to choose between this and a page of its own. The page is returned
-- rather than looked up again because tab:sub(name) builds a new sub-tab every time it is
-- called: asking for "Settings" a second time would put a second identical sub-tab beside
-- the first.
--
-- opts.name / icon / group / subtitle / page   how the tab and its sub-page are labelled
-- opts.window = false    drop the show and hide key and the unload button
-- opts.theme  = false    drop the palette card, or a table passed on to Card:theme
-- opts.configs = false   drop the config manager
-- opts.language          list of { label = "English", code = "en" } for the language card
function Window:settingsTab(opts)
    opts = opts or {}
    local tab = self:tab({
        name = opts.name or "Settings",
        icon = opts.icon or "settings",
        group = opts.group or "Other",
        subtitle = opts.subtitle or "Interface options",
    })
    local page = tab:sub(opts.page or "Settings")

    if opts.window ~= false then
        local card = page:card({ title = "Window", icon = "settings", subtitle = "Show and hide", column = "left" })
        -- Kept out of the keybind panel. That panel is a list of what the script binds, and
        -- the key that shows and hides the interface is not one of those: it is chrome, it
        -- belongs to the kit rather than to the product, and listing it alongside the real
        -- binds pads the panel with a row nobody put there.
        card:keybind("Toggle Interface", function()
            return self.toggleKey and self.toggleKey.Name
        end, function(name)
            local ok, key = pcall(function() return Enum.KeyCode[name] end)
            if ok and key then
                self.toggleKey = key
                self:markDirty()
            end
        end, { list = false })
        card:button("Unload", function() self:unload() end)
    end

    if opts.theme ~= false then
        local card = page:card({ title = "Theme", icon = "palette", subtitle = "Every key is live", column = "left" })
        card:theme(type(opts.theme) == "table" and opts.theme or nil)
    end

    if opts.configs ~= false then
        -- default is always offered, whether or not it has been written yet, because it
        -- is the name the kit itself saves under and a list that hides it until the first
        -- save leaves the card with nothing in it.
        local selected = self:getAutoLoad() or "default"
        local newName = ""
        local function names()
            local list = { "default" }
            for _, name in ipairs(self:listConfigs()) do
                if name ~= "default" then list[#list + 1] = name end
            end
            return list
        end

        local card = page:card({ title = "Configs", icon = "device-floppy", subtitle = "Per game", column = "right" })
        card:dropdown("Config", names, function() return selected end, function(v) selected = v end, { search = true })
        card:input("Name", "new config name", function() return newName end, function(v) newName = v end)
        card:button("Create", function()
            if newName == "" then return end
            if self:saveConfig(newName) then
                selected = newName
                newName = ""
                self:refreshAll()
            end
        end)
        card:button("Save", function() self:saveConfig(selected) end)
        card:button("Load", function()
            if self:loadConfig(selected) then self:refreshAll() end
        end)
        card:button("Delete", function()
            -- default is the fallback the kit loads from, so it stays.
            if selected ~= "default" and self:deleteConfig(selected) then
                selected = "default"
                self:refreshAll()
            end
        end)
        card:divider()
        card:toggle("Load on launch", function() return self:getAutoLoad() ~= nil end, function(v)
            self:setAutoLoad(v and selected or nil)
        end)
        card:toggle("Auto save", function() return self:getAutoSave() ~= nil end, function(v)
            self:setAutoSave(v and selected or nil)
        end)
    end

    -- Only when the caller names the languages, and only when there is more than one of
    -- them. The kit knows which codes have been registered but not what to call them on
    -- screen: a language's name belongs in its own language, so "Русский" rather than
    -- "ru", and that is the caller's to supply.
    local langs = opts.language
    if type(langs) == "table" and #langs > 1 then
        local labels = {}
        for _, entry in ipairs(langs) do labels[#labels + 1] = entry.label end
        local card = page:card({ title = "Language", icon = "world", subtitle = "Re-labels without a rebuild", column = "right" })
        card:list(labels, function()
            local code = self:getLocale()
            for _, entry in ipairs(langs) do
                if entry.code == code then return entry.label end
            end
            return labels[1]
        end, function(label)
            for _, entry in ipairs(langs) do
                if entry.label == label then self:setLocale(entry.code) return end
            end
        end, { search = false })
    end

    -- Opacity, and it is part of the palette rather than a separate idea: every key carries
    -- it as a fourth value. These two drive the fourth number on the two keys that make the
    -- window itself see through, which is the only pair anyone reaches for.
    if opts.opacity ~= false then
        local card = page:card({
            title = "Opacity",
            icon = "droplet",
            subtitle = "See through the window",
            column = "left",
        })
        local function write(value)
            for _, key in ipairs({ "background", "card" }) do
                local rgb = self:getColor(key)
                self:setColor(key, { rgb[1], rgb[2], rgb[3], value })
            end
        end
        -- Held here rather than read back off the palette. getColor would do, but the slider
        -- writes two keys and reading one of them back to find out where the slider is makes
        -- the control depend on which of the two it happened to write last.
        local shown = 1
        card:slider("Window", 40, 100, function()
            return math.floor(shown * 100 + 0.5)
        end, function(percent)
            shown = percent / 100
            write(shown)
        end, 0, function(value) return value .. "%" end)
        -- refreshAll, because this writes the value the slider above reads. Without it the
        -- window goes opaque and the control that says how opaque it is keeps its old number.
        card:button("Opaque", function()
            shown = 1
            write(1)
            self:refreshAll()
        end)
        card:divider()
        card:button("Clear Recent Colours", function()
            Interface.clearRecentColors()
            self:refreshAll()
        end)
    end

    -- One toggle per detached panel, and the card fills itself.
    --
    -- Which panels exist is not known here, and it cannot be: a script calls settingsTab
    -- wherever it likes, and the worked example calls it before it builds its watermark and
    -- its HUDs. So the card takes the panels that already exist and then stays open, and
    -- overlayShell adds a row to it for every panel built afterwards. Either order gives the
    -- same card, and a script does not have to know which order it used.
    if opts.panels ~= false then
        local card = page:card({
            title = "Panels",
            icon = "layout-dashboard",
            subtitle = "Drag any panel to move it",
            column = "right",
        })
        self._panelsCard = card
        for name in pairs(self._overlays) do
            self:_panelRow(name)
        end
    end

    -- The clipboard carries exactly what a file carries, and it is how a setup actually gets
    -- shared: a screenshot of a config is no use to anybody and neither is a file path on
    -- somebody else's machine.
    if opts.share ~= false then
        local card = page:card({
            title = "Share",
            icon = "copy",
            subtitle = "Through the clipboard",
            column = "right",
        })
        card:button("Copy Config", function()
            if self:exportConfig() then
                self:notify({ title = "Config", text = "Copied to the clipboard", icon = "copy" })
            else
                self:notify({ title = "Config", text = "Could not read the config", icon = "x" })
            end
        end)
        local pasted = ""
        card:input("Paste", "paste a config here", function() return pasted end, function(value)
            pasted = value
        end)
        card:button("Load Pasted", function()
            if pasted == "" then return end
            if self:importConfig(pasted) then
                pasted = ""
                self:refreshAll()
                self:notify({ title = "Config", text = "Loaded", icon = "check" })
            else
                self:notify({ title = "Config", text = "That is not a config", icon = "x" })
            end
        end)
    end

    -- The type on a sub-page of its own, as one card.
    --
    -- It is four weight rows and a family list, and none of it is something anyone changes
    -- twice. Sitting on the main page it pushed the palette, the configs and the language
    -- down past the fold, which is the wrong trade: the settings people actually open are the
    -- colours and the configs. So the fine detail moves one sub-tab across, where it is one
    -- click away and not in the way.
    --
    -- One card and not two. The second one held a sentence and two buttons, and the sentence
    -- was there to explain why the two buttons were not on the card they act on. They are on
    -- it now, under a divider, and the page has one thing on it instead of two.
    --
    -- Built after the main page, so the main page is the one that opens: the first sub-tab
    -- asked for is the active one.
    if opts.type ~= false then
        local detail = tab:sub(opts.typePage or "Type")
        detail:card({
            title = "Type",
            icon = "quote",
            subtitle = "Family, weight and size",
            column = "left",
        }):typography(type(opts.type) == "table" and opts.type or nil)
    end

    return tab, page
end

-- Re-apply every control's visual from its current value (used after loading a
-- config so toggles, sliders, dropdowns reflect the loaded state).
function Window:refreshAll()
    for _, fn in ipairs(self._refresh) do pcall(fn) end
    -- The colour readers too, because a loaded config brings a palette with it.
    for _, fn in ipairs(self._repaint) do pcall(fn) end
    -- The page heading is not a control, so it is re-read here as well: a
    -- language change goes through this path too.
    if self.title and self._titlePhrase then self.title.Text = translate(self._titlePhrase) end
    if self.subtitle and self._subtitlePhrase then self.subtitle.Text = translate(self._subtitlePhrase) end
end

-- Language for this window. The phrase table is shared by the whole session, so
-- this sets the session language and remembers the choice with the config.
function Window:setLocale(code)
    Interface.setLocale(code)
    self.locale = code
    self._dirty = true
end

function Window:getLocale()
    return Interface.getLocale()
end

-- Bind a control to a saved flag. Returns get and set backed by window.flags so
-- the value is persisted by save/load. Usage:
--   local g, s = window:flag("aimbot", false); card:toggle("Aimbot", g, s)
function Window:flag(key, default)
    if self.flags[key] == nil then
        self.flags[key] = default
    end
    return function() return self.flags[key] end, function(v) self.flags[key] = v; self._dirty = true end
end

-- Marks the config dirty so auto save will persist it on its next tick. Controls
-- with their own setter (colour pickers) call this so their changes are saved too.
function Window:markDirty() self._dirty = true end

-- Re-fit the interface to the screen it is on: the window's size, the sidebar's
-- share of it, and every detached panel pulled back inside the viewport. Runs on a
-- timer and can be called by hand after a change nothing else notices.
--
-- A window the user has dragged is left where they put it. Re-centring something
-- somebody deliberately moved is worse than a window slightly off centre.
function Window:refit(force)
    local view = viewport()
    local known = self._view
    if not force and known and known.X == view.X and known.Y == view.Y then return end
    self._view = view

    -- What the strip under the window takes, which is nothing when there is no strip.
    local reserve = self._statusLift or 0
    local winW, winH = windowFit(view, reserve)
    local sideW = sidebarFit(winW)
    self.window.Size = UDim2.new(0, winW, 0, winH)
    if self._sidebar then self._sidebar.Size = UDim2.new(0, sideW, 1, 0) end
    if self._content then
        self._content.Position = UDim2.new(0, sideW, 0, 0)
        self._content.Size = UDim2.new(1, -sideW, 1, 0)
    end

    if not self._moved then
        -- Half the reserve off the centre, so the window and the strip under it are centred
        -- as one object rather than the window being centred and the strip hanging below it.
        local centred = UDim2.new(
            0, math.floor(view.X / 2),
            0, math.floor(view.Y / 2) - (reserve // 2)
        )
        self._resting = centred
        if self._open then self.window.Position = centred end
    end

    for name, frame in pairs(self._overlays) do
        if frame and frame.Parent then
            local rest = self._overlayRest[name] or frame.Position
            local kept = clampToView(rest, frame.AbsoluteSize, view)
            if kept ~= rest then
                self._overlayRest[name] = kept
                if frame.Visible then frame.Position = kept end
                self._dirty = true
            end
        end
    end
    if self.closeOverlays then self.closeOverlays() end
end

local CONFIG_ROOT = "NewReality/configs"
-- Configs are stored per game so one game's configs never appear in another.
local function placeFolder()
    -- Key by GameId (universe), not PlaceId, so every place of one game (e.g. a
    -- separate lobby place and the main game place) shares the same configs.
    return CONFIG_ROOT .. "/" .. tostring(game.GameId)
end
local function configPath(name)
    return placeFolder() .. "/" .. name .. ".json"
end
local function ensureConfigDir()
    pcall(function()
        if not (makefolder and isfolder) then return end
        if not isfolder("NewReality") then makefolder("NewReality") end
        if not isfolder(CONFIG_ROOT) then makefolder(CONFIG_ROOT) end
        local d = placeFolder()
        if not isfolder(d) then makefolder(d) end
    end)
end

-- What a config holds: the flags, the palette with its opacity, the show/hide key,
-- the language, the theme preset, the recent colours and the position and visibility
-- of every detached panel. The window's own position is left out on purpose so it
-- always opens centred.
--
-- Built here rather than inside saveConfig, because the clipboard export and the
-- file write have to be the same thing. A config copied out of one session and
-- pasted into another that restores less than a file would is a trap.
function Window:snapshot()
    -- Snapshot the current theme so colours are restored on load too. The fourth
    -- number is the key's opacity, which the old format dropped and which is the
    -- difference between a translucent window and an opaque one.
    local theme = {}
    for key in pairs(DEFAULTS) do
        local c = PALETTE[key]
        theme[key] = {
            math.floor(c.R * 255 + 0.5),
            math.floor(c.G * 255 + 0.5),
            math.floor(c.B * 255 + 0.5),
            PALETTE_A[key] or 1,
        }
    end
    -- The resting place of each detached panel, not wherever the show/hide animation
    -- has the frame at this instant. Writing the live position could persist a panel
    -- halfway through leaving.
    local overlays = {}
    for key, frame in pairs(self._overlays) do
        if frame and frame.Parent then
            local p = self._overlayRest[key] or frame.Position
            overlays[key] = { p.X.Scale, p.X.Offset, p.Y.Scale, p.Y.Offset, frame.Visible and 1 or 0 }
        end
    end
    local recent = {}
    for i, hex in ipairs(recentColors) do recent[i] = hex end
    return {
        build = Interface.version,
        flags = self.flags,
        theme = theme,
        themeName = self.theme,
        toggleKey = (typeof(self.toggleKey) == "EnumItem") and self.toggleKey.Name or nil,
        locale = Interface.getLocale(),
        -- The type as well as the palette. Weight is as much a matter of taste as colour
        -- is, and a choice that had to be made again on every launch is not a choice the
        -- kit was really offering.
        font = Interface.getFont(),
        weights = Interface.roleWeights(),
        textScale = Interface.getTextScale(),
        recent = recent,
        overlays = overlays,
        -- Where the window itself was left, and only when somebody moved it.
        --
        -- It used to be left out on purpose, so the window always opened centred. That is the
        -- right default and it is still what an untouched window does, but it is the wrong answer
        -- for a window that was deliberately dragged out of the way: the config remembers where
        -- every panel was put and then forgets the one thing the user moved first. The resting
        -- place is written rather than the live position, so a snapshot taken mid animation does
        -- not persist a window halfway through opening.
        window = self._moved and self._resting and {
            self._resting.X.Scale,
            self._resting.X.Offset,
            self._resting.Y.Scale,
            self._resting.Y.Offset,
        } or nil,
    }
end

function Window:saveConfig(name, silent)
    if type(name) ~= "string" or name == "" then return false end
    if type(writefile) ~= "function" then log("warn", "executor has no writefile") return false end
    local payload = self:snapshot()
    local ok, err = pcall(function()
        ensureConfigDir()
        writefile(configPath(name), HttpService:JSONEncode(payload))
    end)
    -- Some executors sandbox writefile and silently drop the file without
    -- raising an error, so verify the file is actually present afterwards.
    if ok and type(isfile) == "function" and not isfile(configPath(name)) then
        ok = false
        err = "file missing after write (executor blocked writefile?)"
    end
    if ok then
        if not silent then log("info", "saved config: " .. configPath(name)) end
    else
        log("warn", "saveConfig failed: " .. tostring(err))
    end
    return ok
end

-- Apply a decoded snapshot. Shared by loadConfig and by the clipboard import, so
-- the two cannot drift apart.
function Window:restore(data)
    if type(data) ~= "table" then return false end
    -- New format is { flags = , theme = , ... }; old format was just the flags table.
    local flags = (type(data.flags) == "table") and data.flags or data
    for k, v in pairs(flags) do self.flags[k] = v end
    -- The language first, so every label the theme pass repaints is already in
    -- the right words.
    if type(data.locale) == "string" and data.locale ~= "" then
        Interface.setLocale(data.locale)
        self.locale = data.locale
    end
    -- Then the type, for the same reason and one more: both of these re-face every label
    -- in the interface, and doing that after the colour pass would repaint work that is
    -- about to be thrown away.
    if type(data.font) == "string" and data.font ~= "" then
        Interface.setFont(data.font)
    end
    if type(data.weights) == "table" then
        for role, weight in pairs(data.weights) do
            Interface.setRoleWeight(role, weight)
        end
    end
    -- Absent in a config written before the size was a setting, which is the same as the
    -- default, so there is nothing to migrate.
    if type(data.textScale) == "number" then
        Interface.setTextScale(data.textScale)
    end
    -- Restore the saved theme colours through the themed registry. A three
    -- number entry comes from an older config and means full opacity.
    if type(data.theme) == "table" then
        for key, rgb in pairs(data.theme) do
            if DEFAULTS[key] and type(rgb) == "table" then
                self:setColor(key, rgb)
            end
        end
    end
    if type(data.themeName) == "string" then self.theme = data.themeName end
    if type(data.toggleKey) == "string" then
        local okKey, key = pcall(function() return Enum.KeyCode[data.toggleKey] end)
        if okKey and key then self.toggleKey = key end
    end
    if type(data.recent) == "table" then
        table.clear(recentColors)
        for _, hex in ipairs(data.recent) do
            if type(hex) == "string" and #hex == 6 then
                recentColors[#recentColors + 1] = hex
            end
        end
    end
    -- Where the window was left, if it was ever moved. Clamped on the way in for the same reason
    -- the panels are: a config written on a wide monitor must not put it somewhere this screen
    -- has no pixels. _moved is set as well, so the refit timer leaves it where the config put it
    -- instead of re-centring it on the next viewport change.
    if type(data.window) == "table" and #data.window >= 4 then
        pcall(function()
            local at = clampWindow(
                UDim2.new(data.window[1], data.window[2], data.window[3], data.window[4]),
                self.window.Size.X.Offset,
                self.window.Size.Y.Offset,
                viewport()
            )
            self._resting = at
            self._moved = true
            if self._open then self.window.Position = at end
        end)
    end

    -- Restore the saved positions of detached parts. Kept for later too, so an
    -- overlay created after this load still picks its spot up.
    if type(data.overlays) == "table" then
        self._overlayPos = data.overlays
        for key, t in pairs(data.overlays) do
            local frame = self._overlays[key]
            if frame and frame.Parent and type(t) == "table" and #t >= 4 then
                pcall(function()
                    -- Clamped on the way in: a config written on a bigger monitor
                    -- puts panels where this screen has no pixels, and a panel that
                    -- cannot be reached cannot be dragged back.
                    --
                    -- Only when the size is known. A panel is auto sized, and a config loaded in
                    -- the same frame the panel was built in reaches here before the engine has
                    -- measured it, so its width reads as zero. The clamp then has no idea how wide
                    -- the panel is and pulls anything left of sixty pixels in to sixty, which moves
                    -- panels that were saved against the left edge.
                    local measured = frame.AbsoluteSize
                    local saved = UDim2.new(t[1], t[2], t[3], t[4])
                    local at = (measured and measured.X > 0)
                        and clampToView(saved, measured, viewport())
                        or saved
                    self._overlayRest[key] = at
                    frame.Position = at
                    if t[5] ~= nil then self:showOverlay(frame, t[5] == 1, true) end
                end)
            end
        end
    end
    self:refreshAll()
    return true
end

function Window:loadConfig(name)
    if type(name) ~= "string" or name == "" then return false end
    if type(readfile) ~= "function" or type(isfile) ~= "function" then
        log("warn", "executor has no readfile/isfile")
        return false
    end
    local path = configPath(name)
    if not isfile(path) then
        log("warn", "config '" .. name .. "' does not exist (" .. path .. ")")
        return false
    end
    local ok, data = pcall(function()
        return HttpService:JSONDecode(readfile(path))
    end)
    if not ok then
        log("warn", "loadConfig failed: " .. tostring(data))
        return false
    end
    return self:restore(data)
end

-- Clipboard --------------------------------------------------------------------
-- The same snapshot a file holds, as text. Sharing a setup with somebody is the
-- thing people actually want to do with a config, and passing a file around is not
-- how anyone does it.
--
-- Export returns the text as well as putting it on the clipboard, so a script can
-- show it in a box when the executor has no setclipboard.
function Window:exportConfig()
    local ok, text = pcall(function()
        return HttpService:JSONEncode(self:snapshot())
    end)
    if not ok then
        log("warn", "exportConfig failed: " .. tostring(text))
        return nil
    end
    if type(setclipboard) == "function" then
        pcall(setclipboard, text)
    end
    return text
end

-- Import from text, or from the clipboard when no text is given and the executor
-- can read it back.
function Window:importConfig(text)
    if (text == nil or text == "") and type(getclipboard) == "function" then
        local ok, fromClipboard = pcall(getclipboard)
        if ok then text = fromClipboard end
    end
    if type(text) ~= "string" or text == "" then return false end
    local ok, data = pcall(function()
        return HttpService:JSONDecode(text)
    end)
    if not ok or type(data) ~= "table" then
        log("warn", "importConfig: not a config")
        return false
    end
    local applied = self:restore(data)
    if applied then self._dirty = true end
    return applied
end

function Window:listConfigs()
    local out = {}
    pcall(function()
        local dir = placeFolder()
        if type(listfiles) ~= "function" then return end
        local files = nil
        -- Some executors return isfolder == false even when the folder exists,
        -- so try listfiles directly and fall back to the isfolder guard.
        local ok, res = pcall(listfiles, dir)
        if ok and type(res) == "table" then files = res end
        if files then
            for _, f in ipairs(files) do
                local nm = string.match(f, "([^/\\]+)%.json$")
                if nm then table.insert(out, nm) end
            end
        end
    end)
    return out
end

function Window:deleteConfig(name)
    if type(name) ~= "string" or name == "" then return false end
    if type(delfile) ~= "function" then log("warn", "executor has no delfile") return false end
    local ok, err = pcall(function() delfile(configPath(name)) end)
    if not ok then log("warn", "deleteConfig failed: " .. tostring(err)) end
    return ok
end

-- Auto load pointer: stored in its own file (not inside a config) so it can be
-- read at startup before any config is loaded. setAutoLoad(nil) clears it.
local function autoLoadPath()
    return placeFolder() .. "/_autoload.txt"
end
function Window:setAutoLoad(name)
    local ok = pcall(function()
        ensureConfigDir()
        if type(name) == "string" and name ~= "" then
            if type(writefile) == "function" then writefile(autoLoadPath(), name) end
        elseif type(delfile) == "function" and type(isfile) == "function" and isfile(autoLoadPath()) then
            delfile(autoLoadPath())
        end
    end)
    -- Auto save follows it, when auto save is running at all.
    --
    -- Writing to one config and reading another is not a state worth supporting: it is only ever a
    -- mistake, and it is the mistake a real session falls into on its own. A script turns auto save
    -- on at startup, before anybody has marked a config, so it writes to "default". Later the user
    -- picks a config of their own on the settings page and marks it to load. From then on every
    -- drag, every toggle and every colour goes into one file and the next launch reads the other,
    -- so nothing they change is ever seen again. Both settings said they were on and both were
    -- telling the truth, which is what made it invisible.
    if type(name) == "string" and name ~= "" and self._autoSaveName then
        self:setAutoSave(name)
    end
    return ok
end
function Window:getAutoLoad()
    local out = nil
    pcall(function()
        if type(isfile) == "function" and type(readfile) == "function" and isfile(autoLoadPath()) then
            local s = readfile(autoLoadPath())
            if type(s) == "string" and s ~= "" then out = s end
        end
    end)
    return out
end

-- The saved look, before there is a window to put it on.
--
-- A config carries two kinds of thing. Most of it belongs to a window: the flags, the show and
-- hide key, where each detached panel sits. The rest belongs to the session and to every window
-- in it: the palette, the type family, the weights, the text size and the language. That second
-- kind can be applied with nothing built yet, which is what this does.
--
-- What it fixes is the key prompt turning up in the factory colours. Somebody who spent a while
-- on a palette got the default one on the first thing the script drew and their own the moment
-- the window opened, and the two do not match, so it read as a fault in the product rather than
-- as a prompt that had not read the config yet. The prompt is drawn before any window exists,
-- so waiting for loadConfig cannot fix it: the session-wide half has to go on first.
--
-- The name defaults to whatever setAutoLoad marked, so the ordinary call takes no arguments.
-- Nothing window shaped is touched, so this is safe to call at any point and safe to call
-- twice. Returns the name it applied, or nil.
function Interface.preloadConfig(name)
    if type(readfile) ~= "function" or type(isfile) ~= "function" then return nil end
    if name == nil then
        pcall(function()
            if isfile(autoLoadPath()) then
                local marked = readfile(autoLoadPath())
                if type(marked) == "string" and marked ~= "" then name = marked end
            end
        end)
    end
    if type(name) ~= "string" or name == "" then return nil end
    local path = configPath(name)
    local ok, data = pcall(function()
        if not isfile(path) then return nil end
        return HttpService:JSONDecode(readfile(path))
    end)
    if not ok or type(data) ~= "table" then return nil end

    -- The language first, then the type, then the colours. The same order Window:restore uses
    -- and for the same reason: the first two re-face every label there is, so doing them after
    -- the colour pass would repaint work that is about to be thrown away.
    if type(data.locale) == "string" and data.locale ~= "" then
        Interface.setLocale(data.locale)
    end
    if type(data.font) == "string" and data.font ~= "" then
        Interface.setFont(data.font)
    end
    if type(data.weights) == "table" then
        for role, weight in pairs(data.weights) do
            Interface.setRoleWeight(role, weight)
        end
    end
    if type(data.textScale) == "number" then
        Interface.setTextScale(data.textScale)
    end
    if type(data.theme) == "table" then
        for key, rgb in pairs(data.theme) do
            -- accentSoft is derived from two of the others, so it is recomputed below rather
            -- than read out of the file.
            if DEFAULTS[key] and type(rgb) == "table" and key ~= "accentSoft" then
                applyKey(key, colorOf(rgb), rgb[4] or PALETTE_A[key] or 1)
            end
        end
        applyKey("accentSoft", legibleOn(PALETTE.accent, PALETTE.background), PALETTE_A.accent)
    end
    if type(data.recent) == "table" then
        table.clear(recentColors)
        for _, hex in ipairs(data.recent) do
            if type(hex) == "string" and #hex == 6 then
                recentColors[#recentColors + 1] = hex
            end
        end
    end
    return name
end

-- Auto save: persists the named config a couple of seconds after any change, so
-- every toggle, slider and colour is kept without the user pressing Save. Pass
-- nil to stop. Combined with setAutoLoad, settings survive between sessions.
function Window:setAutoSave(name)
    self._autoSaveName = (type(name) == "string" and name ~= "") and name or nil
    if self._autoSaveName and not self._autoSaveStop then
        -- Runs on the shared ticker, two seconds apart, and only writes when a
        -- control actually changed something.
        self._autoSaveStop = addTicker(2, function()
            if self._dirty and self._autoSaveName then
                self._dirty = false
                self:saveConfig(self._autoSaveName, true)
            end
        end)
        table.insert(self._conns, self._autoSaveStop)
    end
end

-- Which config auto save is writing to, or nil while it is off.
function Window:getAutoSave()
    return self._autoSaveName
end

-- Notifications ---------------------------------------------------------------
-- Toasts come in from off the right edge of the screen and stack upward from the
-- bottom right corner. The stack is positioned by hand rather than by a layout:
-- a layout would move the older toasts in one frame, and the point of the stack
-- is that they are pushed up, with a little weight behind them.
--
-- Both axes live in one Position, so every animation writes the full value: the
-- entry slide, the shift upward and the exit all target the same property and
-- the newest tween simply wins.
LAYOUT.toastWidth = 286
LAYOUT.toastGap = 8
LAYOUT.toastMax = 6

function Window:notify(opts)
    if type(opts) == "string" then opts = { title = opts } end
    opts = opts or {}
    if not self._toasts then
        local holder = newInstance("Frame")
        holder.Name = randomName()
        holder.AnchorPoint = Vector2.new(1, 1)
        holder.Position = UDim2.new(1, -18, 1, -18)
        holder.Size = UDim2.new(0, LAYOUT.toastWidth, 1, -36)
        holder.BackgroundTransparency = 1
        holder.ZIndex = 200
        holder.Parent = self.screen
        self._toasts = holder
        self._toastStack = {}
    end

    local stack = self._toastStack
    local hasText = opts.text ~= nil and opts.text ~= ""
    local height = hasText and 58 or 42
    local offscreen = LAYOUT.toastWidth + 48

    local toast = newGroup()
    toast.Name = randomName()
    toast.AnchorPoint = Vector2.new(1, 1)
    toast.Size = UDim2.new(0, LAYOUT.toastWidth, 0, height)
    toast.Position = UDim2.new(1, offscreen, 1, 0)
    toast.BorderSizePixel = 0
    toast.ZIndex = 200
    toast.Parent = self._toasts
    themed(toast, "BackgroundColor3", "card")
    corner(toast, 10)
    stroke(toast, "stroke", 1, 0.35)

    -- Just the icon. It used to sit on a tinted disc, which put a second shape
    -- inside a card that already had one and drew the eye away from the text the
    -- notification exists to deliver.
    local textX = 16
    if opts.icon then
        local ic = makeIcon(toast, opts.icon, UDim2.new(0, 20, 0, 20), "icon")
        ic.AnchorPoint = Vector2.new(0, 0.5)
        ic.Position = UDim2.new(0, 16, 0.5, 0)
        if ic.Image == "" then
            ic:Destroy()
        else
            textX = 46
        end
    end

    local title = newInstance("TextLabel")
    title.BackgroundTransparency = 1
    title.Position = UDim2.new(0, textX, 0, hasText and 9 or 0)
    title.Size = UDim2.new(1, -textX - 14, 0, hasText and 18 or height)
    title.TextSize = 14
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.TextYAlignment = Enum.TextYAlignment.Center
    title.TextTruncate = Enum.TextTruncate.AtEnd
    title.Parent = toast
    faced(title, "semibold")
    themed(title, "TextColor3", "text")
    localized(title, "Text", opts.title or "Notification")

    if hasText then
        local msg = newInstance("TextLabel")
        msg.BackgroundTransparency = 1
        msg.Position = UDim2.new(0, textX, 0, 28)
        msg.Size = UDim2.new(1, -textX - 14, 0, 18)
        msg.TextSize = 14
        msg.TextXAlignment = Enum.TextXAlignment.Left
        msg.TextTruncate = Enum.TextTruncate.AtEnd
        msg.Parent = toast
        faced(msg, "regular")
        themed(msg, "TextColor3", "subtext")
        localized(msg, "Text", opts.text)
    end

    -- Anywhere on the toast dismisses it early.
    local hit = newInstance("TextButton")
    hit.Size = UDim2.new(1, 0, 1, 0)
    hit.BackgroundTransparency = 1
    hit.AutoButtonColor = false
    hit.Text = ""
    hit.ZIndex = 10
    hit.Parent = toast

    -- The whole toast fades, words included, as one number.
    local setAlpha = groupFade(toast)
    setAlpha(0)
    local fadeStop = nil
    local alphaNow = 0
    local function runFade(target, duration, onDone)
        if fadeStop then
            fadeStop()
            fadeStop = nil
        end
        local from = alphaNow
        local elapsed = 0
        fadeStop = addTicker(0, function(dt)
            if not toast.Parent then
                if fadeStop then fadeStop() fadeStop = nil end
                return
            end
            elapsed += dt
            local t = math.min(elapsed / duration, 1)
            alphaNow = from + (target - from) * t
            setAlpha(alphaNow)
            if t >= 1 then
                if fadeStop then fadeStop() fadeStop = nil end
                if onDone then onDone() end
            end
        end)
    end

    local entry = { frame = toast, height = height, y = 0, offX = 0 }

    -- Lay the stack out from the bottom up. The newest toast is at index one, so
    -- adding one pushes the rest along with a small settle at the end of the
    -- travel rather than snapping them into their new slot.
    local function relayout(animate)
        local y = 0
        for i = 1, #stack do
            local item = stack[i]
            item.y = -y
            local target = UDim2.new(1, item.offX, 1, item.y)
            if animate and item ~= entry then
                tween(item.frame, 0.5, { Position = target }, EASE_JELLY)
            elseif not animate then
                item.frame.Position = target
            end
            y += item.height + LAYOUT.toastGap
        end
    end

    local dismissed = false
    local function dismiss()
        if dismissed then return end
        dismissed = true
        for i = #stack, 1, -1 do
            if stack[i] == entry then table.remove(stack, i) end
        end
        entry.offX = offscreen
        -- Out the way it came in, and taken down when the surface has gone rather than
        -- when a tween says so. A position tween on a toast is replaced every time the
        -- stack relays out, and a replaced tween reports completion straight away.
        runFade(0, 0.3, function() toast:Destroy() end)
        tween(toast, 0.3, { Position = UDim2.new(1, offscreen, 1, entry.y) }, EASE)
        relayout(true)
    end

    table.insert(stack, 1, entry)
    -- Older toasts move first, then the new one comes in over the gap it made.
    relayout(true)
    tween(toast, 0.42, { Position = UDim2.new(1, 0, 1, entry.y) }, EASE)
    runFade(1, 0.24)

    hit.MouseButton1Click:Connect(dismiss)

    -- A run of toasts should not climb off the top of the screen.
    while #stack > LAYOUT.toastMax do
        local oldest = stack[#stack]
        if oldest and oldest.dismiss then oldest.dismiss() else break end
    end

    entry.dismiss = dismiss
    task.delay(opts.duration or 3, dismiss)
    return toast
end

-- Detached overlays -----------------------------------------------------------
-- The watermark, the keybind panel and custom HUDs are the same shell: a small
-- themed card that lives on the screen instead of inside the window, can be
-- dragged anywhere and has its position and visibility saved with the config.
local OVERLAY_Z = 150

local function overlayShell(self, name, opts)
    -- A group, so the panel and its rows fade together. It is dragged with whole pixel
    -- deltas and never scaled, so the blit stays one to one.
    local frame = newGroup()
    frame.Name = randomName()
    frame.Size = opts.size or UDim2.new(0, 0, 0, 34)
    frame.AutomaticSize = opts.autoSize or Enum.AutomaticSize.X
    frame.Position = opts.position or UDim2.new(0, 16, 0, 16)
    frame.BorderSizePixel = 0
    frame.ZIndex = OVERLAY_Z
    frame.Parent = self.screen
    themed(frame, "BackgroundColor3", "card")
    corner(frame, opts.radius or 8)
    stroke(frame, "stroke", 1, 0.3)
    local setAlpha = groupFade(frame)

    -- A position saved in the config wins over the default one.
    local saved = self._overlayPos and self._overlayPos[name]
    if type(saved) == "table" and #saved >= 4 then
        frame.Position = UDim2.new(saved[1], saved[2], saved[3], saved[4])
    end
    self._overlays[name] = frame
    self._panelNames[name] = opts.label
    -- A row on the settings page for it, if that page has already been built. See
    -- Window:_panelRow for why this is pushed from here rather than pulled from there.
    if self._panelsCard then self:_panelRow(name) end

    -- Where the panel belongs, held here rather than read back off the frame.
    --
    -- The show and hide animation moves the frame, so reading frame.Position to
    -- find the resting place gives a mid-animation value whenever a toggle
    -- interrupts one. Each interrupted toggle then adopted that value as the new
    -- resting place and the panel walked down the screen a few pixels at a time,
    -- and auto save wrote the walk to the config. This is the only thing the
    -- animation and the config agree to read.
    self._overlayRest[name] = frame.Position
    -- Dropping it marks the config dirty, so auto save keeps the new spot.
    makeDraggable(frame, frame, function(dropped)
        self._overlayRest[name] = dropped.Position
        self._dirty = true
    end)

    -- Show and hide. Registered on the window so win:showOverlay works on a
    -- watermark as well as on a HUD.
    --
    -- The panel drops a little as it goes and lifts back into place as it returns, so
    -- hiding one reads as the panel leaving rather than as the panel being switched
    -- off. Only the frame's own position moves, and the resting place is restored the
    -- moment the animation is done, because that position is what the config stores
    -- and what a drag starts from.
    --
    -- The first call is the panel appearing, which is not a change the user made, so
    -- it does not mark the config dirty and trigger a write on startup.
    local settled = false
    local LIFT = 12
    local wantVisible = true
    local fadeStop = nil

    local function liftedFrom(resting)
        return UDim2.new(resting.X.Scale, resting.X.Offset, resting.Y.Scale, resting.Y.Offset + LIFT)
    end

    -- Run the fade on the shared driver, from wherever it currently is, so a toggle
    -- that interrupts another picks up mid way instead of restarting.
    local alphaNow = 1
    local function runFade(target, duration)
        if fadeStop then
            fadeStop()
            fadeStop = nil
        end
        local from = alphaNow
        local elapsed = 0
        if math.abs(target - from) < 0.01 then
            alphaNow = target
            setAlpha(target)
            return
        end
        fadeStop = addTicker(0, function(dt)
            elapsed += dt
            local t = math.min(elapsed / duration, 1)
            alphaNow = from + (target - from) * t
            setAlpha(alphaNow)
            if t >= 1 then
                if fadeStop then fadeStop() fadeStop = nil end
                -- Hidden only if hiding is still what was asked for. Reading the
                -- transparency instead let a fast off-then-on land here while the
                -- panel was on its way back in, and it was switched off behind the
                -- toggle that said it was on.
                if not wantVisible then frame.Visible = false end
            end
        end)
    end

    self._overlayFade[frame] = function(visible, instant)
        local resting = self._overlayRest[name] or frame.Position
        wantVisible = visible
        if visible then
            frame.Visible = true
            if instant then
                frame.Position = resting
                alphaNow = 1
                setAlpha(1)
            else
                frame.Position = liftedFrom(resting)
                tween(frame, 0.34, { Position = resting }, EASE)
                runFade(1, 0.24)
            end
        elseif instant then
            frame.Position = resting
            alphaNow = 0
            setAlpha(0)
            frame.Visible = false
        else
            runFade(0, 0.2)
            local out = tween(frame, 0.24, { Position = liftedFrom(resting) }, EASE, Enum.EasingDirection.In)
            out.Completed:Once(function()
                -- Back to the resting place either way, so an interrupted hide
                -- cannot leave the panel parked on the lifted offset.
                frame.Position = self._overlayRest[name] or resting
            end)
        end
        if settled then self._dirty = true end
        settled = true
    end

    -- A visibility saved in the config wins over the caller's default, the same
    -- way the saved position does.
    local startVisible = opts.visible ~= false
    if saved and saved[5] ~= nil then startVisible = saved[5] == 1 end
    if startVisible then
        self._overlayFade[frame](true)
    else
        wantVisible = false
        alphaNow = 0
        frame.Visible = false
        settled = true
    end
    return frame
end

-- One row on the settings page's Panels card, for the panel registered under this name.
--
-- Called from two places and it has to be safe from both: once per existing panel when the
-- card is built, and once per panel built after that. Nothing happens when there is no card,
-- which is the case for a script that dropped the Panels card or never asked for a settings
-- page at all.
--
-- The label comes from whoever built the panel, because the key it is saved under is not a
-- label: a HUD is saved under "hud:session" so that a HUD and the watermark cannot collide in
-- the config. A panel built by hand through a route that names no label falls back to its key
-- with a capital on the front, which reads correctly for a one word key. Either way it goes
-- through the phrase table like every other label, so a translation renames the row without
-- the caller doing anything.
function Window:_panelRow(name)
    local card = self._panelsCard
    if not card then return end
    if self._panelRows and self._panelRows[name] then return end
    self._panelRows = self._panelRows or {}
    self._panelRows[name] = true
    local label = self._panelNames[name]
    if not label or label == "" then
        -- The key, with anything up to a colon dropped: the prefixes are there so a HUD, a bar
        -- and a ring called the same thing cannot collide in one config, and "Bar:health" is a
        -- config key rather than something to read.
        local plain = string.match(name, ":(.+)$") or name
        label = string.upper(string.sub(plain, 1, 1)) .. string.sub(plain, 2)
    end
    card:toggle(label, function()
        local frame = self._overlays[name]
        return frame ~= nil and frame.Parent ~= nil and frame.Visible
    end, function(value)
        local frame = self._overlays[name]
        if frame then self:showOverlay(frame, value) end
    end)
end

-- Show or hide any detached panel with the shell's own fade. Frames the library
-- did not build fall back to a plain visibility flip.
function Window:showOverlay(frame, visible, instant)
    if not frame then return end
    local fade = self._overlayFade[frame]
    if fade then
        fade(visible ~= false, instant)
    else
        frame.Visible = visible ~= false
    end
end

-- Title row shared by the keybind panel and the HUDs: optional logo or icon,
-- the title itself and a divider under it.
local function overlayHeader(body, cfg)
    local row = newInstance("Frame")
    row.Name = randomName()
    row.Size = UDim2.new(1, 0, 0, 20)
    row.BackgroundTransparency = 1
    row.ZIndex = OVERLAY_Z
    row.LayoutOrder = nextOrder(body)
    row.Parent = body

    local textX = 0
    if cfg.logo then
        local mark, _, _, empty = logoMark(row, UDim2.new(0, 18, 0, 18), { zIndex = OVERLAY_Z })
        if empty then
            mark:Destroy()
        else
            mark.AnchorPoint = Vector2.new(0, 0.5)
            mark.Position = UDim2.new(0, 0, 0.5, 0)
            textX = 24
        end
    elseif cfg.icon then
        local ic = makeIcon(row, cfg.icon, UDim2.new(0, 16, 0, 16), "icon")
        ic.AnchorPoint = Vector2.new(0, 0.5)
        ic.Position = UDim2.new(0, 0, 0.5, 0)
        ic.ZIndex = OVERLAY_Z
        if ic.Image ~= "" then textX = 22 else ic:Destroy() end
    end

    local title = newInstance("TextLabel")
    title.BackgroundTransparency = 1
    title.Position = UDim2.new(0, textX, 0, 0)
    title.Size = UDim2.new(1, -textX, 1, 0)
    title.TextSize = 14
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.TextTruncate = Enum.TextTruncate.AtEnd
    title.ZIndex = OVERLAY_Z
    title.Parent = row
    faced(title, "semibold")
    themed(title, "TextColor3", "text")
    local setPhrase = localized(title, "Text", cfg.title or "")

    local divider = newInstance("Frame")
    divider.Size = UDim2.new(1, 0, 0, 1)
    divider.BackgroundTransparency = 0.4
    divider.BorderSizePixel = 0
    divider.ZIndex = OVERLAY_Z
    divider.LayoutOrder = nextOrder(body)
    divider.Parent = body
    themed(divider, "BackgroundColor3", "stroke")
    return title, setPhrase
end

-- Draggable watermark: logo + animated NewReality brand | FPS | time.
-- opts: { position = UDim2, brand = "text", show = { logo=, brand=, fps=, time= } }
function Window:watermark(opts)
    opts = opts or {}
    local show = opts.show or {}
    if self._watermark then self._watermark:Destroy() end

    local wm = overlayShell(self, "watermark", {
        position = opts.position or UDim2.new(0, 16, 0, 16),
        size = UDim2.new(0, 0, 0, 34),
        label = "Watermark",
    })
    padding(wm, nil, { left = 12, right = 12 })
    local lay = listLayout(wm, 9, Enum.FillDirection.Horizontal)
    lay.VerticalAlignment = Enum.VerticalAlignment.Center
    self._watermark = wm

    local order = 0
    local function nextO() order = order + 1 return order end
    local function sep()
        local f = newInstance("Frame")
        f.Size = UDim2.new(0, 1, 0, 16)
        f.BorderSizePixel = 0
        f.ZIndex = OVERLAY_Z
        f.LayoutOrder = nextO()
        f.Parent = wm
        themed(f, "BackgroundColor3", "stroke")
    end
    -- gradient = true for a label a UIGradient is about to take over: it stays in the
    -- text key's registry for its opacity but the key does not write its colour, because
    -- a gradient multiplies what is underneath it. See animateBrand.
    local function textSeg(initial, role, gradient, size)
        local t = newInstance("TextLabel")
        t.AutomaticSize = Enum.AutomaticSize.X
        t.Size = UDim2.new(0, 0, 1, 0)
        t.BackgroundTransparency = 1
        -- Passed in rather than written over afterwards. faced() measures the text scale from
        -- the size the label already has, so a caller that sets it after the fact leaves that
        -- one label at its unscaled size on a build running at anything but 100%.
        t.TextSize = size or 14
        t.TextYAlignment = Enum.TextYAlignment.Center
        t.Text = initial
        t.ZIndex = OVERLAY_Z
        t.LayoutOrder = nextO()
        t.Parent = wm
        faced(t, role or "medium")
        themed(t, "TextColor3", "text", gradient and { paint = false } or nil)
        return t
    end

    if show.logo ~= false then
        local mark, _, _, empty = logoMark(wm, UDim2.new(0, 24, 0, 24), { zIndex = OVERLAY_Z })
        mark.LayoutOrder = nextO()
        if empty then mark:Destroy() end
    end
    if show.brand ~= false then
        animateBrand(textSeg(opts.brand or "NewReality", "bold", true, 15))
    end

    local fpsLabel, timeLabel
    if show.fps ~= false then
        sep()
        fpsLabel = textSeg("FPS 60")
    end
    if show.time ~= false then
        sep()
        timeLabel = textSeg("00:00:00")
    end

    -- Frames are counted every frame, the labels are only written twice a second.
    local frames, acc, stop = 0, 0, nil
    stop = addTicker(0, function(dt)
        if not wm.Parent then
            if stop then stop() end
            return
        end
        frames += 1
        acc += dt
        if acc < 0.5 then return end
        if wm.Visible then
            if fpsLabel then fpsLabel.Text = "FPS " .. math.floor(frames / acc + 0.5) end
            if timeLabel then timeLabel.Text = os.date("%H:%M:%S") end
        end
        frames, acc = 0, 0
    end)
    wm.Destroying:Connect(function() if stop then stop() end end)
    return wm
end

-- Draggable keybind panel listing every keybind, its key and active state.
-- opts: { position=UDim2, width=number, title=string, showInactive=bool }
function Window:keybindList(opts)
    opts = opts or {}
    if self._keybindPanel then self._keybindPanel:Destroy() end
    local width = opts.width or 190
    local showInactive = opts.showInactive ~= false

    local panel = overlayShell(self, "keybind", {
        position = opts.position or UDim2.new(0, 16, 0, 70),
        size = UDim2.new(0, width, 0, 0),
        autoSize = Enum.AutomaticSize.Y,
        label = "Keybinds",
    })
    self._keybindPanel = panel

    local body = newInstance("Frame")
    body.Name = randomName()
    body.BackgroundTransparency = 1
    body.Size = UDim2.new(1, 0, 0, 0)
    body.AutomaticSize = Enum.AutomaticSize.Y
    body.ZIndex = OVERLAY_Z
    body.Parent = panel
    listLayout(body, 4)
    padding(body, 10)
    overlayHeader(body, { title = opts.title or "Keybinds", icon = opts.icon or "keyboard", logo = opts.logo })

    local rows = {}
    for _, bind in ipairs(self._binds) do
        local row = newInstance("Frame")
        row.Name = randomName()
        row.Size = UDim2.new(1, 0, 0, 20)
        row.BackgroundTransparency = 1
        row.ZIndex = OVERLAY_Z
        row.LayoutOrder = nextOrder(body)
        row.Parent = body

        local dot = newInstance("Frame")
        dot.AnchorPoint = Vector2.new(0, 0.5)
        dot.Position = UDim2.new(0, 1, 0.5, 0)
        dot.Size = UDim2.new(0, 7, 0, 7)
        dot.BorderSizePixel = 0
        dot.ZIndex = OVERLAY_Z
        dot.Parent = row
        -- Deliberately not in the theme registry. The dot is the corrected accent while its
        -- bind is live and subtext while it is not, so a registry that painted it by key
        -- would paint a live one subtext along with every other subtext coloured thing, and
        -- it would read as switched off. The painter below owns it.
        dot.BackgroundColor3 = PALETTE.subtext
        corner(dot, 4)

        local lbl = newInstance("TextLabel")
        lbl.BackgroundTransparency = 1
        lbl.Position = UDim2.new(0, 16, 0, 0)
        lbl.Size = UDim2.new(1, -76, 1, 0)
        lbl.TextSize = 13
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.TextTruncate = Enum.TextTruncate.AtEnd
        lbl.ZIndex = OVERLAY_Z
        lbl.Parent = row
        faced(lbl, "medium")
        -- Same again: full text while the bind is live, subtext while it is not.
        lbl.TextColor3 = PALETTE.subtext
        localized(lbl, "Text", bind.label)

        local keyLbl = newInstance("TextLabel")
        keyLbl.AnchorPoint = Vector2.new(1, 0.5)
        keyLbl.Position = UDim2.new(1, 0, 0.5, 0)
        keyLbl.Size = UDim2.new(0, 58, 1, 0)
        keyLbl.BackgroundTransparency = 1
        keyLbl.TextSize = 13
        keyLbl.TextXAlignment = Enum.TextXAlignment.Right
        keyLbl.TextTruncate = Enum.TextTruncate.AtEnd
        keyLbl.Text = ""
        keyLbl.ZIndex = OVERLAY_Z
        keyLbl.Parent = row
        faced(keyLbl, "regular")
        themed(keyLbl, "TextColor3", "subtext")

        rows[#rows + 1] = { row = row, dot = dot, lbl = lbl, key = keyLbl, bind = bind }
    end

    -- The ticker below only writes a row when its own state changes, so on a palette change
    -- a row that was already lit kept the accent it was lit with. This repaints the two
    -- state coloured parts of every row from the colour on screen at the end of each palette
    -- pass, which means they follow the ease rather than snapping when it ends.
    --
    -- Clearing the cached state and waiting for the next tick was the earlier attempt. It
    -- picked the right colour up eventually, but a tick is a tenth of a second away and the
    -- registry was repainting the dot subtext on every frame until then, so a lit dot
    -- flickered for the length of the change.
    addStatePainter(panel, function()
        for _, r in ipairs(rows) do
            local live = r.lastActive and true or false
            r.dot.BackgroundColor3 = live and shownColor("accentSoft") or shownColor("subtext")
            r.lbl.TextColor3 = live and shownColor("text") or shownColor("subtext")
        end
    end)
    -- The key text is not state coloured, but it is translated, and a language change has to
    -- reach the "None" a row falls back to.
    table.insert(self._refresh, function()
        for _, r in ipairs(rows) do
            r.lastKey = nil
        end
    end)

    -- Ten refreshes a second is enough for a bind list, and each row is only
    -- written when its key or its state actually changed.
    local stop
    stop = addTicker(0.1, function()
        if not panel.Parent then
            if stop then stop() end
            return
        end
        if not panel.Visible then return end
        for _, r in ipairs(rows) do
            local keys = (r.bind.keys and r.bind.keys()) or {}
            local text = (#keys > 0) and table.concat(keys, "+") or translate("None")
            if text ~= r.lastKey then
                r.lastKey = text
                r.key.Text = text
            end
            local active = (r.bind.active and r.bind.active()) or false
            if active ~= r.lastActive then
                r.lastActive = active
                tween(r.dot, 0.18, { BackgroundColor3 = active and PALETTE.accentSoft or PALETTE.subtext }, EASE_SOFT)
                tween(r.lbl, 0.18, { TextColor3 = active and PALETTE.text or PALETTE.subtext }, EASE_SOFT)
                r.row.Visible = showInactive or active
            end
        end
    end)
    panel.Destroying:Connect(function() if stop then stop() end end)
    return panel
end

-- Custom HUD ------------------------------------------------------------------
-- The same shell and the same row design as the watermark and the keybind panel,
-- so a script never has to rebuild that look by hand. A row reads its value from
-- a function and the panel refreshes the rows on one shared timer.
--
--   local hud = win:hud({ title = "Session", icon = "gauge", width = 190 })
--   hud:row("Kills", function() return kills end)
--   hud:row({ label = "Money", icon = "coin-pound", value = function() return cash end })
--   hud:bar("Health", function() return hp / maxHp end)
--   hud:section("Farm")
--   local rate = hud:row("Per hour", "0")     -- pushed instead of polled
--   rate:set("1 240")
--
-- Rows return a handle with set, setLabel, setVisible and remove. The HUD itself
-- has setTitle, setVisible, clear, destroy and a .frame field.
local Hud = {}
Hud.__index = Hud

-- A value is a plain string or number, or a function polled on the timer.
local function hudText(value)
    if value == nil then return "" end
    local kind = type(value)
    if kind == "number" then
        if value % 1 == 0 then return tostring(math.floor(value)) end
        return string.format("%.2f", value)
    elseif kind == "boolean" then
        return value and translate("On") or translate("Off")
    end
    return tostring(value)
end

local function hudRead(source)
    if type(source) == "function" then
        local ok, out = pcall(source)
        return ok and out or nil
    end
    return source
end

function Hud:_track(entry)
    self._live[#self._live + 1] = entry
    entry.update()
end

function Hud:_line(height)
    local row = newInstance("Frame")
    row.Name = randomName()
    row.Size = UDim2.new(1, 0, 0, height)
    row.BackgroundTransparency = 1
    row.ZIndex = OVERLAY_Z
    row.LayoutOrder = nextOrder(self._body)
    row.Parent = self._body
    return row
end

-- label / value row. cfg: label, value, icon, dot, color, height.
function Hud:row(label, value, opts)
    local cfg
    if type(label) == "table" then
        cfg = label
    else
        cfg = opts or {}
        cfg.label = label
        if value ~= nil then cfg.value = value end
    end

    local row = self:_line(cfg.height or 20)
    local textX = 0
    local dot
    if cfg.dot then
        dot = newInstance("Frame")
        dot.AnchorPoint = Vector2.new(0, 0.5)
        dot.Position = UDim2.new(0, 1, 0.5, 0)
        dot.Size = UDim2.new(0, 7, 0, 7)
        dot.BorderSizePixel = 0
        dot.ZIndex = OVERLAY_Z
        dot.Parent = row
        -- Out of the theme registry on purpose: lit it is the corrected accent, unlit it is
        -- subtext, so painting it by key would paint a lit one as though it were off. The
        -- painter further down owns both it and the name beside it.
        dot.BackgroundColor3 = PALETTE.subtext
        corner(dot, 4)
        textX = 16
    elseif cfg.icon then
        local ic = makeIcon(row, cfg.icon, UDim2.new(0, 15, 0, 15), "iconDim")
        ic.AnchorPoint = Vector2.new(0, 0.5)
        ic.Position = UDim2.new(0, 0, 0.5, 0)
        ic.ZIndex = OVERLAY_Z
        if ic.Image ~= "" then textX = 21 else ic:Destroy() end
    end

    local labelText = newInstance("TextLabel")
    labelText.BackgroundTransparency = 1
    labelText.Position = UDim2.new(0, textX, 0, 0)
    labelText.Size = UDim2.new(1, -textX - 70, 1, 0)
    labelText.TextSize = 13
    labelText.TextXAlignment = Enum.TextXAlignment.Left
    labelText.TextTruncate = Enum.TextTruncate.AtEnd
    labelText.ZIndex = OVERLAY_Z
    labelText.Parent = row
    faced(labelText, "medium")
    if dot then
        -- A row with a dot has a state, and the name follows it: full text while the dot is
        -- lit, subtext while it is not. So it is painted with the dot rather than by key.
        labelText.TextColor3 = PALETTE.text
    else
        themed(labelText, "TextColor3", "text", { fade = false })
    end
    local setLabelPhrase = localized(labelText, "Text", cfg.label or "")

    local valueText = newInstance("TextLabel")
    valueText.AnchorPoint = Vector2.new(1, 0.5)
    valueText.Position = UDim2.new(1, 0, 0.5, 0)
    valueText.Size = UDim2.new(0, 68, 1, 0)
    valueText.BackgroundTransparency = 1
    valueText.TextSize = 13
    valueText.TextXAlignment = Enum.TextXAlignment.Right
    valueText.TextTruncate = Enum.TextTruncate.AtEnd
    valueText.Text = hudText(hudRead(cfg.value))
    valueText.ZIndex = OVERLAY_Z
    valueText.Parent = row
    faced(valueText, "regular")
    if cfg.color then
        valueText.TextColor3 = colorOf(cfg.color)
    else
        themed(valueText, "TextColor3", "subtext")
    end

    local handle = {
        frame = row,
        set = function(_, v)
            cfg.value = v
            valueText.Text = hudText(hudRead(v))
        end,
        setLabel = function(_, v)
            setLabelPhrase(tostring(v or ""))
        end,
        setVisible = function(_, v)
            row.Visible = v ~= false
        end,
        remove = function()
            row:Destroy()
        end,
    }

    -- The poll below only writes the dot and the name when the state they show changes, so on
    -- a palette change a lit row kept the accent it was lit with. This repaints both from the
    -- colour on screen at the end of every palette pass, so they follow the ease.
    --
    -- Clearing the cached state and letting the next tick sort it out was the earlier
    -- version: it landed on the right colour a tenth of a second later, which is long enough
    -- to watch happen.
    if dot then
        addStatePainter(row, function()
            local on = handle._lastDot and true or false
            dot.BackgroundColor3 = on and shownColor("accentSoft") or shownColor("subtext")
            labelText.TextColor3 = on and shownColor("text") or shownColor("subtext")
        end)
    end

    -- Only poll the rows that were given a function, a pushed value costs nothing.
    if type(cfg.value) == "function" or type(cfg.dot) == "function" then
        self:_track({
            update = function()
                if type(cfg.value) == "function" then
                    local text = hudText(hudRead(cfg.value))
                    if text ~= handle._last then
                        handle._last = text
                        valueText.Text = text
                    end
                end
                if type(cfg.dot) == "function" and dot then
                    local on = hudRead(cfg.dot) and true or false
                    if on ~= handle._lastDot then
                        handle._lastDot = on
                        tween(dot, 0.18, { BackgroundColor3 = on and PALETTE.accentSoft or PALETTE.subtext }, EASE_SOFT)
                        tween(labelText, 0.18, { TextColor3 = on and PALETTE.text or PALETTE.subtext }, EASE_SOFT)
                    end
                end
            end,
            alive = function() return row.Parent ~= nil end,
        })
    end
    return handle
end

-- Progress bar row. getRatio returns 0..1, opts: { color, text = fn, height }.
function Hud:bar(label, getRatio, opts)
    opts = opts or {}
    local row = self:_line(opts.height or 30)

    local labelText = newInstance("TextLabel")
    labelText.BackgroundTransparency = 1
    labelText.Size = UDim2.new(1, -60, 0, 15)
    labelText.TextSize = 13
    labelText.TextXAlignment = Enum.TextXAlignment.Left
    labelText.TextTruncate = Enum.TextTruncate.AtEnd
    labelText.ZIndex = OVERLAY_Z
    labelText.Parent = row
    faced(labelText, "medium")
    themed(labelText, "TextColor3", "text")
    local setLabelPhrase = localized(labelText, "Text", label or "")

    local valueText = newInstance("TextLabel")
    valueText.AnchorPoint = Vector2.new(1, 0)
    valueText.Position = UDim2.new(1, 0, 0, 0)
    valueText.Size = UDim2.new(0, 58, 0, 15)
    valueText.BackgroundTransparency = 1
    valueText.TextSize = 13
    valueText.TextXAlignment = Enum.TextXAlignment.Right
    valueText.Text = ""
    valueText.ZIndex = OVERLAY_Z
    valueText.Parent = row
    faced(valueText, "regular")
    themed(valueText, "TextColor3", "subtext")

    local track = newInstance("Frame")
    track.AnchorPoint = Vector2.new(0, 1)
    track.Position = UDim2.new(0, 0, 1, 0)
    track.Size = UDim2.new(1, 0, 0, 6)
    track.BorderSizePixel = 0
    track.ZIndex = OVERLAY_Z
    track.Parent = row
    themed(track, "BackgroundColor3", "track")
    corner(track, 3)

    local fill = newInstance("Frame")
    fill.Size = UDim2.new(0, 0, 1, 0)
    fill.BorderSizePixel = 0
    fill.ZIndex = OVERLAY_Z
    fill.Parent = track
    corner(fill, 3)
    -- The same shading a slider fill carries, so the two kinds of bar in the kit read
    -- as the same object. One with a ramp next to one without looks like one of them is
    -- shaded by mistake. A row given its own colour keeps it through a theme change,
    -- otherwise the bar follows the accent.
    barRamp(fill, opts.color and colorOf(opts.color) or nil)

    local last = nil
    local function apply(ratio)
        ratio = math.clamp(tonumber(ratio) or 0, 0, 1)
        if last and math.abs(ratio - last) < 0.005 then return end
        last = ratio
        tween(fill, 0.2, { Size = UDim2.new(ratio, 0, 1, 0) }, EASE_SOFT)
        valueText.Text = opts.text and tostring(opts.text(ratio)) or (math.floor(ratio * 100 + 0.5) .. "%")
    end
    apply(hudRead(getRatio) or 0)

    local handle = {
        frame = row,
        set = function(_, v) apply(v) end,
        setLabel = function(_, v) setLabelPhrase(tostring(v or "")) end,
        setVisible = function(_, v) row.Visible = v ~= false end,
        remove = function() row:Destroy() end,
    }
    if type(getRatio) == "function" then
        self:_track({
            update = function() apply(hudRead(getRatio) or 0) end,
            alive = function() return row.Parent ~= nil end,
        })
    end
    return handle
end

-- Small upper case caption that splits the panel into groups.
function Hud:section(text)
    local row = self:_line(18)
    local label = newInstance("TextLabel")
    label.BackgroundTransparency = 1
    label.Size = UDim2.new(1, 0, 1, 0)
    label.TextSize = 11
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.TextYAlignment = Enum.TextYAlignment.Bottom
    label.ZIndex = OVERLAY_Z
    label.Parent = row
    faced(label, "semibold")
    themed(label, "TextColor3", "subtext")
    local setPhrase = localized(label, "Text", tostring(text or ""), string.upper)
    return { frame = row, setLabel = function(_, v) setPhrase(tostring(v or "")) end }
end

-- Full width line of text, wraps over several lines when it is long.
function Hud:text(value)
    local row = self:_line(16)
    row.AutomaticSize = Enum.AutomaticSize.Y
    local label = newInstance("TextLabel")
    label.BackgroundTransparency = 1
    label.Size = UDim2.new(1, 0, 0, 0)
    label.AutomaticSize = Enum.AutomaticSize.Y
    label.TextWrapped = true
    label.TextSize = 13
    label.LineHeight = 1.22
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Text = hudText(hudRead(value))
    label.ZIndex = OVERLAY_Z
    label.Parent = row
    faced(label, "regular")
    themed(label, "TextColor3", "subtext")

    local handle = {
        frame = row,
        set = function(_, v) label.Text = hudText(hudRead(v)) end,
        setVisible = function(_, v) row.Visible = v ~= false end,
        remove = function() row:Destroy() end,
    }
    if type(value) == "function" then
        self:_track({
            update = function()
                local text = hudText(hudRead(value))
                if text ~= handle._last then
                    handle._last = text
                    label.Text = text
                end
            end,
            alive = function() return row.Parent ~= nil end,
        })
    end
    return handle
end

function Hud:divider()
    local line = newInstance("Frame")
    line.Size = UDim2.new(1, 0, 0, 1)
    line.BackgroundTransparency = 0.4
    line.BorderSizePixel = 0
    line.ZIndex = OVERLAY_Z
    line.LayoutOrder = nextOrder(self._body)
    line.Parent = self._body
    themed(line, "BackgroundColor3", "stroke")
    return line
end

function Hud:setTitle(text)
    if self._setTitlePhrase then
        self._setTitlePhrase(tostring(text or ""))
    elseif self._title then
        self._title.Text = tostring(text or "")
    end
end

function Hud:setVisible(visible, instant)
    self._ctx:showOverlay(self.frame, visible ~= false, instant)
end

-- Drop every row but keep the panel and its title.
function Hud:clear()
    self._live = {}
    for _, child in ipairs(self._body:GetChildren()) do
        if child:IsA("GuiObject") and child ~= self._headerRow then
            child:Destroy()
        end
    end
end

function Hud:destroy()
    if self._stop then self._stop() end
    self.frame:Destroy()
end

-- opts: title, icon, logo, width, position, id (config key), interval, visible.
function Window:hud(opts)
    opts = opts or {}
    local id = "hud:" .. tostring(opts.id or opts.title or (#self._huds + 1))
    local frame = overlayShell(self, id, {
        position = opts.position or UDim2.new(0, 16, 0, 190),
        size = UDim2.new(0, opts.width or 190, 0, 0),
        autoSize = Enum.AutomaticSize.Y,
        radius = opts.radius or 8,
        visible = opts.visible,
        -- The title, because that is what the panel says on screen and a row that names it
        -- something else is a row about a different panel as far as anyone reading it knows.
        label = opts.title,
    })

    local body = newInstance("Frame")
    body.Name = randomName()
    body.BackgroundTransparency = 1
    body.Size = UDim2.new(1, 0, 0, 0)
    body.AutomaticSize = Enum.AutomaticSize.Y
    body.ZIndex = OVERLAY_Z
    body.Parent = frame
    listLayout(body, opts.spacing or 4)
    padding(body, opts.padding or 10)

    local hud = setmetatable({
        frame = frame,
        _body = body,
        _live = {},
        _ctx = self,
        _id = id,
    }, Hud)

    if opts.title or opts.logo or opts.icon then
        hud._title, hud._setTitlePhrase = overlayHeader(body, { title = opts.title or "", icon = opts.icon, logo = opts.logo })
        hud._headerRow = hud._title.Parent
    end

    -- One timer per HUD walks its polled rows, and a row that was removed drops
    -- out of the list on the next pass.
    local stop
    stop = addTicker(opts.interval or 0.1, function()
        if not frame.Parent then
            if stop then stop() end
            return
        end
        if not frame.Visible then return end
        local live = hud._live
        for i = #live, 1, -1 do
            local entry = live[i]
            if entry.alive and not entry.alive() then
                table.remove(live, i)
            else
                entry.update()
            end
        end
    end)
    hud._stop = stop
    frame.Destroying:Connect(function() if stop then stop() end end)

    self._huds[#self._huds + 1] = hud
    return hud
end

-- The status strip ------------------------------------------------------------
-- A strip of its own under the window: the clock, the date, who the session belongs to,
-- how long the key has left and how many times it has run.
--
-- Under the window and not inside it. It was a footnote along the bottom of the content
-- area, which put session facts inside the frame that holds the script's controls and made
-- the page shorter to fit them: two unrelated things in one box, and the one that matters
-- gave up the room. Now it is a strip beside the window, travelling with it and fading with
-- it, sized to what it has to say. What it costs in height comes off the window rather than
-- being added underneath, so turning it on does not move the interface down the screen.
--
-- Off unless a build asks for it, because most of what it shows only means anything when
-- there is a key system behind it, and a bar reading "user: Player1" on a local build is
-- chrome pretending to be information.
--
-- Every field is optional and every field hides itself when it has nothing to say, which
-- matters for two of them in particular. The run count and the expiry come from whatever
-- the validator reported, so on a build with no key system they are simply absent rather
-- than zero. The run count is deliberately not counted here: a number the library kept
-- would live on this machine, which makes it a number the user can edit, and a run count
-- that can be edited is not a run count. It is the server's to report or nobody's.
LAYOUT.statusH = 24
LAYOUT.statusGap = 8
-- What the page area gives up to the top of the content and to its own bottom margin. The
-- status strip does not appear here any more: it is outside the window and takes nothing off
-- the page, which is the whole point of having moved it.
LAYOUT.pagesTop = 56
LAYOUT.pagesInset = 72

-- How long a key has left, as one unit.
--
-- It began as a clock, "2d 23:59:50", counting down beside the clock that is already on the
-- strip two fields to the left, then became "2d 23h". Both were too much. The strip answers one
-- question here, roughly how long is left, and the answer to it is a single number: three days,
-- five hours, twelve minutes. A second unit beside it is precision nobody asked for on a line
-- that is meant to be read at a glance and not studied.
local function untilText(seconds)
    seconds = math.max(math.floor(seconds), 0)
    if seconds >= 86400 then return (seconds // 86400) .. "d" end
    if seconds >= 3600 then return (seconds // 3600) .. "h" end
    -- Under a minute still reads as a minute rather than as nothing: the field is there to say
    -- the key is nearly out, and "0m" says less than "1m" does.
    return math.max(seconds // 60, 1) .. "m"
end

function Window:statusBar(opts)
    opts = opts or {}
    if self._status then
        if self._statusFade then self:_dropFade(self._statusFade) end
        self._statusFade = nil
        self._status:Destroy()
        self._status = nil
    end
    if opts.enabled == false then
        if self._statusLift and self._statusLift > 0 then
            self._statusLift = 0
            self:refit(true)
        end
        return nil
    end
    local show = opts.show or {}

    -- A group, so it fades with the window on one number the way the body does, and a child
    -- of the window frame rather than of the body, so it travels with a drag and re-centres
    -- with a refit without either of those knowing it exists.
    --
    -- Sized to its contents. A strip the full width of the window is five short fields and
    -- eight hundred pixels of nothing, so it takes the width it needs, which also means a
    -- build showing one field gets a small strip rather than the same empty bar.
    --
    -- Left aligned with the window rather than centred under it. Centred, it is a floating
    -- caption with no edge to belong to and it drifts as fields come and go; against the left
    -- edge it lines up with the sidebar above it and stays put whatever it is showing.
    local bar = newGroup()
    bar.Name = randomName()
    bar.AnchorPoint = Vector2.new(0, 0)
    bar.Position = UDim2.new(0, 0, 1, LAYOUT.statusGap)
    bar.Size = UDim2.new(0, 0, 0, LAYOUT.statusH)
    bar.AutomaticSize = Enum.AutomaticSize.X
    bar.BorderSizePixel = 0
    bar.Parent = self.window
    themed(bar, "BackgroundColor3", "card")
    corner(bar, 8)
    stroke(bar, "stroke", 1, 0.3)
    self._status = bar
    self._statusFade = self:_addFade(groupFade(bar))
    -- The strip only exists once it has been asked for, so the window is re-fitted to make
    -- room for it here rather than the fit having to guess.
    self._statusLift = LAYOUT.statusH + LAYOUT.statusGap
    self:refit(true)

    local row = Instance.new("Frame")
    row.Size = UDim2.new(0, 0, 1, 0)
    row.AutomaticSize = Enum.AutomaticSize.X
    row.BackgroundTransparency = 1
    row.Parent = bar
    padding(row, nil, { left = 12, right = 12 })
    local lay = listLayout(row, 8, Enum.FillDirection.Horizontal)
    lay.VerticalAlignment = Enum.VerticalAlignment.Center

    local order = 0
    local function nextO() order += 1 return order end
    local function sep()
        local f = Instance.new("Frame")
        f.Size = UDim2.new(0, 1, 0, 10)
        f.BackgroundTransparency = 0.4
        f.BorderSizePixel = 0
        f.LayoutOrder = nextO()
        f.Parent = row
        themed(f, "BackgroundColor3", "stroke")
        return f
    end
    -- A field is a separator and a label that go together: hiding the label has to hide
    -- the line beside it, or a field with nothing to say leaves a stray tick behind.
    local fields = {}
    local function field(read)
        local line = (#fields > 0) and sep() or nil
        local label = Instance.new("TextLabel")
        label.AutomaticSize = Enum.AutomaticSize.X
        label.Size = UDim2.new(0, 0, 1, 0)
        label.BackgroundTransparency = 1
        label.TextSize = 12
        label.TextYAlignment = Enum.TextYAlignment.Center
        label.Text = ""
        label.LayoutOrder = nextO()
        label.Parent = row
        faced(label, "regular")
        themed(label, "TextColor3", "subtext")
        fields[#fields + 1] = { label = label, line = line, read = read }
        return label
    end

    if show.time ~= false then
        field(function() return os.date("%H:%M:%S") end)
    end
    if show.date ~= false then
        field(function() return os.date("%d.%m.%Y") end)
    end
    if show.user ~= false then
        field(function()
            local info = Interface.session()
            local named = info and info.user
            if type(named) == "string" and named ~= "" then return named end
            -- Only the key's owner, never the Roblox account as a stand-in. A bar that
            -- prints the local player's name looks like it knows who the session belongs
            -- to when all it knows is who is playing.
            return nil
        end)
    end
    if show.expires ~= false then
        field(function()
            local info = Interface.session()
            local at = info and tonumber(info.expires)
            if not at then return nil end
            local left = at - os.time()
            if left <= 0 then return translate("Expired") end
            return untilText(left)
        end)
    end
    if show.runs ~= false then
        field(function()
            local info = Interface.session()
            local runs = info and tonumber(info.runs)
            if not runs then return nil end
            return translate("Runs") .. " " .. math.floor(runs)
        end)
    end
    if type(opts.text) == "function" then
        field(function()
            local ok, value = pcall(opts.text)
            if ok and value ~= nil and value ~= "" then return tostring(value) end
            return nil
        end)
    end

    local function paint()
        local first = true
        for _, entry in ipairs(fields) do
            local ok, value = pcall(entry.read)
            local text = (ok and value ~= nil) and tostring(value) or nil
            entry.label.Visible = text ~= nil
            if text then
                if entry.label.Text ~= text then entry.label.Text = text end
                -- The separator belongs to the field on its right, and the leftmost field
                -- that is actually showing must not have one.
                if entry.line then entry.line.Visible = not first end
                first = false
            elseif entry.line then
                entry.line.Visible = false
            end
        end
    end
    paint()

    -- Twice a second. The clock is the only thing here that moves on its own and it is
    -- shown to the second, so anything faster is a write nobody can see.
    local stop
    stop = addTicker(0.5, function()
        if not bar.Parent then
            if stop then stop() end
            return
        end
        if bar.Visible and self._open then paint() end
    end)
    bar.Destroying:Connect(function() if stop then stop() end end)
    table.insert(self._refresh, paint)
    return bar
end

function Interface.new(opts)
    -- The gate, on every window and not only on the first. gateOpen re-runs the validator
    -- when its last answer is older than the caller asked for, so a window built long
    -- after the key was entered is a window that was checked rather than one that
    -- inherited a pass.
    if not gateOpen() then
        error("[NewReality] this session is not authorised", 2)
    end
    opts = opts or {}
    local self = setmetatable({
        tabs = {}, groups = {}, flags = {},
        -- Two lists, because they are called at very different rates.
        --
        -- _refresh re-reads a control's value and re-renders it, tweens included. That is
        -- what a config load needs and it is called once, by refreshAll.
        --
        -- _repaint only re-reads a colour and writes it: no tween, no allocation. setColor
        -- calls it, and setColor happens once per frame for as long as a colour picker or an
        -- opacity slider is being dragged. Running the first list at that rate is what made
        -- dragging one control start a tween on every other control on the page, sixty times
        -- a second, until the client gave out.
        _refresh = {}, _repaint = {}, _binds = {},
        -- Open floating panels (dropdowns, pickers, gear popovers), the shared
        -- listeners this window owns, the detached overlays by config name, the
        -- fade helper of each of them and the HUDs built through win:hud.
        _panels = {}, _conns = {}, _overlays = {}, _overlayFade = {}, _overlayRest = {}, _huds = {},
        -- What to call each of those overlays on the settings page. The key it is saved
        -- under is not it: a HUD is saved under "hud:session" so that two panels cannot
        -- collide in the config, and "Hud:session" is not a row label.
        _panelNames = {},
        -- Index of every named control, filled while the interface is built and read
        -- by the search field in the sidebar.
        _search = {},
        _open = true,
        locale = Interface.getLocale(),
    }, Window)
    WINDOWS[#WINDOWS + 1] = self

    local screen = newInstance("ScreenGui")
    screen.Name = randomName()
    screen.ResetOnSpawn = false
    screen.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screen.IgnoreGuiInset = true
    -- High DisplayOrder so the window, watermark and keybind list sit above any
    -- other GUI a script creates (ESP text billboards should use a lower order).
    pcall(function() screen.DisplayOrder = 100000 end)
    screen.Parent = guiParent(screen)
    self.screen = screen

    -- Keep the ScreenGui where it was put. Reparenting another kit's GUI into
    -- your own tree is the usual first step to reading it, so the move is put
    -- back on the next step unless the window is being unloaded.
    local home = screen.Parent
    if home then
        local guard = screen.AncestryChanged:Connect(function(_, parent)
            if self._dead or parent == home then return end
            task.defer(function()
                if self._dead or screen.Parent == home then return end
                pcall(function() screen.Parent = home end)
            end)
        end)
        table.insert(self._conns, function() guard:Disconnect() end)
    end

    -- The root frame carries no paint of its own: it is the anchor the window
    -- scales around and the coordinate space the floating panels are placed in.
    -- Everything you can see is inside the body group, which is what lets a fade
    -- take the whole window down evenly, outlines included.
    -- Centred on a whole pixel, not on a scale of 0.5. A viewport with an odd
    -- width puts a scale centred frame on a half pixel, and the body group is then
    -- blitted between two pixel rows, which softens every glyph in the window. The
    -- offset is worked out once and the drag controller only ever adds whole pixel
    -- deltas to it.
    local view = viewport()
    local winW, winH = windowFit(view)
    local sideW = sidebarFit(winW)
    self._view = view
    local window = newInstance("Frame")
    window.Name = randomName()
    window.AnchorPoint = Vector2.new(0.5, 0.5)
    window.Size = UDim2.new(0, winW, 0, winH)
    window.Position = UDim2.new(0, math.floor(view.X / 2), 0, math.floor(view.Y / 2))
    window.BackgroundTransparency = 1
    window.BorderSizePixel = 0
    window.Parent = screen
    self.window = window
    self._shadow = shadow(window)

    -- Everything the window draws lives in here, and it is a group so that opening and
    -- closing fades all of it by one number: the sidebar, the cards, the labels on them
    -- and the outlines, at the same rate.
    --
    -- The group is safe because of what surrounds it rather than because of anything it
    -- does. Its size is the window's, the window is sized to an even number of pixels and
    -- positioned on whole ones, dragging only ever adds whole pixel deltas, and nothing
    -- anywhere carries a UIScale. So the raster is blitted one to one and every glyph
    -- lands exactly where it would have without the group.
    local body = newGroup()
    body.Name = randomName()
    body.Size = UDim2.new(1, 0, 1, 0)
    body.BorderSizePixel = 0
    body.ZIndex = 1
    body.Parent = window
    themed(body, "BackgroundColor3", "background")
    corner(body, 14)
    self._body = body

    -- Sidebar
    local sidebar = Instance.new("Frame")
    sidebar.Size = UDim2.new(0, sideW, 1, 0)
    sidebar.BorderSizePixel = 0
    sidebar.Parent = body
    themed(sidebar, "BackgroundColor3", "sidebar")
    corner(sidebar, 14)
    self._sidebar = sidebar
    local sidebarMask = Instance.new("Frame")
    sidebarMask.Size = UDim2.new(0, 12, 1, 0)
    sidebarMask.Position = UDim2.new(1, -12, 0, 0)
    sidebarMask.BorderSizePixel = 0
    sidebarMask.Parent = sidebar
    themed(sidebarMask, "BackgroundColor3", "sidebar")

    local brandRow = Instance.new("Frame")
    brandRow.Size = UDim2.new(1, -28, 0, 48)
    brandRow.Position = UDim2.new(0, 16, 0, 16)
    brandRow.BackgroundTransparency = 1
    brandRow.Parent = sidebar
    -- Brand mark: the two layer C+H logo whose C follows the accent colour, or
    -- the single logo icon when that pack is not in the icon set.
    local mark, _, _, noMark = logoMark(brandRow, UDim2.new(0, 40, 0, 40))
    mark.AnchorPoint = Vector2.new(0, 0.5)
    mark.Position = UDim2.new(0, 0, 0.5, 0)
    if noMark then
        mark:Destroy()
        mark = nil
        if iconAsset(opts.icon or "logo") then
            mark = makeIcon(brandRow, opts.icon or "logo", UDim2.new(0, 40, 0, 40), "icon")
            mark.AnchorPoint = Vector2.new(0, 0.5)
            mark.Position = UDim2.new(0, 0, 0.5, 0)
        end
    end
    local hasLogo = mark ~= nil
    local brand = Instance.new("TextLabel")
    brand.BackgroundTransparency = 1
    brand.Position = UDim2.new(0, hasLogo and 50 or 0, 0, 0)
    brand.Size = UDim2.new(1, hasLogo and -50 or 0, 1, 0)
    brand.TextSize = 23
    brand.TextXAlignment = Enum.TextXAlignment.Left
    brand.Text = opts.brand or "NewReality"
    brand.Parent = brandRow
    faced(brand, "bold")
    -- The gradient owns the colour, the key owns the opacity. See animateBrand.
    themed(brand, "TextColor3", "text", { paint = false })
    animateBrand(brand)

    local sidebarList = Instance.new("ScrollingFrame")
    -- Below the search field, which the window builds after the overlay layer exists.
    sidebarList.Position = UDim2.new(0, 10, 0, 110)
    sidebarList.Size = UDim2.new(1, -22, 1, -120)
    sidebarList.BackgroundTransparency = 1
    sidebarList.BorderSizePixel = 0
    sidebarList.ScrollBarThickness = 0
    sidebarList.CanvasSize = UDim2.new(0, 0, 0, 0)
    sidebarList.AutomaticCanvasSize = Enum.AutomaticSize.Y
    sidebarList.Parent = sidebar
    listLayout(sidebarList, 4)
    self.sidebarList = sidebarList

    -- Content
    local content = Instance.new("Frame")
    content.Position = UDim2.new(0, sideW, 0, 0)
    content.Size = UDim2.new(1, -sideW, 1, 0)
    content.BackgroundTransparency = 1
    content.Parent = body
    self._content = content

    -- Drag handle sits behind the header so the title bar is draggable, but the
    -- labels (created after it) stay on top.
    local topDrag = Instance.new("Frame")
    topDrag.Size = UDim2.new(1, 0, 0, 56)
    topDrag.BackgroundTransparency = 1
    topDrag.Parent = content

    local title = Instance.new("TextLabel")
    title.BackgroundTransparency = 1
    title.Position = UDim2.new(0, 24, 0, 13)
    title.Size = UDim2.new(1, -48, 0, 24)
    title.TextSize = 22
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.TextTruncate = Enum.TextTruncate.AtEnd
    title.Text = ""
    title.Parent = content
    faced(title, "bold")
    themed(title, "TextColor3", "text")
    self.title = title

    local subtitle = Instance.new("TextLabel")
    subtitle.BackgroundTransparency = 1
    subtitle.Position = UDim2.new(0, 24, 0, 37)
    subtitle.Size = UDim2.new(1, -48, 0, 16)
    subtitle.TextSize = 14
    subtitle.TextXAlignment = Enum.TextXAlignment.Left
    subtitle.TextTruncate = Enum.TextTruncate.AtEnd
    subtitle.Text = ""
    subtitle.Parent = content
    faced(subtitle, "regular")
    themed(subtitle, "TextColor3", "subtext")
    self.subtitle = subtitle

    local pages = Instance.new("Frame")
    pages.Position = UDim2.new(0, 24, 0, LAYOUT.pagesTop)
    pages.Size = UDim2.new(1, -48, 1, -LAYOUT.pagesInset)
    pages.BackgroundTransparency = 1
    -- Clipped, so a page changing travels in and out behind the edge of the content
    -- area instead of sliding across the window's margin. It is what turns the
    -- movement into one page replacing another rather than two frames drifting.
    -- Nothing needs to escape this rectangle: the dropdowns, pickers and popovers all
    -- live in the overlay layer, which is a sibling of the window.
    pages.ClipsDescendants = true
    pages.Parent = content
    self.pages = pages

    -- Overlay for popovers, dropdown lists and colour pickers. It is a sibling of
    -- the body group rather than a child: a CanvasGroup rasterises its children
    -- into its own rectangle, and a dropdown that opens above a low window has to
    -- be free to draw outside it.
    local overlay = Instance.new("Frame")
    overlay.Size = UDim2.new(1, 0, 1, 0)
    overlay.BackgroundTransparency = 1
    overlay.ZIndex = 40
    overlay.Parent = window
    self.overlay = overlay

    self._bodyFade = self:_addFade(groupFade(body))

    -- Close the floating panels, newest first. With keepPopovers the gear
    -- settings popovers stay open, so a dropdown or a colour picker opened from
    -- inside one does not take its host down with it. Tab switches, hiding the
    -- window and opening a gear close everything.
    self.closeOverlays = function(keepPopovers)
        local stack = self._panels
        for i = #stack, 1, -1 do
            local panel = stack[i]
            if not (keepPopovers and panel.popover) then
                panel.close()
            end
        end
        if self._closeSearch and not keepPopovers then self._closeSearch() end
    end

    -- The search field goes in after the overlay layer, because its result list
    -- floats in that layer.
    self:_buildSearch(sidebar)

    -- Where a floating panel goes, given the offset of its control and its size.
    --
    -- Below the control if it fits, above it if it does not, and if neither side has
    -- the room then whichever side has more of it, pinned against the edge of the
    -- screen. That last case used to clamp the below position into the viewport,
    -- which for a tall panel next to a control in the middle of the screen parked it
    -- straight over the row that opened it.
    --
    -- Returns the position and which side it settled on, because the side decides which
    -- way the panel animates in: a panel below its row comes down out of it, one above
    -- comes up out of it. Without the second value the caller cannot tell the two apart,
    -- and every panel travelled the same way, so half of them opened by moving away from
    -- the control they belong to.
    self.fitPanel = function(xOff, yBelow, w, h, yAbove)
        local winPos = self.window.AbsolutePosition
        local cam = workspace.CurrentCamera
        local vp = (cam and cam.ViewportSize) or self.window.AbsoluteSize
        -- Worked out in screen space, so a panel may sit outside the window (above it
        -- when the window is low) but never off the screen.
        local sx = math.clamp(winPos.X + xOff, 8, math.max(8, vp.X - w - 8))
        local below = winPos.Y + yBelow
        local above = winPos.Y + (yAbove or yBelow)

        local roomBelow = (vp.Y - 8) - below
        local roomAbove = above - 8
        local sy, onTop
        if h <= roomBelow then
            sy, onTop = below, false
        elseif h <= roomAbove then
            sy, onTop = above - h, true
        elseif roomAbove > roomBelow then
            -- Pinned to the top of the screen because that is the roomier side, which
            -- puts the panel above its row even though it did not fit there either.
            sy, onTop = 8, true
        else
            sy, onTop = math.max(8, vp.Y - 8 - h), false
        end

        -- Whole pixels. Half a pixel of offset is half a pixel of blur across
        -- everything written on the panel.
        return UDim2.new(0, math.floor(sx - winPos.X + 0.5), 0, math.floor(sy - winPos.Y + 0.5)), onTop
    end

    -- Dropping the window updates where the open animation returns it to, and marks
    -- it as placed by hand so a viewport change stops re-centring it.
    local function dropped(frame)
        self._resting = frame.Position
        self._moved = true
    end
    makeDraggable(window, topDrag, dropped)

    -- The second way in. A floating panel puts a full window click catcher under
    -- itself, so while a dropdown or a picker is open a press on the title strip
    -- never reaches the strip. The catcher asks this first, and a press that landed
    -- on the strip becomes a window drag with the panel left open.
    self._dragStrip = topDrag
    self.dragWindowFrom = function(input)
        if not pressedOver(input, topDrag) then return false end
        startDrag(window, input, dropped)
        return true
    end

    -- Follow the screen. A player can change resolution, go full screen or rotate a
    -- device mid session, and a window sized for the old viewport is either off the
    -- edge or a stamp in the middle. Checked twice a second on the shared driver
    -- rather than on a per frame signal, because nothing here needs to be immediate.
    table.insert(self._conns, addTicker(0.5, function()
        if self._dead then return end
        self:refit()
    end))

    -- Hotkey to show/hide the window (RightShift by default).
    self.toggleKey = opts.toggleKey or Enum.KeyCode.RightShift
    table.insert(self._conns, onKey(function(input, gpe)
        if gpe then return end
        if input.KeyCode == self.toggleKey then
            self:toggle()
        end
    end))

    -- Keep asking while the window lives, so a revoked session loses its interface instead
    -- of running on with a stale pass. A refusal drops the token as well as the window, so
    -- nothing can be rebuilt afterwards without passing again.
    --
    -- Only when the build said what to ask with. See gateRecheck: the key is not kept, so
    -- there is no second question to put unless the caller supplied one, and a timer that
    -- invents one takes the interface down for no reason.
    --
    -- deferFirst, because this measures a period. Armed the other way it fired one frame
    -- after the window was built, which is how a key that had just been accepted came back
    -- as a refusal and an empty screen.
    if gateArmed() and type(gateOpts and gateOpts.revalidate) == "function" then
        local period = (gateOpts and gateOpts.recheck) or 60
        if period > 0 then
            table.insert(self._conns, addTicker(period, function()
                if self._dead then return end
                local can, passed, info = gateRecheck()
                if not can then return end
                if passed then
                    if info then gateInfo = info end
                    gateToken = mintToken()
                    return
                end
                gateToken = nil
                gateInfo = nil
                if gateOpts and type(gateOpts.onLost) == "function" then
                    pcall(gateOpts.onLost, "revoked")
                end
                self:unload()
            end, true))
        end
    end

    -- The status strip, when the build asks for it. Built last, so it can re-fit the window
    -- to make room for itself under it.
    if opts.statusBar ~= nil and opts.statusBar ~= false then
        self:statusBar(type(opts.statusBar) == "table" and opts.statusBar or nil)
    end

    self._resting = window.Position
    self._shadow.ImageTransparency = 1
    self._alphaNow = 0
    self._open = false
    window.Visible = false

    -- How this window first appears.
    --
    -- Every open after this one is Window:toggle, and normally so is this one: one path, one
    -- description of what opening looks like, no two of them to drift apart. The exception is
    -- the debut, which is the interface assembling itself a part at a time and happens once.
    --
    -- opts.entrance = false never plays it, true always does, and left alone it plays for the
    -- first window built after a key was accepted, which is the moment it is for: the script
    -- has just been let in, and this is it arriving.
    local debut = opts.entrance
    if debut == nil then debut = gateFresh end
    gateFresh = false
    if debut then
        self:_debut()
    else
        self:toggle(true)
    end

    return self
end

-- Tear the interface down: stop the listeners and timers this window put on the
-- shared hubs, drop its HUDs and remove the GUI. Call this instead of destroying
-- the ScreenGui by hand, otherwise the timers keep running with nothing to draw.
function Window:unload()
    if self._dead then return end
    self._dead = true
    if self._autoSaveName and self._dirty then
        pcall(function() self:saveConfig(self._autoSaveName, true) end)
    end
    for _, stop in ipairs(self._conns) do pcall(stop) end
    table.clear(self._conns)
    for _, hud in ipairs(self._huds) do pcall(function() hud:destroy() end) end
    table.clear(self._huds)
    table.clear(self._panels)
    self.screen:Destroy()
end

Interface.Window = Window
Interface.Card = Card

-- The key system -------------------------------------------------------------
-- A small window that takes a key, hands it to the caller's validator and opens the gate
-- if the validator is happy. Everything about what a valid key is belongs to the caller:
-- this owns the asking, the checking schedule and the refusing.
--
--   local ok = UI.keySystem({
--       check = function(key)
--           local reply = game:HttpGet("https://keys.example/verify?k=" .. key)
--           if reply ~= "valid" then return false end
--           -- Anything the bar should show comes back here. None of it is invented.
--           return { ok = true, user = "ccodix", expires = os.time() + 86400, runs = 41 }
--       end,
--       getKeyUrl = "https://keys.example/get",
--       discordUrl = "https://discord.gg/newreality",
--   })
--   if not ok then return end
--   local win = UI.new({ statusBar = true })
--
-- keySystem yields until the question is settled, so the line after it runs with the
-- answer already known. It returns true on a pass and false when the user closed the
-- prompt or ran out of attempts, and the caller decides what that means: returning false
-- rather than killing the thread keeps the decision where it belongs.
--
-- opts:
--   enabled = false   skip the whole thing and return true, for a local build
--   check             the validator. Required. false or { ok = false } refuses.
--   key               try this one first and never show the prompt if it passes. For a
--                     build that already has a key in hand; it is not remembered here.
--   revalidate        asks whether the session is still allowed, part way through it. Takes
--                     no arguments, because the key is not kept and there is nothing to send
--                     again. Without it there is no re-checking at all, which is deliberate:
--                     see gateRecheck.
--   recheck = 300     seconds between those, while the session runs; 0 to never
--   attempts = 0      wrong keys allowed before it gives up; 0 for no limit
--   onLost            called when a re-check fails after a pass
--   title / note / placeholder / getKeyUrl / discordUrl / brand
--   hidden = false    start with the field revealed rather than masked
--   timeout = 600     give up waiting after this long and refuse, so a broken scheduler
--                     cannot leave the caller yielding for the rest of the session
--
-- The key is never held. It goes to the validator as an argument, the field it was typed
-- into is cleared on the way out, and it is not in the config, not in a file and not on
-- any table this library returns. The harness checks that last part by walking a config
-- snapshot for the key it just used.
--
-- keyPrompt is the same window without the waiting: it returns a handle with done, pass,
-- submit(key) and close(), so a caller that wants to drive it on its own thread can, and
-- so the prompt is reachable from a test that cannot block.
function Interface.keyPrompt(opts)
    opts = opts or {}

    -- The saved palette, type and language, before the first thing the script draws. Without
    -- this the prompt comes up in the factory colours and the window that follows it comes up
    -- in the user's, which reads as a fault rather than as a prompt drawn a moment too early.
    -- opts.config = false skips it, and a string names a config other than the marked one.
    if opts.config ~= false then
        Interface.preloadConfig(type(opts.config) == "string" and opts.config or nil)
    end

    -- The links, worked out before anything is drawn, because how many there are decides how
    -- tall the card is. A link that was not given is absent rather than present and dead, and
    -- a build with neither gets a shorter card instead of a strip of nothing under the button.
    --
    -- Discord is the mark on its own when it has something to sit beside. It is the one logo
    -- every reader of this window already knows, so the word next to it said nothing the mark
    -- did not. Alone it takes the whole row, and an eighteen pixel mark lost in the middle of
    -- three hundred and forty is worse than a word, so alone it keeps its word.
    local links = {}
    if type(opts.getKeyUrl) == "string" and opts.getKeyUrl ~= "" then
        -- Words and no picture. There is no drawing of a key site, and the nearest thing in
        -- the pack read as a domino sitting next to the label rather than as anything to do
        -- with a key. Two words say it and take no explaining.
        links[#links + 1] = { label = "Get Key", url = opts.getKeyUrl }
    end
    if type(opts.discordUrl) == "string" and opts.discordUrl ~= "" then
        links[#links + 1] = { icon = "brand-discord", url = opts.discordUrl, square = true }
    end
    if #links == 1 and links[1].square then
        links[1].square = false
        links[1].label = "Discord"
    end

    local screen = newInstance("ScreenGui")
    screen.Name = randomName()
    screen.ResetOnSpawn = false
    screen.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screen.IgnoreGuiInset = true
    pcall(function() screen.DisplayOrder = 100000 end)
    screen.Parent = guiParent(screen)

    local view = viewport()
    -- Head 62, field at 74, status at 120, Check at 142, the links at 188 and 34 tall, then
    -- the same 18 of air under them as there is either side.
    local LINKS_Y = 188
    local W = 380
    local H = (#links > 0) and (LINKS_Y + 34 + 18) or (142 + 38 + 18)
    local root = newInstance("Frame")
    root.Name = randomName()
    root.AnchorPoint = Vector2.new(0.5, 0.5)
    root.Size = UDim2.new(0, W, 0, H)
    root.Position = UDim2.new(0, math.floor(view.X / 2), 0, math.floor(view.Y / 2))
    root.BackgroundTransparency = 1
    root.Parent = screen
    shadow(root)

    local card = newGroup()
    card.Name = randomName()
    card.Size = UDim2.new(1, 0, 1, 0)
    card.BorderSizePixel = 0
    card.Parent = root
    themed(card, "BackgroundColor3", "background")
    corner(card, 14)
    stroke(card, "stroke", 1, 0.35)
    local setAlpha = groupFade(card)
    setAlpha(0)

    local head = Instance.new("Frame")
    head.Size = UDim2.new(1, 0, 0, 62)
    head.BackgroundTransparency = 1
    head.Parent = card
    makeDraggable(root, head)

    local mark, _, _, noMark = logoMark(head, UDim2.new(0, 30, 0, 30))
    mark.AnchorPoint = Vector2.new(0, 0.5)
    mark.Position = UDim2.new(0, 20, 0.5, 0)
    if noMark then mark:Destroy() end
    local textX = noMark and 20 or 60

    local title = Instance.new("TextLabel")
    title.BackgroundTransparency = 1
    title.Position = UDim2.new(0, textX, 0, 14)
    title.Size = UDim2.new(1, -textX - 20, 0, 20)
    title.TextSize = 18
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.TextTruncate = Enum.TextTruncate.AtEnd
    title.Parent = head
    faced(title, "bold")
    themed(title, "TextColor3", "text")
    localized(title, "Text", opts.title or (opts.brand or "NewReality"))

    local note = Instance.new("TextLabel")
    note.BackgroundTransparency = 1
    note.Position = UDim2.new(0, textX, 0, 34)
    note.Size = UDim2.new(1, -textX - 20, 0, 16)
    note.TextSize = 13
    note.TextXAlignment = Enum.TextXAlignment.Left
    note.TextTruncate = Enum.TextTruncate.AtEnd
    note.Parent = head
    faced(note, "regular")
    themed(note, "TextColor3", "subtext")
    localized(note, "Text", opts.note or "Paste your key to continue")

    -- The field, and the eye that reveals it. No outline round it, on focus or otherwise:
    -- every other field in the kit is a plain filled shape and a ring here made this one look
    -- like a different kind of control.
    local box = Instance.new("Frame")
    box.Position = UDim2.new(0, 20, 0, 74)
    box.Size = UDim2.new(1, -40, 0, 38)
    box.BorderSizePixel = 0
    box.Parent = card
    themed(box, "BackgroundColor3", "control")
    corner(box, 9)

    local input = Instance.new("TextBox")
    input.BackgroundTransparency = 1
    input.Position = UDim2.new(0, 12, 0, 0)
    input.Size = UDim2.new(1, -52, 1, 0)
    input.TextSize = 14
    input.Text = ""
    input.ClearTextOnFocus = false
    input.TextXAlignment = Enum.TextXAlignment.Left
    input.Parent = box
    faced(input, "regular")
    themed(input, "TextColor3", "text")
    themed(input, "PlaceholderColor3", "subtext")
    localized(input, "PlaceholderText", opts.placeholder or "Paste your key here")

    local eye = Instance.new("TextButton")
    eye.AnchorPoint = Vector2.new(1, 0.5)
    eye.Position = UDim2.new(1, -8, 0.5, 0)
    eye.Size = UDim2.new(0, 26, 0, 26)
    eye.BackgroundTransparency = 1
    eye.AutoButtonColor = false
    eye.Text = ""
    eye.Parent = box
    -- One icon, not two. The pack has an eye and no crossed out eye, and a state shown by
    -- swapping to an icon that is not there is a state shown by an empty square. Revealed
    -- is the accent, hidden is the dim icon colour, which is the same language the rest of
    -- the kit uses for on and off.
    local eyeImg = makeIcon(eye, "eye", UDim2.new(1, 0, 1, 0), "iconDim")
    eyeImg.Active = false

    -- The real key lives here and nowhere else, and the field shows dots instead of it.
    --
    -- Roblox has no password field, so the mask is done by hand: the box holds one dot per
    -- character and the change handler works out what was typed by taking the dots off the
    -- front of whatever the box now says. That covers typing, pasting and backspacing,
    -- which is all anyone does to a key. Editing in the middle of a masked string appends
    -- at the end instead, and reveal is one click away for anyone who needs to.
    local secret = ""
    local masked = opts.hidden ~= false
    local writing = false
    local DOT = utf8 and utf8.char(8226) or "*"

    local function render()
        writing = true
        input.Text = masked and string.rep(DOT, #secret) or secret
        writing = false
        tintIcon(eyeImg, masked and PALETTE.iconDim or PALETTE.accentSoft)
    end

    input:GetPropertyChangedSignal("Text"):Connect(function()
        if writing then return end
        local shown = input.Text
        if not masked then
            secret = shown
            return
        end
        -- Masked, so what the box says is dots plus whatever was just typed. The dot is a
        -- multi byte character, so everything here counts bytes and divides: the mask for a
        -- key of n characters is n * #DOT bytes long.
        local mask = string.rep(DOT, #secret)
        if shown == "" then
            secret = ""
        elseif #shown < #mask then
            -- Shorter than the mask: characters came off the end.
            secret = string.sub(secret, 1, #shown // #DOT)
        elseif string.sub(shown, 1, #mask) == mask then
            -- The mask is intact at the front, so the rest of it is new input.
            secret = secret .. string.sub(shown, #mask + 1)
        else
            -- The mask itself was edited. Everything that is not a dot is real input and it
            -- goes on the end: reconstructing where it was typed is not worth the code when
            -- revealing the field is one click away.
            secret = (string.gsub(shown, DOT, ""))
        end
        render()
    end)
    eye.MouseButton1Click:Connect(function()
        masked = not masked
        render()
    end)
    eye.MouseEnter:Connect(function() tintIcon(eyeImg, PALETTE.icon) end)
    eye.MouseLeave:Connect(function() render() end)
    render()

    local status = Instance.new("TextLabel")
    status.BackgroundTransparency = 1
    status.Position = UDim2.new(0, 20, 0, 120)
    status.Size = UDim2.new(1, -40, 0, 16)
    status.TextSize = 13
    status.TextXAlignment = Enum.TextXAlignment.Left
    status.TextTruncate = Enum.TextTruncate.AtEnd
    status.Text = ""
    status.Parent = card
    faced(status, "medium")
    themed(status, "TextColor3", "subtext")

    -- Three tones and not two. A refusal and an acceptance are both worth saying loudly and
    -- they are not the same news, so a pass takes the accent, a refusal takes the accent
    -- lifted off the surface until it can be read, and everything else stays quiet.
    local function say(text, tone)
        status.Text = text and translate(text) or ""
        if tone == "good" then
            status.TextColor3 = legibleOn(PALETTE.accent, PALETTE.background)
        elseif tone == "bad" then
            status.TextColor3 = PALETTE.accentSoft
        else
            status.TextColor3 = PALETTE.subtext
        end
    end

    -- Buttons. Check Key is the primary one and it is filled with the accent, because it is
    -- the only thing on the card anybody came here to press: three identical grey rectangles
    -- made the reader pick it out by reading all three.
    local function flatButton(label, position, size)
        local btn = Instance.new("TextButton")
        btn.Position = position
        btn.Size = size
        btn.BorderSizePixel = 0
        btn.AutoButtonColor = false
        btn.TextSize = 14
        btn.Parent = card
        faced(btn, "medium")
        themed(btn, "BackgroundColor3", "control")
        themed(btn, "TextColor3", "text")
        corner(btn, 9)
        if label then localized(btn, "Text", label) else btn.Text = "" end
        hoverSurface(btn)
        return btn
    end

    local checkBtn = Instance.new("TextButton")
    checkBtn.Position = UDim2.new(0, 20, 0, 142)
    checkBtn.Size = UDim2.new(1, -40, 0, 38)
    checkBtn.BorderSizePixel = 0
    checkBtn.AutoButtonColor = false
    checkBtn.TextSize = 14
    checkBtn.Parent = card
    faced(checkBtn, "bold")
    corner(checkBtn, 9)
    localized(checkBtn, "Text", "Check Key")
    -- A state painter rather than two themed() calls, because the text colour is derived
    -- from the fill: pick a pale accent and white letters on it are not letters. It follows a
    -- live accent change the same way the rest of the kit does.
    local checkHot = false
    addStatePainter(checkBtn, function()
        local accent = shownColor("accent")
        checkBtn.BackgroundColor3 = checkHot and accent:Lerp(Color3.new(1, 1, 1), 0.12) or accent
        checkBtn.TextColor3 = contrastOn(accent)
    end)
    checkBtn.MouseEnter:Connect(function()
        checkHot = true
        runStatePainters()
    end)
    checkBtn.MouseLeave:Connect(function()
        checkHot = false
        runStatePainters()
    end)

    -- The links under it, laid out from the list built at the top.
    do
        local gap = 8
        -- The squares take a fixed 38, the rest is shared by whatever is left. One link on
        -- its own fills the row whichever kind it is.
        local squares, wide = 0, 0
        for _, entry in ipairs(links) do
            if entry.square then squares += 1 else wide += 1 end
        end
        local room = W - 40 - gap * math.max(#links - 1, 0)
        local squareW = (wide > 0) and 38 or math.floor(room / math.max(squares, 1))
        local wideW = (wide > 0) and math.floor((room - squareW * squares) / wide) or 0
        local x = 20
        for _, entry in ipairs(links) do
            local w = entry.square and squareW or wideW
            local btn = flatButton(entry.label, UDim2.new(0, x, 0, LINKS_Y), UDim2.new(0, w, 0, 34))
            x += w + gap
            if entry.icon then
                local img = makeIcon(btn, entry.icon, UDim2.new(0, 18, 0, 18), "icon")
                img.Active = false
                if entry.square then
                    img.AnchorPoint = Vector2.new(0.5, 0.5)
                    img.Position = UDim2.new(0.5, 0, 0.5, 0)
                else
                    img.AnchorPoint = Vector2.new(0, 0.5)
                    img.Position = UDim2.new(0, 12, 0.5, 0)
                    -- Room for the icon, taken off the left so the words stay centred in
                    -- what is left rather than sitting under the mark.
                    btn.TextXAlignment = Enum.TextXAlignment.Center
                    local pad = Instance.new("UIPadding")
                    pad.PaddingLeft = UDim.new(0, 26)
                    pad.Parent = btn
                end
            end
            btn.MouseButton1Click:Connect(function()
                -- The clipboard, and the link itself on screen when there is no clipboard
                -- to put it on. Opening a browser is not attempted: it is an executor
                -- function that plenty of them do not have, and a button that silently does
                -- nothing is worse than one that hands you something to paste.
                local copied = false
                pcall(function()
                    if type(setclipboard) == "function" then
                        setclipboard(entry.url)
                        copied = true
                    end
                end)
                say(copied and "Link copied" or entry.url, nil)
            end)
        end
    end

    local closeBtn = Instance.new("TextButton")
    closeBtn.AnchorPoint = Vector2.new(1, 0.5)
    closeBtn.Position = UDim2.new(1, -16, 0, 31)
    closeBtn.Size = UDim2.new(0, 22, 0, 22)
    closeBtn.BackgroundTransparency = 1
    closeBtn.AutoButtonColor = false
    closeBtn.Text = ""
    closeBtn.Parent = head
    local closeImg = makeIcon(closeBtn, "x", UDim2.new(1, 0, 1, 0), "iconDim")
    closeImg.Active = false
    closeBtn.MouseEnter:Connect(function() tintIcon(closeImg, PALETTE.icon) end)
    closeBtn.MouseLeave:Connect(function() tintIcon(closeImg, PALETTE.iconDim) end)

    -- Settled: true on a pass, false when the prompt was closed or the attempts ran out.
    local answer = nil
    local tries = 0
    local limit = (type(opts.attempts) == "number" and opts.attempts > 0) and opts.attempts or 0
    local busy = false
    local leaving = false
    -- leaving is "on the way out", left is "off the screen". keySystem waits for the second one
    -- before it hands control back, so the window it was gating does not open behind the card.
    local left = false
    local resting = root.Position
    -- The entrance writes root.Position every frame, and so do the two animations below it.
    -- A key submitted inside the first three tenths of a second would otherwise have two
    -- tickers arguing over the same property. Whoever moves next stops the entrance first.
    local stopEnter = nil

    -- Out, and it takes its time about it on a pass.
    --
    -- It used to be a sixteen hundredths fade and nothing else, fired the instant the
    -- validator came back, so "Key accepted" was drawn and painted over in the same breath:
    -- the card blinked out and whether it had accepted anything was a guess. hold keeps it on
    -- screen long enough to read, and then it leaves upwards and accelerating, which is the
    -- opposite curve to the one it arrived on. The window it was gating builds behind it in
    -- that time, so the two cross rather than the screen going empty in between.
    local function finish(result, hold)
        if leaving then return end
        leaving = true
        answer = result
        if stopEnter then stopEnter() stopEnter = nil end
        -- The key goes before the window does, and it goes whether the answer was yes or
        -- no. There is no path out of here that leaves it in the field.
        secret = ""
        writing = true
        input.Text = ""
        writing = false
        -- Let the field go, so a keyboard is not left captured by a window that is leaving.
        pcall(function() input:ReleaseFocus() end)
        local wait = hold or 0
        local stop
        local elapsed = 0
        stop = addTicker(0, function(dt)
            elapsed += dt
            if elapsed < wait then return end
            local t = math.min((elapsed - wait) / 0.2, 1)
            -- Accelerating away: t^2 rather than the softened curve it came in on.
            local eased = t * t
            setAlpha(1 - eased)
            root.Position = UDim2.new(
                resting.X.Scale, resting.X.Offset,
                resting.Y.Scale, math.floor(resting.Y.Offset - 14 * eased + 0.5)
            )
            if t >= 1 then
                if stop then stop() end
                screen:Destroy()
                left = true
            end
        end)
    end

    -- A refused key nudges the card sideways and settles back.
    --
    -- Whole pixels, and the card is moved rather than scaled: the kit does not scale anything
    -- carrying text, and a CanvasGroup resampled at a fractional offset softens every glyph
    -- under it for as long as the animation lasts. Three cycles over a fifth of a second,
    -- which is enough to read as a refusal without being a toy.
    local function refuse()
        if leaving then return end
        if stopEnter then stopEnter() stopEnter = nil end
        setAlpha(1)
        local stop
        local elapsed = 0
        stop = addTicker(0, function(dt)
            elapsed += dt
            local t = math.min(elapsed / 0.22, 1)
            local offset = math.floor(math.sin(t * math.pi * 6) * 7 * (1 - t) + 0.5)
            root.Position = UDim2.new(
                resting.X.Scale, resting.X.Offset + offset,
                resting.Y.Scale, resting.Y.Offset
            )
            if t >= 1 then
                root.Position = resting
                if stop then stop() end
            end
        end)
    end

    local function run()
        local key = secret
        local passed, info = gateRun(key)
        key = nil
        busy = false
        if leaving then return end
        if passed then
            gateToken = mintToken()
            gateInfo = info
            gateFresh = true
            say("Key accepted", "good")
            finish(true, 0.24)
            return
        end
        gateToken = nil
        gateInfo = nil
        tries += 1
        if limit > 0 and tries >= limit then
            say("Too many attempts", "bad")
            refuse()
            finish(false, 0.5)
            return
        end
        say(limit > 0 and ("Invalid key, " .. (limit - tries) .. " left") or "Invalid key", "bad")
        refuse()
    end

    -- inline for a caller that owns its own thread, spawned for a click.
    --
    -- A validator that talks to a key site blocks, and blocking a click handler freezes the
    -- prompt it was clicked on, so the button spawns. submit does not: whoever called it is
    -- already on a thread of their own and would rather have the answer than a promise, and
    -- it is the only way in that a harness with no scheduler can use.
    local function attempt(inline)
        if busy or leaving then return end
        if secret == "" then
            say("Enter your key first", "bad")
            refuse()
            return
        end
        busy = true
        say("Checking..", nil)
        if inline then
            run()
        else
            task.spawn(run)
        end
    end

    checkBtn.MouseButton1Click:Connect(function() attempt(false) end)
    input.FocusLost:Connect(function(enter) if enter then attempt(false) end end)
    closeBtn.MouseButton1Click:Connect(function() finish(false) end)

    -- In, on the same curve the window uses.
    do
        local elapsed = 0
        local from = resting
        root.Position = UDim2.new(from.X.Scale, from.X.Offset, from.Y.Scale, from.Y.Offset + 24)
        stopEnter = addTicker(0, function(dt)
            elapsed += dt
            local t = math.min(elapsed / 0.28, 1)
            local eased = 1 - (1 - t) ^ 5
            setAlpha(eased)
            root.Position = UDim2.new(
                from.X.Scale, from.X.Offset,
                from.Y.Scale, math.floor(from.Y.Offset + 24 * (1 - eased) + 0.5)
            )
            if t >= 1 and stopEnter then
                stopEnter()
                stopEnter = nil
            end
        end)
    end

    -- The handle. Nothing here hands out the key: submit takes one and forgets it, and
    -- there is no getter for what was typed.
    return {
        frame = root,
        submit = function(key)
            if type(key) == "string" then
                secret = key
                render()
            end
            attempt(true)
        end,
        close = function() finish(false) end,
        settled = function() return answer ~= nil end,
        passed = function() return answer == true end,
        -- Settled and off the screen, which is not the same moment: the card holds its answer
        -- long enough to read and then leaves.
        gone = function() return left end,
    }
end

-- Arm the gate and, unless a key was handed in that works, ask for one.
function Interface.keySystem(opts)
    opts = opts or {}
    if opts.enabled == false then return true end
    if type(opts.check) ~= "function" then
        log("warn", "keySystem: no check function, so there is nothing to verify against")
        return true
    end

    -- Before either path, not just the one that draws a prompt. A build that hands its key in
    -- never sees the prompt but still goes straight into building a window, and that window's
    -- first appearance should be in the user's colours rather than snapping into them a moment
    -- after the debut has started. keyPrompt does it again for a caller that goes there
    -- directly; it reads one file and it is idempotent.
    if opts.config ~= false then
        Interface.preloadConfig(type(opts.config) == "string" and opts.config or nil)
    end

    gateCheck = opts.check
    gateOpts = {
        recheck = (type(opts.recheck) == "number" and opts.recheck >= 0) and opts.recheck or 300,
        onLost = type(opts.onLost) == "function" and opts.onLost or nil,
        -- Without this there is no re-checking, and that is the right default: the key is not
        -- kept, so the only thing a timer could send is nothing at all, and a validator asked
        -- to verify nothing says no. See gateRecheck.
        revalidate = type(opts.revalidate) == "function" and opts.revalidate or nil,
    }
    gateToken = nil
    gateInfo = nil

    -- A key handed in by the caller is tried before anything is drawn, so a build that
    -- already has one does not make the user paste it again. It is not remembered here
    -- either: it is an argument to the validator and then it is gone.
    if type(opts.key) == "string" and opts.key ~= "" then
        local passed, info = gateRun(opts.key)
        if passed then
            gateToken = mintToken()
            gateInfo = info
            gateFresh = true
            return true
        end
    end

    local prompt = Interface.keyPrompt(opts)
    -- Bounded. A scheduler that never yields would otherwise leave the caller spinning for
    -- the rest of the session, and refusing after ten minutes is a better failure than a
    -- frozen script with no window and no explanation.
    local limit = (type(opts.timeout) == "number" and opts.timeout > 0) and opts.timeout or 600
    local started = os.clock()
    while not prompt.settled() do
        if os.clock() - started > limit then
            prompt.close()
            return false
        end
        task.wait(0.05)
    end

    -- And then until the card is actually gone, not just until the answer is known.
    --
    -- Returning on the answer let the caller start building its window while the prompt was still
    -- leaving, and the two are separate ScreenGuis on the same DisplayOrder, so which one drew in
    -- front was down to luck. What that looked like was the prompt sitting in the middle of the
    -- screen behind the window that had just opened, fading out from underneath it. Waiting is
    -- half a second at most and the sequence then reads the way it was designed: accepted, gone,
    -- and the interface arrives into an empty screen.
    local waited = os.clock()
    while not prompt.gone() do
        if os.clock() - waited > 2 then break end
        task.wait(0.03)
    end
    return prompt.passed()
end

-- Showcase: run the file directly to preview the design. A product script that
-- embeds this kit sets _G.NewRealityShowcase = false before use to skip it.
function Interface.showcase()
    local win = Interface.new({ icon = "logo" })

    -- A neutral component demo. This is only a preview of the kit, it is not a
    -- product layout, so it just shows each control type once. The worked example
    -- of a real layout lives in examples/interface-demo.luau.
    local home = win:tab({ name = "Dashboard", icon = "layout-dashboard", group = "Main", subtitle = "Overview of every control" })
    do
        local s = home:sub("Controls")
        local basics = s:card({ title = "Basics", icon = "adjustments", subtitle = "Buttons and toggles", column = "left" })
        basics:button("Run Action", function() win:notify({ title = "Action", text = "Button clicked", icon = "bolt" }) end)
        do
            local g, set = win:flag("simpleToggle", true)
            basics:toggle("Simple Toggle", g, set)
        end
        -- get and set are unpacked into locals wherever another argument follows
        -- them: a call takes only the first value of a multi value expression
        -- unless it is the last argument, so passing win:flag() mid-list would
        -- quietly drop the setter.
        do
            local gearGet, gearSet = win:flag("gearToggle", false)
            basics:toggle("Toggle With Settings", gearGet, gearSet, function(sc)
                local innerGet, innerSet = win:flag("gearValue", 40)
                sc:slider("Inner Value", 0, 100, innerGet, innerSet, 0)
                sc:toggle("Inner Toggle", win:flag("gearInner", true))
                sc:label("Everything a card takes works in here too.")
            end)
        end
        do
            -- Multi keybind that can also be cleared (right click) and fires a callback.
            local g, set = win:flag("bindKeys", { "F" })
            basics:keybind("Bind Keys", g, set, { multi = true, callback = function() end })
        end

        local values = s:card({ title = "Values", icon = "gauge", subtitle = "Sliders and steppers", column = "right" })
        do
            local get, set = win:flag("speed", 50)
            values:slider("Speed", 16, 200, get, set, 0)
        end
        do
            local get, set = win:flag("multiplier", 1.5)
            values:slider("Multiplier", 0, 5, get, set, 1)
        end
        values:stepper("Count", 0, 10, 1, win:flag("count", 3))
        values:segmented("Mode", { "Off", "Hold", "On" }, win:flag("mode", "Hold"))

        local more = home:sub("More")
        more:card({ title = "Labels", icon = "info-circle", column = "left" }):label("This sub-tab proves the top tabs switch correctly.")
    end

    local lists = win:tab({ name = "Selectors", icon = "list", group = "Main", subtitle = "Dropdowns, lists, colours" })
    do
        local s = lists:sub("Selectors")
        local pick = s:card({ title = "Pickers", icon = "filter", column = "left" })
        do
            local get, set = win:flag("single", "Alpha")
            pick:dropdown("Single", { "Alpha", "Beta", "Gamma" }, get, set, { search = true })
        end
        do
            local get, set = win:flag("multi", { "Pink" })
            pick:dropdown("Multi", { "Red", "Green", "Blue", "Pink" }, get, set, { multi = true, search = true })
        end
        local accent = { 251, 149, 255, 1 }
        pick:colorpicker("Colour", function() return accent end, function(v) accent = v end)

        local conf = s:card({ title = "Config List", icon = "device-floppy", column = "right" })
        do
            local get, set = win:flag("preset", "Default")
            conf:list({ "Default", "Rage", "Legit", "Custom" }, get, set, { search = true })
        end
    end

    local settings = win:tab({ name = "Settings", icon = "settings", group = "Other", subtitle = "Interface options" })
    do
        local s = settings:sub("Settings")
        local ui = s:card({ title = "Window", icon = "settings", subtitle = "Show and hide", column = "left" })
        ui:keybind("Toggle UI", function() return win.toggleKey.Name end, function(k)
            local ok, key = pcall(function() return Enum.KeyCode[k] end)
            if ok and key then
                win.toggleKey = key
                win:markDirty()
            end
        end)
        ui:button("Unload", function() win:unload() end)

        -- Detached overlays: the watermark strip, the keybind list and a HUD
        -- built from the same rows, all draggable and saved with the config.
        local overlays = s:card({ title = "Panels", icon = "layout-dashboard", subtitle = "Detached panels", column = "left" })
        local wm = win:watermark()
        local binds = win:keybindList({ position = UDim2.new(0, 16, 0, 70) })
        -- No logo on the HUD by default: a panel the script builds gets whatever
        -- header the script asks for, so the choice is left to the caller.
        local demoHud = win:hud({ title = "Session", position = UDim2.new(0, 16, 0, 190) })
        local startedAt = os.clock()
        demoHud:row("Uptime", function()
            local secs = math.floor(os.clock() - startedAt)
            return string.format("%02d:%02d", secs // 60, secs % 60)
        end)
        demoHud:section("Status")
        demoHud:row({ label = "Farm", dot = function() return (os.clock() % 4) < 2 end, value = "Idle" })
        demoHud:bar("Progress", function() return (os.clock() % 10) / 10 end)
        overlays:toggle("Watermark", function() return wm.Visible end, function(v) win:showOverlay(wm, v) end)
        overlays:toggle("Keybind List", function() return binds.Visible end, function(v) win:showOverlay(binds, v) end)
        overlays:toggle("Session HUD", function() return demoHud.frame.Visible end, function(v) demoHud:setVisible(v) end)

        -- Live theme colours, from the card method rather than written out here: the
        -- preset dropdown and a row per key, every tagged part recolouring as it changes.
        s:card({ title = "Theme", icon = "palette", subtitle = "Colour every part", column = "left" }):theme()

        local cfg = s:card({ title = "Save Manager", icon = "device-floppy", subtitle = "Configurations", column = "right" })
        local cfgSel = "default"
        local function cfgList()
            local list = { "default" }
            for _, n in ipairs(win:listConfigs()) do
                if n ~= "default" then table.insert(list, n) end
            end
            return list
        end
        cfg:dropdown("Config", cfgList, function() return cfgSel end, function(v) cfgSel = v end, { search = true })
        cfg:button("Save", function() win:saveConfig(cfgSel) end)
        cfg:button("Load", function() win:loadConfig(cfgSel) end)
    end
    return win
end

if _G.NewRealityShowcase ~= false then
    pcall(Interface.showcase)
end

-- What the loader receives is a read only view of the module: reads pass
-- through, writes are refused and the metatable cannot be pulled back, so a
-- foreign script cannot swap new() for its own copy or walk the internals from
-- the handle it was given. Sub-tables that are meant to be edited stay open,
-- Interface.icons[name] = "rbxassetid://.." still works.
local api = setmetatable({}, {
    __index = Interface,
    __newindex = function()
        error("[NewReality] interface is read only", 2)
    end,
    __metatable = "locked",
    __tostring = function()
        return "NewReality interface " .. Interface.version
    end,
})

return api
