PQL.FACTORY.EditBox = {}

function PQL.FACTORY.EditBox:_CreateFieldLabel(parent, text)
    local label = parent:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    label:SetPoint("TOPLEFT", parent)
    PQLSetFont(label, {
        size = 12,
        text = text
    })
    return label
end

function PQL.FACTORY.EditBox:Create(parent, params)
    local editBoxWrapper = CreateFrame("Frame", nil, parent, "PQLEditBoxTemplate")

    if params.width then editBoxWrapper:SetWidth(params.width) end
    if params.height then editBoxWrapper:SetHeight(params.height) end
	if params.anchor then PQLSetPoints(editBoxWrapper, params.anchor) end

    PQLSetFont(editBoxWrapper.editBox, { size = 12, justify = "LEFT" })
	PQLSetFont(editBoxWrapper.editBox.displayValue, { size = 12, justify = "LEFT", align = "TOP" })
    PQLNineSlice(editBoxWrapper.editBox, "EditBox")
    editBoxWrapper.editBox:SetMultiLine(params.multiline or false)
    editBoxWrapper.editBox:SetAllPoints(editBoxWrapper)
	editBoxWrapper.editBox:SetHyperlinksEnabled(true)

    PQLSetFont(editBoxWrapper.editBox.placeholder, {
        size = 12,
        text = params.placeholder,
        color = {1, 1, 1, 0.7}
    })

	function editBoxWrapper:SetDisplayValue(show)
		if show then
			local value = self:GetValue()
			local displayValue = value

			if params.FilterDisplayValue then
				local filteredDisplayValue = params.FilterDisplayValue(displayValue)
				if filteredDisplayValue then displayValue = filteredDisplayValue end
			end

			editBoxWrapper.editBox.displayValue:SetText(displayValue)

			if value:trim():len() > 0 then
				PQLSetFont(editBoxWrapper.editBox, { size = 12, color = {1, 1, 1, 0} })
				editBoxWrapper.editBox.displayValue:Show()
				editBoxWrapper.editBox.placeholder:Hide()
			else
				PQLSetFont(editBoxWrapper.editBox, { size = 12 })
				editBoxWrapper.editBox.displayValue:Hide()
				editBoxWrapper.editBox.placeholder:Show()
			end
		else
			PQLSetFont(editBoxWrapper.editBox, { size = 12 })
			editBoxWrapper.editBox.displayValue:Hide()
			editBoxWrapper.editBox.placeholder:Hide()
		end
	end

	function editBoxWrapper:GetValue()
		return editBoxWrapper.editBox:GetText()
	end

	function editBoxWrapper:SetValue(value, triggerOnChange)
		editBoxWrapper.editBox:SetText(value)
		editBoxWrapper:SetDisplayValue(true)

		if triggerOnChange and params.OnChanged then
			params.OnChanged(editBoxWrapper:GetValue())
		end
	end

	-- Tooltip
	editBoxWrapper.editBox:SetScript("OnEnter", function()
		if params.tooltip then PQLShowTooltip(params.tooltip, editBoxWrapper.editBox) end
	end)

	editBoxWrapper.editBox:SetScript("OnLeave", function()
		GameTooltip:Hide()
	end)

	-- Hyperlinks
	editBoxWrapper.editBox:SetScript("OnHyperlinkEnter", function(_, link)
		PQLAnchorTooltip(editBoxWrapper.editBox)
		GameTooltip:SetHyperlink(link)
		GameTooltip:Show()
	end)

	editBoxWrapper.editBox:SetScript("OnHyperlinkLeave", function(_, link)
		GameTooltip:Hide()
	end)

	editBoxWrapper.editBox:SetScript("OnHyperlinkClick", function(_, link, _, button)
		local linkType = PQL.UTIL.LINK:GetType(link)

		if button == "LeftButton" then
			if linkType == "item" and IsControlKeyDown() then
				local itemId = PQL.UTIL.LINK:GetItemId(link)
				if itemId and C_Item.IsDressableItemByID(itemId) then DressUpVisual(link) end
			else
				editBoxWrapper.editBox:SetFocus()
			end
		elseif button == "RightButton" then
			if linkType == "map" then
				local _, point = PQL.UTIL.LINK:GetMapPointInfo(link)
				if not point then return end
				PQL.dropdown:Open({
					{
						text = "Add WoW Waypoint",
						OnClick = function() C_Map.SetUserWaypoint(point) end
					},
					{
						text = "Add TomTom Waypoint",
						OnClick = function()
							local mapInfo = C_Map.GetMapInfo(point.uiMapID)
							local waypointText = mapInfo.name

							if params.FilterMapLinkWaypointText then
								waypointText = params.FilterMapLinkWaypointText(waypointText, mapInfo)
							end

							if TomTom then
								TomTom:AddWaypoint(point.uiMapID, point.position.x, point.position.y, {
									title = waypointText,
									persistent = nil,
									minimap = true,
									world = true
								})
							end
						end
					}
				})
			else
				editBoxWrapper.editBox:SetFocus()
			end
		end
	end)

	-- Right Clicks
	editBoxWrapper.editBox:SetScript("OnMouseDown", function(_, button)
		if button == "RightButton" and params.OnRightClick then
			params.OnRightClick()
		end
	end)

	-- Focus
	editBoxWrapper.editBox:SetScript("OnEditFocusGained", function()
		PQL.focusedEditBox = editBoxWrapper.editBox
		editBoxWrapper:SetDisplayValue(false)
	end)

	editBoxWrapper.editBox:SetScript("OnEditFocusLost", function()
		PQL.focusedEditBox = nil
		editBoxWrapper:SetDisplayValue(true)

		if params.FilterValue then
			local value = editBoxWrapper:GetValue()
			editBoxWrapper:SetValue(params.FilterValue(value) or "", true)
		end
	end)

	-- On Change
	editBoxWrapper.editBox:SetScript("OnTextChanged", function(_, userInput)
		if userInput and params.OnChanged then
			local value = editBoxWrapper:GetValue()
			params.OnChanged(value)
		end
	end)

	-- Enter Key
    editBoxWrapper.editBox:SetScript("OnEnterPressed", function(_, key)
		if not editBoxWrapper.editBox:IsMultiLine() or IsControlKeyDown() then
			editBoxWrapper.editBox:ClearFocus()
		end
    end)

	-- Modified Item Click
	editBoxWrapper.editBox.OnModifiedItemClick = function(itemId, itemLink)
		if params.FilterModifiedItemClick then
			local result = params.FilterModifiedItemClick(itemId, itemLink)

			if type(result) == "string" then
				editBoxWrapper:SetValue(result, true)
			end
		end

		if params.OnModifiedItemClick then
			params.OnModifiedItemClick(itemId, itemLink)
		end
	end

	-- Initialize the display value
	editBoxWrapper:SetDisplayValue(true)

    return editBoxWrapper
end

function PQL.FACTORY.EditBox:CreateField(parent, label, editBoxParams, after, distance)
    local field = {
        label = PQL.FACTORY.EditBox:_CreateFieldLabel(parent, label),
        editBox = PQL.FACTORY.EditBox:Create(parent, editBoxParams)
    }

    if after then
        field.label:SetPoint("TOPLEFT", after, "BOTTOMLEFT", 0, distance or -20)
    else
        field.label:SetPoint("TOPLEFT")
    end

    PQLSetPoints(field.editBox, {
        {"TOPLEFT", field.label, "BOTTOMLEFT", 0, -10},
        {"TOPRIGHT", parent}
    })

    return field
end
