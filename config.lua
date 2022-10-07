Config = {
    GetObject = function(callback)
        QBCore = exports['qb-core']:GetCoreObject()
        callback(QBCore)
    end,

    ItemRemoveTrigger = function(source, Framework)
        local src = source 
        local xPlayer = Framework.GetPlayerFromId(src)
        xPlayer.removeInventoryItem("c4", 1)
    end,

    BombConfig = {
        C4Model = "h4_prop_h4_ld_bomb_01a",
        C4Item = "c4",    
        ItemTrigger = function(source)
            TriggerClientEvent('almez-bombs:itemUsed', source)
        end, -- don't change if you don't know what you're doing
    },

    BombConfig = {
        C4Model = "h4_prop_h4_ld_bomb_01a",
        C4Item = "c4",    
        ItemTrigger = function(source)
            TriggerClientEvent('almez-bombs:carbombs:itemUsed', source)
        end, -- don't change if you don't know what you're doing
    },

    Notify = function(Framework, text)
        Framework.Functions.Notify(text)
    end,
}