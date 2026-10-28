if Config.CustomInventory ~= 'qs' then return end

-- qs-inventory registers the items made in its in-game creator a moment after
-- it starts, and can add or change them at any time. ESX.Items is read once
-- they are in, and again whenever qs-inventory reports a change.
local function syncItems()
    local ok, items = pcall(function() return exports['qs-inventory']:GetItemList() end)
    if not ok or type(items) ~= 'table' then return end
    ESX.Items = items
    TriggerEvent('esx:itemsUpdated')
end

local function waitForItemList()
    local deadline = GetGameTimer() + 30000
    while GetGameTimer() < deadline do
        if GetResourceState('qs-inventory') == 'started' then
            local ok, ready = pcall(function() return exports['qs-inventory']:ItemListReady() end)
            -- An older qs-inventory has no such export: its list is complete as it is.
            if not ok or ready then return end
        end
        Wait(250)
    end
end

MySQL.ready(function()
    syncItems()
    CreateThread(function()
        waitForItemList()
        syncItems()
    end)
end)

AddEventHandler('qs-inventory:itemListUpdated', syncItems)
---@diagnostic disable-next-line: duplicate-set-field
ESX.GetItemLabel = function(item)
    return exports['qs-inventory']:GetItemLabel(item)
end
exports('GetUsableItems', function()
    return Core.UsableItemsCallbacks
end)
---@diagnostic disable-next-line: duplicate-set-field
ESX.RegisterUsableItem = function(item, cb)
    Core.UsableItemsCallbacks[item] = cb
    exports['qs-inventory']:CreateUsableItem(item, cb)
end
---@diagnostic disable-next-line: duplicate-set-field
ESX.UseItem = function(source, item, ...)
    if ESX.Items[item] then
        local itemCallback = Core.UsableItemsCallbacks[item]
        return exports['qs-inventory']:UseItem(item, source, ...)
    else
        print(('[^3WARNING^7] Item ^5"%s"^7 was used but does not exist!'):format(item))
    end
end
