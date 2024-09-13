PQL.ENTITY.Group = {}

local function Instantiate(data)
	local e = {data = data}

	function e:Get(key, default)
		return self.data[key] or default
	end

	function e:GetNumber(key, default)
		return tonumber(self:Get(key, default)) or default or 0
	end

	function e:GetID()
		return self:Get("groupID")
	end

	function e:GetTitle()
		return self:Get("title") and self:Get("title"):trim() or ""
	end

	function e:GetQuests()
		return PQL.ENTITY.Quest:ByGroup(self:GetID())
	end

	function e:IsCollapsed()
		return self:Get("isCollapsed")
	end

	function e:Update(key, value, isStrict)
		PQL.DATA.GROUPS:Update(self:GetID(), key, value, isStrict)
	end

	function e:Reorder(direction)
		PQL.DATA.GROUPS:Reorder(self:GetID(), direction)
	end

	function e:ToggleCollapsed()
		self:Update("isCollapsed", not self:IsCollapsed())
	end

	function e:Delete()
		PQL.DATA.GROUPS:Delete(self:GetID())

		-- Delete Quests
		local quests = self:GetQuests()
		for _, quest in ipairs(quests) do quest:Delete() end
	end

	function e:Edit()
		PQL.main.GroupDrawer:Open(self:GetID())
	end

	return e
end

function PQL.ENTITY.Group:Create()
	local groupID = PQL.DATA.GROUPS:Create()
	return self:ByID(groupID)
end

function PQL.ENTITY.Group:All()
	local groups = PQL.DATA.GROUPS:GetAll()
	local result = {}

	for _, group in ipairs(groups) do
		table.insert(result, Instantiate(group))
	end

	return result
end

function PQL.ENTITY.Group:AsDropdownOptions(onClickCallback)
	local groups = PQL.DATA.GROUPS:GetAll()
	local result = {}

	for _, group in ipairs(groups) do
		local title = group.title:trim() == "" and
			string.format("[ID: %d]", group.groupID) or
			group.title

		table.insert(result, {
			text = title,
			OnClick = function() onClickCallback(Instantiate(group)) end
		})
	end

	return result
end

function PQL.ENTITY.Group:ByID(groupID)
	local data = PQL.DATA.GROUPS:Get(groupID)
	if not data then return nil end
	return Instantiate(data)
end
