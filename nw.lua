-- NewReality interface - worked example
-- A product shaped script built on the UI library: every control, the detached
-- panels, live theming, translations and the config manager, laid out the way a
-- real script lays them out rather than as a list of components.
--
-- Nothing here touches the game. Each control writes a flag and the flags are
-- read back on screen, so the example can be dropped into any place and the only
-- thing it changes is its own state.
--
-- Run it with an executor:
--   loadstring(game:HttpGet("https://raw.githubusercontent.com/<repo>/main/examples/interface-demo.luau"))()

_G.NewRealityShowcase = false

local URL = "https://raw.githubusercontent.com/ccodix0-gif/lib/refs/heads/main/nw.lua"

local source
local okHttp, httpErr = pcall(function() source = game:HttpGet(URL) end)
if not okHttp or type(source) ~= "string" or #source < 1000 then
    warn("[DEMO] HttpGet failed: " .. tostring(httpErr))
    return
end
local chunk, compileErr = loadstring(source)
if not chunk then
    warn("[DEMO] compile failed: " .. tostring(compileErr))
    return
end
local okRun, UI = pcall(chunk)
if not okRun or type(UI) ~= "table" then
    warn("[DEMO] run failed: " .. tostring(UI))
    return
end

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- Translations ----------------------------------------------------------------
-- Optional. Delete this block and the script runs in English with no language
-- control anywhere in it, because the Settings tab below only builds that control
-- when at least one language has been registered.
--
-- Phrases are keyed by the English text, so the layout is written once and a
-- language only lists what it wants changed.
UI.addLocale("ru", {
    -- Chrome the library draws itself
    None = "Нет",
    Settings = "Настройки",
    ["Search.."] = "Поиск..",
    On = "Вкл",
    Off = "Выкл",

    -- Sidebar groups, tabs and their subtitles
    Main = "Основное",
    Other = "Прочее",
    Farm = "Фарм",
    Automation = "Автоматизация",
    Visuals = "Визуал",
    ["Players and world"] = "Игроки и мир",
    ["Window, panels, theme, configs"] = "Окно, панели, тема, конфиги",

    -- Sub-tabs
    Auto = "Авто",
    Targets = "Цели",
    Players = "Игроки",
    World = "Мир",

    -- Farm
    ["Farm loop"] = "Цикл фарма",
    ["The main worker"] = "Основной рабочий",
    Behaviour = "Поведение",
    Radius = "Радиус",
    Delay = "Задержка",
    Retries = "Повторы",
    Mode = "Режим",
    Hold = "Удержание",
    Toggle = "Переключение",
    Always = "Всегда",
    ["Every control writes into win.flags, and auto save keeps them between sessions."] =
        "Каждый контрол пишет в win.flags, автосохранение хранит их между сессиями.",
    ["Reset counter"] = "Сбросить счётчик",
    Notifications = "Уведомления",
    ["Toast behaviour"] = "Поведение уведомлений",
    ["Toasts slide in from the right edge and push the stack up. Click one to dismiss it early."] =
        "Уведомления выезжают справа и поднимают стопку. Клик закрывает досрочно.",
    ["Send one"] = "Отправить одно",
    ["Send five"] = "Отправить пять",
    ["Title only"] = "Только заголовок",
    Priority = "Приоритет",
    Closest = "Ближайший",
    Weakest = "Слабейший",
    Strongest = "Сильнейший",
    ["Ignore list"] = "Список исключений",
    ["Pause farm"] = "Пауза фарма",
    Preset = "Пресет",
    Safe = "Осторожно",
    Balanced = "Сбалансированно",
    Greedy = "Жадно",
    Collected = "Собрано",
    Enabled = "Включено",
    Reset = "Сброшено",

    -- Visuals
    ["Player ESP"] = "ESP игроков",
    ["Boxes, names, tracers"] = "Боксы, имена, трейсеры",
    Boxes = "Боксы",
    Style = "Стиль",
    Corner = "Углы",
    Full = "Полностью",
    Outline = "Обводка",
    ["Fill opacity"] = "Прозрачность заливки",
    ["Box colour"] = "Цвет боксов",
    ["Team check"] = "Проверка команды",
    Names = "Имена",
    Tracers = "Трейсеры",
    ["Name colour"] = "Цвет имён",
    ["Max distance"] = "Макс. дистанция",
    Labels = "Подписи",
    Prefix = "Префикс",
    ["shown before a name"] = "перед именем",
    Opacity = "Прозрачность",
    ["A colour picker carries opacity as the fourth value. The grid under the bar is what tells you how transparent the colour is."] =
        "Пикер несёт прозрачность четвёртым значением. Сетка под полосой показывает, насколько цвет прозрачен.",
    Translucent = "Полупрозрачный",
    ["Solid only"] = "Только плотный",
    Environment = "Окружение",
    ["Full bright"] = "Полная яркость",
    ["Time of day"] = "Время суток",
    ["No fog"] = "Без тумана",

    -- Settings: window
    Window = "Окно",
    ["Show and hide"] = "Показ и скрытие",
    ["Toggle interface"] = "Открыть интерфейс",
    ["The key is saved with the config, so it survives a restart."] =
        "Клавиша сохраняется в конфиге и переживает перезапуск.",
    ["Hide window"] = "Скрыть окно",
    Unload = "Выгрузить",

    -- Settings: detached panels
    Panels = "Панели",
    ["Drag any panel to move it"] = "Панель можно перетащить",
    Watermark = "Ватермарка",
    ["Keybind list"] = "Список бинда",
    ["Session panel"] = "Панель сессии",
    ["Rename session"] = "Переименовать панель",
    Session = "Сессия",
    Farming = "Фарм идёт",
    Uptime = "Время",
    Farmed = "Нафармлено",
    Progress = "Прогресс",
    Cycle = "Цикл",
    Note = "Заметка",
    Running = "Работает",
    Idle = "Простой",

    -- Library chrome for the search field
    ["Search the interface.."] = "Поиск по интерфейсу..",
    ["Nothing found"] = "Ничего не найдено",

    -- Settings: theme
    Theme = "Тема",
    ["Every key is live"] = "Каждый ключ живой",
    Keys = "Ключи",
    Accent = "Акцент",
    Icons = "Иконки",
    ["Dim icons"] = "Приглушённые иконки",
    Knobs = "Ручки",
    Share = "Поделиться",
    ["Through the clipboard"] = "Через буфер обмена",
    ["Copy config"] = "Скопировать конфиг",
    ["Paste here"] = "Вставить сюда",
    ["paste a config"] = "вставь конфиг",
    ["Apply pasted"] = "Применить вставленное",
    Copied = "Скопировано",
    Applied = "Применено",
    ["Not a config"] = "Это не конфиг",
    Background = "Фон",
    Sidebar = "Боковая панель",
    Cards = "Карточки",
    Controls = "Контролы",
    Track = "Дорожка",
    Text = "Текст",
    ["Reset theme"] = "Сбросить тему",
    ["Translucent window"] = "Полупрозрачное окно",
    ["Opaque window"] = "Плотное окно",
    ["Drop the opacity of a key and the whole surface follows, outlines and text with it."] =
        "Уменьши прозрачность ключа, и вся поверхность последует за ним вместе с обводками и текстом.",

    -- Settings: configs
    Configs = "Конфиги",
    ["Per game"] = "Отдельно для каждой игры",
    Config = "Конфиг",
    Name = "Название",
    ["new config name"] = "название конфига",
    Create = "Создать",
    Save = "Сохранить",
    Load = "Загрузить",
    Delete = "Удалить",
    Saved = "Сохранено",
    Loaded = "Загружено",
    Created = "Создано",
    Deleted = "Удалено",
    Persistence = "Хранение",
    ["Load on launch"] = "Загружать при запуске",
    ["Auto save"] = "Автосохранение",
    ["A config keeps the flags, the palette with its opacity, the show and hide key, the language and every detached panel."] =
        "Конфиг хранит флаги, палитру с прозрачностью, клавишу показа, язык и все отсоединённые панели.",

    -- Settings: language
    Language = "Язык",
    ["Re-labels without a rebuild"] = "Переподписывает без пересборки",

    -- Farm: the multi keybind
    Boost = "Ускорение",
    ["Boost farm"] = "Ускорить фарм",

    -- Panels
    ["Targets panel"] = "Панель целей",
    ["In range"] = "В радиусе",
    Queue = "Очередь",
    Workload = "Нагрузка",

    -- Extras
    Extras = "Дополнительно",
    ["Icons, colours, diagnostics"] = "Иконки, цвета, диагностика",
    ["Icon pack"] = "Набор иконок",
    ["Embedded in the library"] = "Встроен в библиотеку",
    Icon = "Иконка",
    ["Send with this icon"] = "Отправить с этой иконкой",
    ["Own artwork"] = "Своя графика",
    ["Register a name"] = "Зарегистрировать имя",
    Colours = "Цвета",
    Pickers = "Пикеры",
    ["With and without opacity"] = "С прозрачностью и без",
    ["With opacity"] = "С прозрачностью",
    Without = "Без",
    Recent = "Недавние",
    ["Shared by every picker"] = "Общие для всех пикеров",
    ["Clear recent"] = "Очистить недавние",
    ["Seed a few"] = "Заполнить примером",
    ["Recent cleared"] = "Недавние очищены",
    ["Recent seeded"] = "Недавние заполнены",
    Diagnostics = "Диагностика",
    Build = "Сборка",
    ["Diagnostics to console"] = "Диагностика в консоль",
    ["A config exists on disk"] = "На диске есть конфиг",
    ["Try it"] = "Попробуй",
    ["The parts that move"] = "То, что движется",
    ["Open the first section"] = "Открыть первый раздел",
    ["Open the last section"] = "Открыть последний раздел",
    ["Pick a section further down the sidebar and the page comes up from below; pick one above and it comes down. Sub-pages travel sideways along their bar."] =
        "Выбери раздел ниже по списку, и страница придёт снизу; выше, и придёт сверху. Подстраницы едут вбок по своей полосе.",
    ["Open a dropdown, then drag the window by its title: the panel stays open and travels with it. Scroll the column and the panel leaves in the direction its row went."] =
        "Открой список и потяни окно за заголовок: панель останется открытой и поедет с окном. Прокрути колонку, и панель уйдёт туда же, куда ушла её строка.",
    ["The library writes nothing to the console on its own. A script that wants the diagnostics asks for them, and gets the level with the message."] =
        "Библиотека сама ничего не пишет в консоль. Скрипту, которому нужна диагностика, она выдаётся вместе с уровнем сообщения.",
    ["Every colour a picker lands on goes to the front of the recent row, which is saved with the config. The last slot in the row empties it."] =
        "Каждый цвет, на котором останавливается пикер, встаёт в начало строки недавних, и она сохраняется в конфиге. Последняя ячейка строки её очищает.",
    ["A picker carries opacity as the fourth value. The grid under the bar and behind the swatch is what tells you how transparent the colour is, and the number beside the bar is what it is."] =
        "Пикер несёт прозрачность четвёртым значением. Сетка под полосой и за образцом показывает, насколько цвет прозрачен, а число рядом с полосой говорит, насколько именно.",
    ["UI.icons takes a Roblox asset id under a name of your own, and UI.setIconFolder reads PNGs off the executor's disk instead of the pack."] =
        "UI.icons принимает id ассета Roblox под своим именем, а UI.setIconFolder читает PNG с диска исполнителя вместо набора.",
    ["A name the pack does not have draws nothing at all rather than a broken square, so a typo costs an icon and not the layout."] =
        "Имени, которого нет в наборе, соответствует пустота, а не битый квадрат, поэтому опечатка стоит иконки, а не вёрстки.",
})

