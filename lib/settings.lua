local M = {}

function M.new(database, changed)
    local self = {holdControl=database:GetBool("holdControl") == true}

    function self:build(parent)
        local root = ui.Layer.new(parent)
        root:SetSize(0, 0, 1, 1)
        local title = ui.Text.new(root)
        title:SetPos(12, 10)
        title:SetSize(-24, 24, 1, 0)
        title.font = id.Font.MUSEO_SANS_15PT_REGULAR
        title.content, title.rgba, title.clickthrough = "Context IDs", 0xD8C18FFF, true

        local button = ui.Button.new(root)
        button:SetPos(12, 42)
        button:SetSize(-24, 32, 1, 0)
        button.stylesheetID = id.StyleSheet.BUTTON_DEFAULT
        button.text.font = id.Font.MUSEO_SANS_15PT_REGULAR
        local function refresh()
            button.label = "Hold Control to show: " .. (self.holdControl and "On" or "Off")
        end
        refresh()
        button:Subscribe(ui.Hook.ONBUTTONPRESSED, function()
            self.holdControl = not self.holdControl
            if not database:SetBool("holdControl", self.holdControl) then
                log("Context IDs could not save the Control setting.")
            end
            refresh()
            changed()
        end)
    end

    return self
end

return M
