-- Keep the ID labels and name matching in one place.
local M = {}

-- Remove colour tags and extra spaces so the same name still matches.
function M.normalise(value)
    if type(value) ~= "string" then
        return ""
    end
    return value
        :gsub("<[^>]*>", "", math.maxinteger)
        :lower()
        :gsub("%s+", " ", math.maxinteger)
        :match("^%s*(.-)%s*$", 1)
end

-- Show the target ID, and include its sprite ID when we have one.
function M.label(target)
    local label = target.kind .. " ID: " .. target.id
    if target.spriteID ~= nil then
        label = label .. " | Sprite ID: " .. target.spriteID
    end
    return label
end

-- This is the coloured text we add to the existing menu and hover name.
function M.annotation(target)
    return " <col=80d8ff>(" .. M.label(target) .. ")</col>"
end

return M