local win = UI.new({ icon = "logo", toggleKey = Enum.KeyCode.RightShift })

-- The library writes nothing to the console on its own. There is a toggle for this
-- on the Extras tab, and a script can install its own handler at any point.
-- UI.setLogger(function(level, message) warn(level, message) end)



local F = win.flags
local startedAt = os.clock()
local farmed = 0

-- Farm ------------------------------------------------------------------------
local tFarm = win:tab({ name = "Farm", icon = "seedling", group = "Main", subtitle = "Automation" })
do
    local page = tFarm:sub("Auto")

    local loop = page:card({
        title = "Farm loop",
        subtitle = "The main worker",
        icon = "bolt",
        column = "left",
        -- A card can carry its own enable switch in the header. Either shape
        -- works: the pair straight from win:flag, or get and set by name.
        toggle = { win:flag("farmEnabled", false) },
    })
    loop:section("Behaviour")
    do
        -- get and set come back as two values. They unpack on their own only when
        -- they are the last arguments, so anywhere another argument follows they
        -- go into locals first.
        local get, set = win:flag("farmRadius", 60)
        loop:slider("Radius", 10, 250, get, set, 0)
    end
    do
        local get, set = win:flag("farmDelay", 0.35)
        loop:slider("Delay", 0.05, 2, get, set, 2, function(v) return v .. " s" end)
    end
    loop:stepper("Retries", 0, 10, 1, win:flag("farmRetries", 3))
    loop:segmented("Mode", { "Hold", "Toggle", "Always" }, win:flag("farmMode", "Toggle"))
    loop:divider()
    loop:label("Every control writes into win.flags, and auto save keeps them between sessions.")
    loop:button("Reset counter", function()
        farmed = 0
        win:notify({ title = "Farm", text = "Reset", icon = "trash" })
    end)

    local notify = page:card({ title = "Notifications", icon = "bell", subtitle = "Toast behaviour", column = "right" })
    notify:label("Toasts slide in from the right edge and push the stack up. Click one to dismiss it early.")
    notify:button("Send one", function()
        win:notify({ title = "Farm", text = "Enabled", icon = "bolt" })
    end)
    notify:button("Send five", function()
        for i = 1, 5 do
            task.delay(i * 0.12, function()
                win:notify({ title = "Collected", text = tostring(i), icon = "diamond", duration = 4 })
            end)
        end
    end)
    notify:button("Title only", function()
        win:notify("Saved")
    end)

    local targets = tFarm:sub("Targets")
    local filter = targets:card({ title = "Priority", icon = "current-location", column = "left" })
    do
        local get, set = win:flag("farmPriority", "Closest")
        filter:dropdown("Priority", { "Closest", "Weakest", "Strongest" }, get, set, { search = true })
    end
    do
        -- A dynamic list: the options are read again every time the panel opens.
        local get, set = win:flag("farmIgnore", {})
        filter:dropdown("Ignore list", function()
            local names = {}
            for _, player in ipairs(Players:GetPlayers()) do
                if player ~= LocalPlayer then table.insert(names, player.Name) end
            end
            if #names == 0 then table.insert(names, LocalPlayer.Name) end
            return names
        end, get, set, { multi = true, search = true })
    end
    do
        local get, set = win:flag("farmPauseKey", "F")
        filter:keybind("Pause farm", get, set, {
            active = function() return F.farmEnabled end,
            callback = function()
                F.farmEnabled = not F.farmEnabled
                win:markDirty()
                win:refreshAll()
            end,
        })
    end
    do
        -- A keybind can hold several keys. Any one of them fires the callback, and
        -- the keybind panel lists them together.
        local get, set = win:flag("farmBoostKeys", { "LeftShift", "MouseButton2" })
        filter:keybind("Boost", get, set, {
            multi = true,
            listName = "Boost farm",
            active = function() return F.farmEnabled end,
        })
    end

    local list = targets:card({ title = "Preset", icon = "list", column = "right" })
    do
        local get, set = win:flag("farmPreset", "Balanced")
        list:list({ "Safe", "Balanced", "Greedy" }, get, set, { search = true })
    end
