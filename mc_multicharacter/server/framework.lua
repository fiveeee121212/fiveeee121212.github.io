MC = MC or {}
MC.Framework = {}

local activeFramework = nil
local ESX, QBCore

local function detectFramework()
    if Config.Framework == 'esx' then
        return 'esx'
    end

    if Config.Framework == 'qb' then
        return 'qb'
    end

    if GetResourceState('qb-core') == 'started' then
        return 'qb'
    end

    if GetResourceState('es_extended') == 'started' then
        return 'esx'
    end

    return 'standalone'
end

function MC.Framework.Init()
    activeFramework = detectFramework()
    MC.Utils.Debug(('Framework détecté: %s'):format(activeFramework))

    if activeFramework == 'esx' then
        ESX = exports['es_extended']:getSharedObject()
    elseif activeFramework == 'qb' then
        QBCore = exports['qb-core']:GetCoreObject()
    end
end

function MC.Framework.GetType()
    return activeFramework
end

function MC.Framework.ApplyCharacter(source, character)
    if activeFramework == 'esx' then
        TriggerEvent('esx:onPlayerJoined', source, character.characterId)
        return true
    end

    if activeFramework == 'qb' then
        if not QBCore then
            return false
        end

        local Player = QBCore.Functions.GetPlayer(source)
        if Player and Player.PlayerData then
            Player.Functions.SetMetaData('mc_characterId', character.characterId)
            Player.Functions.SetMetaData('mc_identity', {
                firstName = character.firstName,
                lastName = character.lastName,
                birthDate = character.birthDate,
                sex = character.sex,
                nationality = character.nationality
            })
        end

        TriggerClientEvent('QBCore:Client:OnPlayerLoaded', source)
        return true
    end

    return true
end
