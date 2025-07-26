---@diagnostic disable: cast-local-type
local TouchConfigScene = Scene:extend()
TouchConfigScene.title = "Touchscreen configuration"

local function roundUnit(n,u)
	local u = u or 1
	return math.floor(n/u+.5)*u
end
local function drawText(text, x, y, size, orientation, color)
	if color == nil then color = {1, 1, 1, 1} end
	love.graphics.setFont(font_3x5_3)
	love.graphics.setColor(color)
	love.graphics.printf(text, x, y, size*2, orientation, nil, 0.5)
end
local function math_clamp(x, min, max)
    if max < min then
        min, max = max, min
    end
    return x < min and min or (x > max and max or x)
end

local buttonList
local sliderList = {}
---@class VCTRL.data
local focusingButton
---@type number
local snapUnit = 1

---@type function
local function exitSceneFunc(saved)
	VCTRL.release()
	BUTTON.release(buttonList)
	if TOUCH_SETTINGS.firstTime and not saved then
		scene = InputConfigScene(true)
	else
		scene = TitleScene()
		TOUCH_SETTINGS.firstTime = false
	end
end

buttonList = {
	showToggle = BUTTON.new{
		text = function()
			if focusingButton then
				return focusingButton.show and ">SHOW<\nhide" or "show\n>HIDE<"
			else
				return "show\nhide"
			end
		end,
		x = 400, y = 110, w = 60, h = 40,
		codeWhenReleased = function()
			if focusingButton then
				focusingButton.show = not focusingButton.show
				VCTRL.hasChanged = true
			end
		end,
		update = function(self) self.textColor = focusingButton and {1, 1, 1} or {0.5, 0.5, 0.5} end
	},
	-- previewToggle = BUTTON.new{
	--     text = "Preview\nON",
	--     x = 570, y = 60, w = 60, h = 40,
	--     codeWhenReleased = function()
	--         VCTRL.release()
	--         BUTTON.release(buttonList)
	--         scene = TouchConfigPreviewScene()
	--     end
	-- },
	resetAll = BUTTON.new{
		text = "RESET\nALL",
		x = 500, y = 110, w = 60, h = 40,
		codeWhenReleased = function()
			local selection = love.window.showMessageBox(
				"Save config?", "Are you really sure about RESETTING ALL touchscreen configuration?",
				{"Yes", "No", escapebutton = 2, enterbutton = 1},
				"info", true
			)
			if selection == 1 then
				VCTRL.focus = nil; focusingButton = nil
				VCTRL.hasChanged = false
				VCTRL.clearAll()
				VCTRL.new(TOUCH_SETTINGS.__default__.bind[1])
				TOUCH_SETTINGS.bind[1] = TOUCH_SETTINGS.__default__.bind[1]
			end
		end
	},
	menuScreen = BUTTON.new{
		text = "MENU",
		x = 570, y = 10, w = 60, h = 40,
		codeWhenReleased = function()
			if VCTRL.hasChanged or TOUCH_SETTINGS.firstTime then
				local selection = love.window.showMessageBox(
					"Save config?", "Do you want to save your changes before exiting?",
					{"Save", "Discard", "Keep editing", escapebutton = 3, enterbutton = 1},
					"info", true
				)
				if selection == 1 then
					TOUCH_SETTINGS.bind[1] = VCTRL.exportAll()
					-- love.window.showMessageBox("Saved!", "Your changes was saved!")

					exitSceneFunc(true)
				elseif selection == 2 then
					VCTRL.clearAll()
					VCTRL.new(TOUCH_SETTINGS.bind[1] or {})
					-- love.window.showMessageBox("Discarded!", "Your changes was discarded!")

					exitSceneFunc()
				end
			else
				exitSceneFunc()
			end
		end
	}
}
sliderList.buttonSize = newSlider(
	200, 30, 120, 0, 0, 120,
	function(v)
		if focusingButton then
			v = roundUnit(v, 5)
			if focusingButton.r ~= v then
				focusingButton.r = v
				VCTRL.hasChanged = true
			end
			sliderList.buttonSize.value = v / 120
		end
	end,
	{width = 40}
)
sliderList.iconSize = newSlider(
	480, 30, 120, 0, 0, 100,
	function(v)
		if focusingButton then
			v = roundUnit(v, 5)
			if focusingButton.iconSize ~= v then
				focusingButton.iconSize = v
				VCTRL.hasChanged = true
			end
			sliderList.iconSize.value = v / 100
		end
	end,
	{width = 40}
)
sliderList.opacity = newSlider(
	200, 80, 120, 0, 0, 1,
	function()
		local v
		if focusingButton then
			v = roundUnit(sliderList.opacity.value, 0.01)
			if focusingButton.alpha~=v then
				focusingButton.alpha = v
				VCTRL.hasChanged = true
			end
			sliderList.opacity.value = v
		end
	end,
	{width = 40}
)
local gridSizeTable = {1, 2, 5, 10, 20, 50, 100}
sliderList.gridSize = newSlider(
	480, 80, 120, 1, 1, #gridSizeTable - 1,
	function()
		local f = #gridSizeTable - 1
		local v = roundUnit(sliderList.gridSize.value, 1 / f)
		sliderList.gridSize.value = v
		snapUnit = gridSizeTable[roundUnit(v * f + 1)]
	end,
	{width = 40}
); sliderList.gridSize.forceLight = true

