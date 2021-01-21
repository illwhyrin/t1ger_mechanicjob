
FXCore = nil
TriggerEvent(Config.Core, function(obj) FXCore = obj end)
RegisterServerEvent('t1ger_mechanicjob:fetchMechShops')
AddEventHandler('t1ger_mechanicjob:fetchMechShops', function()

    local xPlayers = FXCore.Functions.GetPlayers()
    local players  = {}

    local DataFected = false
	for i = 1, #xPlayers, 1 do
        local xPlayer = FXCore.Functions.GetPlayer(xPlayers[i])
		table.insert(players, { source = xPlayer.PlayerData.source, identifier = xPlayer.PlayerData.steam, shopID = 0 })
    end
    exports['ghmattimysql']:execute("SELECT * FROM t1ger_mechanic", {}, function(results)
        if #results > 0 then 
            for l,ply in pairs(players) do
                for k,v in pairs(results) do
                    if ply.identifier == v.identifier then
                        ply.shopID = v.shopID
                    end
                    if k == #results then DataFected = true end
                    
                end
            end
        else
            DataFected = true
        end
    end)
    while not DataFected do Wait(5) end
    local plyShopID = 0
    if DataFected then 
        for k,v in pairs(players) do
            if v.shopID > 0 then plyShopID = v.shopID else plyShopID = 0 end
           
            TriggerClientEvent('t1ger_mechanicjob:fetchMechShopsCL', v.source, plyShopID)
           
        end
    end

end)

RegisterServerEvent('t1ger_mechanicjob:fireEmployee')
AddEventHandler('t1ger_mechanicjob:fireEmployee', function(id, plyIdentifier)
    local xPlayer = FXCore.Functions.GetPlayer(source)
    exports['ghmattimysql']:execute("SELECT * FROM t1ger_mechanic WHERE shopID = @shopID", {['@shopID'] = id}, function(data)
        if data[1].employees ~= nil then
            local employees = json.decode(data[1].employees)
            if #employees > 0 then 
                for k,v in pairs(employees) do 
                    if plyIdentifier == v.identifier then 
                        table.remove(employees, k)
                        exports['ghmattimysql']:execute("UPDATE t1ger_mechanic SET employees = @employees WHERE shopID = @shopID", {
                            ['@employees'] = json.encode(employees),
                            ['@shopID'] = id
                        })
                        local xTarget = FXCore.Functions.GetPlayer(plyIdentifier)
                        xTarget.Functions.SetJob("unemployed", 1)
                        TriggerClientEvent('t1ger_mechanicjob:ShowNotifyESX', xTarget.PlayerData.source, Lang['mech_employee_fired'])
                        break
                    end
                end
            end
        end
    end)
end)

FXCore.Functions.CreateCallback('t1ger_mechanicjob:getIfVehicleOwned', function (source, cb, plate)
    local xPlayer = FXCore.Functions.GetPlayer(source)
    local found = nil
    local vehicleData = nil

    exports['ghmattimysql']:execute('SELECT * FROM player_vehicles WHERE steam = @owner', {
        ['@owner'] = xPlayer.PlayerData.steam
    }, function (result)

        local vehicles = {}
if result ~= nil then
        for i=1, #result, 1 do
            vehicleData = json.decode(result[i].mods)
            if vehicleData.plate == plate then
                found = true
                cb(found)
                break
            end
        end

        if not found then
            cb(nil)
        end
    end
    end)
end)
FXCore.Functions.CreateCallback('t1ger_mechanicjob:getVehDegradation',function(source, cb, plate)
    local xPlayer = FXCore.Functions.GetPlayer(source)
    exports['ghmattimysql']:execute("SELECT health FROM player_vehicles WHERE plate=@plate",{['@plate'] = plate}, function(data)
        if data[1]  ~= nil then
            local health = json.decode(data[1].health)
            cb(health)
            
        end
    end)
end)
FXCore.Functions.CreateCallback('t1ger_mechanicjob:buyMechShop',function(source, cb, id, val, name)
  
    local xPlayer = FXCore.Functions.GetPlayer(source)

    local els = xPlayer.PlayerData.steam
    local money = 0
    if Config.PayMechShopWithCash then
        money = xPlayer.PlayerData.money["cash"]
    else
        money = xPlayer.PlayerData.money["bank"]
    end
	if money >= val.price then
		if Config.PayMechShopWithCash then
			xPlayer.Functions.RemoveMoney("cash",val.price)
		else
			xPlayer.Functions.RemoveMoney('bank', val.price)
        end
        
        FXCore.Functions.ExecuteSql(true,"INSERT INTO t1ger_mechanic (identifier, shopID, name) VALUES ('"..els.."', '"..id.."', '"..name.."')")
        cb(true)
    else
        cb(false)
    end
end)


FXCore.Functions.CreateCallback('t1ger_mechanicjob:sellMechShop',function(source, cb, id, val, sellPrice)
    local xPlayer = FXCore.Functions.GetPlayer(source)
    exports['ghmattimysql']:execute("SELECT shopID FROM t1ger_mechanic WHERE identifier = @identifier", {['@identifier'] = xPlayer.PlayerData.steam}, function(data)

        if data[1]~= nil then
        if data[1].shopID ~= nil then 
            if data[1].shopID == id then
                exports['ghmattimysql']:execute("DELETE FROM t1ger_mechanic WHERE shopID=@shopID", {['@shopID'] = id}) 
                if Config.RecieveSoldMechShopCash then
                    xPlayer.Functions.AddMoney("cash",sellPrice)
                else
                    xPlayer.Functions.AddMoney("bank",sellPrice)
                end
                cb(true)
            else
                cb(false)
            end
        end
    end
    end)

end)

-- Reanme Mech Shop:
FXCore.Functions.CreateCallback('t1ger_mechanicjob:renameMechShop',function(source, cb, id, val, name)
    local xPlayer = FXCore.Functions.GetPlayer(source)
    exports['ghmattimysql']:execute("SELECT shopID FROM t1ger_mechanic WHERE identifier = @identifier", {['@identifier'] = xPlayer.PlayerData.steam}, function(data)
        if data[1].shopID ~= nil then 
            if data[1].shopID == id then
                exports.ghmattimysql:executeSync("UPDATE t1ger_mechanic SET name = @name WHERE shopID = @shopID", {
                    ['@name'] = name,
                    ['@shopID'] = id
                })
                cb(true)
            else
                cb(false)
            end
        end
    end)
end)

-- Get Employees:
FXCore.Functions.CreateCallback('t1ger_mechanicjob:getEmployees',function(source, cb, id)
    local xPlayer = FXCore.Functions.GetPlayer(source)
    local dataFected = false
    local shopEmployees = {}
    local noEmployees = false
    exports['ghmattimysql']:execute("SELECT employees FROM t1ger_mechanic WHERE shopID = @shopID", {['@shopID'] = id}, function(data)
        if data[1].employees ~= nil then
            local employees = json.decode(data[1].employees)
            if #employees > 0 then
                for k,v in pairs(employees) do
                   
                    exports['ghmattimysql']:execute('SELECT * FROM players WHERE steam = @identifier', {['@identifier'] = v.identifier}, function (info)
                        for j,l in pairs(info) do 
                            local player = FXCore.Functions.GetSource(l.steam)
                            local jugador = FXCore.Functions.GetPlayer(player)
                            local player1 = FXCore.Functions.GetSource(v.identifier)
                            local jugador1 = FXCore.Functions.GetPlayer(player1)
                            if v.identifier == l.steam then 
                                table.insert(shopEmployees,{identifier = v.identifier, firstname = jugador.PlayerData.charinfo.firstname, lastname = jugador.PlayerData.charinfo.lastname, jobGrade = jugador1.PlayerData.job.grade})
                                if k == #employees then 
                                    dataFected = true
                                end
                            end
                        end
                    end)
                end
            else
                noEmployees = true
                dataFected = true
            end
        end 
    end)
    while not dataFected do
        Citizen.Wait(1)
    end
    if dataFected then
   
        if noEmployees then cb(nil) 
        else 
            cb(shopEmployees)
           
         end
    end
end)
-- Fire Employee:
RegisterServerEvent('t1ger_mechanicjob:updateEmployeJobGrade')
AddEventHandler('t1ger_mechanicjob:updateEmployeJobGrade', function(id, plyIdentifier, newJobGrade)
    
    local xPlayer = FXCore.Functions.GetPlayer(source)


    exports['ghmattimysql']:execute("SELECT employees FROM t1ger_mechanic WHERE shopID = @shopID", {['@shopID'] = id}, function(data)
        if data[1].employees ~= nil then 
            local employees = json.decode(data[1].employees)
            if #employees > 0 then 
                for k,v in pairs(employees) do 
                    if plyIdentifier == v.identifier then
                        local xTarget = FXCore.Functions.GetPlayer(plyIdentifier)
                        local grade = FXCore.Shared.Jobs["mechanic"].grades
                        
                        for j,c in ipairs(grade) do
                      
                        if newJobGrade >= 0 and newJobGrade <= j then
                            if xTarget.PlayerData.job.grade ~= newJobGrade then 
                                v.jobGrade = newJobGrade
                                exports.ghmattimysql:executeSync("UPDATE t1ger_mechanic SET employees = @employees WHERE shopID = @shopID", {
                                    ['@employees'] = json.encode(employees),
                                    ['@shopID'] = id
                                })
                                xTarget.Functions.SetJob("mechanic", tonumber(newJobGrade))
                                Wait(200)
                                TriggerClientEvent('t1ger_mechanicjob:ShowNotifyESX', xPlayer.PlayerData.source, (Lang['you_updat_job_grade_for']:format(xTarget.PlayerData.charinfo.firstname, newJobGrade)))
                                TriggerClientEvent('t1ger_mechanicjob:ShowNotifyESX', xTarget.PlayerData.source, (Lang['your_job_grade_updated']:format(newJobGrade)))
                            else
                                TriggerClientEvent('t1ger_mechanicjob:ShowNotifyESX', xPlayer.PlayerData.source, (Lang['target_alrdy_has_job_g']:format(xTarget.PlayerData.charinfo.firstname)))
                            end
                        else
                            TriggerClientEvent('t1ger_mechanicjob:ShowNotifyESX', xPlayer.PlayerData.source, (Lang['mix_max_job_grade']:format(j)))
                        end
                        end
                    end 
                end
            end
        end
    end)
end)

-- Callback to Get online players:
FXCore.Functions.CreateCallback('t1ger_mechanicjob:getOnlinePlayers', function(source, cb)
	local fetchedPlayers = GetOnlinePlayers()
	cb(fetchedPlayers)
    local xPlayer = FXCore.Functions.GetPlayer(source)

    
end)

-- Reqruit Employee:
RegisterServerEvent('t1ger_mechanicjob:reqruitEmployee')
AddEventHandler('t1ger_mechanicjob:reqruitEmployee', function(id, plyIdentifier, name)


    local xPlayer = FXCore.Functions.GetPlayer(source)
    local loopDone = false
    local identifierMatch = false
    local noEmployees = false
    exports['ghmattimysql']:execute("SELECT employees FROM t1ger_mechanic WHERE shopID = @shopID", {['@shopID'] = id}, function(data)
        if data[1] ~= nil then 
        if data[1].employees ~= nil then 
            local employees = json.decode(data[1].employees)
            if #employees > 0 then
                for k,v in pairs(employees) do 
                    if plyIdentifier == v.identifier then

                        TriggerClientEvent('t1ger_mechanicjob:ShowNotifyESX', xPlayer.PlayerData.source, Lang['already_hired'])
                        identifierMatch = true
                        break
                    else
                        if k == #employees then 
                            loopDone = true
                        end
                    end
                end
            else
                noEmployees = true
                loopDone = true
            end
        end
        end
    end)
    while not loopDone do 
        Citizen.Wait(1)
    end

    if loopDone then
        if noEmployees then
            exports['ghmattimysql']:execute("SELECT * FROM t1ger_mechanic WHERE shopID = @shopID", {['@shopID'] = id}, function(data)
                for _,y in pairs(data) do 
                    local employees = {}
                    table.insert(employees,{identifier = plyIdentifier})
                    exports.ghmattimysql:executeSync("UPDATE t1ger_mechanic SET employees = @employees WHERE shopID = @shopID", {
                        ['@employees'] = json.encode(employees),
                        ['@shopID'] = id
                    })
                    TriggerClientEvent('t1ger_mechanicjob:ShowNotifyESX', xPlayer.PlayerData.source, (Lang['you_recruited_x']:format(name)))
                    local xTarget = FXCore.Functions.GetPlayerentifier(plyIdentifier)
                    xTarget.Functions.SetJob("mechanic")
                    TriggerClientEvent('t1ger_mechanicjob:ShowNotifyESX', xTarget.PlayerData.source, Lang['you_have_been_recruited'])
                    break
                end
            end)
        else
            if not identifierMatch then
                exports['ghmattimysql']:execute("SELECT * FROM t1ger_mechanic WHERE shopID = @shopID", {['@shopID'] = id}, function(data)
                    for _,y in pairs(data) do 
                        local employees = json.decode(y.employees)
                        table.insert(employees,{identifier = plyIdentifier})
                        exports.ghmattimysql:executeSync("UPDATE t1ger_mechanic SET employees = @employees WHERE shopID = @shopID", {
                            ['@employees'] = json.encode(employees),
                            ['@shopID'] = id
                        })
                        TriggerClientEvent('t1ger_mechanicjob:ShowNotifyESX', xPlayer.PlayerData.source, (Lang['you_recruited_x']:format(name)))
                        local xTarget = FXCore.Functions.GetPlayerentifier(plyIdentifier)
                        xTarget.setJob("mechanic", 0)
                        TriggerClientEvent('t1ger_mechanicjob:ShowNotifyESX', xTarget.PlayerData.source, Lang['you_have_been_recruited'])
                        break
                    end
                end)
            end
        end
    end
end)

-- Withdraw Account Money:
RegisterServerEvent('t1ger_mechanicjob:withdrawMoney')
AddEventHandler('t1ger_mechanicjob:withdrawMoney', function(id, amount)
    local xPlayer = FXCore.Functions.GetPlayer(source)
    local accountMoney = 0
    exports['ghmattimysql']:execute("SELECT money FROM t1ger_mechanic WHERE shopID = @shopID", {['@shopID'] = id}, function(data)
        if data[1].money ~= nil then 
            accountMoney = data[1].money
        end
        if amount <= accountMoney then 
            exports.ghmattimysql:executeSync("UPDATE t1ger_mechanic SET money = @money WHERE shopID = @shopID", {
                ['@money'] = (accountMoney - amount),
                ['@shopID'] = id
            })
            xPlayer.Functions.AddMoney("cash", amount)
            TriggerClientEvent('t1ger_mechanicjob:ShowNotifyESX', xPlayer.PlayerData.source, (Lang['you_withdrew_x_amount']:format(amount)))
        else
            TriggerClientEvent('t1ger_mechanicjob:ShowNotifyESX', xPlayer.PlayerData.source, Lang['withdrawal_denied'])
        end
    end)
end)

-- Deposit Account Money:
RegisterServerEvent('t1ger_mechanicjob:depositMoney')
AddEventHandler('t1ger_mechanicjob:depositMoney', function(id, amount)
    local xPlayer = FXCore.Functions.GetPlayer(source)
    local accountMoney = 0
    exports['ghmattimysql']:execute("SELECT money FROM t1ger_mechanic WHERE shopID = @shopID", {['@shopID'] = id}, function(data)
        if data[1].money ~= nil then 
            accountMoney = data[1].money
        end
        local plyMoney = xPlayer.PlayerData.money["cash"]
        if plyMoney >= amount then 
            exports.ghmattimysql:executeSync("UPDATE t1ger_mechanic SET money = @money WHERE shopID = @shopID", {
                ['@money'] = (accountMoney + amount),
                ['@shopID'] = id
            })
            xPlayer.Functions.RemoveMoney("cash", amount)
            TriggerClientEvent('t1ger_mechanicjob:ShowNotifyESX', xPlayer.PlayerData.source, (Lang['you_deposited_x_amount']:format(amount)))
        else
            TriggerClientEvent('t1ger_mechanicjob:ShowNotifyESX', xPlayer.PlayerData.source, Lang['not_enough_money'])
        end
    end)
end)

-- Check Storage Access:
FXCore.Functions.CreateCallback('t1ger_mechanicjob:checkAccess',function(source, cb, id)
    local xPlayer = FXCore.Functions.GetPlayer(source)
    exports['ghmattimysql']:execute("SELECT * FROM t1ger_mechanic WHERE shopID = @shopID", {['@shopID'] = id}, function(data)
        for shops,columns in pairs(data) do 
            if columns.shopID == id then 
                if xPlayer.PlayerData.steam == columns.identifier then 
                    cb(true)
                    break
                end
                if columns.employees ~= nil then 
                    local employees = json.decode(columns.employees)
                    if #employees > 0 then 
                        for k,v in pairs(employees) do 
                            if xPlayer.PlayerData.steam == v.identifier then 
                                cb(true)
                                break
                            end
                        end
                    else
                        cb(false)
                    end
                end
            end
        end
    end)
end)

-- Get User Inventory:
FXCore.Functions.CreateCallback('t1ger_mechanicjob:getUserInventory', function(source, cb)
    local xPlayer = FXCore.Functions.GetPlayer(source)
    local inventoryItems = xPlayer.PlayerData.items
    cb(inventoryItems)
end)


