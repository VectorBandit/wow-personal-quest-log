PQL.DATA.DEFAULT_DB.profile.groups = {
	idCache = 0,
	v2fixed = false,
	v2entries = {},
}

PQL.DATA.GROUPS = {}

function PQL.DATA.GROUPS:_ApplyV2Fix()
	if PQL.DATA.db.profile.groups.v2fixed then return end
	if not PQL.DATA.db.profile.groups.entries then return end

	local newGroups = {}

	for _, group in ipairs(PQL.DATA.db.profile.groups.entries) do
		table.insert(newGroups, {
			groupID = group.groupId,
			isCollapsed = group.isCollapsed or false,
			title = group.groupTitle or "",
			notes = group.groupNotes or "",
			order = group.groupOrder,
		})
	end

	PQL.DATA.db.profile.groups.v2entries = newGroups
	PQL.DATA.db.profile.groups.v2fixed = true
end

function PQL.DATA.GROUPS:GetAll()
	table.sort(PQL.DATA.db.profile.groups.v2entries, function(a, b)
		if not a.order then return false end
		if not b.order then return true end
		return a.order < b.order
	end)

	return PQL.DATA.db.profile.groups.v2entries
end

function PQL.DATA.GROUPS:Get(groupID)
	return PQLTable.fromKeyValue(self:GetAll(), "groupID", groupID)
end

function PQL.DATA.GROUPS:GetAtOrder(order)
    return PQLTable.fromKeyValue(self:GetAll(), "order", order)
end

function PQL.DATA.GROUPS:Create()
    local groupID = PQL.DATA.db.profile.groups.idCache + 1
    PQL.DATA.db.profile.groups.idCache = groupID

    local group = {
        groupID = groupID,
		isCollapsed = false,
        title = "",
        notes = "",
        order = PQLTable.length(self:GetAll()) + 1,
    }

    table.insert(PQL.DATA.db.profile.groups.v2entries, group)

    PQL.DATA:Fire("GROUP_CREATED", groupID)

    return groupID
end

function PQL.DATA.GROUPS:Update(groupID, key, value, isStrict)
	local group = self:Get(groupID)
	if not group then return end

	group[key] = value

	if isStrict == nil then isStrict = true end
	PQL.DATA:Fire("GROUP_UPDATED", groupID, isStrict)
end

function PQL.DATA.GROUPS:Reorder(groupID, direction)
    local group = self:Get(groupID)
	if not group then return end

	local prevOrder = group.order
	local newOrder = group.order + direction

	local numGroups = PQLTable.length(self:GetAll())

	if newOrder <= 0 or newOrder > numGroups then
		-- Not possible to reorder in that direction
		return
	end

	local otherGroup = self:GetAtOrder(newOrder)

	self:Update(otherGroup.groupID, "order", prevOrder)
	self:Update(group.groupID, "order", newOrder)
end

function PQL.DATA.GROUPS:Delete(groupID)
    local groups = self:GetAll()
    local newGroups = {}

    for _, group in ipairs(groups) do
        if group.groupID ~= groupID then
            table.insert(newGroups, group)
        end
    end

    -- Reset the order
    for i, group in ipairs(newGroups) do
        newGroups[i].order = i
    end

    PQL.DATA.db.profile.groups.v2entries = newGroups

    PQL.DATA:Fire("GROUP_DELETED", groupID)
end

