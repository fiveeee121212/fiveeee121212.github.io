MC = MC or {}
MC.Players = {}

local RESOURCE_NAME = GetCurrentResourceName()

local function getPlayerLicense(source)
    for _, identifier in ipairs(GetPlayerIdentifiers(source)) do
        if identifier:find((Config.IdentifierField or 'license') .. ':', 1, true) == 1 then
            return identifier
        end
    end

    return nil
end

local function playerState(source)
    MC.Players[source] = MC.Players[source] or {
        selectedCharacterId = nil,
        rateLimit = {}
    }

    return MC.Players[source]
end

local function canUseAction(source, action, interval)
    local state = playerState(source)
    local now = GetGameTimer()
    local last = state.rateLimit[action] or 0

    if now - last < interval then
        return false
    end

    state.rateLimit[action] = now
    return true
end

local function findAvailableSlot(characters)
    local used = {}
    for _, character in ipairs(characters) do
        used[character.slot] = true
    end

    for slot = 1, Config.MaxSlotsPerLicense do
        if not used[slot] then
            return slot
        end
    end

    return nil
end

local function getSelectionBucket(source)
    return Config.Selection.RoutingBucket + source
end

CreateThread(function()
    MC.Framework.Init()
end)

lib.callback.register('mc_multicharacter:getCharacters', function(source)
    local license = getPlayerLicense(source)
    if not license then
        return {
            ok = false,
            error = 'license_introuvable'
        }
    end

    local characters = MC.DB.GetCharacters(license)
    return {
        ok = true,
        characters = characters,
        maxSlots = Config.MaxSlotsPerLicense
    }
end)

lib.callback.register('mc_multicharacter:createCharacter', function(source, payload)
    if not canUseAction(source, 'createCharacter', 800) then
        return { ok = false, error = 'action_trop_rapide' }
    end

    local license = getPlayerLicense(source)
    if not license then
        return { ok = false, error = 'license_introuvable' }
    end

    local valid, reason = MC.Utils.ValidatePayload(payload)
    if not valid then
        return { ok = false, error = reason }
    end

    local existing = MC.DB.GetCharacters(license)
    if #existing >= Config.MaxSlotsPerLicense then
        return { ok = false, error = 'slots_atteints' }
    end

    local preferredSlot = tonumber(payload.slot)
    local occupiedSlots = {}
    for _, char in ipairs(existing) do
        occupiedSlots[char.slot] = true
    end

    local freeSlot = nil
    if preferredSlot and preferredSlot >= 1 and preferredSlot <= Config.MaxSlotsPerLicense and not occupiedSlots[preferredSlot] then
        freeSlot = preferredSlot
    else
        freeSlot = findAvailableSlot(existing)
    end

    if not freeSlot then
        return { ok = false, error = 'aucun_slot_disponible' }
    end

    local characterId = MC.DB.CreateCharacter(license, freeSlot, payload)
    if not characterId then
        return { ok = false, error = 'creation_echouee' }
    end

    local created = MC.DB.GetCharacterById(license, characterId)
    return {
        ok = true,
        character = created
    }
end)

lib.callback.register('mc_multicharacter:deleteCharacter', function(source, characterId)
    if not canUseAction(source, 'deleteCharacter', 600) then
        return { ok = false, error = 'action_trop_rapide' }
    end

    if type(characterId) ~= 'string' or characterId == '' then
        return { ok = false, error = 'character_id_invalide' }
    end

    local license = getPlayerLicense(source)
    if not license then
        return { ok = false, error = 'license_introuvable' }
    end

    local deleted = MC.DB.DeleteCharacter(license, characterId)
    return {
        ok = deleted,
        error = deleted and nil or 'suppression_echouee'
    }
end)

lib.callback.register('mc_multicharacter:selectCharacter', function(source, characterId)
    if not canUseAction(source, 'selectCharacter', 450) then
        return { ok = false, error = 'action_trop_rapide' }
    end

    if type(characterId) ~= 'string' or characterId == '' then
        return { ok = false, error = 'character_id_invalide' }
    end

    local license = getPlayerLicense(source)
    if not license then
        return { ok = false, error = 'license_introuvable' }
    end

    local character = MC.DB.GetCharacterById(license, characterId)
    if not character then
        return { ok = false, error = 'personnage_introuvable' }
    end

    local state = playerState(source)
    state.selectedCharacterId = characterId

    local applied = MC.Framework.ApplyCharacter(source, character)
    if not applied then
        return { ok = false, error = 'framework_apply_failed' }
    end

    SetPlayerRoutingBucket(source, 0)

    return {
        ok = true,
        character = character
    }
end)

RegisterNetEvent('mc_multicharacter:enterSelection', function()
    local source = source
    local bucket = getSelectionBucket(source)
    SetPlayerRoutingBucket(source, bucket)
end)

RegisterNetEvent('mc_multicharacter:saveLastPosition', function(position)
    local source = source
    local state = playerState(source)

    if not state.selectedCharacterId then
        return
    end

    local license = getPlayerLicense(source)
    if not license then
        return
    end

    MC.DB.UpdateLastPosition(license, state.selectedCharacterId, position)
end)

AddEventHandler('playerDropped', function()
    local source = source
    MC.Players[source] = nil
end)

RegisterCommand('mc_reloadchars', function(source)
    if source ~= 0 then
        return
    end

    print(('[%s] Etat des joueurs chargé: %s'):format(RESOURCE_NAME, json.encode(MC.Players)))
end, true)
