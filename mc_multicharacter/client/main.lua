local selectionOpen = false
local selectionCam = nil
local selectedCharacter = nil
local hasInitialized = false

local function notify(description, type)
    lib.notify({
        title = 'Multicharacter',
        description = description,
        type = type or 'inform'
    })
end

local function setPreviewState(enabled)
    local ped = PlayerPedId()

    FreezeEntityPosition(ped, enabled)
    SetEntityInvincible(ped, enabled)
    SetEntityVisible(ped, not enabled, false)
    SetEntityCollision(ped, not enabled, not enabled)

    if enabled then
        SetEntityCoordsNoOffset(ped, Config.Selection.SpawnHidden.x, Config.Selection.SpawnHidden.y, Config.Selection.SpawnHidden.z, false, false, false)
        SetEntityHeading(ped, Config.Selection.SpawnHidden.w)
    end
end

local function createSelectionCam()
    if DoesCamExist(selectionCam) then
        DestroyCam(selectionCam, true)
    end

    selectionCam = CreateCamWithParams(
        'DEFAULT_SCRIPTED_CAMERA',
        Config.Selection.Camera.position.x,
        Config.Selection.Camera.position.y,
        Config.Selection.Camera.position.z,
        0.0,
        0.0,
        0.0,
        Config.Selection.Camera.fov,
        true,
        2
    )

    PointCamAtCoord(selectionCam, Config.Selection.Camera.lookAt.x, Config.Selection.Camera.lookAt.y, Config.Selection.Camera.lookAt.z)
    SetCamActive(selectionCam, true)
    RenderScriptCams(true, true, 700, true, true)
end

local function destroySelectionCam()
    if DoesCamExist(selectionCam) then
        RenderScriptCams(false, true, 400, true, true)
        DestroyCam(selectionCam, false)
        selectionCam = nil
    end
end

local function setNuiVisible(visible, payload)
    SetNuiFocus(visible, visible)
    SendNUIMessage({
        action = visible and 'open' or 'close',
        payload = payload or {}
    })
end

local function refreshCharacters()
    local result = lib.callback.await('mc_multicharacter:getCharacters', false)
    if not result or not result.ok then
        notify('Impossible de charger tes personnages.', 'error')
        return nil
    end

    return result
end

local function openSelection()
    if selectionOpen then
        return
    end

    local data = refreshCharacters()
    if not data then
        return
    end

    selectionOpen = true
    TriggerServerEvent('mc_multicharacter:enterSelection')
    setPreviewState(true)
    createSelectionCam()
    ClearTimecycleModifier()
    SetWeatherTypeNowPersist(Config.Selection.Weather)
    SetTimecycleModifier(Config.Selection.Timecycle)

    setNuiVisible(true, {
        maxSlots = data.maxSlots,
        characters = data.characters
    })
end

local function spawnSelectedCharacter(character)
    if not character then
        return
    end

    local position = character.position or {}
    local x = tonumber(position.x) or Config.DefaultSpawn.x
    local y = tonumber(position.y) or Config.DefaultSpawn.y
    local z = tonumber(position.z) or Config.DefaultSpawn.z
    local h = tonumber(position.h) or Config.DefaultSpawn.w

    local ped = PlayerPedId()
    RequestCollisionAtCoord(x, y, z)
    SetEntityCoordsNoOffset(ped, x, y, z, false, false, false)
    SetEntityHeading(ped, h)
    FreezeEntityPosition(ped, false)
    SetEntityVisible(ped, true, false)
    SetEntityInvincible(ped, false)
    SetEntityCollision(ped, true, true)

    ClearTimecycleModifier()
    destroySelectionCam()
    setNuiVisible(false)

    selectionOpen = false
    selectedCharacter = character
    notify(('Connexion avec %s %s'):format(character.firstName, character.lastName), 'success')
end

RegisterNUICallback('mc:createCharacter', function(data, cb)
    local result = lib.callback.await('mc_multicharacter:createCharacter', false, data)
    cb(result or { ok = false, error = 'aucune_reponse_serveur' })
end)

RegisterNUICallback('mc:deleteCharacter', function(data, cb)
    local characterId = data and data.characterId
    local result = lib.callback.await('mc_multicharacter:deleteCharacter', false, characterId)
    cb(result or { ok = false, error = 'aucune_reponse_serveur' })
end)

RegisterNUICallback('mc:selectCharacter', function(data, cb)
    local characterId = data and data.characterId
    local result = lib.callback.await('mc_multicharacter:selectCharacter', false, characterId)
    if result and result.ok then
        spawnSelectedCharacter(result.character)
    end

    cb(result or { ok = false, error = 'aucune_reponse_serveur' })
end)

RegisterNUICallback('mc:refresh', function(_, cb)
    local result = refreshCharacters()
    cb(result or { ok = false, error = 'refresh_failed' })
end)

RegisterNUICallback('mc:closeAttempt', function(_, cb)
    notify('Tu dois sélectionner un personnage.', 'warning')
    cb({ ok = false })
end)

CreateThread(function()
    while true do
        if selectionOpen then
            DisableAllControlActions(0)
            EnableControlAction(0, 1, true)
            EnableControlAction(0, 2, true)
            EnableControlAction(0, 245, true)
        end
        Wait(0)
    end
end)

CreateThread(function()
    while true do
        Wait(10000)

        if selectedCharacter then
            local ped = PlayerPedId()
            if DoesEntityExist(ped) then
                local coords = GetEntityCoords(ped)
                local heading = GetEntityHeading(ped)
                TriggerServerEvent('mc_multicharacter:saveLastPosition', {
                    x = coords.x,
                    y = coords.y,
                    z = coords.z,
                    h = heading
                })
            end
        end
    end
end)

AddEventHandler('onClientResourceStart', function(resource)
    if resource ~= GetCurrentResourceName() then
        return
    end

    if hasInitialized then
        return
    end

    hasInitialized = true
    Wait(800)
    openSelection()
end)

RegisterCommand('multicharacter', function()
    openSelection()
end, false)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then
        return
    end

    destroySelectionCam()
    SetNuiFocus(false, false)
    ClearTimecycleModifier()
end)
