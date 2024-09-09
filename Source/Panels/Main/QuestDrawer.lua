PQL.main.QuestDrawer = PQLFactory.Drawer:Create("Quest", { title = "Quest Details" })
PQL.main:AddModule("QuestDrawer")
PQL.main:AddDrawer("QuestDrawer")

local d = PQL.main.QuestDrawer

function PQL.main.QuestDrawer:Init()

	-- Create the "Move" button
	d.inner.moveButton = PQLFactory.Button:CreateIconButton(d.inner, {
		icon = "Move",
		anchor = {"TOPRIGHT", d.inner, -72, 0},
		tooltipTitle = "Move Quest",
		callback = function()
			local options = PQL_DB.Groups:GetAsDropdownOptions(function(group)
				PQL_DB.Quests:Update(d.questData.questId, "groupId", group.groupId)
			end)

			PQL.dropdown:Open(options)
		end
	})

	-- Create the "Toggle Visibility" button
	d.inner.visibilityButton = PQLFactory.Button:CreateIconButton(d.inner, {
		icon = "VisibleOn",
		anchor = {"TOPRIGHT", d.inner, -36, 0},
		tooltipTitle = "Toggle Quest Visibility",
		callback = function()
			PQL_DB.Quests:Update(d.questData.questId, "isVisible", not d.questData.isVisible)
		end
	})

    -- Create the "Delete" button
    d.inner.deleteButton = PQLFactory.Button:CreateIconButton(d.inner, {
        icon = "Delete",
        anchor = {"TOPRIGHT"},
        tooltipTitle = "Delete Quest",
        callback = function()
            PQL.confirmationPopup:Open({
                OnConfirm = function()
					if d.questData then
						PQL_DB.Quests:Delete(d.questData.questId)
					end
                    d:Close()
                end
            })
        end
    })

    d:SetupFields()
    d:SetupGoalsRegion()

	PQL_DB:On("Quests.Updated", function()
		if not d.isOpen then return end
		d:UpdateFields()
	end)

	PQL_DB:On("Goals.Updated", function()
		if not d.isOpen then return end
		d.inner.goals:Populate()
	end)

    d:Close()
end

function PQL.main.QuestDrawer:OnOpen(questId)
	d.questId = questId
    d:UpdateFields()

	if not PQL.db.profile.seenQuestDrawerHelp then
		PQL.main:ToggleHelp()
		PQL.db.profile.seenQuestDrawerHelp = true
	end
end

function PQL.main.QuestDrawer:OnClose()
	d.questId = nil
    d:UpdateFields()
end

