local spawned = {}

local function loadModelFromList(models)
    for _, name in ipairs(models) do
        local hash = GetHashKey(name)
        if IsModelValid(hash) then
            RequestModel(hash)
            local timeout = 0
            while not HasModelLoaded(hash) and timeout < 5000 do
                Wait(10)
                timeout = timeout + 10
            end
            if HasModelLoaded(hash) then
                return hash
            end
        end
    end
    return 0
end

local function placeOnGround(entity)
    local coords = GetEntityCoords(entity)
    local found, groundZ = GetGroundZFor_3dCoord(coords.x, coords.y, coords.z, false)
    if found then
        SetEntityCoordsNoOffset(entity, coords.x, coords.y, groundZ, false, false, false)
    end
    FreezeEntityPosition(entity, true)
end

local function createProp(id, data)
    if spawned[id] and DoesEntityExist(spawned[id].entity) then
        return
    end

    local model = loadModelFromList(Config.PropModels)
    if model == 0 then
        return
    end

    local coords = vec3(data.x, data.y, data.z)
    local entity = CreateObjectNoOffset(model, coords.x, coords.y, coords.z, false, false, false)
    SetEntityHeading(entity, data.h or 0.0)
    placeOnGround(entity)
    SetEntityAsMissionEntity(entity, true, true)
    SetEntityCanBeDamaged(entity, false)
    FreezeEntityPosition(entity, true)

    exports.ox_target:addLocalEntity(entity, {
        {
            name = 'ms_mushroom_collect',
            label = L('target_label'),
            icon = 'fa-solid fa-hand',
            distance = Config.TargetDistance,
            onSelect = function()
                TriggerServerEvent('ms_mushrooms:attemptCollect', id)
            end
        }
    })

    spawned[id] = { entity = entity }
end

local function deleteProp(id)
    local p = spawned[id]
    if not p then return end
    local entity = p.entity
    if entity and DoesEntityExist(entity) then
        exports.ox_target:removeLocalEntity(entity, 'ms_mushroom_collect')
        DeleteObject(entity)
    end
    spawned[id] = nil
end

RegisterNetEvent('ms_mushrooms:syncSpawns', function(spawns)
    for id, data in pairs(spawned) do
        deleteProp(id)
    end
    for id, data in pairs(spawns or {}) do
        createProp(id, data)
    end
end)

RegisterNetEvent('ms_mushrooms:removeSpawn', function(spawnId)
    deleteProp(spawnId)
end)

RegisterNetEvent('ms_mushrooms:startCollect', function(spawnId, duration)
    local ok = lib.progressBar({
        duration = duration or Config.ProgressDuration,
        label = L('progress_label'),
        useWhileDead = false,
        canCancel = true,
        disable = {
            move = true,
            car = true,
            combat = true,
            mouse = false,
            sprint = true,
        },
        anim = {
            dict = 'amb@world_human_gardener_plant@male@base',
            clip = 'base',
        }
    })

    if ok then
        TriggerServerEvent('ms_mushrooms:finishCollect', spawnId)
    else
        lib.notify({ type = 'error', description = L('collect_cancelled') })
    end
end)

RegisterNetEvent('ms_mushrooms:collectDenied', function(reason)
    lib.notify({ type = 'error', description = reason or L('collect_denied_default') })
end)

RegisterNetEvent('ms_mushrooms:onConsume', function(eatMs, effectMs)
    local ped = PlayerPedId()

    local dict = 'amb@code_human_wander_eating_donut@male@idle_a'
    RequestAnimDict(dict)
    while not HasAnimDictLoaded(dict) do Wait(0) end

    TaskPlayAnim(ped, dict, 'idle_a', 8.0, -8.0, eatMs or Config.EatDuration, 49, 0, false, false, false)
    Wait(eatMs or Config.EatDuration)
    ClearPedTasks(ped)

    StartScreenEffect('DrugsMichaelAliensFight', 0, true)
    ShakeGameplayCam('DRUNK', 0.8)
    SetTimecycleModifier('spectator5')
    SetPedMovementClipset(ped, 'move_m@drunk@verydrunk', true)

    Wait(effectMs or Config.EffectDuration)

    StopScreenEffect('DrugsMichaelAliensFight')
    ShakeGameplayCam('DRUNK', 0.0)
    ResetPedMovementClipset(ped, 0.0)
    ClearTimecycleModifier()
end)

CreateThread(function()
    TriggerServerEvent('ms_mushrooms:clientReady')
end)
