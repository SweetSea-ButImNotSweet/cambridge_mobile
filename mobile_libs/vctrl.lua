local gc_newQuad=love.graphics.newQuad

---Get distance between two points
---@param x1 number
---@param y1 number
---@param x2 number
---@param y2 number
---@return number
local function math_distance(x1,y1,x2,y2)
    return ((x1-x2)^2+(y1-y2)^2)^.5
end

local function mDrawQ(obj,quad,x,y,a,k)
    local _,_,w,h=quad:getViewport()
    love.graphics.draw(obj,quad,x,y,a,k,nil,w*.5,h*.5)
end

local alternativePfunction={}
local alternativeRfunction={
    touch_settings=function()
        if (
            scene.title ~= 'Game' and
            scene.title ~= TouchConfigScene.title
        ) then
            scene = TouchConfigScene()
        end
        scene:onInputRelease{input="touch_settings", type="virtual"}
    end,
    align_view=function()
        if scene.title ~= TouchConfigScene.title then
            scene:onInputRelease{input="align_view", type="virtual"}
            ALIGN_VIEW_RIGHT = ALIGN_VIEW_RIGHT == 1.4 and 0.5 or math.min(ALIGN_VIEW_RIGHT + 0.5,1.4)
        end
    end
}

local empty_quad=gc_newQuad(1,1,1,1,1,1)
-- A table containing quads used to draw icons for virtual control system.
local virtual_quad=setmetatable((function()
    local t={}
    local w=336
    empty_quad=gc_newQuad(0,0,1,1,5*w,4*w)
    for i,name in next,{
        'left','right','up','down','hold',
        'rotate_left','rotate_left2','rotate_right','rotate_right2','rotate_180',
        'tab','menu_decide','delete','','',
        'retry','align_view','menu_back','','',
    } do if #name>0 then t[name]=gc_newQuad((i-1)%5*w,math.floor((i-1)/5)*w,w,w,5*w,4*w) end end
    return t
end)(),{
    __index=function() return empty_quad end
})
local virtual_texture=love.graphics.newImage('mobile_libs/vctrlTexture.png')


local control_type={}

control_type.button={}
control_type.button.__index=control_type.button
function control_type.button:new(data)
    local data=data or {}
    return setmetatable({
        show=data.show==nil and true or data.show,
        x=data.x or 320,
        y=data.y or 240,
        r=data.r or 80, -- size
        shape=data.shape or 'square',
        key=data.key or 'X',
        iconSize=data.iconSize or 60,
        alpha=data.alpha or 0.75,
        quad=virtual_quad[data.key],
    },self)
end
function control_type.button:export()
    return {
        type = 'button',
        show = self.show,
        x = self.x,
        y = self.y,
        r = self.r,
        shape = self.shape,
        key = self.key,
        iconSize = self.iconSize,
        alpha = self.alpha,
    }
end
function control_type.button:reset()
    self.pressed=false
    self.lastPressTime=-1e99
    self.pressingID=false
end
function control_type.button:press(_,_,id)
    self.pressed=true
    self.lastPressTime=love.timer.getTime()
    self.pressingID=id
    -- love.keypressed(self.key, love.keyboard.getScancodeFromKey(self.key))
    if alternativePfunction[self.key] then
        alternativePfunction[self.key]()
    else
        scene:onInputPress{input=self.key,type="virtual"}
    end
end
function control_type.button:release()
    self.pressed=false
    self.pressingID=false
    -- love.keyreleased(self.key,love.keyboard.getScancodeFromKey(self.key))
    if alternativeRfunction[self.key] then
        alternativeRfunction[self.key]()
    else
        scene:onInputRelease{input=self.key,type="virtual"}
    end
end
function control_type.button:drag(dx,dy)
    self.x,self.y=self.x+dx,self.y+dy
