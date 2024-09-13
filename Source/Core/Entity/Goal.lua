PQL.ENTITY.Goal = {}

local function BuildResourceCountText(e)
	local required = e:Get("requiredCount", 0)
	required = tonumber(required) or 0

	local current = e:Get("currentCount", 0)
	current = tonumber(current) or 0

	-- NOTE: Clamping is disabled until the total amount of required
	-- resources is shown in the Group display. This allows the player
	-- to know if they have enough resources to complete many objectives
	-- that require the same resource.
	--------------------------------------------------------------------
	-- if current > required then current = required end

	return string.format("%d/%d", current, required)
end

local function Instantiate(data)
	local e = {data = data}

	function e:Get(key, default)
		return self.data[key] or default
	end

	function e:GetNumber(key, default)
		return tonumber(self:Get(key, default)) or default or 0
	end

	function e:GetID()
		return self:Get("goalID")
	end

	function e:AsyncGetText(callback)
		if self:IsType(PQL_GOALTYPE_CUSTOM) then
			local description = self:Get("description", "")
			if description:trim() == "" then description = "[NO_TEXT]" end

			callback(description)

		elseif self:IsType(PQL_GOALTYPE_ITEM) then
			PQL.UTIL.ITEM:Get(self:Get("resourceID"), function(item)
				local countText = BuildResourceCountText(self)
				local itemName = item and item.name or "[ITEM_NOT_FOUND]"

				callback(string.format("%s %s", countText, itemName))
			end)

		elseif self:IsType(PQL_GOALTYPE_CURRENCY) then
			local countText = BuildResourceCountText(self)
			local currency = PQL.UTIL.CURRENCY:Get(self:Get("resourceID"))
			local currencyName = currency and currency.name or "[CURRENCY_NOT_FOUND]"

			callback(string.format("%s %s", countText, currencyName))

		elseif self:IsType(PQL_GOALTYPE_UNIT) then
			local countText = BuildResourceCountText(self)
			local unitName = PQL.UTIL.UNIT:GetNameFromID(self:Get("unitID"))
			if not unitName then unitName = "[UNIT_NOT_FOUND]" end

			callback(string.format("%s %s", countText, unitName))

		else
			callback("[UNSUPPORTED_GOAL_TYPE]")
		end
	end

	function e:GetQuest()
		return PQL.ENTITY.Quest:ByID(self:Get("questID"))
	end

	function e:IsType(type)
		return self:Get("type") == type
	end

	function e:IsCompleted()
		return self:Get("isCompleted")
	end

	function e:Update(key, value, isStrict)
		PQL.DATA.GOALS:Update(self:GetID(), key, value, isStrict)
	end

	function e:Reorder(direction)
		PQL.DATA.GOALS:Reorder(self:GetID(), direction)
	end

	function e:SetType(type)
		self:Update("type", type)
	end

	function e:SetCompleted(isCompleted)
		self:Update("isCompleted", isCompleted, PQL_NOT_STRICT)
	end

	function e:MaybeToggleCompleted()
		-- Only possible for CUSTOM goal types.
		if self:IsType(PQL_GOALTYPE_CUSTOM) then
			self:SetCompleted(not self:IsCompleted())
		end
	end

	function e:ResetProgress()
		self:Update("currentCount", 0)
		self:SetCompleted(false)

		if self:Get("damagedUnits") then
			self:Update("damagedUnits", {})
		end
	end

	function e:Delete()
		PQL.DATA.GOALS:Delete(self:GetID())
	end

	function e:Edit()
		PQL.main.QuestDrawer:Open(self:Get("questID"))
	end

	function e:ShowTooltip(anchorTo)
		if self:IsType(PQL_GOALTYPE_ITEM) then
			PQL.UTIL.ITEM:ShowTooltip(self:Get("resourceID"), anchorTo)

		elseif self:IsType(PQL_GOALTYPE_CURRENCY) then
			PQL.UTIL.CURRENCY:ShowTooltip(self:Get("resourceID"), anchorTo)

		elseif self:IsType(PQL_GOALTYPE_UNIT) then
			PQL.UTIL.UNIT:ShowTooltip(self:Get("unitID"), anchorTo)
		end
	end

	return e
end

function PQL.ENTITY.Goal:Create(questID, data)
	local goalID = PQL.DATA.GOALS:Create(questID, data)
	return self:ByID(goalID)
end

function PQL.ENTITY.Goal:All()
	local goals = PQL.DATA.GOALS:GetAll()
	local result = {}

	for _, goal in ipairs(goals) do
		table.insert(result, Instantiate(goal))
	end

	return result
end

function PQL.ENTITY.Goal:ByID(goalID)
	local data = PQL.DATA.GOALS:Get(goalID)
	if not data then return nil end
	return Instantiate(data)
end

function PQL.ENTITY.Goal:ByType(type)
	local goals = PQL.DATA.GOALS:GetByType(type)
	local result = {}

	for _, goal in ipairs(goals) do
		table.insert(result, Instantiate(goal))
	end

	return result
end

function PQL.ENTITY.Goal:ByQuest(questID)
	local goals = PQL.DATA.GOALS:GetByQuest(questID)
	local result = {}

	for _, goal in ipairs(goals) do
		table.insert(result, Instantiate(goal))
	end

	return result
end

