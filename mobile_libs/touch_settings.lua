local fs = love.filesystem
local FILE=require'mobile_libs.file''binser'

local CONFIG_FILE = 'mobile/touch_config.txt'
love.filesystem.createDirectory('mobile')
local _settings = fs.read(CONFIG_FILE) ~= nil and FILE.read(CONFIG_FILE) or {}
local _defaultSettings = {
    firstTime = true,

    ---@type table<string,string>[]
    bind = {
        {
            {type='button',x=  1 *  70 + 120,y =  1 * 70 + 120, r = 30, key=            'up',iconSize=80},
            {type='button',x=  2 *  70 + 120,y =  1 * 70 + 120, r = 30, key=          'down',iconSize=80},
            {type='button',x=  3 *  70 + 120,y =  1 * 70 + 120, r = 30, key=          'left',iconSize=80},
            {type='button',x=  4 *  70 + 120,y =  1 * 70 + 120, r = 30, key=         'right',iconSize=80},
            {type='button',x=  5 *  70 + 120,y =  1 * 70 + 120, r = 30, key=          'hold',iconSize=80},

            {type='button',x=  1 *  70 + 120,y =  2 * 70 + 120, r = 30, key=   'rotate_left',iconSize=80},
            {type='button',x=  2 *  70 + 120,y =  2 * 70 + 120, r = 30, key=  'rotate_left2',iconSize=80},
            {type='button',x=  3 *  70 + 120,y =  2 * 70 + 120, r = 30, key=  'rotate_right',iconSize=80},
            {type='button',x=  4 *  70 + 120,y =  2 * 70 + 120, r = 30, key= 'rotate_right2',iconSize=80},
            {type='button',x=  5 *  70 + 120,y =  2 * 70 + 120, r = 30, key=    'rotate_180',iconSize=80},

            {type='button',x=  1 *  70 + 120,y =  3 * 70 + 120, r = 30, key=   'menu_decide',iconSize=80},
            -- {type='button',x=  2 *  70 + 120,y =  3 * 70 + 120, r = 30, key=             '2',iconSize=80},
            -- {type='button',x=  3 *  70 + 120,y =  3 * 70 + 120, r = 30, key=             '3',iconSize=80},
            -- {type='button',x=  4 *  70 + 120,y =  3 * 70 + 120, r = 30, key=             '4',iconSize=80},
            {type='button',x=  5 *  70 + 120,y =  3 * 70 + 120, r = 30, key=     'menu_back',iconSize=80},

            {type='button',x=  1 *  70 + 120,y =  4 * 70 + 120, r = 30, key=        'delete',iconSize=80},
            {type='button',x=  2 *  70 + 120,y =  4 * 70 + 120, r = 30, key=           'tab',iconSize=80},
            {type='button',x=  3 *  70 + 120,y =  4 * 70 + 120, r = 30, key=         'retry',iconSize=80},
            {type='button',x=  4 *  70 + 120,y =  4 * 70 + 120, r = 30, key=    'align_view',iconSize=80},
            {type='button',x=  5 *  70 + 120,y =  4 * 70 + 120, r = 30, key='touch_settings',iconSize=80},

        }, -- 1
        {
            {type='button',x=     70,y=280,key=           'up',r=45,iconSize=60,alpha=0.4,shape='circle'},
            {type='button',x=     70,y=430,key=         'down',r=45,iconSize=60,alpha=0.4,shape='circle'},
            {type='button',x=     -5,y=355,key=         'left',r=45,iconSize=60,alpha=0.4,shape='circle'},
            {type='button',x=    145,y=355,key=        'right',r=45,iconSize=60,alpha=0.4,shape='circle'},
            {type='button',x=640- -5,y=355,key=  'rotate_left',r=45,iconSize=60,alpha=0.4,shape='circle'},
            {type='button',x=640-145,y=355,key= 'rotate_left2',r=45,iconSize=60,alpha=0.4,shape='circle'},
            {type='button',x=640- 70,y=430,key= 'rotate_right',r=45,iconSize=60,alpha=0.4,shape='circle'},
            {type='button',x=640- 70,y=280,key='rotate_right2',r=45,iconSize=60,alpha=0.4,shape='circle'},
            {type='button',x=320,    y=420,key=        'retry',r=35,iconSize=60,alpha=0.4,shape='circle'},
        }  -- 2
    },
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