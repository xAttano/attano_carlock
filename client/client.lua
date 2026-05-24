-- client.lua
-- NOTE: This version expects your config to use Config = {}
-- and your server events/callbacks to use attanos_carlock.

local ESX = nil

local function sendVehicleNotice(description, icon, iconColor)
    lib.notify({
        title = Config.Locale.NotifyTitle,
        description = description,
        position = 'top',
        style = {
            backgroundColor = '#1E1E2E',
            color = '#C1C2C5',
            ['.description'] = { color = '#909296' }
        },
        icon = icon,
        iconColor = iconColor
    })
end

local isHotwiring = false
local isLockpicking = false
local temporaryKeys = {}
local vehicleKeyCache = {}

local function normalizePlate(plate)
    return (plate or '')
        :upper()
        :gsub("^%s*(.-)%s*$", "%1")
        :gsub("%s+", "")
end

local function getVehiclePlate(vehicle)
    return normalizePlate(GetVehicleNumberPlateText(vehicle))
end

local function hasVehicleKey(vehicle)
    if not vehicle or vehicle == 0 then return false end

    local plate = getVehiclePlate(vehicle)

    if temporaryKeys[plate] then
        return true
    end

    local now = GetGameTimer()

    if vehicleKeyCache[plate] and (now - vehicleKeyCache[plate].time) < 1000 then
        return vehicleKeyCache[plate].value
    end

    local p = promise.new()

    ESX.TriggerServerCallback('attanos_carlock:getVeh', function(result)
        local hasKey = result == true

        vehicleKeyCache[plate] = {
            value = hasKey,
            time = GetGameTimer()
        }

        p:resolve(hasKey)
    end, plate)

    return Citizen.Await(p)
end

local function breakLockpick()
    if not Config.RemoveLockpickOnFail then return end

    if math.random(1, 100) <= (Config.LockpickBreakChance or 35) then
        TriggerServerEvent('attanos_carlock:server:removeLockpick')
        sendVehicleNotice("Lockpick broke.", 'xmark', '#f38ba8')
    end
end

local function doLockpick(vehicle)
    if isLockpicking or not DoesEntityExist(vehicle) then return end

    if hasVehicleKey(vehicle) then
        sendVehicleNotice(Config.Locale.AlreadyHasKey, 'triangle-exclamation', '#f38ba8')
        return
    end

    local locked = GetVehicleDoorLockStatus(vehicle)

    if not Config.LockpickAllowIfUnlocked and locked ~= 2 then
        sendVehicleNotice(Config.Locale.VehicleAlreadyUnlocked, 'triangle-exclamation', '#f38ba8')
        return
    end

    local count = exports.ox_inventory:Search('count', Config.LockpickItem)

    if not count or count < 1 then
        sendVehicleNotice(Config.Locale.NeedLockpick, 'triangle-exclamation', '#f38ba8')
        return
    end

    isLockpicking = true

    TriggerEvent('attano-vehiclecrime:client:vehicleDispatch', vehicle, "Carjacking / Vehicle Break-In")

    local success = lib.skillCheck(Config.LockpickSkillcheck, { '1', '2', '3', '4' })

    if success then
        if lib.progressCircle({
            duration = Config.LockpickTime,
            label = Config.Locale.ProgressLockpicking,
            position = 'bottom',
            useWhileDead = false,
            canCancel = true,
            disable = Config.DisableControls
        }) then
            SetVehicleDoorsLocked(vehicle, 1)
            SetVehicleDoorsLockedForAllPlayers(vehicle, false)

            sendVehicleNotice(Config.Locale.LockpickSuccess, 'lock-open', '#a6e3a1')
        else
            sendVehicleNotice("Cancelled.", 'triangle-exclamation', '#f38ba8')
        end
    else
        breakLockpick()
        sendVehicleNotice(Config.Locale.LockpickFailed, 'xmark', '#f38ba8')
    end

    isLockpicking = false
