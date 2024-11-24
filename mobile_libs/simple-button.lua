-- SIMPLE-BUTTON.lua<br>
-- A simple module that aims to help you quickly create buttons<br>
-- It is can be used as a base class to help you quickly creating button<br>
-- This module has type notations so IntelliSense should give you some suggestions<br>
local BUTTON = {}

-- MIT License

-- Copyright (c) 2024 SweetSea-ButImNotSweet

-- Permission is hereby granted, free of charge, to any person obtaining a copy
-- of this software and associated documentation files (the "Software"), to deal
-- in the Software without restriction, including without limitation the rights
-- to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
-- copies of the Software, and to permit persons to whom the Software is
-- furnished to do so, subject to the following conditions:

-- The above copyright notice and this permission notice shall be included in all
-- copies or substantial portions of the Software.

-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
-- AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
-- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
-- OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
-- SOFTWARE.

local NULL = function() end
local function checkColorTableValidation(C)
    if C and type(C) == "table" and (#C == 3 or #C == 4) then
        for _, v in pairs(C) do
            if type(v) ~= "number" or v<0 or v>1 then return false end
        end
    else
        return false
    end
    return true
end

---@class BUTTON.button
---@field text? string|function # Name of the button, will be used to show
---@field textOrientation? "center"|"justify"|"left"|"right"
---
---@field x? number # Position of the button (x, y, w, h)
---@field y? number # Position of the button (x, y, w, h)
---@field w? number # Position of the button (x, y, w, h)
---@field h? number # Position of the button (x, y, w, h)
---@field r? number # Radius corner, cannot larger than half of button's width and half of button's height
---
---@field borderWidth? number|1 # Line width will be used to draw button
---@field borderJoin? "bevel"|"miter"|"none"
---@field borderStyle? "rough"|"smooth"
---
---@field font? love.Font
---
---@field backgroundColor? integer[]
---@field textColor? integer[]
---@field borderColor? integer[]
---@field hoverColor? integer[]
---@field pressColor? integer[]
---
---@field codeWhenPressed? function| # Code will be execute when pressed
---@field codeWhenReleased? function| # Code will be execute when released
---@field drawingButtonFunc? function| # The function is used to draw text<br>You can override the default one if you feel the default text drawing function is not suitable for you
---
---@field draw? function
---@field update? function
local button = {
    textOrientation = "center",
    r = 0,

    backgroundColor = {0,0,0,0},
    hoverColor = {1,1,1,0.5},
    pressColor = {0, 1, 0.5, 0.5},
    borderColor = {1,1,1},
    textColor = {1,1,1},

    font = love.graphics.newFont(15),

    borderWidth = 1,
    borderJoin = "none",
    borderStyle = "smooth",

    codeWhenPressed  = NULL,
    codeWhenReleased = NULL,
    update = NULL,

    _hovering = false,
    _pressed = false,
    _touchID = false,
}; button.__index = button
function button:draw()
    love.graphics.setLineWidth(self.borderWidth)
    love.graphics.setLineStyle(self.borderStyle)
    love.graphics.setLineJoin(self.borderJoin)

    love.graphics.setColor(self.backgroundColor)
    love.graphics.rectangle('fill', self.x, self.y, self.w, self.h, self.r)

    if self._pressed then
        love.graphics.setColor(self.pressColor)
        love.graphics.rectangle('fill', self.x, self.y, self.w, self.h, self.r)
    elseif self._hovering then
        love.graphics.setColor(self.hoverColor)
        love.graphics.rectangle('fill', self.x, self.y, self.w, self.h, self.r)
    end

    love.graphics.setColor(self.textColor)
    love.graphics.setFont(self.font)

    local text = type(self.text) == 'function' and self.text() or self.text

    local lineAmount
    do
        local _, t = self.font:getWrap(text, self.w)
        lineAmount = #t
    end
    local textHeight = self.font:getHeight() * (lineAmount * 0.5)
    local textPos = self.y + (self.h * 0.5) - textHeight
    love.graphics.printf(text, self.x, textPos, self.w, self.textOrientation)

    love.graphics.setColor(self.borderColor)
    love.graphics.rectangle('line', self.x, self.y, self.w, self.h, self.r)
end
---Check if current position is hovering the button, if it is, return true
function button:isHovering(x,y)
    if not y then return false end
    if
        x >= self.x and
        y >= self.y and
        x <= self.x + self.w and
        y <= self.y + self.h
    then
        return true
    else
        return false
    end
end
---Trigger press action, only when ``self._hovering`` is true
function button:press(x, y, touchID)
    if self:isHovering(x, y) and not self._pressed then
        self._touchID = touchID
        self._pressed = true

        self.codeWhenPressed()
        self:draw()

        return true
    end
end
---Trigger release action, don't need ``self._hovering`` to ``true``
function button:release(x, y, touchID)
    local valid
    if touchID then
        valid = touchID == self._touchID
    else
        valid = true
    end

    if valid then
        self._pressed = false
        self._touchID = false

        if touchID then
            self._hovering = false
        else
            self._hovering = self:isHovering(x, y)
        end

        if self:isHovering(x, y) then
            self.codeWhenReleased()
            return true
        end
    end
end

---@param D BUTTON.button|BUTTON.newData
---@param safe? boolean @ Creating widget? If not then ignore accept missing important parameters
---@return nil
---Validate the provided data, will be called by ``BUTTON.new`` and ``BUTTON.setDefaultOption``<br>
---***WARNING! THIS FUNCTION WILL RAISE EXCEPTION IF DATA IS INVALID!***
function BUTTON.checkDataValidation(D, safe)
    if not safe then
        if type(D.text) == 'function' then
            assert(type(D.text()) == 'string', "[text] is a function but it doesn't return any string?!")
        elseif type(D.text) ~= 'string' then
            error("[text] must be a string or a function returns string, got "..type(D.text))
        end

        assert(type(D.x) == "number"            , "[x] must be a integer")
        assert(type(D.y) == "number"            , "[y] must be a integer")
        assert(type(D.w) == "number" and D.w > 0, "[w] must be a positive integer")
        assert(type(D.h) == "number" and D.h > 0, "[h] must be a positive integer")
        assert((type(D.r) == "number" and D.r >= 0 and D.r <= D.w * 0.5 and D.r <= D.h * 0.5) or D.r == nil, "[r] must be a positive integer and cannot larger than half of button's width and half of button's height")
    else
        assert(type(D.r) == "number" and D.r >= 0 or D.r == nil, "[r] must be a positive integer (CAUTION: a extra condition is temproraily ignored because you are setting default option)")
    end
    assert(table.contains({"center","justify","left","right"}, D.textOrientation) or D.textOrientation == nil, "[borderJoin] must be 'bevel', 'miter' or 'none")
    assert((type(D.borderWidth) == "number" and D.borderWidth > 0) or D.borderWidth == nil, "[borderWidth] must be a postive integer")
    assert(table.contains({"bevel", "miter", "none"}, D.borderJoin) or D.borderJoin == nil, "[borderJoin] must be 'bevel', 'miter' or 'none")
    assert(table.contains({"rough", "smooth"}, D.borderStyle) or D.borderStyle == nil, "[borderStyle] must be 'rough' or 'smooth'")
    assert((D.font and D.font.typeOf and D.font:typeOf("Font")) or D.font == nil, "[font] must be love.Font")

    assert(checkColorTableValidation(D.backgroundColor), "[backgroundColor] must be a table with r, g, b (, a) values, all of them must be integers between 0 and 1")
    assert(checkColorTableValidation(D.hoverColor), "[hoverColor] must be a table with r, g, b (, a) values, all of them must be integers between 0 and 1")
    assert(checkColorTableValidation(D.pressColor), "[hoverColor] must be a table with r, g, b (, a) values, all of them must be integers between 0 and 1")
    assert(checkColorTableValidation(D.borderColor), "[borderColor] must be a table with r, g, b (, a) values, all of them must be integers between 0 and 1")
    assert(checkColorTableValidation(D.textColor), "[textColor] must be a table with r, g, b (, a) values, all of them must be integers between 0 and 1")

    assert(type(D.codeWhenPressed)   == "function" or D.codeWhenPressed   == nil, "[codeWhenPressed] must be a function or nil")
    assert(type(D.codeWhenReleased)  == "function" or D.codeWhenReleased  == nil, "[codeWhenReleased] must be a function or nil")
    assert(type(D.drawingButtonFunc) == "function" or D.drawingButtonFunc == nil, "[drawingButtonFunc] must be a function or nil")
end

---@class BUTTON.newData
---@field text string|function # Name of the button, will be used to show. If function provided, it should return the string!
---@field textOrientation? "center"|"justify"|"left"|"right"
---
---@field x  number # Position of the button (x, y, w, h)
---@field y  number # Position of the button (x, y, w, h)
---@field w  number # Position of the button (x, y, w, h)
---@field h  number # Position of the button (x, y, w, h)
---@field r? number # Radius corner, cannot larger than half of button's width and half of button's height
---
---@field borderWidth? number|1 # Line width will be used to draw button
---@field borderJoin? "bevel"|"miter"|"none"
---@field borderStyle? "rough"|"smooth"
---
---@field font? love.Font
---
---@field backgroundColor? integer[]
---@field textColor? integer[]
---@field borderColor? integer[]
---@field hoverColor? integer[]
---@field pressColor? integer[]
---
---@field codeWhenPressed? function| # Code will be execute when pressed
---@field codeWhenReleased? function| # Code will be execute when released
---@field drawingButtonFunc? function| # The function is used to draw text<br>You can override the default one if you feel the default text drawing function is not suitable for you
---
---@field draw? function
---@field update? function

---@param D BUTTON.newData
---@nodiscard
---Create a new button, provide you a table with 4 functions inside: draw and update, press and release<br>
---You need to put them into intended callbacks :)
---
---Remember to fill 5 necessary parameters: name, x, y, w and h
function BUTTON.new(D)
    local B = setmetatable(D, button)
    BUTTON.checkDataValidation(B)
    return B
