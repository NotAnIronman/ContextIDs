local total = 0
local function equal(actual, expected)
    assert(actual == expected, "Expected " .. tostring(expected) .. ", got " .. tostring(actual))
end
local function test(name, fn)
    fn()
    total = total + 1
    print("PASS " .. name)
end

local handlers, widgets, logs, saved, control, focused, menuOpen, mouse, mouseAvailable
local host, settingsHost, nativeLabel, nativeBox, nativeLayers, apiAvailable
local objects, commands, contentHost
local function boot(preferences)
    handlers, widgets, logs, saved = {}, {}, {}, preferences or {}
    control, focused, menuOpen, mouseAvailable, apiAvailable = false, true, false, true, true
    mouse = {x=200, y=200}
    objects, commands = {
        [42005]={id=42005,name="Reward casket (master)",configName="MASTER_CASKET_FIXTURE"},
        [383]={id=383,name="Raw shark",configName="RAW_SHARK"},
    }, {}
    Event = {}
    for _, name in ipairs({"MiniMenuReady", "Draw", "MiniMenuOpened", "WindowFocusChanged", "GameStateChanged", "SettingsLayerReady", "ContentLayerReady"}) do
        Event[name] = {Subscribe=function(_, callback) handlers[name]=callback end,
            Unsubscribe=function() handlers[name]=nil end}
    end
    PluginShutdown = nil
    PersistentDB = {GetBool=function(_, key) return saved[key] end,
        SetBool=function(_, key, value) saved[key]=value; return true end}
    id = {Interface={TOPLEVEL_V2=1477}, Component={TOPLEVEL_V2__PLUGIN_BUILD_LAYER_TOP=3},
        Font={MUSEO_SANS_15PT_REGULAR=1}, StyleSheet={BUTTON_DEFAULT=2,INPUT_DEFAULT=3}}
    config = {Font={FromID=function() return {GetStringWidth=function(_, content)
        return #content:gsub("<[^>]*>", "") * 7
    end} end}}
    config.Obj = {FromID=function(itemID) return objects[itemID] end}
    ExecuteConsoleCommand=function(command) commands[#commands+1]=command end
    local function component(kind, parent)
        local value = {kind=kind, parent=parent, children={}, hooks={}, text={}, hidden=false,visibleGlobal=true}
        function value:SetSize(w,h,wp,hp)
            self.size = {width=w, height=h, widthParentPc=wp or 0, heightParentPc=hp or 0}
            self.width = w+(wp or 0)*(self.parent and self.parent.width or 0)
            self.height = h+(hp or 0)*(self.parent and self.parent.height or 0)
            for _, child in ipairs(self.children) do
                if child.size then
                    local size = child.size
                    child:SetSize(size.width,size.height,size.widthParentPc,size.heightParentPc)
                end
            end
        end
        function value:SetPos(x,y) self.x,self.y=x,y end
        function value:MoveToFront() self.front=true end
        function value:Subscribe(hook, callback) self.hooks[hook]=callback end
        function value:Setup(visibility,filter,maxLength)
            self.visibility,self.filterMode,self.maxLength=visibility,filter,maxLength
        end
        function value:DeleteAll()
            for _,child in ipairs(self.children) do child:Destroy() end
            self.children={}
        end
        function value:Destroy()
            self.destroyed,self.hidden=true,true
            for _, child in ipairs(self.children) do child:Destroy() end
        end
        if parent then parent.children[#parent.children+1]=value end
        widgets[#widgets+1]=value
        return value
    end
    local viewport = component("Viewport")
    viewport:SetSize(1920,1080)
    viewport.staticID,viewport.type=896,20
    host = component("PluginHost", viewport)
    host:SetSize(0,0,1,1)
    host.xyGlobal={x=0,y=0}
    settingsHost=component("SettingsHost")
    settingsHost:SetSize(420,300)
    contentHost=component("ContentHost")
    contentHost:SetSize(420,500)
    nativeBox=component("NativeFrame",viewport)
    nativeBox:SetSize(135,54)
    nativeBox.staticID,nativeBox.type=899,20
    local parent=nativeBox
    nativeLayers={[899]=nativeBox}
    for _, staticID in ipairs({901,902}) do
        parent=component("NativeLayer",parent)
        parent.staticID,parent.type=staticID,20
        parent:SetSize(staticID==901 and -8 or -10,staticID==901 and -8 or -4,1,1)
        nativeLayers[staticID]=parent
    end
    nativeLabel=component("NativeLabel",parent)
    nativeLabel:SetSize(0,18,1,0)
    nativeLabel.type,nativeLabel.font,nativeLabel.visibleGlobal=2,1,true
    nativeLabel.content=""
    ui={Hook={ONBUTTONPRESSED=1,ONCONTENTCHANGED=2}, ComponentType={LABEL=2,SPRITE=3,BUTTON=9,LAYER=20}, Interfaces={},
        TextContentVisibilityMode={VISIBLE=0},InputFieldFilterMode={NONE=0,NUMERIC=2},
        InputFieldActionResult={CONTENT_CHANGE=1,SUBMIT=2,SUBMIT_ON_ESCAPE=3,SUBMIT_ON_FOCUS_LOSS=4}}
    function ui.Interfaces:GetComponent(interfaceID,staticID,categoryID,dynamicID)
        if not apiAvailable then return nil end
        if interfaceID==3 then return host end
        if interfaceID~=1477 then return nil end
        if categoryID~=nil or dynamicID~=nil then
            if staticID==902 and categoryID==0 and dynamicID==0 then return nativeLabel end
            return nil
        end
        return nativeLayers[staticID]
    end
    for _, kind in ipairs({"Layer","Text","Rectangle","Button","InputField"}) do
        ui[kind]={new=function(parent) return component(kind,parent) end}
    end
    Mouse={IsAvailable=function() return mouseAvailable end, GetPosition=function() return mouse end}
    Keyboard={IsControlDown=function() return control end}
    game={options={InterfaceScale={setting=100}}}
    MiniMenu={IsOpen=function() return menuOpen end}
    MiniMenuEntryType={NONE=0,INTERFACE=1,OBJ=2,LOC=3,NPC=4,PLAYER=7}
    log=function(message) logs[#logs+1]=message end
    dofile(pluginRoot.."/main.lua")
end

local function item(name, id)
    return {actionEntryType=2,subjectText=name,fullText="Take "..name,objData={config={id=id,name=name}},actionType=23}
end
local function npc(name, id)
    return {actionEntryType=4,subjectText=name,fullText="Talk-to "..name,
        npcData={entity={isValid=true,configID=id,uid=987654,displayName=name}},actionType=9}
end
local function object(name, id)
    return {actionEntryType=3,subjectText=name,fullText="Use "..name,locData={config={id=id,name=name}},actionType=7}
end
local function interface(interfaceID, itemID)
    return {actionEntryType=1,subjectText=itemID and "Raw shark" or "Settings",fullText=itemID and "Eat Raw shark" or "Open Settings",
        componentData={component={interfaceID=interfaceID,staticID=70},objConfig=itemID and {id=itemID,name="Raw shark"}}}
end
local function select(entries)
    handlers.MiniMenuReady({miniMenu={entries=entries}})
    local top=entries[#entries]
    nativeLabel.content=top and top.fullText or ""
    nativeLabel.visibleGlobal=top~=nil
    nativeLabel:SetSize(0,18,1,0)
    nativeBox:SetSize(135,54)
    handlers.Draw({})
end
local function floating()
    for _, widget in ipairs(widgets) do
        if widget.kind=="Layer" and widget.parent==host and not widget.destroyed then return widget end
    end
end
local function floatingText()
    local root=floating()
    if not root or root.hidden then return nil end
    for _, child in ipairs(root.children) do if child.kind=="Text" then return child.content end end
end
local function annotated()
    return nativeLabel.content:find(" ID: ",1,true)~=nil
end
local function changeSetting()
    handlers.SettingsLayerReady({component=settingsHost})
    for _, widget in ipairs(widgets) do
        if widget.kind=="Button" and not widget.destroyed then
            widget.hooks[ui.Hook.ONBUTTONPRESSED]()
            return widget
        end
    end
    error("Control setting button missing")
end

test("resolves item, NPC config, and world object IDs",function()
    boot()
    local Target=require("lib/target")
    equal(Target.resolve(item("Raw shark",383)).id,383)
    local target=Target.resolve(npc("Hans",0))
    equal(target.kind,"NPC")
    equal(target.id,0)
    equal(Target.resolve(object("Copper rock",11936)).kind,"Object")
    equal(Target.resolve(object("Copper rock",11936)).id,11936)
end)

test("inventory and bank item IDs take priority over their containing interface",function()
    boot()
    local Target=require("lib/target")
    for _, interfaceID in ipairs({1473,517}) do
        local target=Target.resolve(interface(interfaceID,383))
        equal(target.kind,"Item")
        equal(target.id,383)
    end
    local target=Target.resolve(interface(1477))
    equal(target.kind,"Interface")
    equal(target.id,1477)
end)

test("sprite components show built-in IDs beside their interface and in the menu",function()
    boot()
    local entry=interface(1477)
    entry.componentData.component.type=ui.ComponentType.SPRITE
    entry.componentData.component.spriteID=1234
    entry.componentData.component.associatedObjectID=-1
    select({entry})
    equal(floatingText(),"Interface ID: 1477 | Sprite ID: 1234")
    equal(entry.overrideText,"Open Settings <col=80d8ff>(Interface ID: 1477 | Sprite ID: 1234)</col>")
    equal(nativeBox.width,135)
end)

test("button graphics expose their sprite ID including zero",function()
    boot()
    local entry=interface(1639)
    entry.componentData.component.type=ui.ComponentType.BUTTON
    entry.componentData.component.sprite={spriteID=0}
    select({entry})
    equal(floatingText(),"Interface ID: 1639 | Sprite ID: 0")
    assert(entry.overrideText:find("Sprite ID: 0",1,true))
end)

test("runtime sprites and associated item images retain their existing IDs",function()
    boot()
    local entry=interface(1477)
    entry.componentData.component.type=ui.ComponentType.SPRITE
    entry.componentData.component.spriteID=1234
    entry.componentData.component.runtimeSprite={}
    select({entry})
    equal(floatingText(),"Interface ID: 1477")
    equal(entry.overrideText,nil)
    entry.componentData.component.runtimeSprite=nil
    entry.componentData.component.associatedObjectID=383
    select({entry})
    equal(floatingText(),"Interface ID: 1477")
    entry.componentData.objConfig={id=383,name="Raw shark"}
    entry.subjectText,entry.fullText="Raw shark","Eat Raw shark"
    select({entry})
    equal(floatingText(),nil)
    equal(entry.overrideText,"Eat Raw shark <col=80d8ff>(Item ID: 383)</col>")
end)

test("invalid or unreadable sprite properties preserve the interface ID",function()
    boot()
    local entry=interface(1477)
    entry.componentData.component.type=ui.ComponentType.SPRITE
    for _, value in ipairs({-1,1.5,math.huge,"1234"}) do
        entry.componentData.component.spriteID=value
        select({entry})
        equal(floatingText(),"Interface ID: 1477")
    end
    entry.componentData.component.spriteID=nil
    setmetatable(entry.componentData.component,{__index=function(_,key)
        if key=="spriteID" then error("sprite not available") end
    end})
    select({entry})
    equal(floatingText(),"Interface ID: 1477")
end)

test("sprite IDs follow Control and refresh without duplicate or stale annotations",function()
    boot({holdControl=true})
    local entry=interface(1477)
    entry.componentData.component.type=ui.ComponentType.SPRITE
    entry.componentData.component.spriteID=1234
    select({entry})
    equal(floatingText(),nil)
    equal(entry.overrideText,nil)
    control=true
    select({entry})
    select({entry})
    equal(entry.overrideText,"Open Settings <col=80d8ff>(Interface ID: 1477 | Sprite ID: 1234)</col>")
    entry.componentData.component.spriteID=4321
    select({entry})
    equal(floatingText(),"Interface ID: 1477 | Sprite ID: 4321")
    equal(entry.overrideText,"Open Settings <col=80d8ff>(Interface ID: 1477 | Sprite ID: 4321)</col>")
    entry.componentData.component.spriteID=-1
    select({entry})
    equal(floatingText(),"Interface ID: 1477")
    equal(entry.overrideText,"")
    control=false
    handlers.Draw({})
    equal(floatingText(),nil)
end)

test("unreadable, invalid, and unrelated targets remain unlabelled",function()
    boot()
    local Target=require("lib/target")
    for _, value in ipairs({-1,1.5,math.huge,"383"}) do equal(Target.resolve(item("Raw shark",value)),nil) end
    local invalid=npc("Hans",0)
    invalid.npcData.entity.isValid=false
    equal(Target.resolve(invalid),nil)
    equal(Target.resolve({actionEntryType=7,subjectText="Player"}),nil)
    equal(Target.resolve({actionEntryType=1,componentData={}}),nil)
    equal(Target.resolve(setmetatable({},{__index=function() error("unavailable native entry") end})),nil)
    equal(Target.resolve(nil),nil)
end)

test("world IDs update the existing hover without creating a floating box",function()
    boot()
    local count=#widgets
    for _, entry in ipairs({item("Raw shark",383),npc("Hans",0),object("Copper rock",11936)}) do
        select({entry})
        equal(annotated(),true)
        equal(#widgets,count)
        assert(entry.overrideText:find(" ID: ",1,true))
        equal(nativeLabel.content,entry.overrideText)
    end
    equal(floating(),nil)
end)

test("native frame fits the ID and retains its original padding",function()
    boot()
    select({object("Copper rock",11936)})
    local expected="Use Copper rock <col=80d8ff>(Object ID: 11936)</col>"
    equal(nativeLabel.content,expected)
    local font=config.Font.FromID(1)
    local extra=font:GetStringWidth(expected,false)-font:GetStringWidth("Use Copper rock",false)
    equal(nativeBox.width,135+extra)
    equal(nativeLabel.width,117+extra)
    equal(nativeBox.width-nativeLabel.width,18)
    equal(nativeBox.height,54)
    for _=1,10 do handlers.Draw({}) end
    equal(nativeLabel.content,expected)
    equal(nativeBox.width,135+extra)
    PluginShutdown()
    equal(nativeBox.width,135)
    equal(nativeLabel.width,117)
    equal(nativeLabel.content,"Use Copper rock")
end)

test("right-click annotations preserve entry order, actions, and existing text",function()
    boot()
    local a,b=item("Raw shark",383),npc("Hans",0)
    a.overrideText="Take Raw shark [custom]"
    local entries={a,b}
    select(entries)
    equal(entries[1],a)
    equal(entries[2],b)
    equal(a.actionType,23)
    equal(b.actionType,9)
    equal(a.overrideText,"Take Raw shark [custom] <col=80d8ff>(Item ID: 383)</col>")
    local previous=a.overrideText
    handlers.MiniMenuReady({miniMenu={entries=entries}})
    equal(a.overrideText,previous)
end)

test("only the highest-priority entry controls the hover",function()
    boot()
    select({item("Raw shark",383),{actionEntryType=0,fullText="Walk here"}})
    equal(annotated(),false)
    equal(floatingText(),nil)
    select({npc("Hans",0),item("Raw shark",383)})
    assert(nativeLabel.content:find("Item ID: 383",1,true))
end)

test("interface IDs use a cursor overlay without changing native hover text",function()
    boot()
    local entry=interface(1477)
    select({entry})
    equal(floatingText(),"Interface ID: 1477")
    equal(nativeLabel.content,"Open Settings")
    equal(entry.overrideText,nil)
    local root=floating()
    equal(root.clickthrough,true)
    for _, child in ipairs(root.children) do equal(child.clickthrough,true) end
    local count=#widgets
    handlers.Draw({})
    equal(#widgets,count)
end)

test("switching between UI and world targets hides the previous display",function()
    boot()
    select({interface(1477)})
    select({item("Raw shark",383)})
    equal(floatingText(),nil)
    equal(annotated(),true)
    select({interface(517)})
    equal(floatingText(),"Interface ID: 517")
    equal(annotated(),false)
    equal(nativeBox.width,135)
end)

test("Control gating responds without moving the mouse",function()
    boot({holdControl=true})
    local entry=item("Raw shark",383)
    select({entry})
    equal(annotated(),false)
    equal(entry.overrideText,nil)
    control=true
    handlers.Draw({})
    equal(annotated(),true)
    control=false
    handlers.Draw({})
    equal(annotated(),false)
    equal(nativeBox.width,135)
    control=true
    handlers.Draw({})
    equal(annotated(),true)
end)

test("Control gating applies to interface IDs and right-click text",function()
    boot({holdControl=true})
    select({interface(1477)})
    equal(floatingText(),nil)
    control=true
    handlers.Draw({})
    equal(floatingText(),"Interface ID: 1477")
    control=false
    handlers.Draw({})
    equal(floatingText(),nil)
    local entry=item("Raw shark",383)
    control=true
    select({entry})
    assert(entry.overrideText:find("Item ID: 383",1,true))
    control=false
    handlers.MiniMenuReady({miniMenu={entries={entry}}})
    equal(entry.overrideText,"")
end)

test("Control setting persists and immediately clears existing annotations",function()
    boot()
    select({item("Raw shark",383)})
    local button=changeSetting()
    equal(button.label,"Hold Control to show: On")
    equal(saved.holdControl,true)
    equal(annotated(),false)
    local persisted=saved
    boot(persisted)
    select({item("Raw shark",383)})
    equal(annotated(),false)
end)

test("missing keyboard data hides IDs only when Control is required",function()
    boot({holdControl=true})
    Keyboard=nil
    select({item("Raw shark",383)})
    equal(annotated(),false)
    boot()
    Keyboard=nil
    select({item("Raw shark",383)})
    equal(annotated(),true)
end)

test("cursor overlay stays inside a scaled viewport",function()
    boot()
    game.options.InterfaceScale.setting=200
    mouse={x=3830,y=2150}
    select({interface(1477)})
    local root=floating()
    assert(root.x>=0 and root.y>=0)
    assert(root.x+root.width<=host.width)
    assert(root.y+root.height<=host.height)
    assert(root.x<mouse.x/2 and root.y<mouse.y/2)
    local oldX=root.x
    mouse={x=200,y=200}
    handlers.Draw({})
    assert(root.x~=oldX)
end)

test("unavailable mouse or native UI data does not leave an overlay visible",function()
    boot()
    select({interface(1477)})
    mouseAvailable=false
    handlers.Draw({})
    equal(floatingText(),nil)
    mouseAvailable=true
    mouse=nil
    handlers.Draw({})
    equal(floatingText(),nil)
    boot()
    apiAvailable=false
    select({interface(1477)})
    equal(floatingText(),nil)
    select({item("Raw shark",383)})
    equal(annotated(),false)
end)

test("focus loss, open menus, and game state changes clear displays",function()
    boot()
    select({item("Raw shark",383)})
    handlers.WindowFocusChanged({hasFocus=false})
    equal(annotated(),false)
    handlers.Draw({})
    equal(annotated(),false)
    handlers.WindowFocusChanged({hasFocus=true})
    select({interface(1477)})
    menuOpen=true
    handlers.MiniMenuOpened({})
    equal(floatingText(),nil)
    handlers.Draw({})
    equal(floatingText(),nil)
    menuOpen=false
    select({interface(1477)})
    local old=floating()
    handlers.GameStateChanged({})
    equal(old.destroyed,true)
    equal(floatingText(),nil)
    select({interface(517)})
    equal(floatingText(),"Interface ID: 517")
end)

test("hidden and mismatched native labels are not annotated",function()
    boot()
    handlers.MiniMenuReady({miniMenu={entries={item("Raw shark",383)}}})
    nativeLabel.content="Bank chest"
    handlers.Draw({})
    equal(nativeLabel.content,"Bank chest")
    nativeLabel.content="Raw shark"
    nativeLabel.visibleGlobal=false
    handlers.Draw({})
    equal(nativeLabel.content,"Raw shark")
end)

local function findControl(kind, predicate)
    for index=#widgets,1,-1 do
        local widget=widgets[index]
        if widget.kind==kind and not widget.destroyed and (not predicate or predicate(widget)) then return widget end
    end
    error("Control not found: "..kind)
end
local function typeField(field,content,reason)
    field.content=content
    field.hooks[ui.Hook.ONCONTENTCHANGED](field,reason or ui.InputFieldActionResult.CONTENT_CHANGE,content)
end
local function searchField()
    return findControl("InputField",function(field) return field.emptyText=="Search item name or ID" end)
end
local function quantityField()
    return findControl("InputField",function(field) return field.filterMode==ui.InputFieldFilterMode.NUMERIC end)
end
local function spawnButton()
    return findControl("Button",function(button) return button.label=="Spawn" end)
end
local function chooseMaster()
    local row=findControl("Button",function(button) return button.label:find("[42005]",1,true)~=nil end)
    row.hooks[ui.Hook.ONBUTTONPRESSED]()
end

test("spawner UI searches the actual catalog and sends a command only after clicking Spawn",function()
    boot()
    handlers.ContentLayerReady({component=contentHost})
    typeField(searchField(),"Reward Casket (Master)")
    for _=1,100 do handlers.Draw({}) end
    equal(#commands,0)
    chooseMaster()
    typeField(quantityField(),"12")
    local preview=findControl("InputField",function(field) return field.emptyText=="Command preview" end)
    equal(preview.content,"!give MASTER_CASKET_FIXTURE 12")
    equal(spawnButton().enabled,true)
    equal(#commands,0)
    spawnButton().hooks[ui.Hook.ONBUTTONPRESSED]()
    equal(#commands,1)
    equal(commands[1],"!give MASTER_CASKET_FIXTURE 12")
end)

test("search Enter, quantity Enter, and focus loss never spawn an item",function()
    boot()
    handlers.ContentLayerReady({component=contentHost})
    typeField(searchField(),"42005",ui.InputFieldActionResult.SUBMIT)
    typeField(quantityField(),"4",ui.InputFieldActionResult.SUBMIT)
    typeField(quantityField(),"4",ui.InputFieldActionResult.SUBMIT_ON_FOCUS_LOSS)
    equal(spawnButton().enabled,true)
    equal(#commands,0)
end)

test("spawner UI disables Spawn for invalid quantities and unavailable config names",function()
    boot()
    handlers.ContentLayerReady({component=contentHost})
    typeField(searchField(),"42005")
    typeField(quantityField(),"0")
    equal(spawnButton().enabled,false)
    typeField(quantityField(),"2147483648")
    equal(spawnButton().enabled,false)
    typeField(quantityField(),"1")
    equal(spawnButton().enabled,true)
    objects[42005].configName=""
    typeField(searchField(),"42005")
    equal(spawnButton().enabled,false)
    equal(#commands,0)
end)

test("editing the preview cannot send an arbitrary console command",function()
    boot()
    handlers.ContentLayerReady({component=contentHost})
    typeField(searchField(),"42005")
    local preview=findControl("InputField",function(field) return field.emptyText=="Command preview" end)
    preview.content="!resetsave"
    spawnButton().hooks[ui.Hook.ONBUTTONPRESSED]()
    equal(commands[1],"!give MASTER_CASKET_FIXTURE 1")
end)

test("new search clears the old spawn target before results arrive",function()
    boot()
    handlers.ContentLayerReady({component=contentHost})
    typeField(searchField(),"42005")
    equal(spawnButton().enabled,true)
    typeField(searchField(),"Raw shark")
    equal(spawnButton().enabled,false)
    for _=1,100 do handlers.Draw({}) end
    local row=findControl("Button",function(button) return button.label:find("[383]",1,true)~=nil end)
    row.hooks[ui.Hook.ONBUTTONPRESSED]()
    spawnButton().hooks[ui.Hook.ONBUTTONPRESSED]()
    equal(commands[1],"!give RAW_SHARK 1")
end)

test("spawner panel resizing preserves the search and quantity",function()
    boot()
    handlers.ContentLayerReady({component=contentHost})
    typeField(searchField(),"42005")
    typeField(quantityField(),"7")
    contentHost:SetSize(420,300)
    handlers.Draw({})
    equal(searchField().content,"42005")
    equal(quantityField().content,"7")
    equal(spawnButton().enabled,true)
    local status=findControl("Text",function(text) return text.content:find("Ready.",1,true)~=nil end)
    assert(status.y+status.height<=300)
    spawnButton().hooks[ui.Hook.ONBUTTONPRESSED]()
    equal(commands[1],"!give MASTER_CASKET_FIXTURE 7")
end)

test("pagination changes the visible result rows without sending commands",function()
    boot()
    handlers.ContentLayerReady({component=contentHost})
    typeField(searchField(),"rune")
    for _=1,100 do handlers.Draw({}) end
    local nextButton=findControl("Button",function(button) return button.label=="Next" end)
    equal(nextButton.enabled,true)
    nextButton.hooks[ui.Hook.ONBUTTONPRESSED]()
    local page=findControl("Text",function(text) return text.content:find("Page 2 /",1,true)~=nil end)
    assert(page.content)
    equal(#commands,0)
end)

test("spawner handles missing console access and is destroyed on game-state change",function()
    boot()
    ExecuteConsoleCommand=nil
    handlers.ContentLayerReady({component=contentHost})
    local root=contentHost.children[#contentHost.children]
    typeField(searchField(),"42005")
    equal(spawnButton().enabled,false)
    handlers.GameStateChanged({})
    equal(root.destroyed,true)
    equal(#commands,0)
end)

test("world hover IDs remain available outside the spawner panel",function()
    boot()
    handlers.ContentLayerReady({component=contentHost})
    select({item("Raw shark",383)})
    equal(annotated(),true)
end)

test("shutdown removes subscriptions and destroys only the plugin overlay",function()
    boot()
    select({interface(1477)})
    local root=floating()
    equal(handlers.Logic,nil)
    equal(Event.PluginShutdown,nil)
    PluginShutdown()
    equal(root.destroyed,true)
    equal(nativeLabel.destroyed,nil)
    equal(nativeBox.destroyed,nil)
    equal(next(handlers),nil)
end)

print(string.format("%d checks passed. In-game rendering still needs validation.",total))
