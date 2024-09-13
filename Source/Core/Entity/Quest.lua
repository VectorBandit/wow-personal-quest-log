PQL.ENTITY.Quest = {}

local function Instantiate(data)
	local e = {data = data}

	function e:Get(key, default)
		return self.data[key] or default
	end

	function e:GetNumber(key, default)
		return tonumber(self:Get(key, default)) or default or 0
	end

	function e:GetID()
		return self:Get("questID")
	end

	function e:GetTitle(includeGoals)
		local title = self:Get("title")

		if not title or title:trim() == "" then
			title = string.format("[ID: %d]", self:GetID())
		end

		if not includeGoals then
			return title
		end

		local totalCount, completedCount = PQL.DATA.GOALS:GetByQuestCount(self:GetID())

		if totalCount > 0 then
			return string.format("%s (%d/%d)", title, completedCount, totalCount)
		else
			return title
		end
	end

	function e:GetSimpleTitle()
	end

	function e:GetGroup()
		return PQL.ENTITY.Group:ByID(self:Get("groupID"))
	end

	function e:GetGoals()
		return PQL.ENTITY.Goal:ByQuest(self:GetID())
	end

	function e:IsVisible()
		return self:Get("isVisible")
	end

	function e:Update(key, value, isStrict)
		PQL.DATA.QUESTS:Update(self:GetID(), key, value, isStrict)
	end

	function e:Reorder(direction)
		PQL.DATA.QUESTS:Reorder(self:GetID(), direction)
	end

	function e:Move(groupID)
		self:Update("groupID", groupID)
	end

	function e:ToggleVisible()
		self:Update("isVisible", not self:IsVisible())
	end

	function e:Delete()
		PQL.DATA.QUESTS:Delete(self:GetID())

		-- Delete Goals
		local goals = self:GetGoals()
		for _, goal in ipairs(goals) do goal:Delete() end
	end
	
	function e:Edit()
		PQL.main.QuestDrawer:Open(self:GetID())
	end

	return e
end

function PQL.ENTITY.Quest:Create(groupID, data)
	local questID = PQL.DATA.QUESTS:Create(groupID, data)
	return self:ByID(questID)
end

function PQL.ENTITY.Quest:All()
	local quests = PQL.DATA.QUESTS:GetAll()
	local result = {}

	for _, quest in ipairs(quests) do
		table.insert(result, Instantiate(quest))
	end

	return result
end

function PQL.ENTITY.Quest:ByID(questID)
	local data = PQL.DATA.QUESTS:Get(questID)
	if not data then return nil end
	return Instantiate(data)
end

function PQL.ENTITY.Quest:ByGroup(groupID, visibleOnly)
	local quests = PQL.DATA.QUESTS:GetByGroup(groupID, visibleOnly)
	local result = {}

	for _, quest in ipairs(quests) do
		table.insert(result, Instantiate(quest))
	end

	return result
end
