PQL_DB_INITIAL_DATABASE.profile.quests = {
	idCache = 0,
	entries = {}
}

PQL_DB.Quests = {}

function PQL_DB.Quests:GetClean()
	return PQLTable.clean(PQL.db.profile.quests.entries)
end

function PQL_DB.Quests:GetOrdered()
	local quests = self:GetClean()

	table.sort(quests, function(a, b)
		return a.questOrder < b.questOrder
	end)

	return quests
end

function PQL_DB.Quests:Get(questId)
	return PQLTable.fromKeyValue(self:GetClean(), "questId", questId)
end

function PQL_DB.Quests:GetByGroup(groupId, visibleOnly)
	local quests = self:GetOrdered()
	local groupQuests = {}

	for _, quest in ipairs(quests) do
		if quest.groupId == groupId then
			if (visibleOnly and quest.isVisible) or not visibleOnly then
				table.insert(groupQuests, quest)
			end
		end
	end

	return groupQuests
end

function PQL_DB.Quests:GetAtOrder(questOrder, groupId)
	local groupQuests = self:GetByGroup(groupId)
	return PQLTable.fromKeyValue(groupQuests, "questOrder", questOrder)
end

function PQL_DB.Quests:Create(groupId, data)
	local id = PQL.db.profile.quests.idCache + 1
	PQL.db.profile.quests.idCache = id

	if not data then data = {} end

	local quest = {
		groupId = groupId,
		isVisible = true,
		questId = id,
		questTitle = data.questTitle or "",
		questNotes = data.questNotes or "",
		questOrder = PQLTable.length(self:GetByGroup(groupId)) + 1
	}

	table.insert(PQL.db.profile.quests.entries, quest)

	PQL_DB:Fire("Quests.Created")
	PQL_DB:Fire("Quests.Updated")

	return quest
end

function PQL_DB.Quests:Update(questId, prop, value, isDetail, isShallow)
	local quest = self:Get(questId)
	if not quest then return end
	local previousGroupId = quest.groupId -- Used for resetting order later.

	if isDetail then
		quest.questDetails[prop] = value
	else
		quest[prop] = value
	end

	if prop == "groupId" then
		-- Group was changed. Reset the order.
		self:_ResetOrder(value, quest.questId)
		self:_ResetOrder(previousGroupId)
	end

	PQL_DB:Fire("Quests.Updated")

	if not isShallow then
		PQL_DB:Fire("Quests.Updated.DeepOnly")
	end
end

function PQL_DB.Quests:Reorder(questId, direction)
	local quest = self:Get(questId)
	if not quest then return end

	local prevOrder = quest.questOrder
	local newOrder = quest.questOrder + direction

	local numQuests = PQLTable.length(self:GetByGroup(quest.groupId))

	if newOrder <= 0 or newOrder > numQuests then
		-- Not possible to reorder in that direction.
		return
	end

	local otherQuest = self:GetAtOrder(newOrder, quest.groupId)

	-- Swap orders.
	self:Update(otherQuest.questId, "questOrder", prevOrder)
	self:Update(quest.questId, "questOrder", newOrder)
end

function PQL_DB.Quests:Delete(questId)
	local quests = self:GetOrdered()
	local newQuests = {}

	local deletedQuestGroupId = nil
	local deleted = false

	for _, quest in ipairs(quests) do
		if quest.questId ~= questId then
			table.insert(newQuests, quest)
		else
			deletedQuestGroupId = quest.groupId
			deleted = true
		end
	end

	-- Stop here if no quest was deleted.
	if not deleted then return end

	-- Update the main list.
	PQL.db.profile.quests.entries = newQuests

	-- Reset the order.
	newQuests = self:_ResetOrder(deletedQuestGroupId)

	PQL_DB:Fire("Quests.Deleted")
	PQL_DB:Fire("Quests.Updated")
end

function PQL_DB.Quests:_ResetOrder(groupId, lastId)
	local quests = self:GetOrdered()
	local numQuests = PQLTable.length(self:GetByGroup(groupId))
	local order = 1

	for i, quest in ipairs(quests) do
		if quest.groupId == groupId then
			if quest.questId == lastId then
				quest.questOrder = numQuests -- Last position.
			else
				quest.questOrder = order
				order = order + 1
			end
		end
	end
end

