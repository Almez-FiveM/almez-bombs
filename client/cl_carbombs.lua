local carBombActive = false
local carHasBomb = false
local listening = false
local bombTick = 0
local duration = 0
PlantedCarBombs = {}

local function getVehicleSpeed(pEntity)
  return GetEntitySpeed(pEntity) * 2.236936
end

local function doTickNoise(pEntity)
	PlaySoundFromEntity(-1, 'Beep_Red', pEntity, 'DLC_HEIST_HACKING_SNAKE_SOUNDS', true, 10)
  bombTick = bombTick + 1
end

local function stopTickNoise(pEntity)
  bombTick = 0
end

local function resetCarBombState()
  listening = false
  carBombActive = false
  carHasBomb = false
  bombTick = 0
  duration = 0
end

local function explodeVehicle(pEntity)
  exports['almez-sync']:SyncedExecution('NetworkExplodeVehicle', pEntity, 1, 0, 0)
  TriggerServerEvent('almez-bombs:carbombs:removeBomb', NetworkGetNetworkIdFromEntity(pEntity))
end

local function listenForBombTick(pEntity, pMinSpeed, pTicksBeforeExplode, pTicksForRemoval)
  if listening then return end

  listening = true
  Citizen.CreateThread(function()
    while listening do
      if not DoesEntityExist(pEntity) then
        resetCarBombState()
        break
      end

      -- Set the bomb active now so we can listen for ticks
      if carHasBomb and not carBombActive and getVehicleSpeed(pEntity) > pMinSpeed then
        carBombActive = true
        TriggerEvent('DoLongHudText', 'Bomb activated - Do not leave the vehicle - SPEED', 1, 10000)
      end

      if duration >= pTicksForRemoval then
        resetCarBombState()
        TriggerEvent('DoLongHudText', 'Bomb deactivated', 1, 10000)
        TriggerServerEvent('almez-bombs:carbombs:removeBomb', NetworkGetNetworkIdFromEntity(pEntity))
        break
      end

      -- If they are moving less than the speed limit start ticking
      if carBombActive and getVehicleSpeed(pEntity) < pMinSpeed  then
        doTickNoise(pEntity)
      elseif getVehicleSpeed(pEntity) > pMinSpeed and bombTick > 0 then
        stopTickNoise(pEntity)
      end

      if bombTick > pTicksBeforeExplode then
        resetCarBombState()
        explodeVehicle(pEntity)
      end
      
      duration = duration + 1
      Wait(1000)
    end
  end)
end

local function checkForCarBomb(pEntity) 
  if not DoesEntityExist(pEntity) then return end

  TriggerEvent('animation:PlayAnimation', 'search')

  local progress = exports['almez-taskbar']:taskBar(2500, 'Searching for car bomb...', true)
  ClearPedTasks(PlayerPedId())

  if progress ~= 100 then return end

  local pNetId = NetworkGetNetworkIdFromEntity(pEntity)
  local carBombMeta = PlantedCarBombs[pNetId] or false

  if carBombMeta then
    TriggerServerEvent('almez-bombs:carbombs:foundBomb', pNetId, carBombMeta)
    return TriggerEvent('DoLongHudText', 'Looks like there is a car bomb on this vehicle', 1)
  end

  return TriggerEvent('DoLongHudText', 'There seems to be no bomb on this vehicle.', 1)
end

RegisterNetEvent('almez-bombs:carbombs:UpdateCarbombs')
AddEventHandler('almez-bombs:carbombs:UpdateCarbombs', function (carBombs)
    PlantedCarBombs = carBombs
end)

RegisterNetEvent('almez-bombs:carbombs:checkForCarBomb')
AddEventHandler('almez-bombs:carbombs:checkForCarBomb', function()
  local playerPed = PlayerPedId()
  local coords = GetEntityCoords(playerPed)
  local vehicle = Framework.Game.GetClosestVehicle(coords)
    if DoesEntityExist(vehicle) then
      checkForCarBomb(vehicle)
    end
end)

RegisterNetEvent('baseevents:enteredVehicle')
AddEventHandler('baseevents:enteredVehicle', function (pEntity, pSeat, pName, pNetId)
  if pSeat ~= -1 then return end
  if pNetId == nil then return end

  local carBombMeta = PlantedCarBombs[pNetId] or false
  if carBombMeta and not carBombActive then
    print('[almez-bombs] Entered vehicle with car bomb')
    listenForBombTick(pEntity, carBombMeta.minSpeed, carBombMeta.ticksBeforeExplode, carBombMeta.ticksForRemoval)
    carHasBomb = true
  else
    print('[almez-bombs] Entered vehicle without car bomb')
  end
end)

