local M = {}

function M.normalise(value)
    if type(value) ~= "string" then return "" end
    return value:gsub("<[^>]*>", ""):lower():gsub("%s+", " "):match("^%s*(.-)%s*$")
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
