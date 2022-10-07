Framework = nil

Config.GetObject(function(obj)
    Framework = obj
end)

plantedBombs = {}

Framework.RegisterUsableItem(Config.BombConfig.C4Item, function(source)
    Config.BombConfig.ItemTrigger(source)
end)

RegisterServerEvent('almez-bombs:bombs:exploded')
AddEventHandler('almez-bombs:bombs:exploded', function(index)
    TriggerClientEvent('almez-bombs:bombs:exploded', -1, index)
end)

RegisterServerEvent('almez-bombs:bombs:explode')
AddEventHandler('almez-bombs:bombs:explode', function(index)
    TriggerClientEvent('almez-bombs:bombs:explode', -1, index)
end)

RegisterServerEvent("almez-bombs:removeItem")
AddEventHandler("almez-bombs:removeItem",function()
    local src = source
    Config.ItemRemoveTrigger(src, Framework)
end)

RegisterServerEvent('almez-bombs:bombs:completedHacking')
AddEventHandler('almez-bombs:bombs:completedHacking', function(success, index)
    if success then
        TriggerClientEvent('almez-bombs:bombs:defused', -1, index)
    else 
        TriggerClientEvent('almez-bombs:bombs:explode', -1, index)
    end
end)

RegisterServerEvent('almez-bombs:bombs:cut')
AddEventHandler('almez-bombs:bombs:cut', function(index, bomb, wire)
    local src = source
    if bomb.wire == wire then
        TriggerClientEvent('almez-bombs:bombs:defuseCorrectBomb', src, index, bomb.coloredSquares, bomb.timeToComplete)
    else 
        TriggerClientEvent('almez-bombs:bombs:explode', -1, index)
    end
end)

RegisterServerEvent('almez-bombs:plant')
AddEventHandler('almez-bombs:plant', function(coords, length, wire, coloredSquares, timeToComplete)
    local lastIndex = 0
    for k, v in pairs(plantedBombs) do
        lastIndex = k
    end
    plantedBombs[lastIndex + 1] = {
        defused = false,
        exploded = false,
        length = length * 1000,
        wire = wire,
        coloredSquares = coloredSquares,
        timeToComplete = timeToComplete,
        startTime = GetGameTimer(),
        soundEnable = true,
        coords = coords 
    }
    TriggerClientEvent('almez-bombs:bombs:UpdateBombs', -1, plantedBombs)
end)

Citizen.CreateThread(function()
    while true do 
        Citizen.Wait(1000)
        for k,v in pairs(plantedBombs) do
            if not v.defused or not v.exploded then
                local remaining = v.length - (GetGameTimer() - v.startTime)
                seconds =(remaining/1000)%60
                minutes =(remaining/(1000*60))%60
                hours =(remaining/(1000*60*60))%24
                if math.floor(hours) == 0 and math.floor(minutes) == 0 and math.floor(seconds) == 0 then
                    TriggerEvent("almez-bombs:bombs:explode", k)
                end
            end
        end
    end
end)