RegisterNetEvent('baseevents:leftVehicle')
AddEventHandler('baseevents:leftVehicle', function (pEntity, pSeat, pName, pNetId)
  if pNetId == nil then return end

  local carBombMeta = PlantedCarBombs[pNetId] or false
  if carBombMeta and carBombActive then
    resetCarBombState()
    explodeVehicle(pEntity)
  end

  -- At this point they should have blown up if they had a bomb else reset state
  resetCarBombState()
end)

RegisterNetEvent('almez-bombs:carbombs:itemUsed')
AddEventHandler('almez-bombs:carbombs:itemUsed', function()
  local playerPed = PlayerPedId()
  local coords = GetEntityCoords(playerPed)
  local vehicle = Framework.Game.GetClosestVehicle(coords)
  if vehicle == 0 then return end

  if GetDistanceBetweenCoords(GetEntityCoords(PlayerPedId(), true), GetEntityCoords(vehicle), false) > 3.0 then return end

  TriggerEvent('animation:PlayAnimation', 'kneel')

  local keyboard, minSpeed, ticksBeforeExplode, ticksForRemoval, coloredSquares, timeToComplete = exports["almez-keyboard"]:Keyboard({
      header = "Set Car Bomb", 
      rows = {
        { label = 'Min Speed (MPH)', icon = 'stopwatch', type = 'number' },
        { label = 'Ticks before explosion (Seconds)', icon = 'stopwatch', type = 'number' },
        { label = 'Removal Length (Seconds)', icon = 'stopwatch', type = 'number' },
        -- { label = "Grid Size (5-12)", icon = "stopwatch", type = "number" },
        { label = "Colored Sqaures (5-20)", icon = "stopwatch", type = "number" },
        { label = "Time To Complete (10-30 Seconds)", icon = "stopwatch", type = "number"},
      },
  })
  
  if not keyboard then 
    ClearPedTasks(PlayerPedId())
    return
  end

  local minSpeed = tonumber(minSpeed) or 0
  if minSpeed <= 1 then
    return TriggerEvent('DoLongHudText', 'Min speed must be more than 1 MPH', 2)
  end

  local ticksBeforeExplode = tonumber(ticksBeforeExplode) or 0
  if ticksBeforeExplode < 5 then
    return TriggerEvent('DoLongHudText', 'Min ticks before explosion needs to be more than 5', 2)
  end

  local ticksForRemoval = tonumber(ticksForRemoval) or 0
  if ticksForRemoval < 5 then
    return TriggerEvent('DoLongHudText', 'Removal duration needs to be more than 5', 2)
  end

  local coloredSquares = tonumber(coloredSquares)
  if coloredSquares > 20 or coloredSquares < 5 then
      return TriggerEvent("DoLongHudText", "Colored Sqaures must be between 5-20", 2)
  end

  local timeToComplete = tonumber(timeToComplete) * 1000
  if timeToComplete < 10000 or timeToComplete > 30000 then
      return TriggerEvent("DoLongHudText", "Time to complete must be between 10-30 seconds", 2)
  end

  local progress = exports['almez-taskbar']:taskBar(2000, 'Planting car bomb...', true)
  
  ClearPedTasks(PlayerPedId())
  
  if progress ~= 100 then return end

  local netId = NetworkGetNetworkIdFromEntity(vehicle)
  TriggerServerEvent('almez-bombs:carbombs:addCarBomb', netId, minSpeed, ticksBeforeExplode, ticksForRemoval, coloredSquares, timeToComplete)
  TriggerEvent('inventory:removeItem', 'car_bomb', 1)
  
  return TriggerEvent('DoLongHudText', 'Successfully added car bomb to vehicle', 1)
end)

RegisterNetEvent('almez-bombs:carBombs:removeBomb')
AddEventHandler('almez-bombs:carBombs:removeBomb', function (pData, pEntity)
  local pNetId = NetworkGetNetworkIdFromEntity(pEntity)
  local carBombMeta = PlantedCarBombs[pNetId] or false

  if carBombMeta then
    TriggerEvent('animation:PlayAnimation', 'kneel')
  
    exports['almez-thermite']:OpenThermiteGame(function(success)
        TriggerServerEvent('almez-bombs:carBombs:completeHacking', success, pNetId)
    end, carBombMeta.coloredSqaures, 3, carBombMeta.timeToComplete)
  end
end)

RegisterNetEvent('almez-bombs:carBombs:completeHacking')
AddEventHandler('almez-bombs:carBombs:completeHacking', function(success, pNetId)
  ClearPedTasks(PlayerPedId())

  TriggerServerEvent('almez-bombs:carbombs:removeBomb', pNetId)
  if success then
    TriggerEvent('DoLongHudText', 'Bomb has been removed from vehicle', 1)
    TriggerEvent("player:receiveItem", "car_bomb_defused", 1)
  else
    explodeVehicle(NetworkGetEntityFromNetworkId(pNetId)) 
    resetCarBombState()
  end
end)
