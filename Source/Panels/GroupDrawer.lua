PQL.main.GroupDrawer = PQL.FACTORY.Drawer:Create("Group", { title = "Group Details" })
PQL.main:AddModule("GroupDrawer")
PQL.main:AddDrawer("GroupDrawer")

local d = PQL.main.GroupDrawer

function PQL.main.GroupDrawer:Init()
	-- Button: Delete
	PQL.FACTORY.Button:CreateIconButton(d, {
		icon = "Delete",
		anchor = {"TOPRIGHT", d, -20, -20},
		tooltip = {title = "Delete Group"},
		OnClick = function()
			PQL.confirmPopup:Open({
				text = "Deleting this group will also delete all quests associated with it.",
				OnConfirm = function()
					if d.data then d.data:Delete() end
					d:Close()
				end,
			})
		end
	})

	-- Automatically create a quest when shift-clicking merchant items.
	PQL:On("ModifiedItemClick", function(itemID)
		if not d.isOpen then return end

		local merchantItem = PQLUtil.Merchant:GetItemByID(itemID)
		if merchantItem then
			local notes = "Item: "..merchantItem.link.."\n\n"
			notes = notes.."Location: "..PQLUtil.Links:MakePin()

			local quest = PQL.ENTITY.Quest:Create(d.data:getID(), {
				title = merchantItem.name,
				notes = notes
			})

			for _, resource in ipairs(merchantItem.cost) do
				PQL.ENTITY.Goal:Create(quest:GetID(), {
					type = resource.type,
					resourceID = resource.id,
					requiredCount = resource.amount,
				})
			end
		end
	end)

	d:SetupFields()
	d:SetupQuestsRegion()

	PQL.DATA:On({
		"GROUP_UPDATED",
		"GROUP_DELETED",
		"QUEST_CREATED",
		"QUEST_UPDATED",
		"QUEST_DELETED",
	}, function(event, ...)
		if event == "GROUP_UPDATED" then
			local groupID, isStrict = ...
			if groupID == d.groupID and isStrict then self:UpdateFields() end
		elseif event == "GROUP_DELETED" then
			local groupID = select(1, ...)
			if groupID == d.groupID then d:Close() end
		elseif event == "QUEST_UPDATED" then
			local isStrict = select(2, ...)
			if isStrict then d.inner.quests:Populate() end
		elseif event == "QUEST_CREATED" or event == "QUEST_DELETED" then
			d.inner.quests:Populate()
		else
			PQL:Print("[UNHANDLED_EVENT] GroupDrawer", event)
		end
	end)

	d:Close()
end

function PQL.main.GroupDrawer:OnOpen(groupID)
	d.groupID = groupID
	d:UpdateFields()

	if not PQL.DATA:Get("seenGroupDrawerHelp") then
		PQL.main:ToggleHelp()
		PQL.DATA:Set("seenGroupDrawerHelp", true)
	end
end

function PQL.main.GroupDrawer:OnClose()
	d.groupID = nil
	d:UpdateFields()
end

function PQL.main.GroupDrawer:SetupFields()
	d.inner.fields = {}

	-- Field: Title
	d.inner.fields.title = PQL.FACTORY.EditBox:CreateField(d.inner, "Group Title", {
		placeholder = "Enter title",
		OnChanged = function(title) d.data:Update("title", title, PQL_NOT_STRICT) end,
	}, d.inner.title, -20)

	-- Field: Notes
	d.inner.fields.notes = PQL.FACTORY.EditBox:CreateField(d.inner, "Group Notes", {
		placeholder = "Enter notes",
		multiline = true,
		OnChanged = function(notes) d.data:Update("notes", notes, PQL_NOT_STRICT) end,
		FilterModifiedItemClick = function(_, itemLink)
			local c = d.inner.fields.notes.editBox.editBox:GetCursorPosition()
			local t = d.inner.fields.notes.editBox.editBox:GetText()

			return PQLString.insert(t, itemLink, c)
		end,
	}, d.inner.fields.title.editBox)

	d.inner.fields.notes.editBox:SetHeight(200)
end

