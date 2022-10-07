# almez-bombs
NoPixel Inspired C4 Script


Step 1: Install almez-bombs & almez-sync
Step 2: Install baseevents if you dont have (fivem default script)
Step 3: Add this lines to baseevents server;

AddEventHandler('baseevents:enteringVehicle', function(vehicle, seat, vehModel, netId)
	local player = source
	TriggerClientEvent('baseevents:enteredVehicle', player, vehicle, seat, vehModel, netId)
end)

AddEventHandler('baseevents:leftVehicle', function(vehicle, seat, vehModel, netId)
	local player = source
	TriggerClientEvent('baseevents:leftVehicle', player, vehicle, seat, vehModel, netId)
end)

Step 4: Add almez-sync & almez-bombs to your config file, then restart server and use!

You can change item names, C4 model, item triggers from config.
