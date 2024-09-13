PQL.main = PQL.FACTORY.Panel:Create("Main", {size = {280, 550}})

function PQL.main:Init()
    self.createGroupButton = PQL.FACTORY.Button:CreateIconButton(PQL.main, {
        icon = "Add",
        anchor = {"TOPLEFT", PQL.main, "TOPLEFT", 10, -10},
        tooltip = {title = "Create Group"},
        OnClick = function()
            PQL.ENTITY.Group:Create():Edit()
        end,
    })

	-- Add title
	self.title = self:CreateFontString(nil, "ARTWORK", "GameFontNormal")
	PQLSetFont(self.title, { text = "Personal Quest Log" })
	self.title:SetPoint("LEFT", self, "TOPLEFT", 44, -22)

    self.helpButton = PQL.FACTORY.Button:CreateIconButton(PQL.main, {
        icon = "Help",
        anchor = {"RIGHT", PQL.main, "TOPRIGHT", -44, -22},
        tooltip = {title = "Help"},
        OnClick = function() self:ToggleHelp() end,
    })

    self.closeButton = PQL.FACTORY.Button:CreateIconButton(PQL.main, {
        icon = "Close",
        anchor = {"RIGHT", PQL.main, "TOPRIGHT", -10, -22},
        OnClick = function() PQL.main:Hide() end,
    })

    self.inner.groups = PQL.FACTORY.DynamicList:Create(self.inner, {
        spacing = 12,
        actions = PQL.main.groupsActions
    })

	-- Update when Groups, Quests, or Goals are updated.
	PQL.DATA:On({
		"GROUP_CREATED",
		"GROUP_UPDATED",
		"GROUP_DELETED",
		"QUEST_CREATED",
		"QUEST_UPDATED",
		"QUEST_DELETED",
		"GOAL_CREATED",
		"GOAL_UPDATED",
		"GOAL_DELETED",
	}, function() self:UpdateList() end)

	self:UpdateList()
end

function PQL.main:OnShow()
	if not PQL.DATA:Get("seenHelp") then
		self:ToggleHelp()
		PQL.DATA:Set("seenHelp", true)
	end

	self:UpdateList()
end

function PQL.main:OnHide()
	HelpPlate_Hide()
end

function PQL.main:UpdateList()
	-- FIX: Implement better solution.
	-- PQL_Core:CheckAsyncGoalsCompletion()
	self.inner.groups:Populate()
end

