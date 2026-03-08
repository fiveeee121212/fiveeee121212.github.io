fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'mc_multicharacter'
author 'GPT-5.3 Codex'
description 'Script multicharacter complet avec NUI et MySQL'
version '1.0.0'

ui_page 'web/index.html'

files {
    'web/index.html',
    'web/style.css',
    'web/app.js'
}

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua',
    'shared/utils.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/db.lua',
    'server/framework.lua',
    'server/main.lua'
}

client_scripts {
    'client/main.lua'
}
