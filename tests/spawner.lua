local Search=require("lib/item_search")
local Spawner=require("lib/item_spawner")
local count=0
local function equal(actual,expected)
    assert(actual==expected,"Expected "..tostring(expected)..", got "..tostring(actual))
end
local function test(name,fn) fn();count=count+1;print("PASS "..name) end
local function finish(search)
    for _=1,1000 do if not search:busy() then return end;search:step() end
    error("Search did not finish")
end
local function fixture()
    local objects={
        [42005]={id=42005,name="Reward casket (master)",configName="MASTER_CASKET_FIXTURE"},
        [64151]={id=64151,name="Spooky reward casket (master)",configName="SPOOKY_CASKET_FIXTURE"},
        [383]={id=383,name="Raw shark",configName="RAW_SHARK"},
    }
    local commands={}
    local model=Spawner.new({items=function() return {
        64151,"Spooky reward casket (master)",42005,"Reward casket (master)",383,"Raw shark",
    } end,lookup=function(itemID) return objects[itemID] end,
        execute=function(command) commands[#commands+1]=command end})
    return model,objects,commands
end

test("common-name search finds the master casket in the bundled cache catalog",function()
    local search=Search.new(function() return require("lib/item_data") end)
    search:start("Reward Casket (Master)")
    while search.busy do search:step(512) end
    equal(search.rows[1].id,42005)
    equal(search.rows[1].name,"Reward casket (master)")
    equal(search.total,44527)
    assert(search.rows[2].id~=42005)
end)

test("search ignores case and punctuation and supports words in a different order",function()
    for _,query in ipairs({"REWARD_CASKET_(MASTER)","master casket reward"}) do
        local model=fixture()
        model:search(query)
        finish(model)
        assert(#model.rows>=1)
        local found=false
        for _,row in ipairs(model.rows) do if row.id==42005 then found=true end end
        equal(found,true)
    end
end)

test("duplicate display names keep distinct item IDs",function()
    local search=Search.new(function() return {9,"Test item",3,"Test item",7,"Other item"} end)
    search:start("Test item")
    search:step(10)
    equal(#search.rows,2)
    equal(search.rows[1].id,3)
    equal(search.rows[2].id,9)
end)

test("search work is bounded and a newer query replaces the old results",function()
    local data={}
    for i=1,100 do data[#data+1]=i;data[#data+1]="Item "..i end
    local search=Search.new(function() return data end)
    search:start("item")
    search:step(7)
    equal(search.scanned,7)
    equal(search.busy,true)
    search:start("item 99")
    while search.busy do search:step(7) end
    equal(#search.rows,1)
    equal(search.rows[1].id,99)
end)

test("numeric ID lookup works without loading the bundled catalog",function()
    local model=Spawner.new({items=function() error("Catalog must not be loaded") end,
        lookup=function(itemID) return {id=itemID,name="New item",configName="NEW_ITEM"} end,
        execute=function() error("Must not spawn during search") end})
    model:search("70000")
    equal(model.rows[1].id,70000)
    equal(model.rows[1].name,"New item")
    equal(model.command,"!give NEW_ITEM 1")
end)

test("search and selection never execute a spawn command",function()
    local model,_,commands=fixture()
    model:search("master")
    finish(model)
    equal(model.command,nil)
    model:select(model.rows[1])
    model:setQuantity("12")
    equal(#commands,0)
    equal(model.command,"!give MASTER_CASKET_FIXTURE 12")
end)

test("Spawn sends the live config name and requested quantity exactly once",function()
    local model,_,commands=fixture()
    model:search("42005")
    model:setQuantity("12")
    equal(model:spawn(),true)
    equal(#commands,1)
    equal(commands[1],"!give MASTER_CASKET_FIXTURE 12")
    assert(model.status:find("Sent:",1,true))
end)

test("invalid quantities cannot send a console command",function()
    for _,quantity in ipairs({"","0","-1","1.5","2147483648","1; !bank","1e3"}) do
        local model,_,commands=fixture()
        model:search("42005")
        model:setQuantity(quantity)
        equal(model.command,nil)
        equal(model:spawn(),false)
        equal(#commands,0)
    end
end)

test("unavailable and unsafe config names cannot be spawned",function()
    for _,configName in ipairs({"","42005","NAME\n!bank","NAME OTHER","NAME;OTHER"}) do
        local model,objects,commands=fixture()
        objects[42005].configName=configName
        model:search("42005")
        equal(model:spawn(),false)
        equal(#commands,0)
    end
    local model,objects,commands=fixture()
    objects[42005]=nil
    model:search("42005")
    equal(model:spawn(),false)
    equal(#commands,0)
end)

test("selection and quantities are revalidated against the current client before spawning",function()
    local model,objects,commands=fixture()
    model:search("42005")
    objects[42005].configName="CURRENT_CASKET_FIXTURE"
    equal(model:spawn(),true)
    equal(commands[1],"!give CURRENT_CASKET_FIXTURE 1")
    objects[42005]=nil
    equal(model:spawn(),false)
    equal(#commands,1)
end)

test("new searches clear the previous selection and command",function()
    local model,_,commands=fixture()
    model:search("42005")
    model:search("nothing matches this")
    finish(model)
    equal(#model.rows,0)
    equal(model.selected,nil)
    equal(model.command,nil)
    equal(model:spawn(),false)
    equal(#commands,0)
end)

test("console command errors are reported without claiming that items were received",function()
    local model=Spawner.new({items=function() return {} end,
        lookup=function(itemID) return {id=itemID,name="Test item",configName="TEST_ITEM"} end,
        execute=function() error("Console unavailable") end})
    model:search("1")
    equal(model:spawn(),false)
    assert(model.status:find("Could not send",1,true))
end)

print(string.format("%d spawner checks passed.",count))