function PQL.main:PrepareHelp()
	self.help = {
		FramePos = { x = 0, y = 0 },
		FrameSize = { width = 10, height = 10 },
	}

	-- Create Button
	table.insert(self.help, {
		ButtonPos = { x = -18, y = 0 },
		HighLightBox = { x = 4, y = -3, width = 38, height = 39 },
		ToolTipDir = "LEFT",
		ToolTipText = "Create a Quest Group!\n\nQuests can be moved between groups for better organization."
	})

	-- Groups List
	table.insert(self.help, {
		ButtonPos = { x = -18, y = -262 },
		HighLightBox = { x = 4, y = -49, width = 256, height = 497 },
		ToolTipDir = "LEFT",
		ToolTipText = "This is your main list of Groups, Quests, and Goals.\n\n"..
			"GROUPS: [Click] to Edit or [Right-Click] for more actions.\n\n"..
			"QUESTS: [Click] to Edit or [Right-Click] for more actions.\n\n"..
			"GOALS: [Double-Click] to complete custom goals. [Hover] to view Item and Currency information.\n\n"..
			"Item and Currency goals are completed automatically."
	})

	-- Any Drawer
	if self.GroupDrawer.isOpen or self.QuestDrawer.isOpen then
		-- Close Button
		table.insert(self.help, {
			ButtonPos = { x = 795, y = -252 },
			HighLightBox = { x = 777, y = -255, width = 39, height = 40 },
			ToolTipDir = "RIGHT",
			ToolTipText = "Close drawer."
		})
	end

	-- Group Drawer
	if self.GroupDrawer.isOpen then
		-- Delete Button
		table.insert(self.help, {
			ButtonPos = { x = 724, y = -14 },
			HighLightBox = { x = 708, y = -17, width = 39, height = 40 },
			ToolTipDir = "RIGHT",
			ToolTipText = "Delete this Quest Group."
		})

		-- Fields
		table.insert(self.help, {
			ButtonPos = { x = 724, y = -184 },
			HighLightBox = { x = 298, y = -60, width = 449, height = 294 },
			ToolTipDir = "RIGHT",
			ToolTipText = "This is the main information about this Group.\n\n"..
				"You can use the Notes field to save important information, and you can also [Right-Click] on Items to add links!"
		})

		-- Quests
		table.insert(self.help, {
			ButtonPos = { x = 724, y = -428 },
			HighLightBox = { x = 298, y = -356, width = 449, height = 190 },
			ToolTipDir = "RIGHT",
			ToolTipText = "This is where you manage all Quests from this Group.\n\n"..
				"AUTO-TRACKING\n\n"..
				"With this window open, you can [Shift-Click] any vendor item to automatically create a quest to track it.\n\n"..
				"The addon will also generate all the necessary goals to help you gather the required resources to acquire the item!"
		})
	end

	-- Quest Drawer
	if self.QuestDrawer.isOpen then
		-- Action Buttons
		table.insert(self.help, {
			ButtonPos = { x = 724, y = -14 },
			HighLightBox = { x = 635, y = -17, width = 112, height = 40 },
			ToolTipDir = "RIGHT",
			ToolTipText = "Move, Toggle Visibility, or Delete this Quest."
		})

		-- Fields
		table.insert(self.help, {
			ButtonPos = { x = 724, y = -184 },
			HighLightBox = { x = 298, y = -60, width = 449, height = 294 },
			ToolTipDir = "RIGHT",
			ToolTipText = "This is the main information about this Quest.\n\n"..
				"You can use the Notes field to save important information, and you can also [Right-Click] on Items to add links!"
		})

		-- Quests
		table.insert(self.help, {
			ButtonPos = { x = 724, y = -428 },
			HighLightBox = { x = 298, y = -356, width = 449, height = 190 },
			ToolTipDir = "RIGHT",
			ToolTipText = "This is where you manage all Goals for this Quest.\n\n"..
				"[Double-Click] on the Goal type to toggle between available options.\n\n"..
				"[Shift-Click] on items while editing a field to automatically paste the ID.\n\n"..
				"For currency IDs, visit Wowhead."
		})
	end
end

function PQL.main:ToggleHelp()
	if self.isHelpActive then
		self.isHelpActive = false
		HelpPlate_Hide()
	else
		self.isHelpActive = true
		self:PrepareHelp()

		HelpPlate_Show(self.help, self, self.helpButton)
	end
end

-------------------------------------------------------------------------------
-- FACTORY | Group
-------------------------------------------------------------------------------

