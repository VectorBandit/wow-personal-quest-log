PQL.main.GroupDrawer = PQLFactory.Drawer:Create({ title = "Group Details" })
PQL.main:AddModule("GroupDrawer")
PQL.main:AddDrawer("GroupDrawer")

local d = PQL.main.GroupDrawer

function PQL.main.GroupDrawer:Init()

    -- Create the "Delete" button
    d.inner.deleteButton = PQLFactory.Button:CreateIconButton(d.inner, {
        icon = "Delete",
        anchor = {"TOPRIGHT"},
        tooltipTitle = "Delete Group",
        callback = function()
            PQL.confirmationPopup:Open({
                OnConfirm = function()
					if d.groupData then
						PQL_DB.Groups:Delete(d.groupData.groupId)
					end
                    d:Close()
                end
            })
        end
    })

	-- Automatically create a quest when shift-clicking merchant items
	PQL:On("ModifiedItemClick", function(itemId)
		if not d.isOpen then return end

		local merchantItem = PQL_Data.Merchant:GetItemById(itemId)
		if merchantItem then
			local notes = "Item: "..merchantItem.link.."\n\n"
			notes = notes.."Location: "..PQL_Data.Links:MakePin()

			local quest = PQL_DB.Quests:Create(d.groupData.groupId, {
				questTitle = merchantItem.name,
				questNotes = notes
			})

			for _, resource in ipairs(merchantItem.cost) do
				PQL_DB.Goals:Create(quest.questId, {
					goalType = resource.type,
					goalDetails = {
						resourceId = resource.id,
						requiredCount = resource.amount
					}
				})
			end
		end
	end)

    d:SetupFields()
	d:SetupQuestsRegion()

	PQL_DB:On("Quests.Updated", function() d.inner.quests:Populate() end)

    d:Close()
end

function PQL.main.GroupDrawer:OnOpen(groupId)
	d.groupId = groupId
	d:UpdateFields()

	if not PQL.db.profile.seenGroupDrawerHelp then
		PQL.main:ToggleHelp()
		PQL.db.profile.seenGroupDrawerHelp = true
	end
end

function PQL.main.GroupDrawer:OnClose()
	d.groupId = nil
	d:UpdateFields()
end

function PQL.main.GroupDrawer:SetupFields()
    d.inner.fields = {}

    -- Field: Title
    d.inner.fields.title = PQLFactory.EditBox:CreateField(d.inner, "Group Title", {
        placeholder = "Enter title",
        OnChanged = function(value)
			PQL_DB.Groups:Update(d.groupData.groupId, "groupTitle", value:trim())
        end
    }, d.inner.title, -24)

    -- Field: Notes
    d.inner.fields.notes = PQLFactory.EditBox:CreateField(d.inner, "Group Notes", {
        placeholder = "Enter notes",
        multiline = true,
        OnChanged = function(value)
			PQL_DB.Groups:Update(d.groupData.groupId, "groupNotes", value:trim())
        end,
		FilterModifiedItemClick = function(_, itemLink)
			local c = d.inner.fields.notes.editBox.editBox:GetCursorPosition()
			local t = d.inner.fields.notes.editBox.editBox:GetText()

			return PQLString.insert(t, itemLink, c)
		end
    }, d.inner.fields.title.editBox)

    d.inner.fields.notes.editBox:SetHeight(200)
end

function PQL.main.GroupDrawer:SetupQuestsRegion()
	d.inner.questsTitle = d.inner:CreateFontString(nil, "ARTWORK", "GameFontNormal")
	d.inner.questsTitle:SetPoint("TOPLEFT", d.inner.fields.notes.editBox, "BOTTOMLEFT", 0, -24)

	PQLSetFont(d.inner.questsTitle, {
		size = 18,
		text = "Group Quests"
	})

	-- Region
	d.inner.questsRegion = CreateFrame("Frame", nil, d.inner)

	PQLSetPoints(d.inner.questsRegion, {
		{"TOPLEFT", d.inner.questsTitle, "BOTTOMLEFT", 0, -24},
		{"RIGHT"}
	})

	-- List
	d.inner.quests = PQLFactory.DynamicList:Create(d.inner.questsRegion, {
		actions = PQL.main.GroupDrawer.questsActions,
		spacing = 12
	})

	-- Add New
	d.inner.questsRegion.addButton = PQLFactory.Button:CreateButton(d.inner.questsRegion, {
		text = "Add Quest",
		width = 80,
		anchor = {
			{"TOPLEFT", d.inner.questsRegion, "BOTTOMLEFT", 0, -12},
			{"RIGHT"}
		},
		callback = function()
			PQL_DB.Quests:Create(d.groupData.groupId)
		end
	})

	-- Reposition the scroll frame bottom gutter
	d.inner.bottomGutter:SetPoint("TOPLEFT", d.inner.questsRegion.addButton, "BOTTOMLEFT")
