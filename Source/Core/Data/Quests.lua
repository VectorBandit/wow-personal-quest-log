PQL.DATA.DEFAULT_DB.profile.quests = {
	idCache = 0,
	v2fixed = false,
	v2entries = {},
}

PQL.DATA.QUESTS = {}

function PQL.DATA.QUESTS:_ResetOrder(groupID, lastID)
	local quests = self:GetAll()
	local lastOrder = PQLTable.length(self:GetByGroup(groupID))

	local order = 1

	for _, quest in ipairs(quests) do
		if quest.groupID == groupID then
			if quest.questID == lastID then
				quest.order = lastOrder
			else
				quest.order = order
				order = order + 1
			end
		end
	end
end

function PQL.DATA.QUESTS:_ApplyV2Fix()
	if PQL.DATA.db.profile.quests.v2fixed then return end
	if not PQL.DATA.db.profile.quests.entries then return end

	local newQuests = {}
	local groupIDs = {}

	for _, quest in ipairs(PQL.DATA.db.profile.quests.entries) do
		if not tContains(groupIDs, quest.groupId) then
			table.insert(groupIDs, quest.groupId)
		end

		table.insert(newQuests, {
			questID = quest.questId,
			groupID = quest.groupId,
			isVisible = quest.isVisible or true,
			title = quest.questTitle or "",
			notes = quest.questNotes or "",
		})
	end

	PQL.DATA.db.profile.quests.v2entries = newQuests
	PQL.DATA.db.profile.quests.v2fixed = true

	for _, groupID in ipairs(groupIDs) do
		self:_ResetOrder(groupID)
	end
end

function PQL.DATA.QUESTS:GetAll()
	table.sort(PQL.DATA.db.profile.quests.v2entries, function(a, b)
		if not a.order then return false end
		if not b.order then return true end
		return a.order < b.order
	end)

	return PQL.DATA.db.profile.quests.v2entries
end

function PQL.DATA.QUESTS:Get(questID)
	return PQLTable.fromKeyValue(self:GetAll(), "questID", questID)
end

function PQL.DATA.QUESTS:GetByGroup(groupID, visibleOnly)
	local quests = PQLTable.fromKeyValue(self:GetAll(), "groupID", groupID, true)

	if not visibleOnly then
		return quests
	else
		return PQLTable.fromKeyValue(quests, "isVisible", true, true)
	end
end

function PQL.DATA.QUESTS:GetAtOrder(order, groupID)
	local quests = self:GetByGroup(groupID)
	return PQLTable.fromKeyValue(quests, "order", order)
end

function PQL.DATA.QUESTS:Create(groupID, questData)
	local questID = PQL.DATA.db.profile.quests.idCache + 1
	PQL.DATA.db.profile.quests.idCache = questID

	if not questData then questData = {} end

	local quest = {
		questID = questID,
		groupID = groupID,
		isVisible = true,
		title = questData.title or "",
		notes = questData.notes or "",
		order = PQLTable.length(self:GetByGroup(groupID)) + 1
	}

	table.insert(PQL.DATA.db.profile.quests.v2entries, quest)

	PQL.DATA:Fire("QUEST_CREATED", questID)

	return questID
end

function PQL.DATA.QUESTS:Update(questID, key, value, isStrict)
	local quest = self:Get(questID)
	if not quest then return end

	local previousGroupID = quest.groupID -- Used for resetting order later, if needed

	quest[key] = value

	if prop == "groupID" then
		-- Group was changed, reset the order
		self:_ResetOrder(value, quest.questID)
		self:_ResetOrder(previousGroupID)
	end

	if isStrict == nil then isStrict = true end
	PQL.DATA:Fire("QUEST_UPDATED", questID, isStrict)
end

function PQL.DATA.QUESTS:Reorder(questID, direction)
	local quest = self:Get(questID)
	if not quest then return end

	local prevOrder = quest.order
	local newOrder = quest.order + direction

	local numQuests = PQLTable.length(self:GetByGroup(quest.groupID))

	if newOrder <= 0 or newOrder > numQuests then
		-- Not possible to reorder in that direction
		return
	end

	local otherQuest = self:GetAtOrder(newOrder, quest.groupID)

	self:Update(otherQuest.questID, "order", prevOrder)
	self:Update(quest.questID, "order", newOrder)
end

function PQL.DATA.QUESTS:Delete(questID)
	local quests = self:GetAll()
	local newQuests = {}

	local deletedQuestGroupID = nil
	local deleted = false

	for _, quest in ipairs(quests) do
		if quest.questID ~= questID then
			table.insert(newQuests, quest)
		else
			deletedQuestGroupID = quest.groupID
			deleted = true
		end
	end

	-- Stop here if no quest was deleted
	if not deleted then return end

	-- Update the main list
	PQL.DATA.db.profile.quests.v2entries = newQuests

	-- Reset the order
	self:_ResetOrder(deletedQuestGroupId)

	PQL.DATA:Fire("QUEST_DELETED", questID)
end
