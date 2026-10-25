local M = {}

function M.normalise(value)
    if type(value) ~= "string" then return "" end
    return value:gsub("<[^>]*>", ""):lower():gsub("%s+", " "):match("^%s*(.-)%s*$")
end

function M.annotation(target)
    return " <col=80d8ff>(" .. target.kind .. " ID: " .. target.id .. ")</col>"
end

return M
