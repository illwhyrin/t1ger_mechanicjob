----------------------- [ MenuV ] -----------------------
--Converted by JericoFX#3512 and Thanks for the awesome work of Prototype Designs for the fixes
----------------------- [ MenuV ] -----------------------
fx_version 'adamant'
game 'gta5'


client_scripts {
    '@menuv/menuv.lua',
    'language.lua',
	'config.lua',
	'client/*.lua'
}
server_scripts {
    'language.lua',
    'config.lua',
    'server/*.lua',
}

dependencies {
    'menuv'
}