end
function control_type.button:draw(forceAlpha)
    local alpha = forceAlpha or self.alpha
    love.graphics.setLineWidth(4)
    if self.shape=='circle' then
        love.graphics.setColor(0,0,0,alpha)
        love.graphics.circle('fill',self.x,self.y,self.r-4)

        love.graphics.setColor(1,1,1,self.pressed and .5 or 0)
        love.graphics.circle('fill',self.x,self.y,self.r-4)

        love.graphics.setColor(1,1,1,alpha)
        love.graphics.circle('line',self.x,self.y,self.r-2)
    elseif self.shape=='square' then
        love.graphics.setColor(0,0,0,alpha)
        love.graphics.rectangle('fill',self.x-self.r-4,self.y-self.r-4,self.r*2+8,self.r*2+8)

        love.graphics.setColor(1,1,1,self.pressed and .5 or 0)
        love.graphics.rectangle('fill',self.x-self.r-4,self.y-self.r-4,self.r*2+8,self.r*2+8)

        love.graphics.setColor(1,1,1,alpha)
        love.graphics.rectangle('line',self.x-self.r-2,self.y-self.r-2,self.r*2+4,self.r*2+4)
    end
    if self.iconSize>0 and self.quad then
        love.graphics.setColor(1,1,1,alpha)
        local _,_,w,h=self.quad:getViewport()
        mDrawQ(
            virtual_texture,
            self.quad,
            self.x,self.y,0,
            self.iconSize/100*math.min(self.r*2/w,self.r*2/h)
        )
    end
end
function control_type.button:getDistance(x,y)
    if self.shape=='circle' then
        return math_distance(x,y,self.x,self.y)/self.r
    elseif self.shape=='square' then
        return math.max(math.abs(x-self.x),math.abs(y-self.y))/self.r
    end
end

local touches={}
local global_toggle=false
VCTRL={}
VCTRL.focus=nil -- Focusing buttons
VCTRL.hasChanged = false

---@class VCTRL.data
---@field type 'button'
---@field x number
---@field y number
---@field shape? string
---@field key? string
---@field iconSize? number
---@field alpha? number
---@field show? boolean
---@field pressFunc function|nil
---@field releaseFunc function|nil

---@param ... VCTRL.data[]
---Adding (multiple) virtual button(s)
function VCTRL.new(...)
    for _,d in pairs(...) do table.insert(VCTRL,control_type[d.type]:new(d)) end
end

---@param key string
---@param pfunc function|nil
---@param rfunc function|nil
function VCTRL.setAltFunction(key,pfunc,rfunc)
    alternativePfunction[key] = pfunc
    alternativeRfunction[key] = rfunc
end

---@param toggle boolean|false
---Enabling virtual control or not
function VCTRL.toggle(toggle)
    if not toggle then
        -- Release all buttons to prevent button ghost situation
        for id, b in pairs(touches) do
            b:release(id)
            touches[id]=nil
        end
    end
    global_toggle=toggle
end

function VCTRL.clearAll()
    local toggle = global_toggle
    VCTRL.toggle(false)
    global_toggle = toggle

    for i=#VCTRL,1,-1 do VCTRL[i] = nil end
    collectgarbage()
end

---@param force? boolean Forcing click on hidden widgets?
function VCTRL.press(x,y,id,force)
    if not (global_toggle and id) then return end
    local obj,closestDist=false,1e99
    for _, w in ipairs(VCTRL) do
        if w.show or force then
            local d=w:getDistance(x,y)
            if d<=1 and d<closestDist then
                obj,closestDist=w,d
            end
        end
    end
    if obj then
        touches[id]=obj
        obj:press(x,y,id)
        VCTRL.focus=obj
        return true
    end
end

function VCTRL.release(id)
    if not (global_toggle and id) then return end
    if touches[id] then
        touches[id]:release()
        touches[id]=nil
        return true
    end
end

function VCTRL.drag(dx,dy,id)
    if not global_toggle then return end
    if touches[id] then
        touches[id]:drag(dx,dy)
        return true
    end
end

function VCTRL.draw(forceAlpha)
    if not global_toggle then return end
    for _, w in ipairs(VCTRL) do
        if w.show then w:draw(forceAlpha) end
    end
end

function VCTRL.reset()
    for _, w in ipairs(VCTRL) do
        if w.pressingID then touches[w.pressingID] = nil end
        w:reset()
    end
end

function VCTRL.exportAll()
    local t = {}
    for o, k in ipairs(VCTRL) do t[o] = k:export() end
    return t
end