local function sliderList_draw()
	for _, s in pairs(sliderList) do
		if s.forceLight then
			love.graphics.setColor(1, 1, 1)
		else
			love.graphics.setColor(focusingButton and {1, 1, 1} or {0.5, 0.5, 0.5})
		end
		love.graphics.setLineWidth(1)
		s:draw()
	end
end

local function sliderList_update()
	local x, y
	if #love.touch.getTouches() == 1 then
		x, y = GLOBAL_TRANSFORM:inverseTransformPoint(love.touch.getPosition(love.touch.getTouches()[1]))
	else
		x, y = GLOBAL_TRANSFORM:inverseTransformPoint(love.mouse.getPosition())
	end
	for _, s in pairs(sliderList) do
		s:update(x, y, #love.touch.getTouches() == 1 or love.mouse.isDown(1))
	end
end

function TouchConfigScene:new()
	VCTRL.toggle(true)

	VCTRL.focus = nil
	focusingButton = nil
end
function TouchConfigScene:update()
	-- TODO
	if VCTRL.focus~=focusingButton then
		focusingButton = VCTRL.focus
		sliderList.opacity.value = focusingButton.alpha
		sliderList.buttonSize.value = focusingButton.r / 120
		sliderList.iconSize.value = focusingButton.iconSize / 100
	end

	BUTTON.update(buttonList)
	sliderList_update()
end

local string_format = string.format
function TouchConfigScene:render()
	drawBackground("title_night")

	if snapUnit >= 5 then
		local x1, y1 = GLOBAL_TRANSFORM:inverseTransformPoint(0, 0)
		local x2, y2 = GLOBAL_TRANSFORM:inverseTransformPoint(love.graphics.getDimensions())

		love.graphics.setColor(1,1,1,math.sin(love.timer.getTime()*4)*.1+.25)
		love.graphics.setLineWidth(1)
		-- From 0 to X
		for i=x1, x2+snapUnit, snapUnit do
			local x = i - i % snapUnit
			love.graphics.line(x, y1, x, y2)
		end
		-- From 0 to Y
		for i=y1,y2+snapUnit,snapUnit do
			local y= i - i % snapUnit
			love.graphics.line(x1, y, x2, y)
		end
	end

	love.graphics.setColor(0, 0, 0, 0.7)
	love.graphics.rectangle("fill", 5, 5, 560, 100)

	-- Button Size
	drawText(string_format("Size (buttons)\n%14.1d", focusingButton and focusingButton.r or 0), 10, 13, 100, "left")
	-- Icon size
	drawText(string_format("Size (icons)\n%13.1d%%", focusingButton and focusingButton.iconSize or 0), 290, 13, 100, "left")
	-- Opacity
	drawText(string_format("Opacity\n%13.1d%%", focusingButton and focusingButton.alpha * 100 or 0), 10, 63, 100, "left")
	-- Snap to grid
	drawText(string_format("Snap to grid\n%14.1d", snapUnit), 290, 63, 100, "left")

	for _, v in ipairs(VCTRL) do
		if v ~= focusingButton then
			v:draw(v.alpha * (focusingButton and 0.25 or 1))
		end
	end
	if focusingButton then
		focusingButton:draw(
			math_clamp(
				math.sin(love.timer.getTime()*4)*.5+0.1,
				focusingButton.show and 1 or 0.1, 1
			)
		)
	end

	sliderList_draw()
	BUTTON.draw(buttonList)
end


function TouchConfigScene:onInputMove(e)
	if e.type == "touch" or (e.type == "mouse" and love.mouse.isDown(1)) then
		if VCTRL.drag(e.dx, e.dy, e.id or 1) then VCTRL.hasChanged = true end
	elseif e.type == "mouse" then
		BUTTON.checkHovering(buttonList, e.x, e.y)
	end
end

function TouchConfigScene:onInputPress(e)
	if e.type == "mouse" or e.type == "touch" then
		if not (
			VCTRL.press(e.x, e.y, e.id and e.id or 1, true) or
			BUTTON.press(buttonList, e.x, e.y, e.id) or
			(e.x >= 120 and e.x <= 280 and e.y >= 10 and e.y <= 100) or
			(e.x >= 400 and e.x <= 560 and e.y >= 10 and e.y <= 100)
		) then
			VCTRL.focus = nil
			focusingButton = nil
		end
	end
end

function TouchConfigScene:onInputRelease(e)
	if e.type == "mouse" or e.type == "touch" then
		if not BUTTON.release(buttonList, e.x, e.y, e.id) then
			if focusingButton and VCTRL.release(e.id or 1) then
				focusingButton.x = roundUnit(focusingButton.x, snapUnit)
				focusingButton.y = roundUnit(focusingButton.y, snapUnit)
			end
		end
	end
end

return TouchConfigScene