end

---@param D BUTTON.button
function BUTTON.setDefaultOption(D)
    BUTTON.checkDataValidation(setmetatable(D, button), true)
    for k, v in pairs(D) do
        if button[k] ~= nil then
            button[k] = v
        else
            error("Parameter named ["..k.."] is not existed or cannot be set default value, in BUTTON!")
        end
    end
end

-- < EXTRA GENERAL OPTIONS >

---Draw all buttons in provided list
---@param list table<any,BUTTON.button>
function BUTTON.draw(list)
    for _, v in pairs(list) do v:draw() end
end
---Update all buttons in provided list
---@param list table<any,BUTTON.button>
function BUTTON.update(list)
    for _, v in pairs(list) do v:update() end
end

---Check if current mouse position is inside button<br>
---Calling BUTTON.press will trigger this, but you can call it when moving mouse so button can be highlighted when being hovered
---@param list table<BUTTON.button>
---@param x number # Mouse position
---@param y number # Mouse position
function BUTTON.checkHovering(list, x, y)
    local highlighted_a_button = false
    for _, v in pairs(list) do
        if highlighted_a_button then
            v._hovering = false
        else
            v._hovering = v:isHovering(x, y)
        end

        if not highlighted_a_button and v._hovering then highlighted_a_button = true end
    end
end

--- Trigger the press action, only if ``button._hovering == true``
---@param list table<BUTTON.button>
---@param x number # Mouse position
---@param y number # Mouse position
function BUTTON.press(list, x, y, touchID)
    for _, v in pairs(list) do if v:press(x, y, touchID) then return true end end
end

---Trigger the release action
---@param list table<BUTTON.button>
function BUTTON.release(list, x, y, touchID)
    for _, v in pairs(list) do if v:release(x, y, touchID) then return true end end
end

--- Do a reset, useful for switching scenes
function BUTTON.reset(list)
    for _, v in pairs(list) do
        v._pressed = false
        v._hovering = false
        v._touchID = false
    end
end

return BUTTON