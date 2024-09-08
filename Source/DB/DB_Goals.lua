PQL_DB_INITIAL_DATABASE.profile.goals = {
    idCache = 0,
    entries = {}
}

PQL_DB.Goals = {
    CONST = {
        goalTypes = {
            "Custom",
            "Item",
            "Currency"
        }
    }
}

function PQL_DB.Goals:GetClean()
    return PQLTable.clean(PQL.db.profile.goals.entries)
end

function PQL_DB.Goals:GetByQuest(questId)
    local goals = self:GetClean()
    local questGoals = {}

    for _, goal in ipairs(goals) do
        if goal.questId == questId then
            table.insert(questGoals, goal)
        end
    end

    return questGoals
end

function PQL_DB.Goals:GetCount(questId)
	local completed = 0
	local pending = 0
	local goals = self:GetByQuest(questId)

	for _, goal in ipairs(goals) do
		if goal.isCompleted then
			completed = completed + 1
		else
			pending = pending + 1
		end
	end

	return unpack({completed, pending, PQLTable.length(goals)})
end

function PQL_DB.Goals:Get(goalId)
    return PQLTable.fromKeyValue(self:GetClean(), "goalId", goalId)
end

function PQL_DB.Goals:GetGoalTypeLabel(goalType)
    return PQL_DB.Goals.CONST.goalTypes[goalType] or "[INVALID_TYPE]"
end

function PQL_DB.Goals:Create(questId, data)
    local id = PQL.db.profile.goals.idCache + 1
    PQL.db.profile.goals.idCache = id

	if not data then data = {} end

    local goal = {
        questId = questId,
        isCompleted = false,
        goalId = id,
        goalType = data.goalType or 1,
        goalDetails = data.goalDetails or {}
    }

    table.insert(PQL.db.profile.goals.entries, goal)

    PQL_DB:Fire("Goals.Created")
    PQL_DB:Fire("Goals.Updated")

    return goal
end

function PQL_DB.Goals:Update(goalId, prop, value, isDetail, silent)
	local goal = self:Get(goalId)
	if not goal then return end

	if isDetail then
		goal.goalDetails[prop] = value
	else
		goal[prop] = value
	end

	if not silent then PQL_DB:Fire("Goals.Updated") end
end

function PQL_DB.Goals:Delete(goalId)
    local goals = self:GetClean()
    local newGoals = {}

    for _, goal in ipairs(goals) do
        if goal.goalId ~= goalId then
            table.insert(newGoals, goal)
        end
    end

    PQL.db.profile.goals.entries = newGoals

    PQL_DB:Fire("Goals.Deleted")
    PQL_DB:Fire("Goals.Updated")
end

