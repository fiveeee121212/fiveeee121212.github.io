MC = MC or {}
MC.Utils = {}

local function isNilOrEmpty(value)
    return value == nil or value == ''
end

function MC.Utils.Debug(message, payload)
    if not Config.Debug then
        return
    end

    if payload ~= nil then
        print(('[mc_multicharacter] %s %s'):format(message, json.encode(payload)))
        return
    end

    print(('[mc_multicharacter] %s'):format(message))
end

function MC.Utils.Trim(value)
    if type(value) ~= 'string' then
        return value
    end

    return value:match('^%s*(.-)%s*$')
end

function MC.Utils.SanitizeName(value)
    if type(value) ~= 'string' then
        return nil
    end

    value = MC.Utils.Trim(value)
    if isNilOrEmpty(value) then
        return nil
    end

    if #value < Config.NameRules.MinLength or #value > Config.NameRules.MaxLength then
        return nil
    end

    if not value:match(Config.NameRules.Pattern) then
        return nil
    end

    return value
end

function MC.Utils.NormalizeSex(value)
    if type(value) ~= 'string' then
        return nil
    end

    value = value:lower()
    if Config.AllowedSexValues[value] then
        return value
    end

    return nil
end

function MC.Utils.ValidateBirthDate(value)
    if type(value) ~= 'string' then
        return false
    end

    local y, m, d = value:match('^(%d%d%d%d)%-(%d%d)%-(%d%d)$')
    y, m, d = tonumber(y), tonumber(m), tonumber(d)
    if not y or not m or not d then
        return false
    end

    if y < Config.BirthRules.MinYear or y > Config.BirthRules.MaxYear then
        return false
    end

    if m < 1 or m > 12 or d < 1 or d > 31 then
        return false
    end

    return true
end

function MC.Utils.ValidatePayload(payload)
    if type(payload) ~= 'table' then
        return false, 'payload_invalide'
    end

    for _, field in ipairs(Config.RequiredFields) do
        if isNilOrEmpty(payload[field]) then
            return false, ('champ_manquant:%s'):format(field)
        end
    end

    local firstName = MC.Utils.SanitizeName(payload.firstName)
    local lastName = MC.Utils.SanitizeName(payload.lastName)
    local sex = MC.Utils.NormalizeSex(payload.sex)
    local birthDate = payload.birthDate
    local nationality = MC.Utils.Trim(payload.nationality)

    if not firstName then
        return false, 'prenom_invalide'
    end

    if not lastName then
        return false, 'nom_invalide'
    end

    if not sex then
        return false, 'sexe_invalide'
    end

    if not MC.Utils.ValidateBirthDate(birthDate) then
        return false, 'date_naissance_invalide'
    end

    if not nationality or #nationality < 2 or #nationality > 32 then
        return false, 'nationalite_invalide'
    end

    payload.firstName = firstName
    payload.lastName = lastName
    payload.sex = sex
    payload.birthDate = birthDate
    payload.nationality = nationality

    return true
end

function MC.Utils.SafeDecode(value, fallback)
    if type(value) ~= 'string' or value == '' then
        return fallback or {}
    end

    local ok, parsed = pcall(json.decode, value)
    if not ok or type(parsed) ~= 'table' then
        return fallback or {}
    end

    return parsed
end
