PQL.GOALS = {}

function PQL.GOALS:Init()
	TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Unit, function(tooltip)
		if PQL.DATA:Get("showGoalsInTooltip") then
			self:ExtendUnitTooltip(tooltip)
		end
	end)

	TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Item, function(tooltip)
		if PQL.DATA:Get("showGoalsInTooltip") then
			self:ExtendItemTooltip(tooltip, data)
		end
	end)

	-- Process inventory-related goals when a goal is updated.
	PQL.DATA:On("GOAL_UPDATED", function(...)
		local _, goalID, _, key = ...
		local goal = PQL.ENTITY.GOAL:ByID(goalID)

		if goal:IsType(PQL_GOALTYPE_ITEM) or goal:IsType(PQL_GOALTYPE_CURRENCY) then
			if key == "requiredCount" or key == "resourceID" then
				-- Process inventory-related dependencies.
				self:ProcessInventoryDependentGoal(goal)
			end

		elseif goal:IsType(PQL_GOALTYPE_UNIT) then
			if key == "requiredCount" or key == "unitID" then
				-- Check if the goal is (still) completed after this change.
				self:DetermineGoalCompletion(goal)
			end
		end
	end)
end

local function AppendGoalsToTooltip(tooltip, filterFn)
	local quests = PQL.ENTITY.QUEST:All()
	local result = {}

	for _, quest in ipairs(quests) do
		local goals = quest:GetGoals()
		local displayedGoals = {}

		for _, goal in ipairs(goals) do
			if filterFn(goal) then
				table.insert(displayedGoals, goal)
			end
		end

		if PQLTable.length(displayedGoals) > 0 then
			tooltip:AddDoubleLine(quest:GetTitle(false), "PQL", 0.7, 0.9, 1, 0.7, 0.7, 0.7)

			for _, goal in ipairs(displayedGoals) do
				local c = goal:IsCompleted() and 0.7 or 1
				goal:AsyncGetText(function(text)
					tooltip:AddLine("- "..text, c, c, c, true)
				end)
			end
		end
	end
end

function PQL.GOALS:ExtendUnitTooltip(tooltip)
	local _, _, unitGUID = tooltip:GetUnit()
	if not unitGUID then return end

	local unitID = PQL.UTIL.UNIT:GetIDFromGUID(unitGUID)
	if not unitID then return end

	AppendGoalsToTooltip(tooltip, function(goal)
		return (
			goal:IsType(PQL_GOALTYPE_UNIT) and
			goal:GetNumber("unitID") == unitID
		)
	end)
end

function PQL.GOALS:ExtendItemTooltip(tooltip)
	local _, _, itemID = tooltip:GetItem()
	if not itemID then return end

	AppendGoalsToTooltip(tooltip, function(goal)
		return (
			goal:IsType(PQL_GOALTYPE_ITEM) and
			goal:GetNumber("resourceID") == itemID
		)
	end)
end

function PQL.GOALS:DetermineGoalCompletion(goal)
	local isCompleted = nil

	if (
		goal:IsType(PQL_GOALTYPE_ITEM) or
		goal:IsType(PQL_GOALTYPE_CURRENCY) or
		goal:IsType(PQL_GOALTYPE_UNIT)
		) then
		local required = goal:GetNumber("requiredCount")
		local current = goal:GetNumber("currentCount")
		isCompleted = current and required and required > 0 and current >= required
	end

	if isCompleted == nil then return end

	if isCompleted ~= goal:IsCompleted() then
		goal:SetCompleted(isCompleted)
	end
end

function PQL.GOALS:ProcessInventoryDependentGoal(goal)
	if goal:IsType(PQL_GOALTYPE_ITEM) then
		local current = PQL.UTIL.ITEM:GetCount(goal:GetNumber("resourceID"))
		goal:Update("currentCount", current, PQL_NOT_STRICT)
		self:DetermineGoalCompletion(goal)

	elseif goal:IsType(PQL_GOALTYPE_CURRENCY) then
		local current = PQL.UTIL.CURRENCY:GetCount(goal:GetNumber("resourceID"))
		goal:Update("currentCount", current, PQL_NOT_STRICT)
		self:DetermineGoalCompletion(goal)
	end
end

function PQL.GOALS:ProcessInventoryDependentGoals()
	local goals = PQL.ENTITY.GOAL:All()
	for _, goal in pairs(goals) do
		self:ProcessInventoryDependentGoal(goal)
	end
end

function PQL.GOALS:ProcessCombatDependentGoals()
	local _, eventType, _, sourceGUID, _, _, _, unitGUID, _, _, _ = CombatLogGetCurrentEventInfo()
	if not unitGUID then return end
	local unitID = PQL.UTIL.UNIT:GetIDFromGUID(unitGUID)
	if not unitID then return end

	local isDamageEvent = string.match(eventType, "_DAMAGE$")
	local isDeathEvent = eventType == "UNIT_DIED"

	-- No reason to continue if none of these are true.
	if not isDamageEvent and not isDeathEvent then return end

	local goals = PQL.ENTITY.GOAL:ByType(PQL_GOALTYPE_UNIT)
	for _, goal in ipairs(goals) do
		if goal:GetNumber("unitID") == unitID then
			local damagedUnits = goal:Get("damagedUnits", {})

			if isDamageEvent then
				-- Save the last unit that damaged the target unit.
				damagedUnits[unitGUID] = sourceGUID
				goal:Update("damagedUnits", damagedUnits, PQL_NOT_STRICT)
			else
				-- Check if the unit that killed the target unit is:
				-- >> Player in current Party or Raid
				-- >> Pet owned by someone in current Party or Raid
				local lastDamageSourceGUID = damagedUnits[unitGUID]
				if lastDamageSourceGUID then
					local lastDamageSourceInParty = PQL.UTIL.UNIT:IsInParty(lastDamageSourceGUID)
					if lastDamageSourceInParty then
						goal:Update("currentCount", goal:GetNumber("currentCount") + 1, PQL_NOT_STRICT)
						self:DetermineGoalCompletion(goal)
					end
				end
			end
		end
	end
end
