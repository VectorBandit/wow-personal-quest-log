PQL.main.QuestDrawer = PQL.FACTORY.Drawer:Create("Quest", { title = "Quest Details" })
PQL.main:AddModule("QuestDrawer")
PQL.main:AddDrawer("QuestDrawer")

local d = PQL.main.QuestDrawer

function PQL.main.QuestDrawer:Init()
	-- Button: Move
	PQL.FACTORY.Button:CreateIconButton(d, {
		icon = "Move",
		anchor = {"TOPRIGHT", d, -88, -20},
		tooltip = {title = "Move Quest"},
		OnClick = function()
			local options = PQL.ENTITY.GROUP:AsDropdownOptions(function(group)
				d.data:Move(group:GetID())
			end)

			PQL.dropdown:Open(options)
		end
	})

	-- Button: Visibility
	d.visibilityButton = PQL.FACTORY.Button:CreateIconButton(d, {
		icon = "VisibleOn",
		anchor = {"TOPRIGHT", d, -54, -20},
		tooltip = {title = "Toggle Quest Visibility"},
		OnClick = function() d.data:ToggleVisible() end
	})

	-- Button: Delete
	PQL.FACTORY.Button:CreateIconButton(d, {
		icon = "Delete",
		anchor = {"TOPRIGHT", d, -20, -20},
		tooltip = {title = "Delete Quest"},
		OnClick = function()
			PQL.confirmPopup:Open({
				text = "Deleting this quest will also delete all goals associated with it.",
				OnConfirm = function()
					d.data:Delete()
					d:Close()
				end
			})
		end
	})

	d:SetupFields()
	d:SetupGoalsRegion()

	PQL.DATA:On({
		"QUEST_UPDATED",
		"QUEST_DELETED",
		"GOAL_CREATED",
		"GOAL_UPDATED",
		"GOAL_DELETED",
	}, function(event, ...)
		if event == "QUEST_UPDATED" then
			local questID, isStrict = ...
			if questID == d.questID and isStrict then self:UpdateFields() end
		elseif event == "QUEST_DELETED" then
			local questID = select(1, ...)
			if questID == d.questID then d:Close() end
		elseif event == "GOAL_UPDATED" then
			local isStrict = select(2, ...)
			if isStrict then d.inner.goals:Populate() end
		elseif event == "GOAL_CREATED" or event == "GOAL_DELETED" then
			d.inner.goals:Populate()
		else
			PQL:Print("[UNHANDLED_EVENT] QuestDrawer", event)
		end
	end)

	d:Close()
end

function PQL.main.QuestDrawer:OnOpen(questID)
	d.questID = questID
	d:UpdateFields()

	if not PQL.DATA:Get("seenQuestDrawerHelp") then
		PQL.main:ToggleHelp()
		PQL.DATA:Set("seenQuestDrawerHelp", true)
	end
end

function PQL.main.QuestDrawer:OnClose()
	d.questID = nil
	d:UpdateFields()
end

function PQL.main.QuestDrawer:SetupFields()
	d.inner.fields = {}

	-- Field: Title
	d.inner.fields.title = PQL.FACTORY.EditBox:CreateField(d.inner, "Quest Title", {
		placeholder = "Enter title",
		OnChanged = function(title) d.data:Update("title", title, PQL_NOT_STRICT) end,
	}, d.inner.title, -20)

	-- Field: Notes
	d.inner.fields.notes = PQL.FACTORY.EditBox:CreateField(d.inner, "Quest Notes", {
		placeholder = "Enter notes",
		multiline = true,
		OnChanged = function(notes) d.data:Update("notes", notes, PQL_NOT_STRICT) end,
		FilterModifiedItemClick = function(_, itemLink)
			local c = d.inner.fields.notes.editBox.editBox:GetCursorPosition()
			local t = d.inner.fields.notes.editBox.editBox:GetText()

			return PQLString.insert(t, itemLink, c)
		end,
		FilterMapLinkWaypointText = function(areaName)
			if d.questData.questTitle:trim() == "" then return areaName end
			return string.format("%s\n(%s)", d.questData.questTitle, areaName)
		end
	}, d.inner.fields.title.editBox)

	d.inner.fields.notes.editBox:SetHeight(200)
