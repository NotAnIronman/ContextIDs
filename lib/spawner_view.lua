local M = {}

local function plain(value)
    return value:gsub("<[^>]*>", "", math.maxinteger):gsub("[\r\n]", " ", math.maxinteger)
end

function M.new(model, canExecute)
    local self = {}
    local root, view, page, pageSize, lastWidth, lastHeight = nil, nil, 1, 1, nil, nil

    function self:visible()
        if not root then return false end
        local ok, visible = pcall(function() return root.visibleGlobal and not root.hidden end)
        return ok and visible == true
    end

    function self:clear()
        if root then pcall(function() root:Destroy() end) end
        root, view = nil, nil
        model:cancel()
    end

    local function refresh()
        local pages = math.max(1, math.ceil(#model.rows/pageSize))
        page = math.max(1, math.min(page, pages))
        view.results.content = model:busy() and "Searching..." or #model.rows .. " matching items"
        for index, button in ipairs(view.rows) do
            local row = model.rows[(page-1)*pageSize+index]
            button.hidden = row == nil
            if row then
                local marker = model.selected and model.selected.id == row.id and "> " or ""
                button.label = marker .. plain(row.name) .. "  [" .. row.id .. "]"
            end
        end
        view.previous.enabled, view.next.enabled = page > 1, page < pages
        view.page.content = "Page " .. page .. " / " .. pages
        view.details.content = model.selected and plain(model.selected.name) .. "<br>ID: " .. model.selected.id
            .. " | Config: " .. model.selected.configName or "Select an item to see its current config name."
        view.command.content = model.command or ""
        view.spawn.enabled = model.command ~= nil and canExecute()
        view.status.content = model.status
    end

    local function layout()
        root:DeleteAll()
        lastWidth, lastHeight = root.width, root.height
        pageSize = math.max(1, math.min(8, math.floor((root.height-270)/26)))
        view = {rows={}}
        local font = id.Font.MUSEO_SANS_15PT_REGULAR
        local function text(x,y,w,h,content,relative)
            local component = ui.Text.new(root)
            component:SetPos(x,y)
            component:SetSize(w,h,relative and 1 or 0,0)
            component.font, component.rgba, component.clickthrough = font, 0xDDEEF8FF, true
            component.maxLines = 2
            component.content = content
            return component
        end
        local function field(x,y,w,h,value,mode,limit,relative)
            local component = ui.InputField.new(root)
            component:SetPos(x,y)
            component:SetSize(w,h,relative and 1 or 0,0)
            component.stylesheetID = id.StyleSheet.INPUT_DEFAULT
            component:Setup(ui.TextContentVisibilityMode.VISIBLE,mode,limit)
            component.text.font, component.text.maxLines = font,1
            component.content = value
            return component
        end
        local function button(x,y,w,label,relative,callback)
            local component = ui.Button.new(root)
            component:SetPos(x,y)
            component:SetSize(w,24,relative and 1 or 0,0)
            component.stylesheetID, component.text.font = id.StyleSheet.BUTTON_DEFAULT,font
            component.label = label
            component.text.maxLines = 1
            component:Subscribe(ui.Hook.ONBUTTONPRESSED,callback)
            return component
        end

        text(12,8,-24,22,"Item spawner",true)
        view.search = field(12,36,-24,28,model.query,ui.InputFieldFilterMode.NONE,160,true)
        view.search.emptyText = "Search item name or ID"
        view.search:Subscribe(ui.Hook.ONCONTENTCHANGED,function(_,reason,contents)
            if reason == ui.InputFieldActionResult.CONTENT_CHANGE or reason == ui.InputFieldActionResult.SUBMIT then
                page = 1
                model:search(contents)
                refresh()
            end
        end)
        view.results = text(12,68,-24,18,"",true)
        for index=1,pageSize do
            view.rows[index] = button(12,90+(index-1)*26,-24,"",true,function()
                local row = model.rows[(page-1)*pageSize+index]
                if row then model:select(row); refresh() end
            end)
        end
        local pagerY = 92+pageSize*26
        view.previous = button(12,pagerY,72,"Previous",false,function() page=page-1; refresh() end)
        view.next = button(90,pagerY,72,"Next",false,function() page=page+1; refresh() end)
        view.page = text(172,pagerY,-184,24,"",true)
        view.details = text(12,pagerY+32,-24,40,"",true)
        text(12,pagerY+78,64,28,"Quantity",false)
        view.quantity = field(80,pagerY+78,84,28,model.quantity,ui.InputFieldFilterMode.NUMERIC,10,false)
        view.quantity:Subscribe(ui.Hook.ONCONTENTCHANGED,function(_,reason,contents)
            if reason == ui.InputFieldActionResult.CONTENT_CHANGE or reason == ui.InputFieldActionResult.SUBMIT then
                model:setQuantity(contents)
                refresh()
            end
        end)
        view.spawn = button(176,pagerY+78,-188,"Spawn",true,function()
            if canExecute() then model:spawn()
            else model.status="Console commands are unavailable in this client." end
            refresh()
        end)
        view.command = field(12,pagerY+112,-24,26,"",ui.InputFieldFilterMode.NONE,512,true)
        view.command.emptyText = "Command preview"
        view.status = text(12,pagerY+142,-24,36,"",true)
        refresh()
    end

    function self:build(parent)
        if root then pcall(function() root:Destroy() end) end
        root = ui.Layer.new(parent)
        root:SetSize(0,0,1,1)
        page = 1
        layout()
    end

    function self:draw()
        if not self:visible() then return end
        if root.width ~= lastWidth or root.height ~= lastHeight then layout() end
        if model:step() then refresh() end
    end

    return self
end

return M