function PQL.main.GroupDrawer:SetupQuestsRegion()
	d.inner.questsTitle = d.inner:CreateFontString(nil, "ARTWORK", "GameFontNormal")
	d.inner.questsTitle:SetPoint("TOPLEFT", d.inner.fields.notes.editBox, "BOTTOMLEFT", 0, -20)

	PQLSetFont(d.inner.questsTitle, {
		size = 18,
		text = "Group Quests"
	})

	-- Region
	d.inner.questsRegion = CreateFrame("Frame", nil, d.inner)

	PQLSetPoints(d.inner.questsRegion, {
		{"TOPLEFT", d.inner.questsTitle, "BOTTOMLEFT", 0, -20},
		{"RIGHT"}
	})

	-- List
	d.inner.quests = PQL.FACTORY.DynamicList:Create(d.inner.questsRegion, {
		actions = PQL.main.GroupDrawer.questsActions,
		spacing = 10
	})

	-- Add New
	d.inner.questsRegion.addButton = PQL.FACTORY.Button:CreateButton(d.inner.questsRegion, {
		text = "Add Quest",
		anchor = {
			{"TOPLEFT", d.inner.questsRegion, "BOTTOMLEFT", 0, -10},
			{"RIGHT"}
		},
		OnClick = function() PQL.ENTITY.Quest:Create(d.data:GetID()) end,
	})

	-- Reposition the scroll frame bottom gutter
	d.inner.bottomGutter:SetPoint("TOPLEFT", d.inner.questsRegion.addButton, "BOTTOMLEFT")
end

function PQL.main.GroupDrawer:UpdateFields()
	d.data = PQL.ENTITY.Group:ByID(d.groupID)

	d.inner.fields.title.editBox:SetValue(d.data and d.data:Get("title") or "")
	d.inner.fields.notes.editBox:SetValue(d.data and d.data:Get("notes") or "")

	d.inner.quests:Populate()
end

-------------------------------------------------------------------------------
-- FACTORY | Quest
-------------------------------------------------------------------------------

PQL.main.GroupDrawer.questsActions = {
	FetchEntries = function()
		return PQL.ENTITY.Quest:ByGroup(d.groupID)
	end,

	Create = function(parent)
		local questFrame = CreateFrame("Frame", nil, parent)
		questFrame:SetHeight(24)

		-- Field: Quest Title
		questFrame.questTitle = PQL.FACTORY.EditBox:Create(questFrame, {
			placeholder = "Enter title",
			tooltip = {
				title = "Quest",
				body = function() return questFrame.questTitle.editBox:GetText() end,
			},
			OnChanged = function(title) questFrame.data:Update("title", title, PQL_NOT_STRICT) end,
		})

		PQLSetPoints(questFrame.questTitle, {
			{"TOPLEFT"},
			{"TOPRIGHT", questFrame, "TOPRIGHT", -102, 0}
		})

		-- Edit Button
		questFrame.editButton = PQL.FACTORY.Button:CreateIconButton(questFrame, {
			icon = "Edit",
			anchor = {"TOPRIGHT", questFrame, "TOPRIGHT", -68, 0},
			tooltip = {title = "Edit Quest"},
			OnClick = function() questFrame.data:Edit() end,
		})

		-- Visibility Button
		questFrame.visibilityButton = PQL.FACTORY.Button:CreateIconButton(questFrame, {
			icon = "VisibleOn",
			anchor = {"TOPRIGHT", questFrame, "TOPRIGHT", -34, 0},
			tooltip = {title = "Toggle Quest Visibility"},
			OnClick = function() questFrame.data:ToggleVisible() end,
		})

		-- Options
		questFrame.optionsButton = PQL.FACTORY.Button:CreateIconButton(questFrame, {
			icon = "Dropdown",
			anchor = {"TOPRIGHT"},
			tooltip = {title = "Options"},
			OnClick = function()
				PQL.dropdown:Open({
					{
						text = "Move quest",
						OnClick = function()
							local options = PQL.ENTITY.Group:AsDropdownOptions(function(group)
								questFrame.data:Move(group:GetID())
							end)

							PQL.dropdown:Open(options)
						end,
					},
				}, {
					{
						icon = "Delete",
						tooltip = {title = "Delete Quest"},
						OnClick = function()
							PQL.confirmPopup:Open({
								text = "Deleting this quest will also delete all goals associated with it.",
								OnConfirm = function() questFrame.data:Delete() end,
							})
						end,
					},
					{
						icon = "ArrowDown",
						tooltip = {title = "Move Down"},
						OnClick = function() questFrame.data:Reorder(1) end,
					},
					{
						icon = "ArrowUp",
						tooltip = {title = "Move Up"},
						OnClick = function() questFrame.data:Reorder(-1) end,
					},
					{
						icon = "Edit",
						OnClick = function() questFrame.data:Edit() end,
					},
				})
			end,
		})

		return questFrame
	end,

	Init = function(questFrame)
		questFrame.questTitle:SetValue(questFrame.data:Get("title"))
		questFrame.visibilityButton:Update({
			icon = questFrame.data:IsVisible() and "VisibleOn" or "VisibleOff",
			style = questFrame.data:IsVisible() and "" or "Transparent",
		})
	end
}