end

function PQL.main.QuestDrawer:SetupGoalsRegion()
	d.inner.goalsTitle = d.inner:CreateFontString(nil, "ARTWORK", "GameFontNormal")
	d.inner.goalsTitle:SetPoint("TOPLEFT", d.inner.fields.notes.editBox, "BOTTOMLEFT", 0, -20)

	PQLSetFont(d.inner.goalsTitle, {
		size = 18,
		text = "Quest Goals"
	})

	-- Region Frame
	d.inner.goalsRegion = CreateFrame("Frame", nil, d.inner)

	PQLSetPoints(d.inner.goalsRegion, {
		{"TOPLEFT", d.inner.goalsTitle, "BOTTOMLEFT", 0, -20},
		{"RIGHT"}
	})

	-- Goals List
	d.inner.goals = PQL.FACTORY.DynamicList:Create(d.inner.goalsRegion, {
		actions = PQL.main.QuestDrawer.goalsActions,
		spacing = 10
	})

	d.inner.goalsRegion.addButton = PQL.FACTORY.Button:CreateButton(d.inner.goalsRegion, {
		text = "Add Goal",
		width = 80,
		anchor = {
			{"TOPLEFT", d.inner.goalsRegion, "BOTTOMLEFT", 0, -10},
			{"RIGHT"}
		},
		OnClick = function() PQL.ENTITY.GOAL:Create(d.data:GetID()) end,
	})

	-- Reposition the scroll frame bottom gutter
	d.inner.bottomGutter:SetPoint("TOPLEFT", d.inner.goalsRegion.addButton, "BOTTOMLEFT")
end

function PQL.main.QuestDrawer:UpdateFields()
	d.data = PQL.ENTITY.QUEST:ByID(d.questID)

	d:UpdateVisibilityButton()

	d.inner.fields.title.editBox:SetValue(d.data and d.data:Get("title") or "")
	d.inner.fields.notes.editBox:SetValue(d.data and d.data:Get("notes") or "")

	d.inner.goals:Populate()
end

function PQL.main.QuestDrawer:UpdateVisibilityButton()
	d.visibilityButton:Update({
		icon = d.data and d.data:IsVisible() and "VisibleOn" or "VisibleOff",
		style = d.data and d.data:IsVisible() and "" or "Transparent",
	})
end

-------------------------------------------------------------------------------
-- FACTORY | Goal
-------------------------------------------------------------------------------

