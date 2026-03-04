MC = MC or {}
MC.DB = {}

local CHARACTERS_TABLE = 'mc_characters'

local INSERT_QUERY = ([[
    INSERT INTO %s (
        character_id, license, slot, firstname, lastname, sex, birthdate, nationality,
        job, job_grade, money, bank, skin, metadata, pos_x, pos_y, pos_z, heading, created_at, last_seen
    )
    VALUES (
        ?, ?, ?, ?, ?, ?, ?, ?,
        ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, NOW(), NOW()
    )
]]):format(CHARACTERS_TABLE)

local SELECT_QUERY = ([[
    SELECT
        character_id, slot, firstname, lastname, sex, birthdate, nationality,
        job, job_grade, money, bank, skin, metadata, pos_x, pos_y, pos_z, heading, created_at, last_seen
    FROM %s
    WHERE license = ?
    ORDER BY slot ASC
]]):format(CHARACTERS_TABLE)

local SELECT_ONE_QUERY = ([[
    SELECT *
    FROM %s
    WHERE character_id = ? AND license = ?
    LIMIT 1
]]):format(CHARACTERS_TABLE)

local SLOT_COUNT_QUERY = ([[
    SELECT COUNT(*) as amount
    FROM %s
    WHERE license = ?
]]):format(CHARACTERS_TABLE)

local DELETE_QUERY = ([[
    DELETE FROM %s
    WHERE character_id = ? AND license = ?
    LIMIT 1
]]):format(CHARACTERS_TABLE)

local UPDATE_LAST_POS_QUERY = ([[
    UPDATE %s
    SET pos_x = ?, pos_y = ?, pos_z = ?, heading = ?, last_seen = NOW()
    WHERE character_id = ? AND license = ?
    LIMIT 1
]]):format(CHARACTERS_TABLE)

function MC.DB.GetCharacters(license)
    local rows = MySQL.query.await(SELECT_QUERY, { license }) or {}
    local characters = {}

    for _, row in ipairs(rows) do
        characters[#characters + 1] = {
            characterId = row.character_id,
            slot = row.slot,
            firstName = row.firstname,
            lastName = row.lastname,
            sex = row.sex,
            birthDate = row.birthdate,
            nationality = row.nationality,
            job = row.job,
            jobGrade = row.job_grade,
            money = row.money,
            bank = row.bank,
            skin = MC.Utils.SafeDecode(row.skin, {}),
            metadata = MC.Utils.SafeDecode(row.metadata, {}),
            position = {
                x = row.pos_x,
                y = row.pos_y,
                z = row.pos_z,
                h = row.heading
            },
            createdAt = row.created_at,
            lastSeen = row.last_seen
        }
    end

    return characters
end

function MC.DB.GetCharacterById(license, characterId)
    local row = MySQL.single.await(SELECT_ONE_QUERY, { characterId, license })
    if not row then
        return nil
    end

    return {
        characterId = row.character_id,
        slot = row.slot,
        firstName = row.firstname,
        lastName = row.lastname,
        sex = row.sex,
        birthDate = row.birthdate,
        nationality = row.nationality,
        job = row.job,
        jobGrade = row.job_grade,
        money = row.money,
        bank = row.bank,
        skin = MC.Utils.SafeDecode(row.skin, {}),
        metadata = MC.Utils.SafeDecode(row.metadata, {}),
        position = {
            x = row.pos_x,
            y = row.pos_y,
            z = row.pos_z,
            h = row.heading
        }
    }
end

function MC.DB.GetUsedSlotCount(license)
    local row = MySQL.single.await(SLOT_COUNT_QUERY, { license })
    return row and row.amount or 0
end

function MC.DB.CreateCharacter(license, slot, payload)
    local characterId = ('%s:%s:%s'):format(Config.CharacterIdPrefix, license, slot)

    local ok = MySQL.insert.await(INSERT_QUERY, {
        characterId, license, slot, payload.firstName, payload.lastName, payload.sex, payload.birthDate, payload.nationality,
        Config.JobDefaults.name, Config.JobDefaults.grade, Config.MoneyDefaults.cash, Config.MoneyDefaults.bank,
        json.encode({}), json.encode({}),
        Config.DefaultSpawn.x, Config.DefaultSpawn.y, Config.DefaultSpawn.z, Config.DefaultSpawn.w
    })

    if not ok then
        return nil
    end

    return characterId
end

function MC.DB.DeleteCharacter(license, characterId)
    local changed = MySQL.update.await(DELETE_QUERY, { characterId, license })
    return changed and changed > 0
end

function MC.DB.UpdateLastPosition(license, characterId, position)
    if not position then
        return false
    end

    local x = tonumber(position.x)
    local y = tonumber(position.y)
    local z = tonumber(position.z)
    local h = tonumber(position.h or position.heading or 0.0)

    if not x or not y or not z or not h then
        return false
    end

    local changed = MySQL.update.await(UPDATE_LAST_POS_QUERY, { x, y, z, h, characterId, license })
    return changed and changed > 0
end