-- Deposit Items into Storage:
RegisterServerEvent('t1ger_mechanicjob:depositItem')
AddEventHandler('t1ger_mechanicjob:depositItem', function(item, amount, id)

    local xPlayer = FXCore.Functions.GetPlayer(source)
    local addItem = item
    local itemAdded = false
    if xPlayer.Functions.GetItemByName(addItem).amount >= amount then

        exports['ghmattimysql']:execute("SELECT storage FROM t1ger_mechanic WHERE shopID ='"..id.."'", function(data)
            if data[1].storage ~= nil then
                local storage = json.decode(data[1].storage)
                if #storage > 0 then 
                    for k,v in ipairs(storage) do 
                        if v.item == addItem then
                            v.count = (v.count + amount)
                            itemAdded = true
                            break
                        else
                            if k == #storage then
                                if Config.ItemLabelESX then
                                    table.insert(storage, {item = addItem, count = amount, label = addItem.label})
                                else
                                    table.insert(storage, {item = addItem, count = amount, label = tostring(addItem)})
                                end
                                itemAdded = true
                                break
                            end
                        end
                    end
                    while not itemAdded do Citizen.Wait(1) end
                    if itemAdded then 
                        exports.ghmattimysql:executeSync("UPDATE t1ger_mechanic SET storage = @storage WHERE shopID = @shopID", {
                            ['@storage'] = json.encode(storage),
                            ['@shopID'] = id
                        })
                        xPlayer.Functions.RemoveItem(addItem, amount)
                        local itemLabel = ''
                        if Config.ItemLabelESX  then itemLabel = addItem.label else itemLabel = tostring(addItem) end
                        TriggerClientEvent('t1ger_mechanicjob:ShowNotifyESX', xPlayer.PlayerData.source, (Lang['storage_deposited_x']:format(amount, itemLabel)))
                    end
                else
                    storage = {}
                    if Config.ItemLabelESX  then
                        table.insert(storage, {item = addItem, count = amount, label = addItem.label})
                    else
                        table.insert(storage, {item = addItem, count = amount, label = tostring(addItem)})
                    end
                    exports.ghmattimysql:executeSync("UPDATE t1ger_mechanic SET storage = @storage WHERE shopID = @shopID", {
                        ['@storage'] = json.encode(storage),
                        ['@shopID'] = id
                    })   
                    xPlayer.Functions.RemoveItem(addItem, amount)
                    local itemLabel = ''
                    if Config.ItemLabelESX then itemLabel = addItem.label else itemLabel = tostring(addItem) end
                    TriggerClientEvent('t1ger_mechanicjob:ShowNotifyESX', xPlayer.PlayerData.source, (Lang['storage_deposited_x']:format(amount, itemLabel)))
                end
            end
        end)
    else
        TriggerClientEvent('t1ger_mechanicjob:ShowNotifyESX', xPlayer.PlayerData.source, Lang['not_enough_items'])
    end
end)

-- Get Storage Inventory:
FXCore.Functions.CreateCallback('t1ger_mechanicjob:getStorageInventory', function(source, cb, id)
	local xPlayer = FXCore.Functions.GetPlayer(source)
    local dataFected = false
    local storageInv = {}
    exports['ghmattimysql']:execute("SELECT storage FROM t1ger_mechanic WHERE shopID = @shopID", {['@shopID'] = id}, function(data)
        if data[1].storage ~= nil then
            local storage = json.decode(data[1].storage)
            if #storage > 0 then 
                for k,v in pairs(storage) do 
                    table.insert(storageInv,{item = v.item, count = v.count, label = v.label})
                    if k == #storage then 
                        dataFected = true
                    end
                end
            else
                cb(nil)
            end
        end
    end)
    while not dataFected do
        Citizen.Wait(1)
    end
    if dataFected then 
        cb(storageInv)
    end
end)

FXCore.Functions.CreateCallback('t1ger_mechanicjob:getTakenShops', function(source, cb)
    local xPlayer =  FXCore.Functions.GetPlayer(source).PlayerData.steam
 
    exports['ghmattimysql']:execute("SELECT shopID, name FROM t1ger_mechanic WHERE identifier = @identifier", {['@identifier'] = xPlayer}, function(data)
        
      
        cb(data)
    end)
end)


FXCore.Functions.CreateCallback('t1ger_mechanicjob:getShopAccounts', function(source, cb)
    local xPlayer = FXCore.Functions.GetPlayer(source)
    exports['ghmattimysql']:execute("SELECT money FROM t1ger_mechanic WHERE identifier = @citizenid", {['@citizenid'] = xPlayer.PlayerData.steam}, function(data)
        if data[1].money ~= nil then
            local account = json.decode(data[1].money)
            cb(account)
        else
            cb(nil)
        end
    end)
end)

RegisterServerEvent('t1ger_mechanicjob:JobReward')
AddEventHandler('t1ger_mechanicjob:JobReward', function()
    local xPlayer = FXCore.Functions.GetPlayer(source)
    xPlayer.Functions.AddMoney("cash", Config.Payout)
end)


-- Withdraw Items from Storage:
RegisterServerEvent('t1ger_mechanicjob:withdrawItem')
AddEventHandler('t1ger_mechanicjob:withdrawItem', function(item, amount, id)
    local xPlayer = FXCore.Functions.GetPlayer(source)
    local removeItem = item
    exports['ghmattimysql']:execute("SELECT storage FROM t1ger_mechanic WHERE shopID = @shopID", {['@shopID'] = id}, function(data)

        if data[1].storage ~= nil then
            local storage = json.decode(data[1].storage)
            
            for k,v in pairs(storage) do
                if removeItem == v.item then
                    v.count = (v.count - amount)
                    Citizen.Wait(250)
                    if v.count == 0 then
                        table.remove(storage, k)
                    end
                    exports.ghmattimysql:execute("UPDATE t1ger_mechanic SET storage = @storage WHERE shopID = @shopID", {
                        ['@storage'] = json.encode(storage),
                        ['@shopID'] = id
                    })
                    xPlayer.Functions.AddItem(removeItem, amount)
                   
                    local itemLabel = ''
                    if Config.ItemLabelESX  then itemLabel = FXCore.Functions.GetItemByName(removeItem) else itemLabel = tostring(removeItem) end
                    TriggerClientEvent('t1ger_mechanicjob:ShowNotifyESX', xPlayer.PlayerData.source, (Lang['storage_withdrew_x']:format(amount, itemLabel)))
                end
            end
        end
    
    end)
end)


-- Craft Items:
RegisterServerEvent('t1ger_mechanicjob:craftItem')
AddEventHandler('t1ger_mechanicjob:craftItem', function(item_label, item_name, item_recipe, id, val)
    local xPlayer        = FXCore.Functions.GetPlayer(source)
    local removeItems    = {}
    local loopDone       = false
    local hasRecipeItems = false
    for k, v in ipairs(item_recipe) do
        local material = Config.Materials[v.id]

        local items = material.item
        local cuan  = xPlayer.Functions.GetItemByName(items)
        if cuan ~= nil then
            if cuan.amount >= v.qty then
                table.insert(removeItems, { item = items, amount = v.qty })
            else
                loopDone       = true
                hasRecipeItems = false
                break
            end
        else
          --  TriggerClientEvent("FXCore:Notify", source, "you dont have the items")
            loopDone       = true
            hasRecipeItems = false
            break
        end
    end
    if k == #item_recipe then
        loopDone       = true
        hasRecipeItems = true
    end

while not loopDone do
    Citizen.Wait(1)
end
if hasRecipeItems then
    for k, v in pairs(removeItems) do
        xPlayer.Functions.RemoveItem(v.item, v.amount)
    end
    xPlayer.Functions.AddItem(item_name, 1)
else
    TriggerClientEvent('t1ger_mechanicjob:ShowNotifyESX', xPlayer.PlayerData.source, Lang['not_enough_materials'])
end
end)

-- Billing:
RegisterServerEvent('t1ger_mechanicjob:sendBill')
AddEventHandler('t1ger_mechanicjob:sendBill',function(target, amount)
	local xPlayer = FXCore.Functions.GetPlayer(source)
    local xPlayers = FXCore.Functions.GetPlayers()
    if amount ~= nil then
        if amount >= 0 then
            for i = 1, #xPlayers, 1 do
                local tPlayer = FXCore.Functions.GetPlayer(xPlayers[i])
                if tPlayer.source == target then
                    tPlayer.Functions.RemoveMoney('bank', tonumber(amount))
                    TriggerClientEvent('t1ger_mechanicjob:ShowNotifyESX', tPlayer.PlayerData.source, "You paid the invoice of ~g~$"..amount.."~s~ to the mechanic.")
                    xPlayer.Functions.AddMoney('bank', tonumber(amount))
                    TriggerClientEvent('t1ger_mechanicjob:ShowNotifyESX', xPlayer.PlayerData.source, "You received payment from the invoice of ~g~$"..amount)
                    break
                end
            end
        end
    end
end)

-- Repair Kits:
Citizen.CreateThread(function()
	for k,v in pairs(Config.RepairKits) do 
		FXCore.Functions.CreateUseableItem(v.item, function(source)
			local xPlayer = FXCore.Functions.GetPlayer(source)
			TriggerClientEvent('t1ger_mechanicjob:useRepairKit', xPlayer.PlayerData.source, k, v)
		end)
	end
end)

-- Remove item event:
RegisterServerEvent('t1ger_mechanicjob:removeItem')
AddEventHandler('t1ger_mechanicjob:removeItem', function(item, amount)
    local xPlayer = FXCore.Functions.GetPlayer(source)
    xPlayer.Functions.RemoveItem(item, amount)
end)
-- Get inventory item:
FXCore.Functions.CreateCallback('t1ger_mechanicjob:getInventoryItem',function(source, cb, item)
    local xPlayer = FXCore.Functions.GetPlayer(source)
    local hasItem = xPlayer.Functions.GetItemByName(item)
    if hasItem then cb(true) else cb(false) end
end)

Citizen.CreateThread(function()
	for k,v in pairs(Config.BodyParts) do 
		FXCore.Functions.CreateUseableItem(v.item, function(source)
			local xPlayer = FXCore.Functions.GetPlayer(source)
			TriggerClientEvent('t1ger_mechanicjob:installBodyPartCL', xPlayer.PlayerData.source, k, v)
		end)
	end
end)

function GetOnlinePlayers()
    local xPlayers = FXCore.Functions.GetPlayers()
	local players  = {}
	for i=1, #xPlayers, 1 do
		local xPlayer = FXCore.Functions.GetPlayer(xPlayers[i])
		table.insert(players, {
			source     = xPlayer.PlayerData.source,
			citizenid = xPlayer.PlayerData.steam,
			name       = xPlayer.PlayerData.charinfo.firstname
		})
    end
    return players
end


-- Get Materials for Health Part Repair:
FXCore.Functions.CreateCallback('t1ger_mechanicjob:getMaterialsForHealthRep',function(source, cb, plate, degName, materials, newValue, addValue, vehOnLift)
    local xPlayer = FXCore.Functions.GetPlayer(source)
    -- Get & Remove materials:
    local removeItems = {}
    local loopDone = false
    local hasMaterials = false
    for k,v in ipairs(materials) do
        local items = Config.Materials[v.id]
        local multiplier = math.floor(addValue)
        local reqAmount = (v.qty * multiplier)
        local item = xPlayer.Functions.GetItemByName(items.item)
        if item.amount >= reqAmount then
            table.insert(removeItems, {item = items.item, amount = reqAmount})
        else
            loopDone = true
            hasMaterials = false
            break
        end
        if k == #materials then
            loopDone = true
            hasMaterials = true
        end
    end
    while not loopDone do
        Citizen.Wait(1)
    end
    if hasMaterials then
        for k,v in pairs(removeItems) do
            xPlayer.Functions.RemoveItem(v.item, v.amount)
        end
        cb(true)
    else
        cb(false)
    end
end)

RegisterServerEvent('t1ger_mechanicjob:updateVehDegradation') 
AddEventHandler('t1ger_mechanicjob:updateVehDegradation', function(plate, label, degName, vehOnLift)
    local xPlayer = FXCore.Functions.GetPlayer(source)
    exports['ghmattimysql']:execute("SELECT health FROM player_vehicles WHERE plate=@plate",{['@plate'] = plate}, function(data) 
        if #data > 0 then
            if data[1].health ~= nil then 
                local health = json.decode(data[1].health)
                if #health > 0 then 
                    for k,v in pairs(health) do
                        if v.part == degName then
                            local updateValue = vehOnLift[plate].health[degName].value
                            if v.part == "engine" then
                                v.value = math.floor(updateValue * 10 * 10)
                            else
                                v.value = math.floor(updateValue * 10)
                            end
                            exports.ghmattimysql:executeSync("UPDATE player_vehicles SET health = @health WHERE plate = @plate", {
                                ['@health'] = json.encode(health),
                                ['@plate'] = plate
                            })
                            TriggerClientEvent('t1ger_mechanicjob:ShowNotifyESX', xPlayer.PlayerData.source, (Lang['you_rep_health_part']:format(degName, updateValue)))
                            break
                        end
                    end
                end
            end 
        end
	end)
end)


-- Degrade Vehicle Degradation:
RegisterServerEvent('t1ger_mechanicjob:degradeVehHealth') 
AddEventHandler('t1ger_mechanicjob:degradeVehHealth', function(plate, damageArray)
    local xPlayer = FXCore.Functions.GetPlayer(source)
    exports['ghmattimysql']:execute("SELECT health FROM player_vehicles WHERE plate=@plate",{['@plate'] = plate}, function(data) 
        if #data > 0 then
            if data[1].health ~= nil then 
                local health = json.decode(data[1].health)
                if #health > 0 then 
                    for k,v in pairs(health) do
                        local part = damageArray[v.part]
                        if part ~= nil then
                            if v.part == part.degName then 
                                local degVal = part.degValue
                                local oldVal = v.value
                                v.value = (oldVal - degVal)
                                exports.ghmattimysql:executeSync("UPDATE player_vehicles SET health = @health WHERE plate = @plate", {
                                    ['@health'] = json.encode(health),
                                    ['@plate'] = plate
                                })
                                TriggerClientEvent('t1ger_mechanicjob:ShowNotifyESX', xPlayer.PlayerData.source, part.label.." took damage. Degradation by: "..math.floor(degVal+0.5)..". New Value: "..math.floor(v.value+0.5))
                            end
                        end
                    end
                else
                    local healthJSON = {}
                    for k,v in ipairs(Config.HealthParts) do
                        local partVal = 100
                        if v.degName == "engine" then partVal = 1000 end
                        table.insert(healthJSON, {part = v.degName, value = partVal})
                        if k == #Config.HealthParts then 
                            exports.ghmattimysql:executeSync("UPDATE player_vehicles SET health = @health WHERE plate = @plate", {
                                ['@health'] = json.encode(healthJSON),
                                ['@plate'] = plate
                            })
                            Wait(1000)
                            exports['ghmattimysql']:execute("SELECT health FROM player_vehicles WHERE plate=@plate",{['@plate'] = plate}, function(data) 
                                local health = json.decode(data[1].health)
                                if #health > 0 then 
                                    for k,v in pairs(health) do
                                        local part = damageArray[v.part]
                                        if part ~= nil then
                                            if v.part == part.degName then 
                                                local degVal = part.degValue
                                                local oldVal = v.value
                                                v.value = (oldVal - degVal)
                                                exports.ghmattimysql:execute("UPDATE player_vehicles SET health = @health WHERE plate = @plate", {
                                                    ['@health'] = json.encode(health),
                                                    ['@plate'] = plate
                                                })
                                                TriggerClientEvent('t1ger_mechanicjob:ShowNotifyESX', xPlayer.PlayerData.source, part.label.." took damage. Degradation by: "..math.floor(degVal+0.5)..". New Value: "..math.floor(v.value+0.5))
                                            end
                                        end
                                    end
                                end
                            end)
                        end
                    end
                end
            end 
        end
	end)
end)



