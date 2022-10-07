PlantedCarBombs = {}

RegisterServerEvent('almez-bombs:carbombs:removeBomb')
AddEventHandler('almez-bombs:carbombs:removeBomb', function(netId)
    local player = source
    local carBombMeta = PlantedCarBombs[netId] or false
    PlantedCarBombs[netId] = nil
    TriggerClientEvent('almez-bombs:carbombs:removeBomb', player, netId)
    TriggerClientEvent('almez-bombs:carbombs:UpdateCarbombs', -1, PlantedCarBombs)
end)
    

RegisterServerEvent('almez-bombs:carbombs:addCarBomb')
AddEventHandler('almez-bombs:carbombs:addCarBomb', function(netId, minSpeed, ticksBeforeExplode, ticksForRemoval, coloredSquares, timeToComplete)
    PlantedCarBombs[netId] = {
        minSpeed = minSpeed,
        ticksBeforeExplode = ticksBeforeExplode,
        ticksForRemoval = ticksForRemoval,
        coloredSquares = coloredSquares,
        timeToComplete = timeToComplete,
    }
    TriggerClientEvent('almez-bombs:carbombs:UpdateCarbombs', -1, PlantedCarBombs)
end)