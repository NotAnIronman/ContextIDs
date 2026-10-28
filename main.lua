local Target = require("lib/target")
local Text = require("lib/text")
local hover = require("lib/native_hover").new()
local cursor = require("lib/cursor_overlay").new()
local function clearDisplay() hover:clear(); cursor:hide() end
local settings = require("lib/settings").new(PersistentDB, clearDisplay)
local spawner = require("lib/item_spawner").new({
    items=function() return require("lib/item_data") end,
    lookup=function(itemID) return config.Obj.FromID(itemID) end,
    execute=function(command) ExecuteConsoleCommand(command) end,
})
local spawnerView = require("lib/spawner_view").new(spawner,function()
    return type(ExecuteConsoleCommand) == "function"
end)
local focused, selected = true, nil
local reference = "context-ids"
local subscriptions = {}
local originals = setmetatable({}, {__mode="k"})

local function allowed()
    if not focused then return false end
    if not settings.holdControl then return true end
    local ok, down = pcall(function() return Keyboard.IsControlDown() end)
    return ok and down == true
end

local function subscribe(name, callback)
    Event[name].Subscribe(reference, callback)
    subscriptions[#subscriptions+1] = name
end

subscribe("MiniMenuReady", function(event)
    local entries = event.miniMenu.entries
    local show = allowed()
    for _, entry in ipairs(entries) do
        local old = originals[entry]
        if old and entry.overrideText == old.rendered then entry.overrideText = old.original end
        originals[entry] = nil
        if show then
            local target = Target.resolve(entry)
            if target and (target.kind ~= "Interface" or target.spriteID ~= nil) then
                local original = entry.overrideText or ""
                local base = original ~= "" and original or entry.fullText
                local rendered = base .. Text.annotation(target)
                entry.overrideText = rendered
                originals[entry] = {original=original, rendered=rendered}
            end
        end
    end
    selected = Target.resolve(entries[#entries])
    if not selected or not show then clearDisplay() end
end)

subscribe("Draw", function()
    spawnerView:draw()
    if not selected or not allowed() or MiniMenu.IsOpen() then clearDisplay(); return end
    if selected.kind == "Interface" then
        hover:clear()
        cursor:show(Text.label(selected))
    else
        cursor:hide()
        hover:setTarget(selected.name, Text.annotation(selected))
        hover:draw()
    end
end)

subscribe("MiniMenuOpened", clearDisplay)
subscribe("WindowFocusChanged", function(event)
    focused = event.hasFocus
    if not focused then selected = nil; clearDisplay() end
end)
subscribe("GameStateChanged", function()
    selected = nil
    hover:clear()
    cursor:clear()
    spawnerView:clear()
end)
subscribe("SettingsLayerReady", function(event) settings:build(event.component) end)
subscribe("ContentLayerReady", function(event)
    selected = nil
    clearDisplay()
    spawnerView:build(event.component)
end)

function PluginShutdown()
    for _, name in ipairs(subscriptions) do Event[name].Unsubscribe(reference) end
    hover:clear()
    cursor:clear()
    spawnerView:clear()
end
