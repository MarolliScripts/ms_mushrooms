local ESX = exports['es_extended']:getSharedObject()

local activeSpawns = {}
local locks = {}

local function playersCount()
    local players = GetPlayers()
    return #players
end

local function generateSpawns()
    activeSpawns = {}
    locks = {}

    local cx, cy, cz, ch = Config.Center.x, Config.Center.y, Config.Center.z, Config.Center.w

    for i = 1, Config.SpawnCount do
        local theta = math.random() * 2.0 * math.pi
        local r = math.random() * Config.Radius
        local x = cx + r * math.cos(theta)
        local y = cy + r * math.sin(theta)
        local z = cz
        local heading = ch
        local id = ('m_%d_%.0f'):format(i, os.clock() * 1000)

        activeSpawns[id] = { x = x, y = y, z = z, h = heading }
    end
end

local function broadcastSpawns(target)
    if target then
        TriggerClientEvent('ms_mushrooms:syncSpawns', target, activeSpawns)
    else
        TriggerClientEvent('ms_mushrooms:syncSpawns', -1, activeSpawns)
    end
end

AddEventHandler('onResourceStart', function(res)
    if res ~= GetCurrentResourceName() then return end
    generateSpawns()
    broadcastSpawns()

    CreateThread(function()
        while true do
            Wait(Config.SpawnInterval)
            generateSpawns()
            broadcastSpawns()
        end
    end)
end)

RegisterNetEvent('ms_mushrooms:clientReady', function()
    local src = source
    broadcastSpawns(src)
end)

RegisterNetEvent('ms_mushrooms:attemptCollect', function(spawnId)
    local src = source

    if playersCount() < Config.RequiredPlayers then
        return TriggerClientEvent('ms_mushrooms:collectDenied', src, L('collect_denied_required_players', Config.RequiredPlayers))
    end

    if not activeSpawns[spawnId] then
        return TriggerClientEvent('ms_mushrooms:collectDenied', src, L('collect_denied_missing'))
    end

    if locks[spawnId] and locks[spawnId] ~= src then
        return TriggerClientEvent('ms_mushrooms:collectDenied', src, L('collect_denied_locked'))
    end

    locks[spawnId] = src
    TriggerClientEvent('ms_mushrooms:startCollect', src, spawnId, Config.ProgressDuration)
end)

RegisterNetEvent('ms_mushrooms:finishCollect', function(spawnId)
    local src = source

    if not activeSpawns[spawnId] or locks[spawnId] ~= src then
        locks[spawnId] = nil
        return
    end

    locks[spawnId] = nil
    activeSpawns[spawnId] = nil
    TriggerClientEvent('ms_mushrooms:removeSpawn', -1, spawnId)

    local canCarry = exports.ox_inventory:CanCarryItem(src, Config.ItemName, 1)
    if not canCarry then
        return TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = L('inventory_full') })
    end

    local success, response = exports.ox_inventory:AddItem(src, Config.ItemName, 1)
    if not success then
        local msg = response or L('unknown_error')
        TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = L('add_item_error', msg) })
        return
    end
end)

ESX.RegisterUsableItem(Config.ItemName, function(source, item)
    local success, response = exports.ox_inventory:RemoveItem(source, Config.ItemName, 1)
    if not success then
        local msg = response or L('unknown_error')
        return TriggerClientEvent('ox_lib:notify', source, { type = 'error', description = L('use_item_error', msg) })
    end
    TriggerClientEvent('ms_mushrooms:onConsume', source, Config.EatDuration, Config.EffectDuration)
end)
