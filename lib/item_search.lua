local M = {}

local function normalise(value)
    return value:lower():gsub("[^%w]+", " "):match("^%s*(.-)%s*$")
end

function M.new(load)
    local self = {rows={}, busy=false, scanned=0, total=0}
    local data, names, query, words, cursor = nil, {}, "", {}, 1

    function self:start(value)
        query = normalise(value)
        self.rows, self.scanned, self.busy = {}, 0, false
        cursor, words = 1, {}
        if query == "" then return end
        if not data then data = load() end
        self.total = #data / 2
        for word in query:gmatch("%S+") do words[#words+1] = word end
        self.busy = true
    end

    function self:step(budget)
        if not self.busy then return false end
        local stop = math.min(#data, cursor + budget*2 - 1)
        while cursor <= stop do
            local name = names[cursor]
            if not name then name = normalise(data[cursor+1]); names[cursor] = name end
            local matches = true
            for _, word in ipairs(words) do
                if not name:find(word, 1, true) then matches = false; break end
            end
            if matches then
                local rank = name == query and 0 or name:sub(1,#query) == query and 1
                    or name:find(query,1,true) and 2 or 3
                self.rows[#self.rows+1] = {id=data[cursor], name=data[cursor+1], rank=rank, sortName=name}
            end
            cursor = cursor + 2
            self.scanned = self.scanned + 1
        end
        if cursor > #data then
            table.sort(self.rows, function(a,b)
                if a.rank ~= b.rank then return a.rank < b.rank end
                if a.sortName ~= b.sortName then return a.sortName < b.sortName end
                return a.id < b.id
            end)
            self.busy = false
        end
        return true
    end

    function self:cancel() self.busy = false end

    return self
end

return M
