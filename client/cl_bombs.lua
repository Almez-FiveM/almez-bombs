Framework = nil 

Citizen.CreateThread(function()
    while Framework == nil do 
        Config.GetObject(function(obj)
            Framework = obj
        end)
        Citizen.Wait(0)
    end
end)

local plantedBombs = {}
AddEventHandler("almez-bombs:itemUsed", function()
    local wireOptions = {
        { id = "red", name = "Red" },
        { id = "green", name = "Green" },
        { id = "blue", name = "Blue" },
        { id = "yellow", name = "Yellow" },
        { id = "purple", name = "Purple" },
        { id = "white", name = "White" },
        { id = "random", name = "Random :)" },
    }

    local keyboard, length, wire, coloredSquares, timeToComplete = exports["almez-keyboard"]:Keyboard({
        header = "Set Bomb", 
        rows = {
            {label = "Length in seconds (120-7200)", type = "number", icon = "stopwatch"},
            {label = "Wire to cut", type = "select", options = wireOptions, icon = "solid fa-scissors"},
            {label = "Colored Squares (5-10)", type = "number", icon = "solid fa-square"},
            {label = "Time To Complete (10-30)", type = "number", icon = "stopwatch"},
        },
    })

    if not keyboard then return end

    if wire == "random" then
        while wire == "random" do
            wire = wireOptions[math.random(1, #wireOptions)].id
            Citizen.Wait(1)
        end
    end
    length = tonumber(length) 
    coloredSquares = tonumber(coloredSquares)

    print(length, wire, coloredSquares, timeToComplete)
    -- if length < 120 or length > 7200 then
    --     return TriggerEvent("DoLongHudText", "Time needs to be between 120 and 7200 seconds", 2)
    -- end
    -- testten sonra yorum satırı kaldırılacak
    if coloredSquares > 20 or coloredSquares < 5 then
        return TriggerEvent("DoLongHudText", "Colored Sqaures must be between 5-20", 2)
    end

    local timeToComplete = tonumber(timeToComplete) * 1000
    if timeToComplete < 10000 or timeToComplete > 30000 then
        return TriggerEvent("DoLongHudText", "Time to complete must be between 10-30 seconds", 2)
    end

    local coords = GetEntityCoords(PlayerPedId()) + GetEntityForwardVector(PlayerPedId())

    TaskPlayAnim(PlayerPedId(), "amb@world_human_bum_wash@male@low@idle_a", "idle_a", 8.0, -8.0, -1, 1, 1.0, false, false, false)

    local progress = exports["almez-taskbar"]:taskBar(1000, "Planting bomb...", true)
    ClearPedTasks(PlayerPedId())

    if progress ~= 100 then return end
    
    local _, GroundZ = GetGroundZAndNormalFor_3dCoord(coords.x, coords.y, coords.z, 0)
    TriggerServerEvent('almez-bombs:plant', {
        x = coords.x,
        y = coords.y,
        z = GroundZ + 0.05
    }, length, wire, coloredSquares, timeToComplete)
    FreezeEntityPosition(obj, true)

    TriggerEvent("DoLongHudText", "Bomb planted", 2)
    TriggerServerEvent("almez-bombs:removeItem")
end)

RegisterNetEvent("almez-bombs:bombs:UpdateBombs")
AddEventHandler("almez-bombs:bombs:UpdateBombs", function (bombs)
    plantedBombs = bombs
    for index,bomb in pairs(plantedBombs) do
        DeleteObject(bomb.obj)
        -- if bomb.obj ~= nil then return end
        local obj = CreateObject(GetHashKey(Config.BombConfig.C4Model), bomb.coords.x, bomb.coords.y, bomb.coords.z-0.15, true, false, false)
        SetEntityRotation(obj, 270.0, 0.0, 0.0, false, true)
        FreezeEntityPosition(obj, true)
        bomb.obj = obj
    end
end)


RegisterNetEvent("almez-bombs:bombs:defuseCorrectBomb")
AddEventHandler("almez-bombs:bombs:defuseCorrectBomb", function (index, coloredSquares, timeToComplete)
    TriggerEvent("doAnim", "kneel2")
    exports['almez-thermite']:OpenThermiteGame(function(success)
        TriggerServerEvent('almez-bombs:bombs:completedHacking', success, index)
    end, coloredSquares, 3, timeToComplete)
end)

AddEventHandler("almez-bombs:bombs:checkTime", function()
    local nearestBomb = getNearestBomb(GetEntityCoords(PlayerPedId()))
    if not nearestBomb then return end
    if plantedBombs[nearestBomb].defused or plantedBombs[nearestBomb].exploded then 
        TriggerEvent("DoLongHudText", "Bomb already defused or exploded.", 2)
       return
    end
    
    local remaining = plantedBombs[nearestBomb].length - (GetGameTimer() - plantedBombs[nearestBomb].startTime)
    seconds =(remaining/1000)%60
    minutes =(remaining/(1000*60))%60
    hours =(remaining/(1000*60*60))%24
    print(remaining)
    -- print(hours, minutes, seconds)
    if math.floor(hours) == 0 then 
        TriggerEvent("DoLongHudText", ("Remaining time: %s  minutes and %s seconds"):format(math.floor(minutes), math.floor(seconds)), 2)
    elseif math.floor(hours) == 0 and math.floor(minutes) == 0 then
        TriggerEvent("DoLongHudText", ("Remaining time: %s seconds"):format(math.floor(hours), math.floor(minutes), math.floor(seconds)), 2)
    else 
        TriggerEvent("DoLongHudText", ("Remaining time:%s hours %s  minutes and %s seconds"):format(math.floor(hours), math.floor(minutes), math.floor(seconds)), 2)
    end
end)

AddEventHandler("almez-bombs:bombs:cut", function (params)
    if not params.wire then return false end

    local nearestBomb = getNearestBomb(GetEntityCoords(PlayerPedId()))
    if not nearestBomb then return false end

    if plantedBombs[nearestBomb].defused or plantedBombs[nearestBomb].exploded then return false end
    TriggerServerEvent('almez-bombs:bombs:cut', nearestBomb, plantedBombs[nearestBomb], params.wire)
end)

RegisterNetEvent("almez-bombs:bombs:defused")
AddEventHandler("almez-bombs:bombs:defused", function(index)
    if not plantedBombs[index] then return end
    plantedBombs[index].defused = true

    if plantedBombs[index].soundId and plantedBombs[index].handle then
        plantedBombs[index].handle = nil
        plantedBombs[index].soundId = nil
    end
end)

RegisterNetEvent("almez-bombs:bombs:explode")
AddEventHandler("almez-bombs:bombs:explode", function (index)
    if not plantedBombs[index] then return false end

    AddExplosion(
        plantedBombs[index].coords.x,
        plantedBombs[index].coords.y,
        plantedBombs[index].coords.z,
        15,
        100.0,
        true,
        false,
        0.0
    )
    plantedBombs[index].exploded = true
    TriggerServerEvent("almez-bombs:bombs:exploded", index)
end)

RegisterNetEvent("almez-bombs:bombs:exploded")
AddEventHandler("almez-bombs:bombs:exploded", function(index)
    if not plantedBombs[index] then return false end
    
    plantedBombs[index].exploded = true
    if plantedBombs[index].soundEnable then
        plantedBombs[index].soundEnable = false
    end
end)


AddEventHandler('onResourceStop', function (resource)
    if resource ~= GetCurrentResourceName() then return end
    for index, bomb in pairs(plantedBombs) do
        DeleteObject(bomb.obj)
        plantedBombs[index] = nil
    end
end)

function getNearestBomb(coords, dist)
    if not dist then dist = 3 end
    local nearestBomb = nil
    local nearestDistance = nil
    for index, bomb in pairs(plantedBombs) do
        local distance = #(vector3(coords.x, coords.y, coords.z) - vector3(bomb.coords.x, bomb.coords.y, bomb.coords.z))
        if not nearestDistance or distance < nearestDistance and (not bomb.exploded and not bomb.defused) then
            nearestBomb = index
            nearestDistance = distance
        end
    end
    if not nearestDistance or nearestDistance > dist then return nil end
    return nearestBomb
end

RegisterNetEvent('DoLongHudText')
AddEventHandler('DoLongHudText', function(text)
    Config.Notify(Framework, text)
end)

Citizen.CreateThread(function()
    while true do 
        Citizen.Wait(1000)
        for k,v in pairs(plantedBombs) do
            if not v.defused and not v.exploded then
                if v.soundEnable then
                    PlaySoundFromEntity(-1, 'Beep_Red', v.obj, 'DLC_HEIST_HACKING_SNAKE_SOUNDS', true, 10)
                end
            end
        end
    end
end)