PQL.main.QuestDrawer.goalsActions = {
	FetchEntries = function()
		return PQL.ENTITY.GOAL:ByQuest(d.questID)
	end,

	Create = function(parent)
		local goalFrame = CreateFrame("Frame", nil, parent)
		goalFrame:SetHeight(24)

		goalFrame.goalTypeButton = PQL.FACTORY.Button:CreateButton(goalFrame, {
			width = 70,
			anchor = {"TOPLEFT"},
			style = "Custom",
			tooltip = {
				title = "Goal Type",
				body = "[Right-Click] to change.",
			},
			OnRightClick = function()
				PQL.dropdown:Open({
					{
						text = "Custom",
						tooltip = {title = PQL_GOALTYPES[PQL_GOALTYPE_CUSTOM].label, body = PQL_GOALTYPES[PQL_GOALTYPE_CUSTOM].description},
						OnClick = function() goalFrame.data:SetType(PQL_GOALTYPE_CUSTOM) end
					},
					{
						text = "Item",
						tooltip = {title = PQL_GOALTYPES[PQL_GOALTYPE_ITEM].label, body = PQL_GOALTYPES[PQL_GOALTYPE_ITEM].description},
						OnClick = function() goalFrame.data:SetType(PQL_GOALTYPE_ITEM) end
					},
					{
						text = "Currency",
						tooltip = {title = PQL_GOALTYPES[PQL_GOALTYPE_CURRENCY].label, body = PQL_GOALTYPES[PQL_GOALTYPE_CURRENCY].description},
						OnClick = function() goalFrame.data:SetType(PQL_GOALTYPE_CURRENCY) end
					},
					{
						text = "Unit",
						tooltip = {title = PQL_GOALTYPES[PQL_GOALTYPE_UNIT].label, body = PQL_GOALTYPES[PQL_GOALTYPE_UNIT].description},
						OnClick = function() goalFrame.data:SetType(PQL_GOALTYPE_UNIT) end
					},
				})
			end
		})

		-- Fields
		goalFrame.fields = CreateFrame("Frame", nil, goalFrame)

		PQLSetPoints(goalFrame.fields, {
			{"TOPLEFT", goalFrame, "TOPLEFT", 80, 0},
			{"BOTTOMRIGHT", goalFrame, "BOTTOMRIGHT", -34, 0}
		})

		goalFrame.fields.tabs = d:CreateGoalFieldTabs(goalFrame)

		-- Options
		goalFrame.optionsButton = PQL.FACTORY.Button:CreateIconButton(goalFrame, {
			icon = "Dropdown",
			anchor = {"TOPRIGHT"},
			tooltip = {title = "Options"},
			OnClick = function()
				PQL.dropdown:Open({
					{
						text = "Reset progress",
						OnClick = function()
							PQL.confirmPopup:Open({
								text = "Doing so will reset the progress towards completing this goal.",
								OnConfirm = function() goalFrame.data:ResetProgress() end,
							})
						end,
					}
				}, {
					{
						icon = "Delete",
						tooltip = {title = "Delete Goal"},
						OnClick = function()
							PQL.confirmPopup:Open({
								OnConfirm = function() goalFrame.data:Delete() end,
							})
						end,
					},
					{
						icon = "ArrowDown",
						tooltip = {title = "Move Down"},
						OnClick = function() goalFrame.data:Reorder(1) end,
					},
					{
						icon = "ArrowUp",
						tooltip = {title = "Move Up"},
						OnClick = function() goalFrame.data:Reorder(-1) end,
					},
				})
			end,
		})

		return goalFrame
	end,

	Init = function(goalFrame)
		PQLNineSlice(goalFrame.goalTypeButton, "GoalType-"..goalFrame.data:Get("type"), false)

		goalFrame.goalTypeButton.text:SetText(PQL_GOALTYPES[goalFrame.data:Get("type")].label)

		-- Show the correct field tab
		for _, fields in pairs(goalFrame.fields.tabs) do
			fields:Hide()
		end

		goalFrame.fields.tabs[goalFrame.data:Get("type")]:Show()

		-- Update tab fields
		for fieldKey, field in pairs(goalFrame.fields.tabs[goalFrame.data:Get("type")]) do
			if type(field) == "table" then
				field:SetValue(goalFrame.data:Get(fieldKey, ""))
			end
		end
	end
}

