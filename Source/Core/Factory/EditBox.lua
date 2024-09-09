PQLFactory.EditBox = {}

function PQLFactory.EditBox:_CreateFieldLabel(parent, text)
    local label = parent:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    label:SetPoint("TOPLEFT", parent)
    PQLSetFont(label, {
        size = 12,
        text = text
    })
    return label
end

function PQLFactory.EditBox:Create(parent, params)
    local editBoxWrapper = CreateFrame("Frame", nil, parent, "PQLEditBoxTemplate")

    if params.width then
        editBoxWrapper:SetWidth(params.width)
    end

    if params.height then
        editBoxWrapper:SetHeight(params.height)
    end

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

	function editBoxWrapper:_UpdateDisplayValue(show)
		if show then
			local value = self:GetValue()
			local displayValue = value

			if params.FilterDisplayValue then
				displayValue = params.FilterDisplayValue(displayValue)
			end

			editBoxWrapper.editBox.displayValue:SetText(displayValue)

			PQLSetFont(editBoxWrapper.editBox, { size = 12, color = {1, 1, 1, 0} })
			editBoxWrapper.editBox.displayValue:Show()
		else
			PQLSetFont(editBoxWrapper.editBox, { size = 12 })
			editBoxWrapper.editBox.displayValue:Hide()
		end
	end

	function editBoxWrapper:GetValue()
		return editBoxWrapper.editBox:GetText():trim()
	end

	function editBoxWrapper:SetValue(value)
		editBoxWrapper.editBox:SetText(value)
		editBoxWrapper:_UpdateDisplayValue(true)
	end

	-- Tooltip
	editBoxWrapper.editBox:SetScript("OnEnter", function()
        if params.tooltipTitle or params.tooltipBody then
			PQLAttachTooltip(editBoxWrapper.editBox)

            if params.tooltipTitle then
                GameTooltip:AddLine(params.tooltipTitle)
            end

            if params.tooltipBody then
                if type(params.tooltipBody) == "function" then
                    params.tooltipBody()
                else
                    GameTooltip:AddLine(params.tooltipBody, 0.9, 0.9, 0.9, true)
                end
            end

			GameTooltip:Show()
        end
	end)

	editBoxWrapper.editBox:SetScript("OnLeave", function()
		GameTooltip:Hide()
	end)

	editBoxWrapper.editBox:SetScript("OnHyperlinkEnter", function(_, link)
		PQLAttachTooltip(editBoxWrapper.editBox)
		GameTooltip:SetHyperlink(link)
		GameTooltip:Show()
	end)

	editBoxWrapper.editBox:SetScript("OnHyperlinkLeave", function(_, link)
		GameTooltip:Hide()
	end)

	editBoxWrapper.editBox:SetScript("OnHyperlinkClick", function(_, link, _, button)
		local linkType = PQL_Data.Links:GetType(link)

		if button == "LeftButton" and linkType == "item" and IsControlKeyDown() then
			-- Attempt to dress up.
			local itemId = PQL_Data.Links:GetItemId(link)
			if itemId and C_Item.IsDressableItemByID(itemId) then DressUpVisual(link) end

			-- if linkType == "item" then
			-- elseif linkType == "map" then
			-- end
		elseif button == "RightButton" and linkType == "map" then
			local rawPoint, point = PQL_Data.Links:GetMapPointInfo(link)

			if point then
				PQL.dropdown:Open({
					{
						text = "Add WoW waypoint",
						callback = function() C_Map.SetUserWaypoint(point) end
					},
					{
						text = "Add TomTom waypoint",
						callback = function()
							local mapInfo = C_Map.GetMapInfo(rawPoint.mapId)
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
			end
		end
	end)

	-- Scripts
	editBoxWrapper.editBox:SetScript("OnEditFocusGained", function()
		PQL._focusedEditBox = editBoxWrapper.editBox
		editBoxWrapper:_UpdateDisplayValue(false)
	end)

	editBoxWrapper.editBox:SetScript("OnEditFocusLost", function()
		PQL._focusedEditBox = nil

		local value = editBoxWrapper:GetValue()

		if params.FilterValue then
			value = params.FilterValue(value)
		end

		-- Update the value.
		editBoxWrapper:SetValue(value)

		if params.OnChanged then
			params.OnChanged(value)
		end
	end)

	-- Modified Item Click
	editBoxWrapper.editBox.OnModifiedItemClick = function(itemId, itemLink)
		if params.FilterModifiedItemClick then
			local result = params.FilterModifiedItemClick(itemId, itemLink)

			if type(result) == "string" then
				editBoxWrapper.editBox:SetText(result)
			end
		end

		if params.OnModifiedItemClick then
			params.OnModifiedItemClick(itemId, itemLink)
		end
	end

	-- Initialize the display value
	editBoxWrapper:_UpdateDisplayValue(true)

    return editBoxWrapper
end

function PQLFactory.EditBox:CreateField(parent, label, editBoxParams, after, distance)
    local field = {
        label = PQLFactory.EditBox:_CreateFieldLabel(parent, label),
        editBox = PQLFactory.EditBox:Create(parent, editBoxParams)
    }

    if after then
        field.label:SetPoint("TOPLEFT", after, "BOTTOMLEFT", 0, distance or -16)
    else
        field.label:SetPoint("TOPLEFT")
    end

    PQLSetPoints(field.editBox, {
        {"TOPLEFT", field.label, "BOTTOMLEFT", 0, -8},
        {"TOPRIGHT", parent}
    })

    return field
end
