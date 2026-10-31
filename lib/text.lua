local M = {}

function M.normalise(value)
    if type(value) ~= "string" then return "" end
    return value:gsub("<[^>]*>", "", math.maxinteger):lower():gsub("%s+", " ", math.maxinteger):match("^%s*(.-)%s*$", 1)
end

function M.label(target)
    local label = target.kind .. " ID: " .. target.id
    if target.spriteID ~= nil then label = label .. " | Sprite ID: " .. target.spriteID end
    return label
end

function M.annotation(target)
    return " <col=80d8ff>(" .. M.label(target) .. ")</col>"
end

return M