end

local function doHotwire(vehicle)
    if isHotwiring or not DoesEntityExist(vehicle) then return end

    if hasVehicleKey(vehicle) then
        sendVehicleNotice(Config.Locale.AlreadyHasKey, 'triangle-exclamation', '#f38ba8')
        return
    end

    if GetPedInVehicleSeat(vehicle, -1) ~= PlayerPedId() then
        sendVehicleNotice(Config.Locale.MustBeDriver, 'triangle-exclamation', '#f38ba8')
        return
    end

    isHotwiring = true
    SetVehicleEngineOn(vehicle, false, true, true)

    local success = lib.skillCheck(Config.HotwireSkillcheck, { '1', '2', '3', '4' })

    if success then
        if lib.progressCircle({
            duration = Config.HotwireTime,
            label = Config.Locale.ProgressHotwiring,
            position = 'bottom',
            useWhileDead = false,
            canCancel = true,
            disable = Config.DisableControls
        }) then
            local plate = getVehiclePlate(vehicle)

            temporaryKeys[plate] = true

            TriggerServerEvent('attanos_carlock:server:giveTempKey', plate)

            SetVehicleEngineOn(vehicle, true, true, false)
            SetVehicleUndriveable(vehicle, false)

            sendVehicleNotice(Config.Locale.HotwireSuccess, 'bolt', '#a6e3a1')
        else
            sendVehicleNotice("Cancelled.", 'triangle-exclamation', '#f38ba8')
        end
    else
        sendVehicleNotice(Config.Locale.HotwireFailed, 'xmark', '#f38ba8')
    end

    isHotwiring = false
end

CreateThread(function()
    while ESX == nil do
        TriggerEvent('esx:getSharedObject', function(obj)
            ESX = obj
        end)

        Wait(100)
    end
end)

local targetLockOption = {
    name = 'attanos_carlock:target',
    icon = Config.TargetIcon,
    label = Config.Locale.TargetLabel,
    onSelect = function(data)
        local vehicle = data.entity

        if not DoesEntityExist(vehicle) then return end
        if not ESX or not ESX.TriggerServerCallback then
            print("^1[attanos_carlock]^7 ESX.TriggerServerCallback is missing.")
            return
        end

        local plate = normalizePlate(GetVehicleNumberPlateText(vehicle))

        ESX.TriggerServerCallback('attanos_carlock:getVeh', function(hasKey)
            if not hasKey then
                sendVehicleNotice("You don't have keys for this vehicle.", 'triangle-exclamation', '#f38ba8')
                return
            end

            local start = GetGameTimer()

            while not NetworkHasControlOfEntity(vehicle) and (GetGameTimer() - start) < 1500 do
                NetworkRequestControlOfEntity(vehicle)
                Wait(0)
            end

            if not NetworkHasControlOfEntity(vehicle) then
                sendVehicleNotice("Couldn't get control of the vehicle.", 'triangle-exclamation', '#f38ba8')
                return
            end

            local status = GetVehicleDoorLockStatus(vehicle)
            local wasLocked = status == 2

            if wasLocked then
                SetVehicleDoorsLocked(vehicle, 1)
                SetVehicleDoorsLockedForAllPlayers(vehicle, false)
                PlayVehicleDoorOpenSound(vehicle, 0)
                sendVehicleNotice(Config.Locale.NotifyUnlocked, 'lock-open', '#a6e3a1')
            else
                SetVehicleDoorsLocked(vehicle, 2)
                SetVehicleDoorsLockedForAllPlayers(vehicle, true)
                PlayVehicleDoorCloseSound(vehicle, 0)
                sendVehicleNotice(Config.Locale.NotifyLocked, 'lock', '#f38ba8')
            end

            SetVehicleLights(vehicle, 2)
            Wait(150)
            SetVehicleLights(vehicle, 0)
        end, plate)
    end
}

