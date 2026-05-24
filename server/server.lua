ESX = nil

local sharedVehicleKeys = {}
local temporaryVehicleKeys = {}

local function normalizePlate(plate)
    plate = (plate or ''):upper()
    plate = plate:gsub("^%s*(.-)%s*$", "%1")
    plate = plate:gsub("%s+", "")
    return plate
end

local function getPlayerIdentifier(source)
    local xPlayer = ESX.GetPlayerFromId(source)
    return xPlayer and xPlayer.identifier or nil
end

local function playerHasTemporaryKey(source, plate)
    local identifier = getPlayerIdentifier(source)
    if not identifier then return false end

    local plateNorm = normalizePlate(plate)

    return temporaryVehicleKeys[identifier]
        and temporaryVehicleKeys[identifier][plateNorm] == true
end

local function giveTemporaryKey(source, plate)
    local identifier = getPlayerIdentifier(source)
    if not identifier then return end

    local plateNorm = normalizePlate(plate)

    temporaryVehicleKeys[identifier] = temporaryVehicleKeys[identifier] or {}
    temporaryVehicleKeys[identifier][plateNorm] = true

    print(("[attanos_carlock] Temporary key given -> %s plate=%s"):format(identifier, plateNorm))
end

local function giveSharedKey(targetSource, plate)
    local identifier = getPlayerIdentifier(targetSource)
    if not identifier then return false end

    local plateNorm = normalizePlate(plate)

    sharedVehicleKeys[identifier] = sharedVehicleKeys[identifier] or {}
    sharedVehicleKeys[identifier][plateNorm] = true

    return true
end

local function removeSharedKey(targetSource, plate)
    local identifier = getPlayerIdentifier(targetSource)
    if not identifier then return false end

    local plateNorm = normalizePlate(plate)

    if sharedVehicleKeys[identifier] then
        sharedVehicleKeys[identifier][plateNorm] = nil
    end

    return true
end

CreateThread(function()
    while ESX == nil do
        TriggerEvent('esx:getSharedObject', function(obj)
            ESX = obj
        end)

        Wait(100)
    end

    print("^2[attanos_carlock]^7 ESX ready. Registering callbacks and exports.")

    exports('shareKey', function(targetSource, plate)
        local success = giveSharedKey(targetSource, plate)

        if success then
            print(("[attanos_carlock] Shared key added -> target=%s plate=%s"):format(
                targetSource,
                normalizePlate(plate)
            ))
        end

        return success
    end)

    exports('removeSharedKey', function(targetSource, plate)
        local success = removeSharedKey(targetSource, plate)

        if success then
            print(("[attanos_carlock] Shared key removed -> target=%s plate=%s"):format(
                targetSource,
                normalizePlate(plate)
            ))
        end

        return success
    end)

    RegisterNetEvent('attanos_carlock:server:giveTempKey', function(plate)
        local source = source
        giveTemporaryKey(source, plate)
    end)

    ESX.RegisterServerCallback('attanos_carlock:getVeh', function(source, cb, plate)
        local identifier = getPlayerIdentifier(source)

        if not identifier then
            print("[attanos_carlock] getVeh failed: no player identifier")
            cb(false)
            return
        end

        local plateNorm = normalizePlate(plate)

        if playerHasTemporaryKey(source, plateNorm) then
            cb(true)
            return
        end

        if sharedVehicleKeys[identifier] and sharedVehicleKeys[identifier][plateNorm] then
            cb(true)
            return
        end

        MySQL.Async.fetchAll([[
            SELECT plate, owner
            FROM owned_vehicles
            WHERE owner = @owner
              AND REPLACE(UPPER(TRIM(plate)), ' ', '') = @plate
            LIMIT 1
        ]], {
            ['@owner'] = identifier,
            ['@plate'] = plateNorm
        }, function(result)
            local ownsVehicle = result and result[1] ~= nil
            cb(ownsVehicle)
        end)
    end)
end)

RegisterNetEvent('attanos_carlock:server:giveKeyToNearest', function(targetSource, plate)
    local source = source

    if not targetSource or source == targetSource then return end

    local giverIdentifier = getPlayerIdentifier(source)
    local targetIdentifier = getPlayerIdentifier(targetSource)

    if not giverIdentifier or not targetIdentifier then return end

    local plateNorm = normalizePlate(plate)

    local function grantVehicleKey()
        sharedVehicleKeys[targetIdentifier] = sharedVehicleKeys[targetIdentifier] or {}
        sharedVehicleKeys[targetIdentifier][plateNorm] = true

        TriggerClientEvent('ox_lib:notify', source, {
            title = 'Attano Car Lock',
            description = 'You gave the vehicle key away.',
            type = 'success'
        })

        TriggerClientEvent('ox_lib:notify', targetSource, {
            title = 'Attano Car Lock',
            description = 'You received a vehicle key.',
            type = 'success'
        })
    end

    if playerHasTemporaryKey(source, plateNorm) then
        grantVehicleKey()
        return
    end

    if sharedVehicleKeys[giverIdentifier] and sharedVehicleKeys[giverIdentifier][plateNorm] then
        grantVehicleKey()
        return
    end

    MySQL.Async.fetchAll([[
        SELECT plate
        FROM owned_vehicles
        WHERE owner = @owner
          AND REPLACE(UPPER(TRIM(plate)), ' ', '') = @plate
        LIMIT 1
    ]], {
        ['@owner'] = giverIdentifier,
        ['@plate'] = plateNorm
    }, function(result)
        local ownsVehicle = result and result[1] ~= nil

        if ownsVehicle then
            grantVehicleKey()
        else
            TriggerClientEvent('ox_lib:notify', source, {
                title = 'Attano Car Lock',
                description = "You don't have keys for that vehicle.",
                type = 'error'
            })
        end
    end)
end)

RegisterNetEvent('attanos_carlock:server:removeLockpick', function()
    local source = source
    local lockpickItem = Config and Config.LockpickItem or 'lockpick'

    exports.ox_inventory:RemoveItem(source, lockpickItem, 1)
end)