function PQL.main.QuestDrawer:SetupFields()
    d.inner.fields = {}

    -- Field: Title
    d.inner.fields.title = PQLFactory.EditBox:CreateField(d.inner, "Quest Title", {
        placeholder = "Enter title",
        OnChanged = function(value)
			PQL_DB.Quests:Update(d.questData.questId, "questTitle", value:trim())
        end
    }, d.inner.title, -24)

    -- Field: Notes
    d.inner.fields.notes = PQLFactory.EditBox:CreateField(d.inner, "Quest Notes", {
        placeholder = "Enter notes",
        multiline = true,
        OnChanged = function(value)
			PQL_DB.Quests:Update(d.questData.questId, "questNotes", value:trim())
        end,
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
	d.inner.goalsTitle:SetPoint("TOPLEFT", d.inner.fields.notes.editBox, "BOTTOMLEFT", 0, -24)

	PQLSetFont(d.inner.goalsTitle, {
		size = 18,
		text = "Quest Goals"
	})

	-- Region
	d.inner.goalsRegion = CreateFrame("Frame", nil, d.inner)

	PQLSetPoints(d.inner.goalsRegion, {
		{"TOPLEFT", d.inner.goalsTitle, "BOTTOMLEFT", 0, -24},
		{"RIGHT"}
	})

	-- List
    d.inner.goals = PQLFactory.DynamicList:Create(d.inner.goalsRegion, {
        actions = PQL.main.QuestDrawer.goalsActions,
        spacing = 12
    })

    d.inner.goalsRegion.addButton = PQLFactory.Button:CreateButton(d.inner.goalsRegion, {
        text = "Add Goal",
        width = 80,
        anchor = {
            {"TOPLEFT", d.inner.goalsRegion, "BOTTOMLEFT", 0, -12},
            {"RIGHT"}
        },
        callback = function()
            PQL_DB.Goals:Create(d.questData.questId)
        end
    })

	-- Reposition the scroll frame bottom gutter
	d.inner.bottomGutter:SetPoint("TOPLEFT", d.inner.goalsRegion.addButton, "BOTTOMLEFT")
end

function PQL.main.QuestDrawer:UpdateFields()
    local quest = PQL_DB.Quests:Get(d.questId)
    d.questData = quest or {}

	-- Update the visibility button
	d.inner.visibilityButton:Update({
		icon = d.questData.isVisible and "VisibleOn" or "VisibleOff"
	})

	-- Update fields
    if quest then
        d.inner.fields.title.editBox:SetValue(quest.questTitle)
        d.inner.fields.notes.editBox:SetValue(quest.questNotes)
    else
        d.inner.fields.title.editBox:SetValue("")
        d.inner.fields.notes.editBox:SetValue("")
    end

	-- Update goals
    d.inner.goals:Populate()
end

-------------------------------------------------------------------------------
-- FACTORY | Goal
-------------------------------------------------------------------------------

PQL.main.QuestDrawer.goalsActions = {
    FetchEntries = function()
        return PQL_DB.Goals:GetByQuest(d.questData.questId)
    end,

    Create = function(parent)
        local goalFrame = CreateFrame("Frame", nil, parent)
        goalFrame:SetHeight(24)

        goalFrame.goalTypeButton = PQLFactory.Button:CreateButton(goalFrame, {
            width = 70,
            anchor = {{"TOPLEFT"}},
            isCustomStates = true,
            tooltipTitle = "Goal Type",
            tooltipBody = function()
                GameTooltip:AddLine("Double-click to change.", 1, 1, 1, true)
                GameTooltip:AddLine("[Custom]", 0.463, 1, 0.902, true)
                GameTooltip:AddLine("- A simple goal you can track by manually completing it.", 1, 1, 1, true)
                GameTooltip:AddLine("[Item]", 1, 0.459, 1, true)
                GameTooltip:AddLine("- Track a certain amount of an item.", 1, 1, 1, true)
                GameTooltip:AddLine("[Currency]", 0.855, 1, 0.459, true)
                GameTooltip:AddLine("- Track a certain amount of a currency.", 1, 1, 1, true)
            end,
            isDoubleClick = true,
            callback = function()
                local currentGoalType = goalFrame.entryData.goalType
                local newGoalType = currentGoalType + 1
                if newGoalType > #PQL_DB.Goals.CONST.goalTypes then newGoalType = 1 end
				PQL_DB.Goals:Update(goalFrame.entryData.goalId, "goalType", newGoalType)
            end
        })

        -- Fields
        goalFrame.fields = CreateFrame("Frame", nil, goalFrame)

        PQLSetPoints(goalFrame.fields, {
            {"TOPLEFT", goalFrame, "TOPLEFT", 78, 0},
            {"BOTTOMRIGHT", goalFrame, "BOTTOMRIGHT", -32, 0}
        })

		goalFrame.fields.tabs = d:CreateGoalFieldTabs(goalFrame)

        -- Delete Button
        goalFrame.deleteButton = PQLFactory.Button:CreateIconButton(goalFrame, {
            icon = "Delete",
            anchor = {"TOPRIGHT"},
            callback = function()
                PQL.confirmationPopup:Open({
                    OnConfirm = function()
                        PQL_DB.Goals:Delete(goalFrame.entryData.goalId)
                    end
                })
            end
        })

        return goalFrame
    end,

    Init = function(goalFrame)
        local goalTypeLabel = PQL_DB.Goals:GetGoalTypeLabel(goalFrame.entryData.goalType)

        PQLNineSlice(goalFrame.goalTypeButton, "GoalType-"..goalTypeLabel)
        goalFrame.goalTypeButton.text:SetText(goalTypeLabel)

		-- Show the correct field tab.
		for goalType, fields in pairs(goalFrame.fields.tabs) do
			if goalType == goalFrame.entryData.goalType then
				fields:Show()
			else
				fields:Hide()
			end
		end

		-- Update tab fields.
		for fieldKey, field in pairs(goalFrame.fields.tabs[goalFrame.entryData.goalType]) do
			if type(field) == "table" then
				local fieldValue = goalFrame.entryData.goalDetails[fieldKey] or ""
				field:SetValue(fieldValue)
			end
		end
    end
}

function PQL.main.QuestDrawer:CreateGoalFieldTabs(goalFrame)
	local tabs = {}

	-- Fields (Goal Type: Custom)
	tabs[1] = CreateFrame("Frame", nil, goalFrame.fields)
	tabs[1]:SetAllPoints(goalFrame.fields)

	tabs[1].description = PQLFactory.EditBox:Create(tabs[1], {
		placeholder = "Description",
		OnChanged = function(value)
			PQL_DB.Goals:Update(goalFrame.entryData.goalId, "description", value:trim(), true)
		end
	})

	PQLSetPoints(tabs[1].description, {{"TOPLEFT"}, {"TOPRIGHT"}})

	-- Fields (Goal Type: Item)
	tabs[2] = CreateFrame("Frame", nil, goalFrame.fields)
	tabs[2]:SetAllPoints(goalFrame.fields)

	tabs[2].resourceId = PQLFactory.EditBox:Create(tabs[2], {
		placeholder = "Item ID",
		tooltipTitle = "Item ID",
		tooltipBody = "Paste item ID here, or shift-click an item from your bag or a vendor.",
		OnChanged = function(value)
			PQL_DB.Goals:Update(goalFrame.entryData.goalId, "resourceId", value, true)
		end,
		FilterDisplayValue = function(value)
			if not value or value:trim() == "" then return "" end
			local _, itemLink = GetItemInfo(value)
			return itemLink or value.." (Invalid ID)"
		end,
		FilterModifiedItemClick = function(itemId)
			return itemId
		end
	})

	PQLSetPoints(tabs[2].resourceId, {
		{"TOPLEFT"},
		{"TOPRIGHT", goalFrame.fields, "TOPRIGHT", -108, 0},
	})

	tabs[2].requiredCount = PQLFactory.EditBox:Create(tabs[2], {
		placeholder = "Count",
		OnChanged = function(value)
			PQL_DB.Goals:Update(goalFrame.entryData.goalId, "requiredCount", value, true)
		end,
		FilterValue = function(value)
			local n = value:gsub("%D", "")
			return n and tonumber(n) or n
		end
	})

	PQLSetPoints(tabs[2].requiredCount, {
		{"TOPLEFT", goalFrame.fields, "TOPRIGHT", -100, 0},
		{"TOPRIGHT"}
	})

	-- Fields (Goal Type: Currency)
	tabs[3] = CreateFrame("Frame", nil, goalFrame.fields)
	tabs[3]:SetAllPoints(goalFrame.fields)

	tabs[3].resourceId = PQLFactory.EditBox:Create(tabs[3], {
		placeholder = "Currency ID",
		OnChanged = function(value)
			PQL_DB.Goals:Update(goalFrame.entryData.goalId, "resourceId", value, true)
		end,
		FilterDisplayValue = function(value)
			if not value or value:trim() == "" then return "" end
			local currencyInfo = PQL_Data.Currencies:Get(value)
			return currencyInfo and currencyInfo.link or value.." (Invalid ID)"
		end
	})

	PQLSetPoints(tabs[3].resourceId, {
		{"TOPLEFT"},
		{"TOPRIGHT", goalFrame.fields, "TOPRIGHT", -108, 0}
	})

	tabs[3].requiredCount = PQLFactory.EditBox:Create(tabs[3], {
		placeholder = "Count",
		OnChanged = function(value)
			PQL_DB.Goals:Update(goalFrame.entryData.goalId, "requiredCount", value, true)
		end,
		FilterValue = function(value)
			local n = value:gsub("%D", "")
			return n and tonumber(n) or n
		end
	})

	PQLSetPoints(tabs[3].requiredCount, {
		{"TOPLEFT", goalFrame.fields, "TOPRIGHT", -100, 0},
		{"TOPRIGHT"}
	})

	return tabs
end