local targetLockpickOption = {
    name = 'attanos_carlock:lockpick',
    icon = 'fa-solid fa-screwdriver-wrench',
    label = 'Lockpick Vehicle',
    distance = 2.0,
    canInteract = function(entity)
        if not DoesEntityExist(entity) then return false end

        return GetVehicleDoorLockStatus(entity) == 2
    end,
    onSelect = function(data)
        local vehicle = data.entity

        if not vehicle or vehicle == 0 then return end

        doLockpick(vehicle)
    end
}

if Config.TargetSupport then
    exports.ox_target:addGlobalVehicle({
        targetLockOption,
        targetLockpickOption
    })
end

local function flashVehicleLights(vehicle)
    SetVehicleLights(vehicle, 2)
    Wait(200)
    SetVehicleLights(vehicle, 0)
    Wait(150)
    SetVehicleLights(vehicle, 2)
    Wait(500)
    SetVehicleLights(vehicle, 0)
end

local function playVehicleHorn(vehicle)
    StartVehicleHorn(vehicle, 200, "HELDDOWN", false)
    Wait(300)
    StartVehicleHorn(vehicle, 150, "HELDDOWN", false)
end

function ToggleLock(entity)
    local vehicle
    local ped = PlayerPedId()
    local x, y, z = table.unpack(GetEntityCoords(ped))

    if not entity then
        if IsPedInAnyVehicle(ped, false) then
            vehicle = GetVehiclePedIsIn(ped, false)
        else
            vehicle = GetClosestVehicle(x, y, z, Config.CheckRadius or 8.0, 0, 71)
        end
    else
        vehicle = entity
    end

    if not DoesEntityExist(vehicle) then
        if Config.Notifications.NoNearbyVehicles then
            sendVehicleNotice(Config.Locale.NoVehicleNearby, 'triangle-exclamation', '#f38ba8')
        end

        return
    end

    local start = GetGameTimer()

    while DoesEntityExist(vehicle) and not NetworkHasControlOfEntity(vehicle) and (GetGameTimer() - start) < 1500 do
        NetworkRequestControlOfEntity(vehicle)
        Wait(0)
    end

    if not DoesEntityExist(vehicle) then return end

    if not NetworkHasControlOfEntity(vehicle) then
        sendVehicleNotice("Couldn't get control of the vehicle yet. Try again.", 'triangle-exclamation', '#f38ba8')
        return
    end

    ESX.TriggerServerCallback('attanos_carlock:getVeh', function(owned)
        if owned then
            local lockStatus = GetVehicleDoorLockStatus(vehicle)

            if lockStatus == 1 then
                SetVehicleDoorsLocked(vehicle, 2)
                ExecuteCommand(Config.CommandOnLock)

                lib.progressCircle({
                    duration = Config.ProgressLength,
                    label = Config.Locale.ProgressLocking,
                    position = 'bottom',
                    useWhileDead = false,
                    canCancel = true,
                    disable = Config.DisableControls,
                    anim = Config.KeyFobAnimation
                })

                if Config.Notifications.Locked then
                    sendVehicleNotice(Config.Locale.NotifyLocked, 'lock', '#f38ba8')
                end

                if Config.Sounds then
                    PlaySoundFromCoord(-1, "PIN_BUTTON", x, y, z, "ATM_SOUNDS", true, 5, false)
                end

                if Config.Lights then
                    flashVehicleLights(vehicle)
                end

            elseif lockStatus == 2 then
                SetVehicleDoorsLocked(vehicle, 1)
                ExecuteCommand(Config.CommandOnUnlock)

                lib.progressCircle({
                    duration = Config.ProgressLength,
                    label = Config.Locale.ProgressUnlocking,
                    position = 'bottom',
                    useWhileDead = false,
                    canCancel = false,
                    disable = Config.DisableControls,
                    anim = Config.KeyFobAnimation
                })

                if Config.Notifications.Unlocked then
                    sendVehicleNotice(Config.Locale.NotifyUnlocked, 'lock-open', '#a6e3a1')
                end

                if Config.Sounds then
                    PlaySoundFromCoord(-1, "PIN_BUTTON", x, y, z, "ATM_SOUNDS", true, 5, false)
                end

                if Config.Horn then
                    playVehicleHorn(vehicle)
                end

                if Config.Lights then
                    flashVehicleLights(vehicle)
                end
            end
        else
            if Config.Notifications.NotYourVehicle then
                sendVehicleNotice(Config.Locale.NotOwned, 'triangle-exclamation', '#f38ba8')
            end
        end
    end, ESX.Math.Trim(GetVehicleNumberPlateText(vehicle)))
