fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'Attano Scripts'
description 'Advanced ESX vehicle lock, hotwire, and key sharing system'
version '1.0.0'

shared_scripts {
    '@ox_lib/init.lua',
    'config/*.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/*.lua'
}

client_scripts {
    'client/*.lua'
}

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/style.css',
    'html/script.js'
}

dependencies {
    'ox_lib',
    'ox_target',
    'ox_inventory',
    'oxmysql',
    'es_extended'
}