PQL.main.groupsActions = {
    FetchEntries = function()
		return PQL.ENTITY.Group:All()
    end,

    Create = function(parent)
        local groupFrame = CreateFrame("Frame", nil, parent)
        PQLPrepareForText(groupFrame)

        -- Title (Click to Edit)
		groupFrame.title = PQL.FACTORY.Button:CreateButton(groupFrame, {
			style = "Faded",
			anchor = {{"TOPLEFT"}, {"RIGHT", -34, 0}},
			justify = "LEFT",
			OnClick = function() groupFrame.data:Edit() end,
			OnRightClick = function()
				PQL.dropdown:Open({
					{
						text = "Add quest",
						justify = "LEFT",
						OnClick = function() PQL.ENTITY.Quest:Create(groupFrame.data:GetID()):Edit() end
					},
				}, {
					{
						icon = "Delete",
						tooltip = {title = "Delete Group"},
						OnClick = function()
							PQL.confirmPopup:Open({
								text = "Deleting this group will also delete all quests associated with it.",
								OnConfirm = function() groupFrame.data:Delete() end
							})
						end
					},
					{
						icon = "ArrowDown",
						tooltip = {title = "Move Down"},
						OnClick = function() groupFrame.data:Reorder(1) end
					},
					{
						icon = "ArrowUp",
						tooltip = {title = "Move Up"},
						OnClick = function() groupFrame.data:Reorder(-1) end
					},
					{
						icon = "Edit",
						OnClick = function() groupFrame.data:Edit() end
					},
				})
			end
		})

		-- Collapse Button
        groupFrame.collapseButton = PQL.FACTORY.Button:CreateIconButton(groupFrame, {
            icon = "ChevronDown",
            anchor = {"TOPRIGHT"},
            OnClick = function() groupFrame.data:ToggleCollapsed() end
        })

        -- Inner Wrapper (Quests List)
        groupFrame.inner = CreateFrame("Frame", nil, groupFrame)
        PQLPrepareForText(groupFrame.inner)
        PQLSetPoints(groupFrame.inner, {{"TOPLEFT", groupFrame, "TOPLEFT", 0, -39}, {"TOPRIGHT"}})

        groupFrame.inner.quests = PQL.FACTORY.DynamicList:Create(groupFrame.inner, {
            actions = PQL.main.questsActions,
            spacing = 15
        })

        return groupFrame
    end,

    Init = function(groupFrame)
        groupFrame.title.text:SetText(groupFrame.data:GetTitle())

        groupFrame.collapseButton:Update({
			icon = groupFrame.data:IsCollapsed() and "ChevronLeft" or "ChevronDown"
		})

        -- Update the quests list.
		if groupFrame.data:IsCollapsed() then
			groupFrame.inner:Hide()
		else
			groupFrame.inner.quests:Populate(groupFrame.data:GetID())
			groupFrame.inner:Show()
		end

        -- Update the group frame height.
		local groupFrameHeight = groupFrame.data:IsCollapsed() and 24 or (
			24 + (groupFrame.inner.quests:IsEmpty() and 0 or 15 + groupFrame.inner:GetHeight())
		)

        groupFrame:SetHeight(groupFrameHeight)
    end
}

-------------------------------------------------------------------------------
-- FACTORY | Quest
-------------------------------------------------------------------------------