end

function PQL.main.GroupDrawer:UpdateFields()
    local group = PQL_DB.Groups:Get(d.groupId)
    d.groupData = group or {}

    if group then
        d.inner.fields.title.editBox:SetValue(group.groupTitle)
        d.inner.fields.notes.editBox:SetValue(group.groupNotes)
    else
        d.inner.fields.title.editBox:SetValue("")
        d.inner.fields.notes.editBox:SetValue("")
    end

	d.inner.quests:Populate()
end

-------------------------------------------------------------------------------
-- FACTORY | Quest
-------------------------------------------------------------------------------

PQL.main.GroupDrawer.questsActions = {
	FetchEntries = function()
		return PQL_DB.Quests:GetByGroup(d.groupData.groupId)
	end,

	Create = function(parent)
		local questFrame = CreateFrame("Frame", nil, parent)
		questFrame:SetHeight(24)

		-- Field: Quest Title
		questFrame.questTitle = PQLFactory.EditBox:Create(questFrame, {
			placeholder = "Enter title",
			OnChanged = function(value)
				PQL_DB.Quests:Update(questFrame.entryData.questId, "questTitle", value)
			end
		})

		PQLSetPoints(questFrame.questTitle, {
			{"TOPLEFT"},
			{"TOPRIGHT", questFrame, "TOPRIGHT", -192, 0}
		})

		-- Edit Button
		questFrame.editButton = PQLFactory.Button:CreateIconButton(questFrame, {
			icon = "Edit",
			anchor = {"TOPRIGHT", questFrame, "TOPRIGHT", -160, 0},
			tooltipTitle = "Edit Quest",
			callback = function()
				PQL.main.QuestDrawer:Open(questFrame.entryData.questId)
			end
		})

		-- Move Button
		questFrame.moveButton = PQLFactory.Button:CreateIconButton(questFrame, {
			icon = "Move",
			anchor = {"TOPRIGHT", questFrame, "TOPRIGHT", -128, 0},
			tooltipTitle = "Move Quest",
			callback = function()
				local options = PQL_DB.Groups:GetAsDropdownOptions(function(group)
					PQL_DB.Quests:Update(questFrame.entryData.questId, "groupId", group.groupId)
				end)

				PQL.dropdown:Open(options)
			end
		})

		-- Visibility Button
		questFrame.visibilityButton = PQLFactory.Button:CreateIconButton(questFrame, {
			icon = "VisibleOn",
			anchor = {"TOPRIGHT", questFrame, "TOPRIGHT", -96, 0},
			tooltipTitle = "Toggle Quest Visibility",
			callback = function()
				PQL_DB.Quests:Update(questFrame.entryData.questId, "isVisible", not questFrame.entryData.isVisible)
			end
		})

		-- Move Up Button
		questFrame.moveUpButton = PQLFactory.Button:CreateIconButton(questFrame, {
			icon = "ArrowUp",
			anchor = {"TOPRIGHT", questFrame, "TOPRIGHT", -64, 0},
			tooltipTitle = "Move Up",
			callback = function()
				PQL_DB.Quests:Reorder(questFrame.entryData.questId, -1)
			end
		})

		-- Move Down Button
		questFrame.moveDownButton = PQLFactory.Button:CreateIconButton(questFrame, {
			icon = "ArrowDown",
			anchor = {"TOPRIGHT", questFrame, "TOPRIGHT", -32, 0},
			tooltipTitle = "Move Down",
			callback = function()
				PQL_DB.Quests:Reorder(questFrame.entryData.questId, 1)
			end
		})

		-- Delete Button
		questFrame.deleteButton = PQLFactory.Button:CreateIconButton(questFrame, {
			icon = "Delete",
			anchor = {"TOPRIGHT"},
			tooltipTitle = "Delete Quest",
			callback = function()
				PQL.confirmationPopup:Open({
					OnConfirm = function()
						PQL_DB.Quests:Delete(questFrame.entryData.questId)
					end
				})
			end
		})

		return questFrame
	end,

	Init = function(questFrame)
		questFrame.questTitle:SetValue(questFrame.entryData.questTitle)
		questFrame.visibilityButton:Update({
			icon = questFrame.entryData.isVisible and "VisibleOn" or "VisibleOff"
		})
	end
}

