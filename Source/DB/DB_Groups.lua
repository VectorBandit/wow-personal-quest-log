PQL_DB_INITIAL_DATABASE.profile.groups = {
    idCache = 0,
    entries = {}
}

PQL_DB.Groups = {}

function PQL_DB.Groups:GetClean()
    return PQLTable.clean(PQL.db.profile.groups.entries)
end

function PQL_DB.Groups:GetOrdered()
    local groups = self:GetClean()

    table.sort(groups, function(a, b)
        return a.groupOrder < b.groupOrder
    end)

    return groups
end

function PQL_DB.Groups:GetAsDropdownOptions(callback)
	local groups = self:GetOrdered()
	local options = {}

	for _, group in ipairs(groups) do
		local title = group.groupTitle:trim() == "" and
			string.format("[ID: %d]", group.groupId) or
			group.groupTitle

		table.insert(options, {
			text = title,
			OnClick = function() callback(group) end
		})
	end

	return options
end

function PQL_DB.Groups:Get(groupId)
    return PQLTable.fromKeyValue(self:GetClean(), "groupId", groupId)
end

function PQL_DB.Groups:GetAtOrder(groupOrder)
    return PQLTable.fromKeyValue(self:GetClean(), "groupOrder", groupOrder)
end

function PQL_DB.Groups:Create()
    local id = PQL.db.profile.groups.idCache + 1
    PQL.db.profile.groups.idCache = id

    local group = {
        groupId = id,
		isCollapsed = false,
        groupTitle = "",
        groupNotes = "",
        groupOrder = PQLTable.length(self:GetClean()) + 1
    }

    table.insert(PQL.db.profile.groups.entries, group)

    PQL_DB:Fire("Groups.Created")
    PQL_DB:Fire("Groups.Updated")

    return group
end

function PQL_DB.Groups:Update(groupId, prop, value)
	local group = self:Get(groupId)
	if not group then return end

	group[prop] = value

	PQL_DB:Fire("Groups.Updated")
end

function PQL_DB.Groups:Reorder(groupId, direction)
    local group = self:Get(groupId)
	if not group then return end

	local prevOrder = group.groupOrder
	local newOrder = group.groupOrder + direction

	local numGroups = PQLTable.length(self:GetClean())

	if newOrder <= 0 or newOrder > numGroups then
		-- Not possible to reorder in that direction.
		return
	end

	local otherGroup = self:GetAtOrder(newOrder)

	-- Swap orders.
	self:Update(otherGroup.groupId, "groupOrder", prevOrder)
	self:Update(group.groupId, "groupOrder", newOrder)
end

function PQL_DB.Groups:Delete(groupId)
    local groups = self:GetOrdered() -- Has to be the ordered version.
    local newGroups = {}

    for _, group in ipairs(groups) do
        if group.groupId ~= groupId then
            table.insert(newGroups, group)
        end
    end

    -- Reset the order.
    for i, group in ipairs(newGroups) do
        newGroups[i].groupOrder = i
    end

    PQL.db.profile.groups.entries = newGroups

    PQL_DB:Fire("Groups.Deleted")
    PQL_DB:Fire("Groups.Updated")
end