end

CreateThread(function()
    while true do
        Wait(0)

        local ped = PlayerPedId()

        if IsPedInAnyVehicle(ped, false) and GetVehicleDoorLockStatus(GetVehiclePedIsIn(ped, false)) == 2 then
            DisableControlAction(0, 75, true)
        else
            EnableControlAction(0, 75, true)
        end
    end
end)

RegisterCommand('carlock', function()
    ToggleLock()
    Wait(300)
end, false)

RegisterKeyMapping('carlock', 'Lock or Unlock your personal vehicle', 'keyboard', 'l')

CreateThread(function()
    while true do
        Wait(400)

        local ped = PlayerPedId()
        local vehicle = GetVehiclePedIsIn(ped, false)

        if vehicle ~= 0 and GetPedInVehicleSeat(vehicle, -1) == ped and Config.RequireKeyToStart then
            local hasKey = hasVehicleKey(vehicle)
            local engineRunning = GetIsVehicleEngineRunning(vehicle)

            if hasKey then
                SetVehicleUndriveable(vehicle, false)
            else
                if engineRunning then
                    SetVehicleUndriveable(vehicle, false)
                else
                    SetVehicleEngineOn(vehicle, false, true, true)
                    SetVehicleUndriveable(vehicle, true)
                end
            end
        end
    end
end)

CreateThread(function()
    while true do
        local sleep = 1000
        local ped = PlayerPedId()
        local vehicle = GetVehiclePedIsIn(ped, false)

        if vehicle ~= 0 and GetPedInVehicleSeat(vehicle, -1) == ped then
            local hasKey = hasVehicleKey(vehicle)
            local engineRunning = GetIsVehicleEngineRunning(vehicle)

            if not hasKey and not isHotwiring and not engineRunning then
                sleep = 0
                lib.showTextUI(Config.Locale.HotwirePrompt)

                if IsControlJustPressed(0, Config.HotwireKey) then
                    doHotwire(vehicle)
                end
            else
                lib.hideTextUI()
            end
        else
            lib.hideTextUI()
        end

        Wait(sleep)
    end
end)

RegisterNetEvent('attanos_carlock:client:useLockpick', function()
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local vehicle = lib.getClosestVehicle(coords, 3.0, false)

    if not vehicle or vehicle == 0 or not DoesEntityExist(vehicle) then
        sendVehicleNotice(Config.Locale.NoVehicleNearby, 'triangle-exclamation', '#f38ba8')
        return
    end

    doLockpick(vehicle)
end)

CreateThread(function()
    while true do
        Wait(0)

        local ped = PlayerPedId()

        if IsPedInAnyVehicle(ped, false) then
            local vehicle = GetVehiclePedIsIn(ped, false)

            if GetPedInVehicleSeat(vehicle, -1) == ped then
                if IsControlPressed(0, 36) and IsControlJustPressed(0, 73) then
                    local engineRunning = GetIsVehicleEngineRunning(vehicle)
                    local hasKey = hasVehicleKey(vehicle)

                    if engineRunning then
                        SetVehicleEngineOn(vehicle, false, true, true)
                    else
                        if hasKey then
                            SetVehicleEngineOn(vehicle, true, true, false)
                        else
                            sendVehicleNotice("You don't have the keys.", 'triangle-exclamation', '#f38ba8')
                        end
                    end
                end
            end
        end
    end
end)