end

-- Visuals ---------------------------------------------------------------------
local tVisuals = win:tab({ name = "Visuals", icon = "eye", group = "Main", subtitle = "Players and world" })
do
    local page = tVisuals:sub("Players")
    local esp = page:card({ title = "Player ESP", icon = "eye", subtitle = "Boxes, names, tracers", column = "left" })

    -- A gear popover keeps a long option list off the card: the whole control set
    -- is available inside it.
    do
        local get, set = win:flag("espBoxes", true)
        esp:toggle("Boxes", get, set, function(sc)
            sc:dropdown("Style", { "Corner", "Full", "Outline" }, win:flag("espBoxStyle", "Corner"))
            local fillGet, fillSet = win:flag("espBoxFill", 70)
            sc:slider("Fill opacity", 0, 100, fillGet, fillSet, 0)
            sc:colorpicker("Box colour", win:flag("espBoxColor", { 0, 255, 255, 1 }))
            sc:toggle("Team check", win:flag("espTeamCheck", true))
        end)
    end
    esp:toggle("Names", win:flag("espNames", true))
    esp:toggle("Tracers", win:flag("espTracers", false))
    esp:colorpicker("Name colour", win:flag("espNameColor", { 255, 255, 255, 1 }))
    do
        local get, set = win:flag("espDistance", 500)
        esp:slider("Max distance", 50, 2000, get, set, 0, function(v) return v .. " m" end)
    end

    local text = page:card({ title = "Labels", icon = "quote", column = "right" })
    text:input("Prefix", "shown before a name", win:flag("espPrefix", ""))
    text:section("Opacity")
    text:label("A colour picker carries opacity as the fourth value. The grid under the bar is what tells you how transparent the colour is.")
    text:colorpicker("Translucent", win:flag("espGlow", { 0, 255, 255, 0.35 }))
    do
        local get, set = win:flag("espSolid", { 255, 80, 80 })
        text:colorpicker("Solid only", get, set, { alpha = false })
    end

    local world = tVisuals:sub("World")
    local env = world:card({ title = "Environment", icon = "world", column = "left" })
    env:toggle("Full bright", win:flag("worldBright", false))
    do
        local get, set = win:flag("worldTime", 14)
        env:slider("Time of day", 0, 24, get, set, 0, function(v) return v .. ":00" end)
    end
    env:toggle("No fog", win:flag("worldFog", false))
