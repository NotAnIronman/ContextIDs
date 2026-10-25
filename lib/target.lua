local Text = require("lib/text")
local M = {}

local function validID(value)
    return type(value) == "number" and value >= 0 and value <= 2147483647 and value % 1 == 0
end

local function resolve(entry)
    if not entry then return nil end
    local kind, value, fallback
    if entry.actionEntryType == MiniMenuEntryType.INTERFACE then
        local data = entry.componentData
        if not data then return nil end
        if data.objConfig then
            kind, value, fallback = "Item", data.objConfig.id, data.objConfig.name
        elseif data.component then
            local interfaceID = data.component.interfaceID
            if validID(interfaceID) then return {kind="Interface", id=interfaceID} end
        end
    elseif entry.actionEntryType == MiniMenuEntryType.OBJ then
        local cfg = entry.objData and entry.objData.config
        if cfg then kind, value, fallback = "Item", cfg.id, cfg.name end
    elseif entry.actionEntryType == MiniMenuEntryType.NPC then
        local entity = entry.npcData and entry.npcData.entity
        if entity and entity.isValid ~= false then
            kind, value, fallback = "NPC", entity.configID, entity.displayName
        end
    elseif entry.actionEntryType == MiniMenuEntryType.LOC then
        local cfg = entry.locData and entry.locData.config
        if cfg then kind, value, fallback = "Object", cfg.id, cfg.name end
    end
    if not validID(value) then return nil end
    local name = entry.subjectText
    if Text.normalise(name) == "" then name = fallback end
    if Text.normalise(name) == "" then return nil end
    return {kind=kind, id=value, name=name}
end

function M.resolve(entry)
    local ok, target = pcall(resolve, entry)
    if ok then return target end
end

return M
