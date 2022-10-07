
CreateThread(function()
    local models = {
        GetHashKey(Config.BombConfig.C4Model),
    }
    exports['almez-target']:AddTargetModel(models, {
        options = {
         {
            event = "almez-bombs:bombs:checkTime",
            icon = "stopwatch",
            label = "Check remaining time",
         },
         {
             event = "almez-bombs:bombs:cut",
             icon = "cut",
             label = "Cut red wire",
             args = { wire = "red"}
         },
         {
             event = "almez-bombs:bombs:cut",
             icon = "cut",
             label = "Cut green wire",
             args = { wire = "green" }
         },
         {
             event = "almez-bombs:bombs:cut",
             icon = "cut",
             label = "Cut blue wire",
             args = { wire = "blue" }
         },
         {
             event = "almez-bombs:bombs:cut",
             icon = "cut",
             label = "Cut yellow wire",
             args = { wire = "yellow" }
         },
         {
             event = "almez-bombs:bombs:cut",
             icon = "cut",
             label = "Cut purple wire",
             args = { wire = "purple" }
         },
         {
             event = "almez-bombs:bombs:cut",
             icon = "cut",
             label = "Cut white wire",
             args = { wire = "white" }
         },
        },
        job = {"all"},
        distance = 2.5
    })
    RequestAnimDict("amb@world_human_bum_wash@male@low@idle_a")
    while not HasAnimDictLoaded("amb@world_human_bum_wash@male@low@idle_a") do
        Wait(100)
        RequestAnimDict("amb@world_human_bum_wash@male@low@idle_a")
    end
end)