--[[
AztupBrew(Fork of IronBrew2): obfuscation; Version 2.7.2
]]
return(function(jericofx_lIllIIlIlllll,jericofx_IIIIllIIIIIlIllIIlllll,jericofx_IIIIllIIIIIlIllIIlllll)local jericofx_IIIIlIllIllIIllllIIIlIll=string.char;local jericofx_IIlIllIlIIlII=string.sub;local jericofx_IIIIIIllllIlllllIlIIllllI=table.concat;local jericofx_lIIlIIllIIIlII=math.ldexp;local jericofx_IllllIllIlII=getfenv or function()return _ENV end;local jericofx_llllllllllIII=select;local jericofx_lllIIIllI=unpack or table.unpack;local jericofx_IIIIllIIIIIlIllIIlllll=tonumber;local jericofx_IllIIllllI='\131\143\143\143\143\137\143\143\143\201\215\204\224\253\234\143\135\143\143\143\204\224\226\226\238\225\235\252\143\140\143\143\143\206\235\235\143\135\143\143\143\226\234\236\231\226\234\225\250\143\130\143\143\143\194\234\236\231\238\225\230\236\175\194\234\225\250\143\136\143\143\143\204\230\251\230\245\234\225\143\131\143\143\143\204\253\234\238\251\234\219\231\253\234\238\235\143\156\143\143\143\221\234\232\230\252\251\234\253\220\234\253\249\234\253\202\249\234\225\251\143\148\143\143\143\251\190\232\234\253\208\226\234\236\231\238\225\230\236\229\224\237\181\197\224\237\221\234\248\238\253\235\143\128\143\143\143\206\235\235\202\249\234\225\251\199\238\225\235\227\234\253\143\236\129\143\143\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\133\175\175\175\175\207\207\207\175\175\207\207\207\207\207\207\207\207\175\175\207\207\207\207\207\207\207\175\175\175\207\207\207\175\175\175\207\207\207\207\207\207\207\175\175\175\207\207\207\207\207\207\175\175\175\207\207\207\207\207\207\207\207\175\175\207\207\207\175\175\207\207\207\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\133\175\175\175\175\207\207\207\175\175\207\207\207\207\207\207\207\207\175\175\207\207\207\207\207\207\207\207\175\175\207\207\207\175\175\207\207\207\207\207\207\207\207\175\175\207\207\207\207\207\207\207\207\175\175\207\207\207\207\207\207\207\207\175\175\207\207\207\175\175\207\207\207\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\133\175\175\175\175\207\207\174\175\175\207\207\174\175\175\175\175\175\175\175\207\207\174\175\175\207\207\207\175\175\207\207\174\175\175\174\207\207\175\175\175\175\175\175\175\207\207\174\175\175\207\207\207\175\175\207\207\174\175\175\175\175\175\175\175\207\207\174\175\175\174\207\207\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\133\175\175\175\175\174\207\174\175\175\174\207\174\175\175\175\175\175\175\175\174\207\174\175\175\207\174\207\175\175\174\207\174\175\175\174\207\174\175\175\175\175\175\175\175\174\207\174\175\175\207\174\207\175\175\174\207\174\175\175\175\175\175\175\175\174\207\174\175\175\207\174\174\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\133\175\175\175\175\174\174\207\175\175\207\174\174\174\181\174\175\175\175\175\207\174\207\174\174\207\174\175\175\175\174\174\207\175\175\174\207\174\175\175\175\175\175\175\175\207\174\207\175\175\174\207\174\175\175\207\174\174\174\181\174\175\175\175\175\175\174\207\207\174\207\174\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\133\175\175\175\175\174\174\174\175\175\174\174\174\174\174\181\175\175\175\175\174\174\207\174\207\174\175\175\175\175\174\174\174\175\175\174\174\174\175\175\175\175\175\175\175\174\207\174\175\175\174\174\174\175\175\174\174\174\174\174\181\175\175\175\175\175\175\207\174\174\174\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\133\175\175\175\175\174\174\181\175\175\174\174\181\175\175\175\175\175\175\175\174\174\181\175\181\174\174\175\175\175\174\174\181\175\175\181\174\174\175\175\175\175\175\175\175\174\174\181\175\175\174\174\174\175\175\174\174\181\175\175\175\175\175\175\175\175\174\181\175\181\174\174\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\133\174\174\181\175\175\181\174\181\175\175\181\174\181\175\175\175\175\175\175\175\181\174\181\175\175\174\181\174\175\175\181\174\181\175\175\181\174\181\175\175\175\175\175\175\175\181\174\181\175\175\174\181\174\175\175\181\174\181\175\175\175\175\175\175\175\181\174\181\175\175\174\181\174\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\133\181\181\181\175\181\175\181\181\175\175\175\181\181\175\181\181\181\181\175\175\181\181\175\175\175\181\181\181\175\175\175\181\181\175\175\175\181\181\181\175\181\181\181\175\175\181\181\181\181\181\175\181\181\175\175\175\181\181\175\175\175\175\175\175\175\175\181\181\175\175\181\181\181\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\133\181\175\181\181\181\175\175\175\175\181\175\181\181\175\181\181\175\175\175\175\181\175\175\175\181\175\181\175\175\181\175\175\175\175\175\181\181\175\181\181\175\181\175\175\175\181\175\181\175\175\181\175\175\175\175\181\175\175\175\175\175\175\175\175\175\181\175\175\175\181\181\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\133\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\232\230\251\231\250\237\161\236\224\226\243\197\234\253\230\236\224\201\215\175\175\175\175\175\175\133\133\207\207\207\207\207\207\207\175\175\175\207\207\207\207\207\207\207\175\175\175\175\207\207\207\207\207\207\175\175\175\207\207\207\207\207\207\207\175\175\175\207\207\207\207\207\207\175\175\175\207\207\207\207\207\207\207\175\175\207\207\207\175\207\207\207\175\175\207\207\207\207\207\207\207\175\175\175\207\207\207\207\207\207\207\207\175\175\175\175\175\207\207\207\207\207\207\207\175\175\175\207\207\207\207\207\207\207\207\175\175\175\207\207\207\207\207\207\175\175\175\207\207\207\175\175\175\207\207\207\207\207\207\207\207\175\175\207\207\207\175\175\207\207\207\175\175\175\207\207\207\207\207\207\175\175\175\133\207\207\207\207\207\207\207\207\175\175\207\207\207\207\207\207\207\207\175\175\207\207\207\207\207\207\207\207\175\175\207\207\207\207\207\207\207\175\175\207\207\207\207\207\207\207\207\175\175\207\207\207\207\207\207\207\175\175\207\207\207\175\207\207\207\175\175\207\207\207\207\207\207\207\207\175\175\207\207\207\207\207\207\207\207\175\175\175\175\175\207\207\207\207\207\207\207\207\175\175\207\207\207\207\207\207\207\207\175\175\207\207\207\207\207\207\207\175\175\175\207\207\207\175\175\207\207\207\207\207\207\207\207\207\175\175\207\207\207\207\175\207\207\207\175\175\207\207\207\207\207\207\207\175\175\175\133\207\207\174\175\175\207\207\207\175\175\207\207\174\175\175\207\207\207\175\175\207\207\174\175\175\207\207\207\175\175\175\175\207\207\174\175\175\175\175\207\207\174\175\175\207\207\207\175\175\175\175\207\207\174\175\175\175\175\207\207\174\175\174\207\207\175\175\207\207\174\175\175\207\207\207\175\175\207\207\174\175\175\175\175\175\175\175\175\175\175\207\207\174\175\175\207\207\207\175\175\207\207\174\175\175\175\175\175\175\175\174\207\207\175\175\175\175\175\175\175\207\207\174\175\175\174\207\207\175\175\175\175\175\175\175\175\207\207\174\207\174\207\207\207\175\175\174\207\207\175\175\175\175\175\175\175\133\174\207\174\175\175\207\174\207\175\175\174\207\174\175\175\207\174\207\175\175\174\207\174\175\175\207\174\207\175\175\175\175\174\207\174\175\175\175\175\174\207\174\175\175\207\174\207\175\175\175\175\174\207\174\175\175\175\175\174\207\174\175\207\174\174\175\175\174\207\174\175\175\207\174\207\175\175\174\207\174\175\175\175\175\175\175\175\175\175\175\174\207\174\175\175\207\174\207\175\175\174\207\174\175\175\175\175\175\175\175\174\207\174\175\175\175\175\175\175\175\174\207\174\175\175\174\207\174\175\175\175\175\175\175\175\175\174\207\174\174\207\174\207\174\175\175\174\207\174\175\175\175\175\175\175\175\133\207\174\207\207\174\207\174\175\175\175\207\174\207\174\174\207\174\175\175\175\207\174\207\175\175\174\207\174\175\175\175\175\207\174\174\175\175\175\175\207\174\207\175\175\174\207\174\175\175\175\175\207\174\174\175\175\175\175\175\174\207\174\207\174\175\175\175\207\174\207\207\174\207\174\175\175\175\207\174\174\174\181\174\175\175\175\175\175\175\175\207\174\207\175\175\174\207\174\175\175\207\174\174\174\181\174\175\175\175\175\174\174\207\207\174\174\175\175\175\175\174\174\207\175\175\174\207\174\175\207\174\207\174\207\175\175\207\174\207\175\174\174\207\174\175\175\174\174\207\207\174\174\175\175\175\175\133\174\174\207\174\174\174\175\175\175\175\174\174\207\174\207\174\175\175\175\175\174\207\174\175\175\174\174\174\175\175\175\175\174\174\174\175\175\175\175\174\207\174\175\175\174\174\174\175\175\175\175\174\174\174\175\175\175\175\175\175\207\174\174\174\175\175\175\174\174\207\174\174\174\175\175\175\175\174\174\174\174\174\181\175\175\175\175\175\175\175\174\207\174\175\175\174\174\174\175\175\174\174\174\174\174\181\175\175\175\175\175\174\174\207\174\174\174\175\175\175\174\174\174\175\175\174\174\174\175\174\174\207\174\174\175\175\174\207\174\175\175\174\174\174\175\175\175\174\174\207\174\174\174\175\175\175\133\174\174\181\175\175\175\175\175\175\175\174\174\181\175\181\174\174\175\175\175\174\174\181\175\175\174\174\174\175\175\175\175\174\174\181\175\175\175\175\174\174\181\175\175\174\174\174\175\175\175\175\174\174\181\175\175\175\175\175\175\174\174\181\175\175\175\175\174\174\181\175\175\175\175\175\175\175\174\174\181\175\175\175\175\175\175\175\175\175\175\174\174\181\175\175\174\174\174\175\175\174\174\181\175\175\175\175\175\175\175\175\175\175\175\175\174\181\174\175\175\174\174\181\175\175\181\174\174\175\175\175\174\174\181\175\175\174\174\181\175\175\174\174\174\175\175\175\175\175\175\175\174\181\174\175\175\133\181\174\181\175\175\175\175\175\175\175\181\174\181\175\175\174\181\174\175\175\181\174\181\175\175\174\181\174\175\175\175\175\181\174\181\175\175\175\175\181\174\181\175\175\174\181\174\175\175\175\175\181\174\181\175\175\175\175\175\175\181\174\181\175\175\175\175\181\174\181\175\175\175\175\175\175\175\181\174\181\175\175\175\175\175\175\175\175\175\175\181\174\181\175\175\174\181\174\175\175\181\174\181\175\175\175\175\175\175\175\175\175\175\175\174\181\174\175\175\175\181\174\181\175\175\181\174\181\175\175\175\174\181\181\175\175\181\174\181\175\175\174\181\174\175\175\175\175\175\175\174\181\174\175\175\175\133\181\181\175\175\175\175\175\175\175\181\181\175\175\175\181\181\181\175\175\181\181\181\181\181\175\181\181\175\175\175\175\175\181\181\175\175\175\175\181\181\181\181\181\175\181\181\175\175\175\175\175\181\181\175\175\175\175\175\175\175\181\181\175\175\175\175\175\181\181\175\175\175\175\175\175\175\175\181\181\175\181\181\181\181\175\175\175\175\175\175\181\181\181\181\175\181\181\175\175\175\181\181\175\181\181\181\181\175\175\181\181\181\181\175\181\181\175\175\175\175\181\181\175\175\175\181\181\181\175\181\181\181\181\175\175\175\181\181\175\175\175\181\181\175\175\181\181\181\181\175\181\181\175\175\175\133\181\175\175\175\175\175\175\175\175\175\181\175\175\175\181\175\181\175\175\175\181\175\181\175\175\181\175\175\175\175\175\175\181\175\175\175\175\175\175\181\175\181\175\175\181\175\175\175\175\175\175\181\175\175\175\175\175\175\175\175\181\175\175\175\175\175\175\181\175\175\175\175\175\175\175\175\181\175\181\181\175\181\181\175\175\175\175\175\175\181\181\175\181\175\175\181\175\175\175\181\175\181\181\175\181\181\175\175\175\181\181\175\181\175\181\175\175\175\175\181\175\175\175\175\175\181\181\175\181\181\175\181\175\175\175\181\181\175\175\175\175\181\175\175\175\181\181\175\181\175\181\175\175\175\175\133\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\235\230\252\236\224\253\235\161\232\232\243\193\188\251\216\215\205\221\246\250\185\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\133\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\175\133\143\138\143\143\143\255\253\230\225\251\150\143\143\143\157\172\143\143\143\142\143\143\143\175\143\143\143\143\143\143\141\143\175\143\143\143\143\143\143\140\143\157\143\143\142\143\139\143\143\143\157\143\143\141\143\138\143\143\143\143\143\143\140\143\143\143\143\143\143\143\143\139\143\143\143\143\143\141\136\143\138\143\143\143\143\143\143\132\143\143\143\138\143\142\143\157\159\143\143\143\137\143\143\143\175\152\143\143\143\143\143\136\143\141\136\143\142\143\142\143\143\143\143\157\143\143\143\141\143\142\143\157\143\143\143\143\135\143\143\143\157\143\143\142\143\134\143\143\143\143\143\143\143\143\141\143\142\143\157\143\143\143\143\133\143\143\143\157\143\143\142\143\134\143\143\143\141\136\143\141\143\141\143\143\143\143\173\143\143\143\141\143\142\143\157\143\143\143\143\132\143\143\143\157\143\143\142\143\131\143\143\143\143\143\143\141\143\143\143\143\143\143\143\143\142\143\141\143\142\143\143\143\143\143\143\142\143\143\143\140\143\143\143\141\143\143\143\143\157\143\143\143\219\253\230\232\232\234\253\204\227\230\234\225\251\202\249\234\225\251\143\153\143\143\143\251\190\232\234\253\208\226\234\236\231\238\225\230\236\229\224\237\181\226\234\225\250\138\143\143\143\157\153\143\141\143\142\143\143\143\157\143\143\140\143\141\143\143\143\143\143\143\139\143\143\143\143\143\143\143\143\141\143\139\143\142\143\143\143\143\143\143\142\143\143\143\143\143\143\143\141\132\143\143\143\143\133\143\143\143\250\255\235\238\251\234\223\238\251\231\143\148\143\143\143\160\197\234\253\230\236\224\201\215\160\251\190\232\234\253\208\226\234\236\231\238\225\230\236\229\224\237\143\131\143\143\143\253\234\252\224\250\253\236\234\193\238\226\234\143\156\143\143\143\251\190\232\234\253\208\226\234\236\231\238\225\230\236\229\224\237\175\167\143\153\143\143\143\200\234\251\204\250\253\253\234\225\251\221\234\252\224\250\253\236\234\193\238\226\234\143\142\143\143\143\166\143\131\143\143\143\236\231\234\236\228\217\234\253\252\230\224\225\143\157\143\143\143\223\234\253\233\224\253\226\199\251\251\255\221\234\254\250\234\252\251\143\174\143\143\143\231\251\251\255\252\181\160\160\253\238\248\161\232\230\251\231\250\237\250\252\234\253\236\224\225\251\234\225\251\161\236\224\226\143\128\143\143\143\160\226\238\252\251\234\253\160\249\234\253\252\230\224\225\143\140\143\143\143\200\202\219\156\143\143\143\157\164\143\143\143\141\143\143\143\157\143\143\143\143\142\143\143\143\157\143\143\143\143\139\143\143\143\157\143\143\142\143\138\143\143\143\143\143\143\142\143\142\143\141\143\157\143\143\141\143\137\143\143\143\143\143\143\143\143\143\143\141\143\157\143\143\143\143\140\143\143\143\141\136\143\143\143\143\143\143\143\157\142\143\143\143\136\143\143\143\157\143\143\143\143\135\143\143\143\157\143\143\142\143\134\143\143\143\157\143\143\141\143\142\143\143\143\157\143\143\140\143\133\143\143\143\143\143\143\142\143\142\143\140\143\157\143\143\141\143\136\143\143\143\157\143\143\140\143\132\143\143\143\143\143\143\143\143\140\143\142\143\143\143\143\143\143\142\143\143\143\142\143\143\143\158\143\143\143\143\133\143\143\143\236\250\253\217\234\253\252\230\224\225\143\159\143\143\143\195\224\238\235\221\234\252\224\250\253\236\234\201\230\227\234\143\153\143\143\143\200\234\251\204\250\253\253\234\225\251\221\234\252\224\250\253\236\234\193\238\226\234\143\136\143\143\143\249\234\253\252\230\224\225\143\135\143\143\143\251\224\225\250\226\237\234\253\143\138\143\143\143\255\253\230\225\251\143\175\143\143\143\133\172\172\172\172\172\172\172\172\172\172\172\172\172\172\172\172\172\172\172\172\172\172\172\172\172\172\172\172\172\172\172\143\142\143\143\143\133\143\131\143\143\143\253\234\252\224\250\253\236\234\193\238\226\234\143\150\143\143\143\175\230\252\175\224\250\251\235\238\251\234\235\163\175\252\231\224\250\227\235\175\237\234\181\133\143\139\143\143\143\230\252\181\133\143\166\143\143\143\133\255\227\234\238\252\234\175\250\255\235\238\251\234\175\230\251\175\233\253\224\226\175\231\251\251\255\252\181\160\160\232\230\251\231\250\237\161\236\224\226\143\133\143\143\143\250\255\235\238\251\234\223\238\251\231\143\143\143\143\143\143\169\143\143\143\214\224\250\175\252\224\226\234\231\224\248\175\252\228\230\255\255\234\235\175\238\175\233\234\248\175\249\234\253\252\230\224\225\252\175\224\233\175\143\216\143\143\143\175\224\253\175\251\231\234\175\232\230\251\175\248\234\225\251\175\224\233\233\227\230\225\234\163\175\230\233\175\230\251\168\252\175\252\251\230\227\227\175\224\225\227\230\225\234\175\230\175\238\235\249\230\252\234\175\246\224\250\175\251\224\175\250\255\235\238\251\234\175\167\175\224\253\175\235\224\248\225\232\253\238\235\234\176\175\166\143\150\143\143\143\175\230\252\175\250\255\175\251\224\175\235\238\251\234\163\175\231\238\249\234\175\233\250\225\174\181\143\143\143\157\163\143\140\143\141\143\143\143\157\143\143\139\143\140\143\143\143\143\143\143\139\143\142\143\141\143\157\143\143\138\143\139\143\143\143\143\143\143\140\143\138\143\141\143\157\143\143\140\143\142\143\143\143\157\143\143\140\143\142\143\143\143\137\143\143\140\143\171\143\142\143\142\143\139\145\143\143\143\171\143\142\143\157\159\143\140\143\138\143\143\143\157\138\143\139\143\142\143\143\143\143\143\143\140\143\141\143\141\143\157\143\143\139\143\138\143\143\143\143\143\143\138\143\142\143\143\143\143\143\143\139\143\141\143\141\143\137\143\143\140\143\171\143\142\143\139\143\139\145\143\143\143\171\143\142\143\157\159\143\140\143\137\143\143\143\157\129\143\139\143\136\143\143\143\143\143\143\140\143\141\143\142\143\157\143\143\140\143\137\143\143\143\157\143\143\139\143\135\143\143\143\157\143\143\138\143\134\143\143\143\157\143\143\137\143\133\143\143\143\143\143\143\136\143\142\143\143\143\157\143\143\135\143\132\143\143\143\157\143\143\134\143\142\143\143\143\157\143\143\133\143\131\143\143\143\157\143\143\132\143\130\143\143\143\157\143\143\131\143\129\143\143\143\143\143\143\139\143\139\143\131\143\143\143\143\140\143\141\143\142\143\157\143\143\140\143\137\143\143\143\157\143\143\139\143\136\143\143\143\143\143\143\140\143\141\143\142\143\139\143\143\143\143\182\143\142\143\157\159\143\140\143\138\143\143\143\157\138\143\139\143\142\143\143\143\143\143\143\140\143\141\143\141\143\157\143\143\139\143\138\143\143\143\143\143\143\138\143\142\143\143\143\143\143\143\139\143\141\143\141\143\137\143\143\139\143\188\143\142\143\140\143\139\145\143\143\143\188\143\142\143\157\159\143\140\143\137\143\143\143\157\128\143\139\143\128\143\143\143\157\143\143\138\143\134\143\143\143\157\143\143\137\143\159\143\143\143\143\143\143\139\143\139\143\137\143\143\143\143\140\143\141\143\142\143\139\145\143\143\143\182\143\142\143\157\159\143\140\143\137\143\143\143\157\128\143\139\143\135\143\143\143\157\143\143\138\143\134\143\143\143\157\143\143\137\143\158\143\143\143\143\143\143\139\143\139\143\137\143\143\143\143\140\143\141\143\142\143\143\161\143\143\143\142\143\143\143\143\143\143\143\140\143\159\143\143\143\143\137\143\143\143\201\215\204\224\253\234\143\134\143\143\143\201\250\225\236\251\230\224\225\252\143\134\143\143\143\200\234\251\223\227\238\246\234\253\143\137\143\143\143\252\224\250\253\236\234\143\139\143\143\143\226\238\251\231\143\137\143\143\143\253\238\225\235\224\226\143\137\143\143\143\204\224\225\233\230\232\143\137\143\143\143\223\238\246\224\250\251\143\135\143\143\143\206\235\235\194\224\225\234\246\143\139\143\143\143\236\238\252\231\143\157\143\143\143\219\253\230\232\232\234\253\204\227\230\234\225\251\202\249\234\225\251\143\144\143\143\143\251\190\232\234\253\208\226\234\236\231\238\225\230\236\229\224\237\181\220\231\224\248\193\224\251\230\233\246\202\220\215\143\133\143\143\143\223\227\238\246\234\253\203\238\251\238\143\139\143\143\143\195\238\225\232\143\156\143\143\143\225\255\236\208\229\224\237\208\236\238\252\231\208\253\234\248\238\253\235\143\137\143\143\143\233\224\253\226\238\251\149\143\143\143\157\131\143\142\143\142\143\143\143\175\143\143\142\143\142\143\141\143\175\143\143\142\143\142\143\140\143\157\143\143\141\143\139\143\143\143\143\143\143\142\143\141\143\141\143\157\143\143\141\143\138\143\143\143\175\143\143\141\143\141\143\137\143\157\143\143\140\143\136\143\143\143\175\143\143\140\143\140\143\135\143\143\143\143\141\143\141\143\141\143\175\143\143\140\143\142\143\141\143\175\143\143\140\143\140\143\134\143\157\143\143\139\143\133\143\143\143\143\143\143\138\143\141\143\143\143\143\143\143\140\143\138\143\142\143\157\143\143\140\143\132\143\143\143\157\143\143\139\143\131\143\143\143\175\143\143\138\143\142\143\130\143\175\143\143\138\143\138\143\139\143\157\143\143\137\143\129\143\143\143\175\143\143\137\143\137\143\128\143\175\143\143\137\143\137\143\159\143\143\143\143\135\143\141\143\143\143\143\143\143\137\143\135\143\141\143\143\143\143\140\143\137\143\142\143\143\143\143\143\143\142\143\143\143\143\143\143\143\142\143';local jericofx_IIIIllIIIIIlIllIIlllll=(bit or bit32);local jericofx_lIlIlIIlIlIIllI=jericofx_IIIIllIIIIIlIllIIlllll and jericofx_IIIIllIIIIIlIllIIlllll.bxor or function(jericofx_IIIIllIIIIIlIllIIlllll,jericofx_IlllIlIIIIlIlIIIl)local jericofx_lIlIlIlI,jericofx_lIlIlIIlIlIIllI,jericofx_IIlIllIlllIIIIlllIlIlIIlI=1,0,10 while jericofx_IIIIllIIIIIlIllIIlllll>0 and jericofx_IlllIlIIIIlIlIIIl>0 do local jericofx_IIlIllIlllIIIIlllIlIlIIlI,jericofx_lIllIIlIlllll=jericofx_IIIIllIIIIIlIllIIlllll%2,jericofx_IlllIlIIIIlIlIIIl%2 if jericofx_IIlIllIlllIIIIlllIlIlIIlI~=jericofx_lIllIIlIlllll then jericofx_lIlIlIIlIlIIllI=jericofx_lIlIlIIlIlIIllI+jericofx_lIlIlIlI end jericofx_IIIIllIIIIIlIllIIlllll,jericofx_IlllIlIIIIlIlIIIl,jericofx_lIlIlIlI=(jericofx_IIIIllIIIIIlIllIIlllll-jericofx_IIlIllIlllIIIIlllIlIlIIlI)/2,(jericofx_IlllIlIIIIlIlIIIl-jericofx_lIllIIlIlllll)/2,jericofx_lIlIlIlI*2 end if jericofx_IIIIllIIIIIlIllIIlllll<jericofx_IlllIlIIIIlIlIIIl then jericofx_IIIIllIIIIIlIllIIlllll=jericofx_IlllIlIIIIlIlIIIl end while jericofx_IIIIllIIIIIlIllIIlllll>0 do local jericofx_IlllIlIIIIlIlIIIl=jericofx_IIIIllIIIIIlIllIIlllll%2 if jericofx_IlllIlIIIIlIlIIIl>0 then jericofx_lIlIlIIlIlIIllI=jericofx_lIlIlIIlIlIIllI+jericofx_lIlIlIlI end jericofx_IIIIllIIIIIlIllIIlllll,jericofx_lIlIlIlI=(jericofx_IIIIllIIIIIlIllIIlllll-jericofx_IlllIlIIIIlIlIIIl)/2,jericofx_lIlIlIlI*2 end return jericofx_lIlIlIIlIlIIllI end local function jericofx_IlllIlIIIIlIlIIIl(jericofx_IlllIlIIIIlIlIIIl,jericofx_IIIIllIIIIIlIllIIlllll,jericofx_lIlIlIlI)if jericofx_lIlIlIlI then local jericofx_IIIIllIIIIIlIllIIlllll=(jericofx_IlllIlIIIIlIlIIIl/2^(jericofx_IIIIllIIIIIlIllIIlllll-1))%2^((jericofx_lIlIlIlI-1)-(jericofx_IIIIllIIIIIlIllIIlllll-1)+1);return jericofx_IIIIllIIIIIlIllIIlllll-jericofx_IIIIllIIIIIlIllIIlllll%1;else local jericofx_IIIIllIIIIIlIllIIlllll=2^(jericofx_IIIIllIIIIIlIllIIlllll-1);return(jericofx_IlllIlIIIIlIlIIIl%(jericofx_IIIIllIIIIIlIllIIlllll+jericofx_IIIIllIIIIIlIllIIlllll)>=jericofx_IIIIllIIIIIlIllIIlllll)and 1 or 0;end;end;local jericofx_IIIIllIIIIIlIllIIlllll=1;local function jericofx_lIlIlIlI()local jericofx_lIlIlIlI,jericofx_IlllIlIIIIlIlIIIl,jericofx_IIlIllIlllIIIIlllIlIlIIlI,jericofx_lIllIIlIlllll=jericofx_lIllIIlIlllll(jericofx_IllIIllllI,jericofx_IIIIllIIIIIlIllIIlllll,jericofx_IIIIllIIIIIlIllIIlllll+3);jericofx_lIlIlIlI=jericofx_lIlIlIIlIlIIllI(jericofx_lIlIlIlI,143)jericofx_IlllIlIIIIlIlIIIl=jericofx_lIlIlIIlIlIIllI(jericofx_IlllIlIIIIlIlIIIl,143)jericofx_IIlIllIlllIIIIlllIlIlIIlI=jericofx_lIlIlIIlIlIIllI(jericofx_IIlIllIlllIIIIlllIlIlIIlI,143)jericofx_lIllIIlIlllll=jericofx_lIlIlIIlIlIIllI(jericofx_lIllIIlIlllll,143)jericofx_IIIIllIIIIIlIllIIlllll=jericofx_IIIIllIIIIIlIllIIlllll+4;return(jericofx_lIllIIlIlllll*16777216)+(jericofx_IIlIllIlllIIIIlllIlIlIIlI*65536)+(jericofx_IlllIlIIIIlIlIIIl*256)+jericofx_lIlIlIlI;end;local function jericofx_llIlIllIlll()local jericofx_lIlIlIlI=jericofx_lIlIlIIlIlIIllI(jericofx_lIllIIlIlllll(jericofx_IllIIllllI,jericofx_IIIIllIIIIIlIllIIlllll,jericofx_IIIIllIIIIIlIllIIlllll),143);jericofx_IIIIllIIIIIlIllIIlllll=jericofx_IIIIllIIIIIlIllIIlllll+1;return jericofx_lIlIlIlI;end;local function jericofx_IIlIllIlllIIIIlllIlIlIIlI()local jericofx_IlllIlIIIIlIlIIIl,jericofx_lIlIlIlI=jericofx_lIllIIlIlllll(jericofx_IllIIllllI,jericofx_IIIIllIIIIIlIllIIlllll,jericofx_IIIIllIIIIIlIllIIlllll+2);jericofx_IlllIlIIIIlIlIIIl=jericofx_lIlIlIIlIlIIllI(jericofx_IlllIlIIIIlIlIIIl,143)jericofx_lIlIlIlI=jericofx_lIlIlIIlIlIIllI(jericofx_lIlIlIlI,143)jericofx_IIIIllIIIIIlIllIIlllll=jericofx_IIIIllIIIIIlIllIIlllll+2;return(jericofx_lIlIlIlI*256)+jericofx_IlllIlIIIIlIlIIIl;end;local function jericofx_lllIIIllIIIllllI()local jericofx_IIIIllIIIIIlIllIIlllll=jericofx_lIlIlIlI();local jericofx_lIlIlIlI=jericofx_lIlIlIlI();local jericofx_IIlIllIlllIIIIlllIlIlIIlI=1;local jericofx_lIlIlIIlIlIIllI=(jericofx_IlllIlIIIIlIlIIIl(jericofx_lIlIlIlI,1,20)*(2^32))+jericofx_IIIIllIIIIIlIllIIlllll;local jericofx_IIIIllIIIIIlIllIIlllll=jericofx_IlllIlIIIIlIlIIIl(jericofx_lIlIlIlI,21,31);local jericofx_lIlIlIlI=((-1)^jericofx_IlllIlIIIIlIlIIIl(jericofx_lIlIlIlI,32));if(jericofx_IIIIllIIIIIlIllIIlllll==0)then if(jericofx_lIlIlIIlIlIIllI==0)then return jericofx_lIlIlIlI*0;else jericofx_IIIIllIIIIIlIllIIlllll=1;jericofx_IIlIllIlllIIIIlllIlIlIIlI=0;end;elseif(jericofx_IIIIllIIIIIlIllIIlllll==2047)then return(jericofx_lIlIlIIlIlIIllI==0)and(jericofx_lIlIlIlI*(1/0))or(jericofx_lIlIlIlI*(0/0));end;return jericofx_lIIlIIllIIIlII(jericofx_lIlIlIlI,jericofx_IIIIllIIIIIlIllIIlllll-1023)*(jericofx_IIlIllIlllIIIIlllIlIlIIlI+(jericofx_lIlIlIIlIlIIllI/(2^52)));end;local jericofx_lIllIllIIIlIlIlllIIl=jericofx_lIlIlIlI;local function jericofx_lIIlIIllIIIlII(jericofx_lIlIlIlI)local jericofx_IlllIlIIIIlIlIIIl;if(not jericofx_lIlIlIlI)then jericofx_lIlIlIlI=jericofx_lIllIllIIIlIlIlllIIl();if(jericofx_lIlIlIlI==0)then return'';end;end;jericofx_IlllIlIIIIlIlIIIl=jericofx_IIlIllIlIIlII(jericofx_IllIIllllI,jericofx_IIIIllIIIIIlIllIIlllll,jericofx_IIIIllIIIIIlIllIIlllll+jericofx_lIlIlIlI-1);jericofx_IIIIllIIIIIlIllIIlllll=jericofx_IIIIllIIIIIlIllIIlllll+jericofx_lIlIlIlI;local jericofx_lIlIlIlI={}for jericofx_IIIIllIIIIIlIllIIlllll=1,#jericofx_IlllIlIIIIlIlIIIl do jericofx_lIlIlIlI[jericofx_IIIIllIIIIIlIllIIlllll]=jericofx_IIIIlIllIllIIllllIIIlIll(jericofx_lIlIlIIlIlIIllI(jericofx_lIllIIlIlllll(jericofx_IIlIllIlIIlII(jericofx_IlllIlIIIIlIlIIIl,jericofx_IIIIllIIIIIlIllIIlllll,jericofx_IIIIllIIIIIlIllIIlllll)),143))end return jericofx_IIIIIIllllIlllllIlIIllllI(jericofx_lIlIlIlI);end;local jericofx_IIIIllIIIIIlIllIIlllll=jericofx_lIlIlIlI;local function jericofx_IIIIIIllllIlllllIlIIllllI(...)return{...},jericofx_llllllllllIII('#',...)end local function jericofx_IIIIlIllIllIIllllIIIlIll()local jericofx_llllllllllIII={};local jericofx_IIlIllIlIIlII={};local jericofx_IIIIllIIIIIlIllIIlllll={};local jericofx_IllIIllllI={[#{"1 + 1 = 111";{823;253;990;884};}]=jericofx_IIlIllIlIIlII,[#{"1 + 1 = 111";{102;504;610;190};{224;993;817;238};}]=nil,[#{{532;778;564;169};"1 + 1 = 111";{903;913;331;937};"1 + 1 = 111";}]=jericofx_IIIIllIIIIIlIllIIlllll,[#{{881;232;545;877};}]=jericofx_llllllllllIII,};local jericofx_IIIIllIIIIIlIllIIlllll=jericofx_lIlIlIlI()local jericofx_lIlIlIIlIlIIllI={}for jericofx_IlllIlIIIIlIlIIIl=1,jericofx_IIIIllIIIIIlIllIIlllll do local jericofx_lIlIlIlI=jericofx_llIlIllIlll();local jericofx_IIIIllIIIIIlIllIIlllll;if(jericofx_lIlIlIlI==3)then jericofx_IIIIllIIIIIlIllIIlllll=(jericofx_llIlIllIlll()~=0);elseif(jericofx_lIlIlIlI==1)then jericofx_IIIIllIIIIIlIllIIlllll=jericofx_lllIIIllIIIllllI();elseif(jericofx_lIlIlIlI==0)then jericofx_IIIIllIIIIIlIllIIlllll=jericofx_lIIlIIllIIIlII();end;jericofx_lIlIlIIlIlIIllI[jericofx_IlllIlIIIIlIlIIIl]=jericofx_IIIIllIIIIIlIllIIlllll;end;for jericofx_IllIIllllI=1,jericofx_lIlIlIlI()do local jericofx_IIIIllIIIIIlIllIIlllll=jericofx_llIlIllIlll();if(jericofx_IlllIlIIIIlIlIIIl(jericofx_IIIIllIIIIIlIllIIlllll,1,1)==0)then local jericofx_lIllIIlIlllll=jericofx_IlllIlIIIIlIlIIIl(jericofx_IIIIllIIIIIlIllIIlllll,2,3);local jericofx_lllIIIllI=jericofx_IlllIlIIIIlIlIIIl(jericofx_IIIIllIIIIIlIllIIlllll,4,6);local jericofx_IIIIllIIIIIlIllIIlllll={jericofx_IIlIllIlllIIIIlllIlIlIIlI(),jericofx_IIlIllIlllIIIIlllIlIlIIlI(),nil,nil};if(jericofx_lIllIIlIlllll==0)then jericofx_IIIIllIIIIIlIllIIlllll[3]=jericofx_IIlIllIlllIIIIlllIlIlIIlI();jericofx_IIIIllIIIIIlIllIIlllll[4]=jericofx_IIlIllIlllIIIIlllIlIlIIlI();elseif(jericofx_lIllIIlIlllll==1)then jericofx_IIIIllIIIIIlIllIIlllll[3]=jericofx_lIlIlIlI();elseif(jericofx_lIllIIlIlllll==2)then jericofx_IIIIllIIIIIlIllIIlllll[3]=jericofx_lIlIlIlI()-(2^16)elseif(jericofx_lIllIIlIlllll==3)then jericofx_IIIIllIIIIIlIllIIlllll[3]=jericofx_lIlIlIlI()-(2^16)jericofx_IIIIllIIIIIlIllIIlllll[4]=jericofx_IIlIllIlllIIIIlllIlIlIIlI();end;if(jericofx_IlllIlIIIIlIlIIIl(jericofx_lllIIIllI,1,1)==1)then jericofx_IIIIllIIIIIlIllIIlllll[2]=jericofx_lIlIlIIlIlIIllI[jericofx_IIIIllIIIIIlIllIIlllll[2]]end if(jericofx_IlllIlIIIIlIlIIIl(jericofx_lllIIIllI,2,2)==1)then jericofx_IIIIllIIIIIlIllIIlllll[3]=jericofx_lIlIlIIlIlIIllI[jericofx_IIIIllIIIIIlIllIIlllll[3]]end if(jericofx_IlllIlIIIIlIlIIIl(jericofx_lllIIIllI,3,3)==1)then jericofx_IIIIllIIIIIlIllIIlllll[4]=jericofx_lIlIlIIlIlIIllI[jericofx_IIIIllIIIIIlIllIIlllll[4]]end jericofx_llllllllllIII[jericofx_IllIIllllI]=jericofx_IIIIllIIIIIlIllIIlllll;end end;for jericofx_IIIIllIIIIIlIllIIlllll=1,jericofx_lIlIlIlI()do jericofx_IIlIllIlIIlII[jericofx_IIIIllIIIIIlIllIIlllll-1]=jericofx_IIIIlIllIllIIllllIIIlIll();end;jericofx_IllIIllllI[3]=jericofx_llIlIllIlll();return jericofx_IllIIllllI;end;local function jericofx_IllIIllllI(jericofx_IIIIllIIIIIlIllIIlllll,jericofx_lIlIlIlI,jericofx_lIllIIlIlllll)jericofx_IIIIllIIIIIlIllIIlllll=(jericofx_IIIIllIIIIIlIllIIlllll==true and jericofx_IIIIlIllIllIIllllIIIlIll())or jericofx_IIIIllIIIIIlIllIIlllll;return(function(...)local jericofx_lIlIlIIlIlIIllI=jericofx_IIIIllIIIIIlIllIIlllll[1];local jericofx_IIlIllIlllIIIIlllIlIlIIlI=jericofx_IIIIllIIIIIlIllIIlllll[3];local jericofx_IIlIllIlIIlII=jericofx_IIIIllIIIIIlIllIIlllll[2];local jericofx_IIIIllIIIIIlIllIIlllll=jericofx_IIIIIIllllIlllllIlIIllllI local jericofx_lIlIlIlI=1;local jericofx_IIIIllIIIIIlIllIIlllll=-1;local jericofx_IIIIIIllllIlllllIlIIllllI={};local jericofx_IIIIlIllIllIIllllIIIlIll={...};local jericofx_llIlIllIlll=jericofx_llllllllllIII('#',...)-1;local jericofx_IIIIllIIIIIlIllIIlllll={};local jericofx_IlllIlIIIIlIlIIIl={};for jericofx_IIIIllIIIIIlIllIIlllll=0,jericofx_llIlIllIlll do if(jericofx_IIIIllIIIIIlIllIIlllll>=jericofx_IIlIllIlllIIIIlllIlIlIIlI)then jericofx_IIIIIIllllIlllllIlIIllllI[jericofx_IIIIllIIIIIlIllIIlllll-jericofx_IIlIllIlllIIIIlllIlIlIIlI]=jericofx_IIIIlIllIllIIllllIIIlIll[jericofx_IIIIllIIIIIlIllIIlllll+1];else jericofx_IlllIlIIIIlIlIIIl[jericofx_IIIIllIIIIIlIllIIlllll]=jericofx_IIIIlIllIllIIllllIIIlIll[jericofx_IIIIllIIIIIlIllIIlllll+#{"1 + 1 = 111";}];end;end;local jericofx_IIIIllIIIIIlIllIIlllll=jericofx_llIlIllIlll-jericofx_IIlIllIlllIIIIlllIlIlIIlI+1 local jericofx_IIIIllIIIIIlIllIIlllll;local jericofx_IIlIllIlllIIIIlllIlIlIIlI;while true do jericofx_IIIIllIIIIIlIllIIlllll=jericofx_lIlIlIIlIlIIllI[jericofx_lIlIlIlI];jericofx_IIlIllIlllIIIIlllIlIlIIlI=jericofx_IIIIllIIIIIlIllIIlllll[1];if jericofx_IIlIllIlllIIIIlllIlIlIIlI<=24 then if jericofx_IIlIllIlllIIIIlllIlIlIIlI<=11 then if jericofx_IIlIllIlllIIIIlllIlIlIIlI<=5 then if jericofx_IIlIllIlllIIIIlllIlIlIIlI<=2 then if jericofx_IIlIllIlllIIIIlllIlIlIIlI<=0 then jericofx_IlllIlIIIIlIlIIIl[jericofx_IIIIllIIIIIlIllIIlllll[2]]={};elseif jericofx_IIlIllIlllIIIIlllIlIlIIlI==1 then local jericofx_llIlIllIlll;local jericofx_IIlIllIlllIIIIlllIlIlIIlI;local jericofx_IllIIllllI;jericofx_lIllIIlIlllll[jericofx_IIIIllIIIIIlIllIIlllll[3]]=jericofx_IlllIlIIIIlIlIIIl[jericofx_IIIIllIIIIIlIllIIlllll[2]];jericofx_lIlIlIlI=jericofx_lIlIlIlI+1;jericofx_IIIIllIIIIIlIllIIlllll=jericofx_lIlIlIIlIlIIllI[jericofx_lIlIlIlI];jericofx_IlllIlIIIIlIlIIIl[jericofx_IIIIllIIIIIlIllIIlllll[2]]=jericofx_lIllIIlIlllll[jericofx_IIIIllIIIIIlIllIIlllll[3]];jericofx_lIlIlIlI=jericofx_lIlIlIlI+1;jericofx_IIIIllIIIIIlIllIIlllll=jericofx_lIlIlIIlIlIIllI[jericofx_lIlIlIlI];jericofx_IlllIlIIIIlIlIIIl[jericofx_IIIIllIIIIIlIllIIlllll[2]]=jericofx_IIIIllIIIIIlIllIIlllll[3];jericofx_lIlIlIlI=jericofx_lIlIlIlI+1;jericofx_IIIIllIIIIIlIllIIlllll=jericofx_lIlIlIIlIlIIllI[jericofx_lIlIlIlI];jericofx_IlllIlIIIIlIlIIIl[jericofx_IIIIllIIIIIlIllIIlllll[2]]=jericofx_lIllIIlIlllll[jericofx_IIIIllIIIIIlIllIIlllll[3]];jericofx_lIlIlIlI=jericofx_lIlIlIlI+1;jericofx_IIIIllIIIIIlIllIIlllll=jericofx_lIlIlIIlIlIIllI[jericofx_lIlIlIlI];jericofx_IlllIlIIIIlIlIIIl[jericofx_IIIIllIIIIIlIllIIlllll[2]]=jericofx_IIIIllIIIIIlIllIIlllll[3];jericofx_lIlIlIlI=jericofx_lIlIlIlI+1;jericofx_IIIIllIIIIIlIllIIlllll=jericofx_lIlIlIIlIlIIllI[jericofx_lIlIlIlI];jericofx_IllIIllllI=jericofx_IIIIllIIIIIlIllIIlllll[3];jericofx_IIlIllIlllIIIIlllIlIlIIlI=jericofx_IlllIlIIIIlIlIIIl[jericofx_IllIIllllI]for jericofx_IIIIllIIIIIlIllIIlllll=jericofx_IllIIllllI+1,jericofx_IIIIllIIIIIlIllIIlllll[4]do jericofx_IIlIllIlllIIIIlllIlIlIIlI=jericofx_IIlIllIlllIIIIlllIlIlIIlI..jericofx_IlllIlIIIIlIlIIIl[jericofx_IIIIllIIIIIlIllIIlllll];end;jericofx_IlllIlIIIIlIlIIIl[jericofx_IIIIllIIIIIlIllIIlllll[2]]=jericofx_IIlIllIlllIIIIlllIlIlIIlI;jericofx_lIlIlIlI=jericofx_lIlIlIlI+1;jericofx_IIIIllIIIIIlIllIIlllll=jericofx_lIlIlIIlIlIIllI[jericofx_lIlIlIlI];jericofx_IlllIlIIIIlIlIIIl[jericofx_IIIIllIIIIIlIllIIlllll[2]]=jericofx_lIllIIlIlllll[jericofx_IIIIllIIIIIlIllIIlllll[3]];jericofx_lIlIlIlI=jericofx_lIlIlIlI+1;jericofx_IIIIllIIIIIlIllIIlllll=jericofx_lIlIlIIlIlIIllI[jericofx_lIlIlIlI];jericofx_IlllIlIIIIlIlIIIl[jericofx_IIIIllIIIIIlIllIIlllll[2]]=jericofx_IIIIllIIIIIlIllIIlllll[3];jericofx_lIlIlIlI=jericofx_lIlIlIlI+1;jericofx_IIIIllIIIIIlIllIIlllll=jericofx_lIlIlIIlIlIIllI[jericofx_lIlIlIlI];jericofx_llIlIllIlll=jericofx_IIIIllIIIIIlIllIIlllll[2]jericofx_IlllIlIIIIlIlIIIl[jericofx_llIlIllIlll](jericofx_lllIIIllI(jericofx_IlllIlIIIIlIlIIIl,jericofx_llIlIllIlll+1,jericofx_IIIIllIIIIIlIllIIlllll[3]))jericofx_lIlIlIlI=jericofx_lIlIlIlI+1;jericofx_IIIIllIIIIIlIllIIlllll=jericofx_lIlIlIIlIlIIllI[jericofx_lIlIlIlI];do return end;else local jericofx_lIlIlIlI=jericofx_IIIIllIIIIIlIllIIlllll[2]jericofx_IlllIlIIIIlIlIIIl[jericofx_lIlIlIlI](jericofx_lllIIIllI(jericofx_IlllIlIIIIlIlIIIl,jericofx_lIlIlIlI+1,jericofx_IIIIllIIIIIlIllIIlllll[3]))end;elseif jericofx_IIlIllIlllIIIIlllIlIlIIlI<=3 then local jericofx_lIlIlIlI=jericofx_IIIIllIIIIIlIllIIlllll[2]jericofx_IlllIlIIIIlIlIIIl[jericofx_lIlIlIlI]=jericofx_IlllIlIIIIlIlIIIl[jericofx_lIlIlIlI](jericofx_lllIIIllI(jericofx_IlllIlIIIIlIlIIIl,jericofx_lIlIlIlI+1,jericofx_IIIIllIIIIIlIllIIlllll[3]))elseif jericofx_IIlIllIlllIIIIlllIlIlIIlI==4 then local jericofx_IIIIllIIIIIlIllIIlllll=jericofx_IIIIllIIIIIlIllIIlllll[2]jericofx_IlllIlIIIIlIlIIIl[jericofx_IIIIllIIIIIlIllIIlllll](jericofx_IlllIlIIIIlIlIIIl[jericofx_IIIIllIIIIIlIllIIlllll+1])else local jericofx_IIlIllIlllIIIIlllIlIlIIlI;jericofx_IlllIlIIIIlIlIIIl[jericofx_IIIIllIIIIIlIllIIlllll[2]]=jericofx_lIllIIlIlllll[jericofx_IIIIllIIIIIlIllIIlllll[3]];jericofx_lIlIlIlI=jericofx_lIlIlIlI+1;jericofx_IIIIllIIIIIlIllIIlllll=jericofx_lIlIlIIlIlIIllI[jericofx_lIlIlIlI];jericofx_IIlIllIlllIIIIlllIlIlIIlI=jericofx_IIIIllIIIIIlIllIIlllll[2]jericofx_IlllIlIIIIlIlIIIl[jericofx_IIlIllIlllIIIIlllIlIlIIlI]=jericofx_IlllIlIIIIlIlIIIl[jericofx_IIlIllIlllIIIIlllIlIlIIlI](jericofx_IlllIlIIIIlIlIIIl[jericofx_IIlIllIlllIIIIlllIlIlIIlI+1])jericofx_lIlIlIlI=jericofx_lIlIlIlI+1;jericofx_IIIIllIIIIIlIllIIlllll=jericofx_lIlIlIIlIlIIllI[jericofx_lIlIlIlI];jericofx_IlllIlIIIIlIlIIIl[jericofx_IIIIllIIIIIlIllIIlllll[2]]=jericofx_lIllIIlIlllll[jericofx_IIIIllIIIIIlIllIIlllll[3]];jericofx_lIlIlIlI=jericofx_lIlIlIlI+1;jericofx_IIIIllIIIIIlIllIIlllll=jericofx_lIlIlIIlIlIIllI[jericofx_lIlIlIlI];jericofx_IlllIlIIIIlIlIIIl[jericofx_IIIIllIIIIIlIllIIlllll[2]]=jericofx_IlllIlIIIIlIlIIIl[jericofx_IIIIllIIIIIlIllIIlllll[3]];jericofx_lIlIlIlI=jericofx_lIlIlIlI+1;jericofx_IIIIllIIIIIlIllIIlllll=jericofx_lIlIlIIlIlIIllI[jericofx_lIlIlIlI];jericofx_IIlIllIlllIIIIlllIlIlIIlI=jericofx_IIIIllIIIIIlIllIIlllll[2]jericofx_IlllIlIIIIlIlIIIl[jericofx_IIlIllIlllIIIIlllIlIlIIlI]=jericofx_IlllIlIIIIlIlIIIl[jericofx_IIlIllIlllIIIIlllIlIlIIlI](jericofx_IlllIlIIIIlIlIIIl[jericofx_IIlIllIlllIIIIlllIlIlIIlI+1])jericofx_lIlIlIlI=jericofx_lIlIlIlI+1;jericofx_IIIIllIIIIIlIllIIlllll=jericofx_lIlIlIIlIlIIllI[jericofx_lIlIlIlI];if(jericofx_IlllIlIIIIlIlIIIl[jericofx_IIIIllIIIIIlIllIIlllll[2]]<jericofx_IlllIlIIIIlIlIIIl[jericofx_IIIIllIIIIIlIllIIlllll[4]])then jericofx_lIlIlIlI=jericofx_lIlIlIlI+1;else jericofx_lIlIlIlI=jericofx_IIIIllIIIIIlIllIIlllll[3];end;end;elseif jericofx_IIlIllIlllIIIIlllIlIlIIlI<=8 then if jericofx_IIlIllIlllIIIIlllIlIlIIlI<=6 then jericofx_IlllIlIIIIlIlIIIl[jericofx_IIIIllIIIIIlIllIIlllll[2]]=jericofx_IllIIllllI(jericofx_IIlIllIlIIlII[jericofx_IIIIllIIIIIlIllIIlllll[3]],nil,jericofx_lIllIIlIlllll);elseif jericofx_IIlIllIlllIIIIlllIlIlIIlI>7 then local jericofx_lIlIlIlI=jericofx_IIIIllIIIIIlIllIIlllll[2]jericofx_IlllIlIIIIlIlIIIl[jericofx_lIlIlIlI]=jericofx_IlllIlIIIIlIlIIIl[jericofx_lIlIlIlI](jericofx_lllIIIllI(jericofx_IlllIlIIIIlIlIIIl,jericofx_lIlIlIlI+1,jericofx_IIIIllIIIIIlIllIIlllll[3]))else jericofx_IlllIlIIIIlIlIIIl[jericofx_IIIIllIIIIIlIllIIlllll[2]]=jericofx_IllIIllllI(jericofx_IIlIllIlIIlII[jericofx_IIIIllIIIIIlIllIIlllll[3]],nil,jericofx_lIllIIlIlllll);end;elseif jericofx_IIlIllIlllIIIIlllIlIlIIlI<=9 then jericofx_lIllIIlIlllll[jericofx_IIIIllIIIIIlIllIIlllll[3]]=jericofx_IlllIlIIIIlIlIIIl[jericofx_IIIIllIIIIIlIllIIlllll[2]];elseif jericofx_IIlIllIlllIIIIlllIlIlIIlI>10 then local jericofx_lIlIlIlI=jericofx_IIIIllIIIIIlIllIIlllll[2]jericofx_IlllIlIIIIlIlIIIl[jericofx_lIlIlIlI](jericofx_lllIIIllI(jericofx_IlllIlIIIIlIlIIIl,jericofx_lIlIlIlI+1,jericofx_IIIIllIIIIIlIllIIlllll[3]))else jericofx_lIllIIlIlllll[jericofx_IIIIllIIIIIlIllIIlllll[3]]=jericofx_IlllIlIIIIlIlIIIl[jericofx_IIIIllIIIIIlIllIIlllll[2]];end;elseif jericofx_IIlIllIlllIIIIlllIlIlIIlI<=17 then if jericofx_IIlIllIlllIIIIlllIlIlIIlI<=14 then if jericofx_IIlIllIlllIIIIlllIlIlIIlI<=12 then local jericofx_IllIIllllI;local jericofx_IIlIllIlllIIIIlllIlIlIIlI;jericofx_IlllIlIIIIlIlIIIl[jericofx_IIIIllIIIIIlIllIIlllll[2]]=jericofx_lIllIIlIlllll[jericofx_IIIIllIIIIIlIllIIlllll[3]];jericofx_lIlIlIlI=jericofx_lIlIlIlI+1;jericofx_IIIIllIIIIIlIllIIlllll=jericofx_lIlIlIIlIlIIllI[jericofx_lIlIlIlI];jericofx_IlllIlIIIIlIlIIIl[jericofx_IIIIllIIIIIlIllIIlllll[2]]=jericofx_IlllIlIIIIlIlIIIl[jericofx_IIIIllIIIIIlIllIIlllll[3]][jericofx_IIIIllIIIIIlIllIIlllll[4]];jericofx_lIlIlIlI=jericofx_lIlIlIlI+1;jericofx_IIIIllIIIIIlIllIIlllll=jericofx_lIlIlIIlIlIIllI[jericofx_lIlIlIlI];jericofx_IlllIlIIIIlIlIIIl[jericofx_IIIIllIIIIIlIllIIlllll[2]]=jericofx_IlllIlIIIIlIlIIIl[jericofx_IIIIllIIIIIlIllIIlllll[3]][jericofx_IIIIllIIIIIlIllIIlllll[4]];jericofx_lIlIlIlI=jericofx_lIlIlIlI+1;jericofx_IIIIllIIIIIlIllIIlllll=jericofx_lIlIlIIlIlIIllI[jericofx_lIlIlIlI];jericofx_IlllIlIIIIlIlIIIl[jericofx_IIIIllIIIIIlIllIIlllll[2]]=jericofx_lIllIIlIlllll[jericofx_IIIIllIIIIIlIllIIlllll[3]];jericofx_lIlIlIlI=jericofx_lIlIlIlI+1;jericofx_IIIIllIIIIIlIllIIlllll=jericofx_lIlIlIIlIlIIllI[jericofx_lIlIlIlI];jericofx_IIlIllIlllIIIIlllIlIlIIlI=jericofx_IIIIllIIIIIlIllIIlllll[2]jericofx_IlllIlIIIIlIlIIIl[jericofx_IIlIllIlllIIIIlllIlIlIIlI]=jericofx_IlllIlIIIIlIlIIIl[jericofx_IIlIllIlllIIIIlllIlIlIIlI](jericofx_IlllIlIIIIlIlIIIl[jericofx_IIlIllIlllIIIIlllIlIlIIlI+1])jericofx_lIlIlIlI=jericofx_lIlIlIlI+1;jericofx_IIIIllIIIIIlIllIIlllll=jericofx_lIlIlIIlIlIIllI[jericofx_lIlIlIlI];jericofx_IlllIlIIIIlIlIIIl[jericofx_IIIIllIIIIIlIllIIlllll[2]]=jericofx_lIllIIlIlllll[jericofx_IIIIllIIIIIlIllIIlllll[3]];jericofx_lIlIlIlI=jericofx_lIlIlIlI+1;jericofx_IIIIllIIIIIlIllIIlllll=jericofx_lIlIlIIlIlIIllI[jericofx_lIlIlIlI];jericofx_IlllIlIIIIlIlIIIl[jericofx_IIIIllIIIIIlIllIIlllll[2]]=jericofx_IlllIlIIIIlIlIIIl[jericofx_IIIIllIIIIIlIllIIlllll[3]][jericofx_IIIIllIIIIIlIllIIlllll[4]];jericofx_lIlIlIlI=jericofx_lIlIlIlI+1;jericofx_IIIIllIIIIIlIllIIlllll=jericofx_lIlIlIIlIlIIllI[jericofx_lIlIlIlI];jericofx_IlllIlIIIIlIlIIIl[jericofx_IIIIllIIIIIlIllIIlllll[2]]=jericofx_lIllIIlIlllll[jericofx_IIIIllIIIIIlIllIIlllll[3]];jericofx_lIlIlIlI=jericofx_lIlIlIlI+1;jericofx_IIIIllIIIIIlIllIIlllll=jericofx_lIlIlIIlIlIIllI[jericofx_lIlIlIlI];jericofx_IlllIlIIIIlIlIIIl[jericofx_IIIIllIIIIIlIllIIlllll[2]]=jericofx_IlllIlIIIIlIlIIIl[jericofx_IIIIllIIIIIlIllIIlllll[3]][jericofx_IIIIllIIIIIlIllIIlllll[4]];jericofx_lIlIlIlI=jericofx_lIlIlIlI+1;jericofx_IIIIllIIIIIlIllIIlllll=jericofx_lIlIlIIlIlIIllI[jericofx_lIlIlIlI];jericofx_IIlIllIlllIIIIlllIlIlIIlI=jericofx_IIIIllIIIIIlIllIIlllll[2]jericofx_IlllIlIIIIlIlIIIl[jericofx_IIlIllIlllIIIIlllIlIlIIlI]=jericofx_IlllIlIIIIlIlIIIl[jericofx_IIlIllIlllIIIIlllIlIlIIlI](jericofx_IlllIlIIIIlIlIIIl[jericofx_IIlIllIlllIIIIlllIlIlIIlI+1])jericofx_lIlIlIlI=jericofx_lIlIlIlI+1;jericofx_IIIIllIIIIIlIllIIlllll=jericofx_lIlIlIIlIlIIllI[jericofx_lIlIlIlI];jericofx_IlllIlIIIIlIlIIIl[jericofx_IIIIllIIIIIlIllIIlllll[2]]=jericofx_IlllIlIIIIlIlIIIl[jericofx_IIIIllIIIIIlIllIIlllll[3]][jericofx_IIIIllIIIIIlIllIIlllll[4]];jericofx_lIlIlIlI=jericofx_lIlIlIlI+1;jericofx_IIIIllIIIIIlIllIIlllll=jericofx_lIlIlIIlIlIIllI[jericofx_lIlIlIlI];jericofx_IlllIlIIIIlIlIIIl[jericofx_IIIIllIIIIIlIllIIlllll[2]]=jericofx_IlllIlIIIIlIlIIIl[jericofx_IIIIllIIIIIlIllIIlllll[3]][jericofx_IIIIllIIIIIlIllIIlllll[4]];jericofx_lIlIlIlI=jericofx_lIlIlIlI+1;jericofx_IIIIllIIIIIlIllIIlllll=jericofx_lIlIlIIlIlIIllI[jericofx_lIlIlIlI];jericofx_IlllIlIIIIlIlIIIl[jericofx_IIIIllIIIIIlIllIIlllll[2]]=jericofx_IIIIllIIIIIlIllIIlllll[3];jericofx_lIlIlIlI=jericofx_lIlIlIlI+1;jericofx_IIIIllIIIIIlIllIIlllll=jericofx_lIlIlIIlIlIIllI[jericofx_lIlIlIlI];jericofx_IlllIlIIIIlIlIIIl[jericofx_IIIIllIIIIIlIllIIlllll[2]]=jericofx_IlllIlIIIIlIlIIIl[jericofx_IIIIllIIIIIlIllIIlllll[3]];jericofx_lIlIlIlI=jericofx_lIlIlIlI+1;jericofx_IIIIllIIIIIlIllIIlllll=jericofx_lIlIlIIlIlIIllI[jericofx_lIlIlIlI];jericofx_IIlIllIlllIIIIlllIlIlIIlI=jericofx_IIIIllIIIIIlIllIIlllll[2]jericofx_IlllIlIIIIlIlIIIl[jericofx_IIlIllIlllIIIIlllIlIlIIlI](jericofx_lllIIIllI(jericofx_IlllIlIIIIlIlIIIl,jericofx_IIlIllIlllIIIIlllIlIlIIlI+1,jericofx_IIIIllIIIIIlIllIIlllll[3]))jericofx_lIlIlIlI=jericofx_lIlIlIlI+1;jericofx_IIIIllIIIIIlIllIIlllll=jericofx_lIlIlIIlIlIIllI[jericofx_lIlIlIlI];jericofx_IlllIlIIIIlIlIIIl[jericofx_IIIIllIIIIIlIllIIlllll[2]]=jericofx_lIllIIlIlllll[jericofx_IIIIllIIIIIlIllIIlllll[3]];jericofx_lIlIlIlI=jericofx_lIlIlIlI+1;jericofx_IIIIllIIIIIlIllIIlllll=jericofx_lIlIlIIlIlIIllI[jericofx_lIlIlIlI];jericofx_IlllIlIIIIlIlIIIl[jericofx_IIIIllIIIIIlIllIIlllll[2]]=jericofx_IIIIllIIIIIlIllIIlllll[3];jericofx_lIlIlIlI=jericofx_lIlIlIlI+1;jericofx_IIIIllIIIIIlIllIIlllll=jericofx_lIlIlIIlIlIIllI[jericofx_lIlIlIlI];jericofx_IlllIlIIIIlIlIIIl[jericofx_IIIIllIIIIIlIllIIlllll[2]]=jericofx_IlllIlIIIIlIlIIIl[jericofx_IIIIllIIIIIlIllIIlllll[3]][jericofx_IIIIllIIIIIlIllIIlllll[4]];jericofx_lIlIlIlI=jericofx_lIlIlIlI+1;jericofx_IIIIllIIIIIlIllIIlllll=jericofx_lIlIlIIlIlIIllI[jericofx_lIlIlIlI];jericofx_IlllIlIIIIlIlIIIl[jericofx_IIIIllIIIIIlIllIIlllll[2]]=jericofx_IlllIlIIIIlIlIIIl[jericofx_IIIIllIIIIIlIllIIlllll[3]][jericofx_IIIIllIIIIIlIllIIlllll[4]];jericofx_lIlIlIlI=jericofx_lIlIlIlI+1;jericofx_IIIIllIIIIIlIllIIlllll=jericofx_lIlIlIIlIlIIllI[jericofx_lIlIlIlI];jericofx_IlllIlIIIIlIlIIIl[jericofx_IIIIllIIIIIlIllIIlllll[2]]=jericofx_lIllIIlIlllll[jericofx_IIIIllIIIIIlIllIIlllll[3]];jericofx_lIlIlIlI=jericofx_lIlIlIlI+1;jericofx_IIIIllIIIIIlIllIIlllll=jericofx_lIlIlIIlIlIIllI[jericofx_lIlIlIlI];jericofx_IlllIlIIIIlIlIIIl[jericofx_IIIIllIIIIIlIllIIlllll[2]]=jericofx_IlllIlIIIIlIlIIIl[jericofx_IIIIllIIIIIlIllIIlllll[3]][jericofx_IIIIllIIIIIlIllIIlllll[4]];jericofx_lIlIlIlI=jericofx_lIlIlIlI+1;jericofx_IIIIllIIIIIlIllIIlllll=jericofx_lIlIlIIlIlIIllI[jericofx_lIlIlIlI];jericofx_IIlIllIlllIIIIlllIlIlIIlI=jericofx_IIIIllIIIIIlIllIIlllll[2];jericofx_IllIIllllI=jericofx_IlllIlIIIIlIlIIIl[jericofx_IIIIllIIIIIlIllIIlllll[3]];jericofx_IlllIlIIIIlIlIIIl[jericofx_IIlIllIlllIIIIlllIlIlIIlI+1]=jericofx_IllIIllllI;jericofx_IlllIlIIIIlIlIIIl[jericofx_IIlIllIlllIIIIlllIlIlIIlI]=jericofx_IllIIllllI[jericofx_IIIIllIIIIIlIllIIlllll[4]];jericofx_lIlIlIlI=jericofx_lIlIlIlI+1;jericofx_IIIIllIIIIIlIllIIlllll=jericofx_lIlIlIIlIlIIllI[jericofx_lIlIlIlI];jericofx_IlllIlIIIIlIlIIIl[jericofx_IIIIllIIIIIlIllIIlllll[2]]=jericofx_IlllIlIIIIlIlIIIl[jericofx_IIIIllIIIIIlIllIIlllll[3]];jericofx_lIlIlIlI=jericofx_lIlIlIlI+1;jericofx_IIIIllIIIIIlIllIIlllll=jericofx_lIlIlIIlIlIIllI[jericofx_lIlIlIlI];jericofx_IIlIllIlllIIIIlllIlIlIIlI=jericofx_IIIIllIIIIIlIllIIlllll[2]jericofx_IlllIlIIIIlIlIIIl[jericofx_IIlIllIlllIIIIlllIlIlIIlI]=jericofx_IlllIlIIIIlIlIIIl[jericofx_IIlIllIlllIIIIlllIlIlIIlI](jericofx_lllIIIllI(jericofx_IlllIlIIIIlIlIIIl,jericofx_IIlIllIlllIIIIlllIlIlIIlI+1,jericofx_IIIIllIIIIIlIllIIlllll[3]))jericofx_lIlIlIlI=jericofx_lIlIlIlI+1;jericofx_IIIIllIIIIIlIllIIlllll=jericofx_lIlIlIIlIlIIllI[jericofx_lIlIlIlI];jericofx_IIlIllIlllIIIIlllIlIlIIlI=jericofx_IIIIllIIIIIlIllIIlllll[2]jericofx_IlllIlIIIIlIlIIIl[jericofx_IIlIllIlllIIIIlllIlIlIIlI](jericofx_lllIIIllI(jericofx_IlllIlIIIIlIlIIIl,jericofx_IIlIllIlllIIIIlllIlIlIIlI+1,jericofx_IIIIllIIIIIlIllIIlllll[3]))jericofx_lIlIlIlI=jericofx_lIlIlIlI+1;jericofx_IIIIllIIIIIlIllIIlllll=jericofx_lIlIlIIlIlIIllI[jericofx_lIlIlIlI];do return end;elseif jericofx_IIlIllIlllIIIIlllIlIlIIlI>13 then local jericofx_lllIIIllI;local jericofx_IllIIllllI;local jericofx_IIlIllIlllIIIIlllIlIlIIlI;jericofx_IlllIlIIIIlIlIIIl[jericofx_IIIIllIIIIIlIllIIlllll[2]]=jericofx_IIIIllIIIIIlIllIIlllll[3];jericofx_lIlIlIlI=jericofx_lIlIlIlI+1;jericofx_IIIIllIIIIIlIllIIlllll=jericofx_lIlIlIIlIlIIllI[jericofx_lIlIlIlI];jericofx_IIlIllIlllIIIIlllIlIlIIlI=jericofx_IIIIllIIIIIlIllIIlllll[2]jericofx_IlllIlIIIIlIlIIIl[jericofx_IIlIllIlllIIIIlllIlIlIIlI](jericofx_IlllIlIIIIlIlIIIl[jericofx_IIlIllIlllIIIIlllIlIlIIlI+1])jericofx_lIlIlIlI=jericofx_lIlIlIlI+1;jericofx_IIIIllIIIIIlIllIIlllll=jericofx_lIlIlIIlIlIIllI[jericofx_lIlIlIlI];jericofx_IlllIlIIIIlIlIIIl[jericofx_IIIIllIIIIIlIllIIlllll[2]]=jericofx_lIllIIlIlllll[jericofx_IIIIllIIIIIlIllIIlllll[3]];jericofx_lIlIlIlI=jericofx_lIlIlIlI+1;jericofx_IIIIllIIIIIlIllIIlllll=jericofx_lIlIlIIlIlIIllI[jericofx_lIlIlIlI];jericofx_IlllIlIIIIlIlIIIl[jericofx_IIIIllIIIIIlIllIIlllll[2]]=jericofx_IIIIllIIIIIlIllIIlllll[3];jericofx_lIlIlIlI=jericofx_lIlIlIlI+1;jericofx_IIIIllIIIIIlIllIIlllll=jericofx_lIlIlIIlIlIIllI[jericofx_lIlIlIlI];jericofx_IlllIlIIIIlIlIIIl[jericofx_IIIIllIIIIIlIllIIlllll[2]]=jericofx_lIllIIlIlllll[jericofx_IIIIllIIIIIlIllIIlllll[3]];jericofx_lIlIlIlI=jericofx_lIlIlIlI+1;jericofx_IIIIllIIIIIlIllIIlllll=jericofx_lIlIlIIlIlIIllI[jericofx_lIlIlIlI];jericofx_IlllIlIIIIlIlIIIl[jericofx_IIIIllIIIIIlIllIIlllll[2]]=jericofx_IIIIllIIIIIlIllIIlllll[3];jericofx_lIlIlIlI=jericofx_lIlIlIlI+1;jericofx_IIIIllIIIIIlIllIIlllll=jericofx_lIlIlIIlIlIIllI[jericofx_lIlIlIlI];jericofx_IlllIlIIIIlIlIIIl[jericofx_IIIIllIIIIIlIllIIlllll[2]]=jericofx_IlllIlIIIIlIlIIIl[jericofx_IIIIllIIIIIlIllIIlllll[3]];jericofx_lIlIlIlI=jericofx_lIlIlIlI+1;jericofx_IIIIllIIIIIlIllIIlllll=jericofx_lIlIlIIlIlIIllI[jericofx_lIlIlIlI];jericofx_IlllIlIIIIlIlIIIl[jericofx_IIIIllIIIIIlIllIIlllll[2]]=jericofx_IIIIllIIIIIlIllIIlllll[3];jericofx_lIlIlIlI=jericofx_lIlIlIlI+1;jericofx_IIIIllIIIIIlIllIIlllll=jericofx_lIlIlIIlIlIIllI[jericofx_lIlIlIlI];jericofx_IlllIlIIIIlIlIIIl[jericofx_IIIIllIIIIIlIllIIlllll[2]]=jericofx_lIllIIlIlllll[jericofx_IIIIllIIIIIlIllIIlllll[3]];jericofx_lIlIlIlI=jericofx_lIlIlIlI+1;jericofx_IIIIllIIIIIlIllIIlllll=jericofx_lIlIlIIlIlIIllI[jericofx_lIlIlIlI];jericofx_IlllIlIIIIlIlIIIl[jericofx_IIIIllIIIIIlIllIIlllll[2]]=jericofx_IIIIllIIIIIlIllIIlllll[3];jericofx_lIlIlIlI=jericofx_lIlIlIlI+1;jericofx_IIIIllIIIIIlIllIIlllll=jericofx_lIlIlIIlIlIIllI[jericofx_lIlIlIlI];jericofx_IlllIlIIIIlIlIIIl[jericofx_IIIIllIIIIIlIllIIlllll[2]]=jericofx_lIllIIlIlllll[jericofx_IIIIllIIIIIlIllIIlllll[3]];jericofx_lIlIlIlI=jericofx_lIlIlIlI+1;jericofx_IIIIllIIIIIlIllIIlllll=jericofx_lIlIlIIlIlIIllI[jericofx_lIlIlIlI];jericofx_IlllIlIIIIlIlIIIl[jericofx_IIIIllIIIIIlIllIIlllll[2]]=jericofx_IIIIllIIIIIlIllIIlllll[3];jericofx_lIlIlIlI=jericofx_lIlIlIlI+1;jericofx_IIIIllIIIIIlIllIIlllll=jericofx_lIlIlIIlIlIIllI[jericofx_lIlIlIlI];jericofx_IllIIllllI=jericofx_IIIIllIIIIIlIllIIlllll[3];jericofx_lllIIIllI=jericofx_IlllIlIIIIlIlIIIl[jericofx_IllIIllllI]for jericofx_IIIIllIIIIIlIllIIlllll=jericofx_IllIIllllI+1,jericofx_IIIIllIIIIIlIllIIlllll[4]do jericofx_lllIIIllI=jericofx_lllIIIllI..jericofx_IlllIlIIIIlIlIIIl[jericofx_IIIIllIIIIIlIllIIlllll];end;jericofx_IlllIlIIIIlIlIIIl[jericofx_IIIIllIIIIIlIllIIlllll[2]]=jericofx_lllIIIllI;jericofx_lIlIlIlI=jericofx_lIlIlIlI+1;jericofx_IIIIllIIIIIlIllIIlllll=jericofx_lIlIlIIlIlIIllI[jericofx_lIlIlIlI];jericofx_IIlIllIlllIIIIlllIlIlIIlI=jericofx_IIIIllIIIIIlIllIIlllll[2]jericofx_IlllIlIIIIlIlIIIl[jericofx_IIlIllIlllIIIIlllIlIlIIlI](jericofx_IlllIlIIIIlIlIIIl[jericofx_IIlIllIlllIIIIlllIlIlIIlI+1])jericofx_lIlIlIlI=jericofx_lIlIlIlI+1;jericofx_IIIIllIIIIIlIllIIlllll=jericofx_lIlIlIIlIlIIllI[jericofx_lIlIlIlI];jericofx_IlllIlIIIIlIlIIIl[jericofx_IIIIllIIIIIlIllIIlllll[2]]=jericofx_lIllIIlIlllll[jericofx_IIIIllIIIIIlIllIIlllll[3]];jericofx_lIlIlIlI=jericofx_lIlIlIlI+1;jericofx_IIIIllIIIIIlIllIIlllll=jericofx_lIlIlIIlIlIIllI[jericofx_lIlIlIlI];jericofx_IlllIlIIIIlIlIIIl[jericofx_IIIIllIIIIIlIllIIlllll[2]]=jericofx_IIIIllIIIIIlIllIIlllll[3];jericofx_lIlIlIlI=jericofx_lIlIlIlI+1;jericofx_IIIIllIIIIIlIllIIlllll=jericofx_lIlIlIIlIlIIllI[jericofx_lIlIlIlI];jericofx_IIlIllIlllIIIIlllIlIlIIlI=jericofx_IIIIllIIIIIlIllIIlllll[2]jericofx_IlllIlIIIIlIlIIIl[jericofx_IIlIllIlllIIIIlllIlIlIIlI](jericofx_IlllIlIIIIlIlIIIl[jericofx_IIlIllIlllIIIIlllIlIlIIlI+1])jericofx_lIlIlIlI=jericofx_lIlIlIlI+1;jericofx_IIIIllIIIIIlIllIIlllll=jericofx_lIlIlIIlIlIIllI[jericofx_lIlIlIlI];jericofx_lIlIlIlI=jericofx_IIIIllIIIIIlIllIIlllll[3];else local jericofx_lIlIlIIlIlIIllI=jericofx_IIIIllIIIIIlIllIIlllll[3];local jericofx_lIlIlIlI=jericofx_IlllIlIIIIlIlIIIl[jericofx_lIlIlIIlIlIIllI]for jericofx_IIIIllIIIIIlIllIIlllll=jericofx_lIlIlIIlIlIIllI+1,jericofx_IIIIllIIIIIlIllIIlllll[4]do jericofx_lIlIlIlI=jericofx_lIlIlIlI..jericofx_IlllIlIIIIlIlIIIl[jericofx_IIIIllIIIIIlIllIIlllll];end;jericofx_IlllIlIIIIlIlIIIl[jericofx_IIIIllIIIIIlIllIIlllll[2]]=jericofx_lIlIlIlI;end;elseif jericofx_IIlIllIlllIIIIlllIlIlIIlI<=15 then local jericofx_lllIIIllI;local jericofx_IIlIllIlllIIIIlllIlIlIIlI;local jericofx_IllIIllllI;jericofx_IlllIlIIIIlIlIIIl[jericofx_IIIIllIIIIIlIllIIlllll[2]]=jericofx_IIIIllIIIIIlIllIIlllll[3];jericofx_lIlIlIlI=jericofx_lIlIlIlI+1;jericofx_IIIIllIIIIIlIllIIlllll=jericofx_lIlIlIIlIlIIllI[jericofx_lIlIlIlI];jericofx_IlllIlIIIIlIlIIIl[jericofx_IIIIllIIIIIlIllIIlllll[2]]=jericofx_lIllIIlIlllll[jericofx_IIIIllIIIIIlIllIIlllll[3]];jericofx_lIlIlIlI=jericofx_lIlIlIlI+1;jericofx_IIIIllIIIIIlIllIIlllll=jericofx_lIlIlIIlIlIIllI[jericofx_lIlIlIlI];jericofx_IlllIlIIIIlIlIIIl[jericofx_IIIIllIIIIIlIllIIlllll[2]]=jericofx_IIIIllIIIIIlIllIIlllll[3];jericofx_lIlIlIlI=jericofx_lIlIlIlI+1;jericofx_IIIIllIIIIIlIllIIlllll=jericofx_lIlIlIIlIlIIllI[jericofx_lIlIlIlI];jericofx_IllIIllllI=jericofx_IIIIllIIIIIlIllIIlllll[3];jericofx_IIlIllIlllIIIIlllIlIlIIlI=jericofx_IlllIlIIIIlIlIIIl[jericofx_IllIIllllI]for jericofx_IIIIllIIIIIlIllIIlllll=jericofx_IllIIllllI+1,jericofx_IIIIllIIIIIlIllIIlllll[4]do jericofx_IIlIllIlllIIIIlllIlIlIIlI=jericofx_IIlIllIlllIIIIlllIlIlIIlI..jericofx_IlllIlIIIIlIlIIIl[jericofx_IIIIllIIIIIlIllIIlllll];end;jericofx_IlllIlIIIIlIlIIIl[jericofx_IIIIllIIIIIlIllIIlllll[2]]=jericofx_IIlIllIlllIIIIlllIlIlIIlI;jericofx_lIlIlIlI=jericofx_lIlIlIlI+1;jericofx_IIIIllIIIIIlIllIIlllll=jericofx_lIlIlIIlIlIIllI[jericofx_lIlIlIlI];jericofx_lllIIIllI=jericofx_IIIIllIIIIIlIllIIlllll[2]jericofx_IlllIlIIIIlIlIIIl[jericofx_lllIIIllI](jericofx_IlllIlIIIIlIlIIIl[jericofx_lllIIIllI+1])elseif jericofx_IIlIllIlllIIIIlllIlIlIIlI==16 then jericofx_IlllIlIIIIlIlIIIl[jericofx_IIIIllIIIIIlIllIIlllll[2]]=jericofx_lIllIIlIlllll[jericofx_IIIIllIIIIIlIllIIlllll[3]];else if(jericofx_IlllIlIIIIlIlIIIl[jericofx_IIIIllIIIIIlIllIIlllll[2]]<jericofx_IlllIlIIIIlIlIIIl[jericofx_IIIIllIIIIIlIllIIlllll[4]])then jericofx_lIlIlIlI=jericofx_lIlIlIlI+1;else jericofx_lIlIlIlI=jericofx_IIIIllIIIIIlIllIIlllll[3];end;end;elseif jericofx_IIlIllIlllIIIIlllIlIlIIlI<=20 then if jericofx_IIlIllIlllIIIIlllIlIlIIlI<=18 then local jericofx_IIlIllIlllIIIIlllIlIlIIlI;jericofx_IIlIllIlllIIIIlllIlIlIIlI=jericofx_IIIIllIIIIIlIllIIlllll[2]jericofx_IlllIlIIIIlIlIIIl[jericofx_IIlIllIlllIIIIlllIlIlIIlI](jericofx_IlllIlIIIIlIlIIIl[jericofx_IIlIllIlllIIIIlllIlIlIIlI+1])jericofx_lIlIlIlI=jericofx_lIlIlIlI+1;jericofx_IIIIllIIIIIlIllIIlllll=jericofx_lIlIlIIlIlIIllI[jericofx_lIlIlIlI];jericofx_IlllIlIIIIlIlIIIl[jericofx_IIIIllIIIIIlIllIIlllll[2]]=jericofx_lIllIIlIlllll[jericofx_IIIIllIIIIIlIllIIlllll[3]];jericofx_lIlIlIlI=jericofx_lIlIlIlI+1;jericofx_IIIIllIIIIIlIllIIlllll=jericofx_lIlIlIIlIlIIllI[jericofx_lIlIlIlI];jericofx_IlllIlIIIIlIlIIIl[jericofx_IIIIllIIIIIlIllIIlllll[2]]=jericofx_IIIIllIIIIIlIllIIlllll[3];jericofx_lIlIlIlI=jericofx_lIlIlIlI+1;jericofx_IIIIllIIIIIlIllIIlllll=jericofx_lIlIlIIlIlIIllI[jericofx_lIlIlIlI];jericofx_IIlIllIlllIIIIlllIlIlIIlI=jericofx_IIIIllIIIIIlIllIIlllll[2]jericofx_IlllIlIIIIlIlIIIl[jericofx_IIlIllIlllIIIIlllIlIlIIlI](jericofx_IlllIlIIIIlIlIIIl[jericofx_IIlIllIlllIIIIlllIlIlIIlI+1])jericofx_lIlIlIlI=jericofx_lIlIlIlI+1;jericofx_IIIIllIIIIIlIllIIlllll=jericofx_lIlIlIIlIlIIllI[jericofx_lIlIlIlI];jericofx_IlllIlIIIIlIlIIIl[jericofx_IIIIllIIIIIlIllIIlllll[2]]=jericofx_lIllIIlIlllll[jericofx_IIIIllIIIIIlIllIIlllll[3]];jericofx_lIlIlIlI=jericofx_lIlIlIlI+1;jericofx_IIIIllIIIIIlIllIIlllll=jericofx_lIlIlIIlIlIIllI[jericofx_lIlIlIlI];jericofx_IlllIlIIIIlIlIIIl[jericofx_IIIIllIIIIIlIllIIlllll[2]]=jericofx_IIIIllIIIIIlIllIIlllll[3];elseif jericofx_IIlIllIlllIIIIlllIlIlIIlI==19 then jericofx_IlllIlIIIIlIlIIIl[jericofx_IIIIllIIIIIlIllIIlllll[2]]=jericofx_IlllIlIIIIlIlIIIl[jericofx_IIIIllIIIIIlIllIIlllll[3]][jericofx_IIIIllIIIIIlIllIIlllll[4]];else local jericofx_lIlIlIlI=jericofx_IIIIllIIIIIlIllIIlllll[2];local jericofx_lIlIlIIlIlIIllI=jericofx_IlllIlIIIIlIlIIIl[jericofx_IIIIllIIIIIlIllIIlllll[3]];jericofx_IlllIlIIIIlIlIIIl[jericofx_lIlIlIlI+1]=jericofx_lIlIlIIlIlIIllI;jericofx_IlllIlIIIIlIlIIIl[jericofx_lIlIlIlI]=jericofx_lIlIlIIlIlIIllI[jericofx_IIIIllIIIIIlIllIIlllll[4]];end;elseif jericofx_IIlIllIlllIIIIlllIlIlIIlI<=22 then if jericofx_IIlIllIlllIIIIlllIlIlIIlI>21 then local jericofx_IIlIllIlllIIIIlllIlIlIIlI;jericofx_IlllIlIIIIlIlIIIl[jericofx_IIIIllIIIIIlIllIIlllll[2]]=jericofx_lIllIIlIlllll[jericofx_IIIIllIIIIIlIllIIlllll[3]];jericofx_lIlIlIlI=jericofx_lIlIlIlI+1;jericofx_IIIIllIIIIIlIllIIlllll=jericofx_lIlIlIIlIlIIllI[jericofx_lIlIlIlI];jericofx_IlllIlIIIIlIlIIIl[jericofx_IIIIllIIIIIlIllIIlllll[2]]=jericofx_IIIIllIIIIIlIllIIlllll[3];jericofx_lIlIlIlI=jericofx_lIlIlIlI+1;jericofx_IIIIllIIIIIlIllIIlllll=jericofx_lIlIlIIlIlIIllI[jericofx_lIlIlIlI];jericofx_IlllIlIIIIlIlIIIl[jericofx_IIIIllIIIIIlIllIIlllll[2]]=jericofx_IlllIlIIIIlIlIIIl[jericofx_IIIIllIIIIIlIllIIlllll[3]];jericofx_lIlIlIlI=jericofx_lIlIlIlI+1;jericofx_IIIIllIIIIIlIllIIlllll=jericofx_lIlIlIIlIlIIllI[jericofx_lIlIlIlI];jericofx_IIlIllIlllIIIIlllIlIlIIlI=jericofx_IIIIllIIIIIlIllIIlllll[2]jericofx_IlllIlIIIIlIlIIIl[jericofx_IIlIllIlllIIIIlllIlIlIIlI](jericofx_lllIIIllI(jericofx_IlllIlIIIIlIlIIIl,jericofx_IIlIllIlllIIIIlllIlIlIIlI+1,jericofx_IIIIllIIIIIlIllIIlllll[3]))jericofx_lIlIlIlI=jericofx_lIlIlIlI+1;jericofx_IIIIllIIIIIlIllIIlllll=jericofx_lIlIlIIlIlIIllI[jericofx_lIlIlIlI];do return end;else local jericofx_IIIIllIIIIIlIllIIlllll=jericofx_IIIIllIIIIIlIllIIlllll[2]jericofx_IlllIlIIIIlIlIIIl[jericofx_IIIIllIIIIIlIllIIlllll]=jericofx_IlllIlIIIIlIlIIIl[jericofx_IIIIllIIIIIlIllIIlllll](jericofx_IlllIlIIIIlIlIIIl[jericofx_IIIIllIIIIIlIllIIlllll+1])end;elseif jericofx_IIlIllIlllIIIIlllIlIlIIlI>23 then jericofx_lIlIlIlI=jericofx_IIIIllIIIIIlIllIIlllll[3];else jericofx_IlllIlIIIIlIlIIIl[jericofx_IIIIllIIIIIlIllIIlllll[2]]=jericofx_IlllIlIIIIlIlIIIl[jericofx_IIIIllIIIIIlIllIIlllll[3]][jericofx_IIIIllIIIIIlIllIIlllll[4]];end;elseif jericofx_IIlIllIlllIIIIlllIlIlIIlI<=37 then if jericofx_IIlIllIlllIIIIlllIlIlIIlI<=30 then if jericofx_IIlIllIlllIIIIlllIlIlIIlI<=27 then if jericofx_IIlIllIlllIIIIlllIlIlIIlI<=25 then local jericofx_IIIIllIIIIIlIllIIlllll=jericofx_IIIIllIIIIIlIllIIlllll[2]jericofx_IlllIlIIIIlIlIIIl[jericofx_IIIIllIIIIIlIllIIlllll]=jericofx_IlllIlIIIIlIlIIIl[jericofx_IIIIllIIIIIlIllIIlllll]()elseif jericofx_IIlIllIlllIIIIlllIlIlIIlI>26 then jericofx_IlllIlIIIIlIlIIIl[jericofx_IIIIllIIIIIlIllIIlllll[2]]=(jericofx_IIIIllIIIIIlIllIIlllll[3]~=0);else if(jericofx_IlllIlIIIIlIlIIIl[jericofx_IIIIllIIIIIlIllIIlllll[2]]~=jericofx_IlllIlIIIIlIlIIIl[jericofx_IIIIllIIIIIlIllIIlllll[4]])then jericofx_lIlIlIlI=jericofx_lIlIlIlI+1;else jericofx_lIlIlIlI=jericofx_IIIIllIIIIIlIllIIlllll[3];end;end;elseif jericofx_IIlIllIlllIIIIlllIlIlIIlI<=28 then local jericofx_IIIIllIIIIIlIllIIlllll=jericofx_IIIIllIIIIIlIllIIlllll[2]jericofx_IlllIlIIIIlIlIIIl[jericofx_IIIIllIIIIIlIllIIlllll]=jericofx_IlllIlIIIIlIlIIIl[jericofx_IIIIllIIIIIlIllIIlllll](jericofx_IlllIlIIIIlIlIIIl[jericofx_IIIIllIIIIIlIllIIlllll+1])elseif jericofx_IIlIllIlllIIIIlllIlIlIIlI>29 then jericofx_lIlIlIlI=jericofx_IIIIllIIIIIlIllIIlllll[3];else jericofx_IlllIlIIIIlIlIIIl[jericofx_IIIIllIIIIIlIllIIlllll[2]]={};end;elseif jericofx_IIlIllIlllIIIIlllIlIlIIlI<=33 then if jericofx_IIlIllIlllIIIIlllIlIlIIlI<=31 then jericofx_IlllIlIIIIlIlIIIl[jericofx_IIIIllIIIIIlIllIIlllll[2]]=jericofx_lIllIIlIlllll[jericofx_IIIIllIIIIIlIllIIlllll[3]];elseif jericofx_IIlIllIlllIIIIlllIlIlIIlI==32 then local jericofx_IIIIllIIIIIlIllIIlllll=jericofx_IIIIllIIIIIlIllIIlllll[2]jericofx_IlllIlIIIIlIlIIIl[jericofx_IIIIllIIIIIlIllIIlllll]=jericofx_IlllIlIIIIlIlIIIl[jericofx_IIIIllIIIIIlIllIIlllll]()else jericofx_IlllIlIIIIlIlIIIl[jericofx_IIIIllIIIIIlIllIIlllll[2]]=(jericofx_IIIIllIIIIIlIllIIlllll[3]~=0);end;elseif jericofx_IIlIllIlllIIIIlllIlIlIIlI<=35 then if jericofx_IIlIllIlllIIIIlllIlIlIIlI>34 then jericofx_IlllIlIIIIlIlIIIl[jericofx_IIIIllIIIIIlIllIIlllll[2]]=jericofx_lIllIIlIlllll[jericofx_IIIIllIIIIIlIllIIlllll[3]];jericofx_lIlIlIlI=jericofx_lIlIlIlI+1;jericofx_IIIIllIIIIIlIllIIlllll=jericofx_lIlIlIIlIlIIllI[jericofx_lIlIlIlI];jericofx_IlllIlIIIIlIlIIIl[jericofx_IIIIllIIIIIlIllIIlllll[2]]=jericofx_IlllIlIIIIlIlIIIl[jericofx_IIIIllIIIIIlIllIIlllll[3]][jericofx_IIIIllIIIIIlIllIIlllll[4]];jericofx_lIlIlIlI=jericofx_lIlIlIlI+1;jericofx_IIIIllIIIIIlIllIIlllll=jericofx_lIlIlIIlIlIIllI[jericofx_lIlIlIlI];jericofx_IlllIlIIIIlIlIIIl[jericofx_IIIIllIIIIIlIllIIlllll[2]]=jericofx_IlllIlIIIIlIlIIIl[jericofx_IIIIllIIIIIlIllIIlllll[3]][jericofx_IIIIllIIIIIlIllIIlllll[4]];jericofx_lIlIlIlI=jericofx_lIlIlIlI+1;jericofx_IIIIllIIIIIlIllIIlllll=jericofx_lIlIlIIlIlIIllI[jericofx_lIlIlIlI];jericofx_IlllIlIIIIlIlIIIl[jericofx_IIIIllIIIIIlIllIIlllll[2]]=jericofx_IIIIllIIIIIlIllIIlllll[3];jericofx_lIlIlIlI=jericofx_lIlIlIlI+1;jericofx_IIIIllIIIIIlIllIIlllll=jericofx_lIlIlIIlIlIIllI[jericofx_lIlIlIlI];jericofx_IlllIlIIIIlIlIIIl[jericofx_IIIIllIIIIIlIllIIlllll[2]]=jericofx_IIIIllIIIIIlIllIIlllll[3];jericofx_lIlIlIlI=jericofx_lIlIlIlI+1;jericofx_IIIIllIIIIIlIllIIlllll=jericofx_lIlIlIIlIlIIllI[jericofx_lIlIlIlI];jericofx_IlllIlIIIIlIlIIIl[jericofx_IIIIllIIIIIlIllIIlllll[2]]={};jericofx_lIlIlIlI=jericofx_lIlIlIlI+1;jericofx_IIIIllIIIIIlIllIIlllll=jericofx_lIlIlIIlIlIIllI[jericofx_lIlIlIlI];jericofx_IlllIlIIIIlIlIIIl[jericofx_IIIIllIIIIIlIllIIlllll[2]]=(jericofx_IIIIllIIIIIlIllIIlllll[3]~=0);else local jericofx_IIlIllIlllIIIIlllIlIlIIlI;jericofx_IIlIllIlllIIIIlllIlIlIIlI=jericofx_IIIIllIIIIIlIllIIlllll[2]jericofx_IlllIlIIIIlIlIIIl[jericofx_IIlIllIlllIIIIlllIlIlIIlI](jericofx_lllIIIllI(jericofx_IlllIlIIIIlIlIIIl,jericofx_IIlIllIlllIIIIlllIlIlIIlI+1,jericofx_IIIIllIIIIIlIllIIlllll[3]))jericofx_lIlIlIlI=jericofx_lIlIlIlI+1;jericofx_IIIIllIIIIIlIllIIlllll=jericofx_lIlIlIIlIlIIllI[jericofx_lIlIlIlI];jericofx_IlllIlIIIIlIlIIIl[jericofx_IIIIllIIIIIlIllIIlllll[2]]=jericofx_IIIIllIIIIIlIllIIlllll[3];jericofx_lIlIlIlI=jericofx_lIlIlIlI+1;jericofx_IIIIllIIIIIlIllIIlllll=jericofx_lIlIlIIlIlIIllI[jericofx_lIlIlIlI];jericofx_IlllIlIIIIlIlIIIl[jericofx_IIIIllIIIIIlIllIIlllll[2]]=jericofx_lIllIIlIlllll[jericofx_IIIIllIIIIIlIllIIlllll[3]];jericofx_lIlIlIlI=jericofx_lIlIlIlI+1;jericofx_IIIIllIIIIIlIllIIlllll=jericofx_lIlIlIIlIlIIllI[jericofx_lIlIlIlI];jericofx_IlllIlIIIIlIlIIIl[jericofx_IIIIllIIIIIlIllIIlllll[2]]=jericofx_IlllIlIIIIlIlIIIl[jericofx_IIIIllIIIIIlIllIIlllll[3]];jericofx_lIlIlIlI=jericofx_lIlIlIlI+1;jericofx_IIIIllIIIIIlIllIIlllll=jericofx_lIlIlIIlIlIIllI[jericofx_lIlIlIlI];jericofx_IIlIllIlllIIIIlllIlIlIIlI=jericofx_IIIIllIIIIIlIllIIlllll[2]jericofx_IlllIlIIIIlIlIIIl[jericofx_IIlIllIlllIIIIlllIlIlIIlI](jericofx_IlllIlIIIIlIlIIIl[jericofx_IIlIllIlllIIIIlllIlIlIIlI+1])jericofx_lIlIlIlI=jericofx_lIlIlIlI+1;jericofx_IIIIllIIIIIlIllIIlllll=jericofx_lIlIlIIlIlIIllI[jericofx_lIlIlIlI];do return end;end;elseif jericofx_IIlIllIlllIIIIlllIlIlIIlI>36 then do return end;else if(jericofx_IlllIlIIIIlIlIIIl[jericofx_IIIIllIIIIIlIllIIlllll[2]]~=jericofx_IlllIlIIIIlIlIIIl[jericofx_IIIIllIIIIIlIllIIlllll[4]])then jericofx_lIlIlIlI=jericofx_lIlIlIlI+1;else jericofx_lIlIlIlI=jericofx_IIIIllIIIIIlIllIIlllll[3];end;end;elseif jericofx_IIlIllIlllIIIIlllIlIlIIlI<=43 then if jericofx_IIlIllIlllIIIIlllIlIlIIlI<=40 then if jericofx_IIlIllIlllIIIIlllIlIlIIlI<=38 then local jericofx_IIIIllIIIIIlIllIIlllll=jericofx_IIIIllIIIIIlIllIIlllll[2]jericofx_IlllIlIIIIlIlIIIl[jericofx_IIIIllIIIIIlIllIIlllll](jericofx_IlllIlIIIIlIlIIIl[jericofx_IIIIllIIIIIlIllIIlllll+1])elseif jericofx_IIlIllIlllIIIIlllIlIlIIlI==39 then jericofx_IlllIlIIIIlIlIIIl[jericofx_IIIIllIIIIIlIllIIlllll[2]]=jericofx_IlllIlIIIIlIlIIIl[jericofx_IIIIllIIIIIlIllIIlllll[3]];else local jericofx_IIlIllIlllIIIIlllIlIlIIlI;jericofx_IlllIlIIIIlIlIIIl[jericofx_IIIIllIIIIIlIllIIlllll[2]]=jericofx_lIllIIlIlllll[jericofx_IIIIllIIIIIlIllIIlllll[3]];jericofx_lIlIlIlI=jericofx_lIlIlIlI+1;jericofx_IIIIllIIIIIlIllIIlllll=jericofx_lIlIlIIlIlIIllI[jericofx_lIlIlIlI];jericofx_IIlIllIlllIIIIlllIlIlIIlI=jericofx_IIIIllIIIIIlIllIIlllll[2]jericofx_IlllIlIIIIlIlIIIl[jericofx_IIlIllIlllIIIIlllIlIlIIlI]=jericofx_IlllIlIIIIlIlIIIl[jericofx_IIlIllIlllIIIIlllIlIlIIlI](jericofx_IlllIlIIIIlIlIIIl[jericofx_IIlIllIlllIIIIlllIlIlIIlI+1])jericofx_lIlIlIlI=jericofx_lIlIlIlI+1;jericofx_IIIIllIIIIIlIllIIlllll=jericofx_lIlIlIIlIlIIllI[jericofx_lIlIlIlI];jericofx_IlllIlIIIIlIlIIIl[jericofx_IIIIllIIIIIlIllIIlllll[2]]=jericofx_lIllIIlIlllll[jericofx_IIIIllIIIIIlIllIIlllll[3]];jericofx_lIlIlIlI=jericofx_lIlIlIlI+1;jericofx_IIIIllIIIIIlIllIIlllll=jericofx_lIlIlIIlIlIIllI[jericofx_lIlIlIlI];jericofx_IlllIlIIIIlIlIIIl[jericofx_IIIIllIIIIIlIllIIlllll[2]]=jericofx_IlllIlIIIIlIlIIIl[jericofx_IIIIllIIIIIlIllIIlllll[3]];jericofx_lIlIlIlI=jericofx_lIlIlIlI+1;jericofx_IIIIllIIIIIlIllIIlllll=jericofx_lIlIlIIlIlIIllI[jericofx_lIlIlIlI];jericofx_IIlIllIlllIIIIlllIlIlIIlI=jericofx_IIIIllIIIIIlIllIIlllll[2]jericofx_IlllIlIIIIlIlIIIl[jericofx_IIlIllIlllIIIIlllIlIlIIlI]=jericofx_IlllIlIIIIlIlIIIl[jericofx_IIlIllIlllIIIIlllIlIlIIlI](jericofx_IlllIlIIIIlIlIIIl[jericofx_IIlIllIlllIIIIlllIlIlIIlI+1])jericofx_lIlIlIlI=jericofx_lIlIlIlI+1;jericofx_IIIIllIIIIIlIllIIlllll=jericofx_lIlIlIIlIlIIllI[jericofx_lIlIlIlI];if(jericofx_IlllIlIIIIlIlIIIl[jericofx_IIIIllIIIIIlIllIIlllll[2]]<jericofx_IlllIlIIIIlIlIIIl[jericofx_IIIIllIIIIIlIllIIlllll[4]])then jericofx_lIlIlIlI=jericofx_lIlIlIlI+1;else jericofx_lIlIlIlI=jericofx_IIIIllIIIIIlIllIIlllll[3];end;end;elseif jericofx_IIlIllIlllIIIIlllIlIlIIlI<=41 then if(jericofx_IlllIlIIIIlIlIIIl[jericofx_IIIIllIIIIIlIllIIlllll[2]]<jericofx_IlllIlIIIIlIlIIIl[jericofx_IIIIllIIIIIlIllIIlllll[4]])then jericofx_lIlIlIlI=jericofx_lIlIlIlI+1;else jericofx_lIlIlIlI=jericofx_IIIIllIIIIIlIllIIlllll[3];end;elseif jericofx_IIlIllIlllIIIIlllIlIlIIlI>42 then local jericofx_IIlIllIlllIIIIlllIlIlIIlI;local jericofx_IllIIllllI;local jericofx_lllIIIllI;jericofx_IlllIlIIIIlIlIIIl[jericofx_IIIIllIIIIIlIllIIlllll[2]]=jericofx_IIIIllIIIIIlIllIIlllll[3];jericofx_lIlIlIlI=jericofx_lIlIlIlI+1;jericofx_IIIIllIIIIIlIllIIlllll=jericofx_lIlIlIIlIlIIllI[jericofx_lIlIlIlI];jericofx_lIllIIlIlllll[jericofx_IIIIllIIIIIlIllIIlllll[3]]=jericofx_IlllIlIIIIlIlIIIl[jericofx_IIIIllIIIIIlIllIIlllll[2]];jericofx_lIlIlIlI=jericofx_lIlIlIlI+1;jericofx_IIIIllIIIIIlIllIIlllll=jericofx_lIlIlIIlIlIIllI[jericofx_lIlIlIlI];jericofx_IlllIlIIIIlIlIIIl[jericofx_IIIIllIIIIIlIllIIlllll[2]]=jericofx_IIIIllIIIIIlIllIIlllll[3];jericofx_lIlIlIlI=jericofx_lIlIlIlI+1;jericofx_IIIIllIIIIIlIllIIlllll=jericofx_lIlIlIIlIlIIllI[jericofx_lIlIlIlI];jericofx_IlllIlIIIIlIlIIIl[jericofx_IIIIllIIIIIlIllIIlllll[2]]=jericofx_lIllIIlIlllll[jericofx_IIIIllIIIIIlIllIIlllll[3]];jericofx_lIlIlIlI=jericofx_lIlIlIlI+1;jericofx_IIIIllIIIIIlIllIIlllll=jericofx_lIlIlIIlIlIIllI[jericofx_lIlIlIlI];jericofx_lllIIIllI=jericofx_IIIIllIIIIIlIllIIlllll[2]jericofx_IlllIlIIIIlIlIIIl[jericofx_lllIIIllI]=jericofx_IlllIlIIIIlIlIIIl[jericofx_lllIIIllI]()jericofx_lIlIlIlI=jericofx_lIlIlIlI+1;jericofx_IIIIllIIIIIlIllIIlllll=jericofx_lIlIlIIlIlIIllI[jericofx_lIlIlIlI];jericofx_IlllIlIIIIlIlIIIl[jericofx_IIIIllIIIIIlIllIIlllll[2]]=jericofx_IIIIllIIIIIlIllIIlllll[3];jericofx_lIlIlIlI=jericofx_lIlIlIlI+1;jericofx_IIIIllIIIIIlIllIIlllll=jericofx_lIlIlIIlIlIIllI[jericofx_lIlIlIlI];jericofx_IllIIllllI=jericofx_IIIIllIIIIIlIllIIlllll[3];jericofx_IIlIllIlllIIIIlllIlIlIIlI=jericofx_IlllIlIIIIlIlIIIl[jericofx_IllIIllllI]for jericofx_IIIIllIIIIIlIllIIlllll=jericofx_IllIIllllI+1,jericofx_IIIIllIIIIIlIllIIlllll[4]do jericofx_IIlIllIlllIIIIlllIlIlIIlI=jericofx_IIlIllIlllIIIIlllIlIlIIlI..jericofx_IlllIlIIIIlIlIIIl[jericofx_IIIIllIIIIIlIllIIlllll];end;jericofx_IlllIlIIIIlIlIIIl[jericofx_IIIIllIIIIIlIllIIlllll[2]]=jericofx_IIlIllIlllIIIIlllIlIlIIlI;jericofx_lIlIlIlI=jericofx_lIlIlIlI+1;jericofx_IIIIllIIIIIlIllIIlllll=jericofx_lIlIlIIlIlIIllI[jericofx_lIlIlIlI];jericofx_lIllIIlIlllll[jericofx_IIIIllIIIIIlIllIIlllll[3]]=jericofx_IlllIlIIIIlIlIIIl[jericofx_IIIIllIIIIIlIllIIlllll[2]];else jericofx_IlllIlIIIIlIlIIIl[jericofx_IIIIllIIIIIlIllIIlllll[2]]=jericofx_IIIIllIIIIIlIllIIlllll[3];end;elseif jericofx_IIlIllIlllIIIIlllIlIlIIlI<=46 then if jericofx_IIlIllIlllIIIIlllIlIlIIlI<=44 then local jericofx_IIlIllIlllIIIIlllIlIlIIlI;jericofx_IlllIlIIIIlIlIIIl[jericofx_IIIIllIIIIIlIllIIlllll[2]]=jericofx_lIllIIlIlllll[jericofx_IIIIllIIIIIlIllIIlllll[3]];jericofx_lIlIlIlI=jericofx_lIlIlIlI+1;jericofx_IIIIllIIIIIlIllIIlllll=jericofx_lIlIlIIlIlIIllI[jericofx_lIlIlIlI];jericofx_IlllIlIIIIlIlIIIl[jericofx_IIIIllIIIIIlIllIIlllll[2]]=jericofx_lIllIIlIlllll[jericofx_IIIIllIIIIIlIllIIlllll[3]];jericofx_lIlIlIlI=jericofx_lIlIlIlI+1;jericofx_IIIIllIIIIIlIllIIlllll=jericofx_lIlIlIIlIlIIllI[jericofx_lIlIlIlI];jericofx_IIlIllIlllIIIIlllIlIlIIlI=jericofx_IIIIllIIIIIlIllIIlllll[2]jericofx_IlllIlIIIIlIlIIIl[jericofx_IIlIllIlllIIIIlllIlIlIIlI]=jericofx_IlllIlIIIIlIlIIIl[jericofx_IIlIllIlllIIIIlllIlIlIIlI]()jericofx_lIlIlIlI=jericofx_lIlIlIlI+1;jericofx_IIIIllIIIIIlIllIIlllll=jericofx_lIlIlIIlIlIIllI[jericofx_lIlIlIlI];jericofx_IlllIlIIIIlIlIIIl[jericofx_IIIIllIIIIIlIllIIlllll[2]]=jericofx_IIIIllIIIIIlIllIIlllll[3];jericofx_lIlIlIlI=jericofx_lIlIlIlI+1;jericofx_IIIIllIIIIIlIllIIlllll=jericofx_lIlIlIIlIlIIllI[jericofx_lIlIlIlI];jericofx_IIlIllIlllIIIIlllIlIlIIlI=jericofx_IIIIllIIIIIlIllIIlllll[2]jericofx_IlllIlIIIIlIlIIIl[jericofx_IIlIllIlllIIIIlllIlIlIIlI]=jericofx_IlllIlIIIIlIlIIIl[jericofx_IIlIllIlllIIIIlllIlIlIIlI](jericofx_lllIIIllI(jericofx_IlllIlIIIIlIlIIIl,jericofx_IIlIllIlllIIIIlllIlIlIIlI+1,jericofx_IIIIllIIIIIlIllIIlllll[3]))jericofx_lIlIlIlI=jericofx_lIlIlIlI+1;jericofx_IIIIllIIIIIlIllIIlllll=jericofx_lIlIlIIlIlIIllI[jericofx_lIlIlIlI];jericofx_lIllIIlIlllll[jericofx_IIIIllIIIIIlIllIIlllll[3]]=jericofx_IlllIlIIIIlIlIIIl[jericofx_IIIIllIIIIIlIllIIlllll[2]];jericofx_lIlIlIlI=jericofx_lIlIlIlI+1;jericofx_IIIIllIIIIIlIllIIlllll=jericofx_lIlIlIIlIlIIllI[jericofx_lIlIlIlI];jericofx_IlllIlIIIIlIlIIIl[jericofx_IIIIllIIIIIlIllIIlllll[2]]=jericofx_lIllIIlIlllll[jericofx_IIIIllIIIIIlIllIIlllll[3]];jericofx_lIlIlIlI=jericofx_lIlIlIlI+1;jericofx_IIIIllIIIIIlIllIIlllll=jericofx_lIlIlIIlIlIIllI[jericofx_lIlIlIlI];if(jericofx_IlllIlIIIIlIlIIIl[jericofx_IIIIllIIIIIlIllIIlllll[2]]~=jericofx_IlllIlIIIIlIlIIIl[jericofx_IIIIllIIIIIlIllIIlllll[4]])then jericofx_lIlIlIlI=jericofx_lIlIlIlI+1;else jericofx_lIlIlIlI=jericofx_IIIIllIIIIIlIllIIlllll[3];end;elseif jericofx_IIlIllIlllIIIIlllIlIlIIlI==45 then jericofx_IlllIlIIIIlIlIIIl[jericofx_IIIIllIIIIIlIllIIlllll[2]]=jericofx_IlllIlIIIIlIlIIIl[jericofx_IIIIllIIIIIlIllIIlllll[3]];else do return end;end;elseif jericofx_IIlIllIlllIIIIlllIlIlIIlI<=48 then if jericofx_IIlIllIlllIIIIlllIlIlIIlI>47 then local jericofx_lllIIIllI;local jericofx_IIlIllIlllIIIIlllIlIlIIlI;local jericofx_IllIIllllI;jericofx_IlllIlIIIIlIlIIIl[jericofx_IIIIllIIIIIlIllIIlllll[2]]=jericofx_IIIIllIIIIIlIllIIlllll[3];jericofx_lIlIlIlI=jericofx_lIlIlIlI+1;jericofx_IIIIllIIIIIlIllIIlllll=jericofx_lIlIlIIlIlIIllI[jericofx_lIlIlIlI];jericofx_IlllIlIIIIlIlIIIl[jericofx_IIIIllIIIIIlIllIIlllll[2]]=jericofx_lIllIIlIlllll[jericofx_IIIIllIIIIIlIllIIlllll[3]];jericofx_lIlIlIlI=jericofx_lIlIlIlI+1;jericofx_IIIIllIIIIIlIllIIlllll=jericofx_lIlIlIIlIlIIllI[jericofx_lIlIlIlI];jericofx_IlllIlIIIIlIlIIIl[jericofx_IIIIllIIIIIlIllIIlllll[2]]=jericofx_IIIIllIIIIIlIllIIlllll[3];jericofx_lIlIlIlI=jericofx_lIlIlIlI+1;jericofx_IIIIllIIIIIlIllIIlllll=jericofx_lIlIlIIlIlIIllI[jericofx_lIlIlIlI];jericofx_IllIIllllI=jericofx_IIIIllIIIIIlIllIIlllll[3];jericofx_IIlIllIlllIIIIlllIlIlIIlI=jericofx_IlllIlIIIIlIlIIIl[jericofx_IllIIllllI]for jericofx_IIIIllIIIIIlIllIIlllll=jericofx_IllIIllllI+1,jericofx_IIIIllIIIIIlIllIIlllll[4]do jericofx_IIlIllIlllIIIIlllIlIlIIlI=jericofx_IIlIllIlllIIIIlllIlIlIIlI..jericofx_IlllIlIIIIlIlIIIl[jericofx_IIIIllIIIIIlIllIIlllll];end;jericofx_IlllIlIIIIlIlIIIl[jericofx_IIIIllIIIIIlIllIIlllll[2]]=jericofx_IIlIllIlllIIIIlllIlIlIIlI;jericofx_lIlIlIlI=jericofx_lIlIlIlI+1;jericofx_IIIIllIIIIIlIllIIlllll=jericofx_lIlIlIIlIlIIllI[jericofx_lIlIlIlI];jericofx_lllIIIllI=jericofx_IIIIllIIIIIlIllIIlllll[2]jericofx_IlllIlIIIIlIlIIIl[jericofx_lllIIIllI](jericofx_IlllIlIIIIlIlIIIl[jericofx_lllIIIllI+1])jericofx_lIlIlIlI=jericofx_lIlIlIlI+1;jericofx_IIIIllIIIIIlIllIIlllll=jericofx_lIlIlIIlIlIIllI[jericofx_lIlIlIlI];jericofx_lIlIlIlI=jericofx_IIIIllIIIIIlIllIIlllll[3];else local jericofx_lIlIlIIlIlIIllI=jericofx_IIIIllIIIIIlIllIIlllll[3];local jericofx_lIlIlIlI=jericofx_IlllIlIIIIlIlIIIl[jericofx_lIlIlIIlIlIIllI]for jericofx_IIIIllIIIIIlIllIIlllll=jericofx_lIlIlIIlIlIIllI+1,jericofx_IIIIllIIIIIlIllIIlllll[4]do jericofx_lIlIlIlI=jericofx_lIlIlIlI..jericofx_IlllIlIIIIlIlIIIl[jericofx_IIIIllIIIIIlIllIIlllll];end;jericofx_IlllIlIIIIlIlIIIl[jericofx_IIIIllIIIIIlIllIIlllll[2]]=jericofx_lIlIlIlI;end;elseif jericofx_IIlIllIlllIIIIlllIlIlIIlI>49 then jericofx_IlllIlIIIIlIlIIIl[jericofx_IIIIllIIIIIlIllIIlllll[2]]=jericofx_IIIIllIIIIIlIllIIlllll[3];else local jericofx_lIlIlIlI=jericofx_IIIIllIIIIIlIllIIlllll[2];local jericofx_lIlIlIIlIlIIllI=jericofx_IlllIlIIIIlIlIIIl[jericofx_IIIIllIIIIIlIllIIlllll[3]];jericofx_IlllIlIIIIlIlIIIl[jericofx_lIlIlIlI+1]=jericofx_lIlIlIIlIlIIllI;jericofx_IlllIlIIIIlIlIIIl[jericofx_lIlIlIlI]=jericofx_lIlIlIIlIlIIllI[jericofx_IIIIllIIIIIlIllIIlllll[4]];end;jericofx_lIlIlIlI=jericofx_lIlIlIlI+1;end;end);end;return jericofx_IllIIllllI(true,{},jericofx_IllllIllIlII())();end)(string.byte,table.insert,setmetatable);