end

-- Extras ----------------------------------------------------------------------
-- The parts of the kit a product script usually only touches once: the icon pack,
-- the swatches every picker offers, and the diagnostics the library keeps quiet
-- about unless it is asked.
local tExtras = win:tab({ name = "Extras", icon = "sparkles-2", group = "Other", subtitle = "Icons, colours, diagnostics" })
do
    local page = tExtras:sub("Icons")
    local names = UI.iconNames()
    local picked = "bolt"

    local pack = page:card({ title = "Icon pack", icon = "icons", subtitle = "Embedded in the library", column = "left" })
    pack:label(#names .. " icons are carried inside the library file and unpacked once per build, so a script needs no assets of its own.")
    -- The whole pack in one dropdown, which is what the search field in a dropdown
    -- is for: picking out of a hundred and thirty names by scrolling is no use.
    pack:dropdown("Icon", names, function() return picked end, function(value) picked = value end, { search = true })
    pack:button("Send with this icon", function()
        win:notify({ title = "Icon", text = picked, icon = picked })
    end)
    pack:divider()
    pack:label("A name the pack does not have draws nothing at all rather than a broken square, so a typo costs an icon and not the layout.")

    local own = page:card({ title = "Own artwork", icon = "asset", column = "right" })
    own:label("UI.icons takes a Roblox asset id under a name of your own, and UI.setIconFolder reads PNGs off the executor's disk instead of the pack.")
    own:button("Register a name", function()
        UI.icons["demo-mark"] = UI.iconAsset("crown") or ""
        win:notify({ title = "Icons", text = "demo-mark registered", icon = "demo-mark" })
    end)

    local colours = tExtras:sub("Colours")
    local house = colours:card({ title = "Pickers", icon = "palette", subtitle = "With and without opacity", column = "left" })
    house:label("A picker carries opacity as the fourth value. The grid under the bar and behind the swatch is what tells you how transparent the colour is, and the number beside the bar is what it is.")
    house:colorpicker("With opacity", win:flag("extraHouse", { 0, 255, 255, 1 }))
    do
        -- No opacity on this one, so the picker drops the bar, the number and the grid.
        local get, set = win:flag("extraFlat", { 120, 200, 255 })
        house:colorpicker("Without", get, set, { alpha = false })
    end

    local recent = colours:card({ title = "Recent", icon = "clock", subtitle = "Shared by every picker", column = "right" })
    recent:label("Every colour a picker lands on goes to the front of the recent row, which is saved with the config. The last slot in the row empties it.")
    recent:button("Clear recent", function()
        UI.clearRecentColors()
        win:notify({ title = "Colours", text = "Recent cleared", icon = "trash" })
    end)
    recent:button("Seed a few", function()
        for _, hex in ipairs({ "#FF0044", "#FFAA00", "#22DD88", "#2288FF" }) do
            UI.pushRecentColor(hex)
        end
        win:markDirty()
        win:notify({ title = "Colours", text = "Recent seeded", icon = "droplet" })
    end)

    local diagnostics = tExtras:sub("Diagnostics")
    local build = diagnostics:card({ title = "Build", icon = "info-circle", column = "left" })
    build:label("Version " .. tostring(UI.version) .. ", " .. #names .. " icons, " .. #UI.themeNames() .. " themes.")
    local logging = false
    build:toggle("Diagnostics to console", function() return logging end, function(value)
        logging = value
        UI.setLogger(value and function(level, message)
            warn("[NW " .. level .. "] " .. message)
        end or nil)
    end)
    build:label("The library writes nothing to the console on its own. A script that wants the diagnostics asks for them, and gets the level with the message.")
    -- A control with no setter draws its value and ignores the press, which is how a
    -- state the script owns and the user only reads is put on a card.
    build:toggle("A config exists on disk", function() return #win:listConfigs() > 0 end)

    local motion = diagnostics:card({ title = "Try it", icon = "keyframes", subtitle = "The parts that move", column = "right" })
    motion:label("Pick a section further down the sidebar and the page comes up from below; pick one above and it comes down. Sub-pages travel sideways along their bar.")
    motion:button("Open the first section", function() win.tabs[1].activate() end)
    motion:button("Open the last section", function() win.tabs[#win.tabs].activate() end)
    motion:label("Open a dropdown, then drag the window by its title: the panel stays open and travels with it. Scroll the column and the panel leaves in the direction its row went.")
end

-- Settings --------------------------------------------------------------------
-- Everything that configures the interface itself lives on one page: the window,
-- the detached panels, the palette, the configs and the language. They are all
-- things you set once for the kit rather than for the script, and splitting them
-- over sub-tabs meant hunting for which one held what.
local tSettings = win:tab({ name = "Settings", icon = "settings", group = "Other", subtitle = "Window, panels, theme, configs" })
do
    local page = tSettings:sub("Settings")

    -- The detached panels. A HUD is built by the script, so it gets whatever header
    -- the script asks for: a title on its own here, and logo = true or an icon name
    -- when one is wanted.
    local watermark = win:watermark({ show = { logo = true, brand = true, fps = true, time = true } })
    local keybinds = win:keybindList({ position = UDim2.new(0, 16, 0, 70), width = 200, showInactive = true })

    local session = win:hud({
        title = "Session",
        width = 200,
        position = UDim2.new(0, 16, 0, 210),
        id = "session",
        interval = 0.1,
    })
    session:row("Uptime", function()
        local secs = math.floor(os.clock() - startedAt)
        return string.format("%02d:%02d", secs // 60, secs % 60)
    end)
    session:row("Farmed", function() return farmed end)
    session:row({ label = "Farm", dot = function() return F.farmEnabled end, value = function()
        return F.farmEnabled and "Running" or "Idle"
    end })
    session:section("Progress")
    session:bar("Cycle", function() return (os.clock() % 8) / 8 end, {
        text = function(ratio) return math.floor(ratio * 100) .. "%" end,
    })
    session:divider()
    local note = session:row("Note", "-")
    note:set("pushed value")

    -- A second panel, headed with an icon instead of the two layer mark, to show that
    -- the header is whatever the script asks for and nothing it did not ask for.
    local targetsHud = win:hud({
        title = "Targets",
        icon = "current-location",
        width = 178,
        position = UDim2.new(0, 16, 0, 420),
        id = "targets",
        interval = 0.25,
        visible = false,
    })
    targetsHud:row("In range", function()
        return math.max(#Players:GetPlayers() - 1, 0)
    end)
    targetsHud:row({ label = "Priority", value = function() return tostring(F.farmPriority or "Closest") end })
    targetsHud:section("Workload")
    targetsHud:bar("Queue", function() return ((os.clock() * 0.3) % 1) end)

    -- Left column: the window, then the palette.
    local behaviour = page:card({ title = "Window", icon = "settings", subtitle = "Show and hide", column = "left" })
    behaviour:keybind("Toggle interface", function() return win.toggleKey.Name end, function(key)
        local ok, code = pcall(function() return Enum.KeyCode[key] end)
        if ok and code then
            win.toggleKey = code
            win:markDirty()
        end
    end, { listName = "Interface" })
    behaviour:label("The key is saved with the config, so it survives a restart.")
    behaviour:button("Hide window", function() win:toggle(false) end)
    behaviour:button("Unload", function() win:unload() end)

    local colours = page:card({ title = "Theme", icon = "palette", subtitle = "Every key is live", column = "left" })
    -- Presets are partial palettes: one that names only the accent leaves the greys
    -- where the user put them.
    colours:dropdown("Preset", UI.themeNames(), function() return win:getTheme() or "NewReality" end, function(name)
        win:applyTheme(name)
        win:refreshAll()
    end, { search = true })
    colours:section("Keys")
    local function themeKey(label, key)
        colours:colorpicker(label, function() return win:getColor(key) end, function(rgb)
            win:setColor(key, rgb)
        end)
    end
    themeKey("Accent", "accent")
    themeKey("Background", "background")
    themeKey("Sidebar", "sidebar")
    themeKey("Cards", "card")
    themeKey("Controls", "control")
    themeKey("Track", "track")
    themeKey("Text", "text")
    -- Marks have their own keys, so recolouring the text leaves the icons and the
    -- knobs alone.
    themeKey("Icons", "icon")
    themeKey("Dim icons", "iconDim")
    themeKey("Knobs", "knob")
    themeKey("Outline", "stroke")
    colours:divider()
    colours:section("Opacity")
    colours:label("Drop the opacity of a key and the whole surface follows, outlines and text with it.")
    local function setOpacity(value)
        for _, key in ipairs({ "background", "card" }) do
            local rgb = win:getColor(key)
            win:setColor(key, { rgb[1], rgb[2], rgb[3], value })
        end
    end
    colours:button("Translucent window", function() setOpacity(0.78) end)
    colours:button("Opaque window", function() setOpacity(1) end)
    colours:button("Reset theme", function()
        win:resetTheme()
        win:notify({ title = "Theme", text = "Reset", icon = "palette" })
    end)

    -- Right column: the panels, the configs, what persists, and the language.
    local switches = page:card({ title = "Panels", icon = "layout-dashboard", subtitle = "Drag any panel to move it", column = "right" })
    switches:toggle("Watermark", function() return watermark.Visible end, function(v) win:showOverlay(watermark, v) end)
    switches:toggle("Keybind list", function() return keybinds.Visible end, function(v) win:showOverlay(keybinds, v) end)
    switches:toggle("Session panel", function() return session.frame.Visible end, function(v) session:setVisible(v) end)
    switches:toggle("Targets panel", function() return targetsHud.frame.Visible end, function(v) targetsHud:setVisible(v) end)
    switches:button("Rename session", function()
        session:setTitle(F.farmEnabled and "Farming" or "Session")
    end)

    local selected = win:getAutoLoad() or "default"
    local newName = ""
    local function configList()
        local list = { "default" }
        for _, name in ipairs(win:listConfigs()) do
            if name ~= "default" then table.insert(list, name) end
        end
        return list
    end

    local manager = page:card({ title = "Configs", icon = "device-floppy", subtitle = "Per game", column = "right" })
    manager:dropdown("Config", configList, function() return selected end, function(v) selected = v end, { search = true })
    manager:input("Name", "new config name", function() return newName end, function(v) newName = v end)
    manager:button("Create", function()
        if newName == "" then return end
        if win:saveConfig(newName) then
            selected = newName
            newName = ""
            win:refreshAll()
            win:notify({ title = "Config", text = "Created", icon = "device-floppy" })
        end
    end)
    manager:button("Save", function()
        if win:saveConfig(selected) then
            win:notify({ title = "Config", text = "Saved", icon = "device-floppy" })
        end
    end)
    manager:button("Load", function()
        if win:loadConfig(selected) then
            win:notify({ title = "Config", text = "Loaded", icon = "download" })
        end
    end)
    manager:button("Delete", function()
        if selected ~= "default" and win:deleteConfig(selected) then
            selected = "default"
            win:refreshAll()
            win:notify({ title = "Config", text = "Deleted", icon = "trash" })
        end
    end)

    -- The clipboard carries the same snapshot a file does, which is how people
    -- actually share a setup.
    local share = page:card({ title = "Share", icon = "copy", subtitle = "Through the clipboard", column = "right" })
    local pasted = ""
    share:button("Copy config", function()
        local text = win:exportConfig()
        if text then
            win:notify({ title = "Config", text = "Copied", icon = "copy" })
        end
    end)
    share:input("Paste here", "paste a config", function() return pasted end, function(v) pasted = v end)
    share:button("Apply pasted", function()
        if win:importConfig(pasted ~= "" and pasted or nil) then
            pasted = ""
            win:refreshAll()
            win:notify({ title = "Config", text = "Applied", icon = "download" })
        else
            win:notify({ title = "Config", text = "Not a config", icon = "alert-triangle" })
        end
    end)

    local persist = page:card({ title = "Persistence", icon = "database", column = "right" })
    persist:toggle("Load on launch", function() return win:getAutoLoad() ~= nil end, function(v)
        win:setAutoLoad(v and selected or nil)
    end)
    persist:toggle("Auto save", function() return win:getAutoSave() ~= nil end, function(v)
        win:setAutoSave(v and selected or nil)
    end)
    persist:label("A config keeps the flags, the palette with its opacity, the show and hide key, the language and every detached panel.")

    -- Translations are opt in, so the control only exists when a language was
    -- registered. Drop the addLocale call at the top and this card never appears.
    if UI.hasLocales() then
        local LANGS = { { label = "English", code = "en" }, { label = "Русский", code = "ru" } }
        local names = {}
        for _, entry in ipairs(LANGS) do table.insert(names, entry.label) end
        local function codeOf(label)
            for _, entry in ipairs(LANGS) do
                if entry.label == label then return entry.code end
            end
            return "en"
        end
        local function labelOf(code)
            for _, entry in ipairs(LANGS) do
                if entry.code == code then return entry.label end
            end
            return names[1]
        end
        local lang = page:card({ title = "Language", icon = "world", subtitle = "Re-labels without a rebuild", column = "right" })
        lang:list(names, function() return labelOf(win:getLocale()) end, function(label)
            win:setLocale(codeOf(label))
        end, { search = false })
    end
end

-- A stand in for the work a real script would do: it only moves the numbers the
-- session panel is reading.
task.spawn(function()
    while win.screen and win.screen.Parent do
        if F.farmEnabled then
            farmed += 1
        end
        task.wait(math.max(F.farmDelay or 0.35, 0.1))
    end
end)

-- Startup: load the config that was marked for launch, then keep writing to it.
local auto = win:getAutoLoad()
if auto then
    pcall(function() win:loadConfig(auto) end)
end
win:setAutoSave(auto or "default")
win:refreshAll()

win:notify({
    title = "NewReality",
    text = "Right Shift hides the interface",
    icon = "bolt",
    duration = 5,
})

return win
