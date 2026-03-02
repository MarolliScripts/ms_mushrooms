fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'marolliscripts.pl'
description 'Simple mushroom drug script for ESX'
version '1.0.0'

shared_scripts {
    '@ox_lib/init.lua',
    'shared/config.lua',
    'locales/pl.lua',
    'locales/en.lua',
    'shared/locale.lua'
}

client_scripts {
    'client/client.lua'
}

server_scripts {
    'server/server.lua'
}