PQL.main.questsActions = {
    FetchEntries = function(groupID)
		return PQL.ENTITY.Quest:ByGroup(groupID, true)
    end,

    Create = function(parent)
        local questFrame = CreateFrame("Frame", nil, parent)
        PQLPrepareForText(questFrame)

        -- Title (Click to Edit)
        questFrame.title = CreateFrame("Button", nil, questFrame)
        PQLPrepareForText(questFrame.title)
        PQLSetPoints(questFrame.title, {{"TOPLEFT"}, {"RIGHT"}})

        questFrame.title:RegisterForClicks("AnyUp")
        questFrame.title:SetScript("OnClick", function(_, button)
			if button == "LeftButton" then
				questFrame.data:Edit()
			elseif button == "RightButton" then
				PQL.dropdown:Open({
					{
						text = "Move quest",
						OnClick = function()
							local options = PQL.ENTITY.Group:AsDropdownOptions(function(group)
								questFrame.data:Move(group:GetID())
							end)

							PQL.dropdown:Open(options)
						end
					},
					{
						text = "Hide quest",
						OnClick = function() questFrame.data:ToggleVisible() end
					},
				}, {
					{
						icon = "Delete",
						tooltip = {title = "Delete Quest"},
						OnClick = function()
							PQL.confirmPopup:Open({
								text = "Deleting this quest will also delete all goals associated with it.",
								OnConfirm = function() questFrame.data:Delete() end
							})
						end
					},
					{
						icon = "ArrowDown",
						tooltip = {title = "Move Down"},
						OnClick = function() questFrame.data:Reorder(1) end
					},
					{
						icon = "ArrowUp",
						tooltip = {title = "Move Up"},
						OnClick = function() questFrame.data:Reorder(-1) end
					},
					{
						icon = "Edit",
						OnClick = function() questFrame.data:Edit() end
					},
				})
			end
        end)

        questFrame.title.titleText = questFrame.title:CreateFontString(nil, "ARTWORK", "GameFontNormal")
        PQLSetPoints(questFrame.title.titleText, {{"TOPLEFT"}, {"RIGHT"}})
        PQLSetFont(questFrame.title.titleText, {
            size = 12,
            justify = "LEFT",
            align = "TOP",
            color = PQLTheme:ColorTable("text")
        })

        questFrame.title:SetScript("OnEnter", function()
            questFrame.title.titleText:SetTextColor(1, 1, 1, 1)
        end)

        questFrame.title:SetScript("OnLeave", function()
            questFrame.title.titleText:SetTextColor(PQLTheme:Color("text"))
        end)

        -- Inner (Goals List)
        questFrame.inner = CreateFrame("Frame", nil, questFrame)
        PQLPrepareForText(questFrame.inner)

        questFrame.inner.goals = PQL.FACTORY.DynamicList:Create(questFrame.inner, {
            actions = PQL.main.goalsActions
        })

        return questFrame
    end,

    Init = function(questFrame)
        questFrame.title.titleText:SetText(questFrame.data:GetTitle(true))
        questFrame.title:SetHeight(questFrame.title.titleText:GetStringHeight())

        -- The position needs to be set after the quest title has been calculated
        -- because its height will determine the goals list position.
        PQLSetPoints(questFrame.inner, {{"TOPLEFT", questFrame.title, "BOTTOMLEFT", 0, -14}, {"RIGHT"}})

        -- Populate the list of goals.
        questFrame.inner.goals:Populate(questFrame.data:GetID())

        -- Update the height of this frame to be the height of the quest title + spacing + the list height.
		local questFrameHeight = questFrame.title:GetHeight() + (
			questFrame.inner.goals:IsEmpty() and 0 or 14 + questFrame.inner:GetHeight()
		)

        questFrame:SetHeight(questFrameHeight)
    end
}

-------------------------------------------------------------------------------
-- FACTORY | Goal
-------------------------------------------------------------------------------

PQL.main.goalsActions = {
    FetchEntries = function(questID)
		return PQL.ENTITY.Goal:ByQuest(questID)
    end,

    Create = function(parent)
        local goalFrame = CreateFrame("Button", nil, parent)
        PQLPrepareForText(goalFrame)

		-- Status Icon
        goalFrame.statusIcon = PQL.FACTORY.StatusIcon:Create(goalFrame, {
            icon = "Check",
            anchor = {{"TOPLEFT"}}
        })

		-- Text
        goalFrame.text = goalFrame:CreateFontString(nil, "ARTWORK", "GameFontNormal")
        PQLSetPoints(goalFrame.text, {{"TOPLEFT", goalFrame, "TOPLEFT", 17, 0}, {"RIGHT"}})
        PQLSetFont(goalFrame.text, {
            size = 12,
            justify = "LEFT",
            color = {1, 1, 1, 0.7}
        })

		-- Setup manual completion for "Custom" goals.
        goalFrame:RegisterForClicks("LeftButtonUp")

		goalFrame:SetScript("OnClick", function() goalFrame.data:Edit() end)
        goalFrame:SetScript("OnDoubleClick", function() goalFrame.data:MaybeToggleCompleted() end)

		goalFrame:SetScript("OnEnter", function()
			goalFrame.text:SetTextColor(1, 1, 1, 1)
			goalFrame.data:ShowTooltip(goalFrame)
		end)

		goalFrame:SetScript("OnLeave", function()
			goalFrame.text:SetTextColor(1, 1, 1, 0.7)
			GameTooltip:Hide()
		end)

        return goalFrame
    end,

    Init = function(goalFrame)
		goalFrame.statusIcon:SetStatus(goalFrame.data:IsCompleted())

		goalFrame.data:AsyncGetText(function(text)
			goalFrame.text:SetText(text)
			goalFrame:SetHeight(goalFrame.text:GetStringHeight())
		end)
    end
}

