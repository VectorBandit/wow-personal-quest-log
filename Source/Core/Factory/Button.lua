PQL.FACTORY.Button = {}

function PQL.FACTORY.Button:_HandleFactoryEvent(button, event)
	if button.factoryEvents and button.factoryEvents[event] then
		button.factoryEvents[event]()
	end
end

function PQL.FACTORY.Button:_SetSharedData(button)
	self:_ApplyState(button, "Normal")

    if button.data.anchor then
		button:ClearAllPoints()
		PQLSetPoints(button, button.data.anchor)
    end
end

function PQL.FACTORY.Button:_ApplyState(button, state)
	if button.data.style == "Custom" then return end
	local file = button.data.style and button.data.style ~= "" and
		string.format("Button-%s-%s", button.data.style, state) or
		string.format("Button-%s", state)

	PQLNineSlice(button, file)
end

-- This should not be called more than once on the same Button.
function PQL.FACTORY.Button:_SetSharedScripts(button, factoryEvents)
    button:RegisterForClicks("AnyUp")

    button:SetScript("OnEnter", function()
		self:_ApplyState(button, "Highlight")
		if button.data.tooltip then PQLShowTooltip(button.data.tooltip, button) end
		PQL.FACTORY.Button:_HandleFactoryEvent(button, "OnEnter")
    end)

    button:SetScript("OnLeave", function()
		self:_ApplyState(button, "Normal")
        GameTooltip:Hide()
		PQL.FACTORY.Button:_HandleFactoryEvent(button, "OnLeave")
    end)

	button:SetScript("OnMouseDown", function()
		self:_ApplyState(button, "Pressed")
	end)

	button:SetScript("OnMouseUp", function()
		self:_ApplyState(button, "Normal")
	end)

    button:SetScript("OnClick", function(_, b)
		if b == "LeftButton" and button.data.OnClick then
			button.data.OnClick()
		elseif b == "RightButton" and button.data.OnRightClick then
			button.data.OnRightClick()
		end
    end)

	button:SetScript("OnDoubleClick", function()
		if button.data.OnDoubleClick then button.data.OnDoubleClick() end
	end)
end

-------------------------------------------------------------------------------
-- TEXT BUTTON
-------------------------------------------------------------------------------

function PQL.FACTORY.Button:_SetButtonData(button)
    PQL.FACTORY.Button:_SetSharedData(button)

	-- Width
	button:SetWidth(button.data.width or 1000)
    PQLSetFont(button.text, {size = button.data.size or 12, text = button.data.text})
	if not button.data.width then button:SetWidth(button.text:GetStringWidth()) end

	-- Text Alignment
    if button.data.justify then button.text:SetJustifyH(button.data.justify) end
    if button.data.align then button.text:SetJustifyV(button.data.align) end
end

function PQL.FACTORY.Button:CreateButton(parent, data)
    local button = CreateFrame("Button", nil, parent)
	button:SetSize(1, 24)
	button.data = data

	-- Text
	button.text = button:CreateFontString(nil, "ARTWORK", "GameFontNormal")
	PQLSetPoints(button.text, {{"TOPLEFT", 6, -6}, {"BOTTOMRIGHT", -6, 6}})

	-- Data
	PQL.FACTORY.Button:_SetButtonData(button)
	PQL.FACTORY.Button:_SetSharedScripts(button) -- Only once

	function button:Update(data)
		for key, value in pairs(data) do
			button.data[key] = value
		end
		PQL.FACTORY.Button:_SetButtonData(button)
	end

    return button
end

-------------------------------------------------------------------------------
-- ICON BUTTON
-------------------------------------------------------------------------------

function PQL.FACTORY.Button:_SetIconButtonData(button)
    PQL.FACTORY.Button:_SetSharedData(button)
	button.icon:SetTexture(PQLArt("Icon-"..button.data.icon..".png"))
end

function PQL.FACTORY.Button:CreateIconButton(parent, data)
    local button = CreateFrame("button", nil, parent)
	button:SetSize(data.size or 24, data.size or 24)
	button.data = data

	-- Icon
	button.icon = button:CreateTexture(nil, "ARTWORK")
	button.icon:SetSize(16, 16)
	button.icon:SetPoint("CENTER")

	-- Data
	PQL.FACTORY.Button:_SetIconButtonData(button)
	PQL.FACTORY.Button:_SetSharedScripts(button) -- Only once

	function button:Update(data)
		for key, value in pairs(data) do
			button.data[key] = value
		end

		PQL.FACTORY.Button:_SetIconButtonData(button)
	end

	return button
end

