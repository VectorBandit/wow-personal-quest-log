PQL.DATA.DEFAULT_DB.profile.goals = {
    idCache = 0,
	v2fixed = false,
    v2entries = {}
}

PQL.DATA.GOALS = {}

function PQL.DATA.GOALS:_ResetOrder(questID)
	local goals = PQL.DATA.db.profile.goals.v2entries
	local order = 1

	for _, goal in ipairs(goals) do
		if goal.questID == questID then
			goal.order = order
			order = order + 1
		end
	end
end

function PQL.DATA.GOALS:_ApplyV2Fix()
	if PQL.DATA.db.profile.goals.v2fixed then return end
	if not PQL.DATA.db.profile.goals.entries then return end

	local newGoals = {}
	local questIDs = {}

	for _, goal in ipairs(PQL.DATA.db.profile.goals.entries) do
		if not tContains(questIDs, goal.questId) then
			table.insert(questIDs, goal.questId)
		end

		table.insert(newGoals, {
			goalID = goal.goalId,
			questID = goal.questId,
			isCompleted = goal.isCompleted or false,
			type = goal.goalType or PQL_GOALTYPE_CUSTOM,
			requiredCount = goal.goalDetails.requiredCount or 0,
			currentCount = goal.goalDetails.currentCount or 0,
			resourceID = goal.goalDetails.resourceId or 0,
		})
	end

	PQL.DATA.db.profile.goals.v2entries = newGoals
	PQL.DATA.db.profile.goals.v2fixed = true

	for _, questID in ipairs(questIDs) do
		self:_ResetOrder(questID)
	end
end

function PQL.DATA.GOALS:GetAll()
	table.sort(PQL.DATA.db.profile.goals.v2entries, function(a, b)
		if not a.order then return false end
		if not b.order then return true end
		return a.order < b.order
	end)

	return PQL.DATA.db.profile.goals.v2entries
end

function PQL.DATA.GOALS:Get(goalID)
    return PQLTable.fromKeyValue(self:GetAll(), "goalID", goalID)
end

function PQL.DATA.GOALS:GetByType(type)
	return PQLTable.fromKeyValue(self:GetAll(), "type", type, true)
end

function PQL.DATA.GOALS:GetByQuest(questID)
	return PQLTable.fromKeyValue(self:GetAll(), "questID", questID, true)
end

function PQL.DATA.GOALS:GetByQuestCount(questID)
	local goals = self:GetByQuest(questID)
	local completed = 0
	local pending = 0

	for _, goal in ipairs(goals) do
		if goal.isCompleted then
			completed = completed + 1
		else
			pending = pending + 1
		end
	end

	return unpack({PQLTable.length(goals), completed, pending})
end

function PQL.DATA.GOALS:GetAtOrder(order, questID)
	local goals = self:GetByQuest(questID)
	return PQLTable.fromKeyValue(goals, "order", order)
end

function PQL.DATA.GOALS:Create(questID, goalData)
    local goalID = PQL.DATA.db.profile.goals.idCache + 1
    PQL.DATA.db.profile.goals.idCache = goalID

	if not goalData then goalData = {} end

    local goal = {
        goalID = goalID,
        questID = questID,
        isCompleted = false,
        type = goalData.type or PQL_GOALTYPE_CUSTOM,
		order = PQLTable.length(self:GetByQuest(questID)) + 1,
    }

	for key, value in pairs(goalData) do
		goal[key] = value
	end

    table.insert(PQL.DATA.db.profile.goals.v2entries, goal)

	PQL.DATA:Fire("GOAL_CREATED", goalID)

    return goalID
end

function PQL.DATA.GOALS:Update(goalID, key, value, isStrict)
	local goal = self:Get(goalID)
	if not goal then return end

	goal[key] = value

	if isStrict == nil then isStrict = true end
	PQL.DATA:Fire("GOAL_UPDATED", goalID, isStrict, key)
end

function PQL.DATA.GOALS:Reorder(goalID, direction)
	local goal = self:Get(goalID)
	if not goal then return end

	local prevOrder = goal.order
	local newOrder = goal.order + direction

	local numGoals = PQLTable.length(self:GetByQuest(goal.questID))

	if newOrder <= 0 or newOrder > numGoals then
		-- Not possible to reorder in that direction
		return
	end

	local otherGoal = self:GetAtOrder(newOrder, goal.questID)

	self:Update(otherGoal.goalID, "order", prevOrder)
	self:Update(goal.goalID, "order", newOrder)
end

function PQL.DATA.GOALS:Delete(goalID)
    local goals = self:GetAll()
    local newGoals = {}

	local deletedGoalQuestID = nil
	local deleted = false

    for _, goal in ipairs(goals) do
        if goal.goalID ~= goalID then
            table.insert(newGoals, goal)
		else
			deletedGoalQuestID = goal.questID
			deleted = true
        end
    end

	-- Stop here if no goal was deleted
	if not deleted then return end

	-- Update the main list
    PQL.DATA.db.profile.goals.v2entries = newGoals

	-- Reset the order
	self:_ResetOrder(deletedGoalQuestID)

    PQL.DATA:Fire("GOAL_DELETED", goalID)
end