local function getVehicleSeatData(vehicle)
    local ped = PlayerPedId()
    local currentSeat = nil
    local seats = {}

    local maxPassengers = GetVehicleMaxNumberOfPassengers(vehicle)

    for seat = -1, maxPassengers - 1 do
        local exists = true

        if seat > 1 then
            local boneName = nil

            if seat == 2 then boneName = 'seat_dside_r' end
            if seat == 3 then boneName = 'seat_pside_r' end
            if seat == 4 then boneName = 'seat_dside_r1' end
            if seat == 5 then boneName = 'seat_pside_r1' end
            if seat == 6 then boneName = 'seat_dside_r2' end
            if seat == 7 then boneName = 'seat_pside_r2' end

            if boneName and GetEntityBoneIndexByName(vehicle, boneName) == -1 then
                exists = false
            end
        end

        if exists then
            if GetPedInVehicleSeat(vehicle, seat) == ped then
                currentSeat = seat
            end

            seats[#seats + 1] = {
                id = seat,
                label = tostring(#seats + 1)
            }
        end
    end

    return seats, currentSeat
end

RegisterCommand('givekey', function()
    local ped = PlayerPedId()
    local myCoords = GetEntityCoords(ped)

    local closestPlayer = nil
    local closestDistance = 3.0

    for _, player in ipairs(GetActivePlayers()) do
        local targetPed = GetPlayerPed(player)

        if targetPed ~= ped then
            local targetCoords = GetEntityCoords(targetPed)
            local dist = #(myCoords - targetCoords)

            if dist < closestDistance then
                closestDistance = dist
                closestPlayer = GetPlayerServerId(player)
            end
        end
    end

    if not closestPlayer then
        sendVehicleNotice("No nearby player found.", 'triangle-exclamation', '#f38ba8')
        return
    end

    local vehicle = 0

    if IsPedInAnyVehicle(ped, false) then
        vehicle = GetVehiclePedIsIn(ped, false)
    else
        vehicle = GetClosestVehicle(myCoords.x, myCoords.y, myCoords.z, 5.0, 0, 71)
    end

    if not vehicle or vehicle == 0 or not DoesEntityExist(vehicle) then
        sendVehicleNotice("No nearby vehicle found.", 'triangle-exclamation', '#f38ba8')
        return
    end

    local plate = GetVehicleNumberPlateText(vehicle)

    if not plate or plate == '' then
        sendVehicleNotice("Could not find vehicle plate.", 'triangle-exclamation', '#f38ba8')
        return
    end

    TriggerServerEvent('attanos_carlock:server:giveKeyToNearest', closestPlayer, plate)
end, false)

local vehicleMenuOpen = false

local function openVehicleMenuNUI()
    local ped = PlayerPedId()

    if not IsPedInAnyVehicle(ped, false) then
        sendVehicleNotice("You must be inside a vehicle.", 'triangle-exclamation', '#f38ba8')
        return
    end

    vehicleMenuOpen = true
    SetNuiFocus(true, true)

    local seats, currentSeat = getVehicleSeatData(GetVehiclePedIsIn(ped, false))

    SendNUIMessage({
        action = 'openVehicleMenu',
        state = {
            seats = seats,
            currentSeat = currentSeat
        }
    })
end

local function closeVehicleMenu()
    vehicleMenuOpen = false
    SetNuiFocus(false, false)

    SendNUIMessage({
        action = 'closeVehicleMenu'
    })
end

RegisterNUICallback('closeMenu', function(_, cb)
    closeVehicleMenu()
    cb('ok')
end)

RegisterNUICallback('menuAction', function(data, cb)
    local ped = PlayerPedId()
    local vehicle = GetVehiclePedIsIn(ped, false)

    if vehicle == 0 then
        cb('ok')
        return
    end

    if data.action == 'lockToggle' then
        ToggleLock(vehicle)

    elseif data.action == 'seat' then
        SetPedConfigFlag(ped, 184, false)
        antiShuffleApplied = false
        antiShuffleTimer = GetGameTimer() + 1000
        SetPedIntoVehicle(ped, vehicle, tonumber(data.seat))

    elseif data.action == 'door' then
        local door = tonumber(data.door)

        if GetVehicleDoorAngleRatio(vehicle, door) > 0.0 then
            SetVehicleDoorShut(vehicle, door, false)
        else
            SetVehicleDoorOpen(vehicle, door, false, false)
        end

    elseif data.action == 'window' then
        local window = tonumber(data.window)
        RollDownWindow(vehicle, window)

    elseif data.action == 'engineToggle' then
        local running = GetIsVehicleEngineRunning(vehicle)

        if running then
            SetVehicleEngineOn(vehicle, false, true, true)
        else
            if hasVehicleKey(vehicle) then
                SetVehicleEngineOn(vehicle, true, true, false)
                SetVehicleUndriveable(vehicle, false)
            else
                sendVehicleNotice("You don't have the keys. Hotwire the vehicle first.", 'triangle-exclamation', '#f38ba8')
            end
        end

    elseif data.action == 'lights' then
        if data.mode == 'off' then
            SetVehicleLights(vehicle, 1)
        elseif data.mode == 'normal' then
            SetVehicleLights(vehicle, 3)
        elseif data.mode == 'full' then
            SetVehicleLights(vehicle, 3)
            SetVehicleFullbeam(vehicle, true)
        end

    elseif data.action == 'interiorLight' then
        SetVehicleInteriorlight(vehicle, true)
    end

    cb('ok')
end)

RegisterCommand('vehiclecontrols', function()
    openVehicleMenuNUI()
end, false)

RegisterKeyMapping('vehiclecontrols', 'Open vehicle menu', 'keyboard', 'F7')

CreateThread(function()
    while true do
        Wait(100)

        local ped = PlayerPedId()

        if IsPedInAnyVehicle(ped, false) then
            local vehicle = GetVehiclePedIsIn(ped, false)

            if GetPedInVehicleSeat(vehicle, 0) == ped and GetIsTaskActive(ped, 165) then
                SetPedIntoVehicle(ped, vehicle, 0)
            end
        else
            Wait(400)
        end
    end
end)

local checkedNpcVehicles = {}

CreateThread(function()
    while true do
        Wait(2000)

        local ped = PlayerPedId()
        local coords = GetEntityCoords(ped)

        for _, vehicle in ipairs(GetGamePool('CVehicle')) do
            if DoesEntityExist(vehicle) then
                local dist = #(coords - GetEntityCoords(vehicle))

                if dist <= 75.0 then
                    local vehId = vehicle

                    if not checkedNpcVehicles[vehId] then
                        local driver = GetPedInVehicleSeat(vehicle, -1)
                        local engineRunning = GetIsVehicleEngineRunning(vehicle)

                        if driver == 0 and not engineRunning then
                            local occupied = false

                            for seat = 0, GetVehicleMaxNumberOfPassengers(vehicle) - 1 do
                                if GetPedInVehicleSeat(vehicle, seat) ~= 0 then
                                    occupied = true
                                    break
                                end
                            end

                            if not occupied then
                                checkedNpcVehicles[vehId] = true

                                if not hasVehicleKey(vehicle) then
                                    SetVehicleDoorsLocked(vehicle, 2)
                                    SetVehicleDoorsLockedForAllPlayers(vehicle, true)
                                    SetVehicleDoorsLockedForPlayer(vehicle, PlayerId(), true)
                                end
                            end
                        end
                    end
                end
            end
        end
    end
end)
