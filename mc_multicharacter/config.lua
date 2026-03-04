Config = {}

Config.Debug = false
Config.Locale = 'fr'

Config.Framework = 'auto' -- auto | esx | qb

Config.MaxSlotsPerLicense = 6

Config.CharacterIdPrefix = 'char'
Config.IdentifierField = 'license'

Config.Selection = {
    RoutingBucket = 997,
    SpawnHidden = vec4(-1037.02, -2737.93, 20.17, 327.15),
    Camera = {
        position = vec3(-1032.45, -2734.40, 22.50),
        lookAt = vec3(-1037.02, -2737.93, 20.45),
        fov = 52.0
    },
    Weather = 'CLEAR',
    Timecycle = 'scanline_cam_cheap'
}

Config.DefaultSpawn = vec4(-1037.02, -2737.93, 20.17, 327.15)

Config.NameRules = {
    MinLength = 2,
    MaxLength = 18,
    Pattern = "^[%a%-%s']+$"
}

Config.BirthRules = {
    MinYear = 1940,
    MaxYear = 2010
}

Config.JobDefaults = {
    name = 'unemployed',
    grade = 0
}

Config.MoneyDefaults = {
    cash = 500,
    bank = 2500
}

Config.RequiredFields = {
    'firstName',
    'lastName',
    'sex',
    'birthDate',
    'nationality'
}

Config.AllowedSexValues = {
    m = true,
    f = true,
    x = true
}
