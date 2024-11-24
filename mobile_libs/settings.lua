local fs = love.filesystem

local CONFIG_FILE = '/mobile/touch_config.txt'
local _settings = fs.read(CONFIG_FILE) ~= nil and FILE.read(CONFIG_FILE) or {}
local _defaultSettings = {
    firstTime = true,
    __default__={
        {type='button',x=     70,y=280,key=           'up',r=45,iconSize=60,alpha=0.4},
        {type='button',x=     70,y=430,key=         'down',r=45,iconSize=60,alpha=0.4},
        {type='button',x=     -5,y=355,key=         'left',r=45,iconSize=60,alpha=0.4},
        {type='button',x=    145,y=355,key=        'right',r=45,iconSize=60,alpha=0.4},
        {type='button',x=640- -5,y=355,key=  'rotate_left',r=45,iconSize=60,alpha=0.4},
        {type='button',x=640-145,y=355,key= 'rotate_left2',r=45,iconSize=60,alpha=0.4},
        {type='button',x=640- 70,y=430,key= 'rotate_right',r=45,iconSize=60,alpha=0.4},
        {type='button',x=640- 70,y=280,key='rotate_right2',r=45,iconSize=60,alpha=0.4},
        {type='button',x=320,    y=420,key=      'restart',r=35,iconSize=60,alpha=0.4},
    },

    ---@type table<string,string>[]
    bind = {},
}

return setmetatable(
    {__default__ = _defaultSettings},
    {
        __index = function(_, k)
            if _settings[k] == nil then
                _settings[k] = _defaultSettings[k]
                FILE.write(CONFIG_FILE,_settings)
            end
            return _settings[k]
        end,
        __newindex = function(_, k, v)
            _settings[k] = v
            FILE.write(CONFIG_FILE,_settings)
        end
    }
)