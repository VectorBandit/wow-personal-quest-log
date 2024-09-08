local iconButtonTextureData = {
    NormalTexture = {0, 0.25, 0, 1},
    HighlightTexture = {0.25, 0.5, 0, 1},
    PushedTexture = {0.5, 0.75, 0, 1},
    DisabledTexture = {0.75, 1, 0, 1}
}

PQLFactory.Button = {}

function PQLFactory.Button:_SetSharedData(button)
    -- Anchor
    if button.data.anchor and type(button.data.anchor) == "table" then
		button:ClearAllPoints()
        if type(button.data.anchor[1]) == "table" then
            for _, anchor in ipairs(button.data.anchor) do
                button:SetPoint(unpack(anchor))
            end
        else
            button:SetPoint(unpack(button.data.anchor))
        end
    end
end

-- This should not be called more than once on the same Button.
function PQLFactory.Button:_SetSharedScripts(button, factoryEvents)
	button:SetScript("OnDoubleClick", function()
		if button.data.isDoubleClick then
			button.data.callback()
		end

		if button.factoryEvents and button.factoryEvents["OnDoubleClick"] then
            button.factoryEvents.OnDoubleClick()
		end
	end)

    button:SetScript("OnClick", function()
		if not button.data.isDoubleClick then
			button.data.callback()
		end

        if button.factoryEvents and button.factoryEvents['OnClick'] then
            button.factoryEvents.OnClick()
        end
    end)

    button:SetScript("OnEnter", function()
        if button.data.tooltipTitle or button.data.tooltipBody then
			PQLAttachTooltip(button)

            if button.data.tooltipTitle then
                GameTooltip:AddLine(button.data.tooltipTitle)
            end

            if button.data.tooltipBody then
                if type(button.data.tooltipBody) == "function" then
                    button.data.tooltipBody()
                else
                    GameTooltip:AddLine(button.data.tooltipBody, 0.9, 0.9, 0.9, true)
                end
            end

			GameTooltip:Show()
        end

        if button.factoryEvents and button.factoryEvents["OnEnter"] then
            button.factoryEvents.OnEnter()
        end
    end)

    button:SetScript("OnLeave", function()
        GameTooltip:Hide()

        if button.factoryEvents and button.factoryEvents["OnLeave"] then
            button.factoryEvents.OnLeave()
        end
    end)
end

function PQLFactory.Button:_SetButtonData(button)
    PQLFactory.Button:_SetSharedData(button)

	button:SetWidth(button.data.width or 100)
    PQLSetFont(button.text, {size = button.data.size or 12, text = button.data.text})

	-- Style
    local nsNormal = "Button"
    local nsHighlight = "Button-Highlight"

    if button.data.style == "text-default" then
        nsNormal = "Button_Text"
        nsHighlight = "Button_Text-Highlight"
    elseif button.data.style == "positive" then
        button.text:SetTextColor(unpack(PQL_THEME.valid))
    elseif button.data.style == "negative" then
        button.text:SetTextColor(unpack(PQL_THEME.invalid))
    end

    PQLNineSlice(button, nsNormal)

	-- Text Alignment
    if button.data.justify then
        button.text:SetJustifyH(button.data.justify)
    end

    if button.data.align then
        button.text:SetJustifyV(button.data.align)
    end

	-- Handle State Changes
	button:SetScript("OnMouseDown", function()
		if not button.data.isCustomStates then
			PQLNineSlice(button, "Button-Pressed")
		end
	end)

	button:SetScript("OnMouseUp", function()
		if not button.data.isCustomStates then
			PQLNineSlice(button, nsNormal)
		end
	end)

	button.factoryEvents = {
		OnEnter = function()
			if not button.data.isCustomStates then
				PQLNineSlice(button, nsHighlight)
			end
		end,
		OnLeave = function()
			if not button.data.isCustomStates then
				PQLNineSlice(button, nsNormal)
			end
		end
	}
end

function PQLFactory.Button:_SetIconButtonData(button)
    PQLFactory.Button:_SetSharedData(button)

	button:SetSize(button.data.size or 24, button.data.size or 24)

    for textureType, textureCoords in pairs(iconButtonTextureData) do
        button["Set"..textureType](button, PQLArt("Button-"..button.data.icon..".png"))
        button["Get"..textureType](button):SetTexCoord(unpack(textureCoords))
    end
end

function PQLFactory.Button:CreateButton(parent, data)
    local button = CreateFrame("Button", nil, parent, "PQLButtonTemplate")
    button:RegisterForClicks("LeftButtonUp")
	button.data = data

    button.text:SetPoint("TOPLEFT", button, "TOPLEFT", 6, -6)
    button.text:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -6, 6)

	PQLFactory.Button:_SetButtonData(button)
	PQLFactory.Button:_SetSharedScripts(button) -- Only once

	function button:Update(data)
		for key, value in pairs(data) do
			button.data[key] = value
		end
		PQLFactory.Button:_SetButtonData(button)
	end

    return button
end

function PQLFactory.Button:CreateIconButton(parent, data)
    local button = CreateFrame("button", nil, parent)
    button:RegisterForClicks("LeftButtonUp")
	button.data = data

	PQLFactory.Button:_SetIconButtonData(button)
	PQLFactory.Button:_SetSharedScripts(button) -- Only once

	function button:Update(data)
		for key, value in pairs(data) do
			button.data[key] = value
		end

		PQLFactory.Button:_SetIconButtonData(button)
	end

	return button
end