function PQL.main.QuestDrawer:CreateGoalFieldTabs(goalFrame)
	local tabs = {}

	-- Fields (Goal Type: Custom)
	tabs[PQL_GOALTYPE_CUSTOM] = CreateFrame("Frame", nil, goalFrame.fields)
	local t1 = tabs[PQL_GOALTYPE_CUSTOM]

	t1:SetAllPoints(goalFrame.fields)

	t1["description"] = PQL.FACTORY.EditBox:Create(t1, {
		placeholder = "Description",
		anchor = {{"TOPLEFT"}, {"TOPRIGHT"}},
		OnChanged = function(description) goalFrame.data:Update("description", description, PQL_NOT_STRICT) end,
	})

	-- Fields (Goal Type: Item)
	tabs[PQL_GOALTYPE_ITEM] = CreateFrame("Frame", nil, goalFrame.fields)
	local t2 = tabs[PQL_GOALTYPE_ITEM]

	t2:SetAllPoints(goalFrame.fields)

	t2["resourceID"] = PQL.FACTORY.EditBox:Create(t2, {
		placeholder = "Item ID",
		tooltip = {
			title = "Item ID",
			body = "Paste item ID here, or shift-click an item from your bag or a vendor.",
		},
		anchor = {
			{"TOPLEFT"},
			{"TOPRIGHT", goalFrame.fields, "TOPRIGHT", -80, 0},
		},
		OnChanged = function(resourceID) goalFrame.data:Update("resourceID", resourceID, PQL_NOT_STRICT) end,
		FilterDisplayValue = function(value)
			if not value or value:trim() == "" then return "" end
			local _, itemLink = C_Item.GetItemInfo(value)
			return itemLink or value.." (Invalid ID)"
		end,
		FilterModifiedItemClick = function(itemId) return itemId end,
	})

	t2["requiredCount"] = PQL.FACTORY.EditBox:Create(t2, {
		placeholder = "Count",
		anchor = {
			{"TOPLEFT", goalFrame.fields, "TOPRIGHT", -70, 0},
			{"TOPRIGHT"}
		},
		OnChanged = function(requiredCount) goalFrame.data:Update("requiredCount", requiredCount, PQL_NOT_STRICT) end,
		FilterValue = function(value)
			return value and value:gsub("%D", "") or value
		end,
	})

	-- Fields (Goal Type: Currency)
	tabs[PQL_GOALTYPE_CURRENCY] = CreateFrame("Frame", nil, goalFrame.fields)
	local t3 = tabs[PQL_GOALTYPE_CURRENCY]

	t3:SetAllPoints(goalFrame.fields)

	t3["resourceID"] = PQL.FACTORY.EditBox:Create(t3, {
		placeholder = "Currency ID",
		anchor = {
			{"TOPLEFT"},
			{"TOPRIGHT", goalFrame.fields, "TOPRIGHT", -80, 0}
		},
		OnChanged = function(resourceID) goalFrame.data:Update("resourceID", resourceID, PQL_NOT_STRICT) end,
		FilterDisplayValue = function(value)
			if not value or value:trim() == "" then return "" end
			local currencyInfo = PQL.UTIL.CURRENCY:Get(value)
			return currencyInfo and currencyInfo.link or value.." (Invalid ID)"
		end,
	})

	t3["requiredCount"] = PQL.FACTORY.EditBox:Create(t3, {
		placeholder = "Count",
		anchor = {
			{"TOPLEFT", goalFrame.fields, "TOPRIGHT", -70, 0},
			{"TOPRIGHT"}
		},
		OnChanged = function(requiredCount) goalFrame.data:Update("requiredCount", requiredCount, PQL_NOT_STRICT) end,
		FilterValue = function(value)
			return value and value:gsub("%D", "") or value
		end,
	})

	-- Fields (Goal Type: Unit)
	tabs[PQL_GOALTYPE_UNIT] = CreateFrame("Frame", nil, goalFrame.fields)
	local t4 = tabs[PQL_GOALTYPE_UNIT]

	t4:SetAllPoints(goalFrame.fields)

	t4["unitID"] = PQL.FACTORY.EditBox:Create(t4, {
		placeholder = "Unit ID",
		anchor = {
			{"TOPLEFT"},
			{"TOPRIGHT", goalFrame.fields, -80, 0}
		},
		OnRightClick = function()
			PQL.dropdown:Open({{
				text = "Set from target",
				OnClick = function()
					local targetGUID = UnitGUID("target")
					if not targetGUID then return end
					local targetId = PQL.UTIL.UNIT:GetIDFromGUID(targetGUID)
					if not targetId then return end
					t4["unitID"]:SetValue(targetId, true)
				end,
			}})
		end,
		OnChanged = function(unitID) goalFrame.data:Update("unitID", unitID, PQL_NOT_STRICT) end,
		FilterDisplayValue = function(value)
			if not value or value:trim() == "" then return value end
			return PQL.UTIL.LINK:MakeUnit(value:trim()) or value
		end,
		FilterValue = function(value)
			return value and value:gsub("%D", "") or value
		end,
	})

	t4["requiredCount"] = PQL.FACTORY.EditBox:Create(t4, {
		placeholder = "Count",
		anchor = {
			{"TOPLEFT", goalFrame.fields, "TOPRIGHT", -70, 0},
			{"TOPRIGHT"}
		},
		OnChanged = function(requiredCount) goalFrame.data:Update("requiredCount", requiredCount, PQL_NOT_STRICT) end,
		FilterValue = function(value)
			return value and value:gsub("%D", "") or value
		end,
	})

	return tabs
end

