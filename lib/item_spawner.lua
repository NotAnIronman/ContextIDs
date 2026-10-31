local Search = require("lib/item_search")
local M = {}

local function integer(value, minimum)
    if type(value) ~= "string" or not value:match("^%s*%d+%s*$", 1) then return nil end
    local number = tonumber(value, 10)
    if number and number >= minimum and number <= 2147483647 then return number end
end

function M.new(api)
    local self = {query="", quantity="1", rows={}, selected=nil, command=nil,
        status="Search by item name or ID."}
    local search = Search.new(api.items)

    local function lookup(itemID)
        local ok, item = pcall(function()
            local cfg = api.lookup(itemID)
            if not cfg or cfg.id ~= itemID or type(cfg.name) ~= "string" then return nil end
            local configName = cfg.configName
            if type(configName) ~= "string" or not configName:match("^[%a_][%w_]*$", 1) then return nil end
            return {id=itemID, name=cfg.name, configName=configName}
        end)
        if ok then return item end
    end

    local function preview()
        local quantity = integer(self.quantity, 1)
        self.command = self.selected and quantity
            and "!give " .. self.selected.configName .. " " .. string.format("%.0f", quantity) or nil
    end

    function self:select(row)
        self.selected = lookup(row.id)
        preview()
        if self.selected then
            self.status = "Ready. Click Spawn to send the command."
        else
            self.status = "This item has no usable config name in the current client."
        end
    end

    function self:setQuantity(value)
        self.quantity = value
        preview()
        if not integer(value, 1) then self.status = "Enter a whole quantity from 1 to 2147483647."
        elseif self.selected then self.status = "Ready. Click Spawn to send the command." end
    end

    function self:search(value)
        self.query, self.rows, self.selected, self.command = value, {}, nil, nil
        search:cancel()
        local itemID = integer(value, 0)
        if itemID then
            local item = lookup(itemID)
            if item then
                self.rows = {{id=item.id, name=item.name}}
                self:select(self.rows[1])
            else self.status = "Item ID not found or its config name is unavailable." end
            return
        end
        search:start(value)
        self.status = search.busy and "Searching item names..." or "Search by item name or ID."
    end

    function self:step()
        if not search:step(512) then return false end
        if search.busy then
            self.status = "Searching item names... " .. math.floor(search.scanned/search.total*100) .. "%"
        else
            self.rows = search.rows
            self.status = #self.rows > 0 and "Select an item from the results." or "No matching items."
        end
        return true
    end

    function self:busy() return search.busy end
    function self:cancel() search:cancel() end

    function self:spawn()
        if not self.selected then self.status = "Select an item first."; return false end
        local current = lookup(self.selected.id)
        if not current then
            self.selected, self.command = nil, nil
            self.status = "The selected item is no longer available."
            return false
        end
        self.selected = current
        preview()
        if not self.command then
            self.status = "Enter a whole quantity from 1 to 2147483647."
            return false
        end
        local ok = pcall(api.execute, self.command)
        self.status = ok and "Sent: " .. self.command or "Could not send the command. Check the developer console."
        return ok
    end

    return self
end

return M
